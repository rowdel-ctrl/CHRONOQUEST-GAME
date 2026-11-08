const sharp=require('sharp');const D=require('path').join(__dirname,'../../new-assets')+'/';
function runs(proj,minGap,thr=0){const out=[];let s=-1,last=-1;for(let i=0;i<proj.length;i++){if(proj[i]>thr){if(s<0)s=i;else if(i-last>minGap){out.push([s,last+1]);s=i;}last=i;}}if(s>=0)out.push([s,last+1]);return out;}
async function load(name){
  const {data,info}=await sharp(D+name+'.png').raw().toBuffer({resolveWithObject:true});
  const W=info.width,H=info.height;
  // clear long opaque lines
  const rowCnt=new Array(H).fill(0),colCnt=new Array(W).fill(0);
  for(let y=0;y<H;y++)for(let x=0;x<W;x++) if(data[(y*W+x)*4+3]>200){rowCnt[y]++;colCnt[x]++;}
  const badRows=new Set(),badCols=new Set();
  rowCnt.forEach((c,y)=>{if(c>W*0.5||y<4)badRows.add(y)});colCnt.forEach((c,x)=>{if(c>H*0.5||x<4)badCols.add(x)});
  for(const y of badRows)for(let x=0;x<W;x++)data[(y*W+x)*4+3]=0;
  for(const x of badCols)for(let y=0;y<H;y++)data[(y*W+x)*4+3]=0;
  return {data,W,H,cleared:[badRows.size,badCols.size]};
}
async function segment(name,{thr=90,rowGap=30,colGap=40,minRow=8,minColPx=1}={}){
  const {data,W,H,cleared}=await load(name);
  const A=(x,y)=>data[(y*W+x)*4+3];
  const rowP=new Array(H).fill(0);for(let y=0;y<H;y++)for(let x=0;x<W;x++)if(A(x,y)>thr)rowP[y]++;
  const bands=runs(rowP,rowGap,minRow);
  const res=bands.map(([y0,y1])=>{const colP=new Array(W).fill(0);for(let x=0;x<W;x++){let c=0;for(let y=y0;y<y1;y++)if(A(x,y)>thr)c++;colP[x]=c;}return {y0,y1,cols:runs(colP,colGap,minColPx)};});
  return {W,H,cleared,res,data};
}
module.exports={segment,load,runs};
if(require.main===module)(async()=>{
 for(const [n,o] of [['BOY',{}],['GIRL',{}],['LAPU',{}],['LUNA',{}],['RIZAL',{}],['BONIFACIO',{}],['DEL PILAR',{}],['ENEMIES',{}],['BOSSES',{rowGap:15}]]){
  const r=await segment(n,o);
  console.log(n,r.W+'x'+r.H,'cleared',r.cleared.join('/'),'bands',r.res.length);
  r.res.forEach((b,i)=>console.log('  band',i,b.y0+'-'+b.y1,'n',b.cols.length,b.cols.map(c=>c[0]+'-'+c[1]).join(' ')));
 }})();
