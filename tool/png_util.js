// Minimal, dependency-free PNG decoder (8-bit RGB/RGBA, non-interlaced —
// which is exactly what cdp_shot.js's `shot:` step produces via
// Page.captureScreenshot). Turns a screenshot into an actual pixel-value
// comparison instead of an eyeballed one.
//
// Usage (from a one-off `node -e` script or a throwaway file):
//   const { decodePNG, meanRGB, rgbDistance, pixelDiff } = require('./png_util.js');
//   const img = decodePNG(fs.readFileSync('shot.png'));
//   meanRGB(img, x0, y0, x1, y1)        // average colour of a region
//   rgbDistance(meanA, meanB)           // how different two colours are
//   pixelDiff(imgA, imgB)               // { diffFraction, meanAbsDiff } between two same-size shots
//
// First real use: quantitatively confirming the six GAMEPLAY-V2 era tints
// are actually distinct (mean-colour distance per era pair, cross-checked
// against a same-era reshoot as a noise floor) and counting level-select
// nodes by their era-independent opaque fill colour (AppColors.primary /
// Colors.grey.shade700 / AppColors.accent don't blend with the era's own
// background gradient the way the alpha-blended connector and border do,
// which is what makes exact-colour matching work across all six colour
// schemes with no per-era tuning) — see HANDOFF.md for both.
const zlib = require('zlib');

function decodePNG(buf) {
  if (buf.readUInt32BE(0) !== 0x89504e47) throw new Error('not a PNG');
  let offset = 8;
  let width, height, bitDepth, colorType;
  const idat = [];
  while (offset < buf.length) {
    const len = buf.readUInt32BE(offset);
    const type = buf.toString('ascii', offset + 4, offset + 8);
    const data = buf.subarray(offset + 8, offset + 8 + len);
    if (type === 'IHDR') {
      width = data.readUInt32BE(0);
      height = data.readUInt32BE(4);
      bitDepth = data.readUInt8(8);
      colorType = data.readUInt8(9);
    } else if (type === 'IDAT') {
      idat.push(data);
    } else if (type === 'IEND') {
      break;
    }
    offset += 12 + len;
  }
  if (bitDepth !== 8) throw new Error(`unsupported bit depth ${bitDepth}`);
  const channels = { 0: 1, 2: 3, 3: 1, 4: 2, 6: 4 }[colorType];
  if (colorType !== 6 && colorType !== 2) {
    throw new Error(`unsupported color type ${colorType}`);
  }
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const stride = width * channels;
  const pixels = Buffer.alloc(height * width * 4, 255); // normalize to RGBA
  let pos = 0;
  let prevRow = Buffer.alloc(stride);
  for (let y = 0; y < height; y++) {
    const filter = raw[pos++];
    const row = raw.subarray(pos, pos + stride);
    pos += stride;
    const out = Buffer.alloc(stride);
    for (let x = 0; x < stride; x++) {
      const a = x >= channels ? out[x - channels] : 0;
      const b = prevRow[x];
      const c = x >= channels ? prevRow[x - channels] : 0;
      let pred;
      switch (filter) {
        case 0: pred = 0; break;
        case 1: pred = a; break;
        case 2: pred = b; break;
        case 3: pred = Math.floor((a + b) / 2); break;
        case 4: {
          const p = a + b - c;
          const pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
          pred = (pa <= pb && pa <= pc) ? a : (pb <= pc ? b : c);
          break;
        }
        default: throw new Error(`bad filter ${filter}`);
      }
      out[x] = (row[x] + pred) & 0xff;
    }
    for (let x = 0; x < width; x++) {
      const si = x * channels;
      const di = (y * width + x) * 4;
      if (channels === 4) {
        pixels[di] = out[si]; pixels[di + 1] = out[si + 1];
        pixels[di + 2] = out[si + 2]; pixels[di + 3] = out[si + 3];
      } else if (channels === 3) {
        pixels[di] = out[si]; pixels[di + 1] = out[si + 1];
        pixels[di + 2] = out[si + 2]; pixels[di + 3] = 255;
      }
    }
    prevRow = out;
  }
  return { width, height, pixels }; // pixels: RGBA Buffer, row-major
}

function getPixel(img, x, y) {
  const i = (y * img.width + x) * 4;
  return [img.pixels[i], img.pixels[i + 1], img.pixels[i + 2], img.pixels[i + 3]];
}

// Mean RGB over a rectangular region, sampled on a grid (step>1 to keep it fast).
function meanRGB(img, x0, y0, x1, y1, step = 4) {
  let r = 0, g = 0, b = 0, n = 0;
  for (let y = y0; y < y1; y += step) {
    for (let x = x0; x < x1; x += step) {
      const [pr, pg, pb] = getPixel(img, x, y);
      r += pr; g += pg; b += pb; n++;
    }
  }
  return [r / n, g / n, b / n];
}

function rgbDistance(a, b) {
  return Math.sqrt((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2);
}

// Full pixel-diff between two same-size images: fraction of pixels whose
// per-channel difference exceeds `threshold`, plus mean absolute diff.
function pixelDiff(imgA, imgB, threshold = 12) {
  if (imgA.width !== imgB.width || imgA.height !== imgB.height) {
    throw new Error('size mismatch');
  }
  let diffCount = 0;
  let sumAbsDiff = 0;
  const total = imgA.width * imgA.height;
  for (let i = 0; i < total * 4; i += 4) {
    const dr = Math.abs(imgA.pixels[i] - imgB.pixels[i]);
    const dg = Math.abs(imgA.pixels[i + 1] - imgB.pixels[i + 1]);
    const db = Math.abs(imgA.pixels[i + 2] - imgB.pixels[i + 2]);
    const avg = (dr + dg + db) / 3;
    sumAbsDiff += avg;
    if (dr > threshold || dg > threshold || db > threshold) diffCount++;
  }
  return { diffFraction: diffCount / total, meanAbsDiff: sumAbsDiff / total };
}

module.exports = { decodePNG, getPixel, meanRGB, rgbDistance, pixelDiff };
