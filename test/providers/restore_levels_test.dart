// Logging out wipes the levels a phone remembers (which are done, with stars). Logging in again
// used to leave the level map empty although the server kept every result (user report,
// 2026-11-28: "I logged into 2 devices, logged out the other one, and my progress was gone").
// If the server counts more finished levels than the phone knows, the map is rebuilt from the
// results.
import 'dart:io';

import 'package:chronoquest/models/era_progress.dart';
import 'package:chronoquest/models/quiz_result.dart';
import 'package:chronoquest/providers/progress_provider.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

QuizResult _r(String era, int level, int percentage, {String type = 'pre_test'}) => QuizResult(
      era: era,
      level: level,
      type: type,
      correctAnswersCount: 0,
      totalQuestions: 10,
      percentage: percentage,
      timeTakenTotal: 60,
      questionSnapshots: const [],
    );

Map<String, EraProgress> _server(int done, {bool boss = false}) =>
    {'pre-colonial': EraProgress(eraId: 'pre-colonial', levelsCompleted: done, bossDefeated: boss)};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dir = Directory.systemTemp.createTempSync('chronoquest_restore_levels_').path;

  setUpAll(() async {
    Hive.init(dir);
    await Hive.openBox('chronoquest');
  });

  tearDownAll(() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await Hive.close();
    try {
      Directory(dir).deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async => StorageService.appBox.clear());

  ProgressNotifier make({
    required Map<String, EraProgress> server,
    required Future<List<QuizResult>> Function() results,
  }) =>
      ProgressNotifier(fetchProgress: () async => server, fetchResults: results);

  test('a phone that forgot its levels gets them back, with stars from the best score', () async {
    var asked = 0;
    final notifier = make(
      server: _server(3),
      results: () async {
        asked++;
        return [
          _r('pre-colonial', 1, 100),
          _r('pre-colonial', 2, 75),
          _r('pre-colonial', 3, 40),
          _r('pre-colonial', 3, 95), // a later, better attempt
        ];
      },
    );
    await notifier.loadProgress();
    expect(asked, 1);
    expect(StorageService.getCompletedLevels('pre-colonial'), {1: 3, 2: 2, 3: 3});
    expect(notifier.state.eraProgress['pre-colonial']!.levelsCompleted, 3);
  });

  test('a phone that already knows its levels asks for nothing', () async {
    await StorageService.saveLevelCompleted('pre-colonial', 1, 3);
    await StorageService.saveLevelCompleted('pre-colonial', 2, 1);
    var asked = 0;
    final notifier = make(
      server: _server(2),
      results: () async {
        asked++;
        return [];
      },
    );
    await notifier.loadProgress();
    expect(asked, 0, reason: 'the results are heavy, only fetched when the phone is behind');
  });

  test('stars already on the phone are never lowered, and levels are only added', () async {
    await StorageService.saveLevelCompleted('pre-colonial', 1, 3);
    final notifier = make(
      server: _server(2),
      results: () async => [_r('pre-colonial', 1, 50), _r('pre-colonial', 2, 80)],
    );
    await notifier.loadProgress();
    expect(StorageService.getCompletedLevels('pre-colonial'), {1: 3, 2: 2});
  });

  test('the boss level (a post test) comes back too, other eras too, nothing past the last level',
      () async {
    final bossLevel = 10; // Sinaunang Pilipinas has ten levels, the tenth is the boss
    final notifier = make(
      server: {
        'pre-colonial': const EraProgress(eraId: 'pre-colonial', levelsCompleted: 2, bossDefeated: true),
        'spanish': const EraProgress(eraId: 'spanish', levelsCompleted: 1),
      },
      results: () async => [
        _r('pre-colonial', 1, 90),
        _r('pre-colonial', bossLevel, 100, type: 'post_test'),
        _r('pre-colonial', 99, 100), // not a level of the era
        _r('spanish', 1, 70),
        _r('pre-colonial', 2, 100, type: 'cold_pre_test'), // not a level
      ],
    );
    await notifier.loadProgress();
    expect(StorageService.getCompletedLevels('pre-colonial'), {1: 3, bossLevel: 3});
    expect(StorageService.getCompletedLevels('spanish'), {1: 2});
  });

  test('offline: the map stays as it was and nothing throws', () async {
    final notifier = make(server: _server(3), results: () async => throw 'offline');
    await notifier.loadProgress();
    expect(StorageService.getCompletedLevels('pre-colonial'), isEmpty);
    expect(notifier.state.error, isNull);
  });
}
