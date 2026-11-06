const sharp=require('sharp');const fs=require('fs');const D='C:/Users/PC/Downloads/NEW ASSETS/';
const {bandsFor}=require('./cutEB2.js');
const {prepFrame,place,extents,OUT}=require('./build.js');
fs.mkdirSync('cells_eb',{recursive:true});
const ENEMY=['tribal_warrior','dark_spirit','spanish_soldier','tax_collector','propaganda','american_soldier','japanese_soldier','tank','corruption_figure','misinfo_cloud'];
const BOSS=['bakunawa','governor','general','commander','corruption_boss'];
async function colDensity(sheet,y0,y1,x0,x1){const {data,info}=await sharp(D+sheet+'.png').extract({left:x0,top:y0,width:x1-x0,height:y1-y0}).raw().toBuffer({resolveWithObject:true});const W=info.width,H=info.height;const d=[];for(let x=0;x<W;x++){let c=0;for(let y=0;y<H;y++)if(data[(y*W+x)*4+3]>30)c++;d.push(c);}return d;}
async function cells(sheet,names,opts){
  const bands=await bandsFor(sheet,opts);const meta=await sharp(D+sheet+'.png').metadata();const res=[];
  for(let r=0;r<bands.length;r++){
    let cols=bands[r].cols;
    if(cols.length===5){ // split the widest merged cell at its emptiest column
      let wi=0,ww=0;cols.forEach((c,i)=>{if(c[1]-c[0]>ww){ww=c[1]-c[0];wi=i;}});
      const [a,b]=cols[wi];const d=await colDensity(sheet,bands[r].y0,bands[r].y1,a,b);
      const lo=Math.floor(d.length*0.3),hi=Math.floor(d.length*0.8);let bx=lo,bv=1e9;for(let x=lo;x<hi;x++)if(d[x]<bv){bv=d[x];bx=x;}
      cols=[...cols.slice(0,wi),[a,a+bx],[a+bx,b],...cols.slice(wi+1)];
    }
    const yTop=r>0?Math.round((bands[r-1].y1+bands[r].y0)/2):Math.max(0,bands[r].y0-8),yBot=r<bands.length-1?Math.round((bands[r].y1+bands[r+1].y0)/2):Math.min(meta.height,bands[r].y1+8);
    for(let i=0;i<cols.length;i++){
      const xl=i>0?Math.round((cols[i-1][1]+cols[i][0])/2):Math.max(0,cols[i][0]-8),xr=i<cols.length-1?Math.round((cols[i][1]+cols[i+1][0])/2):Math.min(meta.width,cols[i][1]+8);
      const f=`cells_eb/${names[r]}_${i}.png`;
      await sharp(D+sheet+'.png').extract({left:xl,top:yTop,width:xr-xl,height:yBot-yTop}).toFile(f);
    }
    res.push({name:names[r],n:cols.length});
  }
  return res;
}
module.exports={cells,ENEMY,BOSS};
if(require.main===module)(async()=>{
  console.log(JSON.stringify(await cells('ENEMIES',ENEMY,{expectRows:10})));
  console.log(JSON.stringify(await cells('BOSSES',BOSS,{expectRows:5,rowGap:10})));
})();
