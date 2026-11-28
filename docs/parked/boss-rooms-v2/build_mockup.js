const fs=require('fs');const A='F:/CHRONO/CHRONO-GAMEAPP/assets/';const dir=process.argv[2];
const map={boy_idle:'characters/boy_idle.png',
bakunawa_idle:'bosses/bakunawa_idle.png',governor_idle:'bosses/governor_idle.png',general_idle:'bosses/general_idle.png',commander_idle:'bosses/commander_idle.png',corruption_boss_idle:'bosses/corruption_boss_idle.png',
dark_spirit_1:'enemies/dark_spirit_1.png',spanish_soldier_1:'enemies/spanish_soldier_1.png',american_soldier_1:'enemies/american_soldier_1.png',japanese_soldier_1:'enemies/japanese_soldier_1.png',misinfo_cloud_1:'enemies/misinfo_cloud_1.png'};
for(const e of['pre-colonial','spanish','nationalism','american','ww2','modern'])map['sheet_'+e]='tiles/ground_'+e+'.png';
const o={};for(const[k,v]of Object.entries(map))o[k]='data:image/png;base64,'+fs.readFileSync(A+v).toString('base64');
let t=fs.readFileSync(dir+'/rooms_template.html','utf8');
t=t.replace('/*SRC*/{}',()=>JSON.stringify(o)).replace('/*LAYOUTS*/{}',()=>fs.readFileSync(dir+'/layouts.json','utf8'));
fs.writeFileSync(dir+'/boss_rooms_mockup.html',t);console.log(t.length);
