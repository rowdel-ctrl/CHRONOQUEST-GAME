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
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/artifact_component.dart';
import 'package:chronoquest/game/components/coin_component.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/gate_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/components/tile_platform_component.dart';
import 'package:chronoquest/game/game_input.dart';
import 'package:chronoquest/game/game_spawning.dart';

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
  testWidgets('era1_1 loads and builds through the real game path',
      (tester) async {
    final game = await _run(tester, 'pre-colonial', 1);

    // ── the level took the authored path at all ──────────────────────────
    expect(game.tiledLevel, isNotNull,
        reason: 'era 1 level 1 has a .tmx and must take the Tiled path');

    // ── the procedural spawners never started ────────────────────────────
    // If they had, the level would be double-populated: authored enemies
    // plus spawned ones, and the authored ground plus the million-unit slab.
    expect(game.spawner, isNull);
    expect(game.groundSpawner, isNull);

    // ── the player starts where the author put them ──────────────────────
    expect(game.player.position.x, 220);
    expect(game.player.respawnAnchorX, 220,
        reason: 'the fall anchor must be seeded, or a fall before the first '
            'ground contact has nowhere valid to go');

    // ── the level ends at the authored exit, not the placeholder ─────────
    expect(game.levelEndX, 3140);

    // ── ground is real spans with real gaps ──────────────────────────────
    final sections = game.world.children.whereType<GroundSection>().toList();
    expect(sections.length, 3);
    for (final s in sections) {
      expect(s.sectionWidth, lessThan(10000),
          reason: 'this should be an authored span, not the old slab');
    }

    // ── every authored entity type was instantiated ──────────────────────
    final children = game.world.children;
    expect(children.whereType<EnemyComponent>().length, 4);
    expect(children.whereType<ArtifactComponent>().length, 10);
    expect(children.whereType<GateComponent>().length, 1);
    expect(children.whereType<GateComponent>().single.isLevelExit, isTrue,
        reason: 'the authored gate sits at the exit, so it ends the level');
    expect(children.whereType<CoinComponent>().length, 8);
    expect(children.whereType<TilePlatformComponent>().length, 2);

    // ── the HUD pill counts what the author actually placed ──────────────
    expect(game.artifactsTotal, 10);

    // ── platforms registered for one-way collision ───────────────────────
    // Section 11's caveat 2 calls this "the single most likely place for
    // platforming to silently break": game_collision.dart resolves one-way
    // landings against `game.platforms`, so a Tiled platform that never
    // registers is invisible to it and the player falls through.
    expect(game.platforms.length, 2);

    // ── enemies stand where authored, not off the camera edge ────────────
    // Compared with a tolerance because walkers start patrolling as soon as
    // they mount: by the time these frames have run they have drifted a few
    // units from their authored x, which is correct behaviour. What matters
    // is that they are at their authored spot rather than at
    // `cameraRightEdgeX + 60`, the spawner's off-screen entry point.
    final enemyXs = children
        .whereType<EnemyComponent>()
        .map((e) => e.position.x)
        .toList()
      ..sort();
    expect(enemyXs, hasLength(4));
    for (final (i, authored) in [600, 1620, 2100, 2860].indexed) {
      expect(enemyXs[i], closeTo(authored, 30));
    }

    // ── the curriculum block came through (Section 1) ────────────────────
    final c = game.tiledLevel!.curriculum;
    expect(c, isNotNull);
    expect(c!.grade, 5);
    expect(c.term, 1);
    expect(c.weeks, [1]);
  });

  testWidgets('a level with no .tmx still falls back to the spawner',
      (tester) async {
    final game = await _run(tester, 'spanish', 2);

    expect(game.tiledLevel, isNull);
    expect(game.spawner, isNotNull,
        reason: 'the 42 unauthored levels must keep working until the '
            'generator has emitted their maps');
    expect(game.groundSpawner, isNotNull);
    expect(game.artifactsTotal, 10);
    expect(game.levelEndX, 25000,
        reason: 'unauthored levels keep the Phase 2 placeholder length');
  });
}
