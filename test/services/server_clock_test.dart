// Hearts count in the server's time. The phone's clock belongs to the student,
// so nothing here may depend on it.
import 'package:chronoquest/services/server_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('has no time until the server has been read', () {
    final clock = ServerClock(fetch: () async => null);
    expect(clock.isSynced, isFalse);
    expect(clock.now, isNull);
  });

  test('a failed read leaves it with no time', () async {
    final clock = ServerClock(fetch: () async => null);
    await clock.sync();
    expect(clock.now, isNull);
  });

  test('an error while reading is swallowed', () async {
    final clock = ServerClock(fetch: () async => throw Exception('offline'));
    await clock.sync();
    expect(clock.now, isNull);
  });

  test("reports the server's time, whatever the phone's clock says", () async {
    final server = DateTime.utc(2020, 3, 4, 5, 6, 7);
    final clock = ServerClock(fetch: () async => server.millisecondsSinceEpoch);
    await clock.sync();

    final now = clock.now!;
    expect(now.year, 2020, reason: 'the phone says it is later than this');
    expect(now.difference(server).inSeconds.abs(), lessThan(5));
  });

  test('a failed read keeps the time it already had', () async {
    var answers = <int?>[DateTime.utc(2020).millisecondsSinceEpoch, null];
    final clock = ServerClock(fetch: () async => answers.removeAt(0));
    await clock.sync();
    final before = clock.now;
    await clock.sync();
    expect(clock.now, isNotNull);
    expect(clock.now!.difference(before!).inSeconds.abs(), lessThan(5));
  });

  test('a clock made for tests starts at the time it is given', () {
    final t = DateTime.utc(2021, 1, 1);
    final clock = ServerClock.fixed(t);
    expect(clock.isSynced, isTrue);
    expect(clock.now!.difference(t).inSeconds.abs(), lessThan(5));
  });
}
