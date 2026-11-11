#!/usr/bin/env node
'use strict';
// Marks every second soldier as a chaser in the .tmx files on disk, editing only
// the `behavior` value of those objects (nothing else in the file is touched, line
// endings included). Safe to run again: the result is the same. The rule lives in
// chasers.js, which the generator also uses.
//
//   node tools/levelgen/mark_chasers.js            # edit assets/tiles/levels
//   node tools/levelgen/mark_chasers.js --dry      # only report
const fs = require('fs');
const path = require('path');
const { eras, eraNumber } = require('./rules');
const { markChasers, hasChasers } = require('./chasers');

const LEVELS = path.join(__dirname, '..', '..', 'assets', 'tiles', 'levels');
const OBJECT = /<object\b[^>]*\btype="enemy"[^>]*>[\s\S]*?<\/object>/g;

// Returns { text, soldiers, chasers } for one map's text.
function markText(text, eraId, levelIndex) {
  const objs = [...text.matchAll(OBJECT)].map((m) => ({
    start: m.index, end: m.index + m[0].length, src: m[0],
    x: Number(m[0].match(/\bx="([^"]*)"/)[1]),
    kind: (m[0].match(/name="kind" value="([^"]*)"/) || [])[1],
    behavior: (m[0].match(/name="behavior" value="([^"]*)"/) || [])[1],
  }));
  const before = objs.map((o) => o.behavior);
  markChasers(objs, eraId, levelIndex);
  let out = '';
  let at = 0;
  objs.forEach((o, i) => {
    out += text.slice(at, o.start);
    out += o.behavior === before[i] ? o.src : o.src.replace(/(name="behavior" value=")[^"]*(")/, `$1${o.behavior}$2`);
    at = o.end;
  });
  out += text.slice(at);
  return { text: out, chasers: objs.filter((o) => o.behavior === 'chaser').length };
}

function main(argv) {
  const dry = argv.includes('--dry');
  for (const era of eras) {
    for (let n = 3; n < era.levelWeeks.length; n++) { // below the length: never the boss room
      if (!hasChasers(era.id, n)) continue;
      const file = path.join(LEVELS, `era${eraNumber(era.id)}_${n}.tmx`);
      const text = fs.readFileSync(file, 'utf8');
      const r = markText(text, era.id, n);
      const soldiers = [...text.matchAll(OBJECT)].filter((m) => /name="kind" value="(spanish_soldier|japanese_soldier)"/.test(m[0])).length;
      if (!dry && r.text !== text) fs.writeFileSync(file, r.text);
      console.log(`${path.basename(file)} (${era.id} ${n}): ${r.chasers} of ${soldiers} soldiers are chasers${r.text !== text ? (dry ? ' (would change)' : ' (changed)') : ''}`);
    }
  }
}

if (require.main === module) main(process.argv.slice(2));
module.exports = { markText };
