const sharp=require('sharp');const fs=require('fs');const D=require('path').join(__dirname,'../../new-assets')+'/';
const {runs}=require('./seg2.js');
const BANDS={
 BOY:[[936,1272],[1464,1812]],GIRL:[[896,1210],[1420,1744]],LAPU:[[786,1096],[1184,1454]],LUNA:[[672,982],[1068,1378]],
 RIZAL:[[684,958],[1040,1326]],BONIFACIO:[[764,1090],[1130,1450]],'DEL PILAR':[[966,1316],[1456,1826]]};
const NAME={BOY:'boy',GIRL:'girl',LAPU:'lapu',LUNA:'luna',RIZAL:'rizal',BONIFACIO:'bonifacio','DEL PILAR':'delpilar'};
async function cutSheet(sheet){
  const {data,info}=await sharp(D+sheet+'.png').raw().toBuffer({resolveWithObject:true});const W=info.width;
  const out=[];
  for(let r=0;r<2;r++){
    const [y0,y1]=BANDS[sheet][r];const colP=new Array(W).fill(0);
    for(let x=4;x<W-4;x++){let c=0;for(let y=y0;y<y1;y++)if(data[(y*W+x)*4+3]>100)c++;colP[x]=c;}
    let cols=runs(colP,14,0).filter(c=>c[1]-c[0]>=14);
    while(cols.length>6){ // merge closest pair
      let bi=0,bg=1e9;for(let i=0;i<cols.length-1;i++){const g=cols[i+1][0]-cols[i][1];if(g<bg){bg=g;bi=i;}}
      cols.splice(bi,2,[cols[bi][0],cols[bi+1][1]]);}
    out.push({row:r,y0,y1,cols});
  }
  return out;
}
module.exports={cutSheet,BANDS,NAME};
if(require.main===module)(async()=>{
 for(const s of Object.keys(BANDS)){const o=await cutSheet(s);console.log(s,o.map(r=>r.cols.length+': '+r.cols.map(c=>c[0]+'-'+c[1]).join(' ')).join(' | '));}
})();
