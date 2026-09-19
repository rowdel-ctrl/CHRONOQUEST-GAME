import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../chrono_game.dart';

/// A section of ground at a fixed world position. Gaps are created by NOT
/// placing a GroundSection in a stretch — when the player falls through,
/// they lose a heart and respawn. The section itself doesn't move; the
/// camera moving past it as the player advances creates the on-screen
/// leftward motion.
class GroundSection extends PositionComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  final double sectionWidth;
  final Color color;

  @override
  void update(double dt) {
    super.update(dt);
    if (position.x + sectionWidth < game.cameraLeftEdgeX) {
      removeFromParent();
    }
  }

  GroundSection({
    required this.sectionWidth,
    required this.color,
    required Vector2 sectionPosition,
  }) {
    position = sectionPosition;
  }

  @override
  Future<void> onLoad() async {
    size = Vector2(sectionWidth, 60);
    add(RectangleHitbox());
  }

  @override
  void onMount() {
    super.onMount();
    game.groundSections.add(this);
  }

  @override
  void onRemove() {
    game.groundSections.remove(this);
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color;
    canvas.drawRect(size.toRect(), paint);
  }
}

/// Spawns ground sections with gaps between them.
class GroundSpawner {
  final ChronoGame game;

  GroundSpawner({required this.game});

  Color get _groundColor {
    const colors = {
      'pre-colonial': Color(0xFF5D4E37),
      'spanish': Color(0xFF808080),
      'american': Color(0xFF8B6914),
      'ww2': Color(0xFF4A4A3A),
      'modern': Color(0xFF555555),
    };
    return colors[game.currentEra] ?? const Color(0xFF5D4E37);
  }

  void spawnInitialGround() {
    final section = GroundSection(
      sectionWidth: 1000000,
      color: _groundColor,
      sectionPosition: Vector2.zero()..y = game.groundY,
    );
    game.world.add(section);
  }

  void update(double dt) {}
}
