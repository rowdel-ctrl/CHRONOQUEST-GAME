import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../chrono_game.dart';

/// The boss's attack: a low wave that runs along the ground from the boss towards
/// the student. It is jumped, like a gap: a student whose feet are above it is
/// safe. A hit costs a heart (or the Shield), like any other.
///
/// It only exists between questions (the boss sends it with a wave of minions), so
/// a question is never open while it moves.
class BossShockwave extends PositionComponent with HasGameReference<ChronoGame> {
  static const double waveWidth = 64;
  static const double waveHeight = 44;
  static const double speed = 380;

  /// The farthest a wave travels before it is gone.
  static const double maxTravel = 1100;

  /// 1 right, -1 left.
  final int direction;

  /// World x the wave stops at on the far side (the arena wall), when known.
  final double? limitX;

  double _travelled = 0;
  double _t = 0;

  BossShockwave({required this.direction, required Vector2 start, this.limitX})
      : super(priority: 9) {
    position = start;
    size = Vector2(waveWidth, waveHeight);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final step = speed * dt * direction;
    position.x += step;
    _travelled += step.abs();

    final player = game.player;
    if (player.bodyOverlaps(
        position.x, position.y + 8, position.x + size.x, position.y + size.y)) {
      player.takeHazardHit(knockbackDirection: direction);
    }

    final wall = limitX;
    final pastWall = wall != null &&
        (direction > 0 ? position.x > wall : position.x + size.x < wall);
    final offScreen = position.x > game.cameraRightEdgeX + 300 ||
        position.x + size.x < game.cameraLeftEdgeX - 300;
    if (_travelled >= maxTravel || pastWall || offScreen) removeFromParent();
  }

  final Paint _fill = Paint();

  @override
  void render(ui.Canvas canvas) {
    // Three jagged spikes of dust and light, facing the way it runs.
    final w = size.x, h = size.y;
    final lean = direction * 10.0;
    final flicker = (_t * 24).floor().isEven ? 1.0 : 0.85;
    _fill.color = const Color(0xFFFF8A2A).withValues(alpha: .92 * flicker);
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(w * .18 + lean, h * .15)
      ..lineTo(w * .34, h * .65)
      ..lineTo(w * .52 + lean, 0)
      ..lineTo(w * .68, h * .6)
      ..lineTo(w * .86 + lean, h * .25)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, _fill);
    _fill.color = const Color(0xFFFFF0B0).withValues(alpha: .9 * flicker);
    canvas.drawPath(
        Path()
          ..moveTo(w * .3, h)
          ..lineTo(w * .5 + lean, h * .35)
          ..lineTo(w * .7, h)
          ..close(),
        _fill);
  }
}
