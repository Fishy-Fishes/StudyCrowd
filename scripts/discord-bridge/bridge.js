// Discord -> Claude bridge for one channel. Prints one stdout line per human message.
// Reconnects on drops and tells the channel when it is unhealthy or recovered.
// Exit code 2 = fatal (bad token / missing intents).
const fs=require('fs');
const TOKEN=fs.readFileSync(process.env.BRIDGE_TOKEN_FILE||require('os').homedir()+'/.config/studycrowd/bot-token','utf8').trim();
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

// Typing indicator: from message arrival until our own reply posts (or 90s).
const typing={};
const typeOnce=()=>api('POST',`/channels/${CHANNEL}/typing`,null,1).catch(()=>{});
function startTyping(){ stopTyping(); typeOnce(); typing.t=setInterval(typeOnce,8000); typing.s=setTimeout(stopTyping,90000); }
function stopTyping(){ clearInterval(typing.t); clearTimeout(typing.s); }

let seq=null,hb=null,selfId=null,fails=0,warned=false;
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
      hb=setInterval(()=>ws.send(JSON.stringify({op:1,d:seq})),m.d.heartbeat_interval);
      ws.send(JSON.stringify({op:2,d:{token:TOKEN,intents:1|512|32768,
        properties:{os:'linux',browser:'claude-bridge',device:'claude-bridge'}}}));
    } else if(m.op===7||m.op===9){ ws.close(4000,'reconnect'); }
    else if(m.t==='READY'){
      selfId=m.d.user.id; console.log('[bridge] ready as',m.d.user.username);
      if(warned){warned=false;notify(':white_check_mark: Bridge is back online.');}
      fails=0;
    } else if(m.t==='MESSAGE_CREATE'){
      const d=m.d; if(d.channel_id!==CHANNEL) return;
      if(d.author.id===selfId){stopTyping();return;}
      if(d.author.bot) return;
      startTyping();
      console.log(`[#claude] ${d.author.username} (${d.author.id}) msg ${d.id}: ${JSON.stringify(d.content)}${d.attachments&&d.attachments.length?` [+${d.attachments.length} attachment(s)]`:''}`);
    }
  };
}
process.on('unhandledRejection',e=>console.log('[bridge] unhandled',e&&e.message));
connect();
