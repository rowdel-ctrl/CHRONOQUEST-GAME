// Parallax re-anchoring tests (Phase 3 of CAMERA_REBUILD_CHECKLIST.md).
//
// ParallaxBackground used to scroll at a hardcoded `Vector2(20, 0)`
// baseVelocity, disconnected from the camera — it only looked right by
// coincidence because PlayerComponent.forwardSpeed never changes. It now
// derives `Parallax.baseVelocity` every frame from how far the camera
// actually moved (`game.cameraLeftEdgeX` delta / dt), scaled down by the
// same 20/150 ratio the original hardcoded velocity implied relative to the
// world's scroll speed — without that scale-down, feeding the camera's full
// speed straight into `baseVelocity` made the (2.2x/4.84x multiplied) layers
// scroll faster than the world itself (caught during manual playtesting:
// the background visibly outran the foreground). This still can't drift out
// of sync even if forward speed ever varies (e.g. a future speed power-up).
//
// These tests inject a `Parallax` with an empty layer list (no real image
// data), isolating the camera-velocity math this component is responsible
// for from real image decoding — covered instead by manual playtesting, per
// the flame_test constraint noted in scroll_sync_golden_test.dart.
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/parallax_background.dart';
import 'package:chronoquest/game/components/player_component.dart';

ChronoGame _bareGameWithPlayer({double playerWorldX = 0}) {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  final player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(64, 80)
    ..position = Vector2(playerWorldX, game.groundY - 80);
  game.player = player;
  return game;
}

/// A ParallaxBackground wired to a bare game, with an empty-layer Parallax
/// injected directly (bypassing onLoad's real image decoding — see the
/// `HasGameReference.game` test setter used throughout this checklist's
/// tests).
({ChronoGame game, ParallaxBackground background, Parallax parallax})
    _bareBackground({double playerWorldX = 0}) {
  final game = _bareGameWithPlayer(playerWorldX: playerWorldX);
  final background = ParallaxBackground()
    ..game = game
    ..size = Vector2(800, 450);
  final parallax = Parallax([], size: Vector2(800, 450));
  background.parallax = parallax;
  return (game: game, background: background, parallax: parallax);
}

// Same 20/150 ratio ParallaxBackground applies internally — see its
// `_referenceBaseVelocity` doc comment. Re-derived here (rather than
// imported, since it's private) so this test fails if that ratio drifts
// from what the background actually renders.
const _kBackgroundToWorldRatio = 20.0 / PlayerComponent.forwardSpeed;

void main() {
  group('ParallaxBackground — camera re-anchoring', () {
    test(
        'baseVelocity is a fraction of how fast the camera actually moved '
        'this frame — never faster than the world itself', () {
      final t = _bareBackground();
      const dt = 1 / 60;

      // Seed the baseline on an unadvanced frame, exactly like the
      // component's own first frame after mounting.
      t.background.update(0);

      t.game.player.position.x += PlayerComponent.forwardSpeed * dt;
      t.background.update(dt);

      expect(
        t.parallax.baseVelocity.x,
        closeTo(PlayerComponent.forwardSpeed * _kBackgroundToWorldRatio, 0.01),
      );
      expect(
        t.parallax.baseVelocity.x,
        lessThan(PlayerComponent.forwardSpeed),
        reason: 'Background must scroll slower than the world, or the '
            'parallax depth illusion inverts.',
      );
    });

    test(
        'baseVelocity tracks a changing camera speed frame-to-frame, '
        'instead of staying locked to a fixed value', () {
      final t = _bareBackground();
      const dt = 1 / 60;

      t.background.update(0);

      t.game.player.position.x += PlayerComponent.forwardSpeed * dt;
      t.background.update(dt);
      final normalSpeedVelocity = t.parallax.baseVelocity.x;

      // Simulate a different camera speed frame (e.g. what a future speed
      // power-up would produce) — the old hardcoded-velocity model could
      // never reflect this; the re-anchored version must.
      const boosted = PlayerComponent.forwardSpeed * 2;
      t.game.player.position.x += boosted * dt;
      t.background.update(dt);

      expect(
        normalSpeedVelocity,
        closeTo(PlayerComponent.forwardSpeed * _kBackgroundToWorldRatio, 0.01),
      );
      expect(
        t.parallax.baseVelocity.x,
        closeTo(boosted * _kBackgroundToWorldRatio, 0.01),
      );
    });
  });
}
