// Maria Clara (2026-11-08): cut from "MARIA CLARA.png" (two identical 12-pose blocks; the BOTTOM one has no
// frame line, so it is used). Run from an empty working folder:  node <path>/mariaclara.js
// Needs the `sharp` package (NODE_PATH). Writes out/characters/mariaclara_*.png, then shrinks them to
// 256 colours straight into assets/characters/ (same palette settings as quant.js).
const sharp=require('sharp');const fs=require('fs');const path=require('path');
const {place,extents,rawOf,mainBlob,bbox,feetX}=require('F:/CHRONO/CHRONO-GAMEAPP/tools/art-import/build.js');
const SRC=require('path').join(__dirname,'../../new-assets/MARIA CLARA.png');
const ASSETS='F:/CHRONO/CHRONO-GAMEAPP/assets/characters/';
const ID='mariaclara';
// bottom block: [y0,y1] of each row, [x0,x1] of each of the 6 columns (found by projecting the alpha channel)
const ROWS=[[1104,1566],[1618,2096]];
const COLS=[
 [[337,619],[937,1158],[1336,1621],[1881,2118],[2364,2686],[2882,3193]],
 [[330,786],[919,1205],[1329,1816],[1856,2220],[2380,2642],[2916,3297]]];
const PAD=10;
// clear faint fringe: low alpha -> 0, and a lone semi-transparent pixel ring next to empty space -> 0
function defringe(r){const {data,W,H}=r;const a=(x,y)=>data[(y*W+x)*4+3];
 for(let i=0;i<W*H;i++)if(data[i*4+3]<70)data[i*4+3]=0;
 // edge pixels that are not solid and have few solid neighbours are noise
 const kill=[];
 for(let y=1;y<H-1;y++)for(let x=1;x<W-1;x++){const v=a(x,y);if(v===0||v>=235)continue;
  let solid=0;for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++)if((dx||dy)&&a(x+dx,y+dy)>=235)solid++;
  if(solid<=1)kill.push((y*W+x)*4+3);}
 for(const k of kill)data[k]=0;return r;}
(async()=>{
 const whole=sharp(SRC);const cells={};
 for(let r=0;r<2;r++)for(let c=0;c<6;c++){
  const [x0,x1]=COLS[r][c],[y0,y1]=ROWS[r];
  const buf=await sharp(SRC).extract({left:x0-PAD,top:y0-PAD,width:x1-x0+2*PAD,height:y1-y0+2*PAD}).png().toBuffer();
  const raw=await sharp(buf).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let rr={data:raw.data,W:raw.info.width,H:raw.info.height};
  rr=defringe(rr);rr=mainBlob(rr,{dil:60});   // wide join so the crescent, petals and sparkles stay
  const bb=bbox(rr);cells[`r${r}_c${c}`]={r:rr,bb,ax:feetX(rr,bb),by:bb.y1};
 }
 const P=k=>cells[k];
 const walk=['r0_c0','r0_c1','r0_c2','r0_c3'].map(P),jump=P('r0_c4'),hurt=P('r0_c5');
 const attack=['r1_c0','r1_c1','r1_c2','r1_c3'].map(P),idle=P('r1_c4'),win=P('r1_c5');
 const hIdle=idle.bb.y1-idle.bb.y0;const s=296/hIdle;
 const grp=(frs,minW,minH)=>{let m=0,t=0;for(const f of frs){const e=extents(f,s);m=Math.max(m,e.l,e.r);t=Math.max(t,e.t);}
   return {W:Math.max(minW,2*Math.ceil(m)+8),H:Math.max(minH,Math.ceil(t)+4)};};
 const base=grp([...walk,jump,hurt],240,300),ext=grp([...attack,idle,win],240,300);
 const dir='out/characters/';
 for(let i=0;i<4;i++)await place(walk[i],s,base.W,base.H,`${dir}${ID}_walk_${i+1}.png`);
 await place(jump,s,base.W,base.H,`${dir}${ID}_jump.png`);
 await place(hurt,s,base.W,base.H,`${dir}${ID}_hurt.png`);
 for(let i=0;i<4;i++)await place(attack[i],s,ext.W,ext.H,`${dir}${ID}_attack_${i+1}.png`);
 await place(idle,s,ext.W,ext.H,`${dir}${ID}_idle.png`);
 await place(win,s,ext.W,ext.H,`${dir}${ID}_win.png`);
 console.log(ID,JSON.stringify({scale:+s.toFixed(3),idleH:hIdle,base,ext}));
 for(const f of fs.readdirSync(dir).filter(f=>f.startsWith(ID)&&f.endsWith('.png'))){
  const buf=await sharp(dir+f).png({palette:true,quality:92,colours:256,dither:0.6,effort:9,compressionLevel:9}).toBuffer();
  fs.writeFileSync(path.join(ASSETS,f),buf);}
})();
