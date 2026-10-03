// Discord -> Claude bridge: prints one line per message in channels whose name contains "claude".
const fs=require('fs');
const TOKEN=fs.readFileSync(process.env.BRIDGE_TOKEN_FILE||require('os').homedir()+'/.config/studycrowd/bot-token','utf8').trim();
const API='https://discord.com/api/v10';
const chanName={};
async function name(id){
  if(chanName[id]) return chanName[id];
  try{const r=await fetch(`${API}/channels/${id}`,{headers:{Authorization:'Bot '+TOKEN}});
    const j=await r.json(); chanName[id]=j.name||'?';}catch{chanName[id]='?'}
  return chanName[id];
}
// Typing indicator: shown from the moment a message arrives until our own reply posts (or 90s).
const typing={};
function typeOnce(ch){ fetch(`${API}/channels/${ch}/typing`,{method:'POST',headers:{Authorization:'Bot '+TOKEN}}).catch(()=>{}); }
function startTyping(ch){
  stopTyping(ch); typeOnce(ch);
  const t=setInterval(()=>typeOnce(ch),8000);
  typing[ch]={t,stop:setTimeout(()=>stopTyping(ch),90000)};
}
function stopTyping(ch){ const x=typing[ch]; if(!x) return; clearInterval(x.t); clearTimeout(x.stop); delete typing[ch]; }
let seq=null,hb=null,selfId=null;
function connect(){
  const ws=new WebSocket('wss://gateway.discord.gg/?v=10&encoding=json');
  ws.onopen=()=>console.log('[bridge] socket open');
  ws.onerror=e=>console.log('[bridge] error',e.message||e.type);
  ws.onclose=e=>{console.log('[bridge] closed',e.code,e.reason||'');clearInterval(hb);
    if(![4004,4013,4014].includes(e.code)) setTimeout(connect,5000); else process.exit(1);};
  ws.onmessage=async ev=>{
    const m=JSON.parse(ev.data); if(m.s) seq=m.s;
    if(m.op===10){
      hb=setInterval(()=>ws.send(JSON.stringify({op:1,d:seq})),m.d.heartbeat_interval);
      ws.send(JSON.stringify({op:2,d:{token:TOKEN,intents:1|512|32768,
        properties:{os:'linux',browser:'claude-bridge',device:'claude-bridge'}}}));
    } else if(m.t==='READY') {selfId=m.d.user.id;console.log('[bridge] ready as',m.d.user.username);}
    else if(m.t==='MESSAGE_CREATE'){
      const d=m.d;
      if(d.author.id===selfId){ stopTyping(d.channel_id); return; }
      if(d.author.bot) return;
      const n=await name(d.channel_id);
      if(!n.includes('claude')) return;
      startTyping(d.channel_id);
      console.log(`[#${n}] ${d.author.username} (${d.author.id}) msg ${d.id}: ${JSON.stringify(d.content)}`);
    }
  };
}
connect();
