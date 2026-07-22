import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../chrono_game.dart';

/// Visible low wall obstacle — rendered using real asset file.
class WallComponent extends SpriteComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  final Vector2 _velocity = Vector2.zero();

  @override
  Future<void> onLoad() async {
    // Remove the hyphen from the era name to match 'precolonial_wall.png'
    final eraName = game.currentEra.replaceAll('-', '');
    sprite = await game.loadSprite('obstacles/${eraName}_wall.png');
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