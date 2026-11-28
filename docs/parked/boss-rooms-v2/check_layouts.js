const P='F:/CHRONO/CHRONO-GAMEAPP/tools/levelgen/';
const A=require(P+'arenas.js');const T=require(P+'terrain');const {solve}=require(P+'solve');
const COLS=A.COLS,W=A.WALL,mirror=c=>COLS-1-c;
const NEW={
 'pre-colonial':[[2,W],[6,0],[5,-1],[2,0],[2,2],[2,0],[3,3],[2,0],[2,2],[23,0]],
 'spanish':[[2,W],[6,0],[4,0],[5,3],[4,0],[5,3],[23,0]],
 'nationalism':[[2,W],[8,2],[3,1],[4,0],[2,2],[3,3],[2,2],[25,0]],
 'american':[[2,W],[6,0],[2,1],[2,0],[1,1],[3,0],[2,2],[4,0],[2,3],[25,0]],
 'ww2':[[2,W],[6,0],[4,-1],[1,1],[2,0],[2,1],[2,2],[2,3],[3,4],[25,0]],
 'modern':[[2,W],[6,0],[8,0],[2,1],[2,2],[2,3],[4,4],[2,3],[2,2],[2,1],[17,0]],
};
const out={};let allOk=true;
for(const era of Object.keys(NEW)){
  const left=NEW[era].reduce((a,[n,h])=>a.concat(Array(n).fill(h)),[]);
  if(left.length!==49){console.log(era,'left',left.length);process.exit(1)}
  left.push(1,...Array(7).fill(2));
  const H=Int8Array.from([...left,...[...left].reverse()]);
  const centre=c=>c*24+12,surf=c=>T.surfaceY(H[c]);
  const minions=[];for(const c of[38,42])minions.push({x:centre(c),y:surf(c)},{x:centre(mirror(c)),y:surf(mirror(c))});
  const level={props:{era,level:5},H,S:null,C:null,grid:null,platforms:[],coins:[],artifacts:[],enemies:[],gates:[],spawnX:5*24,exitX:COLS*24,seed:0,arena:{boss:{x:COLS*12,y:surf(COLS/2)},minions,scrolls:[]}};
  const r=solve(level,{margin:0});const spots=r.spots;
  const on=(y,x0,x1)=>spots.some(s=>Math.abs(s.top-y)<1&&s.x+48>=x0&&s.x+48<=x1);
  // every raised block outside the walls and the stage must be reachable
  const bad=[];let c=0;
  while(c<COLS){let e=c;while(e+1<COLS&&H[e+1]===H[c])e++;
    if(H[c]>0&&H[c]!==W&&!(c>=COLS/2-8&&e<=COLS/2+7)&&!(c<2)){if(!on(T.surfaceY(H[c]),c*24,(e+1)*24))bad.push(`cols ${c}-${e} h${H[c]}`)}
    c=e+1}
  const minionsOk=minions.every(m=>on(m.y,m.x-100,m.x+100));
  const bossOk=on(level.arena.boss.y,COLS*12-400,COLS*12+400);
  const flat=[38,42].every(c=>{for(let k=c-6;k<=c+6;k++)if(H[k]!==0)return false;return true});
  const ok=r.traps.length===0&&bad.length===0&&minionsOk&&bossOk&&flat;allOk=allOk&&ok;
  console.log(era.padEnd(13),ok?'OK ':'BAD','traps',r.traps.length,'unreached',bad.join('; ')||'none','minions',minionsOk,'boss',bossOk,'flat',flat,'maxH',Math.max(...left.filter(h=>h<W)));
  const old=A.buildArena(era);
  out[era]={now:{H:Array.from(old.H),platforms:old.platforms.map(p=>({c:Math.round(p.x/24),w:Math.round(p.width/24),h:Math.round((660-p.y)/24*1000)/1000}))},neu:{H:Array.from(H)}};
}
require('fs').writeFileSync(process.argv[2]+'/layouts.json',JSON.stringify(out));console.log(allOk?'ALL OK':'SOME BAD');
