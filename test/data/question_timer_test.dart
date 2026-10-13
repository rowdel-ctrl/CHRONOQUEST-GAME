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
