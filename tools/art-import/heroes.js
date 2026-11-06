const {prepFrame,place,extents,OUT}=require('./build.js');const fs=require('fs');
const ROLES={
 default:{walk:['r0_c0','r0_c1','r0_c2','r0_c3'],jump:'r0_c4',hurt:'r0_c5',attack:['r1_c0','r1_c1','r1_c2','r1_c3'],idle:'r1_c4',win:'r1_c5'},
 lapu:{walk:['r0_c0','r0_c1','r0_c2','r0_c3','r0_c4'],jump:'r0_c5',hurt:'r1_c0',attack:['r1_c1','r1_c2','r1_c3'],idle:'r1_c4',win:'r1_c5'}};
const IDS=['boy','girl','lapu','luna','rizal','bonifacio','delpilar'];
(async()=>{
 const report={};
 for(const id of IDS){
  const roles=ROLES[id]||ROLES.default;
  const P=async k=>prepFrame(`cells/${id}_${k.replace('_','_')}.png`);
  const walk=[];for(const k of roles.walk)walk.push(await P(k));
  const jump=await P(roles.jump),hurt=await P(roles.hurt),idle=await P(roles.idle),win=await P(roles.win);
  const attack=[];for(const k of roles.attack)attack.push(await P(k));
  const hIdle=idle.bb.y1-idle.bb.y0;const s=296/hIdle;
  const grp=(frs,minW,minH)=>{let m=0,t=0;for(const f of frs){const e=extents(f,s);m=Math.max(m,e.l,e.r);t=Math.max(t,e.t);}
    return {W:Math.max(minW,2*Math.ceil(m)+8),H:Math.max(minH,Math.ceil(t)+4)};};
  const base=grp([...walk,jump,hurt],240,300),ext=grp([...attack,idle,win],240,300);
  const dir=`${OUT}/characters/`;
  for(let i=0;i<walk.length;i++)await place(walk[i],s,base.W,base.H,`${dir}${id}_walk_${i+1}.png`);
  await place(jump,s,base.W,base.H,`${dir}${id}_jump.png`);
  await place(hurt,s,base.W,base.H,`${dir}${id}_hurt.png`);
  for(let i=0;i<attack.length;i++)await place(attack[i],s,ext.W,ext.H,`${dir}${id}_attack_${i+1}.png`);
  await place(idle,s,ext.W,ext.H,`${dir}${id}_idle.png`);
  await place(win,s,ext.W,ext.H,`${dir}${id}_win.png`);
  report[id]={scale:+s.toFixed(3),idleH:hIdle,base,ext,walk:walk.length,attack:attack.length};
  console.log(id,JSON.stringify(report[id]));
 }
})();
