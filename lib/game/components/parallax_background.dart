import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import '../chrono_game.dart';
import 'player_component.dart';

/// Scrolling era background built from two depth layers (`_far`, `_near`).
/// Each layer's scroll offset is driven every frame from how far the
/// camera actually moved (`game.cameraLeftEdgeX`), scaled down to the same
/// background:world speed ratio the original hardcoded velocity used, then
/// further scaled per layer by `velocityMultiplierDelta` — not a fixed
/// guessed velocity. This keeps the background locked to the camera even if
/// the player's forward speed ever changes (e.g. a future speed power-up),
/// instead of drifting out of sync.
class ParallaxBackground extends ParallaxComponent<ChronoGame> {
  double? _lastCameraX;

  /// The pre-Phase-3 code drove this with a hardcoded, independently-ticking
  /// `baseVelocity: Vector2(20, 0)` while the world scrolled at a constant
  /// 150 units/sec (`PlayerComponent.forwardSpeed`) — i.e. the background was
  /// tuned to move at roughly 20/150 of the world's speed, which is what
  /// keeps it looking like it's further away than the foreground. Re-anchored
  /// to real camera movement, that same ratio has to be reapplied explicitly,
  /// or feeding the camera's full speed straight into `baseVelocity` makes
  /// the (2.2x/4.84x multiplied) layers scroll faster than the world itself.
  static const double _referenceBaseVelocity = 20.0;

  ParallaxBackground() : super(priority: -10);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = game.size;
    position = Vector2.zero();

    final bgKey = _backgroundAssetKeyForEra(game.currentEra);
    try {
      parallax = await game.loadParallax(
        [
          ParallaxImageData('backgrounds/${bgKey}_far.png'),
          ParallaxImageData('backgrounds/${bgKey}_near.png'),
        ],
        velocityMultiplierDelta: Vector2(2.2, 1.0),
        fill: LayerFill.height,
        repeat: ImageRepeat.repeatX,
        size: size,
      );
    } catch (e) {
      // Fallback so the game is still playable if a background asset is
      // somehow missing, instead of leaving the whole load future unresolved.
      debugPrint(
          'Failed to load parallax background for ${game.currentEra}: $e');
      add(RectangleComponent(
        size: size,
        paint: Paint()..color = const Color(0xFFD4C4A8),
      ));
    }
  }

  @override
  void update(double dt) {
    // Lazily captured on the first post-load frame — game.cameraLeftEdgeX
    // reads player.worldX, and the player isn't mounted yet during onLoad.
    _lastCameraX ??= game.cameraLeftEdgeX;

    if (parallax != null && dt > 0) {
      final cameraVelocityX = (game.cameraLeftEdgeX - _lastCameraX!) / dt;
      parallax!.baseVelocity.x = cameraVelocityX *
          (_referenceBaseVelocity / PlayerComponent.forwardSpeed);
    }
    _lastCameraX = game.cameraLeftEdgeX;

    super.update(dt);
  }

  /// Background PNGs are named without the hyphen used in era ids
  /// (e.g. 'precolonial_far.png' for the 'pre-colonial' era).
  String _backgroundAssetKeyForEra(String era) {
    if (era == 'pre-colonial') return 'precolonial';
    return era;
  }
}
