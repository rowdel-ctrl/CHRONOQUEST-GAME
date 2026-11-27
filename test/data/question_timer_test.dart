// The teacher's question timer on the phone: what the game accepts from a
// download, how it is kept for offline play, and that nothing damaged can
// leave a student with a clock too short to read the question.
import 'dart:io';

import 'package:chronoquest/data/question_bank.dart';
import 'package:chronoquest/services/question_sync.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dir = Directory.systemTemp.createTempSync('chronoquest_timer_test_').path;

  setUpAll(() async {
    Hive.init(dir);
    await Hive.openBox('chronoquest');
    await QuestionBank.loadAll();
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      Directory(dir).deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    QuestionBank.clearSynced();
    await StorageService.appBox.clear();
  });

  group('QuestionBank.applyTimer', () {
    test('a level with no timer has none', () {
      expect(QuestionBank.timerSecondsFor('spanish', 1), 0);
    });

    test('gives each level its time and leaves the rest untimed', () {
      QuestionBank.applyTimer({'spanish': {'1': 45, '2': 30}});
      expect(QuestionBank.timerSecondsFor('spanish', 1), 45);
      expect(QuestionBank.timerSecondsFor('spanish', 2), 30);
      expect(QuestionBank.timerSecondsFor('spanish', 3), 0);
      expect(QuestionBank.timerSecondsFor('pre-colonial', 1), 0);
    });

    test('null (the teacher turned the timer off) clears an earlier timer', () {
      QuestionBank.applyTimer({'spanish': {'1': 45}});
      QuestionBank.applyTimer(null);
      expect(QuestionBank.timerSecondsFor('spanish', 1), 0);
    });

    test('ignores times outside 15 to 120 seconds, fractions, unknown eras and junk', () {
      QuestionBank.applyTimer({
        'spanish': {'1': 14, '2': 121, '3': 20.5, '4': 'soon', 'x': 30, '5': 15},
        'atlantis': {'1': 45},
        'pre-colonial': 'nope',
      });
      expect(QuestionBank.timerSecondsFor('spanish', 1), 0);
      expect(QuestionBank.timerSecondsFor('spanish', 2), 0);
      expect(QuestionBank.timerSecondsFor('spanish', 3), 0);
      expect(QuestionBank.timerSecondsFor('spanish', 4), 0);
      expect(QuestionBank.timerSecondsFor('spanish', 5), 15);
      expect(QuestionBank.timerSecondsFor('atlantis', 1), 0);
      expect(QuestionBank.timerSecondsFor('pre-colonial', 1), 0);
    });

    group('the boss fight\'s own number', () {
      test('none by default', () {
        expect(QuestionBank.bossSeconds, isNull);
      });

      test('is taken from the "boss" key, with or without a timer on the levels', () {
        QuestionBank.applyTimer({'boss': 25});
        expect(QuestionBank.bossSeconds, 25);
        expect(QuestionBank.timerSecondsFor('spanish', 1), 0);

        QuestionBank.applyTimer({'boss': 40, 'spanish': {'1': 45}});
        expect(QuestionBank.bossSeconds, 40);
        expect(QuestionBank.timerSecondsFor('spanish', 1), 45);
      });

      test('follows the same 15 to 120 rule, and ignores fractions and junk', () {
        for (final bad in [14, 121, 20.5, '20', null, true, -5, 0]) {
          QuestionBank.applyTimer({'boss': bad});
          expect(QuestionBank.bossSeconds, isNull, reason: '$bad');
        }
        QuestionBank.applyTimer({'boss': 15});
        expect(QuestionBank.bossSeconds, 15);
        QuestionBank.applyTimer({'boss': 120});
        expect(QuestionBank.bossSeconds, 120);
      });

      test('a timer without it, or no timer at all, goes back to automatic', () {
        QuestionBank.applyTimer({'boss': 25});
        QuestionBank.applyTimer({'spanish': {'1': 45}});
        expect(QuestionBank.bossSeconds, isNull);
        QuestionBank.applyTimer({'boss': 25});
        QuestionBank.applyTimer(null);
        expect(QuestionBank.bossSeconds, isNull);
      });

      test('does not count as an era (an older game would skip it)', () {
        QuestionBank.applyTimer({'boss': 25});
        for (final era in ['pre-colonial', 'spanish', 'nationalism', 'american', 'ww2', 'modern']) {
          for (var level = 1; level <= 10; level++) {
            expect(QuestionBank.timerSecondsFor(era, level), 0);
          }
        }
      });
    });

    test('is dropped on logout, with the rest of the teacher content', () {
      QuestionBank.applyTimer({'spanish': {'1': 45}});
      QuestionBank.clearSynced();
      expect(QuestionBank.timerSecondsFor('spanish', 1), 0);
    });
  });

  group('QuestionSync keeps the timer', () {
    Future<Map<String, dynamic>> reply(String? _, Map<String, dynamic> body) async => body;

    test('a download sets the timer and saves it for offline play', () async {
      final applied = await QuestionSync.sync('AAA111', fetch: (tag) => reply(tag, {
            'tag': 'bank:1',
            'levels': <String, dynamic>{},
            'timer': {'spanish': {'1': 40}},
          }));
      expect(applied, isTrue);
      expect(QuestionBank.timerSecondsFor('spanish', 1), 40);

      QuestionBank.clearSynced(); // the app was closed
      QuestionSync.restore('AAA111');
      expect(QuestionBank.timerSecondsFor('spanish', 1), 40);
    });

    test('another class code does not get the saved timer', () async {
      await QuestionSync.sync('AAA111', fetch: (tag) => reply(tag, {
            'tag': 'bank:1',
            'levels': <String, dynamic>{},
            'timer': {'spanish': {'1': 40}},
          }));
      QuestionBank.clearSynced();
      QuestionSync.restore('BBB222');
      expect(QuestionBank.timerSecondsFor('spanish', 1), 0);
    });

    test('a newer download without a timer turns it off', () async {
      await QuestionSync.sync('AAA111', fetch: (tag) => reply(tag, {
            'tag': 'bank:1',
            'levels': <String, dynamic>{},
            'timer': {'spanish': {'1': 40}},
          }));
      await QuestionSync.sync('AAA111', fetch: (tag) => reply(tag, {
            'tag': 'bank:2',
            'levels': <String, dynamic>{},
          }));
      expect(QuestionBank.timerSecondsFor('spanish', 1), 0);
      QuestionBank.clearSynced();
      QuestionSync.restore('AAA111');
      expect(QuestionBank.timerSecondsFor('spanish', 1), 0);
    });

    test('the boss number is saved for offline play and turned off by a newer download', () async {
      await QuestionSync.sync('AAA111', fetch: (tag) => reply(tag, {
            'tag': 'bank:1',
            'levels': <String, dynamic>{},
            'timer': {'boss': 30},
          }));
      expect(QuestionBank.bossSeconds, 30);
      QuestionBank.clearSynced(); // the app was closed
      expect(QuestionBank.bossSeconds, isNull);
      QuestionSync.restore('AAA111');
      expect(QuestionBank.bossSeconds, 30);

      QuestionBank.clearSynced();
      QuestionSync.restore('BBB222');
      expect(QuestionBank.bossSeconds, isNull, reason: 'another class');

      await QuestionSync.sync('AAA111', fetch: (tag) => reply(tag, {'tag': 'bank:2', 'levels': <String, dynamic>{}}));
      expect(QuestionBank.bossSeconds, isNull);
    });

    test('"up to date" keeps the timer the phone already has', () async {
      await QuestionSync.sync('AAA111', fetch: (tag) => reply(tag, {
            'tag': 'bank:1',
            'levels': <String, dynamic>{},
            'timer': {'spanish': {'1': 40}},
          }));
      final applied = await QuestionSync.sync('AAA111', fetch: (tag) => reply(tag, {'tag': 'bank:1', 'upToDate': true}));
      expect(applied, isFalse);
      expect(QuestionBank.timerSecondsFor('spanish', 1), 40);
    });
  });
}
