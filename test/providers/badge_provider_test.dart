// The badges of a student: earned at the end of a level, a boss or a purchase, paid
// once with a coin gift, kept on the phone for each student, and brought back
// quietly from the server.
import 'dart:io';

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/quiz_result.dart';
import 'package:chronoquest/providers/badge_provider.dart';
import 'package:chronoquest/services/guest_mode.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

QuizResult _result(String era, int level, int percent, {String type = 'pre_test'}) => QuizResult(
      era: era,
      level: level,
      type: type,
      correctAnswersCount: percent ~/ 10,
      totalQuestions: 10,
      percentage: percent,
      timeTakenTotal: 60,
      questionSnapshots: const [],
    );

void main() {
  final dir = Directory.systemTemp.createTempSync('chronoquest_badge_test_').path;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Hive.init(dir);
    await Hive.openBox('chronoquest');
    // logout also clears the secure storage, which has no phone to talk to here.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      Directory(dir).deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() => StorageService.appBox.clear());

  var codex = 0;
  final gifts = <int>[];

  BadgeNotifier make({Future<List<QuizResult>> Function()? loadResults}) {
    codex = 0;
    gifts.clear();
    return BadgeNotifier(
      payCoins: gifts.add,
      loadResults: loadResults,
      codexTotal: () => codex,
      now: () => DateTime(2026, 10, 30, 9),
    );
  }

  BadgeNotifier open(String id, {Future<List<QuizResult>> Function()? loadResults}) =>
      make(loadResults: loadResults)..load(id);

  /// A level won with every answer right and no health lost.
  List<String> perfect(BadgeNotifier n, String era, int level, {int lost = 0}) => [
        for (final b in n.recordLevel(
          eraId: era,
          level: level,
          correct: 10,
          total: 10,
          healthLost: lost,
          anyWrong: false,
        ))
          b.id,
      ];

  group('who it is for', () {
    test('nobody signed in earns and keeps nothing', () {
      final n = make()..load(null);
      expect(n.state.enabled, isFalse);
      expect(perfect(n, 'spanish', 1), isEmpty);
      expect(n.state.earnedCount, 0);
    });

    test('a guest earns and keeps nothing', () {
      final n = make()..load(GuestMode.studentId);
      expect(n.state.enabled, isFalse);
      expect(perfect(n, 'spanish', 1), isEmpty);
      expect(StorageService.getBadges(GuestMode.studentId), isNull);
      expect(gifts, isEmpty);
    });

    test('each student has their own', () {
      final n = open('anna');
      perfect(n, 'spanish', 1);
      n.load('ben');
      expect(n.state.earnedCount, 0);
      n.load('anna');
      expect(n.state.earnedCount, greaterThan(0));
    });
  });

  group('the first time with badges', () {
    test('a student with nothing yet gets a quiet empty start and no gift', () {
      final n = open('anna');
      expect(n.state.enabled, isTrue);
      expect(n.state.earnedCount, 0);
      expect(n.state.quietCount, 0);
      expect(gifts, isEmpty);
      expect(StorageService.getBadges('anna'), isNotNull, reason: 'the start is kept');
    });

    test('what the phone already holds is earned quietly, with no gift', () async {
      await StorageService.saveLevelCompleted('spanish', 1, 3);
      await StorageService.saveLevelCompleted('spanish', 2, 2);
      final n = open('anna');
      expect(n.state.has('stars3:1'), isTrue);
      expect(n.state.quietCount, 1);
      expect(n.state.unseenCount, 1, reason: 'it carries BAGO');
      expect(gifts, isEmpty, reason: 'the gift was for earning it, which was before');
    });

    test('a beaten boss comes with its era medal', () async {
      final boss = getEraById('spanish').levels.length;
      await StorageService.saveLevelCompleted('spanish', boss, 2);
      final n = open('anna');
      expect(n.state.has('era:spanish'), isTrue);
      expect(gifts, isEmpty);
    });

    test('opening again does not pay again', () async {
      await StorageService.saveLevelCompleted('spanish', 1, 3);
      open('anna');
      final again = open('anna');
      expect(gifts, isEmpty);
      expect(again.state.has('stars3:1'), isTrue);
      expect(again.state.quietCount, 1, reason: 'still not mentioned');
    });
  });

  group('finishing a level', () {
    test('returns what it earned, pays the gift once, and keeps it', () {
      final n = open('anna');
      expect(perfect(n, 'spanish', 1), containsAll(['stars3:1', 'perfect:1', 'nodamage:1']));
      expect(gifts, [15], reason: 'three Tanso at 5 each');
      expect(n.state.unseenCount, 3);
      expect(n.state.quietCount, 0, reason: 'earned in play, not quietly');
      // The same level again earns nothing more.
      expect(perfect(n, 'spanish', 1), isEmpty);
      expect(gifts, [15]);
      // And it is on the phone.
      expect(open('anna').state.earnedCount, 3);
    });

    test('a level that lost health has no Walang Galos', () {
      final n = open('anna');
      expect(perfect(n, 'spanish', 1, lost: 2), isNot(contains('nodamage:1')));
    });

    test('the boss earns its medal, and a clean one the clean badge', () {
      final n = open('anna');
      final boss = getEraById('spanish').levels.length;
      final ids = [
        for (final b in n.recordLevel(
          eraId: 'spanish',
          level: boss,
          correct: 10,
          total: 10,
          healthLost: 0,
          anyWrong: false,
        ))
          b.id,
      ];
      expect(ids, containsAll(['era:spanish', 'bossclean']));
    });

    test('a lost level is a day of play and no more', () {
      final n = open('anna');
      n.recordFailed();
      expect(n.state.facts.days, {'2026-10-30'});
      expect(n.state.earnedCount, 0);
    });

    test('the Kodeks counts when a level ends', () {
      final n = open('anna');
      codex = 10;
      final ids = [
        for (final b in n.recordLevel(
          eraId: 'spanish',
          level: 1,
          correct: 5,
          total: 10,
          healthLost: 1,
          anyWrong: true,
        ))
          b.id,
      ];
      expect(ids, contains('collector:1'));
    });
  });

  group('buying', () {
    test('the first purchase earns Unang Bili, once', () {
      final n = open('anna');
      expect([for (final b in n.recordPurchase()) b.id], ['firstbuy']);
      expect(gifts, [5]);
      expect(n.recordPurchase(), isEmpty);
    });
  });

  group('the shelf and the eras screen', () {
    test('opening the shelf clears BAGO, and the one line clears when shown', () async {
      await StorageService.saveLevelCompleted('spanish', 1, 3);
      final n = open('anna');
      expect(n.state.unseenCount, 1);
      n.markAllSeen();
      expect(n.state.unseenCount, 0);
      expect(n.state.quietCount, 1);
      n.clearQuiet();
      expect(n.state.quietCount, 0);
      expect(n.state.has('stars3:1'), isTrue, reason: 'still held');
      expect(open('anna').state.unseenCount, 0, reason: 'kept');
    });

    test('a Kodeks that has grown earns Kolektor quietly', () {
      final n = open('anna');
      codex = 12;
      n.refresh();
      expect(n.state.has('collector:1'), isTrue);
      expect(n.state.quietCount, 1);
      expect(gifts, isEmpty);
    });
  });

  group('from the server', () {
    test('brings badges back on a new phone, quietly, and pays nothing twice', () async {
      final n = open('anna', loadResults: () async => [
            _result('spanish', 1, 100),
            _result('spanish', 2, 95),
          ]);
      await n.syncFromServer();
      expect(n.state.has('stars3:1'), isTrue);
      expect(n.state.has('perfect:1'), isTrue);
      expect(n.state.has('nodamage:1'), isFalse, reason: 'this phone only');
      expect(n.state.quietCount, 2);
      expect(gifts, isEmpty, reason: 'the wallet came with the student and has them');
    });

    test('reading the same attempts again changes nothing', () async {
      final n = open('anna', loadResults: () async => [_result('spanish', 1, 100)]);
      await n.syncFromServer();
      gifts.clear();
      final before = n.state.facts.toJson();
      await n.syncFromServer();
      expect(n.state.facts.toJson(), before);
      expect(gifts, isEmpty);
    });

    test('no internet changes nothing', () async {
      final n = open('anna', loadResults: () async => throw Exception('offline'));
      await n.syncFromServer();
      expect(n.state.earnedCount, 0);
    });

    test('a student who signed out while it was on its way gets nothing', () async {
      late BadgeNotifier n;
      n = open('anna', loadResults: () async {
        n.load('ben');
        return [_result('spanish', 1, 100)];
      });
      await n.syncFromServer();
      expect(n.state.studentId, 'ben');
      expect(n.state.earnedCount, 0);
      expect(StorageService.getBadges('ben')!['earned'], isEmpty);
    });

    test('without a way to ask, or for a guest, it does nothing', () async {
      await open('anna').syncFromServer();
      final guest = make(loadResults: () async => [_result('spanish', 1, 100)])
        ..load(GuestMode.studentId);
      await guest.syncFromServer();
      expect(guest.state.earnedCount, 0);
    });
  });

  test('badges survive a logout, like the wallet', () async {
    final n = open('anna');
    perfect(n, 'spanish', 1);
    await StorageService.clearAll();
    expect(StorageService.getBadges('anna'), isNotNull);
    expect(open('anna').state.earnedCount, 3);
  });
}
