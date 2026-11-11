// The five surprises of the higher levels (2026-11-10): the hopper, the ground pop, the
// falling rock, the thrower and the golden runner. Every one must be fair: a warning of
// at least 0.5 s before anything can hurt, one heart at most, nothing faster than the
// student, at most two going on at once, never in levels 1 to 3 or a boss room.
//
// Bare-game pattern with a stub-animation player, like chaser_blast_test.dart: the
// components are updated by hand in 1/60 s steps. The coin test needs real effects, so it
// mounts a GameWidget like enemy_death_test.dart.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/core/surprise_constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/coin_component.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/falling_rock_component.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/ground_pop_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/components/thrown_item_component.dart';
import 'package:chronoquest/game/enemy_behavior.dart';
import 'package:chronoquest/game/enemy_moves.dart';
import 'package:chronoquest/game/game_collision.dart';
import 'package:chronoquest/game/game_input.dart';
import 'package:chronoquest/game/game_spawning.dart';
import 'package:chronoquest/game/level_loader.dart';
import 'package:chronoquest/game/surprise_art.dart';
import 'package:chronoquest/game/surprise_rules.dart';

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
  player.isOnGround = true;
  player.game = game;
  game.player = player;
  final input = GameInput(game: game);
  input.joystick = JoystickComponent(background: CircleComponent(radius: 10));
  game.gameInput = input;
  if (game.audioService.soundEnabled) game.audioService.toggleSound();
  return game;
}

Future<EnemyComponent> _mount(
  ChronoGame game,
  String type,
  EnemySurprise surprise, {
  double x = 1500,
  double? patrol,
  VoidCallback? onDefeated,
}) async {
  final enemy = EnemyComponent(
    eraId: 'spanish',
    enemyTypeOverride: type,
    worldX: x,
    patrolRangeOverride: patrol,
    surprise: surprise,
    behaviorOverride:
        surprise == EnemySurprise.none || surprise == EnemySurprise.thrower
            ? null
            : EnemyBehavior.walker,
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
    enemy.groundTop + enemy.size.y - p.size.y - lift,
  );
}

/// Puts the student with the middle of their body [dx] right of world x [x], feet on
/// [groundY], lifted by [lift].
void _stand(ChronoGame game, double x, double dx, double groundY,
    {double lift = 0}) {
  final p = game.player;
  p.position = Vector2(x + dx - p.size.x / 2, groundY - p.size.y - lift);
}

extension on EnemyComponent {
  /// Where this enemy's box top is when it stands on the ground (not hopping).
  double get groundTop => game.groundY - size.y;
}

const double _dt = 1 / 60;

/// Updates the enemy for [seconds]; stops early when [until] is true. Returns the time spent.
double _run(EnemyComponent e, double seconds, {bool Function()? until}) {
  var t = 0.0;
  while (t < seconds - 1e-9) {
    if (until != null && until()) break;
    e.update(_dt);
    t += _dt;
  }
  return t;
}

/// Updates any component the same way.
double _step(Component c, double seconds, {bool Function()? until}) {
  var t = 0.0;
  while (t < seconds - 1e-9) {
    if (until != null && until()) break;
    c.update(_dt);
    t += _dt;
  }
  return t;
}

void _draws(Component c) => c.render(ui.Canvas(ui.PictureRecorder()));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─── The rules that hold for every surprise ──────────────────────────────
  group('fair for children', () {
    test('every warning is at least half a second', () {
      const warnings = {
        'hopper squat': SurpriseConstants.hopSquat,
        'ground pop crack': SurpriseConstants.popWarn,
        'falling rock shadow': SurpriseConstants.rockWarn,
        'thrower flash': SurpriseConstants.throwWindup,
        // The ring shows the whole time, so the real warning is flash plus flight.
        'thrower ring':
            SurpriseConstants.throwWindup + SurpriseConstants.throwFlight,
      };
      warnings.forEach((name, seconds) {
        expect(seconds, greaterThanOrEqualTo(SurpriseConstants.minWarning),
            reason: name);
      });
      expect(SurpriseConstants.minWarning, 0.5);
    });

    test('nothing moves faster than the student', () {
      expect(
          SurpriseConstants.hopSpeed, lessThan(PlayerComponent.forwardSpeed));
      expect(SurpriseConstants.goldenSpeed,
          lessThan(PlayerComponent.forwardSpeed));
      expect(SurpriseConstants.hopDistance / SurpriseConstants.hopDuration,
          closeTo(200, 0.01));
      expect(SurpriseConstants.goldenDistance / SurpriseConstants.goldenRunTime,
          closeTo(200, 0.01));
    });

    test('the timings are the approved ones', () {
      expect(SurpriseConstants.hopSquat, 0.55);
      expect(SurpriseConstants.hopDuration, 0.7);
      expect(SurpriseConstants.hopDistance, 140);
      expect(SurpriseConstants.hopDizzy, 1.4);
      expect(SurpriseConstants.popWarn, 0.6);
      expect(SurpriseConstants.rockWarn, 0.8);
      expect(SurpriseConstants.rockDrop, 0.4);
      expect(SurpriseConstants.throwWindup, 0.6);
      expect(SurpriseConstants.throwFlight, 1.4);
      expect(SurpriseConstants.goldenDistance, 200);
      expect(SurpriseConstants.goldenCoinsMin, 8);
      expect(SurpriseConstants.goldenCoinsMax, 10);
    });

    test('hearts stay at most five and one hit costs one', () {
      expect(CombatConstants.invincibilityDuration, greaterThan(1));
    });
  });

  group('the ladder', () {
    test(
        'no surprise before its level, none in levels 1 to 3, none in a boss room',
        () {
      for (final kind in SurpriseKind.values) {
        for (var level = 1; level <= 3; level++) {
          expect(SurpriseRules.allowed(kind, levelNo: level), false,
              reason: '$kind in level $level');
        }
        expect(SurpriseRules.allowed(kind, levelNo: 9, isArena: true), false);
      }
      expect(SurpriseRules.firstLevel(SurpriseKind.hopper), 4);
      expect(SurpriseRules.firstLevel(SurpriseKind.groundPop), 5);
      expect(SurpriseRules.firstLevel(SurpriseKind.fallingRock), 6);
      expect(SurpriseRules.firstLevel(SurpriseKind.thrower), 7);
      expect(SurpriseRules.firstLevel(SurpriseKind.golden), 8);
      expect(SurpriseRules.allowed(SurpriseKind.hopper, levelNo: 4), true);
      expect(SurpriseRules.allowed(SurpriseKind.groundPop, levelNo: 4), false);
      expect(
          SurpriseRules.allowed(SurpriseKind.fallingRock, levelNo: 5), false);
      expect(SurpriseRules.allowed(SurpriseKind.thrower, levelNo: 6), false);
      expect(SurpriseRules.allowed(SurpriseKind.golden, levelNo: 7), false);
      expect(SurpriseRules.allowed(SurpriseKind.golden, levelNo: 8), true);
    });

    test(
        'the map behaviour names switch the enemy surprises on, in the right levels',
        () {
      EnemySurprise s(String b, int level, {bool arena = false}) =>
          SurpriseRules.enemySurpriseFor(b, levelNo: level, isArena: arena);
      expect(s('hopper', 4), EnemySurprise.hopper);
      expect(s('hopper', 3), EnemySurprise.none);
      expect(s('thrower', 7), EnemySurprise.thrower);
      expect(s('thrower', 6), EnemySurprise.none);
      expect(s('golden', 8), EnemySurprise.golden);
      expect(s('golden', 7), EnemySurprise.none);
      expect(s('hopper', 9, arena: true), EnemySurprise.none);
      expect(s('walker', 9), EnemySurprise.none);
      expect(s('chaser', 9), EnemySurprise.none);
      expect(SurpriseRules.enemySurpriseFor('hopper'), EnemySurprise.hopper,
          reason: 'a level built without a number allows it');
    });

    test('LevelBuilder.enemyFor gives the enemy its surprise', () {
      LevelEntity make(String kind, String behavior) => LevelEntity(
          type: 'enemy',
          x: 3000,
          y: 660,
          kind: kind,
          behavior: behavior,
          patrol: 60);
      EnemySurprise of(LevelEntity e, int level, {bool arena = false}) =>
          LevelBuilder.enemyFor(e,
                  eraId: 'spanish',
                  groundY: 660,
                  levelNo: level,
                  isArena: arena)
              .surprise;
      expect(of(make('spanish_soldier', 'hopper'), 4), EnemySurprise.hopper);
      expect(of(make('spanish_soldier', 'hopper'), 2), EnemySurprise.none);
      expect(of(make('tank', 'thrower'), 7), EnemySurprise.thrower);
      expect(of(make('spanish_soldier', 'golden'), 8), EnemySurprise.golden);
      expect(of(make('spanish_soldier', 'golden'), 8, arena: true),
          EnemySurprise.none);
      expect(of(make('spanish_soldier', 'walker'), 9), EnemySurprise.none);
    });

    test('LevelBuilder skips a crack or a rock in a level that is too early',
        () {
      final xml = File('assets/tiles/levels/era1_9.tmx').readAsStringSync();
      final level = LevelLoader.parse(xml);
      int count<T extends Component>(int levelNo) {
        final world = Component();
        LevelBuilder.build(
            level: level,
            world: world,
            groundY: 660,
            eraId: 'pre-colonial',
            levelNo: levelNo);
        return world.children.whereType<T>().length;
      }

      final pops = level.entities.where((e) => e.type == 'ground_pop').length;
      final rocks =
          level.entities.where((e) => e.type == 'falling_rock').length;
      expect(pops, greaterThan(0));
      expect(rocks, greaterThan(0));
      expect(count<GroundPopComponent>(9), pops);
      expect(count<FallingRockComponent>(9), rocks);
      expect(count<GroundPopComponent>(4), 0, reason: 'pops start in level 5');
      expect(count<FallingRockComponent>(5), 0,
          reason: 'rocks start in level 6');
    });
  });

  group('at most two at once', () {
    test('the registry refuses a third and lets it in when one is over', () {
      final r = SurpriseRegistry();
      final a = Object(), b = Object(), c = Object();
      expect(r.tryStart(a), true);
      expect(r.tryStart(b), true);
      expect(r.tryStart(c), false);
      expect(r.activeCount, 2);
      expect(r.tryStart(a), true,
          reason: 'one already counted is not counted twice');
      r.finish(a);
      expect(r.tryStart(c), true);
      expect(r.activeCount, 2);
      r.finish(Object()); // never counted: harmless
      expect(r.activeCount, 2);
      expect(SurpriseConstants.maxAtOnce, 2);
    });

    test('three hoppers beside a student: only two squat at once', () async {
      final game = await _bareGame();
      final hoppers = [
        await _mount(game, 'spanish_soldier', EnemySurprise.hopper, x: 1500),
        await _mount(game, 'spanish_soldier', EnemySurprise.hopper, x: 1520),
        await _mount(game, 'spanish_soldier', EnemySurprise.hopper, x: 1540),
      ];
      _place(game, hoppers[0], -250);
      var most = 0;
      for (var i = 0; i < 120; i++) {
        for (final h in hoppers) {
          h.update(_dt);
        }
        final busy = hoppers
            .where((h) =>
                (h.move! as HopperMove).phase == HopperPhase.squat ||
                (h.move! as HopperMove).phase == HopperPhase.hop)
            .length;
        if (busy > most) most = busy;
        expect(game.surprises.activeCount, lessThanOrEqualTo(2));
      }
      expect(most, 2, reason: 'two went, the third waited');
    });

    test('a ground pop, a rock and a hopper together: the third waits',
        () async {
      final game = await _bareGame();
      final pop = GroundPopComponent(
          eraId: 'spanish', spotX: 1500, surfaceY: game.groundY);
      final rock = FallingRockComponent(spotX: 1560, surfaceY: game.groundY);
      game.world.addAll([pop, rock]);
      await game.ready();
      final hopper =
          await _mount(game, 'spanish_soldier', EnemySurprise.hopper, x: 1540);
      _stand(game, 1500, -300, game.groundY);
      for (var i = 0; i < 5; i++) {
        pop.update(_dt);
        rock.update(_dt);
        hopper.update(_dt);
      }
      expect(game.surprises.activeCount, 2);
      expect(pop.phase, GroundPopPhase.warn);
      expect(rock.phase, FallingRockPhase.warn);
      expect((hopper.move! as HopperMove).phase, HopperPhase.walk);
    });
  });

  // ─── 1. Hopper ───────────────────────────────────────────────────────────
  group('hopper', () {
    test(
        'squats 0.55 s, hops 140 units in 0.7 s, lands dizzy for 1.4 s, walks on',
        () async {
      final game = await _bareGame();
      final e = await _mount(game, 'spanish_soldier', EnemySurprise.hopper);
      final move = e.move! as HopperMove;
      _place(game, e, -250);
      final startX = e.position.x;
      final baseY = e.position.y;

      _run(e, 2, until: () => move.phase == HopperPhase.squat);
      expect(move.phase, HopperPhase.squat);
      final squatX = e.position.x;
      expect(e.hurtsOnTouch, true,
          reason: 'standing still it is an ordinary enemy');
      final squat = _run(e, 2, until: () => move.phase == HopperPhase.hop);
      expect(squat, closeTo(SurpriseConstants.hopSquat, 0.04));
      expect(e.position.x, squatX, reason: 'it does not move while it squats');
      expect(e.facing, -1, reason: 'it faces the student it will hop at');

      var peak = 0.0;
      final hop = _run(e, 2, until: () {
        peak = baseY - e.position.y > peak ? baseY - e.position.y : peak;
        return move.phase == HopperPhase.dizzy;
      });
      expect(hop, closeTo(SurpriseConstants.hopDuration, 0.04));
      expect(squatX - e.position.x, closeTo(SurpriseConstants.hopDistance, 6),
          reason: 'about 140 units, toward the student');
      expect(peak, closeTo(SurpriseConstants.hopPeak, 8));
      expect(e.position.y, baseY, reason: 'it came down');
      expect((e.position.x - startX).abs(),
          lessThan(SurpriseConstants.hopDistance + 40));

      expect(e.hurtsOnTouch, false, reason: 'dizzy: the hit window');
      expect(e.shownPicture, 'idle');
      final dizzy = _run(e, 3, until: () => move.phase == HopperPhase.walk);
      expect(dizzy, closeTo(SurpriseConstants.hopDizzy, 0.04));
      expect(e.hurtsOnTouch, true);
      expect(game.surprises.activeCount, 0, reason: 'its slot is free again');
    });

    test('the hop is slower than the student', () async {
      final game = await _bareGame();
      final e = await _mount(game, 'spanish_soldier', EnemySurprise.hopper);
      final move = e.move! as HopperMove;
      _place(game, e, -250);
      _run(e, 2, until: () => move.phase == HopperPhase.hop);
      var worst = 0.0;
      var last = e.position.x;
      while (move.phase == HopperPhase.hop) {
        e.update(_dt);
        final speed = (last - e.position.x).abs() / _dt;
        if (speed > worst) worst = speed;
        last = e.position.x;
      }
      expect(worst, lessThan(PlayerComponent.forwardSpeed));
    });

    test('only squats for a student at a fair distance', () async {
      // A fresh game for each: a walker that noticed the student walks towards them.
      for (final (dx, lift, why) in [
        (-80.0, 0.0, 'too close: it is just a walker now'),
        (-SurpriseConstants.hopTriggerRange - 60, 0.0, 'too far'),
        (-200.0, 200.0, 'far above: not on its level'),
      ]) {
        final game = await _bareGame();
        final e = await _mount(game, 'spanish_soldier', EnemySurprise.hopper);
        final move = e.move! as HopperMove;
        _place(game, e, dx, lift: lift);
        _run(e, 1.0);
        expect(move.phase, HopperPhase.walk, reason: why);
      }
    });

    test('a hop costs one heart at most, and a dizzy hopper none', () async {
      final game = await _bareGame();
      final e = await _mount(game, 'spanish_soldier', EnemySurprise.hopper);
      final move = e.move! as HopperMove;
      _place(game, e, -250);
      _run(e, 2, until: () => move.phase == HopperPhase.hop);
      final hearts = game.hearts;
      // The student walks into the hopping enemy and stays there.
      for (var i = 0; i < 60 && move.phase == HopperPhase.hop; i++) {
        e.update(_dt);
        _place(game, e, 0);
        game.player.onCollision({}, e);
      }
      expect(game.hearts, hearts - 1,
          reason: 'one heart, however long they overlap');
      // Dizzy: standing right in it is free.
      final game2 = await _bareGame();
      final d = await _mount(game2, 'spanish_soldier', EnemySurprise.hopper);
      _place(game2, d, -250);
      _run(d, 2,
          until: () => (d.move! as HopperMove).phase == HopperPhase.dizzy);
      final hearts2 = game2.hearts;
      _place(game2, d, 0);
      game2.player.onCollision({}, d);
      expect(game2.hearts, hearts2);
    });

    test('a hit at any time kills it and leaves nothing stuck', () async {
      for (final stage in [
        HopperPhase.walk,
        HopperPhase.squat,
        HopperPhase.hop,
        HopperPhase.dizzy
      ]) {
        final game = await _bareGame();
        var defeated = 0;
        final e = await _mount(game, 'spanish_soldier', EnemySurprise.hopper,
            onDefeated: () => defeated++);
        _place(game, e, -250);
        if (stage != HopperPhase.walk) {
          _run(e, 3, until: () => (e.move! as HopperMove).phase == stage);
        }
        e.takeHit();
        expect(e.defeated, true, reason: '$stage');
        expect(defeated, 1);
        expect(game.surprises.activeCount, 0,
            reason: '$stage releases its slot');
        // (A defeated enemy is re-anchored on its middle to spin: half its height lower.)
        expect(e.position.y - e.size.y / 2, e.groundTop,
            reason: '$stage: it was on the ground, not mid-hop');
      }
    });

    test('never hops off a ledge', () async {
      final game = await _bareGame();
      game.groundSections.add(GroundSection(
        sectionWidth: 1000,
        sectionPosition: Vector2(0, game.groundY),
      )..size = Vector2(1000, 60));
      final e = await _mount(game, 'spanish_soldier', EnemySurprise.hopper,
          x: 880, patrol: 40);
      final move = e.move! as HopperMove;
      _place(
          game, e, 250); // student on the right, towards the end of the ground
      _run(e, 2, until: () => move.phase == HopperPhase.hop);
      for (var i = 0; i < 90; i++) {
        e.update(_dt);
        final centre = e.position.x + e.size.x / 2;
        final half = e.size.x * footSpanFraction / 2;
        expect(game.isGroundUnder(centre - half, centre + half), true,
            reason: 'frame $i: left the ground at ${e.position.x}');
      }
    });

    test('a hopper that landed beyond its patrol walks back, it is not snapped',
        () async {
      final game = await _bareGame();
      final e = await _mount(game, 'spanish_soldier', EnemySurprise.hopper,
          patrol: 40);
      final move = e.move! as HopperMove;
      _place(game, e, -250);
      _run(e, 4, until: () => move.phase == HopperPhase.walk && move.age > 1.5);
      final landed = e.position.x;
      expect((landed - e.homeX).abs(), greaterThan(40));
      _place(game, e, -1000); // out of sight
      var biggest = 0.0;
      var last = e.position.x;
      for (var i = 0; i < 240; i++) {
        e.update(_dt);
        final step = (e.position.x - last).abs();
        if (step > biggest) biggest = step;
        last = e.position.x;
      }
      expect(biggest, lessThan(2), reason: 'a walking pace, never a jump');
    });

    test('every state draws without errors', () async {
      final game = await _bareGame();
      final e = await _mount(game, 'tribal_warrior', EnemySurprise.hopper);
      final move = e.move! as HopperMove;
      _place(game, e, -250);
      for (final stage in [
        HopperPhase.squat,
        HopperPhase.hop,
        HopperPhase.dizzy
      ]) {
        _run(e, 3, until: () => move.phase == stage);
        _run(e, 0.2);
        _draws(e);
      }
    });
  });

  // ─── 2. Ground pop ───────────────────────────────────────────────────────
  group('ground pop', () {
    Future<(ChronoGame, GroundPopComponent)> setup(
        {String era = 'pre-colonial'}) async {
      final game = await _bareGame();
      final pop =
          GroundPopComponent(eraId: era, spotX: 1500, surfaceY: game.groundY);
      game.world.add(pop);
      await game.ready();
      return (game, pop);
    }

    test('sleeps until the student is at a fair distance, never right on top',
        () async {
      final (game, pop) = await setup();
      _stand(game, 1500, -80, game.groundY); // too close
      _step(pop, 1);
      expect(pop.phase, GroundPopPhase.dormant);
      _stand(game, 1500, -900, game.groundY); // too far
      _step(pop, 1);
      expect(pop.phase, GroundPopPhase.dormant);
      _stand(game, 1500, -300, game.groundY);
      pop.update(_dt);
      expect(pop.phase, GroundPopPhase.warn);
    });

    test(
        'cracks for 0.6 s, then an enemy rises; it can be hit but not hurt while it rises',
        () async {
      final (game, pop) = await setup();
      _stand(game, 1500, -300, game.groundY);
      pop.update(_dt);
      final warn = _step(pop, 2, until: () => pop.phase == GroundPopPhase.rise);
      expect(warn, closeTo(SurpriseConstants.popWarn, 0.04));
      final e = pop.enemy!;
      await game.ready();
      await e.loaded;
      expect(e.surprise, EnemySurprise.popper);
      expect(e.kind, 'dark_spirit',
          reason: 'the first era raises a dark spirit');
      expect(e.move, isA<RiseMove>());
      final hearts = game.hearts;

      // Rising: standing in it costs nothing.
      _place(game, e, 0);
      var risen = 0.0;
      while ((e.move! as RiseMove).rising) {
        expect(e.hurtsOnTouch, false);
        game.player.onCollision({}, e);
        expect(game.hearts, hearts);
        e.update(_dt);
        risen += _dt;
      }
      expect(risen, closeTo(SurpriseConstants.popRise, 0.04));
      // Fully up: touching hurts, once.
      expect(e.hurtsOnTouch, true);
      for (var i = 0; i < 30; i++) {
        _place(game, e, 0);
        game.player.onCollision({}, e);
      }
      expect(game.hearts, hearts - 1);
    });

    test('hittable at once, even while it rises', () async {
      final (game, pop) = await setup();
      _stand(game, 1500, -300, game.groundY);
      pop.update(_dt);
      _step(pop, 2, until: () => pop.phase == GroundPopPhase.rise);
      final e = pop.enemy!;
      await game.ready();
      await e.loaded;
      e.update(_dt);
      expect((e.move! as RiseMove).rising, true);
      e.takeHit();
      expect(e.defeated, true);
    });

    test('raises the era\'s own walker', () {
      expect(SurpriseRules.popKindFor('pre-colonial'), 'dark_spirit');
      expect(SurpriseRules.popKindFor('spanish'), 'spanish_soldier');
      expect(SurpriseRules.popKindFor('nationalism'), 'spanish_soldier');
      expect(SurpriseRules.popKindFor('american'), 'american_soldier');
      expect(SurpriseRules.popKindFor('ww2'), 'japanese_soldier');
      expect(SurpriseRules.popKindFor('modern'), 'misinfo_cloud');
    });

    test('a dark spirit that came up walks, it does not fuse and burst',
        () async {
      final (game, pop) = await setup();
      _stand(game, 1500, -300, game.groundY);
      pop.update(_dt);
      _step(pop, 2, until: () => pop.phase == GroundPopPhase.rise);
      final e = pop.enemy!;
      await game.ready();
      await e.loaded;
      _run(e, 1);
      _place(game, e, -90);
      _run(e, 2);
      expect(e.isFusing, false);
      expect(e.defeated, false);
    });

    test('it happens once, and the crack goes', () async {
      final (game, pop) = await setup();
      _stand(game, 1500, -300, game.groundY);
      pop.update(_dt);
      _step(pop, 3, until: () => pop.phase == GroundPopPhase.fade);
      expect(game.surprises.activeCount, 0,
          reason: 'free once the enemy is up');
      _step(pop, 2);
      await game.ready();
      expect(pop.isMounted || pop.parent == null, true);
      expect(pop.enemy, isNotNull);
    });

    test('every phase draws without errors', () async {
      final (game, pop) = await setup();
      _draws(pop);
      _stand(game, 1500, -300, game.groundY);
      pop.update(_dt);
      for (final stage in [
        GroundPopPhase.warn,
        GroundPopPhase.rise,
        GroundPopPhase.fade
      ]) {
        _step(pop, 3, until: () => pop.phase == stage);
        _step(pop, 0.1);
        _draws(pop);
      }
      final e = pop.enemy!;
      await game.ready();
      await e.loaded;
      _draws(e);
      _run(e, 0.2);
      _draws(e);
    });
  });

  // ─── 3. Falling rock ─────────────────────────────────────────────────────
  group('falling rock', () {
    Future<(ChronoGame, FallingRockComponent)> setup() async {
      final game = await _bareGame();
      final rock = FallingRockComponent(spotX: 1500, surfaceY: game.groundY);
      game.world.add(rock);
      await game.ready();
      return (game, rock);
    }

    test('a shadow for 0.8 s, a drop of 0.4 s, then it breaks', () async {
      final (game, rock) = await setup();
      _stand(game, 1500, -300, game.groundY);
      rock.update(_dt);
      expect(rock.phase, FallingRockPhase.warn);
      final warn =
          _step(rock, 3, until: () => rock.phase == FallingRockPhase.drop);
      expect(warn, closeTo(SurpriseConstants.rockWarn, 0.04));
      final drop =
          _step(rock, 3, until: () => rock.phase == FallingRockPhase.landed);
      expect(drop, closeTo(SurpriseConstants.rockDrop, 0.04));
      expect(game.hearts, 5, reason: 'the student was out of the shadow');
      expect(rock.hurt, false);
    });

    test('hurts a student standing in the shadow when it lands: one heart',
        () async {
      final (game, rock) = await setup();
      _stand(game, 1500, -300, game.groundY);
      rock.update(_dt);
      _step(rock, 3, until: () => rock.phase == FallingRockPhase.drop);
      _stand(game, 1500, 10, game.groundY); // steps into the shadow
      final hearts = game.hearts;
      for (var i = 0; i < 12; i++) {
        rock.update(_dt);
        expect(game.hearts, hearts,
            reason: 'the falling rock itself never hurts, frame $i');
      }
      _step(rock, 1, until: () => rock.phase == FallingRockPhase.landed);
      expect(rock.hurt, true);
      expect(game.hearts, hearts - 1);
      _step(rock, 2); // pieces and dust are harmless
      expect(game.hearts, hearts - 1);
    });

    test('a student who stepped out in time, or jumped, loses nothing',
        () async {
      for (final dx in [SurpriseConstants.rockRadius + 8, -90.0, 140.0]) {
        final (game, rock) = await setup();
        _stand(game, 1500, -300, game.groundY);
        rock.update(_dt);
        _step(rock, 3, until: () => rock.phase == FallingRockPhase.drop);
        _stand(game, 1500, dx, game.groundY);
        _step(rock, 3, until: () => rock.phase == FallingRockPhase.landed);
        expect(game.hearts, 5, reason: 'at $dx from the middle');
      }
      final (game, rock) = await setup();
      _stand(game, 1500, -300, game.groundY);
      rock.update(_dt);
      _step(rock, 3, until: () => rock.phase == FallingRockPhase.drop);
      _stand(game, 1500, 0, game.groundY,
          lift: SurpriseConstants.rockClearHeight);
      _step(rock, 3, until: () => rock.phase == FallingRockPhase.landed);
      expect(game.hearts, 5, reason: 'feet 60 up: a jump clears it');
    });

    test('hurts only inside the shadow, at the moment it lands', () {
      bool inside(double dx, {double lift = 0}) => SurpriseRules.insideZone(
          centreX: 1500 + dx,
          feetY: 660 - lift,
          spotX: 1500,
          groundY: 660,
          radius: SurpriseConstants.rockRadius,
          clearHeight: SurpriseConstants.rockClearHeight);
      expect(inside(0), true);
      expect(inside(SurpriseConstants.rockRadius), true);
      expect(inside(SurpriseConstants.rockRadius + 1), false);
      expect(inside(-SurpriseConstants.rockRadius - 1), false);
      expect(inside(0, lift: 59), true);
      expect(inside(0, lift: 60), false);
    });

    test('standing in the shadow and leaving before it lands: no hit',
        () async {
      final (game, rock) = await setup();
      _stand(game, 1500, -300, game.groundY);
      rock.update(_dt);
      _stand(game, 1500, 0, game.groundY);
      _step(rock, 0.5);
      _stand(game, 1500, 200, game.groundY);
      _step(rock, 3, until: () => rock.phase == FallingRockPhase.landed);
      expect(game.hearts, 5);
    });

    test('shakes the screen a moment when it lands, then lets go', () async {
      final (game, rock) = await setup();
      _stand(game, 1500, -300, game.groundY);
      rock.update(_dt);
      _step(rock, 3, until: () => rock.phase == FallingRockPhase.landed);
      var moved = false;
      for (var i = 0; i < 30; i++) {
        rock.update(_dt);
        if (game.cameraShake.length > 0.1) moved = true;
      }
      expect(moved, true);
      _step(rock, 1);
      expect(game.cameraShake.x, 0);
      expect(game.cameraShake.y, 0);
    });

    test('every phase draws without errors', () async {
      final (game, rock) = await setup();
      _draws(rock);
      _stand(game, 1500, -300, game.groundY);
      rock.update(_dt);
      for (final stage in [
        FallingRockPhase.warn,
        FallingRockPhase.drop,
        FallingRockPhase.landed
      ]) {
        _step(rock, 3, until: () => rock.phase == stage);
        _step(rock, 0.2);
        _draws(rock);
      }
    });

    test('the rock is a small pixel picture drawn in code', () {
      expect(SurpriseArt.rockCols, 14);
      expect(SurpriseArt.rockRows, 13);
      expect(SurpriseArt.rockCellCount, greaterThan(100));
    });
  });

  // ─── 4. Thrower ──────────────────────────────────────────────────────────
  group('thrower', () {
    Future<(ChronoGame, EnemyComponent)> setup(
        {String type = 'tax_collector'}) async {
      final game = await _bareGame();
      final e = await _mount(game, type, EnemySurprise.thrower);
      return (game, e);
    }

    Future<ThrownItemComponent> startThrow(
        ChronoGame game, EnemyComponent e) async {
      final move = e.move! as ThrowerMove;
      _run(e, 2, until: () => move.phase == ThrowerPhase.windup);
      expect(move.phase, ThrowerPhase.windup);
      await game.ready();
      return move.item!;
    }

    /// Runs the thrower and its item together.
    void both(EnemyComponent e, ThrownItemComponent item, double seconds,
        {bool Function()? until}) {
      var t = 0.0;
      while (t < seconds - 1e-9) {
        if (until != null && until()) break;
        e.update(_dt);
        item.update(_dt);
        t += _dt;
      }
    }

    test(
        'stands still, flashes 0.6 s, the ring shows, the item lands 1.4 s later',
        () async {
      final (game, e) = await setup();
      _place(game, e, -300);
      final x = e.position.x;
      final item = await startThrow(game, e);
      expect(item.age, closeTo(0, 0.05),
          reason: 'the ring shows from the start of the flash');
      expect(item.inFlight, false);
      expect(e.hurtsOnTouch, true);
      both(e, item, SurpriseConstants.throwWindup + 0.05);
      expect(item.inFlight, true,
          reason: 'the item leaves after the 0.6 s flash');
      both(e, item, 5, until: () => item.landed);
      expect(
          item.age,
          closeTo(SurpriseConstants.throwWindup + SurpriseConstants.throwFlight,
              0.05));
      expect(e.position.x, x, reason: 'a thrower never moves or lunges');
      expect(e.isLunging, false);
    });

    test(
        'only the ring hurts: the student standing in it is hit when it lands, not before',
        () async {
      final (game, e) = await setup();
      _place(game, e, -300);
      final item = await startThrow(game, e);
      final hearts = game.hearts;
      both(e, item, 5, until: () => item.age > 1.9);
      expect(game.hearts, hearts, reason: 'the item in the air never hurts');
      both(e, item, 1, until: () => item.landed);
      expect(item.hurt, true);
      expect(game.hearts, hearts - 1, reason: 'one heart');
      both(e, item, 2);
      expect(game.hearts, hearts - 1, reason: 'and no more');
    });

    test('a student who steps out of the ring, or jumps, loses nothing',
        () async {
      final (game, e) = await setup();
      _place(game, e, -300);
      final item = await startThrow(game, e);
      both(e, item, 1);
      _place(game, e, -300 - SurpriseConstants.ringRadius - 12);
      both(e, item, 5, until: () => item.landed);
      expect(game.hearts, 5);
      expect(item.hurt, false);

      final (game2, e2) = await setup();
      _place(game2, e2, -300);
      final item2 = await startThrow(game2, e2);
      both(e2, item2, 1);
      _place(game2, e2, -300, lift: SurpriseConstants.ringClearHeight);
      both(e2, item2, 5, until: () => item2.landed);
      expect(game2.hearts, 5);
    });

    test('throws a coin, a shell or a bundle of money, by who throws', () {
      expect(thrownKindFor('tax_collector'), ThrownKind.coin);
      expect(thrownKindFor('tank'), ThrownKind.shell);
      expect(thrownKindFor('corruption_figure'), ThrownKind.bundle);
    });

    test(
        'a hit during the flash calls the throw off; one in the air still lands',
        () async {
      final (game, e) = await setup();
      _place(game, e, -300);
      var item = await startThrow(game, e);
      both(e, item, 0.3);
      e.takeHit();
      expect(e.defeated, true, reason: 'a thrower takes one hit');
      expect(item.finished, true);
      expect(item.hurt, false);
      expect(game.surprises.activeCount, 0);

      final (game2, e2) = await setup(type: 'tank');
      _place(game2, e2, -300);
      item = await startThrow(game2, e2);
      both(e2, item, SurpriseConstants.throwWindup + 0.2);
      e2.takeHit();
      expect(item.finished, false, reason: 'already thrown');
      item.update(3);
      expect(item.landed, true);
    });

    test('only throws at a student in range who stands on the ground',
        () async {
      final (game, e) = await setup();
      final move = e.move! as ThrowerMove;
      _place(game, e, -80); // too close
      _run(e, 1.5);
      expect(move.phase, ThrowerPhase.idle);
      _place(game, e, -SurpriseConstants.throwRange - 60); // too far
      _run(e, 1.5);
      expect(move.phase, ThrowerPhase.idle);
      _place(game, e, -300);
      game.player.isOnGround = false; // in the air
      _run(e, 1.5);
      expect(move.phase, ThrowerPhase.idle);
    });

    test('throws again after a rest, one item at a time', () async {
      final (game, e) = await setup();
      final move = e.move! as ThrowerMove;
      _place(game, e, -300);
      final first = await startThrow(game, e);
      both(e, first, 6, until: () => move.phase == ThrowerPhase.idle);
      expect(first.landed, true);
      _stand(game, e.position.x + e.size.x / 2, -400,
          game.groundY); // out of the ring
      await game.ready();
      both(e, first, 6, until: () => move.phase == ThrowerPhase.windup);
      expect(move.phase, ThrowerPhase.windup);
      expect(move.item, isNot(same(first)));
    });

    test('draws every picture without errors', () async {
      for (final type in ['tax_collector', 'tank', 'corruption_figure']) {
        final (game, e) = await setup(type: type);
        _place(game, e, -300);
        final item = await startThrow(game, e);
        for (var i = 0; i < 20; i++) {
          both(e, item, 0.15);
          _draws(e);
          _draws(item);
          if (item.landed) break;
        }
      }
    });
  });

  // ─── 5. Golden runner ────────────────────────────────────────────────────
  group('golden runner', () {
    test('never hurts, however it is touched', () async {
      final game = await _bareGame();
      final e = await _mount(game, 'spanish_soldier', EnemySurprise.golden);
      expect(e.hurtsOnTouch, false);
      for (var i = 0; i < 90; i++) {
        _place(game, e, 0);
        game.player.onCollision({}, e);
        e.update(_dt);
      }
      expect(game.hearts, 5);
    });

    test('runs about 200 units away from the student, then stops and rests',
        () async {
      final game = await _bareGame();
      final e = await _mount(game, 'spanish_soldier', EnemySurprise.golden);
      final move = e.move! as GoldenMove;
      _place(game, e, -200);
      final start = e.position.x;
      _run(e, 1, until: () => move.phase == GoldenPhase.alert);
      expect(move.phase, GoldenPhase.alert, reason: 'a "!" first');
      final alert = _run(e, 1, until: () => move.phase == GoldenPhase.run);
      expect(alert, closeTo(SurpriseConstants.goldenAlert, 0.04));
      var worst = 0.0;
      var last = e.position.x;
      final run = _run(e, 3, until: () {
        final speed = (e.position.x - last).abs() / _dt;
        if (speed > worst) worst = speed;
        last = e.position.x;
        return move.phase == GoldenPhase.rest;
      });
      expect(run, closeTo(SurpriseConstants.goldenRunTime, 0.06));
      expect(e.position.x - start, closeTo(SurpriseConstants.goldenDistance, 8),
          reason: 'about 200 units, away from the student');
      expect(worst, lessThan(PlayerComponent.forwardSpeed));
      expect(e.shownPicture, 'idle', reason: 'catching its breath');
      final x = e.position.x;
      final rest = _run(e, 6, until: () => move.phase == GoldenPhase.watch);
      expect(rest, closeTo(SurpriseConstants.goldenRest, 0.06));
      expect(e.position.x, x, reason: 'it stood still');
    });

    test('never runs off a ledge', () async {
      final game = await _bareGame();
      game.groundSections.add(GroundSection(
        sectionWidth: 1000,
        sectionPosition: Vector2(0, game.groundY),
      )..size = Vector2(1000, 60));
      final e =
          await _mount(game, 'spanish_soldier', EnemySurprise.golden, x: 800);
      final move = e.move! as GoldenMove;
      _place(game, e, -200);
      for (var i = 0; i < 120; i++) {
        e.update(_dt);
        final centre = e.position.x + e.size.x / 2;
        final half = e.size.x * footSpanFraction / 2;
        expect(game.isGroundUnder(centre - half, centre + half), true,
            reason: 'frame $i at ${e.position.x}');
      }
      expect(move.phase, isNot(GoldenPhase.run));
    });

    test('a hit kills it at any time', () async {
      for (final stage in [
        GoldenPhase.watch,
        GoldenPhase.alert,
        GoldenPhase.run,
        GoldenPhase.rest
      ]) {
        final game = await _bareGame();
        final e = await _mount(game, 'spanish_soldier', EnemySurprise.golden);
        _place(game, e, -200);
        if (stage != GoldenPhase.watch) {
          _run(e, 3, until: () => (e.move! as GoldenMove).phase == stage);
        }
        e.takeHit();
        expect(e.defeated, true, reason: '$stage');
      }
    });

    test('says "Golden!" once and draws every state', () async {
      final game = await _bareGame();
      final e = await _mount(game, 'tribal_warrior', EnemySurprise.golden);
      final move = e.move! as GoldenMove;
      _place(game, e, -600);
      _run(e, 0.2);
      await game.ready();
      _place(game, e, -200);
      for (final stage in [
        GoldenPhase.alert,
        GoldenPhase.run,
        GoldenPhase.rest
      ]) {
        _run(e, 3, until: () => move.phase == stage);
        _run(e, 0.1);
        _draws(e);
      }
    });

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

    testWidgets('drops 8 to 10 bonus coins when hit', (tester) async {
      var defeated = 0;
      final e = EnemyComponent(
        eraId: 'pre-colonial',
        enemyTypeOverride: 'tribal_warrior',
        worldX: 1500,
        surprise: EnemySurprise.golden,
        behaviorOverride: EnemyBehavior.walker,
        onDefeated: () => defeated++,
      );
      final game = await mountWidget(tester, e);
      final before = game.world.children.whereType<CoinComponent>().length;
      e.takeHit();
      game.updateTree(0.001);
      for (var i = 0; i < 80; i++) {
        game.updateTree(0.02);
      }
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 16));
      }
      final coins =
          game.world.children.whereType<CoinComponent>().length - before;
      expect(
          coins,
          inInclusiveRange(SurpriseConstants.goldenCoinsMin,
              SurpriseConstants.goldenCoinsMax));
      expect(defeated, 1);
    });
  });

  // ─── The maps ────────────────────────────────────────────────────────────
  group('the maps carry the surprises fairly', () {
    final fileName = RegExp(r'era(\d+)_(\d+)\.tmx$');
    final files = Directory('assets/tiles/levels')
        .listSync()
        .whereType<File>()
        .where((f) => fileName.hasMatch(f.path))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    bool hazard(GroundBlock b, LoadedLevel level, bool left) {
      final n = level.blockAt(left ? b.startX - 1 : b.endX + 1);
      return n == null || (n.topY - b.topY).abs() >= 48 - 0.5;
    }

    for (final f in files) {
      final m = fileName.firstMatch(f.path)!;
      final eraNo = int.parse(m.group(1)!);
      final levelNo = int.parse(m.group(2)!);
      test('era${eraNo}_$levelNo.tmx', () {
        final xml = f.readAsStringSync();
        final level = LevelLoader.parse(xml);
        final enemies = level.entities.where((e) => e.type == 'enemy').toList();
        final spots = level.entities
            .where((e) => e.type == 'ground_pop' || e.type == 'falling_rock')
            .toList();
        final marked = enemies
            .where((e) =>
                const ['hopper', 'thrower', 'golden'].contains(e.behavior))
            .toList();

        // The ladder, and the boss rooms and the first three levels have none.
        if (level.isArena || levelNo <= 3) {
          expect(spots, isEmpty);
          expect(marked, isEmpty);
          return;
        }
        for (final e in marked) {
          final first = {'hopper': 4, 'thrower': 7, 'golden': 8}[e.behavior]!;
          expect(levelNo, greaterThanOrEqualTo(first),
              reason: '${e.behavior} at ${e.x}');
        }
        for (final s in spots) {
          expect(levelNo, greaterThanOrEqualTo(s.type == 'ground_pop' ? 5 : 6),
              reason: '${s.type} at ${s.x}');
        }
        for (final e in marked.where((e) => e.behavior == 'thrower')) {
          expect(enemyTypeTable[e.kind]?.behavior, EnemyBehavior.heavy);
        }
        expect(marked.where((e) => e.behavior == 'golden').length,
            lessThanOrEqualTo(1));
        expect(marked.where((e) => e.behavior == 'thrower').length,
            lessThanOrEqualTo(2));
        expect(spots.where((e) => e.type == 'ground_pop').length,
            lessThanOrEqualTo(3));
        expect(spots.where((e) => e.type == 'falling_rock').length,
            lessThanOrEqualTo(3));
        // Each ladder step is there from its level.
        if (levelNo >= 4) {
          expect(marked.where((e) => e.behavior == 'hopper'), isNotEmpty);
        }
        if (levelNo >= 5) {
          expect(spots.where((e) => e.type == 'ground_pop'), isNotEmpty);
        }
        if (levelNo >= 6) {
          expect(spots.where((e) => e.type == 'falling_rock'), isNotEmpty);
        }

        // Where they stand.
        final gate = level.entities.firstWhere((e) => e.type == 'gate');
        final artifacts =
            level.entities.where((e) => e.type == 'artifact').toList();
        final platforms =
            level.entities.where((e) => e.type == 'platform').toList();
        for (final s in [...spots, ...marked]) {
          expect(s.x - level.spawnX, greaterThanOrEqualTo(400),
              reason: '${s.type} at ${s.x} start');
          expect(gate.x - s.x, greaterThanOrEqualTo(400),
              reason: '${s.type} at ${s.x} gate');
        }
        for (final s in spots) {
          final block = level.blockAt(s.x);
          expect(block, isNotNull, reason: '${s.type} at ${s.x} is over a pit');
          expect(block!.topY, s.y, reason: '${s.type} at ${s.x} y');
          // The whole shadow on one block, and 150 from a pit edge or a wall.
          expect(s.x - 60, greaterThanOrEqualTo(block.startX),
              reason: '${s.type} at ${s.x}');
          expect(s.x + 60, lessThanOrEqualTo(block.endX),
              reason: '${s.type} at ${s.x}');
          if (hazard(block, level, true)) {
            expect(s.x - block.startX, greaterThanOrEqualTo(150),
                reason: '${s.type} at ${s.x} left edge');
          }
          if (hazard(block, level, false)) {
            expect(block.endX - s.x, greaterThanOrEqualTo(150),
                reason: '${s.type} at ${s.x} right edge');
          }
          for (final p in platforms) {
            expect(s.x <= p.x - 150 || s.x >= p.x + p.width + 150, true,
                reason: '${s.type} at ${s.x} is by the platform at ${p.x}');
          }
          for (final a in artifacts) {
            expect(s.x <= a.x - 300 || s.x >= a.x + 72 + 300, true,
                reason: '${s.type} at ${s.x} is by the artifact at ${a.x}');
          }
        }
        // Spread out: two crack/rock spots are never closer than a screenful.
        final xs = spots.map((s) => s.x).toList()..sort();
        for (var i = 1; i < xs.length; i++) {
          expect(xs[i] - xs[i - 1], greaterThanOrEqualTo(700));
        }
        // The map must still be one the game builds.
        final world = Component();
        LevelBuilder.build(
            level: level,
            world: world,
            groundY: 660,
            eraId: allErasIdFor(eraNo),
            levelNo: levelNo);
        expect(
            world.children.whereType<EnemyComponent>().length, enemies.length);
      });
    }
  });
}

String allErasIdFor(int eraNo) => const [
      'pre-colonial',
      'spanish',
      'nationalism',
      'american',
      'ww2',
      'modern'
    ][eraNo - 1];

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
