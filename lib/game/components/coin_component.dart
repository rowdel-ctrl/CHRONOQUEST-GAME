import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../chrono_game.dart';

/// Collectible coin rendered using the collectible image. Spawns at a
/// fixed world position ahead of the camera and stays there horizontally
/// (the camera moving past it creates the on-screen leftward motion) while
/// bobbing vertically in place.
class CoinComponent extends SpriteComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  bool collected = false;

  double _bobTime = 0;
  late final double _baseY;

  CoinComponent({Vector2? spawnPosition}) {
    if (spawnPosition != null) {
      position = spawnPosition;
    }
  }

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('collectibles/coin.png');
    // 1.5x the native 28x28, matching the enemy/platform upscale so the
    // world reads at one consistent scale next to the 96x120 player. The
    // CircleHitbox below takes its radius from this size.
    size = Vector2(42, 42);
    if (position.isZero()) {
      // Height measured from the coin's own bottom edge, not its top: with
      // a fixed 32 the taller coin would have hung through the ground.
      position = Vector2(
        game.cameraRightEdgeX + 20,
        game.groundY - size.y - (Random().nextDouble() * 80),
      );
    }
    _baseY = position.y;
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (collected) return;

    _bobTime += dt * 3;
    position.y = _baseY + (sin(_bobTime) * 4);

    // Never culled behind the camera — see level_culling.dart. A coin the
    // player jumped over and came back for must still be there.
  }

  void collect() {
    collected = true;
    removeFromParent();
  }
}
