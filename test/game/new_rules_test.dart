// The 2026-11-02 rules: a Shield turns away a hit as well as a wrong answer, hearts
// found in a level, the halfway flag, the softer fall into a river, the extras laid
// on every authored level, and the free power-ups.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/boss_shockwave.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/halfway_flag_component.dart';
import 'package:chronoquest/game/components/heart_pickup_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_input.dart';
import 'package:chronoquest/game/level_extras.dart';
import 'package:chronoquest/game/level_loader.dart';
import 'package:chronoquest/game/run_stats.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/services/server_clock.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

Future<SpriteAnimation> _blankAnim() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 1, 1));
  final image = await recorder.endRecording().toImage(1, 1);
  return SpriteAnimation.spriteList([Sprite(image)], stepTime: 1.0);
}

Future<ChronoGame> _bareGame({double playerWorldX = 400}) async {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.images.prefix = 'assets/';
  final player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(96, 120)
    ..position = Vector2(playerWorldX, game.groundY - 120)
    ..walkAnimation = await _blankAnim()
    ..jumpAnim = await _blankAnim()
    ..hurtAnim = await _blankAnim();
  player.animation = player.walkAnimation;
  player.game = game;
  game.player = player;
  final input = GameInput(game: game);
  input.joystick = JoystickComponent(background: CircleComponent(radius: 10));
  game.gameInput = input;
  return game;
}

EnemyComponent _enemyAt(ChronoGame game, double x) {
  final enemy =
      EnemyComponent(eraId: 'spanish', enemyTypeOverride: 'spanish_soldier')
        ..size = Vector2(90, 108)
        ..position = Vector2(x, game.groundY - 108);
  enemy.game = game;
  return enemy;
}

LoadedLevel _level(int era, int n) => LevelLoader.parse(
    File('assets/tiles/levels/era${era}_$n.tmx').readAsStringSync());

/// Every authored non-boss level as (era id, era number, level number).
List<(String, int, int)> _ordinaryLevels() {
  const ids = ['pre-colonial', 'spanish', 'nationalism', 'american', 'ww2', 'modern'];
  const counts = [10, 5, 7, 8, 8, 5];
  return [
    for (var e = 0; e < 6; e++)
      for (var n = 1; n < counts[e]; n++) (ids[e], e + 1, n),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('a Shield turns away a hit', () {
    test('no heart is lost, the shield is used up, and the usual shove follows',
        () async {
      final game = await _bareGame();
      game.shieldActive = true;
      final hearts = game.hearts;

      game.player.onCollision({}, _enemyAt(game, 430));

      expect(game.hearts, hearts);
      expect(game.shieldActive, isFalse);
      expect(game.player.invincible, isTrue,
          reason: 'the safe moment still follows, so it cannot be hit twice');
    });

    test('without a shield the same hit costs a heart', () async {
      final game = await _bareGame();
      final hearts = game.hearts;
      game.player.onCollision({}, _enemyAt(game, 430));
      expect(game.hearts, hearts - 1);
    });
  });

  group('hearts found in a level', () {
    test('a heart is given back, up to the five, and the pool is told', () async {
      final game = await _bareGame();
      var told = 0;
      game.onHeartGained = () => told++;
      game.hearts = 3;

      expect(game.gainHeart(), isTrue);
      expect(game.hearts, 4);
      expect(told, 1);

      game.hearts = GameConstants.maxHearts;
      expect(game.gainHeart(), isFalse);
      expect(game.hearts, GameConstants.maxHearts);
      expect(told, 1, reason: 'nothing was given');
    });

    test('the halfway flag gives one heart, once per try, and sets the restart point',
        () async {
      final game = await _bareGame();
      game.hearts = 2;
      game.reachFlag(5000);
      game.reachFlag(5000);
      expect(game.hearts, 3, reason: 'once only');
      expect(game.stats.flagReached, isTrue);
      expect(game.stats.checkpointX, 5000);
    });

    test('the flag component fires when the student walks past its pole', () async {
      final game = await _bareGame(playerWorldX: 100);
      game.hearts = 2;
      final flag = HalfwayFlagComponent(poleX: 900, surfaceY: game.groundY)
        ..game = game;
      flag.update(0.016);
      expect(flag.reached, isFalse);
      expect(game.hearts, 2);
      game.player.position.x = 880; // the middle of the student is now past the pole
      flag.update(0.016);
      expect(flag.reached, isTrue);
      expect(game.hearts, 3);
    });

    test('a heart pickup is taken when hearts are missing and left when they are full',
        () async {
      final game = await _bareGame();
      final heart = HeartPickupComponent(spawnPosition: Vector2(500, 300))
        ..game = game;
      game.hearts = GameConstants.maxHearts;
      heart.collect();
      expect(heart.collected, isFalse, reason: 'full: it stays for later');

      game.hearts = 4;
      heart.collect();
      expect(heart.collected, isTrue);
      expect(game.hearts, 5);
    });
  });

  group('the fall into a river is softer', () {
    test('costs one heart, comes back with a safe moment, a shorter way back', () async {
      final game = await _bareGame(playerWorldX: 1000);
      game.player.respawnAnchorX = 1000;
      final hearts = game.hearts;

      game.playerFellInGap();

      expect(game.hearts, hearts - 1);
      expect(game.stats.falls, 1);
      expect(game.player.invincible, isTrue);
      expect(game.player.position.x, 1000 - PlayerComponent.respawnRunway);
      expect(PlayerComponent.respawnRunway, lessThan(300));
    });

    test('after the flag a fall never puts the student back behind it', () async {
      final game = await _bareGame(playerWorldX: 1000);
      final section = GroundSection(
        sectionWidth: 3000,
        sectionPosition: Vector2(0, game.groundY),
        sectionHeight: 60,
        drawn: false,
      )..size = Vector2(3000, 60);
      game.groundSections.add(section);
      game.stats.checkpointX = 950;
      game.player.respawnAnchorX = 1000;

      game.player.respawn();

      expect(game.player.position.x, 950,
          reason: 'the run-up would have been at 800, behind the flag');
    });
  });

  group('the new pictures draw', () {
    test('the flag (grey, then gold), the shockwave both ways, and the shield bubble',
        () async {
      final game = await _bareGame();
      void draw(Component c) {
        final rec = ui.PictureRecorder();
        c.render(ui.Canvas(rec));
        rec.endRecording().dispose();
      }

      final flag = HalfwayFlagComponent(poleX: 900, surfaceY: game.groundY)
        ..game = game;
      draw(flag);
      flag.reached = true;
      flag.update(0.5);
      draw(flag);

      for (final dir in [1, -1]) {
        draw(BossShockwave(direction: dir, start: Vector2(100, 600))..game = game);
      }

      game.shieldActive = true;
      draw(game.player);
      game.player.facingRight = false;
      draw(game.player);
    });
  });

  group('the run counts what the rules look back on', () {
    test('every third right answer in a row is a streak bonus', () {
      final s = RunStats();
      expect([for (var i = 0; i < 6; i++) s.answered(true)],
          [false, false, true, false, false, true]);
      expect(s.bestStreak, 6);
      s.answered(false);
      expect(s.correctStreak, 0);
      expect(s.bestStreak, 6);
    });

    test('the high road needs every high coin, and some to take', () {
      final s = RunStats();
      expect(s.tookHighRoad, isFalse, reason: 'none to take');
      s.highCoinsTotal = 4;
      s.highCoinsTaken = 3;
      expect(s.tookHighRoad, isFalse);
      s.highCoinsTaken = 4;
      expect(s.tookHighRoad, isTrue);
    });

    test('coins on a high platform are counted apart', () async {
      final game = await _bareGame();
      game.collectCoin(onHighPlatform: true);
      game.collectCoin();
      expect(game.playerCoins, 2);
      expect(game.stats.highCoinsTaken, 1);
    });
  });

  group('extras laid on every authored level', () {
    test('every ordinary level has a flag on solid ground, clear of artifacts and enemies',
        () {
      for (final (id, era, n) in _ordinaryLevels()) {
        final level = _level(era, n);
        final x = LevelExtras.plan(level, eraId: id, levelNo: n);
        expect(x.flag, isNotNull, reason: '$id $n has a flag');
        final flag = x.flag!;
        final block = level.blockAt(flag.x);
        expect(block, isNotNull, reason: '$id $n: the flag stands on ground');
        expect(block!.topY, flag.surfaceY, reason: '$id $n');
        expect(flag.x, greaterThan(level.spawnX));
        expect(flag.x, lessThan(level.exitX));
        for (final e in level.entities
            .where((e) => e.type == 'artifact' || e.type == 'enemy')) {
          expect((e.x - flag.x).abs(), greaterThanOrEqualTo(LevelExtras.flagClearance),
              reason: '$id $n: nothing stands on the flag');
        }
        // About halfway.
        final mid = (level.spawnX + level.exitX) / 2;
        expect((flag.x - mid).abs(), lessThan((level.exitX - level.spawnX) * .2),
            reason: '$id $n: the flag is near the middle');
      }
    });

    test('about half the levels hold a heart, always on a high platform', () {
      var withHeart = 0;
      final levels = _ordinaryLevels();
      for (final (id, era, n) in levels) {
        final level = _level(era, n);
        final x = LevelExtras.plan(level, eraId: id, levelNo: n);
        if (x.heart == null) continue;
        withHeart++;
        final onPlatform = x.highPlatforms.any((p) =>
            x.heart!.x >= p.x - 4 &&
            x.heart!.x + 44 <= p.x + p.width + 4 &&
            x.heart!.y < p.y);
        expect(onPlatform, isTrue, reason: '$id $n: the heart rests on a high platform');
      }
      expect(withHeart, greaterThan(levels.length ~/ 4));
      expect(withHeart, lessThan(levels.length * 3 ~/ 4 + 1));
    });

    test('the same level always gets the same extras', () {
      final level = _level(1, 3);
      final a = LevelExtras.plan(level, eraId: 'pre-colonial', levelNo: 3);
      final b = LevelExtras.plan(level, eraId: 'pre-colonial', levelNo: 3);
      expect(a.flag, b.flag);
      expect(a.heart?.x, b.heart?.x);
      expect(a.bonusCoins.length, b.bonusCoins.length);
    });

    test('extra coins lie on high platforms and count as high coins', () {
      var anyBonus = false;
      for (final (id, era, n) in _ordinaryLevels()) {
        final x = LevelExtras.plan(_level(era, n), eraId: id, levelNo: n);
        if (x.bonusCoins.isNotEmpty) anyBonus = true;
        for (final c in x.bonusCoins) {
          expect(
              x.highPlatforms.any((p) =>
                  c.x >= p.x - 22 && c.x + 42 <= p.x + p.width + 22 && c.y < p.y),
              isTrue,
              reason: '$id $n: a coin at ${c.x} lies on a high platform');
        }
        expect(x.highCoinCount, x.highAuthoredCoins.length + x.bonusCoins.length);
      }
      expect(anyBonus, isTrue);
    });

    test('a boss arena gets none of it', () {
      final arena = _level(2, 5);
      expect(arena.isArena, isTrue);
      final x = LevelExtras.plan(arena, eraId: 'spanish', levelNo: 5);
      expect(x.flag, isNull);
      expect(x.heart, isNull);
      expect(x.bonusCoins, isEmpty);
    });

    test('every artifact stands on the ground, so each one is on the way', () {
      for (final (id, era, n) in _ordinaryLevels()) {
        final level = _level(era, n);
        for (final a in level.entities.where((e) => e.type == 'artifact')) {
          final block = level.blockAt(a.x + 36);
          expect(block, isNotNull, reason: '$id $n: artifact at ${a.x} has ground under it');
          expect(block!.topY, a.y, reason: '$id $n: and stands on its surface');
        }
      }
    });
  });

  group('free power-ups', () {
    final dir = Directory.systemTemp.createTempSync('chronoquest_newrules_').path;

    setUpAll(() async {
      Hive.init(dir);
      await Hive.openBox('chronoquest');
    });

    tearDownAll(() async {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await Hive.close();
      try {
        Directory(dir).deleteSync(recursive: true);
      } catch (_) {}
    });

    // A new notifier saves the hearts without anyone waiting for it.
    tearDown(() => Future<void>.delayed(const Duration(milliseconds: 150)));

    GameNotifier fresh(String student) => GameNotifier(
        clock: ServerClock.fixed(DateTime.utc(2020, 1, 1, 12)))
      ..loadWallet(student);

    test('a boss beaten gives one of each', () {
      final n = fresh('np1');
      final given = n.grantAllPowerUps();
      expect(given, hasLength(3));
      expect(n.state.powerUps.fiftyFifty, 1);
      expect(n.state.powerUps.shield, 1);
      expect(n.state.powerUps.timeFreeze, 1);
    });

    test('a level with no wrong answer gives one, of a kind picked at random', () {
      final n = fresh('np2');
      final kinds = <PowerUpKind>{};
      for (var i = 0; i < 60; i++) {
        kinds.add(n.grantRandomPowerUp());
      }
      expect(kinds, PowerUpKind.values.toSet(), reason: 'all three come up in time');
      final total = n.state.powerUps.fiftyFifty +
          n.state.powerUps.shield +
          n.state.powerUps.timeFreeze;
      expect(total, 60, reason: 'one power-up each time');
    });

    test('they are kept on the phone', () {
      fresh('np3').grantAllPowerUps();
      final again = fresh('np3');
      expect(again.state.powerUps.shield, 1);
    });

    test('a heart found in a level goes into the pool, up to the five', () {
      final n = fresh('np4');
      StorageService.saveHeartsState(const HeartsState(count: 3, regenStartMs: 1));
      n.loadWallet('np4b');
      final before = n.state.hearts.count;
      n.gainHeart();
      expect(n.state.hearts.count, before + 1);
    });
  });

  test('the new numbers are the ones agreed', () {
    expect(CombatConstants.kaalamanRegenSeconds, 8);
    expect(CombatConstants.streakForBonus, 3);
    expect(GameConstants.maxHearts, 5);
  });
}
