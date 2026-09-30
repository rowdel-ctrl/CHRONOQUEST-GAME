// QuestionPool is Phase 3's replacement for QuestionBank's flat-list draw
// (GAMEPLAY-V2.md Section 14). Two acceptance criteria live here:
// "no question repeats within one attempt until the pool is exhausted" and
// the artifact re-serving "a genuinely different question" on retry.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/data/question_pool.dart';
import 'package:chronoquest/models/question.dart';

Question _q(String id) => Question(
      id: id,
      era: 'spanish',
      level: 1,
      questionText: 'Q$id',
      options: const [
        QuestionOption(label: 'A', text: 'right'),
        QuestionOption(label: 'B', text: 'wrong'),
      ],
      correctAnswer: 'right',
      explanation: 'because',
    );

QuestionPool _pool(int n, {int seed = 1}) => QuestionPool(
      questions: List.generate(n, (i) => _q('q$i')),
      random: Random(seed),
    );

void main() {
  group('serving within one attempt', () {
    test('never repeats a question until every one has been served', () {
      final pool = _pool(5);
      final seen = <String>[];

      for (var i = 0; i < 5; i++) {
        seen.add(pool.draw()!.id);
      }

      expect(seen.toSet().length, 5,
          reason: 'all five draws should be distinct before any recycle');
      expect(pool.hasRecycled, false);
      expect(pool.remaining, 0);
    });

    test('recycles once exhausted, and reports that it did', () {
      final pool = _pool(3);

      for (var i = 0; i < 3; i++) {
        pool.draw();
      }
      expect(pool.hasRecycled, false);

      pool.draw(); // fourth draw on a three-question pool
      expect(pool.hasRecycled, true);
      expect(pool.recycleCount, 1);
    });

    test('keeps serving indefinitely rather than running dry', () {
      final pool = _pool(3);
      for (var i = 0; i < 20; i++) {
        expect(pool.draw(), isNotNull);
      }
      expect(pool.recycleCount, greaterThan(1));
    });
  });

  group('retry serves a different question', () {
    test('excluded question is never the one returned', () {
      final pool = _pool(5);
      final first = pool.draw()!;

      for (var i = 0; i < 20; i++) {
        final retry = pool.draw(exclude: first);
        expect(retry!.id, isNot(first.id),
            reason: 'a retry must not re-serve the question just missed');
      }
    });

    test('exclusion holds even when it forces a recycle', () {
      // Two questions: after both are served the next draw must recycle, and
      // must still avoid the excluded one.
      final pool = _pool(2);
      final a = pool.draw()!;
      pool.draw();

      final retry = pool.draw(exclude: a);

      expect(pool.hasRecycled, true);
      expect(retry!.id, isNot(a.id));
    });

    test('a single-question pool still serves rather than returning null', () {
      // Degenerate but real: exclusion cannot be honoured, and serving the
      // same question beats blocking the player at a gate forever.
      final pool = _pool(1);
      final only = pool.draw()!;

      final retry = pool.draw(exclude: only);

      expect(retry, isNotNull);
      expect(retry!.id, only.id);
    });
  });

  group('empty pool', () {
    test('draw returns null instead of throwing', () {
      final pool = QuestionPool(questions: const []);
      expect(pool.isEmpty, true);
      expect(pool.draw(), isNull);
    });
  });

  group('option shuffling', () {
    test('every served question has its options reshuffled', () {
      // Source JSON lists the correct answer first for every question, so an
      // unshuffled serve would make "A" always correct.
      final pool = QuestionPool(
        questions: [
          Question(
            id: 'x',
            era: 'spanish',
            level: 1,
            questionText: 'Q',
            options: const [
              QuestionOption(label: 'A', text: 'right'),
              QuestionOption(label: 'B', text: 'w1'),
              QuestionOption(label: 'C', text: 'w2'),
              QuestionOption(label: 'D', text: 'w3'),
            ],
            correctAnswer: 'right',
            explanation: 'e',
          ),
        ],
        random: Random(7),
      );

      final positions = <int>{};
      for (var i = 0; i < 30; i++) {
        final q = pool.draw()!;
        positions.add(q.options.indexWhere((o) => o.text == q.correctAnswer));
      }

      expect(positions.length, greaterThan(1),
          reason: 'the correct answer must move between serves');
    });
  });

  group('drawMany', () {
    test('returns the requested count, recycling if needed', () {
      final pool = _pool(4);
      expect(pool.drawMany(10).length, 10);
      expect(pool.hasRecycled, true);
    });

    test('returns empty for an empty pool rather than hanging', () {
      expect(QuestionPool(questions: const []).drawMany(5), isEmpty);
    });
  });
}
