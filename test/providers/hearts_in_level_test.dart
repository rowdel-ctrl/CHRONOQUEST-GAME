// Hearts do not come back while a level is being played. The regen clock stops
// when the level starts and carries on from where it was when it ends.
import 'dart:io';

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  final dir = Directory.systemTemp.createTempSync('chronoquest_hearts_test_').path;

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

  /// A pool two hearts down whose countdown began [ago] ago.
  Future<GameNotifier> notifierWithTwoDown(Duration ago) async {
    final start = DateTime.now().subtract(ago).millisecondsSinceEpoch;
    await StorageService.saveHeartsState(
      HeartsState(count: GameConstants.maxHearts - 2, regenStartMs: start),
    );
    return GameNotifier();
  }

  /// Pretends the clock ran on for [ago] since the countdown began, as it would
  /// have in the old code while the level was being played.
  void runClock(GameNotifier notifier, Duration ago) {
    final start = DateTime.now().subtract(ago).millisecondsSinceEpoch;
    // ignore: invalid_use_of_protected_member
    notifier.state = notifier.state.copyWith(
      hearts: HeartsState(count: notifier.state.hearts.count, regenStartMs: start),
    );
  }

  test('no heart appears during a level, however long it runs', () async {
    final notifier = await notifierWithTwoDown(const Duration(seconds: 10));
    notifier.enterLevel();
    final before = notifier.state.hearts.count;

    runClock(notifier, GameConstants.heartRegenInterval * 3); // three hearts' worth
    notifier.refreshHearts(); // what the menu's timer would do

    expect(notifier.state.hearts.count, before);
  });

  test('a heart lost in a level is not preceded by a free one', () async {
    final notifier = await notifierWithTwoDown(const Duration(seconds: 10));
    notifier.enterLevel();
    final before = notifier.state.hearts.count;

    runClock(notifier, GameConstants.heartRegenInterval * 3);
    notifier.loseHeart();

    expect(notifier.state.hearts.count, before - 1);
  });

  test('leaving the level resumes the countdown where it stopped', () async {
    final notifier = await notifierWithTwoDown(const Duration(seconds: 20));
    notifier.enterLevel();
    final countAtStart = notifier.state.hearts.count;

    notifier.exitLevel();

    expect(notifier.state.hearts.count, countAtStart);
    final left = notifier.state.hearts.timeUntilNext(DateTime.now())!;
    // 40 s were left when the level began (give or take the test's own time).
    expect(left.inSeconds, inInclusiveRange(38, 40));
  });

  test('outside a level hearts regenerate as before', () async {
    final notifier = await notifierWithTwoDown(
        GameConstants.heartRegenInterval + const Duration(seconds: 1));
    final start = notifier.state.hearts.count; // already caught up on creation

    expect(start, GameConstants.maxHearts - 1);
  });

  test('entering and leaving twice is harmless', () async {
    final notifier = await notifierWithTwoDown(const Duration(seconds: 5));
    notifier.enterLevel();
    notifier.enterLevel();
    notifier.exitLevel();
    notifier.exitLevel();

    expect(notifier.state.hearts.count, GameConstants.maxHearts - 2);
  });
}
