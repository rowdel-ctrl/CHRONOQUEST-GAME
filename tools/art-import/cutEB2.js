const sharp=require('sharp');const D=require('path').join(__dirname,'../../new-assets')+'/';
const {runs}=require('./seg2.js');
async function bandsFor(sheet,{rowThr=100,colThr=200,rowGap=24,colGap=16,expectRows}={}){
  const {data,info}=await sharp(D+sheet+'.png').raw().toBuffer({resolveWithObject:true});const W=info.width,H=info.height;
  const rowP=new Array(H).fill(0);
  for(let y=0;y<H;y++){let c=0;for(let x=4;x<W-4;x++)if(data[(y*W+x)*4+3]>rowThr)c++;rowP[y]=c;}
  let bands=runs(rowP,rowGap,3).filter(b=>b[1]-b[0]>=60);
  while(bands.length>expectRows){let bi=0,bg=1e9;for(let i=0;i<bands.length-1;i++){const g=bands[i+1][0]-bands[i][1];if(g<bg){bg=g;bi=i;}}bands.splice(bi,2,[bands[bi][0],bands[bi+1][1]]);}
  return bands.map(([y0,y1])=>{
    const colP=new Array(W).fill(0);for(let x=4;x<W-4;x++){let c=0;for(let y=y0;y<y1;y++)if(data[(y*W+x)*4+3]>colThr)c++;colP[x]=c;}
    let cols=runs(colP,colGap,0).filter(c=>c[1]-c[0]>=14);
    while(cols.length>6){let bi=0,bg=1e9;for(let i=0;i<cols.length-1;i++){const g=cols[i+1][0]-cols[i][1];if(g<bg){bg=g;bi=i;}}cols.splice(bi,2,[cols[bi][0],cols[bi+1][1]]);}
    return {y0,y1,cols};});
}
module.exports={bandsFor};
if(require.main===module)(async()=>{
  for(const [s,n,o] of [['ENEMIES',10,{}],['BOSSES',5,{rowGap:10}]]){const b=await bandsFor(s,{expectRows:n,...o});console.log(s,b.length);b.forEach((r,i)=>console.log(' row',i,r.y0+'-'+r.y1,'n',r.cols.length,r.cols.map(c=>c[0]+'-'+c[1]).join(' ')));}
})();
