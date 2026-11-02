import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../chrono_game.dart';

/// The flag about halfway through a level. Passing it gives back one heart (once
/// per try) and makes it the place a fall puts the student back. Grey and limp
/// until reached, then gold and waving.
class HalfwayFlagComponent extends PositionComponent
    with HasGameReference<ChronoGame> {
  static const double poleHeight = 150;
  static const double flagWidth = 70;
  static const double flagHeight = 46;

  /// World x of the pole and the surface it stands on.
  final double poleX;
  final double surfaceY;

  bool reached = false;
  double _t = 0;

  HalfwayFlagComponent({required this.poleX, required this.surfaceY})
      : super(priority: 3) {
    position = Vector2(poleX - 6, surfaceY - poleHeight);
    size = Vector2(flagWidth + 12, poleHeight);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (reached) return;
    final p = game.player;
    if (p.position.x + p.size.x / 2 >= poleX) {
      reached = true;
      game.reachFlag(poleX);
    }
  }

  final Paint _paint = Paint();

  @override
  void render(ui.Canvas canvas) {
    _paint.color = const Color(0xFF3A2A1E);
    canvas.drawRect(const Rect.fromLTWH(4, 0, 6, poleHeight), _paint);
    _paint.color = reached ? const Color(0xFFFFD54F) : const Color(0xFF8A8F98);
    canvas.drawCircle(const Offset(7, 2), 6, _paint);

    // The cloth: a row of strips, each swaying a little more than the one before.
    const strips = 7;
    const stripW = flagWidth / strips;
    _paint.color = reached ? const Color(0xFFE53935) : const Color(0xFF6E7480);
    for (var i = 0; i < strips; i++) {
      final sway = reached ? sin(_t * 5 + i * .7) * 3 * (i / strips) : 0.0;
      final drop = reached ? 0.0 : i * 2.0;
      canvas.drawRect(
          Rect.fromLTWH(10 + i * stripW, 8 + sway + drop, stripW + 1, flagHeight),
          _paint);
    }
    if (reached) {
      _paint.color = const Color(0xFFFFF3C4);
      canvas.drawCircle(
          const Offset(10 + flagWidth * .4, 8 + flagHeight / 2), 7, _paint);
    }
  }
}
