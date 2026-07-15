import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../chrono_game.dart';

/// A section of ground that scrolls left. Gaps are created by NOT placing
/// a GroundSection in a stretch — when the player falls through, they
/// lose a heart and respawn.
class GroundSection extends PositionComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  final double sectionWidth;
  final Color color;

  // Cached for zero-allocation update loop (Flame performance skill)
  final Vector2 _velocity = Vector2.zero();

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
  void update(double dt) {
    super.update(dt);
    _velocity.setValues(-ChronoGame.worldScrollSpeed, 0);
    position.addScaled(_velocity, dt);
    if (position.x < -sectionWidth) {
      removeFromParent();
    }
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
  double _timeSinceLastSpawn = 0;
  double _spawnInterval = 2.0; // seconds between new sections
  final Random _random = Random();

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
    // Fill screen with ground initially
    final section = GroundSection(
      sectionWidth: game.size.x + 200,
      color: _groundColor,
      sectionPosition: Vector2(-100, ChronoGame.groundY),
    );
    game.add(section);
  }

  void update(double dt) {
    _timeSinceLastSpawn += dt;
    if (_timeSinceLastSpawn >= _spawnInterval) {
      _timeSinceLastSpawn = 0;
      _spawnSection();
      // Randomize next interval (gap or no gap)
      _spawnInterval = 1.5 + _random.nextDouble() * 2.0;
    }
  }

  void _spawnSection() {
    // 25% chance of a gap
    final hasGap = _random.nextDouble() < 0.25;

    if (hasGap) {
      // Gap width between 80-120px
      final gapWidth = 80.0 + _random.nextDouble() * 40.0;

      // Section after the gap
      final sectionWidth = 200.0 + _random.nextDouble() * 300.0;
      final section = GroundSection(
        sectionWidth: sectionWidth,
        color: _groundColor,
        sectionPosition: Vector2(
          game.size.x + gapWidth,
          ChronoGame.groundY,
        ),
      );
      game.add(section);
    } else {
      final sectionWidth = 300.0 + _random.nextDouble() * 400.0;
      final section = GroundSection(
        sectionWidth: sectionWidth,
        color: _groundColor,
        sectionPosition: Vector2(game.size.x, ChronoGame.groundY),
      );
      game.add(section);
    }
  }
}
