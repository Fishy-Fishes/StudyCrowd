const T=require("fs").readFileSync(require("os").homedir()+"/.config/studycrowd/bot-token","utf8").trim();
const H={Authorization:"Bot "+T,"Content-Type":"application/json"},A="https://discord.com/api/v10";
const [,, mid, ...rest]=process.argv; const text=rest.join(" ");
(async()=>{
  for(const g of await (await fetch(A+"/users/@me/guilds",{headers:H})).json())
    for(const c of await (await fetch(`${A}/guilds/${g.id}/channels`,{headers:H})).json())
      if(c.type===0&&c.name.includes("claude")){
        const r=await fetch(`${A}/channels/${c.id}/messages`,{method:"POST",headers:H,
          body:JSON.stringify({content:text,message_reference:{message_id:mid},allowed_mentions:{replied_user:false}})});
        console.log(c.name,c.id,r.status);
      }
})();
