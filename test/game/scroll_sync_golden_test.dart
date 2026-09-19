// Camera-follow regression tests (see CAMERA_REBUILD_CHECKLIST.md).
//
// This file used to verify EnemyComponent/WallComponent scrolled left in
// lockstep via a shared `ChronoGame.worldScrollSpeed` constant — that
// constant no longer exists. The player now has a real worldX that
// advances every frame, and the camera follows it; everything else is
// static in world space. What matters now is:
//   - the player always renders at the same fixed screen offset, no
//     matter how far worldX has advanced
//   - the camera's viewfinder tracks the player every single frame, not
//     one frame behind
//
// Why not a pixel-diff golden test of the full game?
//   Full-game rendering needs flame_test's FlameTester harness to drive
//   ChronoGame.onLoad() to completion in a test environment (audio, API
//   calls, real parallax/sprite asset loading). flame_test cannot be added
//   to this project without a breaking version conflict with
//   riverpod_generator ^2.3.9 / hive_generator ^2.0.1. Until those are
//   upgraded, full-frame visual regression should be checked by running
//   `flutter run -d web` and watching the camera follow manually — these
//   tests instead cover the underlying math precisely and deterministically
//   using a bare, unloaded ChronoGame (see `_bareGameWithPlayer` below).
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/player_component.dart';

/// `HasGameReference.game` has an explicit setter "useful in tests" (see
/// flame's has_game_reference.dart) — assigning `game.player` directly and
/// calling `game.onGameResize()` gives us real camera/player math without
/// running ChronoGame's real async onLoad() (audio, API, full asset load).
ChronoGame _bareGameWithPlayer({double playerWorldX = 0}) {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  final player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(64, 80)
    ..position = Vector2(playerWorldX, game.groundY - 80);
  game.player = player;
  return game;
}

void main() {
  group('Camera-follow model', () {
    test(
        'player always renders at the fixed screen offset regardless of '
        'worldX', () {
      for (final worldX in [0.0, 500.0, 12345.0, 999999.5]) {
        final game = _bareGameWithPlayer(playerWorldX: worldX);
        final screenX = game.player.worldX - game.cameraLeftEdgeX;
        expect(
          screenX,
          closeTo(GameConstants.playerX, 0.0001),
          reason: 'Player screen position drifted at worldX=$worldX',
        );
      }
    });

    test('camera viewfinder tracks the player every frame, not one frame behind',
        () {
      final game = _bareGameWithPlayer(playerWorldX: 0);
      // Skip spawner/groundSpawner (left uninitialized in this bare setup)
      // so update() only exercises the camera-follow line.
      game.questionShowing = true;
      const dt = 1 / 60;

      for (var frame = 0; frame < 120; frame++) {
        game.player.position.x += PlayerComponent.forwardSpeed * dt;
        game.update(dt);
        expect(
          game.camera.viewfinder.position.x,
          closeTo(game.cameraLeftEdgeX, 0.0001),
          reason: 'Camera lagged behind the player on frame $frame',
        );
      }
    });

    test(
        'cameraRightEdgeX stays exactly one screen-width ahead of '
        'cameraLeftEdgeX, wherever the player is in the world', () {
      final game = _bareGameWithPlayer(playerWorldX: 3000);
      expect(game.cameraRightEdgeX - game.cameraLeftEdgeX, game.size.x);
    });
  });
}
