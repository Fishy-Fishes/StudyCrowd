// Usage: node reply.js [--file <path>]... <message_id|-> <text...>
// Posts to the bridge channel (no lookups), optionally with file attachments; retries on rate limits.
const fs=require("fs"), path=require("path");
const T=process.env.DISCORD_BOT_TOKEN||fs.readFileSync(process.env.BRIDGE_TOKEN_FILE||require("os").homedir()+"/.config/studycrowd/bot-token","utf8").trim();
const CH=process.env.BRIDGE_CHANNEL_ID||"1555999577637781604";
const args=process.argv.slice(2), files=[];
while(args[0]==="--file"){ args.shift(); files.push(args.shift()); }
const [mid, ...rest]=args; const content=rest.join(" ");

function request(){
  const payload={content,allowed_mentions:{replied_user:false}};
  if(mid&&mid!=="-") payload.message_reference={message_id:mid};
  if(!files.length) return {headers:{"Content-Type":"application/json"},body:JSON.stringify(payload)};
  // Attachments: multipart with payload_json plus files[n] (fetch sets the multipart Content-Type).
  const form=new FormData();
  form.append("payload_json",JSON.stringify(payload));
  files.forEach((f,i)=>form.append(`files[${i}]`,new Blob([fs.readFileSync(f)]),path.basename(f)));
  return {headers:{},body:form};
}

(async()=>{
  for(let i=0;i<4;i++){
    const {headers,body}=request();
    const r=await fetch(`https://discord.com/api/v10/channels/${CH}/messages`,{method:"POST",
      headers:{Authorization:"Bot "+T,...headers},body});
    if(r.status===429){const j=await r.json();await new Promise(x=>setTimeout(x,(j.retry_after||2)*1000));continue;}
    // On failure, print Discord's error body (code + message) so the cause is visible.
    console.log(r.ok?r.status:`${r.status} ${(await r.text()).slice(0,300)}`); return;
  }
  console.log("gave up (rate limited)"); process.exit(1);
})();
