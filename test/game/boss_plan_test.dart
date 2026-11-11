// How a boss fight is laid out (boss_plan.dart, boss_attack_profile.dart): 22 rounds, three
// phases with less time to answer, a wrong answer asked again at the back, and which attack
// each boss throws in which round. Plain Dart, no game.
import 'dart:math';

import 'package:chronoquest/core/boss_attack_constants.dart';
import 'package:chronoquest/game/boss_attack_profile.dart';
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
  group('BossPlan', () {
    test('a fight is 22 rounds', () {
      expect(BossPlan.rounds, 22);
      expect(BossAttackConstants.rounds, 22);
    });

    test('rounds 1-7 are phase 1, 8-15 phase 2, 16-22 phase 3', () {
      expect([for (var r = 1; r <= 22; r++) BossPlan.phaseOfRound(r)], [
        ...List.filled(7, 1),
        ...List.filled(8, 2),
        ...List.filled(7, 3),
      ]);
    });

    test('the time to answer: 15 s, then 12 s, then 10 s', () {
      expect(BossPlan.answerSeconds, [15, 12, 10]);
      expect([for (var r = 1; r <= 22; r++) BossPlan.secondsForRound(r)], [
        ...List.filled(7, 15),
        ...List.filled(8, 12),
        ...List.filled(7, 10),
      ]);
    });

    test('the words on screen', () {
      expect(BossPlan.roundTag(1, 22), 'Tanong 1 ng 22');
      expect(BossPlan.roundTag(7, 22), 'Tanong 7 ng 22');
      expect(BossPlan.phaseTag(1), 'Phase 1 · 15 s');
      expect(BossPlan.phaseTag(10), 'Phase 2 · 12 s');
      expect(BossPlan.phaseTag(22), 'Phase 3 · 10 s');
    });

    test('the extra attack starts in round 16', () {
      expect(BossPlan.extraFromRound, 16);
    });

    test('the rune and the waves: 450 away, 15 s of patience, a wave of 2, 3, 4 after every second round', () {
      expect(BossAttackConstants.runeMinDistance, 450);
      expect(BossAttackConstants.runeStallSeconds, 15);
      expect(BossAttackConstants.waveEveryRounds, 2);
      expect(BossAttackConstants.waveSizes, [2, 3, 4]);
      expect(BossAttackConstants.waveSizes.every((n) => n <= BossAttackConstants.waveMaxAlive), isTrue);
      expect(BossAttackConstants.freezeSeconds, 8);
    });
  });

  group('BossQuestions', () {
    test('asks all 22 questions of a pool of 22, the lesson\'s own first', () {
      final fight = BossQuestions(_pool(22), random: Random(1));
      expect(fight.total, 22);
      final ids = <String>[];
      for (var q = fight.next(); q != null; q = fight.next()) {
        ids.add(q.id);
      }
      expect(ids, hasLength(22));
      expect(ids.toSet(), hasLength(22));
      int n(String id) => int.parse(id.substring(1));
      // A boss pool lists the lesson's own 10 first, then 12 of review.
      expect(ids.take(10).every((id) => n(id) < 10), isTrue);
      expect(ids.skip(10).every((id) => n(id) >= 10), isTrue);
    });

    test('the order changes from one attempt to the next', () {
      final a = BossQuestions(_pool(22), random: Random(1));
      final b = BossQuestions(_pool(22), random: Random(2));
      expect([for (var i = 0; i < 22; i++) a.next()!.id],
          isNot([for (var i = 0; i < 22; i++) b.next()!.id]));
    });

    test('the round counts the answers already right', () {
      final fight = BossQuestions(_pool(22), random: Random(3));
      expect(fight.round, 1);
      fight.next();
      expect(fight.round, 1, reason: 'a question served is not yet a round won');
      fight.solve();
      expect(fight.round, 2);
      expect(fight.solved, 1);
    });

    test('a wrong answer goes to the back of the line, and the fight is still 22 right answers', () {
      final fight = BossQuestions(_pool(22), random: Random(4));
      final first = fight.next()!;
      fight.again(first);
      final ids = <String>[];
      for (var q = fight.next(); q != null; q = fight.next()) {
        ids.add(q.id);
        fight.solve();
      }
      expect(ids, hasLength(22), reason: 'the 21 others and the missed one again');
      expect(ids.last, first.id);
      expect(fight.solved, 22);
      expect(fight.asked, 23);
      expect(fight.isDone, isTrue);
    });

    test('a question missed again goes back again', () {
      final fight = BossQuestions(_pool(2), random: Random(5));
      var q = fight.next()!;
      final stubborn = q;
      fight.again(q);
      fight.next();
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
      expect(seen.length, greaterThan(1),
          reason: 'the right answer does not always sit first');
    });

    test('a short pool gives a short fight; a pool of none has nothing to ask', () {
      expect(BossQuestions(_pool(4)).total, 4);
      expect(BossQuestions(_pool(10)).total, 10);
      final none = BossQuestions(const []);
      expect(none.total, 0);
      expect(none.next(), isNull);
    });
  });

  group('BossProfile', () {
    test('rounds 1-15 throw the main attack, rounds 16-22 the extra one', () {
      const p = BossProfile.bakunawa;
      expect([for (var r = 1; r <= 22; r++) p.attackForRound(r)], [
        ...List.filled(15, BossAttackKind.water),
        ...List.filled(7, BossAttackKind.whirl),
      ]);
    });

    test('each boss has the attacks of its own art', () {
      expect(BossProfile.forEra('pre-colonial').main, BossAttackKind.water);
      expect(BossProfile.forEra('pre-colonial').extra, BossAttackKind.whirl);
      expect(BossProfile.forEra('spanish').main, BossAttackKind.gslash);
      expect(BossProfile.forEra('spanish').extra, BossAttackKind.knights);
      expect(BossProfile.forEra('nationalism').main, BossAttackKind.ghost);
      expect(BossProfile.forEra('american').main, BossAttackKind.pistol);
      expect(BossProfile.forEra('american').extra, BossAttackKind.sonic);
      expect(BossProfile.forEra('ww2').main, BossAttackKind.slash);
      expect(BossProfile.forEra('ww2').extra, BossAttackKind.wind);
      expect(BossProfile.forEra('modern').main, BossAttackKind.fan);
      expect(BossProfile.forEra('modern').extra, BossAttackKind.vortex);
    });

    test('Pag-usbong ng Nasyonalismo has no extra: the ghost knights all the way', () {
      final p = BossProfile.forEra('nationalism');
      expect(p.extra, isNull);
      expect({for (var r = 1; r <= 22; r++) p.attackForRound(r)}, {BossAttackKind.ghost});
    });

    test('every attack has a start, an end and a trail; only the ghosts are not sent back', () {
      for (final k in BossAttackKind.values) {
        expect(k.start.dx, lessThan(0), reason: '$k leaves the boss towards the hero');
        expect(k.end.up, greaterThanOrEqualTo(0));
        expect(k.trail.count, greaterThan(0));
        expect(k.reflects, k != BossAttackKind.ghost);
      }
    });

    test('the special picture goes with the phase 3 attacks and the ghost knights', () {
      for (final k in BossAttackKind.values) {
        final extra = [
          BossAttackKind.whirl,
          BossAttackKind.knights,
          BossAttackKind.sonic,
          BossAttackKind.wind,
          BossAttackKind.vortex,
          BossAttackKind.ghost,
        ].contains(k);
        expect(k.usesSpecialPose, extra, reason: '$k');
      }
    });
  });
}
