'use strict';
// Builds the Grade 6 era files (Himagsikan at Imperyalismong Amerikano, Pamahalaang Kolonyal at
// Pananakop ng Hapon, Batas Militar at Muling Pagbangon ng Demokrasya) from the question sources in
// tools/questions/grade6/term4.js .. term6.js, with the same layout as import_terms.js (10 questions
// per lesson, the last lesson is the boss with 22).
//
//   node tools/questions/generate_grade6.js
//
// The correct answer is placed in a rotating position so the key is not guessable.
const fs = require('fs');
const path = require('path');
const { buildEra, LESSON_QUESTIONS } = require('./import_terms');

const ROOT = path.resolve(__dirname, '..', '..');
const TERMS = [require('./grade6/term4'), require('./grade6/term5'), require('./grade6/term6')];

for (const term of TERMS) {
  let n = 0;
  const lessons = term.lessons.map((lesson, li) => {
    if (lesson.qs.length !== LESSON_QUESTIONS) throw new Error(`${term.era} lesson ${li + 1} has ${lesson.qs.length}`);
    return {
      title: lesson.title,
      questions: lesson.qs.map(([text, correct, wrong, explanation], k) => {
        if (wrong.length !== 3) throw new Error(`${term.era} lesson ${li + 1} #${k + 1}: needs 3 wrong answers`);
        const slot = (n++ * 3 + li) % 4; // rotates through A..D
        const options = [...wrong];
        options.splice(slot, 0, correct);
        return { number: k + 1, text, options, answer: 'ABCD'[slot], explanation };
      }),
    };
  });
  const era = buildEra({ era: term.era, prefix: term.prefix, grade: 'grade6' }, lessons);
  const out = path.join(ROOT, 'assets', 'data', `questions_${term.era}.json`);
  fs.writeFileSync(out, JSON.stringify(era, null, 2) + '\n');
  const total = Object.values(era).reduce((a, l) => a + l.length, 0);
  const tally = { A: 0, B: 0, C: 0, D: 0 };
  Object.values(era).flat().forEach((q) => tally[q.correctAnswer]++);
  console.log(`${term.era}: ${lessons.length} levels, ${total} questions, answers ${JSON.stringify(tally)}`);
}
