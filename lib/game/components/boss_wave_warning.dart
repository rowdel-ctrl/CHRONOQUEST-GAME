import 'dart:math' as math;
import 'dart:ui' show Canvas, Color, Offset, Paint, PaintingStyle, Path, RRect, Radius, Rect, StrokeCap;

import 'package:flame/components.dart';

import '../chrono_game.dart';

/// The red warning of a minion that is about to appear: a pulsing ring on the floor at the spot,
/// or, when the spot is past the edge of the screen, a red "!" badge on that edge with a little
/// arrow toward it. The boss removes it when the minion appears (or when the wave ends). Drawn
/// in code, in world coordinates, so it needs no art.
class BossWaveWarning extends PositionComponent with HasGameReference<ChronoGame> {
  /// Where the minion will stand: the world x of its middle and the y of the floor under it.
  final double spotX;
  final double surfaceY;

  BossWaveWarning({required this.spotX, required this.surfaceY}) {
    priority = 18;
    position = Vector2.zero();
    size = Vector2.zero();
  }

  double _t = 0;

  /// How long it has been showing, in seconds.
  double get seconds => _t;

  /// How far in from the screen edge the badge sits, and how far the spot may be from the edge
  /// and still count as "on the screen" (the ring would be cut off right at the edge).
  static const double edgeInset = 40;

  /// Whether the spot is far enough inside the screen to show the ring on the floor.
  bool get onScreen =>
      spotX > game.cameraLeftEdgeX + edgeInset && spotX < game.cameraRightEdgeX - edgeInset;

  /// Which screen edge shows the badge: -1 left, 1 right, 0 when the ring is on the screen.
  int get edge => onScreen ? 0 : (spotX <= game.cameraLeftEdgeX + edgeInset ? -1 : 1);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final pulse = 0.5 + 0.5 * math.sin(_t * 13);
    final red = Color.fromRGBO(232, 67, 58, 0.55 + 0.45 * pulse);
    const dark = Color(0xFF7A1E18);
    final e = edge;
    if (e == 0) {
      // A ring on the floor, growing and fading a little with each pulse.
      final rx = 34 + 8 * pulse;
      final ry = 11 + 3 * pulse;
      final c = Offset(spotX, surfaceY - 2);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: rx * 2, height: ry * 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = red,
      );
      canvas.drawOval(
        Rect.fromCenter(center: c, width: rx * 1.2, height: ry * 1.2),
        Paint()..color = Color.fromRGBO(232, 67, 58, 0.18 + 0.2 * pulse),
      );
      return;
    }
    // A badge on the edge the minion will come from.
    final cx = e < 0 ? game.cameraLeftEdgeX + edgeInset : game.cameraRightEdgeX - edgeInset;
    final cy = surfaceY - 150;
    final badge = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 46, height: 46), const Radius.circular(12));
    canvas.drawRRect(badge.shift(const Offset(0, 3)), Paint()..color = const Color(0x66000000));
    canvas.drawRRect(badge, Paint()..color = red);
    canvas.drawRRect(
      badge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = dark,
    );
    // The "!": a bar and a dot.
    final white = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy - 5), width: 7, height: 20), const Radius.circular(3)),
        white);
    canvas.drawCircle(Offset(cx, cy + 12), 4, white);
    // An arrow beside the badge, pointing out toward the spot.
    final dir = e.toDouble();
    final tip = cx + dir * (36 + 4 * pulse);
    final arrow = Path()
      ..moveTo(tip, cy)
      ..lineTo(tip - dir * 14, cy - 11)
      ..lineTo(tip - dir * 14, cy + 11)
      ..close();
    canvas.drawPath(arrow, Paint()..color = red);
    canvas.drawPath(
      arrow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = dark,
    );
  }
}
