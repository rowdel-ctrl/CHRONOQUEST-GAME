// The bonus round itself (bonus/bonus_game.dart): its map, its 20 second clock,
// the coins, what an enemy touch costs (5 coins, never below 0, no heart), and how
// the coins reach the wallet (once, the way every level coin does).
import 'dart:io';

import 'package:chronoquest/core/bonus_constants.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/game/bonus/bonus_game.dart';
import 'package:chronoquest/game/bonus/bonus_layout.dart';
import 'package:chronoquest/game/components/artifact_component.dart';
import 'package:chronoquest/game/components/coin_component.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/gate_component.dart';
import 'package:chronoquest/game/components/terrain_component.dart';
import 'package:chronoquest/game/enemy_behavior.dart';
import 'package:chronoquest/game/kaalaman_handler.dart';
import 'package:chronoquest/game/components/tile_platform_component.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/services/audio_service.dart';
import 'package:chronoquest/services/guest_mode.dart';
import 'package:chronoquest/services/server_clock.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart' show AudioPool;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// A widget test that, once it has said what it has to, lets the hero's short hurt pose
/// finish (its 600 ms timer), so no timer is left pending.
void _test(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    await body(tester);
    await tester.pump(const Duration(seconds: 1));
  });
}

Future<BonusGame> _mount(WidgetTester tester, {String era = 'pre-colonial'}) async {
  final game = BonusGame(eraId: era, levelNo: 3, characterId: 'rizal');
  await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
  await tester.pump();
  // The round builds its whole map on load, and every piece loads its own pictures:
  // give it time to finish (the hero, every coin and every walker mounted).
  bool built() =>
      game.isLoaded &&
      game.player.isLoaded &&
      game.world.children.whereType<CoinComponent>().length == game.layout.coins.length &&
      game.world.children.whereType<EnemyComponent>().length == game.layout.enemies.length &&
      game.world.children.whereType<GroundSection>().isNotEmpty;
  for (var i = 0; i < 200 && !(game.isLoaded && built()); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.pump(const Duration(milliseconds: 16));
  expect(game.isLoaded, isTrue);
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageDir =
      Directory.systemTemp.createTempSync('chronoquest_bonus_game_test_').path;

  setUpAll(() async {
    // No sound plugin in a test: the sound switch is off, as for a student who muted it.
    AudioService().setSoundEnabled(false);
    // The round loads like a real level, which asks for its sound pools: give it none
    // (there is no sound plugin in a test).
    AudioService().poolFactory =
        (file) => Future<AudioPool>.error(StateError('no sound in a test'));
    Hive.init(storageDir);
    await Hive.openBox('chronoquest');
  });


  // ─── the map, as data ──────────────────────────────────────────────────────
  group('the bonus map', () {
    test('holds about 58 coins, all on the map and in order', () {
      for (final era in BonusConstants.enemyKinds.keys) {
        final layout = BonusLayout.forEra(era);
        expect(layout.coins.length, inInclusiveRange(55, 60), reason: era);
        expect(layout.coins.length, BonusLayout.coinTotal);
        for (final c in layout.coins) {
          expect(c.x, inInclusiveRange(0, layout.mapWidth), reason: era);
        }
        final xs = layout.coins.map((c) => c.x).toList();
        expect([...xs]..sort(), xs, reason: 'left to right');
        expect(layout.coinsEndX, lessThan(layout.mapWidth));
      }
    });

    test('the walk from the start to the last coin takes about 17 seconds at full speed', () {
      final layout = BonusLayout.forEra('spanish');
      final seconds = (layout.coinsEndX - BonusConstants.spawnX) / 250;
      expect(seconds, inInclusiveRange(15, 19.5));
      expect(BonusConstants.roundSeconds, 20.0);
    });

    test('4 or 5 walkers with the era own art', () {
      for (final entry in BonusConstants.enemyKinds.entries) {
        final layout = BonusLayout.forEra(entry.key);
        expect(layout.enemies.length, inInclusiveRange(4, 5));
        for (final e in layout.enemies) {
          expect(entry.value, contains(e.kind), reason: entry.key);
        }
      }
    });

    test('every slab is at a height the jump reaches, and there are no pits', () {
      final layout = BonusLayout.forEra('ww2');
      for (final p in layout.platforms) {
        final up = BonusLayout.floorY - p.surfaceY;
        expect(up, inInclusiveRange(100, 113), reason: 'under the jump peak minus the landing margin');
        expect(p.endX, lessThan(layout.mapWidth));
      }
      // Slabs are apart from each other, so each is a stepping stone to jump to.
      for (var i = 1; i < layout.platforms.length; i++) {
        expect(layout.platforms[i].x - layout.platforms[i - 1].endX, greaterThan(150));
      }
    });

    test('the walkers stand clear of the start', () {
      final layout = BonusLayout.forEra('spanish');
      for (final e in layout.enemies) {
        expect(e.x - BonusConstants.enemyPatrol, greaterThan(BonusConstants.spawnX + 600));
      }
    });
  });

  // ─── the game built from it ────────────────────────────────────────────────
  _test('builds a floor with no pits and no water, the coins, the walkers and the slabs',
      (tester) async {
    final game = await _mount(tester);
    final layout = game.layout;

    final floors = game.world.children.whereType<GroundSection>().toList();
    expect(floors.length, 1, reason: 'one long floor: no pit anywhere');
    expect(floors.single.position.x, 0);
    expect(floors.single.size.x, layout.mapWidth);
    expect(game.groundSections.length, 1);
    expect(game.world.children.whereType<WaterComponent>(), isEmpty);
    expect(game.world.children.whereType<TerrainComponent>(), isEmpty);

    expect(game.world.children.whereType<CoinComponent>().length, layout.coins.length);
    expect(game.world.children.whereType<EnemyComponent>().length, layout.enemies.length);
    expect(game.platforms.length, layout.platforms.length);
    expect(game.world.children.whereType<TilePlatformComponent>().length, layout.platforms.length);

    // Nothing of a level: no artifact, no gate, no questions.
    expect(game.world.children.whereType<ArtifactComponent>(), isEmpty);
    expect(game.world.children.whereType<GateComponent>(), isEmpty);
    expect(game.questionPool, isNull);
    expect(game.player.position.x, BonusConstants.spawnX);
    expect(game.isBossLevel, isFalse);
  });

  // ─── the clock ─────────────────────────────────────────────────────────────
  _test('the clock is 20 seconds, starts at begin(), and ends the round once',
      (tester) async {
    final game = await _mount(tester);
    game.pauseEngine(); // the test drives time itself
    var told = 0;
    game.onTimeUp = () => told++;

    expect(game.timeLeft, 20.0);
    game.update(3);
    expect(game.timeLeft, 20.0, reason: 'not started: the hero can look around for free');

    game.begin();
    game.update(5);
    expect(game.timeLeft, closeTo(15, 1e-9));
    expect(game.clock.value, closeTo(15, 1e-9));
    expect(game.timeUp, isFalse);

    game.update(14.9);
    expect(game.timeUp, isFalse);
    expect(told, 0);

    game.update(.2);
    expect(game.timeUp, isTrue);
    expect(game.timeLeft, 0);
    expect(game.running, isFalse);
    expect(game.paused, isTrue, reason: 'the picture is held for the tally');
    expect(told, 1);

    game.update(5);
    expect(told, 1, reason: 'told once');
    expect(game.timeLeft, 0);
  });

  _test('coins count into the bonus counter, and not after the time is up',
      (tester) async {
    final game = await _mount(tester);
    game.pauseEngine();
    game.begin();
    var notified = 0;
    game.addListener(() => notified++);

    for (var i = 0; i < 9; i++) {
      game.collectCoin();
    }
    expect(game.counter, 9);
    expect(game.grabbed, 9);
    expect(notified, greaterThan(0));
    expect(game.playerCoins, 0, reason: 'a level coin count is another thing');

    game.forceTimeUp();
    game.collectCoin();
    expect(game.counter, 9, reason: 'a coin after the bell is not paid');
  });

  // ─── enemies ───────────────────────────────────────────────────────────────
  _test('an enemy touch takes 5 coins, never below 0, costs no heart, and the hero blinks',
      (tester) async {
    final game = await _mount(tester);
    game.pauseEngine();
    game.begin();
    var heartsLost = 0;
    game.onHeartLost = () => heartsLost++;
    final hearts = game.hearts;
    final enemy = game.world.children.whereType<EnemyComponent>().first;

    for (var i = 0; i < 12; i++) {
      game.collectCoin();
    }
    game.player.position = enemy.position.clone();
    game.player.onCollision({}, enemy);

    expect(game.counter, 7, reason: '12 - 5');
    expect(game.knockedLoose, 5);
    expect(game.hits, 1);
    expect(game.lastLost, 5);
    expect(game.hearts, hearts, reason: 'no heart is lost');
    expect(heartsLost, 0);
    expect(game.player.invincible, isTrue, reason: 'the hero blinks (its safe moment)');
    expect(game.levelEnded, isFalse);

    // Still inside the enemy a frame later: the blink protects, no second 5.
    game.player.onCollision({}, enemy);
    expect(game.counter, 7);
    expect(game.hits, 1);
  });

  _test('with fewer than 5 coins an enemy takes what there is, and never goes below 0',
      (tester) async {
    final game = await _mount(tester);
    game.pauseEngine();
    game.begin();
    var heartsLost = 0;
    game.onHeartLost = () => heartsLost++;
    final hearts = game.hearts;

    game.collectCoin();
    game.collectCoin();
    game.collectCoin();
    expect(game.loseLife(), isFalse, reason: 'it never fails the round');
    expect(game.counter, 0);
    expect(game.lastLost, 3, reason: 'only 3 were there to lose');

    expect(game.loseLife(), isFalse);
    expect(game.counter, 0, reason: 'never below 0');
    expect(game.lastLost, 0);
    expect(game.knockedLoose, 3);
    expect(game.hits, 2);
    expect(game.hearts, hearts);
    expect(heartsLost, 0);
    expect(game.levelEnded, isFalse);

    // The coins grabbed total is unchanged: grabbed 3, knocked loose 3, counter 0.
    expect(game.grabbed - game.knockedLoose, game.counter);
  });

  _test('the round has its own state: no shield, a full Kaalaman bar for the attack move',
      (tester) async {
    final game = await _mount(tester);
    game.pauseEngine();
    expect(game.shieldActive, isFalse);
    expect(game.kaalaman, CombatConstants.kaalamanStart);
    expect(game.canAttack, isTrue);
  });

  // ─── paying the wallet ─────────────────────────────────────────────────────
  _test('settle() pays the counter once, whoever calls it and however often',
      (tester) async {
    final game = await _mount(tester);
    game.pauseEngine();
    game.begin();
    final paid = <int>[];
    game.onPayout = paid.add;

    for (var i = 0; i < 14; i++) {
      game.collectCoin();
    }
    game.loseLife(); // 14 - 5 = 9
    game.forceTimeUp();

    final first = game.settle();
    final second = game.settle();
    expect(paid, [9]);
    expect(first.coins, 9);
    expect(first.grabbed, 14);
    expect(first.knockedLoose, 5);
    expect(first.leftEarly, isFalse);
    expect(second.coins, 9, reason: 'the same result, no second payment');
    expect(game.settled, isTrue);
  });

  _test('leaving early pays what was collected so far', (tester) async {
    final game = await _mount(tester);
    game.pauseEngine();
    game.begin();
    final paid = <int>[];
    game.onPayout = paid.add;

    for (var i = 0; i < 6; i++) {
      game.collectCoin();
    }
    game.update(4); // 4 of the 20 seconds
    final result = game.settle();

    expect(paid, [6]);
    expect(result.coins, 6);
    expect(result.leftEarly, isTrue);
    expect(game.timeUp, isFalse);
  });

  _test('an empty counter pays nothing at all', (tester) async {
    final game = await _mount(tester);
    game.pauseEngine();
    var paid = 0;
    game.onPayout = (_) => paid++;

    final result = game.settle();

    expect(paid, 0);
    expect(result.coins, 0);
  });

  _test('the coins go into the wallet through addCoins: saved on the phone, once',
      (tester) async {
    final wallet = GameNotifier(clock: ServerClock.fixed(DateTime.utc(2020, 1, 1, 12)))
      ..loadWallet('bonus-student');
    wallet.addCoins(100); // what the student had

    final game = await _mount(tester);
    game.pauseEngine();
    game.begin();
    game.onPayout = wallet.addCoins;
    for (var i = 0; i < 48; i++) {
      game.collectCoin();
    }
    game.loseLife();
    game.loseLife(); // 48 - 10 = 38
    game.forceTimeUp();

    game.settle();
    game.settle();

    expect(wallet.state.coins, 138);
    expect(StorageService.getWallet('bonus-student')!['coins'], 138,
        reason: 'saved on the phone like every other coin');
    final later = GameNotifier(clock: ServerClock.fixed(DateTime.utc(2020, 1, 1, 12)))
      ..loadWallet('bonus-student');
    expect(later.state.coins, 138, reason: 'and still there after a restart');
  });

  _test('a guest earns bonus coins the way a guest earns any coin (kept on the phone, never sent)',
      (tester) async {
    final wallet = GameNotifier(clock: ServerClock.fixed(DateTime.utc(2020, 1, 1, 12)))
      ..loadWallet(GuestMode.studentId);
    expect(wallet.state.coins, 0);

    final game = await _mount(tester);
    game.pauseEngine();
    game.begin();
    game.onPayout = wallet.addCoins;
    for (var i = 0; i < 20; i++) {
      game.collectCoin();
    }
    game.settle();

    expect(wallet.state.coins, 20);
    expect(StorageService.getWallet(GuestMode.studentId)!['coins'], 20);
    expect(StorageService.getWalletUnsynced(GuestMode.studentId), isFalse,
        reason: 'no upload is queued for a guest wallet in this test (no uploader)');
  });

  // The era's own art on the walkers.
  _test('the walkers wear the era art, and only pace', (tester) async {
    final game = await _mount(tester, era: 'ww2');
    final walkers = game.world.children.whereType<EnemyComponent>().toList();
    expect(walkers.length, game.layout.enemies.length);
    for (final w in walkers) {
      expect(BonusConstants.enemyKinds['ww2'], contains(w.enemyTypeOverride));
      expect(w.behaviorOverride, EnemyBehavior.walker);
      expect(w.blasts, isFalse);
    }
    expect(game.currentEra, 'ww2');
  });
}
