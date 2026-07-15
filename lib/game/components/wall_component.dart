import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../chrono_game.dart';

/// Visible low wall obstacle — rendered using real asset file.
class WallComponent extends SpriteComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  final Vector2 _velocity = Vector2.zero();

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('obstacles/${game.currentEra}_wall.png');
    size = Vector2(40, 50);
    position = Vector2(game.size.x + 20, ChronoGame.groundY - size.y);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _velocity.setValues(-ChronoGame.worldScrollSpeed, 0);
    position.addScaled(_velocity, dt);
    if (position.x < -size.x) {
      removeFromParent();
    }
  }
}