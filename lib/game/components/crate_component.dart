import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../chrono_game.dart';

/// Crate obstacle — rendered from the crate.png tile. Spawns at a fixed
/// world position ahead of the camera and stays there; the camera moving
/// past it creates the on-screen leftward motion — same pattern as
/// WallComponent. Colliding with the player (while not already hurt) deals
/// damage and removes the crate, handled in PlayerComponent.onCollisionStart.
class CrateComponent extends SpriteComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('tiles/crate.png');
    // crate.png is a single 16x16 tile — scaled up to match the other
    // ground-level obstacles (WallComponent renders at 40x50).
    size = Vector2(36, 36);
    position = Vector2(game.cameraRightEdgeX + 20, game.groundY - size.y);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (position.x < game.cameraLeftEdgeX - size.x) {
      removeFromParent();
    }
  }
}
