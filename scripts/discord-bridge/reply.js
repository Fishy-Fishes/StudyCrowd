// Usage: node reply.js <message_id|-> <text...>   Posts to the bridge channel (no lookups); retries on rate limits.
const fs=require("fs");
const T=fs.readFileSync(process.env.BRIDGE_TOKEN_FILE||require("os").homedir()+"/.config/studycrowd/bot-token","utf8").trim();
const CH=process.env.BRIDGE_CHANNEL_ID||"1555999577637781604";
const [,, mid, ...rest]=process.argv; const content=rest.join(" ");
(async()=>{
  for(let i=0;i<4;i++){
    const body={content,allowed_mentions:{replied_user:false}};
    if(mid&&mid!=="-") body.message_reference={message_id:mid};
    const r=await fetch(`https://discord.com/api/v10/channels/${CH}/messages`,{method:"POST",
      headers:{Authorization:"Bot "+T,"Content-Type":"application/json"},body:JSON.stringify(body)});
    if(r.status===429){const j=await r.json();await new Promise(x=>setTimeout(x,(j.retry_after||2)*1000));continue;}
    console.log(r.status); return;
  }
  console.log("gave up (rate limited)"); process.exit(1);
})();
