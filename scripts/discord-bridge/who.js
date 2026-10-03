const T=require("fs").readFileSync(require("os").homedir()+"/.config/studycrowd/bot-token","utf8").trim();
fetch("https://discord.com/api/v10/users/"+process.argv[2],{headers:{Authorization:"Bot "+T}})
 .then(async r=>{const j=await r.json();console.log(r.status,JSON.stringify({id:j.id,username:j.username,global_name:j.global_name,bot:j.bot,message:j.message}))});
