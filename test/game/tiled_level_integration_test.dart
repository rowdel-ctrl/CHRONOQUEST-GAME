// End-to-end check that the Phase 4 Tiled path actually runs inside a real
// game, not just that the parser reads the file (level_loader_test.dart).
//
// This is the test that caught the wiring mistakes that unit tests could
// not: enemy `kind` values with no matching sprite on disk (the level built
// fine and then threw at image load), and the player never being moved onto
// the authored `spawn` object.
//
// **Deliberately one assertion-heavy test per path rather than a dozen small
// ones.** `setupSpawning()` is async, and mounting a fresh `GameWidget` for
// every expectation turned out to be flaky in a way that had nothing to do
// with the code under test: the first two mounts loaded the `.tmx` inside
// the pump budget and every later one did not, leaving `tiledLevel` null and
// the assertions quietly reading the procedural fallback instead. Each test
// passed in isolation and failed in sequence. Mounting once and asserting
// the whole built level removes that race rather than papering over it with
// a longer timeout.
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/artifact_component.dart';
import 'package:chronoquest/game/components/coin_component.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/gate_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/components/tile_platform_component.dart';
import 'package:chronoquest/game/game_collision.dart';
import 'package:chronoquest/game/game_input.dart';
import 'package:chronoquest/game/game_spawning.dart';
import 'package:chronoquest/game/level_loader.dart';

class _TiledGame extends ChronoGame {
  _TiledGame(String era, int level) {
    currentEra = era;
    currentLevel = level;
  }

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    camera.viewfinder.anchor = Anchor.topLeft;
    player = PlayerComponent(characterId: 'rizal')
      ..size = Vector2(96, 120)
      ..position = Vector2(0, groundY - 120);
    world.add(player);
    gameInput = GameInput(game: this);
    gameInput.setup();
    await setupSpawning();
  }
}

Future<_TiledGame> _run(
  WidgetTester tester,
  String era,
  int level,
) async {
  final game = _TiledGame(era, level);
  await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
  await tester.pump();
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
  return game;
}

void main() {
  testWidgets('a generated level builds through the real game path',
      (tester) async {
    // Spanish 3 includes a Heavy tax collector, so this also proves that
    // sprite exists and loads. One mount, many assertions: see the note above.
    final game = await _run(tester, 'spanish', 3);

    final level = game.tiledLevel;
    expect(level, isNotNull, reason: 'a generated level must take the Tiled path');
    expect(game.spawner, isNull);

    final children = game.world.children;
    expect(children.whereType<ArtifactComponent>().length, 10);
    expect(children.whereType<GateComponent>().length, 1);
    expect(children.whereType<GateComponent>().single.isLevelExit, isTrue);
    expect(game.artifactsTotal, 10);
    expect(
      children.whereType<EnemyComponent>().length,
      level!.entities.where((e) => e.type == 'enemy').length,
      reason: 'every authored enemy was instantiated',
    );
    expect(
      children.whereType<TilePlatformComponent>().length,
      level.entities.where((e) => e.type == 'platform').length,
    );
    expect(game.groundSections.length, level.groundSpans.length);

    // ── platform fights: enemies stand on their platforms ───────────────
    final fighters = level.entities
        .where((e) => e.type == 'enemy' && level.enemyIsOnPlatform(e))
        .toList();
    expect(fighters, isNotEmpty, reason: 'every generated level has a platform fight');
    final built = children.whereType<EnemyComponent>().toList();
    for (final f in fighters) {
      final enemy = built.firstWhere((c) => (c.position.x - f.x).abs() < 30,
          orElse: () => fail('no enemy built near x=${f.x}'));
      expect(enemy.surfaceY, f.y);
      expect(enemy.position.y + enemy.size.y, closeTo(f.y, 0.5),
          reason: 'the enemy at x=${f.x} should stand on its platform, not the ground');
    }
    expect(built.where((c) => c.surfaceY != null).length, fighters.length,
        reason: 'ground enemies stay on the ground');
    expect(game.levelEndX, level.exitX);
    expect(game.levelEndX, greaterThan(20000),
        reason: 'generated levels run the full ~2 minutes');

    // ── distance to the gate, for the HUD indicator ─────────────────────
    expect(game.gateDistanceUnits(), isNull,
        reason: 'nothing to head for while artifacts remain');
    final answered = game.artifactsAnswered;
    game.artifactsAnswered = game.artifactsTotal;
    final gate = children.whereType<GateComponent>().single;
    final distance = game.gateDistanceUnits()!;
    expect(
      distance,
      closeTo(
        gate.position.x -
            CombatConstants.gateStandoff -
            (game.player.position.x + game.player.size.x),
        0.01,
      ),
    );
    expect(distance, greaterThan(20000), reason: 'the gate is at the far end');
    game.artifactsAnswered = answered;

    // ── respawn after a fall (playtest bug) ──────────────────────────────
    // The anchor used to be the lip of the gap, so a player still holding
    // right walked straight back in and lost every heart in seconds.
    final p = game.player;
    final spans = game.groundSections.toList()
      ..sort((a, b) => a.position.x.compareTo(b.position.x));
    final first = spans.first;
    final end = first.position.x + first.size.x;

    // Hanging 3 units over the ledge is not "standing": no anchor there.
    p.position
      ..x = end - 27
      ..y = game.groundY - p.size.y;
    await tester.pump(const Duration(milliseconds: 16));
    expect(p.respawnAnchorX, lessThanOrEqualTo(end - 72),
        reason: 'the anchor must keep the whole foot span over the ground');

    // The last spot with the whole foot over ground does anchor.
    final lip = end - 72;
    p.position
      ..x = lip
      ..y = game.groundY - p.size.y;
    await tester.pump(const Duration(milliseconds: 16));
    expect(p.respawnAnchorX, closeTo(lip, 1));

    final hearts = game.hearts;
    game.playerFellInGap();
    expect(game.hearts, hearts - 1);
    expect(p.position.x, closeTo(lip - PlayerComponent.respawnRunway, 1));
    final centre = p.position.x + p.size.x / 2;
    expect(game.isGroundUnder(centre - 24, centre + 24), isTrue);
    expect(first.size.x - (p.position.x + p.size.x), greaterThan(150),
        reason: 'there must be room to jump before the gap');

    // A platform hangs over a gap: standing on one must not move the anchor,
    // or the respawn would put the player at ground height over nothing.
    final platform = game.platforms.first;
    p.respawnAnchorX = 500;
    p.position
      ..x = platform.position.x + 24
      ..y = platform.surfaceY - p.size.y;
    p.velocityY = 0;
    p.isOnGround = true;
    await tester.pump(const Duration(milliseconds: 16));
    expect(p.respawnAnchorX, 500);

    // ── a stalled frame does not drop the player through the floor ──────
    // Playtest bug: losing the internet stalled a frame, the whole stall ran
    // as one physics step, and a falling player skipped past the landing
    // band and fell through solid ground.
    // Without the fix the player falls through, loses a heart and is
    // respawned elsewhere, so "on the ground afterwards" alone proves nothing:
    // check they landed where they were, with no heart lost.
    final widest = spans.reduce((a, b) => a.size.x >= b.size.x ? a : b);
    final dropX = widest.position.x + widest.size.x / 2;
    p.position
      ..x = dropX
      ..y = game.groundY - p.size.y - 30;
    p.velocityY = 600;
    p.isOnGround = false;
    final heartsBefore = game.hearts;
    await tester.pump(const Duration(milliseconds: 300));
    expect(p.position.x, dropX, reason: 'not respawned: never fell through');
    expect(game.hearts, heartsBefore);
    expect(p.isOnGround, isTrue);
    expect(p.position.y, closeTo(game.groundY - p.size.y, 0.01));

    // The fall above started the 600 ms hurt-pose timer; let it finish.
    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('pre-colonial 1, the first level, loads and builds through the real game path',
      (tester) async {
    final game = await _run(tester, 'pre-colonial', 1);

    // ── the level took the authored path at all ──────────────────────────
    final level = game.tiledLevel;
    expect(level, isNotNull,
        reason: 'era 1 level 1 has a .tmx and must take the Tiled path');

    // ── the procedural spawners never started ────────────────────────────
    // If they had, the level would be double-populated: authored enemies
    // plus spawned ones, and the authored ground plus the million-unit slab.
    expect(game.spawner, isNull);
    expect(game.groundSpawner, isNull);

    // ── the player starts where the level puts them ──────────────────────
    expect(game.player.position.x, 220);
    expect(game.player.respawnAnchorX, 220,
        reason: 'the fall anchor must be seeded, or a fall before the first '
            'ground contact has nowhere valid to go');

    // ── the level runs its full length, like every other generated level ─
    expect(game.levelEndX, level!.exitX);
    expect(game.levelEndX, greaterThan(20000),
        reason: 'the first level is generated at full length now, not the old '
            '3,140-unit prototype');

    // ── ground is real spans with real gaps ──────────────────────────────
    final sections = game.world.children.whereType<GroundSection>().toList();
    expect(sections.length, level.groundSpans.length);
    expect(sections.length, greaterThan(5));
    for (final s in sections) {
      expect(s.sectionWidth, lessThan(10000),
          reason: 'this should be an authored span, not the old slab');
    }

    // ── every entity the level lists was instantiated ────────────────────
    int listed(String type) => level.entities.where((e) => e.type == type).length;
    final children = game.world.children;
    expect(children.whereType<EnemyComponent>().length, listed('enemy'));
    expect(children.whereType<ArtifactComponent>().length, 10);
    expect(children.whereType<GateComponent>().length, 1);
    expect(children.whereType<GateComponent>().single.isLevelExit, isTrue,
        reason: 'the gate sits at the exit, so it ends the level');
    expect(children.whereType<CoinComponent>().length, listed('coin'));
    expect(children.whereType<TilePlatformComponent>().length, listed('platform'));

    // ── the HUD pill counts what the level actually holds ────────────────
    expect(game.artifactsTotal, 10);

    // ── platforms registered for one-way collision ───────────────────────
    // Section 11's caveat 2 calls this "the single most likely place for
    // platforming to silently break": game_collision.dart resolves one-way
    // landings against `game.platforms`, so a platform that never registers is
    // invisible to it and the player falls through.
    expect(game.platforms.length, listed('platform'));

    // ── enemies stand where the level put them, not off the camera edge ──
    // Compared with a tolerance because walkers start patrolling as soon as
    // they mount: by the time these frames have run they have drifted a few
    // units from their listed x, which is correct behaviour. What matters is
    // that they are at their listed spot rather than at
    // `cameraRightEdgeX + 60`, the spawner's off-screen entry point.
    final enemyXs = children
        .whereType<EnemyComponent>()
        .map((e) => e.position.x)
        .toList()
      ..sort();
    final listedXs = level.entities
        .where((e) => e.type == 'enemy')
        .map((e) => e.x)
        .toList()
      ..sort();
    expect(enemyXs, hasLength(listedXs.length));
    for (var i = 0; i < listedXs.length; i++) {
      expect(enemyXs[i], closeTo(listedXs[i], 30));
    }

    // ── the curriculum block came through (Section 1) ────────────────────
    final c = level.curriculum;
    expect(c, isNotNull);
    expect(c!.grade, 5);
    expect(c.term, 1);
    expect(c.weeks, [1]);
  });

  testWidgets('a level with no .tmx still falls back to the spawner',
      (tester) async {
    // Spanish 2 now has a generated map, so switch the manifest off for this
    // test: the procedural path must keep working for any level without one
    // (the boss levels, until Phase 5), whichever levels happen to be authored.
    final saved = LevelLoader.authored;
    addTearDown(() => LevelLoader.authored = saved);
    LevelLoader.authored = const {};

    final game = await _run(tester, 'spanish', 2);

    expect(game.tiledLevel, isNull);
    expect(game.spawner, isNotNull,
        reason: 'a level without a .tmx must keep working');
    expect(game.groundSpawner, isNotNull);
    expect(game.artifactsTotal, 10);
    expect(game.levelEndX, 25000,
        reason: 'unauthored levels keep the Phase 2 placeholder length');
  });
}
