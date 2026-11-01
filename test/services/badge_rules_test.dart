// The rules of the badges: 28 of them, earned by learning, never counted twice.
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/badge_defs.dart';
import 'package:chronoquest/models/badge_facts.dart';
import 'package:chronoquest/models/quiz_result.dart';
import 'package:chronoquest/services/badge_rules.dart';
import 'package:flutter_test/flutter_test.dart';

BadgeFacts _level(
  BadgeFacts f,
  String era,
  int level, {
  int correct = 8,
  int total = 10,
  int healthLost = 1,
  bool anyWrong = true,
  String day = '2026-10-30',
}) =>
    BadgeRules.applyLevel(f,
        eraId: era,
        level: level,
        correct: correct,
        total: total,
        healthLost: healthLost,
        anyWrong: anyWrong,
        day: day);

List<String> _ids(List<EarnedBadge> b) => [for (final e in b) e.id];

QuizResult _result(String era, int level, int percent,
        {String type = 'pre_test', String? date}) =>
    QuizResult(
      era: era,
      level: level,
      type: type,
      correctAnswersCount: percent ~/ 10,
      totalQuestions: 10,
      percentage: percent,
      timeTakenTotal: 60,
      questionSnapshots: const [],
      testDate: date,
    );

void main() {
  group('the list of badges', () {
    test('there are 28 in 16 families, each id used once', () {
      expect(badgeFamilies, hasLength(16));
      expect(allBadgeSteps, hasLength(28));
      expect({for (final s in allBadgeSteps) s.id}, hasLength(28));
    });

    test('the coin gifts add up to 535', () {
      expect(allBadgeSteps.fold<int>(0, (sum, s) => sum + s.coins), 535);
    });

    test('three tiers each for six families, one level for ten', () {
      expect(badgeFamilies.where((f) => f.tiered), hasLength(6));
      expect(badgeFamilies.where((f) => !f.tiered), hasLength(10));
      final perfect = badgeFamilies.firstWhere((f) => f.id == 'perfect');
      expect([for (final s in perfect.steps) s.need], [1, 5, 15]);
      expect([for (final s in perfect.steps) s.coins], [5, 10, 20]);
      expect([for (final s in perfect.steps) s.metal],
          [BadgeMetal.tanso, BadgeMetal.pilak, BadgeMetal.ginto]);
    });

    test('17 can be worked out again from the server, 11 are this phone only', () {
      final keep = badgeFamilies.where((f) => f.keep).fold<int>(0, (n, f) => n + f.steps.length);
      expect(keep, 17);
      expect(allBadgeSteps.length - keep, 11);
    });

    test('an era badge is named for its era, a champion for its three eras', () {
      final spanish = badgeFamilies.firstWhere((f) => f.id == 'era:spanish');
      expect(spanish.name, 'Bayani ng ${getEraById('spanish').name}');
      expect(spanish.shelfName, getEraById('spanish').name);
      final champ5 = badgeFamilies.firstWhere((f) => f.id == 'champ:5');
      expect(champ5.steps.single.need, 3);
    });

    test('badgeFamilyOf finds the family of a badge', () {
      expect(badgeFamilyOf('perfect:2')?.name, 'Perpekto!');
      expect(badgeFamilyOf('era:ww2')?.glyph, 'n5');
      expect(badgeFamilyOf('nope'), isNull);
    });
  });

  group('finishing a level', () {
    test('3 stars at 90 percent, and not below', () {
      var f = _level(const BadgeFacts(), 'spanish', 1, correct: 9, total: 10);
      expect(f.threeStar, {'spanish:1'});
      f = _level(f, 'spanish', 2, correct: 8, total: 10);
      expect(f.threeStar, {'spanish:1'});
    });

    test('perfect is every answer right, in the game\'s own count', () {
      var f = _level(const BadgeFacts(), 'spanish', 1, correct: 10, total: 10);
      expect(f.perfect, {'spanish:1'});
      f = _level(f, 'spanish', 2, correct: 9, total: 10);
      expect(f.perfect, {'spanish:1'});
      f = _level(f, 'spanish', 3, correct: 0, total: 0);
      expect(f.perfect, {'spanish:1'}, reason: 'a level with no questions is not perfect');
    });

    test('no health lost, and a level that cost some', () {
      var f = _level(const BadgeFacts(), 'spanish', 1, healthLost: 0);
      f = _level(f, 'spanish', 2, healthLost: 2);
      expect(f.noDamage, {'spanish:1'});
    });

    test('a replay never counts a level twice', () {
      var f = _level(const BadgeFacts(), 'spanish', 1, correct: 10, total: 10, healthLost: 0);
      f = _level(f, 'spanish', 1, correct: 10, total: 10, healthLost: 0);
      expect(f.perfect, hasLength(1));
      expect(f.threeStar, hasLength(1));
      expect(f.noDamage, hasLength(1));
    });

    test('a comeback is a replay that beats the best before, and only that', () {
      var f = _level(const BadgeFacts(), 'spanish', 1, correct: 6, total: 10);
      expect(f.comebacks, 0, reason: 'the first time is not a comeback');
      f = _level(f, 'spanish', 1, correct: 6, total: 10);
      expect(f.comebacks, 0, reason: 'the same score is not higher');
      f = _level(f, 'spanish', 1, correct: 8, total: 10);
      expect(f.comebacks, 1);
      f = _level(f, 'spanish', 1, correct: 7, total: 10);
      expect(f.comebacks, 1, reason: 'lower than the best is not a comeback');
      expect(f.best['spanish:1'], 80, reason: 'the best stays the best');
      f = _level(f, 'spanish', 1, correct: 9, total: 10);
      expect(f.comebacks, 2);
    });

    test('every level played, won or lost, makes one day of play', () {
      var f = _level(const BadgeFacts(), 'spanish', 1, day: '2026-10-30');
      f = _level(f, 'spanish', 2, day: '2026-10-30');
      f = BadgeRules.applyFailed(f, day: '2026-10-31');
      expect(f.days, {'2026-10-30', '2026-10-31'});
    });

    test('the day is written the same way every time', () {
      expect(BadgeRules.dayOf(DateTime(2026, 3, 7)), '2026-03-07');
    });
  });

  group('the boss', () {
    final spanishBoss = getEraById('spanish').levels.length;

    test('beating it holds the era', () {
      final f = _level(const BadgeFacts(), 'spanish', spanishBoss);
      expect(f.bosses, {'spanish'});
      expect(f.bossClean, isFalse);
    });

    test('a level before it does not', () {
      expect(_level(const BadgeFacts(), 'spanish', spanishBoss - 1).bosses, isEmpty);
    });

    test('no wrong answer at all makes it clean, and it stays clean', () {
      var f = _level(const BadgeFacts(), 'spanish', spanishBoss, anyWrong: false);
      expect(f.bossClean, isTrue);
      f = _level(f, 'spanish', spanishBoss, anyWrong: true);
      expect(f.bossClean, isTrue, reason: 'a later messy win does not take it back');
    });

    test('a clean ordinary level is not a clean boss', () {
      expect(_level(const BadgeFacts(), 'spanish', 2, anyWrong: false).bossClean, isFalse);
    });
  });

  group('earning', () {
    const none = BadgeFacts();

    test('one perfect level earns Tanso, and Pilak waits for five', () {
      var f = _level(none, 'spanish', 1, correct: 10, total: 10);
      expect(_ids(BadgeRules.newlyEarned(f, codexTotal: 0)),
          containsAll(['perfect:1', 'stars3:1']));
      expect(_ids(BadgeRules.newlyEarned(f, codexTotal: 0)), isNot(contains('perfect:2')));
      for (var i = 2; i <= 5; i++) {
        f = _level(f, 'pre-colonial', i, correct: 10, total: 10);
      }
      expect(_ids(BadgeRules.newlyEarned(f, codexTotal: 0)), contains('perfect:2'));
    });

    test('a badge already held is not earned again', () {
      var f = _level(none, 'spanish', 1, correct: 10, total: 10);
      final first = BadgeRules.newlyEarned(f, codexTotal: 0);
      f = BadgeRules.withEarned(f, first, nowMs: 1);
      expect(BadgeRules.newlyEarned(f, codexTotal: 0), isEmpty);
      f = _level(f, 'spanish', 1, correct: 10, total: 10);
      expect(BadgeRules.newlyEarned(f, codexTotal: 0), isEmpty);
    });

    test('skipping straight past a tier earns both', () {
      var f = none;
      for (var i = 1; i <= 5; i++) {
        f = _level(f, 'pre-colonial', i, correct: 10, total: 10);
      }
      final ids = _ids(BadgeRules.newlyEarned(f, codexTotal: 0));
      expect(ids, containsAll(['perfect:1', 'perfect:2']));
    });

    test('an era badge for the boss and a trophy for the three eras of a grade', () {
      var f = none;
      f = _level(f, 'pre-colonial', getEraById('pre-colonial').levels.length);
      f = _level(f, 'spanish', getEraById('spanish').levels.length);
      var ids = _ids(BadgeRules.newlyEarned(f, codexTotal: 0));
      expect(ids, containsAll(['era:pre-colonial', 'era:spanish']));
      expect(ids, isNot(contains('champ:5')));
      f = _level(f, 'nationalism', getEraById('nationalism').levels.length);
      ids = _ids(BadgeRules.newlyEarned(f, codexTotal: 0));
      expect(ids, contains('champ:5'));
      expect(ids, isNot(contains('champ:6')), reason: 'grade 6 has its own three');
    });

    test('the clean boss badge', () {
      final f = _level(none, 'spanish', getEraById('spanish').levels.length, anyWrong: false);
      expect(_ids(BadgeRules.newlyEarned(f, codexTotal: 0)), contains('bossclean'));
    });

    test('the Kodeks counts from what the Kodeks holds', () {
      expect(_ids(BadgeRules.newlyEarned(none, codexTotal: 9)), isNot(contains('collector:1')));
      expect(_ids(BadgeRules.newlyEarned(none, codexTotal: 10)), contains('collector:1'));
      expect(_ids(BadgeRules.newlyEarned(none, codexTotal: 100)),
          containsAll(['collector:1', 'collector:2', 'collector:3']));
    });

    test('days played, not in a row', () {
      var f = none;
      for (final d in ['2026-10-01', '2026-10-09', '2026-10-30']) {
        f = BadgeRules.playedOn(f, d);
      }
      expect(_ids(BadgeRules.newlyEarned(f, codexTotal: 0)), contains('days:1'));
      expect(_ids(BadgeRules.newlyEarned(f, codexTotal: 0)), isNot(contains('days:2')));
    });

    test('the first purchase', () {
      expect(_ids(BadgeRules.newlyEarned(none.copyWith(bought: true), codexTotal: 0)),
          ['firstbuy']);
    });

    test('earned badges are new on the shelf, and quiet ones are counted for the one line', () {
      final f = _level(none, 'spanish', 1, correct: 10, total: 10);
      final loud = BadgeRules.withEarned(f, BadgeRules.newlyEarned(f, codexTotal: 0), nowMs: 5);
      expect(loud.earned.keys, containsAll(['perfect:1', 'stars3:1']));
      expect(loud.unseen, loud.earned.keys.toSet());
      expect(loud.quiet, 0);
      final quiet = BadgeRules.withEarned(f, BadgeRules.newlyEarned(f, codexTotal: 0),
          nowMs: 5, quiet: true);
      expect(quiet.quiet, 2);
    });

    test('progress is the number the badge asks for', () {
      final f = _level(none, 'spanish', 1, correct: 10, total: 10);
      final perfect = badgeFamilies.firstWhere((x) => x.id == 'perfect');
      final collector = badgeFamilies.firstWhere((x) => x.id == 'collector');
      final champ6 = badgeFamilies.firstWhere((x) => x.id == 'champ:6');
      expect(BadgeRules.progress(perfect, f, codexTotal: 0), 1);
      expect(BadgeRules.progress(collector, f, codexTotal: 62), 62);
      expect(BadgeRules.progress(champ6, f, codexTotal: 0), 0);
    });
  });

  group('what the phone already knows', () {
    test('stars become 3-star levels and beaten bosses', () {
      final boss = getEraById('spanish').levels.length;
      final f = BadgeRules.fromLocalLevels({
        'spanish': {1: 3, 2: 2, boss: 1},
        'pre-colonial': {1: 3},
      });
      expect(f.threeStar, {'spanish:1', 'pre-colonial:1'});
      expect(f.bosses, {'spanish'});
      expect(f.perfect, isEmpty, reason: 'stars cannot tell a perfect level');
      expect(f.comebacks, 0);
    });

    test('a later replay of a 3-star level is not taken for a comeback', () {
      var f = BadgeRules.fromLocalLevels({'spanish': {1: 3}});
      f = _level(f, 'spanish', 1, correct: 9, total: 10);
      expect(f.comebacks, 0);
    });
  });

  group('what the server keeps', () {
    test('attempts give 3-star, perfect and boss levels', () {
      final boss = getEraById('spanish').levels.length;
      final f = BadgeRules.mergeResults(const BadgeFacts(), [
        _result('spanish', 1, 100),
        _result('spanish', 2, 92),
        _result('spanish', 3, 60),
        _result('spanish', boss, 80, type: 'post_test'),
      ]);
      expect(f.threeStar, {'spanish:1', 'spanish:2'});
      expect(f.perfect, {'spanish:1'});
      expect(f.bosses, {'spanish'});
      expect(f.best['spanish:3'], 60);
    });

    test('a comeback is a later attempt that beat the earlier ones', () {
      final f = BadgeRules.mergeResults(const BadgeFacts(), [
        // Given newest first, the way the server sends them.
        _result('spanish', 1, 90, date: '2026-10-03T10:00:00Z'),
        _result('spanish', 1, 70, date: '2026-10-02T10:00:00Z'),
        _result('spanish', 1, 50, date: '2026-10-01T10:00:00Z'),
        _result('spanish', 2, 80, date: '2026-10-01T10:00:00Z'),
        _result('spanish', 2, 60, date: '2026-10-02T10:00:00Z'),
      ]);
      expect(f.comebacks, 2, reason: '50 to 70 to 90 on level 1; level 2 only got worse');
    });

    test('what the phone counted itself is not added to what the server shows', () {
      var local = _level(const BadgeFacts(), 'spanish', 1, correct: 6, total: 10);
      local = _level(local, 'spanish', 1, correct: 8, total: 10);
      expect(local.comebacks, 1);
      final f = BadgeRules.mergeResults(local, [
        _result('spanish', 1, 80, date: '2026-10-02T10:00:00Z'),
        _result('spanish', 1, 60, date: '2026-10-01T10:00:00Z'),
      ]);
      expect(f.comebacks, 1);
    });

    test('reading the same attempts again changes nothing', () {
      final results = [_result('spanish', 1, 100), _result('spanish', 2, 95)];
      final once = BadgeRules.mergeResults(const BadgeFacts(), results);
      final twice = BadgeRules.mergeResults(once, results);
      expect(twice.toJson(), once.toJson());
    });

    test('an era the game does not know is left out', () {
      final f = BadgeRules.mergeResults(const BadgeFacts(), [_result('mars', 1, 100)]);
      expect(f.perfect, isEmpty);
    });

    test('this phone\'s own facts stay', () {
      final base = const BadgeFacts().copyWith(bought: true, days: {'2026-10-30'});
      final f = BadgeRules.mergeResults(base, [_result('spanish', 1, 100)]);
      expect(f.bought, isTrue);
      expect(f.days, {'2026-10-30'});
    });
  });

  test('facts survive being saved and read again', () {
    var f = _level(const BadgeFacts(), 'spanish', 1, correct: 10, total: 10, healthLost: 0);
    f = BadgeRules.withEarned(f, BadgeRules.newlyEarned(f, codexTotal: 0), nowMs: 7, quiet: true)
        .copyWith(bought: true, bossClean: true);
    final back = BadgeFacts.fromJson(f.toJson());
    expect(back.toJson(), f.toJson());
    expect(back.earned['perfect:1'], 7);
    expect(back.unseen, f.unseen);
    expect(back.quiet, f.quiet);
  });
}
