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
    size = Vector2(28, 28);
    if (position.isZero()) {
      position = Vector2(
        game.cameraRightEdgeX + 20,
        game.groundY - 32 - (Random().nextDouble() * 80),
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

    if (position.x < game.cameraLeftEdgeX - size.x) {
      removeFromParent();
    }
  }

  void collect() {
    collected = true;
    removeFromParent();
  }
}
