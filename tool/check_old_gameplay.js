// Proves the platformer was not touched while the new gameplay is built.
//
//   node tool/check_old_gameplay.js            compare lib/game + test/game with the baseline
//   node tool/check_old_gameplay.js --update   write a new baseline (only when the user
//                                              asks for a change to the old gameplay)
//
// The baseline (tool/old_gameplay.baseline.json) holds a SHA-1 per file, taken from the
// commit tagged `before-quest-gameplay`. Exit code 1 lists every file that changed,
// appeared or disappeared.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const root = path.resolve(__dirname, '..');
const baselineFile = path.join(__dirname, 'old_gameplay.baseline.json');
const dirs = ['lib/game', 'test/game'];

function walk(dir, out = []) {
  for (const e of fs.readdirSync(path.join(root, dir), { withFileTypes: true })) {
    const p = `${dir}/${e.name}`;
    if (e.isDirectory()) walk(p, out);
    else out.push(p);
  }
  return out;
}

const now = {};
for (const d of dirs) {
  if (!fs.existsSync(path.join(root, d))) continue;
  for (const f of walk(d).sort()) {
    now[f] = crypto.createHash('sha1').update(fs.readFileSync(path.join(root, f))).digest('hex');
  }
}

if (process.argv.includes('--update')) {
  fs.writeFileSync(baselineFile, JSON.stringify(now, null, 1) + '\n');
  console.log(`baseline written: ${Object.keys(now).length} files`);
  process.exit(0);
}

const base = JSON.parse(fs.readFileSync(baselineFile, 'utf8'));
const bad = [];
for (const f of new Set([...Object.keys(base), ...Object.keys(now)])) {
  if (!(f in now)) bad.push(`removed  ${f}`);
  else if (!(f in base)) bad.push(`added    ${f}`);
  else if (base[f] !== now[f]) bad.push(`changed  ${f}`);
}
if (bad.length) {
  console.error(`OLD GAMEPLAY CHANGED (${bad.length}):\n  ${bad.join('\n  ')}`);
  process.exit(1);
}
console.log(`old gameplay untouched: ${Object.keys(now).length} files match the baseline`);
