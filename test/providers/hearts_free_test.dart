// While the testing switch is on, hearts are not spent: a hit does not take one
// from the pool, and a level can be started on an empty pool.
import 'dart:io';

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/services/server_clock.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  final dir =
      Directory.systemTemp.createTempSync('chronoquest_free_hearts_').path;

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

  // GameNotifier saves without waiting; let the writes land between tests.
  tearDown(() => Future<void>.delayed(const Duration(milliseconds: 50)));

  Future<GameNotifier> notifier(
      {required bool switchOn, required int hearts}) async {
    await StorageService.setUnlockAll(switchOn);
    await StorageService.saveHeartsState(HeartsState(
      count: hearts,
      regenStartMs: DateTime.now().millisecondsSinceEpoch,
    ));
    return GameNotifier(clock: ServerClock.fixed(DateTime.now()));
  }

  test('with the switch on, a hit does not cost a heart', () async {
    final n = await notifier(switchOn: true, hearts: 3);
    n.enterLevel();
    n.loseHeart();
    n.loseHeart();
    expect(n.state.hearts.count, 3);
  });

  test('with the switch on, a level can be started with no hearts', () async {
    final n = await notifier(switchOn: true, hearts: 0);
    expect(n.canStartLevel, isTrue);
  });

  test('with the switch off, hearts are spent as before', () async {
    final n = await notifier(switchOn: false, hearts: GameConstants.maxHearts);
    n.enterLevel();
    n.loseHeart();
    expect(n.state.hearts.count, GameConstants.maxHearts - 1);
  });

  test('with the switch off, no hearts means no level', () async {
    final n = await notifier(switchOn: false, hearts: 0);
    expect(n.canStartLevel, isFalse);
  });
}
