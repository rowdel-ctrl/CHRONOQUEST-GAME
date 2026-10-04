// Phase 4: "fix off-screen culling so objects behind a backtracking player
// are not destroyed" (GAMEPLAY-V2.md Section 11 / the Phase 4 prompt).
//
// Section 11: "the camera follows the player now and the player can turn
// around, so anything culled behind them can be walked back to. For levels
// this short, cull generously or not at all."
//
// These are regression guards with a specific failure in mind: before Phase
// 4, five components deleted themselves once `position.x` fell behind
// `game.cameraLeftEdgeX`. That was correct when the player was locked to a
// fixed screen x (Phase 0) and could never go back. It became wrong the
// moment Phase 1 unlocked the player's x, and actively destructive in Phase
// 4, where every object is authored content a person placed.
//
// Components are mounted through a real GameWidget rather than the bare-game
// pattern, for the same reason answer_point_test.dart does it: their sprite,
// size and `_baseY` are set in onLoad(), and calling update() before that
// has run throws a LateInitializationError.
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/artifact_component.dart';
import 'package:chronoquest/game/components/coin_component.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/components/tile_platform_component.dart';
import 'package:chronoquest/game/game_input.dart';
import 'package:chronoquest/game/level_culling.dart';

/// A game that mounts a player but lays no level content, so each test can
/// add exactly the one component it is about.
class _CullGame extends ChronoGame {
  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    camera.viewfinder.anchor = Anchor.topLeft;
    player = PlayerComponent(characterId: 'rizal')
      ..size = Vector2(96, 120)
      ..position = Vector2(0, groundY - 120);
    world.add(player);
    // PlayerComponent.update() reads the joystick every frame, so the input
    // layer has to exist even though these tests never touch it.
    gameInput = GameInput(game: this);
    gameInput.setup();
  }
}

Future<_CullGame> _mount(WidgetTester tester, Component component) async {
  final game = _CullGame();
  await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  game.world.add(component);
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
  return game;
}

/// Walks the player far enough right that [objectX] is well behind the
/// camera's left edge, then lets several frames run.
Future<void> _walkCameraPast(
  WidgetTester tester,
  _CullGame game,
  double objectX,
) async {
  game.player.position.x = objectX + 5000 + GameConstants.playerX;
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  group('authored level content survives the camera passing it', () {
    testWidgets('a coin the player jumped over is still there on the way back',
        (tester) async {
      final coin = CoinComponent(spawnPosition: Vector2(300, 400));
      final game = await _mount(tester, coin);

      await _walkCameraPast(tester, game, 300);

      expect(coin.parent, isNotNull);
    });

    testWidgets('an unclaimed artifact is not destroyed behind the player',
        (tester) async {
      // The worst case of the old behaviour: walking past an artifact
      // without claiming it deleted its question, its charges and its Codex
      // entry for the rest of the attempt.
      final artifact = ArtifactComponent(worldX: 400, spriteIndex: 1);
      final game = await _mount(tester, artifact);

      await _walkCameraPast(tester, game, 400);

      expect(artifact.parent, isNotNull);
      expect(artifact.isInteractable, isTrue,
          reason: 'it must still be claimable when the player comes back');
    });

    testWidgets('a ground section is not deleted out from under a player',
        (tester) async {
      // Tiled levels lay one section per solid span rather than a single
      // million-unit slab, so a cull here would delete the floor a
      // backtracking player is about to stand on. The old check could never
      // fire against the slab, which is why this went unnoticed until now.
      final game = await _mount(
        tester,
        GroundSection(
          sectionWidth: 200,
          sectionPosition: Vector2(100, 600),
        ),
      );
      final section = game.world.children.whereType<GroundSection>().first;

      await _walkCameraPast(tester, game, 300);

      expect(section.parent, isNotNull);
      expect(game.groundSections, contains(section),
          reason: 'collision uses this list; losing the entry is what would '
              'drop the player through solid-looking ground');
    });

    testWidgets('a platform stays registered for one-way collision',
        (tester) async {
      final platform = TilePlatformComponent(
        widthInTiles: 4,
        surfaceY: 560,
        spawnPosition: Vector2(500, 560),
      );
      final game = await _mount(tester, platform);

      await _walkCameraPast(tester, game, 500);

      expect(platform.parent, isNotNull);
      expect(game.platforms, contains(platform),
          reason: 'game_collision.dart resolves one-way landings against '
              'this list');
    });
  });

  group('LevelCulling.isFarBehindCamera', () {
    // A pure function of the camera edge, so these use a bare game rather
    // than a mounted one — mounting and then teleporting the player leaves
    // the hurt/fall timers pending and trips the test binding's
    // "a Timer is still pending" invariant.
    ChronoGame bare({required double playerWorldX}) {
      final game = ChronoGame();
      game.onGameResize(Vector2(800, 450));
      game.player = PlayerComponent(characterId: 'rizal')
        ..size = Vector2(64, 80)
        ..position = Vector2(playerWorldX, 0);
      return game;
    }

    test('is false for anything within a realistic level length', () {
      // Even the far end of the longest placeholder level is not "far
      // behind" by this margin.
      expect(bare(playerWorldX: 30000).isFarBehindCamera(0), isFalse);
    });

    test('is true only past the deliberately enormous margin', () {
      final game = bare(playerWorldX: 0);
      expect(
        game.isFarBehindCamera(
          game.cameraLeftEdgeX - LevelCulling.cullMarginX - 1,
        ),
        isTrue,
      );
    });
  });
}
