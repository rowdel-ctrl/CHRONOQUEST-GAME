import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../chrono_game.dart';

/// Visible low wall obstacle — rendered using real asset file.
class WallComponent extends SpriteComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  final Vector2 _velocity = Vector2.zero();

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(
        'obstacles/${_obstacleAssetKeyForEra(game.currentEra)}_wall.png');
    size = Vector2(40, 50);
    position = Vector2(game.size.x + 20, game.groundY - size.y);
    add(RectangleHitbox());
  }

  /// Obstacle PNGs are named without the hyphen used in era ids
  /// (e.g. 'precolonial_wall.png' for the 'pre-colonial' era) — same
  /// mismatch as the background art, fixed the same way here.
  String _obstacleAssetKeyForEra(String era) {
    if (era == 'pre-colonial') return 'precolonial';
    return era;
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