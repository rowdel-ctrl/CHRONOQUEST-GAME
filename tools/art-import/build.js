const sharp=require('sharp');const fs=require('fs');const path=require('path');
const D=require('path').join(__dirname,'../../new-assets')+'/';
const {cutSheet,NAME}=require('./cut.js');
const {bandsFor}=require('./cutEB2.js');
const OUT='out';
const SCALE_HERO_H=296;           // standing body height in px  (-> 120 game units at 2.5 px/unit)
// ---------- image helpers ----------
async function rawOf(file){const {data,info}=await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true});return {data,W:info.width,H:info.height};}
function mainBlob({data,W,H},{dil=36,ds=2,thr=40}={}){
  const w=Math.ceil(W/ds),h=Math.ceil(H/ds);const m=new Uint8Array(w*h),core=new Float32Array(w*h);
  for(let y=0;y<H;y++)for(let x=0;x<W;x++){const a=data[(y*W+x)*4+3];if(a>thr){const k=((y/ds)|0)*w+((x/ds)|0);m[k]=1;if(a>200)core[k]+=1;}}
  const r=Math.round(dil/ds/2);const t=new Uint8Array(w*h),d=new Uint8Array(w*h);
  for(let y=0;y<h;y++)for(let x=0;x<w;x++)if(m[y*w+x])for(let dx=-r;dx<=r;dx++){const xx=x+dx;if(xx>=0&&xx<w)t[y*w+xx]=1;}
  for(let y=0;y<h;y++)for(let x=0;x<w;x++)if(t[y*w+x])for(let dy=-r;dy<=r;dy++){const yy=y+dy;if(yy>=0&&yy<h)d[yy*w+x]=1;}
  const lab=new Int32Array(w*h);let best=0,bestScore=-1,n=0;const score=[0];
  for(let i=0;i<w*h;i++){if(!d[i]||lab[i])continue;n++;const st=[i];lab[i]=n;let sc=0;
    while(st.length){const p=st.pop();sc+=core[p];const px=p%w,py=(p/w)|0;for(const [dx,dy] of [[1,0],[-1,0],[0,1],[0,-1]]){const nx=px+dx,ny=py+dy;if(nx<0||ny<0||nx>=w||ny>=h)continue;const q=ny*w+nx;if(d[q]&&!lab[q]){lab[q]=n;st.push(q);}}}
    score[n]=sc;if(sc>bestScore){bestScore=sc;best=n;}}
  const out=Buffer.from(data);
  for(let y=0;y<H;y++)for(let x=0;x<W;x++){const k=((y/ds)|0)*w+((x/ds)|0);if(lab[k]!==best)out[(y*W+x)*4+3]=0;}
  return {data:out,W,H};
}
function bbox({data,W,H},thr=100){let x0=1e9,y0=1e9,x1=-1,y1=-1;for(let y=0;y<H;y++)for(let x=0;x<W;x++)if(data[(y*W+x)*4+3]>thr){if(x<x0)x0=x;if(x>x1)x1=x;if(y<y0)y0=y;if(y>y1)y1=y;}return {x0,y0,x1:x1+1,y1:y1+1};}
function feetX({data,W,H},bb,frac=0.14){ // centre of the lowest part of the figure
  const yTop=bb.y1-Math.max(4,Math.round((bb.y1-bb.y0)*frac));let x0=1e9,x1=-1;
  for(let y=yTop;y<bb.y1;y++)for(let x=bb.x0;x<bb.x1;x++)if(data[(y*W+x)*4+3]>100){if(x<x0)x0=x;if(x>x1)x1=x;}
  return (x0+x1+1)/2;
}
// frame record: {img(raw), bb, ax (feet x), by (bottom y)}
async function prepFrame(file){const r=mainBlob(await rawOf(file));const bb=bbox(r);return {r,bb,ax:feetX(r,bb),by:bb.y1};}
// render a frame at scale s onto a canvas CW x CH with feet anchor at (CW/2, CH) -> png file
async function place(fr,s,CW,CH,outFile){
  const {W,H}=fr.r;
  const resized=await sharp(fr.r.data,{raw:{width:W,height:H,channels:4}}).resize({width:Math.max(1,Math.round(W*s)),height:Math.max(1,Math.round(H*s)),kernel:'lanczos3'}).png().toBuffer();
  const left=Math.round(CW/2-fr.ax*s),top=Math.round(CH-fr.by*s);
  // clip to canvas
  const rm=await sharp(resized).metadata();
  let ex=0,ey=0,cl=left,ct=top,cw=rm.width,chh=rm.height;
  if(cl<0){ex=-cl;cw+=cl;cl=0;} if(ct<0){ey=-ct;chh+=ct;ct=0;} if(cl+cw>CW)cw=CW-cl; if(ct+chh>CH)chh=CH-ct;
  const piece=await sharp(resized).extract({left:ex,top:ey,width:cw,height:chh}).png().toBuffer();
  fs.mkdirSync(path.dirname(outFile),{recursive:true});
  await sharp({create:{width:CW,height:CH,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:piece,left:cl,top:ct}]).png({compressionLevel:9}).toFile(outFile);
}
function extents(fr,s){return {l:(fr.ax-fr.bb.x0)*s,r:(fr.bb.x1-fr.ax)*s,t:(fr.by-fr.bb.y0)*s};}
module.exports={prepFrame,place,extents,rawOf,mainBlob,bbox,feetX,OUT};
