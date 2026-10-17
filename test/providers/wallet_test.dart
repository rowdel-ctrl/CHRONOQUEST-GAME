// The coin wallet: coins earned and spent, power-ups bought, characters
// unlocked, all kept on the phone per student.
import 'dart:io';

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/services/server_clock.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  final dir = Directory.systemTemp.createTempSync('chronoquest_wallet_test_').path;
  final server = DateTime.utc(2020, 1, 1, 12);

  setUpAll(() async {
    Hive.init(dir);
    await Hive.openBox('chronoquest');
  });

  tearDownAll(() async {
    // A new notifier saves the hearts without anyone waiting for it.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await Hive.close();
    try {
      Directory(dir).deleteSync(recursive: true);
    } catch (_) {}
  });

  tearDown(() => Future<void>.delayed(const Duration(milliseconds: 50)));

  GameNotifier fresh(String student, {int coins = 0}) {
    final n = GameNotifier(clock: ServerClock.fixed(server))..loadWallet(student);
    if (coins > 0) n.addCoins(coins);
    return n;
  }

  group('coins', () {
    test('a student starts with none, and level coins are added and kept', () {
      final n = fresh('w1');
      expect(n.state.coins, 0);
      n.addCoins(37);
      expect(n.state.coins, 37);
      // A new session on the same phone reads them back.
      final again = GameNotifier(clock: ServerClock.fixed(server))..loadWallet('w1');
      expect(again.state.coins, 37);
    });

    test('adding nothing, or less, changes nothing', () {
      final n = fresh('w2', coins: 10);
      n.addCoins(0);
      n.addCoins(-5);
      expect(n.state.coins, 10);
    });

    test('each student has their own wallet on a shared phone', () {
      final a = fresh('w3a', coins: 50);
      a.loadWallet('w3b');
      expect(a.state.coins, 0, reason: 'the next student does not get the first one\'s coins');
      a.addCoins(5);
      a.loadWallet('w3a');
      expect(a.state.coins, 50);
      a.loadWallet(null);
      expect(a.state.coins, 0, reason: 'nobody logged in, nothing to spend');
    });
  });

  group('buying a heart', () {
    test('costs the price, adds one heart and keeps the countdown', () async {
      await StorageService.saveHeartsState(
        HeartsState(count: 2, regenStartMs: server.millisecondsSinceEpoch - 5000),
      );
      final n = fresh('h1', coins: 50);
      expect(n.state.hearts.count, 2);

      expect(n.buyHeart(), isTrue);
      expect(n.state.hearts.count, 3);
      expect(n.state.coins, 50 - GameConstants.heartPriceCoins);
      expect(n.state.hearts.regenStartMs, server.millisecondsSinceEpoch - 5000,
          reason: 'the next free heart is still on its way');
      // Kept on the phone, for this student.
      expect(StorageService.getHeartsStateFor('h1').count, 3);
      expect(StorageService.getWallet('h1')!['coins'], 30);
    });

    test('the last heart stops the countdown', () async {
      await StorageService.saveHeartsState(
        HeartsState(count: GameConstants.maxHearts - 1, regenStartMs: server.millisecondsSinceEpoch),
      );
      final n = fresh('h2', coins: 20);
      expect(n.buyHeart(), isTrue);
      expect(n.state.hearts.count, GameConstants.maxHearts);
      expect(n.state.hearts.regenStartMs, isNull);
    });

    test('is refused, with nothing taken, when the pool is full', () async {
      await StorageService.saveHeartsState(HeartsState.initial());
      final n = fresh('h3', coins: 100);
      expect(n.buyHeart(), isFalse);
      expect(n.state.coins, 100);
    });

    test('filling the pool takes the price of every missing heart, all or nothing', () async {
      await StorageService.saveHeartsState(
        HeartsState(count: 2, regenStartMs: server.millisecondsSinceEpoch),
      );
      // Hearts are the student's own; h6 gets the same start as h5 had.
      await StorageService.saveHeartsStateFor(
        'h6',
        HeartsState(count: 2, regenStartMs: server.millisecondsSinceEpoch),
      );
      final short = fresh('h5', coins: GameConstants.heartPriceCoins * 3 - 1);
      expect(short.buyAllHearts(), isFalse);
      expect(short.state.hearts.count, 2);
      expect(short.state.coins, GameConstants.heartPriceCoins * 3 - 1);

      final n = fresh('h6', coins: GameConstants.heartPriceCoins * 3 + 4);
      expect(n.buyAllHearts(), isTrue);
      expect(n.state.hearts.count, GameConstants.maxHearts);
      expect(n.state.hearts.regenStartMs, isNull);
      expect(n.state.coins, 4);
      expect(StorageService.getHeartsStateFor('h6').count, GameConstants.maxHearts);
      expect(n.buyAllHearts(), isFalse, reason: 'nothing left to fill');
    });

    test('is refused when the coins fall short', () async {
      await StorageService.saveHeartsState(
        HeartsState(count: 1, regenStartMs: server.millisecondsSinceEpoch),
      );
      final n = fresh('h4', coins: GameConstants.heartPriceCoins - 1);
      expect(n.buyHeart(), isFalse);
      expect(n.state.hearts.count, 1);
      expect(n.state.coins, GameConstants.heartPriceCoins - 1);
    });
  });

  group('buying power-ups', () {
    test('each costs its price and adds one, kept for next time', () {
      final n = fresh('p1', coins: 100);
      expect(n.buyPowerUp(PowerUpKind.fiftyFifty), isTrue);
      expect(n.buyPowerUp(PowerUpKind.shield), isTrue);
      expect(n.buyPowerUp(PowerUpKind.timeFreeze), isTrue);

      const spent = GameConstants.fiftyFiftyPriceCoins +
          GameConstants.shieldPriceCoins +
          GameConstants.timeFreezePriceCoins;
      expect(n.state.coins, 100 - spent);
      expect(n.state.powerUps.fiftyFifty, 1);
      expect(n.state.powerUps.shield, 1);
      expect(n.state.powerUps.timeFreeze, 1);

      final again = GameNotifier(clock: ServerClock.fixed(server))..loadWallet('p1');
      expect(again.state.powerUps.timeFreeze, 1);
      expect(again.state.coins, 100 - spent);
    });

    test('is refused when the coins fall short', () {
      final n = fresh('p2', coins: GameConstants.timeFreezePriceCoins - 1);
      expect(n.buyPowerUp(PowerUpKind.timeFreeze), isFalse);
      expect(n.state.powerUps.timeFreeze, 0);
      expect(n.state.coins, GameConstants.timeFreezePriceCoins - 1);
    });

    test('what a level used up is not given back after a restart', () {
      final n = fresh('p3', coins: 100);
      n.buyPowerUp(PowerUpKind.shield);
      // The level changes the counts in place, then the screen saves the wallet.
      n.state.powerUps.shield--;
      n.saveWallet();
      final again = GameNotifier(clock: ServerClock.fixed(server))..loadWallet('p3');
      expect(again.state.powerUps.shield, 0);
    });

    test('the milestone rewards are kept too', () {
      final n = fresh('p4');
      n.awardPowerUp(3);
      n.awardPowerUp(7);
      final again = GameNotifier(clock: ServerClock.fixed(server))..loadWallet('p4');
      expect(again.state.powerUps.fiftyFifty, 1);
      expect(again.state.powerUps.shield, 1);
    });
  });

  group('characters', () {
    final paid = allCharacters.firstWhere((c) => c.unlockCost > 0);
    final free = allCharacters.firstWhere((c) => c.unlockCost == 0);

    test('a free one is open and a priced one is locked', () {
      final n = fresh('c1');
      expect(n.isCharacterUnlocked(free.id), isTrue);
      expect(n.isCharacterUnlocked(paid.id), isFalse);
    });

    test('a locked one cannot be picked until it is bought', () {
      final n = fresh('c2');
      n.selectCharacter(free.id);
      n.selectCharacter(paid.id);
      expect(n.state.selectedCharacterId, free.id);
    });

    test('buying takes the price and opens it for good', () {
      final n = fresh('c3', coins: paid.unlockCost + 7);
      expect(n.unlockCharacter(paid.id), isTrue);
      expect(n.state.coins, 7);
      expect(n.isCharacterUnlocked(paid.id), isTrue);

      n.selectCharacter(paid.id);
      expect(n.state.selectedCharacterId, paid.id);

      // Another session on the phone still has it, and an unlock is not charged twice.
      final again = GameNotifier(clock: ServerClock.fixed(server))..loadWallet('c3');
      expect(again.isCharacterUnlocked(paid.id), isTrue);
      expect(again.unlockCharacter(paid.id), isFalse);
      expect(again.state.coins, 7);
    });

    test('is refused when the coins fall short', () {
      final n = fresh('c4', coins: paid.unlockCost - 1);
      expect(n.unlockCharacter(paid.id), isFalse);
      expect(n.state.coins, paid.unlockCost - 1);
      expect(n.isCharacterUnlocked(paid.id), isFalse);
    });

    test('a free character cannot be "bought", and an unknown one is ignored', () {
      final n = fresh('c5', coins: 500);
      expect(n.unlockCharacter(free.id), isFalse);
      expect(n.unlockCharacter('nobody'), isFalse);
      expect(n.state.coins, 500);
    });

    test('a student who had picked a locked character is put back on a free one', () async {
      await StorageService.saveCharacter(paid.id);
      final n = GameNotifier(clock: ServerClock.fixed(server));
      expect(n.state.selectedCharacterId, paid.id, reason: 'read from the phone before anyone is known');
      n.loadWallet('c6');
      expect(n.state.selectedCharacterId, free.id);
      expect(StorageService.getCharacter(), free.id);
    });

    test('the testing switch opens every character', () async {
      await StorageService.setUnlockAll(true);
      addTearDown(() => StorageService.setUnlockAll(false));
      final n = fresh('c7');
      expect(n.isCharacterUnlocked(paid.id), isTrue);
    });

    test('the student build ignores the switch: a locked character stays locked', () async {
      await StorageService.setUnlockAll(true);
      addTearDown(() => StorageService.setUnlockAll(false));
      final n = GameNotifier(clock: ServerClock.fixed(server), testBuild: false)
        ..loadWallet('c8');
      expect(n.isCharacterUnlocked(paid.id), isFalse);
    });
  });
}
