const sharp=require('sharp');const fs=require('fs');const D='C:/Users/PC/Downloads/NEW ASSETS/';
const {cutSheet,NAME}=require('./cut.js');
const PAD=6;
(async()=>{
 const meta={};
 for(const sheet of Object.keys(NAME)){
  const rows=await cutSheet(sheet);const id=NAME[sheet];meta[id]=[];
  const img=sharp(D+sheet+'.png');const info=await img.metadata();
  for(const r of rows)for(let i=0;i<r.cols.length;i++){
    const [x0,x1]=r.cols[i];const left=Math.max(0,x0-PAD),top=Math.max(0,r.y0-PAD-4);
    const width=Math.min(info.width,x1+PAD)-left,height=Math.min(info.height,r.y1+PAD+4)-top;
    const f=`cells/${id}_r${r.row}_c${i}.png`;
    await sharp(D+sheet+'.png').extract({left,top,width,height}).toFile(f);
    meta[id].push({row:r.row,col:i,file:f,left,top,width,height});
  }
  // contact sheet
  const H=230,tiles=[];let xs=[0,0];
  const comps=[];
  for(const m of meta[id]){
    const buf=await sharp(m.file).resize({height:H,fit:'inside'}).toBuffer();const mi=await sharp(buf).metadata();
    const x=xs[m.row];comps.push({input:buf,left:x+10,top:m.row*(H+30)+20});
    const svg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="60" height="22"><text x="2" y="16" font-size="16" fill="#fff" font-family="Arial" font-weight="bold">${m.row}.${m.col}</text></svg>`);
    comps.push({input:svg,left:x+10,top:m.row*(H+30)});
    xs[m.row]+=mi.width+14;
  }
  const w=Math.max(xs[0],xs[1])+20;
  await sharp({create:{width:w,height:2*(H+30)+10,channels:4,background:'#4f7d5a'}}).composite(comps).png().toFile(`contact_${id}.png`);
  console.log(id,'contact',w);
 }
 fs.writeFileSync('cells/meta.json',JSON.stringify(meta,null,1));
})();
