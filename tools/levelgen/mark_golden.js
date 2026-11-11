#!/usr/bin/env node
'use strict';
// Marks the golden artifact in the .tmx files on disk: from level 2 on (never the first
// level, never a boss room) the artifact in the middle of the level, counted left to
// right, gets `<property name="golden" type="bool" value="true"/>`, and no other artifact
// has it. Nothing else in the file is touched, line endings included. Safe to run again:
// the result is the same. The rule lives in golden.js, which the generator also uses, so
// a regenerated map keeps the mark.
//
//   node tools/levelgen/mark_golden.js            # edit assets/tiles/levels
//   node tools/levelgen/mark_golden.js --dry      # only report
const fs = require('fs');
const path = require('path');
const { eras, eraNumber } = require('./rules');
const { markGolden } = require('./golden');

const LEVELS = path.join(__dirname, '..', '..', 'assets', 'tiles', 'levels');
const ARTIFACT = /<object\b[^>]*\btype="artifact"[^>]*>[\s\S]*?<\/object>/g;
const GOLDEN_LINE = /\r?\n[ \t]*<property name="golden"[^>]*\/>/;

// Returns { text, golden } for one map's text: how many artifacts are golden after.
function markText(text, levelIndex, levelCount) {
  const eol = text.includes('\r\n') ? '\r\n' : '\n';
  const objs = [...text.matchAll(ARTIFACT)].map((m) => ({
    start: m.index, end: m.index + m[0].length, src: m[0],
    x: Number(m[0].match(/\bx="([^"]*)"/)[1]),
    golden: GOLDEN_LINE.test(m[0]),
  }));
  const before = objs.map((o) => o.golden);
  markGolden(objs, levelIndex, levelCount);
  let out = '';
  let at = 0;
  objs.forEach((o, i) => {
    out += text.slice(at, o.start);
    let src = o.src;
    if (!!o.golden !== before[i]) {
      src = o.golden
        ? src.replace(/(<property name="art" value="[^"]*"\/>)/, `$1${eol}    <property name="golden" type="bool" value="true"/>`)
        : src.replace(GOLDEN_LINE, '');
    }
    out += src;
    at = o.end;
  });
  out += text.slice(at);
  return { text: out, golden: objs.filter((o) => o.golden).length };
}

function main(argv) {
  const dry = argv.includes('--dry');
  for (const era of eras) {
    const count = era.levelWeeks.length;
    for (let n = 1; n < count; n++) { // below the length: never the boss room
      const file = path.join(LEVELS, `era${eraNumber(era.id)}_${n}.tmx`);
      const text = fs.readFileSync(file, 'utf8');
      const r = markText(text, n, count);
      if (!dry && r.text !== text) fs.writeFileSync(file, r.text);
      console.log(`${path.basename(file)} (${era.id} ${n}): ${r.golden} golden${r.text !== text ? (dry ? ' (would change)' : ' (changed)') : ''}`);
    }
  }
}

if (require.main === module) main(process.argv.slice(2));
module.exports = { markText };
