'use strict';
// Imports the game's questions from the "Term N Final.docx" files (the PISA-type questions section at
// the end of each: 10 multiple-choice questions per lesson, with the correct answer marked) into
// assets/data/questions_<era>.json.
//
//   node tools/questions/import_terms.js <folder holding the .docx files>
//
// A term whose file is missing is skipped and its era file is left as it is. Lesson N of a term is
// level N of its era. The last lesson is the boss level, which asks 22 questions: its own 10 plus 12
// reused from the earlier lessons (spread evenly), given their own ids so a teacher can edit them
// without touching the lesson they came from.
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const ROOT = path.resolve(__dirname, '..', '..');
const BOSS_QUESTIONS = 22;
const LESSON_QUESTIONS = 10;

const TERMS = [
  { file: 'Term 1 Final.docx', era: 'pre-colonial', prefix: 'pre', grade: 'grade5' },
  { file: 'Term 2 Final.docx', era: 'spanish', prefix: 'spa', grade: 'grade5' },
  { file: 'Term 3 Final.docx', era: 'nationalism', prefix: 'nat', grade: 'grade5' },
  { file: 'Term 4 Final.docx', era: 'american', prefix: 'ame', grade: 'grade6' },
  { file: 'Term 5 Final.docx', era: 'ww2', prefix: 'ww2', grade: 'grade6' },
  { file: 'Term 6 Final.docx', era: 'modern', prefix: 'mod', grade: 'grade6' },
];

// ── reading a .docx (a zip) without a library ───────────────────────────────

function readZipEntry(buf, name) {
  let eocd = buf.length - 22;
  while (eocd >= 0 && buf.readUInt32LE(eocd) !== 0x06054b50) eocd--;
  if (eocd < 0) throw new Error('not a zip file');
  const count = buf.readUInt16LE(eocd + 10);
  let p = buf.readUInt32LE(eocd + 16);
  for (let i = 0; i < count; i++) {
    const method = buf.readUInt16LE(p + 10);
    const size = buf.readUInt32LE(p + 20);
    const nameLen = buf.readUInt16LE(p + 28);
    const extraLen = buf.readUInt16LE(p + 30);
    const commentLen = buf.readUInt16LE(p + 32);
    const offset = buf.readUInt32LE(p + 42);
    if (buf.toString('utf8', p + 46, p + 46 + nameLen) === name) {
      const start = offset + 30 + buf.readUInt16LE(offset + 26) + buf.readUInt16LE(offset + 28);
      const data = buf.subarray(start, start + size);
      return method === 0 ? data : zlib.inflateRawSync(data);
    }
    p += 46 + nameLen + extraLen + commentLen;
  }
  throw new Error(`${name} is not in the file`);
}

const decode = (s) => s
  .replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&apos;/g, "'")
  .replace(/&#(\d+);/g, (_, n) => String.fromCodePoint(Number(n)))
  .replace(/&#x([0-9a-f]+);/gi, (_, n) => String.fromCodePoint(parseInt(n, 16)));

/** The paragraphs of a .docx, one per line. */
function docxLines(file) {
  const xml = readZipEntry(fs.readFileSync(file), 'word/document.xml').toString('utf8')
    .replace(/<w:tab\/>/g, ' ')
    .replace(/<w:br[^>]*\/>/g, '\n')
    .replace(/<\/w:tc>/g, ' | ')
    .replace(/<\/w:p>/g, '\n')
    .replace(/<[^>]+>/g, '');
  return decode(xml).split('\n').map((l) => l.replace(/\s*\|\s*$/, '')).filter((l) => l.trim());
}

// ── parsing the question section ────────────────────────────────────────────

const tidy = (s) => s.replace(/ /g, ' ').replace(/\s+/g, ' ').replace(/\(\s+/g, '(').replace(/\s+\)/g, ')').trim();
const same = (a, b) => tidy(a).toLowerCase() === tidy(b).toLowerCase();

/** [{ title, questions: [{ number, text, options: [4 strings], answer: 'A'..'D' }] }], and any warnings. */
function parseQuestions(lines) {
  const start = lines.findIndex((l) => l.startsWith('PISA-Type'));
  if (start < 0) throw new Error('no "PISA-Type" questions section');
  const lessons = [];
  const warnings = [];
  let q = null;

  const finish = (keyLine) => {
    const lesson = lessons[lessons.length - 1];
    const where = `${lesson.title.slice(0, 40)} #${q.number}`;
    const labels = q.options.map((o) => o.label).join('');
    if (labels !== 'ABCD') warnings.push(`${where}: choices are ${labels || 'missing'}, expected ABCD`);
    const m = keyLine.match(/^Correct Answer:\s*([A-D])\.?\s*(.*)$/);
    if (!m) throw new Error(`${where}: cannot read "${keyLine}"`);
    const chosen = q.options.find((o) => o.label === m[1]);
    if (!chosen) throw new Error(`${where}: the answer ${m[1]} is not a choice`);
    if (m[2] && !same(chosen.text, m[2])) {
      warnings.push(`${where}: key says "${tidy(m[2])}" but choice ${m[1]} is "${chosen.text}"; kept the letter`);
    }
    lesson.questions.push({
      number: q.number,
      text: tidy(q.stem.join(' ')),
      options: q.options.map((o) => o.text),
      answer: m[1],
    });
    q = null;
  };

  for (const line of lines.slice(start + 1)) {
    const lesson = line.match(/^LINGGO [0-9][^:]*:\s*(.+)$/);
    if (lesson) { lessons.push({ title: tidy(lesson[1]), questions: [] }); q = null; continue; }
    if (!lessons.length) continue;
    if (/^Correct Answer:/.test(line)) { if (q) finish(line.trim()); continue; }
    const start1 = line.match(/^(\d+)\.\s+(.*)$/);
    const option = line.match(/^\s*([A-D])\.\s*(.*)$/);
    if (option && q) { q.options.push({ label: option[1], text: tidy(option[2]) }); continue; }
    if (start1 && (!q || q.options.length)) { q = { number: Number(start1[1]), stem: [start1[2]], options: [] }; continue; }
    if (q && !q.options.length) q.stem.push(line);
  }
  return { lessons, warnings };
}

// ── building the era file ───────────────────────────────────────────────────

function buildEra({ era, prefix, grade }, lessons) {
  const make = (lesson, q, level, n) => ({
    id: `${prefix}_${level}_${n}`,
    era,
    subTopic: lesson.title,
    gradeLevel: grade,
    level,
    difficulty: 'medium',
    questionType: 'multiple_choice',
    questionText: q.text,
    options: q.options.map((text, i) => ({ label: 'ABCD'[i], text })),
    correctAnswer: q.answer,
    explanation: q.explanation || '',
  });

  const out = {};
  lessons.forEach((lesson, i) => {
    out[String(i + 1)] = lesson.questions.map((q, k) => make(lesson, q, i + 1, k + 1));
  });

  // The boss level: its own lesson, then a spread of the earlier lessons.
  const boss = lessons.length;
  const earlier = lessons.slice(0, -1);
  const extras = [];
  for (let round = 0; extras.length < BOSS_QUESTIONS - LESSON_QUESTIONS && earlier.length; round++) {
    for (let li = 0; li < earlier.length && extras.length < BOSS_QUESTIONS - LESSON_QUESTIONS; li++) {
      const from = earlier[li].questions;
      extras.push(make(earlier[li], from[(round * 3 + li) % from.length], boss, LESSON_QUESTIONS + extras.length + 1));
    }
  }
  out[String(boss)].push(...extras);
  return out;
}

function main() {
  const dir = process.argv[2];
  if (!dir) { console.error('usage: node tools/questions/import_terms.js <folder with the Term N Final.docx files>'); process.exit(1); }
  let imported = 0;
  for (const term of TERMS) {
    const file = path.join(dir, term.file);
    if (!fs.existsSync(file)) { console.log(`skipped ${term.era}: no ${term.file}`); continue; }
    const { lessons, warnings } = parseQuestions(docxLines(file));
    const bad = lessons.filter((l) => l.questions.length !== LESSON_QUESTIONS);
    if (bad.length) throw new Error(`${term.era}: ${bad.map((l) => `${l.title.slice(0, 30)} has ${l.questions.length}`).join('; ')} (expected ${LESSON_QUESTIONS} each)`);
    const era = buildEra(term, lessons);
    const out = path.join(ROOT, 'assets', 'data', `questions_${term.era}.json`);
    fs.writeFileSync(out, JSON.stringify(era, null, 2) + '\n');
    const total = Object.values(era).reduce((n, l) => n + l.length, 0);
    console.log(`${term.era}: ${lessons.length} levels, ${total} questions (boss level ${lessons.length} has ${era[String(lessons.length)].length}) -> ${path.relative(ROOT, out)}`);
    warnings.forEach((w) => console.log(`  warning: ${w}`));
    imported++;
  }
  console.log(`imported ${imported} of ${TERMS.length} terms`);
}

module.exports = { parseQuestions, buildEra, docxLines, BOSS_QUESTIONS, LESSON_QUESTIONS };
if (require.main === module) main();
