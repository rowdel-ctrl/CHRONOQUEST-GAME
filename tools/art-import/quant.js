const sharp=require('sharp');const fs=require('fs');const path=require('path');
(async()=>{let before=0,after=0;
 for(const dir of ['characters','enemies','bosses']){
  const dst=`F:/CHRONO/CHRONO-GAMEAPP/assets/${dir}`;
  for(const f of fs.readdirSync(`out/${dir}`).filter(f=>f.endsWith('.png'))){
    const src=`out/${dir}/${f}`;before+=fs.statSync(src).size;
    const buf=await sharp(src).png({palette:true,quality:92,colours:256,dither:0.6,effort:9,compressionLevel:9}).toBuffer();
    fs.writeFileSync(path.join(dst,f),buf);after+=buf.length;
  }}
 console.log('before',(before/1e6).toFixed(1)+'MB','after',(after/1e6).toFixed(1)+'MB');
})();
