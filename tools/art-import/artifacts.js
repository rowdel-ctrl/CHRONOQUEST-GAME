// Cuts the 60 era artifact icons out of NEW ARTIFACTS.png (2026-11-08).
// Usage: node artifacts.js [canvas=128]   (needs the `sharp` package; see README.md)
// Sheet: 6 blocks top to bottom (one per era), each 2 rows x 5 icons, plus black
// title text under/over the icons that is thrown away. Output:
// assets/collectibles/artifact_<eraId>_<1..10>.png, one square transparent canvas
// for all 60, 256 colours. Also writes a contact sheet to C:/temp/artifacts_sheet.png.
const sharp = require('sharp');
const fs = require('fs');

const SRC = 'C:/Users/PC/Downloads/NEW ASSETS/NEW ARTIFACTS.png';
const DST = 'F:/CHRONO/CHRONO-GAMEAPP/assets/collectibles';
const SHEET = 'C:/temp/artifacts_sheet.png';
const ERAS = ['pre-colonial', 'spanish', 'nationalism', 'american', 'ww2', 'modern'];
const CANVAS = +process.argv[2] || 128;
const MARGIN = Math.round(CANVAS * 0.04); // keep icons off the very edge
const GAP = 24; // pieces closer than this (px) belong to one icon (flag fragment etc.)

(async () => {
  const { data, info } = await sharp(SRC).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const W = info.width, H = info.height;

  // 1. connected components of the alpha channel (8-neighbour)
  const lab = new Int32Array(W * H), stack = new Int32Array(W * H), cs = [];
  for (let i = 0; i < W * H; i++) {
    if (data[i * 4 + 3] <= 16 || lab[i]) continue;
    const id = cs.length + 1; let sp = 0; stack[sp++] = i; lab[i] = id;
    const c = { id, x0: W, y0: H, x1: 0, y1: 0, n: 0, dark: 0 };
    while (sp) {
      const p = stack[--sp], x = p % W, y = (p / W) | 0;
      c.n++; if (Math.max(data[p * 4], data[p * 4 + 1], data[p * 4 + 2]) < 70) c.dark++;
      if (x < c.x0) c.x0 = x; if (x > c.x1) c.x1 = x; if (y < c.y0) c.y0 = y; if (y > c.y1) c.y1 = y;
      for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
        const nx = x + dx, ny = y + dy; if (nx < 0 || ny < 0 || nx >= W || ny >= H) continue;
        const q = ny * W + nx; if (!lab[q] && data[q * 4 + 3] > 16) { lab[q] = id; stack[sp++] = q; }
      }
    }
    cs.push(c);
  }
  // 2. the title text is (nearly) pure black; icons are not. Drop it.
  // (also tiny dark specks, 40-160 px of outline left over beside some icons)
  const keep = cs.filter(c => c.dark / c.n <= 0.97 && !(c.n < 300 && c.dark / c.n > 0.7));

  // 3. group pieces that touch or are within GAP px into one icon
  const par = keep.map((_, i) => i), f = i => (par[i] === i ? i : (par[i] = f(par[i])));
  for (let i = 0; i < keep.length; i++) for (let j = i + 1; j < keep.length; j++) {
    const a = keep[i], b = keep[j];
    if (a.x0 - GAP <= b.x1 && b.x0 - GAP <= a.x1 && a.y0 - GAP <= b.y1 && b.y0 - GAP <= a.y1) par[f(i)] = f(j);
  }
  const groups = {};
  keep.forEach((c, i) => (groups[f(i)] ??= []).push(c));
  const icons = Object.values(groups).map(g => ({
    ids: new Set(g.map(c => c.id)),
    x0: Math.min(...g.map(c => c.x0)), y0: Math.min(...g.map(c => c.y0)),
    x1: Math.max(...g.map(c => c.x1)), y1: Math.max(...g.map(c => c.y1)),
  })).sort((a, b) => a.y0 - b.y0);
  if (icons.length !== 60) throw new Error('expected 60 icons, found ' + icons.length);

  // 4. reading order: 10 icons per era block, top row of 5 then bottom row of 5, left to right
  const sheetCells = [];
  let total = 0;
  for (let e = 0; e < 6; e++) {
    const block = icons.slice(e * 10, e * 10 + 10);
    const ordered = [
      ...block.slice(0, 5).sort((a, b) => a.x0 - b.x0),
      ...block.slice(5).sort((a, b) => a.x0 - b.x0),
    ];
    for (let k = 0; k < 10; k++) {
      const ic = ordered[k], w = ic.x1 - ic.x0 + 1, h = ic.y1 - ic.y0 + 1;
      // copy only this icon's own pieces (neighbours' pixels inside its box are dropped)
      const buf = Buffer.alloc(w * h * 4);
      for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
        const p = (ic.y0 + y) * W + ic.x0 + x;
        if (ic.ids.has(lab[p])) data.copy(buf, (y * w + x) * 4, p * 4, p * 4 + 4);
      }
      const inner = CANVAS - 2 * MARGIN, s = Math.min(inner / w, inner / h);
      const rw = Math.max(1, Math.round(w * s)), rh = Math.max(1, Math.round(h * s));
      const small = await sharp(buf, { raw: { width: w, height: h, channels: 4 } })
        .resize(rw, rh, { kernel: 'lanczos3', fit: 'fill' }).png().toBuffer();
      const out = await sharp({ create: { width: CANVAS, height: CANVAS, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
        .composite([{ input: small, left: Math.floor((CANVAS - rw) / 2), top: Math.floor((CANVAS - rh) / 2) }])
        .png({ palette: true, quality: 92, colours: 256, dither: 0.6, effort: 9, compressionLevel: 9 }).toBuffer();
      const name = `artifact_${ERAS[e]}_${k + 1}.png`;
      fs.writeFileSync(`${DST}/${name}`, out);
      total += out.length; sheetCells.push(out);
    }
  }
  console.log('60 icons,', CANVAS + 'x' + CANVAS, 'total', Math.round(total / 1024) + ' KB');

  // 5. contact sheet to look at: one row per era, 10 icons, grey background
  const cell = CANVAS, composites = sheetCells.map((b, i) => ({ input: b, left: (i % 10) * cell, top: Math.floor(i / 10) * cell }));
  fs.mkdirSync('C:/temp', { recursive: true });
  await sharp({ create: { width: cell * 10, height: cell * 6, channels: 4, background: '#808080' } })
    .composite(composites).png().toFile(SHEET);
})();
