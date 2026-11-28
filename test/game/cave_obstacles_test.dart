// The four obstacles of the underground cave (cave/cave_obstacle_components.dart):
// stalagmite spikes, the stalactite, the crumbling slab and the stone crusher.
// Each one is tried in a small arena (a long floor and a hero), with time driven
// by hand (game.updateTree), so every timing is checked frame by frame.
import 'dart:io';
import 'dart:math' as math;

import 'package:chronoquest/core/cave_constants.dart';
import 'package:chronoquest/core/surprise_constants.dart';
import 'package:chronoquest/game/cave/cave_layout.dart';
import 'package:chronoquest/game/cave/cave_obstacle_components.dart';
import 'package:chronoquest/game/cave/cave_scenery.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_input.dart';
import 'package:chronoquest/services/audio_service.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart' show AudioPool;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// A long floor with a hero on it, and nothing else.
class _Arena extends ChronoGame {
  _Arena() {
    currentEra = 'spanish';
    currentLevel = 4;
  }

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(GroundSection(
      sectionWidth: 9000,
      sectionPosition: Vector2(0, groundY),
      drawn: false,
    ));
    player = PlayerComponent(characterId: 'rizal')
      ..size = Vector2(96, 120)
      ..position = Vector2(100, groundY - 120);
    world.add(player);
    gameInput = GameInput(game: this);
    gameInput.setup();
  }
}

Future<void> _settle(WidgetTester tester, {int frames = 8}) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<_Arena> _mountArena(WidgetTester tester) async {
  final game = _Arena();
  await tester.pumpWidget(MaterialApp(
    home: GameWidget(
      game: game,
      overlayBuilderMap: {
        'QuestionOverlay': (_, __) => const SizedBox.shrink()
      },
    ),
  ));
  await tester.pump();
  await _settle(tester);
  game.hearts = 5;
  game.shieldActive = false;
  return game;
}

/// Adds [c] to the arena and waits until it is part of the game. The hero stays
/// far away meanwhile, so nothing starts.
Future<T> _add<T extends Component>(
    WidgetTester tester, _Arena game, T c) async {
  game.world.add(c);
  await _settle(tester);
  expect(c.isMounted, isTrue);
  return c;
}

/// The hero stands with the middle of the body at [centreX], [lift] above the floor.
void _stand(_Arena g, double centreX, {double lift = 0}) {
  g.player.position = Vector2(centreX - 48, g.groundY - 120 - lift);
  g.player.velocityY = 0;
  g.player.isOnGround = lift == 0;
}

/// Runs [seconds] of game time in 60ths of a second.
void _step(_Arena g, double seconds) {
  var left = seconds;
  while (left > 1e-9) {
    final dt = math.min(1 / 60, left);
    g.updateTree(dt);
    left -= dt;
  }
}

/// Same, but the hero is put back at [centreX] before every frame (a hit shoves
/// the hero away, and the test wants to stay in the way).
void _stepStaying(_Arena g, double seconds, double centreX, {double lift = 0}) {
  var left = seconds;
  while (left > 1e-9) {
    final dt = math.min(1 / 60, left);
    _stand(g, centreX, lift: lift);
    g.updateTree(dt);
    left -= dt;
  }
}

/// A widget test that lets the hero's short reactions finish at the end, so no
/// timer is left pending.
void _test(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    await body(tester);
    await tester.pump(const Duration(seconds: 2));
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageDir =
      Directory.systemTemp.createTempSync('chronoquest_obstacles_test_').path;
  final look = CaveLook.of('spanish');

  setUpAll(() async {
    AudioService().setSoundEnabled(false);
    AudioService().poolFactory =
        (file) => Future<AudioPool>.error(StateError('no sound in a test'));
    Hive.init(storageDir);
    await Hive.openBox('chronoquest');
  });

  // ─── the cycle, as plain numbers ──────────────────────────────────────────
  group('the crusher cycle', () {
    test('up 1.5, shake 0.6, slam 0.3, hold 0.3, rise 0.6: 3.3 in all', () {
      expect(CaveConstants.crusherCycle, closeTo(3.3, 1e-9));
      CrusherPhase at(double t) => CrusherCycle.phaseAt(t);
      expect(at(0), CrusherPhase.up);
      expect(at(1.49), CrusherPhase.up);
      expect(at(1.51), CrusherPhase.warn);
      expect(at(2.09), CrusherPhase.warn);
      expect(at(2.11), CrusherPhase.slam);
      expect(at(2.39), CrusherPhase.slam);
      expect(at(2.41), CrusherPhase.hold);
      expect(at(2.69), CrusherPhase.hold);
      expect(at(2.71), CrusherPhase.rise);
      expect(at(3.29), CrusherPhase.rise);
      expect(at(3.31), CrusherPhase.up, reason: 'the next cycle');
      expect(at(-0.1), CrusherPhase.rise, reason: 'time wraps');
    });

    test('the block rests 175 up, comes down in the slam, and goes back up',
        () {
      expect(CrusherCycle.bottomHeightAt(0), 175);
      expect(CrusherCycle.bottomHeightAt(1.8), 175,
          reason: 'it does not sink while it shakes');
      expect(CrusherCycle.bottomHeightAt(2.1), closeTo(175, 1e-6));
      expect(CrusherCycle.bottomHeightAt(2.25), lessThan(175));
      expect(CrusherCycle.bottomHeightAt(2.25), greaterThan(0));
      expect(CrusherCycle.bottomHeightAt(2.55), 0,
          reason: 'resting on the floor');
      expect(CrusherCycle.bottomHeightAt(3.0),
          allOf(greaterThan(0), lessThan(175)));
      expect(CrusherCycle.bottomHeightAt(3.299), closeTo(175, 1));
      // Going down it only ever goes down, going up only up.
      var last = 175.0;
      for (var t = 2.1; t <= 2.4; t += 0.01) {
        final h = CrusherCycle.bottomHeightAt(t);
        expect(h, lessThanOrEqualTo(last + 1e-9));
        last = h;
      }
      last = 0;
      for (var t = 2.7; t <= 3.3; t += 0.01) {
        final h = CrusherCycle.bottomHeightAt(t);
        expect(h, greaterThanOrEqualTo(last - 1e-9));
        last = h;
      }
    });

    test('only a block going down or resting hurts; the warning is long enough',
        () {
      expect(CrusherCycle.hurts(CrusherPhase.up), isFalse);
      expect(CrusherCycle.hurts(CrusherPhase.warn), isFalse);
      expect(CrusherCycle.hurts(CrusherPhase.slam), isTrue);
      expect(CrusherCycle.hurts(CrusherPhase.hold), isTrue);
      expect(CrusherCycle.hurts(CrusherPhase.rise), isFalse);
      expect(CaveConstants.crusherWarn,
          greaterThanOrEqualTo(SurpriseConstants.minWarning));
      expect(SurpriseConstants.rockWarn,
          greaterThanOrEqualTo(SurpriseConstants.minWarning));
    });

    test(
        'a hero can always walk under it: 100 units take far less than it waits',
        () {
      const walkSeconds = (CaveConstants.crusherWidth + 96) / 250;
      expect(walkSeconds, lessThan(CaveConstants.crusherUp));
      expect(CaveConstants.crusherRestHeight, greaterThan(120),
          reason: 'the hero is 120 tall');
    });
  });

  // ─── 1. spikes ─────────────────────────────────────────────────────────────
  group('stalagmite spikes', () {
    Future<(_Arena, CaveSpikesComponent)> ready(WidgetTester tester,
        {int count = 3}) async {
      final game = await _mountArena(tester);
      final spikes = await _add(tester, game,
          CaveSpikesComponent(spot: CaveSpikeSpot(2000, count), look: look));
      return (game, spikes);
    }

    _test('touching them costs one heart and shoves the hero away',
        (tester) async {
      final (game, spikes) = await ready(tester);
      _stand(game, spikes.spot.centerX - 20);
      _step(game, 1 / 60);
      expect(game.hearts, 4);
      expect(spikes.hits, 1);
      final x0 = game.player.position.x;
      _step(game, 0.2);
      expect(game.player.position.x, lessThan(x0),
          reason:
              'shoved left, away from the spikes it was left of the middle of');
    });

    _test('walking into the edge of a cluster hurts too', (tester) async {
      final (game, spikes) = await ready(tester, count: 1);
      // The hero's body is 58 wide: a centre 40 left of the spike touches it.
      _stand(game, spikes.spot.x - 20);
      _step(game, 1 / 60);
      expect(game.hearts, 4);
    });

    _test('jumped over, they do nothing', (tester) async {
      final (game, spikes) = await ready(tester);
      // The feet at 40 + the grace above the floor clear them; a jump goes to 128.
      for (final lift in [60.0, 100.0, 128.0]) {
        _stand(game, spikes.spot.centerX, lift: lift);
        game.player.velocityY = 0;
        _step(game, 1 / 60);
        expect(game.hearts, 5, reason: 'lift $lift');
      }
    });

    _test('standing near them but not touching does nothing', (tester) async {
      final (game, spikes) = await ready(tester);
      _stand(game, spikes.spot.x - 80);
      _step(game, 0.5);
      _stand(game, spikes.spot.endX + 80);
      _step(game, 0.5);
      expect(game.hearts, 5);
    });

    _test('a Shield takes the hit instead of the heart', (tester) async {
      final (game, spikes) = await ready(tester);
      game.shieldActive = true;
      _stand(game, spikes.spot.centerX);
      _step(game, 1 / 60);
      expect(game.hearts, 5);
      expect(game.shieldActive, isFalse);
      expect(spikes.hits, 1);
    });

    _test('the 1.5 second safe moment stops a second hit', (tester) async {
      final (game, spikes) = await ready(tester);
      _stepStaying(game, 0.8, spikes.spot.centerX);
      expect(game.hearts, 4,
          reason: 'one heart, however long the hero stays in them');
      expect(spikes.hits, 1);
    });

    test('the spikes are what the layout says', () {
      const s = CaveSpikeSpot(1000, 3);
      expect(s.width, 72);
      expect(s.endX, 1072);
      expect(s.centerX, 1036);
      expect(CaveConstants.spikeHeight, 40);
    });
  });

  // ─── 2. stalactite ─────────────────────────────────────────────────────────
  group('the stalactite', () {
    const spot = 3000.0;

    Future<(_Arena, CaveStalactiteComponent)> ready(WidgetTester tester) async {
      final game = await _mountArena(tester);
      final s = await _add(
          tester,
          game,
          CaveStalactiteComponent(
              spotX: spot, surfaceY: game.groundY, look: look));
      return (game, s);
    }

    _test('sleeps while the hero is far, near, or past it', (tester) async {
      final (game, s) = await ready(tester);
      for (final from in [spot - 900, spot - 150, spot + 300]) {
        _stand(game, from);
        _step(game, 0.5);
        expect(s.phase, StalactitePhase.dormant, reason: 'hero at $from');
      }
      expect(game.hearts, 5);
    });

    _test('wakes when the hero is 220 to 520 to its left', (tester) async {
      final (game, s) = await ready(tester);
      _stand(game, spot - 540);
      _step(game, 0.1);
      expect(s.phase, StalactitePhase.dormant);
      _stand(game, spot - 500);
      _step(game, 1 / 60);
      expect(s.phase, StalactitePhase.warn);
    });

    _test('the warning lasts 0.8 s, nothing hurts in it, and the shadow grows',
        (tester) async {
      final (game, s) = await ready(tester);
      _stand(game, spot - 300);
      _step(game, 1 / 60);
      expect(s.phase, StalactitePhase.warn);
      // The hero walks right into the shadow and waits there.
      _stand(game, spot);
      expect(s.shadowProgress, lessThan(.1));
      _step(game, 0.4);
      expect(s.shadowProgress, closeTo(.5, .08));
      expect(s.phase, StalactitePhase.warn);
      _step(game, 0.35); // 0.77 s so far
      expect(s.phase, StalactitePhase.warn);
      expect(game.hearts, 5,
          reason: 'nothing hurts before the warning is over');
      expect(s.shadowProgress, greaterThan(.9));
    });

    _test(
        'it drops from 0.8 s and lands at 1.2 s, hurting a hero in the shadow',
        (tester) async {
      final (game, s) = await ready(tester);
      _stand(game, spot - 300);
      _step(game, 1 / 60);
      _stand(game, spot);
      _step(game, 0.9); // 0.9 s: dropping
      expect(s.phase, StalactitePhase.drop);
      expect(game.hearts, 5, reason: 'dropping, not landed');
      _step(game, 0.2); // 1.1 s: still dropping
      expect(s.phase, StalactitePhase.drop);
      expect(game.hearts, 5);
      _step(game, 0.15); // 1.25 s: landed
      expect(s.phase, StalactitePhase.landed);
      expect(s.hurt, isTrue);
      expect(game.hearts, 4);
    });

    _test('a hero who stepped out of the shadow is not hurt', (tester) async {
      final (game, s) = await ready(tester);
      _stand(game, spot - 300);
      _step(game, 1 / 60);
      _stand(game, spot - 60); // 10 outside the radius of 50
      _step(game, 1.3);
      expect(s.phase, StalactitePhase.landed);
      expect(s.hurt, isFalse);
      expect(game.hearts, 5);
    });

    _test('a jump clears it', (tester) async {
      final (game, s) = await ready(tester);
      _stand(game, spot - 300);
      _step(game, 1 / 60);
      // Held in the air in the shadow, feet 80 up, at the moment it lands.
      _stepStaying(game, 1.3, spot, lift: 80);
      expect(s.phase, StalactitePhase.landed);
      expect(s.hurt, isFalse);
      expect(game.hearts, 5);
    });

    _test('a Shield absorbs it', (tester) async {
      final (game, s) = await ready(tester);
      game.shieldActive = true;
      _stand(game, spot - 300);
      _step(game, 1 / 60);
      _stand(game, spot);
      _step(game, 1.3);
      expect(s.hurt, isTrue);
      expect(game.hearts, 5);
      expect(game.shieldActive, isFalse);
    });

    _test('it happens once: the pieces go and nothing falls again',
        (tester) async {
      final (game, s) = await ready(tester);
      _stand(game, spot - 300);
      _step(game, 1 / 60);
      _stand(game, spot);
      _step(game, 1.25);
      expect(game.hearts, 4);
      // Past the debris time it is gone from the game.
      _stand(game, spot + 600);
      _step(game, SurpriseConstants.rockDebris + 0.3);
      expect(s.isMounted, isFalse);
      // Back in range, nothing happens and no more hearts go.
      _stand(game, spot - 300);
      _step(game, 2);
      expect(game.hearts, 4);
    });

    _test('the 1.5 s safe moment stops a second hit from a second stalactite',
        (tester) async {
      final (game, a) = await ready(tester);
      final b = await _add(
          tester,
          game,
          CaveStalactiteComponent(
              spotX: spot + 40, surfaceY: game.groundY, look: look));
      _stand(game, spot - 300);
      _step(game, 1 / 60);
      _stand(game, spot + 20); // inside both shadows
      _step(game, 1.3);
      expect(a.hurt, isTrue);
      expect(b.phase, StalactitePhase.landed);
      expect(game.hearts, 4, reason: 'both landed on the hero: one heart');
    });

    test('its numbers are the falling rock\'s', () {
      expect(SurpriseConstants.rockWarn, 0.8);
      expect(SurpriseConstants.rockDrop, 0.4);
      expect(SurpriseConstants.rockRadius, 50);
      expect(CaveConstants.stalactiteTriggerNear, 220);
      expect(CaveConstants.stalactiteTriggerFar, 520);
    });
  });

  // ─── 3. crumbling slab ─────────────────────────────────────────────────────
  group('the crumbling slab', () {
    const slabX = 2000.0;

    Future<(_Arena, CrumblingSlabComponent)> ready(WidgetTester tester) async {
      final game = await _mountArena(tester);
      final slab = await _add(
          tester,
          game,
          CrumblingSlabComponent(
            widthInTiles: 10,
            surfaceY: game.groundY - 100,
            spawnPosition: Vector2(slabX, game.groundY - 100),
            look: look,
          ));
      return (game, slab);
    }

    /// The hero lands on the slab (feet on its top), as after a jump.
    void land(_Arena game, CrumblingSlabComponent slab) {
      game.player.position =
          Vector2(slabX + 120 - 48, slab.surfaceY - game.player.size.y);
      game.player.velocityY = 0;
      game.player.isOnGround = true;
    }

    double feet(_Arena g) => g.player.position.y + g.player.size.y;

    _test('it is an ordinary slab until someone lands on it', (tester) async {
      final (game, slab) = await ready(tester);
      expect(slab.isSolid, isTrue);
      // The hero walks under it and stands beside it for a long time.
      _stand(game, slabX + 120);
      _step(game, 2);
      _stand(game, slabX - 200);
      _step(game, 2);
      expect(slab.phase, SlabPhase.solid);
      expect(slab.isSolid, isTrue);
    });

    _test(
        'it holds the hero while it shakes, falls after 0.6 s, and the hero drops',
        (tester) async {
      final (game, slab) = await ready(tester);
      land(game, slab);
      _step(game, 0.1);
      expect(slab.phase, SlabPhase.shaking);
      _step(game, 0.4); // 0.5 s after landing
      expect(slab.phase, SlabPhase.shaking);
      expect(slab.isSolid, isTrue, reason: 'still something to stand on');
      expect(feet(game), closeTo(slab.surfaceY, 1));
      expect(game.player.isOnGround, isTrue);

      _step(game, 0.2); // 0.7 s: it has let go
      expect(slab.phase, SlabPhase.falling);
      expect(slab.isSolid, isFalse,
          reason: 'solid ground goes the moment it falls');

      _step(game, 0.8);
      expect(feet(game), closeTo(game.groundY, 1),
          reason: 'the hero is on the floor');
      expect(game.player.isOnGround, isTrue);
    });

    _test('it fades for 0.45 s, stays away, and comes back 3 s after it fell',
        (tester) async {
      final (game, slab) = await ready(tester);
      land(game, slab);
      _step(game, 1 / 60);
      _step(game, 0.65); // falling began at about 0.6 s after the first frame
      expect(slab.phase, SlabPhase.falling);
      _step(game, 0.5);
      expect(slab.phase, SlabPhase.gone);
      expect(slab.isSolid, isFalse);

      _step(game, 2.8);
      expect(slab.phase, SlabPhase.gone, reason: 'still away');
      expect(slab.isSolid, isFalse);

      _step(game, 0.4);
      expect(slab.phase, SlabPhase.returning);
      expect(slab.isSolid, isTrue, reason: 'it can be stood on as it fades in');

      _step(game, 0.5);
      expect(slab.phase, SlabPhase.solid);
      expect(slab.isSolid, isTrue);
    });

    _test('a hero who comes back to it after it returns can use it',
        (tester) async {
      final (game, slab) = await ready(tester);
      land(game, slab);
      _step(game, 5);
      expect(slab.phase, SlabPhase.solid);
      land(game, slab);
      _step(game, 0.3);
      expect(feet(game), closeTo(slab.surfaceY, 1));
      expect(slab.phase, SlabPhase.shaking, reason: 'and it crumbles again');
    });

    test('its numbers', () {
      expect(CaveConstants.crumbleShake, 0.6);
      expect(CaveConstants.crumbleFall, 0.45);
      expect(CaveConstants.crumbleGone, 3.0);
      expect(CaveConstants.crumbleReturn, 0.4);
    });

    test('the slab is a layout slab marked to crumble, and CaveGame builds it',
        () {
      final c = CaveLayout.forLevel('spanish', 8);
      expect(c.platforms.where((p) => p.crumbling), isNotEmpty);
      const p = CavePlatform(100, 8, 560, crumbling: true);
      expect(p.crumbling, isTrue);
      expect(const CavePlatform(100, 8, 560).crumbling, isFalse);
    });
  });

  // ─── 4. stone crusher ──────────────────────────────────────────────────────
  group('the stone crusher', () {
    const cx = 4000.0;

    Future<(_Arena, CaveCrusherComponent)> ready(WidgetTester tester) async {
      final game = await _mountArena(tester);
      final c = await _add(
          tester,
          game,
          CaveCrusherComponent(
              spot: const CaveCrusherSpot(cx),
              surfaceY: game.groundY,
              look: look));
      c.time = 0;
      return (game, c);
    }

    _test('runs only while the hero is near', (tester) async {
      final (game, c) = await ready(tester);
      _stand(game, cx - 3000);
      _step(game, 2);
      expect(c.time, 0, reason: 'far away: it waits');
      _stand(game, cx - 600);
      _step(game, 1);
      expect(c.time, closeTo(1, .05));
    });

    _test('follows its cycle: up, shake, slam, hold, rise', (tester) async {
      final (game, c) = await ready(tester);
      _stand(game, cx - 600);
      _step(game, 1.0);
      expect(c.phase, CrusherPhase.up);
      expect(c.bottomHeight, 175);
      _step(game, 0.7); // 1.7
      expect(c.phase, CrusherPhase.warn);
      _step(game, 0.5); // 2.2
      expect(c.phase, CrusherPhase.slam);
      expect(c.bottomHeight, lessThan(175));
      _step(game, 0.3); // 2.5
      expect(c.phase, CrusherPhase.hold);
      expect(c.bottomHeight, 0);
      _step(game, 0.4); // 2.9
      expect(c.phase, CrusherPhase.rise);
      _step(game, 0.5); // 3.4 -> next cycle
      expect(c.phase, CrusherPhase.up);
    });

    _test('walking under it while it is up is safe', (tester) async {
      final (game, c) = await ready(tester);
      // 1.4 s of the 1.5 s the block waits.
      _stepStaying(game, 1.4, cx);
      expect(c.phase, CrusherPhase.up);
      expect(game.hearts, 5);
      expect(c.hits, 0);
    });

    _test('standing under it through the warning is safe until it slams',
        (tester) async {
      final (game, c) = await ready(tester);
      c.time = 1.5;
      _stepStaying(game, 0.55, cx);
      expect(c.phase, CrusherPhase.warn);
      expect(game.hearts, 5, reason: 'the warning never hurts');
    });

    _test('the slam hurts a hero under it: one heart', (tester) async {
      final (game, c) = await ready(tester);
      c.time = 2.0;
      _stepStaying(game, 0.45, cx);
      expect(game.hearts, 4);
      expect(c.hits, 1);
    });

    _test('resting on the floor it hurts a hero who walks into it',
        (tester) async {
      final (game, c) = await ready(tester);
      c.time = 2.45; // holding, block on the floor
      _stand(game, cx);
      _step(game, 1 / 60);
      expect(c.phase, CrusherPhase.hold);
      expect(game.hearts, 4);
    });

    _test('rising it is harmless', (tester) async {
      final (game, c) = await ready(tester);
      c.time = 2.72;
      _stepStaying(game, 0.5, cx);
      expect(c.phase, CrusherPhase.rise);
      expect(game.hearts, 5);
    });

    _test('a hero beside it or far from its block is never hurt',
        (tester) async {
      final (game, c) = await ready(tester);
      // 120 to the side: the body (58 wide) and the block (100 wide) never touch.
      _stepStaying(game, CaveConstants.crusherCycle * 2, cx - 120);
      expect(game.hearts, 5);
      _stepStaying(game, CaveConstants.crusherCycle * 2, cx + 120);
      expect(game.hearts, 5);
      expect(c.hits, 0);
    });

    _test('a jump over the block while it rests on the floor clears it',
        (tester) async {
      final (game, c) = await ready(tester);
      c.time = 2.45;
      _stand(game, cx, lift: 90);
      _step(game, 1 / 60);
      expect(game.hearts, 5,
          reason: 'the block is 70 tall: feet at 90 are over it');
    });

    _test('a Shield absorbs the slam', (tester) async {
      final (game, c) = await ready(tester);
      game.shieldActive = true;
      c.time = 2.0;
      _stepStaying(game, 0.45, cx);
      expect(game.hearts, 5);
      expect(game.shieldActive, isFalse);
      expect(c.hits, 1);
    });

    _test('the 1.5 s safe moment stops a second hit in the same slam',
        (tester) async {
      final (game, c) = await ready(tester);
      c.time = 2.0;
      // Through the slam and the hold, with the hero put back under it every frame.
      _stepStaying(game, 0.8, cx);
      expect(game.hearts, 4);
      expect(c.hits, 1);
    });

    test('the block is 100 wide and 70 tall', () {
      const s = CaveCrusherSpot(500);
      expect(s.left, 450);
      expect(s.right, 550);
      expect(CaveConstants.crusherHeight, 70);
    });
  });
}
