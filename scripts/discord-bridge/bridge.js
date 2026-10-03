// Discord -> Claude bridge for one channel. Prints one stdout line per human message.
// Reconnects on drops and tells the channel when it is unhealthy or recovered.
// Exit code 2 = fatal (bad token / missing intents).
const fs=require('fs');
// Token: $DISCORD_BOT_TOKEN if set, else the file $BRIDGE_TOKEN_FILE (default ~/.config/studycrowd/bot-token).
const TOKEN=process.env.DISCORD_BOT_TOKEN||fs.readFileSync(process.env.BRIDGE_TOKEN_FILE||require('os').homedir()+'/.config/studycrowd/bot-token','utf8').trim();
const CHANNEL=process.env.BRIDGE_CHANNEL_ID||'1555999577637781604';
const API='https://discord.com/api/v10', H={Authorization:'Bot '+TOKEN,'Content-Type':'application/json'};
const sleep=ms=>new Promise(r=>setTimeout(r,ms));

async function api(method,path,body,tries=3){
  for(let i=0;i<tries;i++){
    const r=await fetch(API+path,{method,headers:H,body:body&&JSON.stringify(body)});
    if(r.status===429){const j=await r.json().catch(()=>({}));await sleep((j.retry_after||2)*1000);continue;}
    return r;
  }
}
const notify=t=>api('POST',`/channels/${CHANNEL}/messages`,{content:t}).catch(()=>{});

// Typing indicator: one pulse per message. Discord can't cancel typing, only let it lapse
// (~10s), so repeating it showed "typing" for messages that never got a reply.
const typeOnce=()=>api('POST',`/channels/${CHANNEL}/typing`,null,1).catch(()=>{});

// Image parsing: download image attachments so the session can open them with the Read tool.
// Files go to $BRIDGE_IMAGE_DIR (default <tmpdir>/studycrowd-bridge-images); max 8 MB each, 4 per message.
const IMG_DIR=process.env.BRIDGE_IMAGE_DIR||require('path').join(require('os').tmpdir(),'studycrowd-bridge-images');
async function saveImages(d){
  const out=[];
  for(const a of (d.attachments||[]).slice(0,4)){
    if(!(a.content_type||'').startsWith('image/')||a.size>8*1024*1024) continue;
    try{
      fs.mkdirSync(IMG_DIR,{recursive:true});
      const ext=(a.filename.match(/\.[A-Za-z0-9]{1,5}$/)||['.png'])[0].toLowerCase();
      const file=require('path').join(IMG_DIR,`${d.id}-${out.length}${ext}`);
      const r=await fetch(a.url);
      if(!r.ok) continue;
      fs.writeFileSync(file,Buffer.from(await r.arrayBuffer()));
      out.push(file);
    }catch(e){console.log('[bridge] image download failed',e.message);}
  }
  return out;
}

// Catch-up: the ID of the last forwarded message is saved to $BRIDGE_STATE_FILE (default
// <tmpdir>/studycrowd-bridge-last-id). On every READY, messages newer than it are fetched and
// printed with a [catch-up] tag, so restarts, reconnects and Monitor re-arm gaps lose nothing.
const STATE_FILE=process.env.BRIDGE_STATE_FILE||require('path').join(require('os').tmpdir(),'studycrowd-bridge-last-id');
let lastId=null;
try{lastId=fs.readFileSync(STATE_FILE,'utf8').trim()||null;}catch{}
const newer=id=>!lastId||BigInt(id)>BigInt(lastId);
function markSeen(id){ if(!newer(id)) return; lastId=id; try{fs.writeFileSync(STATE_FILE,id);}catch{} }

async function forward(d,tag=''){
  if(!newer(d.id)) return; // already forwarded (live and catch-up can overlap)
  markSeen(d.id);
  const files=await saveImages(d);
  const other=(d.attachments||[]).length-files.length;
  console.log(`${tag}[#claude] ${d.author.username} (${d.author.id}) msg ${d.id}: ${JSON.stringify(d.content)}`+
    files.map(f=>` [image: ${f}]`).join('')+(other>0?` [+${other} non-image attachment(s)]`:''));
}

async function catchUp(){
  try{
    if(!lastId){ // First run: start from the newest message instead of replaying history.
      const r=await api('GET',`/channels/${CHANNEL}/messages?limit=1`);
      const [m]=r&&r.ok?await r.json():[];
      if(m) markSeen(m.id);
      return;
    }
    for(let page=0;page<5;page++){ // up to 500 missed messages
      const r=await api('GET',`/channels/${CHANNEL}/messages?after=${lastId}&limit=100`);
      if(!r||!r.ok){console.log('[bridge] catch-up failed',r&&r.status);return;}
      const msgs=(await r.json()).sort((a,b)=>BigInt(a.id)<BigInt(b.id)?-1:1);
      for(const d of msgs){ if(d.author.bot){markSeen(d.id);continue;} await forward(d,'[catch-up] '); }
      if(msgs.length<100) return;
    }
  }catch(e){console.log('[bridge] catch-up failed',e.message);}
}

let seq=null,hb=null,selfId=null,fails=0,warned=false,acked=true;
let caughtUp=Promise.resolve(); // live messages wait for catch-up so the saved ID never skips ahead
function connect(){
  const ws=new WebSocket('wss://gateway.discord.gg/?v=10&encoding=json');
  ws.onopen=()=>console.log('[bridge] socket open');
  ws.onerror=e=>console.log('[bridge] error',e.message||e.type);
  ws.onclose=async e=>{
    console.log('[bridge] closed',e.code,e.reason||''); clearInterval(hb);
    if([4004,4013,4014].includes(e.code)){
      await notify(`:warning: Bridge stopped: Discord closed the connection with code ${e.code} (${e.code===4004?'bad bot token':'Message Content intent is not enabled'}). A human needs to fix this.`);
      process.exit(2);
    }
    fails++;
    if(fails>=3&&!warned){warned=true;await notify(':warning: Bridge is having trouble reconnecting to Discord. Messages may be missed. Retrying.');}
    setTimeout(connect,Math.min(5000*fails,30000));
  };
  ws.onmessage=async ev=>{
    const m=JSON.parse(ev.data); if(m.s) seq=m.s;
    if(m.op===10){
      // A heartbeat that is never ACKed means a dead ("zombie") connection: drop it and reconnect.
      acked=true;
      hb=setInterval(()=>{
        if(!acked){console.log('[bridge] heartbeat not acknowledged, reconnecting');ws.close(4000,'zombie');return;}
        acked=false; ws.send(JSON.stringify({op:1,d:seq}));
      },m.d.heartbeat_interval);
      ws.send(JSON.stringify({op:2,d:{token:TOKEN,intents:1|512|32768,
        properties:{os:'linux',browser:'claude-bridge',device:'claude-bridge'}}}));
    } else if(m.op===11){ acked=true; }
    else if(m.op===1){ ws.send(JSON.stringify({op:1,d:seq})); }
    else if(m.op===7||m.op===9){ ws.close(4000,'reconnect'); }
    else if(m.t==='READY'){
      selfId=m.d.user.id; console.log('[bridge] ready as',m.d.user.username);
      if(warned){warned=false;notify(':white_check_mark: Bridge is back online.');}
      fails=0;
      caughtUp=catchUp();
    } else if(m.t==='MESSAGE_CREATE'){
      const d=m.d; if(d.channel_id!==CHANNEL) return;
      await caughtUp;
      if(d.author.id===selfId){markSeen(d.id);return;}
      if(d.author.bot){markSeen(d.id);return;}
      typeOnce();
      await forward(d);
    }
  };
}
process.on('unhandledRejection',e=>console.log('[bridge] unhandled',e&&e.message));
connect();
