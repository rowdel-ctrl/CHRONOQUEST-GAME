// The wallet follows the student to the server and back: sent a moment after a
// change, read at sign-in, and never lost when the server cannot be reached.
import 'dart:io';

import 'package:chronoquest/models/student.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/services/server_clock.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  final dir = Directory.systemTemp.createTempSync('chronoquest_wallet_sync_test_').path;
  final server = DateTime.utc(2020, 1, 1, 12);
  const wait = Duration(milliseconds: 60);

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

  tearDown(() => Future<void>.delayed(const Duration(milliseconds: 50)));

  /// A notifier whose sends are caught in [sent] instead of going out.
  GameNotifier make(List<Map<String, dynamic>> sent, {bool accept = true}) => GameNotifier(
        clock: ServerClock.fixed(server),
        uploadDelay: const Duration(milliseconds: 20),
        uploadWallet: (wallet) async {
          sent.add(wallet);
          return accept;
        },
      );

  ServerWallet held(
    String id, {
    int coins = 0,
    int fifty = 0,
    Set<String> unlocked = const {},
  }) =>
      ServerWallet(
        studentId: id,
        coins: coins,
        powerUps: PowerUps(fiftyFifty: fifty),
        unlockedCharacters: unlocked,
      );

  group('sending', () {
    test('a change goes up a moment later, and many changes go up as one', () async {
      final sent = <Map<String, dynamic>>[];
      final n = make(sent)..loadWallet('s1');
      for (var i = 0; i < 12; i++) {
        n.addCoins(1);
      }
      expect(sent, isEmpty, reason: 'not on every coin: the server takes one save a second');
      await Future<void>.delayed(wait);

      expect(sent.length, 1);
      expect(sent.single['coins'], 12);
      expect(sent.single['unlockedCharacters'], isEmpty);
      expect(StorageService.getWalletUnsynced('s1'), isFalse, reason: 'the server has it now');
    });

    test('a character bought goes up with its id', () async {
      final sent = <Map<String, dynamic>>[];
      final n = make(sent)..loadWallet('s2');
      n.addCoins(5000);
      expect(n.unlockCharacter('luna'), isTrue);
      await Future<void>.delayed(wait);

      expect(sent.last['unlockedCharacters'], ['luna']);
    });

    test('numbers past the server\'s limits are cut, so a save is never refused for ever',
        () async {
      final sent = <Map<String, dynamic>>[];
      final n = make(sent)..loadWallet('s3');
      n.addCoins(2000000);
      n.state.powerUps.shield = 150;
      n.saveWallet();
      await Future<void>.delayed(wait);

      expect(sent.last['coins'], 1000000);
      expect(sent.last['shield'], 99);
    });

    test('a send the server refuses is not forgotten', () async {
      final sent = <Map<String, dynamic>>[];
      final n = make(sent, accept: false)..loadWallet('s4');
      n.addCoins(9);
      await Future<void>.delayed(wait);

      expect(sent.length, 1);
      expect(StorageService.getWalletUnsynced('s4'), isTrue);
      expect(n.state.coins, 9, reason: 'the phone still has them');
      expect(StorageService.getWallet('s4')!['coins'], 9);
    });

    test('with nowhere to send, nothing is queued and the phone copy still saves', () {
      final n = GameNotifier(clock: ServerClock.fixed(server))..loadWallet('s5');
      n.addCoins(4);
      expect(StorageService.getWallet('s5')!['coins'], 4);
      expect(StorageService.getWalletUnsynced('s5'), isFalse);
    });

    test('a send waiting for one student does not go out when another signs in', () async {
      final sent = <Map<String, dynamic>>[];
      final n = make(sent)..loadWallet('s6a');
      n.addCoins(30);
      n.loadWallet('s6b');
      await Future<void>.delayed(wait);

      expect(sent, isEmpty, reason: 'it would carry the second student\'s token');
      expect(StorageService.getWalletUnsynced('s6a'), isTrue, reason: 'it goes at their next sign-in');
    });
  });

  group('signing in', () {
    test('a new phone gets the wallet back from the server', () async {
      final sent = <Map<String, dynamic>>[];
      final n = make(sent);
      n.syncWithServer(held('t1', coins: 120, fifty: 2, unlocked: {'luna'}));

      expect(n.state.coins, 120);
      expect(n.state.powerUps.fiftyFifty, 2);
      expect(n.isCharacterUnlocked('luna'), isTrue);
      // And it is on the phone now, so the next start reads it without the server.
      final again = GameNotifier(clock: ServerClock.fixed(server))..loadWallet('t1');
      expect(again.state.coins, 120);
      await Future<void>.delayed(wait);
      expect(sent, isEmpty, reason: 'nothing to send: the server already has it');
    });

    test('an old account with nothing on the server sends up what the phone has', () async {
      final sent = <Map<String, dynamic>>[];
      final n = make(sent)..loadWallet('t2');
      // Coins from before wallets reached the server (saved on the phone only).
      StorageService.saveWallet('t2', {'coins': 120, 'fiftyFifty': 0, 'timeFreeze': 0, 'shield': 0, 'unlocked': []});
      n.loadWallet(null);
      n.loadWallet('t2');
      n.syncWithServer(held('t2'));
      await Future<void>.delayed(wait);

      expect(n.state.coins, 120);
      expect(sent.single['coins'], 120);
    });

    test('an empty phone and an empty server send nothing', () async {
      final sent = <Map<String, dynamic>>[];
      final n = make(sent);
      n.syncWithServer(held('t3'));
      await Future<void>.delayed(wait);
      expect(sent, isEmpty);
    });

    test('coins won while the server could not be reached win over its older copy', () async {
      final sent = <Map<String, dynamic>>[];
      final offline = make(sent, accept: false)..loadWallet('t4');
      offline.addCoins(500);
      await Future<void>.delayed(wait);
      expect(StorageService.getWalletUnsynced('t4'), isTrue);

      // Next sign-in: the server still says 100.
      final later = make(sent)..loadWallet('t4');
      later.syncWithServer(held('t4', coins: 100));
      await Future<void>.delayed(wait);

      expect(later.state.coins, 500);
      expect(sent.last['coins'], 500);
      expect(StorageService.getWalletUnsynced('t4'), isFalse);
    });

    test('characters are only added: the phone keeps one the server does not know yet',
        () async {
      final sent = <Map<String, dynamic>>[];
      final n = make(sent)..loadWallet('t5');
      n.addCoins(5000);
      n.unlockCharacter('luna');
      await Future<void>.delayed(wait); // taken

      final later = make(sent)..loadWallet('t5');
      sent.clear();
      later.syncWithServer(held('t5', coins: 40, unlocked: {'bonifacio'}));
      await Future<void>.delayed(wait);

      expect(later.isCharacterUnlocked('luna'), isTrue, reason: 'not taken away');
      expect(later.isCharacterUnlocked('bonifacio'), isTrue, reason: 'and the server\'s is added');
      expect(later.state.coins, 40, reason: 'the server\'s number replaces the phone\'s');
      expect(sent.last['unlockedCharacters'], containsAll(['luna', 'bonifacio']),
          reason: 'luna goes up so a third phone gets her too');
    });

    test('the server\'s copy goes to the student it belongs to, not the one logged in', () {
      final n = make([])..loadWallet('t6a');
      n.addCoins(10);
      n.syncWithServer(held('t6b', coins: 77));
      expect(n.state.coins, 77);
      expect(StorageService.getWallet('t6a')!['coins'], 10, reason: 'the first student\'s is untouched');
    });
  });

  group('the sign-in answer', () {
    test('a student with a wallet reads it, and an old one reads zeros', () {
      final withWallet = Student.fromJson({
        '_id': 'x',
        'coins': 250,
        'powerUps': {'fiftyFifty': 1, 'timeFreeze': 2, 'shield': 3, 'extraLife': 0},
        'unlockedCharacters': ['luna', 'delpilar'],
      });
      final w = ServerWallet.of(withWallet);
      expect(w.coins, 250);
      expect(w.powerUps.shield, 3);
      expect(w.unlockedCharacters, {'luna', 'delpilar'});
      expect(w.isEmpty, isFalse);

      final old = ServerWallet.of(Student.fromJson({'_id': 'y'}));
      expect(old.isEmpty, isTrue);
    });
  });
}
