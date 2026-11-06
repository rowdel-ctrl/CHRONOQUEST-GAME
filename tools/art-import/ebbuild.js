const {prepFrame,place,extents,OUT}=require('./build.js');const fs=require('fs');
const {ENEMY,BOSS}=require('./eb.js');
async function doGroup(names,kind,box,roles){ // box=[w,h] px
  const rep={};
  for(const n of names){
    const fr=[];for(let i=0;i<6;i++)fr.push(await prepFrame(`cells_eb/${n}_${i}.png`));
    const idle=fr[0];const iw=idle.bb.x1-idle.bb.x0,ih=idle.bb.y1-idle.bb.y0;
    const s=Math.min((box[1]-12)/ih,(box[0]-12)/iw);
    const grp=(idx)=>{let m=0,t=0;for(const i of idx){const e=extents(fr[i],s);m=Math.max(m,e.l,e.r);t=Math.max(t,e.t);}return {W:Math.max(box[0],2*Math.ceil(m)+8),H:Math.max(box[1],Math.ceil(t)+4)};};
    const out={};
    const dir=`${OUT}/${kind}/`;
    const gBase=grp(roles.base),gExt=grp(roles.ext);
    for(const [file,i,g] of roles.files(gBase,gExt)){await place(fr[i],s,g.W,g.H,dir+n+file+'.png');}
    rep[n]={s:+s.toFixed(3),idle:[iw,ih],base:gBase,ext:gExt};
    console.log(kind,n,JSON.stringify(rep[n]));
  }
  fs.writeFileSync(`${OUT}/${kind}_report.json`,JSON.stringify(rep,null,1));
}
(async()=>{
 await doGroup(ENEMY,'enemies',[225,270],{base:[0,1,2,3,5],ext:[4],
   files:(b,e)=>[['_1',1,b],['_2',2,b],['_3',3,b],['_idle',0,b],['_hurt',5,b],['_attack',4,e]]});
 await doGroup(BOSS,'bosses',[300,350],{base:[0,1,4,5],ext:[2,3],
   files:(b,e)=>[['_idle',0,b],['_move',1,b],['_hurt',4,b],['_defeated',5,b],['_attack',2,e],['_special',3,e]]});
})();
