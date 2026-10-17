// Hearts belong to the student, like the wallet. Logging out, restarting the app, or
// another student using the phone must not refill them or hand them on.
import 'dart:io';

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/services/server_clock.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dir = Directory.systemTemp.createTempSync('chronoquest_hearts_student_').path;
  final server = DateTime.utc(2026, 10, 17, 12);

  setUpAll(() async {
    Hive.init(dir);
    await Hive.openBox('chronoquest');
    // Logout also clears the secure storage, which has no phone to talk to here.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  tearDownAll(() async {
    // A new notifier saves without anyone waiting for it.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await Hive.close();
    try {
      Directory(dir).deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async => StorageService.appBox.clear());
  tearDown(() => Future<void>.delayed(const Duration(milliseconds: 50)));

  /// The app as it starts: a notifier, then the logged-in student is told to it.
  GameNotifier session(String? student) =>
      GameNotifier(clock: ServerClock.fixed(server))..loadWallet(student);

  /// Loses [n] hearts the way a level does.
  void lose(GameNotifier n, int hearts) {
    n.enterLevel();
    for (var i = 0; i < hearts; i++) {
      n.loseHeart();
    }
  }

  const full = GameConstants.maxHearts;

  test('a new student starts with a full set', () {
    expect(session('a1').state.hearts.count, full);
  });

  test('hearts lost are still lost after the app restarts', () {
    lose(session('a2'), 2);

    final again = session('a2');

    expect(again.state.hearts.count, full - 2);
  });

  test('logging out and back in does not refill them', () async {
    final n = session('a3');
    lose(n, 2);

    n.loadWallet(null); // logout
    await StorageService.clearAll();
    n.loadWallet('a3'); // login again

    expect(n.state.hearts.count, full - 2);
  });

  test('logging out and restarting the app does not refill them either', () async {
    lose(session('a6'), 3);

    await StorageService.clearAll(); // logout, then the app is closed
    final restarted = session('a6');

    expect(restarted.state.hearts.count, full - 3);
  });

  test('another student on the same phone has their own hearts', () {
    final n = session('a4');
    lose(n, 3);

    n.loadWallet('a5');
    expect(n.state.hearts.count, full, reason: 'not the first student\'s hearts');

    n.loadWallet('a4');
    expect(n.state.hearts.count, full - 3, reason: 'and the first student\'s are still theirs');
  });

  test('nobody logged in holds a full set and saves nothing for anyone', () async {
    final n = session('a7');
    lose(n, 1);

    n.loadWallet(null);

    expect(n.state.hearts.count, full);
    expect(StorageService.getHeartsStateFor('a7').count, full - 1);
  });

  group('hearts the phone kept the old way (one set per phone)', () {
    test('go to the first student who logs in, and only to them', () async {
      await StorageService.saveHeartsState(
        HeartsState(count: 2, regenStartMs: server.millisecondsSinceEpoch),
      );

      final n = session('m1');
      expect(n.state.hearts.count, 2);

      n.loadWallet('m2');
      expect(n.state.hearts.count, full, reason: 'the second student starts full');
    });

    test('a student who already has their own hearts keeps them', () async {
      await StorageService.saveHeartsState(HeartsState(count: 1, regenStartMs: server.millisecondsSinceEpoch));
      await StorageService.saveHeartsStateFor('m3', const HeartsState(count: 4));

      final n = session('m3');

      expect(n.state.hearts.count, 4);
      expect(StorageService.getHeartsState().count, 1, reason: 'the old set is for someone else');
    });
  });
}
