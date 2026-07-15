import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../chrono_game.dart';

/// Flat ground component — single rectangle at the bottom of the screen.
/// Used as the base ground. Gaps are handled by GroundSection segments.
class GroundComponent extends PositionComponent with HasGameReference<ChronoGame> {
  @override
  Future<void> onLoad() async {
    size = Vector2(game.size.x, 60);
    position = Vector2(0, game.size.y - 60);
    // No hitbox here — ground sections handle collision
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = _groundColorForEra(game.currentEra);
    canvas.drawRect(size.toRect(), paint);
  }

  Color _groundColorForEra(String era) {
    const colors = {
      'pre-colonial': Color(0xFF5D4E37),
      'spanish': Color(0xFF808080),
      'american': Color(0xFF8B6914),
      'ww2': Color(0xFF4A4A3A),
      'modern': Color(0xFF555555),
    };
    return colors[era] ?? const Color(0xFF5D4E37);
  }

  void updateSize() {
    size = Vector2(game.size.x, 60);
  }
}
