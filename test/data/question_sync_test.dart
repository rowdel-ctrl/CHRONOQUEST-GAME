// The teacher's question bank, on the phone: downloaded questions replace the
// bundled ones for the levels they cover, are checked again by the game, and
// never make a level worse than what shipped.
import 'dart:io';

import 'package:chronoquest/data/question_bank.dart';
import 'package:chronoquest/services/question_sync.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

Map<String, dynamic> _q(String id, {String correct = 'A', List<String>? options}) => {
      'id': id,
      'era': 'spanish',
      'subTopic': '',
      'gradeLevel': 'grade5',
      'level': 1,
      'difficulty': 'medium',
      'questionType': 'multiple_choice',
      'questionText': 'Tanong $id',
      'options': [
        for (final (i, text) in (options ?? ['Una', 'Pangalawa', 'Pangatlo', 'Pang-apat']).indexed)
          {'label': 'ABCD'[i], 'text': text},
      ],
      'correctAnswer': correct,
      'explanation': '',
    };

List<Map<String, dynamic>> _qs(int n, [String prefix = 'c']) =>
    [for (var i = 0; i < n; i++) _q('${prefix}_$i')];

List<String> _ids(String era, int level) => QuestionBank.poolFor(era, level).map((q) => q.id).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dir = Directory.systemTemp.createTempSync('chronoquest_qsync_test_').path;

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

  group('QuestionBank.applySynced', () {
    test('replaces a level with the downloaded questions', () {
      final used = QuestionBank.applySynced({'spanish': {'1': _qs(6)}});
      expect(used, 1);
      expect(_ids('spanish', 1), ['c_0', 'c_1', 'c_2', 'c_3', 'c_4', 'c_5']);
      expect(QuestionBank.syncedLevels, {'spanish/1'});
    });

    test('leaves every level it does not mention as shipped', () {
      QuestionBank.applySynced({'spanish': {'1': _qs(6)}});
      expect(_ids('spanish', 2).first, 'spa_2_1');
      expect(_ids('pre-colonial', 1).first, 'pre_1_1');
    });

    test('fills a level that shipped with nothing', () {
      expect(QuestionBank.hasRealQuestions('nationalism', 1), isFalse);
      QuestionBank.applySynced({'nationalism': {'1': _qs(3)}});
      expect(QuestionBank.hasRealQuestions('nationalism', 1), isTrue);
      expect(_ids('nationalism', 1), hasLength(3));
    });

    test('keeps the shipped level when the download is thinner than it', () {
      // Spanish level 1 shipped with 5.
      expect(QuestionBank.applySynced({'spanish': {'1': _qs(4)}}), 0);
      expect(_ids('spanish', 1).first, 'spa_1_1');
      expect(QuestionBank.syncedLevels, isEmpty);
    });

    test('drops a question that cannot be played, and judges the rest', () {
      final broken = [
        _q('wrong_answer', correct: 'E'),
        _q('empty_option', options: ['Una', '', 'Pangatlo', 'Pang-apat']),
        _q('one_option', options: ['Lamang']),
        {'id': 'no_options', 'questionText': 'Tanong', 'correctAnswer': 'A'},
        'not even a map',
      ];
      // 5 good + 5 broken: the good ones are enough.
      expect(QuestionBank.applySynced({'spanish': {'1': [..._qs(5), ...broken]}}), 1);
      expect(_ids('spanish', 1), ['c_0', 'c_1', 'c_2', 'c_3', 'c_4']);

      // 4 good + the broken ones: not enough, so the shipped level stays.
      expect(QuestionBank.applySynced({'spanish': {'1': [..._qs(4), ...broken]}}), 0);
      expect(_ids('spanish', 1).first, 'spa_1_1');
    });

    test('ignores an unknown era, a bad level number and bad shapes', () {
      final used = QuestionBank.applySynced({
        'atlantis': {'1': _qs(6)},
        'spanish': {'one': _qs(6), '2': 'nope', '3': _qs(6)},
        'ww2': 'nope',
      });
      expect(used, 1);
      expect(QuestionBank.syncedLevels, {'spanish/3'});
    });

    test('a second download replaces the first rather than adding to it', () {
      QuestionBank.applySynced({'spanish': {'1': _qs(6)}});
      QuestionBank.applySynced({'spanish': {'2': _qs(6)}});
      expect(_ids('spanish', 1).first, 'spa_1_1');
      expect(QuestionBank.syncedLevels, {'spanish/2'});
    });

    test('clearSynced goes back to the bundled questions', () {
      QuestionBank.applySynced({'spanish': {'1': _qs(6)}});
      QuestionBank.clearSynced();
      expect(_ids('spanish', 1).first, 'spa_1_1');
    });

    test('getQuestions plays the downloaded questions too', () {
      QuestionBank.applySynced({'spanish': {'1': _qs(12)}});
      final asked = QuestionBank.getQuestions('spanish', 1);
      expect(asked, hasLength(10));
      expect(asked.every((q) => q.id.startsWith('c_')), isTrue);
    });
  });

  group('QuestionSync', () {
    const classCode = 'AAA111';

    test('downloads, applies and saves the questions', () async {
      String? sentTag = 'unset';
      final changed = await QuestionSync.sync(classCode, fetch: (tag) async {
        sentTag = tag;
        return {'tag': 'bank1:1', 'levels': {'spanish': {'1': _qs(6)}}};
      });
      expect(changed, isTrue);
      expect(sentTag, isNull, reason: 'nothing was held yet');
      expect(_ids('spanish', 1).first, 'c_0');
      final cache = StorageService.getQuestionCache()!;
      expect(cache['classCode'], classCode);
      expect(cache['tag'], 'bank1:1');
    });

    test('sends the tag it holds and does nothing when up to date', () async {
      await QuestionSync.sync(classCode, fetch: (_) async => {'tag': 'bank1:1', 'levels': {'spanish': {'1': _qs(6)}}});
      QuestionBank.clearSynced();
      String? sentTag;
      final changed = await QuestionSync.sync(classCode, fetch: (tag) async {
        sentTag = tag;
        return {'tag': 'bank1:1', 'upToDate': true};
      });
      expect(sentTag, 'bank1:1');
      expect(changed, isFalse);
      expect(QuestionBank.syncedLevels, isEmpty, reason: 'sync does not re-apply; restore does');
    });

    test('restore applies the saved copy with no network', () async {
      await QuestionSync.sync(classCode, fetch: (_) async => {'tag': 'bank1:1', 'levels': {'spanish': {'1': _qs(6)}}});
      QuestionBank.clearSynced();
      QuestionSync.restore(classCode);
      expect(_ids('spanish', 1).first, 'c_0');
    });

    test('restore ignores a copy saved for another class', () async {
      await QuestionSync.sync(classCode, fetch: (_) async => {'tag': 'bank1:1', 'levels': {'spanish': {'1': _qs(6)}}});
      QuestionBank.clearSynced();
      QuestionSync.restore('ZZZ999');
      expect(_ids('spanish', 1).first, 'spa_1_1');
    });

    test('a different class does not send the old tag', () async {
      await QuestionSync.sync(classCode, fetch: (_) async => {'tag': 'bank1:1', 'levels': {'spanish': {'1': _qs(6)}}});
      String? sentTag = 'unset';
      await QuestionSync.sync('ZZZ999', fetch: (tag) async {
        sentTag = tag;
        return {'tag': 'none', 'levels': <String, dynamic>{}};
      });
      expect(sentTag, isNull);
      expect(_ids('spanish', 1).first, 'spa_1_1', reason: 'the new class has no changes');
    });

    test('offline keeps what the phone already has', () async {
      await QuestionSync.sync(classCode, fetch: (_) async => {'tag': 'bank1:1', 'levels': {'spanish': {'1': _qs(6)}}});
      final changed = await QuestionSync.sync(classCode, fetch: (_) async => throw Exception('offline'));
      expect(changed, isFalse);
      expect(_ids('spanish', 1).first, 'c_0');
      expect(StorageService.getQuestionCache()!['tag'], 'bank1:1');
    });

    test('a teacher who unpublishes everything returns the class to the bundled questions', () async {
      await QuestionSync.sync(classCode, fetch: (_) async => {'tag': 'bank1:1', 'levels': {'spanish': {'1': _qs(6)}}});
      await QuestionSync.sync(classCode, fetch: (_) async => {'tag': 'none', 'levels': <String, dynamic>{}});
      expect(_ids('spanish', 1).first, 'spa_1_1');
    });

    test('a reply with no tag or levels changes nothing', () async {
      expect(await QuestionSync.sync(classCode, fetch: (_) async => {'oops': true}), isFalse);
      expect(StorageService.getQuestionCache(), isNull);
    });

    test('does nothing with no class code', () async {
      var called = false;
      await QuestionSync.sync('', fetch: (_) async {
        called = true;
        return {};
      });
      expect(called, isFalse);
    });
  });
}
