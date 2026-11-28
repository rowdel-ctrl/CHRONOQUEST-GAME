// The era books count the levels saved on this phone as well as the server's answer, so the
// percentage on a book moves as soon as a level is won (the level map always did).
import 'dart:io';

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/era_progress.dart';
import 'package:chronoquest/providers/progress_provider.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  final dir = Directory.systemTemp.createTempSync('chronoquest_progress_local_').path;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Hive.init(dir);
    await Hive.openBox('chronoquest');
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      Directory(dir).deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() => StorageService.appBox.clear());

  final era = allEras.first;

  ProgressNotifier make(Map<String, EraProgress> server) {
    final n = ProgressNotifier(fetchProgress: () async => server, fetchResults: () async => []);
    n.state = ProgressState(eraProgress: server);
    return n;
  }

  test('a level won on the phone shows at once, before the server knows', () async {
    final n = make({era.id: EraProgress(eraId: era.id, levelsCompleted: 1)});
    await StorageService.saveLevelCompleted(era.id, 1, 3);
    await StorageService.saveLevelCompleted(era.id, 2, 2);
    expect(n.getEraProgress(era.id).levelsCompleted, 2);
  });

  test('the server wins when it counts more than the phone', () async {
    final n = make({era.id: EraProgress(eraId: era.id, levelsCompleted: 4)});
    await StorageService.saveLevelCompleted(era.id, 1, 3);
    expect(n.getEraProgress(era.id).levelsCompleted, 4);
  });

  test('an era the server has not heard of yet still counts the phone', () async {
    final n = make({});
    await StorageService.saveLevelCompleted(era.id, 1, 1);
    final p = n.getEraProgress(era.id);
    expect(p.levelsCompleted, 1);
    expect(p.eraId, era.id);
  });

  test('a boss beaten on the phone completes the era', () async {
    final n = make({era.id: EraProgress(eraId: era.id, levelsCompleted: 9)});
    await StorageService.saveLevelCompleted(era.id, era.levels.length, 3);
    final p = n.getEraProgress(era.id);
    expect(p.isCompleted, isTrue);
    expect(p.levelsCompleted, 9, reason: 'the server already counted 9; one saved level is not more');
  });

  test('with nothing saved on the phone the server answer is returned as it is', () {
    final server = EraProgress(eraId: era.id, levelsCompleted: 3);
    final n = make({era.id: server});
    expect(identical(n.getEraProgress(era.id), server), isTrue);
  });
}
