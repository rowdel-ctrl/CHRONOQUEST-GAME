// Chaser warning-then-attack moves (2026-11-10): the spirit, propaganda and cloud kinds
// stop and fuse when close, then burst (one heart inside the ring, none if the student
// is outside it or jumping clear, no coins) or pop harmlessly if hit during the fuse;
// a soldier the map made a chaser crouches, dashes, stands tired, then chases again.
// `blasts: false` keeps all of them plain chasers.
//
// Bare-game pattern with a stub-animation player (a burst that hurts goes through
// loseLife -> triggerHurt, which needs the hurt animation). The coin tests need real
// effects, so they use a mounted GameWidget like enemy_death_test.dart.
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/coin_component.dart';
import 'package:chronoquest/game/components/enemy_burst_component.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/enemy_behavior.dart';
import 'package:chronoquest/game/game_collision.dart';
import 'package:chronoquest/game/game_input.dart';
import 'package:chronoquest/game/game_spawning.dart';

Future<SpriteAnimation> _blankAnim() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 1, 1));
  final image = await recorder.endRecording().toImage(1, 1);
  return SpriteAnimation.spriteList([Sprite(image)], stepTime: 1.0);
}

Future<ChronoGame> _bareGame() async {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.images.prefix = 'assets/';
  final player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(96, 120)
    ..position = Vector2(0, game.groundY - 120)
    ..walkAnimation = await _blankAnim()
    ..jumpAnim = await _blankAnim()
    ..hurtAnim = await _blankAnim();
  player.animation = player.walkAnimation;
  player.game = game;
  game.player = player;
  final input = GameInput(game: game);
  input.joystick = JoystickComponent(background: CircleComponent(radius: 10));
  game.gameInput = input;
  // No audio plugin in tests.
  if (game.audioService.soundEnabled) {
    game.audioService.toggleSound();
  }
  return game;
}

Future<EnemyComponent> _mount(
  ChronoGame game,
  String type, {
  EnemyBehavior? behavior,
  bool blasts = true,
  double x = 1500,
  VoidCallback? onDefeated,
}) async {
  final enemy = EnemyComponent(
    eraId: 'spanish',
    enemyTypeOverride: type,
    worldX: x,
    behaviorOverride: behavior,
    blasts: blasts,
    onDefeated: onDefeated,
  );
  game.world.add(enemy);
  await game.ready();
  await enemy.loaded;
  return enemy;
}

/// Puts the student [dx] units right of the enemy's middle (negative = left), feet on
/// the enemy's feet line, lifted by [lift].
void _place(ChronoGame game, EnemyComponent enemy, double dx,
    {double lift = 0}) {
  final p = game.player;
  p.position = Vector2(
    enemy.position.x + enemy.size.x / 2 + dx - p.size.x / 2,
    enemy.position.y + enemy.size.y - p.size.y - lift,
  );
}

/// Runs the enemy for [seconds] in 1/60 s steps; stops early when [until] is true.
double _run(EnemyComponent e, double seconds, {bool Function()? until}) {
  var t = 0.0;
  while (t < seconds - 1e-9) {
    if (until != null && until()) break;
    e.update(1 / 60);
    t += 1 / 60;
  }
  return t;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('chase speed', () {
    test('is 140, still slower than the student', () {
      expect(CombatConstants.chaserSpeed, 140);
      expect(CombatConstants.chaserSpeed, lessThan(250));
    });

    test('a chaser covers 140 units in a second', () async {
      final game = await _bareGame();
      final e = await _mount(game, 'dark_spirit', blasts: false);
      _place(game, e, -400);
      final before = e.position.x;
      _run(e, 1);
      expect(before - e.position.x, closeTo(140, 3));
    });
  });

  group('blast kinds fuse', () {
    test('fuse at 100 units, not at 150', () async {
      for (final kind in ['dark_spirit', 'propaganda', 'misinfo_cloud']) {
        final game = await _bareGame();
        final e = await _mount(game, kind);
        _place(game, e, -150);
        e.update(1 / 60);
        expect(e.isFusing, false, reason: '$kind at 150');
        _place(game, e, -CombatConstants.blastArmRange + 1);
        final x = e.position.x;
        e.update(1 / 60);
        expect(e.isFusing, true, reason: '$kind at 99');
        expect(e.position.x, x, reason: 'and it stops');
        _run(e, 0.3);
        expect(e.position.x, x, reason: 'and stays stopped');
      }
    });

    test('blasts: false never fuses, only chases', () async {
      final game = await _bareGame();
      final e = await _mount(game, 'dark_spirit', blasts: false);
      _place(game, e, -90);
      final x = e.position.x;
      _run(e, 1.5, until: () => e.isFusing);
      expect(e.isFusing, false);
      expect(e.defeated, false);
      expect(e.position.x, lessThan(x), reason: 'it walked on at the student');
    });

    test('shows its attack picture, except propaganda which keeps walking',
        () async {
      final game = await _bareGame();
      final spirit = await _mount(game, 'dark_spirit');
      _place(game, spirit, -90);
      spirit.update(1 / 60);
      expect(spirit.shownPicture, 'attack');

      final flyer = await _mount(game, 'propaganda', x: 3000);
      _place(game, flyer, -90);
      flyer.update(1 / 60);
      expect(flyer.isFusing, true);
      expect(flyer.shownPicture, 'walk');
    });

    test('flickers white faster and faster', () async {
      final game = await _bareGame();
      final e = await _mount(game, 'dark_spirit');
      _place(game, e, -90);
      e.update(1 / 60);
      final samples = <double>[];
      for (var i = 0; i < 40; i++) {
        samples.add(e.fuseFlashAlpha);
        e.update(1 / 60);
        if (!e.isFusing) break;
      }
      expect(samples.reduce((a, b) => a < b ? a : b), lessThan(0.45));
      expect(samples.reduce((a, b) => a > b ? a : b), greaterThan(0.7));
      // Count flashes (upward crossings of the middle) in each half of the fuse.
      int crossings(List<double> s) {
        var n = 0;
        for (var i = 1; i < s.length; i++) {
          if (s[i - 1] < 0.575 && s[i] >= 0.575) n++;
        }
        return n;
      }

      final half = samples.length ~/ 2;
      expect(crossings(samples.sublist(half)),
          greaterThan(crossings(samples.sublist(0, half))));
    });

    test('every state draws without errors', () async {
      final game = await _bareGame();
      final blast = await _mount(game, 'misinfo_cloud');
      _place(game, blast, -90);
      blast.update(1 / 60);
      final soldier = await _mount(game, 'spanish_soldier',
          behavior: EnemyBehavior.chaser, x: 3000);
      _place(game, soldier, -120);
      soldier.update(1 / 60);
      for (final e in [blast, soldier]) {
        e.render(ui.Canvas(ui.PictureRecorder()));
        _run(e, 0.2);
        e.render(ui.Canvas(ui.PictureRecorder()));
      }
      expect(blast.isFusing, true);
      expect(soldier.isCrouching, true);
    });
  });

  group('self-burst', () {
    test('bursts when the fuse runs out and costs exactly one heart', () async {
      final game = await _bareGame();
      var defeated = 0;
      final e = await _mount(game, 'dark_spirit', onDefeated: () => defeated++);
      final hearts = game.hearts;
      _place(game, e, -90);
      e.update(1 / 60);
      expect(e.isFusing, true);
      _run(e, 0.5);
      expect(e.defeated, false, reason: 'still burning');
      expect(game.hearts, hearts);
      _run(e, 0.4);
      expect(e.defeated, true, reason: 'burst');
      expect(game.hearts, hearts - 1);
      expect(defeated, 0, reason: 'a self-burst is not a kill');
      await game.ready();
      expect(game.world.children.whereType<EnemyBurstComponent>(), isNotEmpty);
    });

    test('a student who ran outside the ring loses nothing', () async {
      final game = await _bareGame();
      final e = await _mount(game, 'dark_spirit');
      final hearts = game.hearts;
      _place(game, e, -90);
      e.update(1 / 60);
      _place(game, e, -(CombatConstants.blastRadius + 20));
      _run(e, 1);
      expect(e.defeated, true);
      expect(game.hearts, hearts);
    });

    test('a student jumping clear (feet 60 or more above) loses nothing',
        () async {
      final game = await _bareGame();
      final e = await _mount(game, 'dark_spirit');
      final hearts = game.hearts;
      _place(game, e, -90);
      e.update(1 / 60);
      _place(game, e, -90, lift: CombatConstants.blastHeight);
      _run(e, 1);
      expect(e.defeated, true);
      expect(game.hearts, hearts);
    });

    test('feet only a little above the ground still get hurt', () async {
      final game = await _bareGame();
      final e = await _mount(game, 'dark_spirit');
      final hearts = game.hearts;
      _place(game, e, -90);
      e.update(1 / 60);
      _place(game, e, -90, lift: CombatConstants.blastHeight - 20);
      _run(e, 1);
      expect(game.hearts, hearts - 1);
    });

    test('respects the safe moment after a hit', () async {
      final game = await _bareGame();
      final e = await _mount(game, 'dark_spirit');
      game.player.takeHazardHit(knockbackDirection: 1); // starts invincibility
      final hearts = game.hearts;
      _place(game, e, -90);
      e.update(1 / 60);
      _run(e, 1);
      expect(e.defeated, true);
      expect(game.hearts, hearts, reason: 'no second hit inside the safe time');
    });
  });

  group('a hit during the fuse', () {
    test('pops it harmlessly, as a normal defeat with a small burst', () async {
      final game = await _bareGame();
      var defeated = 0;
      final e =
          await _mount(game, 'misinfo_cloud', onDefeated: () => defeated++);
      final hearts = game.hearts;
      _place(game, e, -90);
      e.update(1 / 60);
      expect(e.isFusing, true);
      e.takeHit();
      expect(e.defeated, true);
      expect(e.isFusing, false, reason: 'no stuck fuse');
      expect(defeated, 1, reason: 'counts as beaten');
      await game.ready();
      final bursts = game.world.children.whereType<EnemyBurstComponent>();
      expect(bursts.length, 1);
      expect(bursts.first.burstScale, CombatConstants.popBurstScale);
      expect(bursts.first.style, BurstStyle.storm);
      _run(e, 1);
      expect(game.hearts, hearts, reason: 'and nothing blasts afterwards');
    });
  });

  group('dash chasers', () {
    test('crouch, dash 130, stand tired, then chase again', () async {
      final game = await _bareGame();
      final e =
          await _mount(game, 'spanish_soldier', behavior: EnemyBehavior.chaser);
      final hearts = game.hearts;
      final start = e.position.x;
      _place(game, e, -135);
      e.update(1 / 60);
      expect(e.isCrouching, true);
      expect(e.position.x, start, reason: 'stopped while it crouches');

      final crouched = 1 / 60 + _run(e, 1, until: () => e.isDashing);
      expect(e.isDashing, true);
      expect(crouched, closeTo(CombatConstants.dashCrouch, 0.04));
      expect(e.shownPicture, 'attack');

      final dashed = _run(e, 1, until: () => e.isTired);
      expect(e.isTired, true);
      expect(dashed, closeTo(CombatConstants.dashDuration, 0.04));
      expect(start - e.position.x, closeTo(CombatConstants.dashDistance, 8));
      expect(e.patrolDirection, -1, reason: 'towards the student');

      // The student has moved off; it rests, then chases at 140.
      _place(game, e, -400);
      final tiredAt = e.position.x;
      final rested = _run(e, 2, until: () => !e.isTired);
      expect(rested, closeTo(CombatConstants.dashTired, 0.04));
      expect(e.position.x, tiredAt, reason: 'did not move while tired');
      final chaseFrom = e.position.x;
      _run(e, 1);
      expect(chaseFrom - e.position.x, closeTo(CombatConstants.chaserSpeed, 4));
      expect(game.hearts, hearts, reason: 'the dash alone changes no hearts');
    });

    test('a student standing in its way is hit as by any enemy', () async {
      final game = await _bareGame();
      final e =
          await _mount(game, 'spanish_soldier', behavior: EnemyBehavior.chaser);
      _place(game, e, -135);
      e.update(1 / 60);
      _run(e, 1, until: () => e.isDashing);
      _run(e, 1, until: () => e.isTired);
      // Normal contact damage: the player's own check against the enemy's hit area.
      final hearts = game.hearts;
      game.player.position.x = e.position.x - 20;
      game.player.onCollision({}, e);
      expect(game.hearts, hearts - 1);
    });

    test('blasts: false never crouches or dashes', () async {
      final game = await _bareGame();
      final e = await _mount(game, 'spanish_soldier',
          behavior: EnemyBehavior.chaser, blasts: false);
      _place(game, e, -120);
      var moved = 0.0;
      for (var i = 0; i < 90; i++) {
        final before = e.position.x;
        e.update(1 / 60);
        moved += before - e.position.x;
        expect(e.isCrouching || e.isDashing || e.isTired, false);
      }
      expect(moved, greaterThan(0), reason: 'it walked at the student');
    });

    test('a soldier with no override stays a walker', () async {
      final game = await _bareGame();
      final e = await _mount(game, 'spanish_soldier');
      _place(game, e, -120);
      _run(e, 2);
      expect(e.isCrouching || e.isDashing || e.isTired, false);
      expect(e.defeated, false);
    });

    test('a hit at any time in the move kills it and leaves no stuck state',
        () async {
      for (final stage in ['crouch', 'dash', 'tired']) {
        final game = await _bareGame();
        final e = await _mount(game, 'spanish_soldier',
            behavior: EnemyBehavior.chaser);
        _place(game, e, -135);
        e.update(1 / 60);
        if (stage != 'crouch') _run(e, 1, until: () => e.isDashing);
        if (stage == 'tired') _run(e, 1, until: () => e.isTired);
        e.takeHit();
        expect(e.defeated, true, reason: stage);
        expect(e.isCrouching || e.isDashing || e.isTired, false, reason: stage);
      }
    });

    test('never dashes off a ledge', () async {
      final game = await _bareGame();
      game.groundSections.add(
        GroundSection(
          sectionWidth: 1000,
          sectionPosition: Vector2(0, game.groundY),
        )..size = Vector2(1000, 60),
      );
      final e = await _mount(game, 'spanish_soldier',
          behavior: EnemyBehavior.chaser, x: 880);
      final start = e.position.x;
      _place(game, e, 125); // to its right, towards the end of the ground
      e.update(1 / 60);
      expect(e.isCrouching, true);
      for (var i = 0; i < 60; i++) {
        e.update(1 / 60);
        final centre = e.position.x + e.size.x / 2;
        final half = e.size.x * footSpanFraction / 2;
        expect(game.isGroundUnder(centre - half, centre + half), true,
            reason: 'frame $i: left the ground at ${e.position.x}');
      }
      expect(e.position.x - start, lessThan(CombatConstants.dashDistance));
      expect(e.position.x - start, greaterThan(0), reason: 'it did move');
    });
  });

  group('burst picture', () {
    for (final style in BurstStyle.values) {
      test('${style.name} draws and removes itself', () async {
        final game = await _bareGame();
        final burst = EnemyBurstComponent(
            style: style, centre: Vector2(100, 100), seed: 3);
        game.world.add(burst);
        await game.ready();
        for (var t = 0.0; t < CombatConstants.burstDuration; t += 0.05) {
          burst.update(0.05);
          burst.render(ui.Canvas(ui.PictureRecorder()));
        }
        expect(burst.age, greaterThanOrEqualTo(CombatConstants.burstDuration));
      });
    }
  });

  group('coins', () {
    Future<_Game> mountWidget(WidgetTester tester, EnemyComponent e) async {
      final game = _Game();
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      game.world.add(e);
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 16));
      }
      return game;
    }

    Future<void> settle(WidgetTester tester, ChronoGame game) async {
      game.updateTree(0.001);
      for (var i = 0; i < 80; i++) {
        game.updateTree(0.02);
      }
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    testWidgets('a self-burst drops no coins', (tester) async {
      var defeated = 0;
      final e = EnemyComponent(
          eraId: 'pre-colonial',
          enemyTypeOverride: 'dark_spirit',
          worldX: 1500,
          onDefeated: () => defeated++);
      final game = await mountWidget(tester, e);
      final coinsBefore = game.world.children.whereType<CoinComponent>().length;
      // Feet well above the blast so nothing needs the hurt animation.
      _place(game, e, -90, lift: 100);
      e.update(1 / 60);
      expect(e.isFusing, true);
      for (var i = 0; i < 50; i++) {
        e.update(1 / 60);
      }
      expect(e.defeated, true);
      await settle(tester, game);
      expect(game.world.children.whereType<CoinComponent>().length, coinsBefore,
          reason: 'no coin was added by the burst');
      expect(e.isMounted, false, reason: 'it is gone');
      expect(defeated, 0);
    });

    testWidgets('a pop drops coins like a normal kill', (tester) async {
      var defeated = 0;
      final e = EnemyComponent(
          eraId: 'pre-colonial',
          enemyTypeOverride: 'dark_spirit',
          worldX: 1500,
          onDefeated: () => defeated++);
      final game = await mountWidget(tester, e);
      final coinsBefore = game.world.children.whereType<CoinComponent>().length;
      _place(game, e, -90);
      e.update(1 / 60);
      expect(e.isFusing, true);
      e.takeHit();
      await settle(tester, game);
      expect(
          game.world.children.whereType<CoinComponent>().length - coinsBefore,
          greaterThanOrEqualTo(CombatConstants.coinDropMin));
      expect(defeated, 1);
    });
  });
}

class _Game extends ChronoGame {
  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    camera.viewfinder.anchor = Anchor.topLeft;
    player = PlayerComponent(characterId: 'rizal')
      ..size = Vector2(96, 120)
      ..position = Vector2(0, groundY - 120);
    setupSpawning();
    if (audioService.soundEnabled) audioService.toggleSound();
  }
}
