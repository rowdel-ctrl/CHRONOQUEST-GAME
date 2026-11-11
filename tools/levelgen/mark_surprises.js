#!/usr/bin/env node
'use strict';
// Puts the surprises into the .tmx files on disk: marks the hoppers, throwers and the
// golden runner (the `behavior` value of existing enemies) and adds or removes the
// `ground_pop` and `falling_rock` objects. The rules live in surprises.js, which the
// generator also uses, so a regenerated map gets the same marks.
//
// Only the entities object layer is touched, and only what it has to be: an enemy whose
// mark changes gets its `behavior` value replaced, a stale surprise object goes, a new one
// is put in x order, and the object ids are renumbered 1, 2, 3 ... in file order (which is
// what the generator writes, so a marked map is the same text the generator makes).
// Objects it does not know (a portal, say) are kept as they are. Line endings are kept.
// Safe to run again: a second run changes nothing.
//
//   node tools/levelgen/mark_surprises.js            # edit assets/tiles/levels
//   node tools/levelgen/mark_surprises.js --dry      # only report
const fs = require('fs');
const path = require('path');
const { eras, eraNumber } = require('./rules');
const tmx = require('./tmx');
const { markSurprises } = require('./surprises');

const LEVELS = path.join(__dirname, '..', '..', 'assets', 'tiles', 'levels');
const OBJECT = /<object\b[^>]*?(?:\/>|>[\s\S]*?<\/object>)/g;
const ITEM_TYPES = new Set(['coin', 'artifact', 'enemy', 'platform', 'ground_pop', 'falling_rock']);
const SURPRISE_TYPES = new Set(['ground_pop', 'falling_rock']);
const attr = (s, name) => (s.match(new RegExp(`\\b${name}="([^"]*)"`)) || [])[1];

// Returns { text, counts } for one map's text.
function markText(original, eraId, levelIndex) {
  const crlf = original.includes('\r\n');
  const text = crlf ? original.replace(/\r\n/g, '\n') : original;
  const level = tmx.read(text);
  const before = level.enemies.map((e) => e.behavior);
  const counts = markSurprises(level, eraId, levelIndex);

  const group = text.match(/( <objectgroup[^>]*name="entities">\n)([\s\S]*?\n)( <\/objectgroup>)/);
  if (!group) throw new Error('no entities layer');
  const region = group[2];
  let blocks = [...region.matchAll(OBJECT)].map((m) => {
    const head = m[0].match(/<object\b[^>]*>/)[0];
    return { src: m[0], type: attr(head, 'type'), x: Number(attr(head, 'x')) };
  });

  // Enemy marks: the i-th enemy block is the i-th enemy tmx.read found.
  let ei = 0;
  for (const b of blocks) {
    if (b.type !== 'enemy') continue;
    const now = level.enemies[ei].behavior;
    if (now !== before[ei]) b.src = b.src.replace(/(name="behavior" value=")[^"]*(")/, `$1${now}$2`);
    ei++;
  }

  // Surprise objects: drop the old ones, put the new ones in x order.
  blocks = blocks.filter((b) => !SURPRISE_TYPES.has(b.type));
  for (const s of level.surprises) {
    const nb = { src: `<object id="0" type="${s.type}" x="${s.x}" y="${s.y}"/>`, type: s.type, x: s.x };
    let last = -1, first = -1;
    blocks.forEach((b, i) => {
      if (!ITEM_TYPES.has(b.type)) return;
      if (first < 0) first = i;
      if (b.x <= s.x) last = i;
    });
    const at = last >= 0 ? last + 1 : first >= 0 ? first : blocks.length;
    blocks.splice(at, 0, nb);
  }

  // Ids 1, 2, 3 ... in file order, as the generator writes them. Only when something changed.
  const noId = (src) => src.replace(/(<object\b[^>]*?\bid=")\d+(")/, '$1$2');
  const changed =
    blocks.map((b) => noId(b.src)).join('\n') !== [...region.matchAll(OBJECT)].map((m) => noId(m[0])).join('\n');
  if (!changed) return { text: original, counts, changed: false };
  blocks.forEach((b, i) => { b.src = b.src.replace(/(<object\b[^>]*?\bid=")\d+(")/, `$1${i + 1}$2`); });
  const newRegion = blocks.map((b) => '  ' + b.src + '\n').join('');
  let out = text.replace(group[0], group[1] + newRegion + group[3]);
  out = out.replace(/nextobjectid="\d+"/, `nextobjectid="${blocks.length + 1}"`);
  return { text: crlf ? out.replace(/\n/g, '\r\n') : out, counts, changed: true };
}

function main(argv) {
  const dry = argv.includes('--dry');
  for (const era of eras) {
    for (let n = 1; n < era.levelWeeks.length; n++) { // below the length: never the boss room
      const file = path.join(LEVELS, `era${eraNumber(era.id)}_${n}.tmx`);
      const text = fs.readFileSync(file, 'utf8');
      if (/name="handEdited" value="true"/.test(text)) { console.log(`${path.basename(file)}: skipped (handEdited)`); continue; }
      const r = markText(text, era.id, n);
      if (!dry && r.changed) fs.writeFileSync(file, r.text);
      const c = r.counts;
      if (n >= 4 || r.changed) {
        console.log(`${path.basename(file)} (${era.id} ${n}): hoppers ${c.hoppers}, pops ${c.pops}, rocks ${c.rocks}, throwers ${c.throwers}, golden ${c.golden}${r.changed ? (dry ? ' (would change)' : ' (changed)') : ''}`);
      }
    }
  }
}

if (require.main === module) main(process.argv.slice(2));
module.exports = { markText };
