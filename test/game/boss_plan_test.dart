// How a boss fight is laid out (boss_plan.dart): every question of the level once, three phases,
// a wrong answer asked again at the back. Plain Dart, no game.
import 'dart:math';

import 'package:chronoquest/game/boss_plan.dart';
import 'package:chronoquest/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

Question _q(int i) => Question(
      id: 'q$i',
      era: 'spanish',
      questionText: 'Tanong $i',
      options: const [
        QuestionOption(label: 'A', text: 'Una'),
        QuestionOption(label: 'B', text: 'Pangalawa'),
      ],
      correctAnswer: 'A',
      explanation: '',
    );

List<Question> _pool(int n) => [for (var i = 0; i < n; i++) _q(i)];

void main() {
  group('BossPlan scroll and lead-in', () {
    test('the tag counts the answers already right', () {
      expect(BossPlan.questionTag(0, 22), 'Tanong 1 ng 22');
      expect(BossPlan.questionTag(6, 22), 'Tanong 7 ng 22');
    });

    final spots = [for (final x in [100.0, 500.0, 900.0, 1300.0, 1700.0]) (x: x, y: 660.0)];

    test('the scroll is at least 450 from the student', () {
      for (var seed = 0; seed < 30; seed++) {
        final s = BossPlan.scrollSpot(spots, 100, const [], Random(seed))!;
        expect((s.x - 100).abs(), greaterThanOrEqualTo(BossPlan.scrollMinDistance));
      }
    });

    test('it keeps away from minions when a spot allows it', () {
      for (var seed = 0; seed < 30; seed++) {
        final s = BossPlan.scrollSpot(spots, 100, const [900, 1300], Random(seed))!;
        expect(s.x, 1700, reason: 'the only far spot with no minion near');
      }
    });

    test('with no spot far enough it takes the farthest; with no spots at all, none', () {
      final near = [(x: 100.0, y: 660.0), (x: 300.0, y: 660.0)];
      expect(BossPlan.scrollSpot(near, 120, const [], Random(1))!.x, 300);
      expect(BossPlan.scrollSpot(const [], 0, const [], Random(1)), isNull);
    });
  });

  group('BossPlan', () {
    test('a boss level of 22 splits 10, 6 and 6: its own lesson, then the review in two halves', () {
      expect(BossPlan.phaseSizes(22), [10, 6, 6]);
    });

    test('any other size splits in the same proportion and loses nothing', () {
      for (final n in [1, 2, 3, 5, 12, 21, 22, 30]) {
        final sizes = BossPlan.phaseSizes(n);
        expect(sizes.fold<int>(0, (a, b) => a + b), n, reason: 'a pool of $n');
        expect(sizes.every((s) => s >= 0), isTrue);
      }
      expect(BossPlan.phaseSizes(0), [0, 0, 0]);
    });

    test('the phase of the question at an index', () {
      expect([for (final i in [0, 9, 10, 15, 16, 21]) BossPlan.phaseOf(i, 22)], [0, 0, 1, 1, 2, 2]);
    });

    test('later phases give less time and more minions', () {
      expect(BossPlan.answerSeconds, [15, 12, 10]);
      expect(BossPlan.minionsPerWave, [2, 3, 4]);
      expect(BossPlan.questionsPerWave, 2);
    });
  });

  group('BossQuestions', () {
    test('asks every question once, the lesson\'s own 10 before the review', () {
      final fight = BossQuestions(_pool(22), random: Random(1));
      final ids = <String>[];
      for (var q = fight.next(); q != null; q = fight.next()) {
        ids.add(q.id);
      }
      expect(ids.toSet(), hasLength(22));
      expect(ids.take(10).toSet(), {for (var i = 0; i < 10; i++) 'q$i'});
      expect(ids.skip(10).take(6).toSet().every((id) => int.parse(id.substring(1)) >= 10), isTrue);
    });

    test('the order changes from one attempt to the next', () {
      final a = BossQuestions(_pool(22), random: Random(1));
      final b = BossQuestions(_pool(22), random: Random(2));
      expect([for (var i = 0; i < 10; i++) a.next()!.id], isNot([for (var i = 0; i < 10; i++) b.next()!.id]));
    });

    test('the phase follows the question, and the banners come once', () {
      final fight = BossQuestions(_pool(22), random: Random(3));
      final banners = <String?>[];
      final phases = <int>[];
      for (var q = fight.next(); q != null; q = fight.next()) {
        phases.add(fight.phase);
        banners.add(fight.takeBanner());
        fight.solve();
      }
      expect(phases, [...List.filled(10, 0), ...List.filled(6, 1), ...List.filled(6, 2)]);
      expect(banners.whereType<String>().toList(), ['PHASE 2', 'PHASE 3', 'FINAL QUESTION']);
      expect(banners[10], 'PHASE 2', reason: 'the 11th question starts phase 2');
      expect(banners[21], 'FINAL QUESTION');
      expect(fight.solved, 22);
    });

    test('a wrong answer goes to the back of the line, into the last phase', () {
      final fight = BossQuestions(_pool(22), random: Random(4));
      final first = fight.next()!;
      fight.again(first);
      final ids = <String>[];
      for (var q = fight.next(); q != null; q = fight.next()) {
        ids.add(q.id);
        fight.solve();
      }
      expect(ids, hasLength(22));
      expect(ids.last, first.id);
      expect(fight.phase, 2);
      expect(fight.isFinal, isTrue);
      expect(fight.asked, 23);
    });

    test('a question missed again goes back again', () {
      final fight = BossQuestions(_pool(2), random: Random(5));
      var q = fight.next()!;
      final stubborn = q;
      fight.again(q);
      q = fight.next()!;
      fight.solve();
      q = fight.next()!;
      expect(q.id, stubborn.id);
      fight.again(q);
      expect(fight.isDone, isFalse);
      expect(fight.next()!.id, stubborn.id);
      expect(fight.isDone, isTrue);
    });

    test('options are shuffled every time a question is asked', () {
      final fight = BossQuestions(_pool(22), random: Random(6));
      final seen = <String>{};
      for (var q = fight.next(); q != null; q = fight.next()) {
        seen.add(q.options.first.text);
      }
      expect(seen.length, greaterThan(1), reason: 'the right answer does not always sit first');
    });

    test('a level with no questions has nothing to ask', () {
      final fight = BossQuestions(const []);
      expect(fight.total, 0);
      expect(fight.next(), isNull);
    });
  });
}
