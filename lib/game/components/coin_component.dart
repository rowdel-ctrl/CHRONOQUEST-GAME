import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../chrono_game.dart';

/// Collectible coin rendered using the collectible image.
class CoinComponent extends SpriteComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  bool collected = false;

  final Vector2 _velocity = Vector2.zero();
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
        game.size.x + 20,
        ChronoGame.groundY - 32 - (Random().nextDouble() * 80),
      );
    }
    _baseY = position.y;
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (collected) return;

    _velocity.setValues(-ChronoGame.worldScrollSpeed, 0);
    position.addScaled(_velocity, dt);

    _bobTime += dt * 3;
    position.y = _baseY + (sin(_bobTime) * 4);

    if (position.x < -size.x) {
      removeFromParent();
    }
  }

  void collect() {
    collected = true;
    removeFromParent();
  }
}