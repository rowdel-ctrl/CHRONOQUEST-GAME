// The phone's clock must not bring hearts back. Hearts count in the server's
// time (ServerClock); the phone's own clock is the student's to change.
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
      Directory.systemTemp.createTempSync('chronoquest_clock_test_').path;
  const interval = GameConstants.heartRegenInterval;

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

  tearDown(() => Future<void>.delayed(const Duration(milliseconds: 50)));

  /// Two hearts down, the countdown started at [startMs] on the server's clock.
  Future<void> seed(int? startMs, {int down = 2}) =>
      StorageService.saveHeartsState(
        HeartsState(
            count: GameConstants.maxHearts - down, regenStartMs: startMs),
      );

  test('moving the phone forward gives nothing: hearts follow the server',
      () async {
    // The server says it is 2020; the phone says it is much later.
    final server = DateTime.utc(2020, 1, 1, 12);
    await seed(server.millisecondsSinceEpoch - 5000); // 5 s into the countdown
    final n = GameNotifier(clock: ServerClock.fixed(server));

    expect(n.state.hearts.count, GameConstants.maxHearts - 2);
    n.refreshHearts();
    expect(n.state.hearts.count, GameConstants.maxHearts - 2);
    expect(n.heartCountdown!.inSeconds, greaterThan(interval.inSeconds - 15));
  });

  test('real server time passing does bring a heart back', () async {
    final server = DateTime.utc(2020, 1, 1, 12);
    await seed(server.millisecondsSinceEpoch - interval.inMilliseconds - 1000);
    final n = GameNotifier(clock: ServerClock.fixed(server));

    expect(n.state.hearts.count, GameConstants.maxHearts - 1);
  });

  test('with no server time nothing comes back, however old the countdown',
      () async {
    await seed(
        DateTime.now().millisecondsSinceEpoch - interval.inMilliseconds * 5);
    final n = GameNotifier(clock: ServerClock(fetch: () async => null));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    n.refreshHearts();

    expect(n.state.hearts.count, GameConstants.maxHearts - 2);
    expect(n.heartCountdown, isNull);
  });

  test(
      'a heart lost with no server time starts its countdown once there is one',
      () async {
    final server = DateTime.utc(2020, 1, 1, 12);
    await StorageService.saveHeartsState(HeartsState.initial());
    var answer = <int?>[null, server.millisecondsSinceEpoch];
    final clock = ServerClock(fetch: () async => answer.removeAt(0));
    final n = GameNotifier(clock: clock);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    n.loseHeart();
    expect(n.state.hearts.count, GameConstants.maxHearts - 1);
    expect(n.state.hearts.regenStartMs, isNull,
        reason: 'no time to start it with');

    await clock.sync();
    n.refreshHearts();
    expect(n.state.hearts.regenStartMs, isNotNull);
    expect(n.heartCountdown!.inSeconds, greaterThan(interval.inSeconds - 15));
  });

  test('a countdown that starts in the future is pulled back to now', () async {
    final server = DateTime.utc(2020, 1, 1, 12);
    // Left over from a moved phone clock: a start a day ahead of the server.
    await seed(
        server.millisecondsSinceEpoch + const Duration(days: 1).inMilliseconds);
    final n = GameNotifier(clock: ServerClock.fixed(server));

    expect(n.heartCountdown!.inSeconds, lessThanOrEqualTo(interval.inSeconds));
  });
}
