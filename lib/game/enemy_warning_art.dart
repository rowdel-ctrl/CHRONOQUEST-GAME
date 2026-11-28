import 'dart:math' as math;
import 'dart:ui';

/// Drawn-in-code marks for enemies (no art files): the health bar of an enemy that takes
/// two hits, the strip on the floor that shows where a dash or a lunge will go, and the small
/// red "!" of a chaser that has just noticed the student.
///
/// Every painter draws in the enemy's own coordinates, where [Canvas] has been moved so the
/// middle of its feet is (0, 0) and things above are at negative y, unless its doc says so.
class EnemyWarningArt {
  EnemyWarningArt._();

  /// Width of one segment of a health bar, the gap between two, and its height.
  static const double barSegmentWidth = 28;
  static const double barSegmentGap = 3;
  static const double barHeight = 9;

  /// How long a segment takes to drain after a hit that did not defeat the enemy.
  static const double healthDrainSeconds = 0.3;

  static final Paint _p = Paint();

  static Paint _fill(Color c) => _p
    ..style = PaintingStyle.fill
    ..shader = null
    ..color = c;

  static Paint _stroke(Color c, double w) => _p
    ..style = PaintingStyle.stroke
    ..shader = null
    ..strokeWidth = w
    ..color = c;

  /// The health bar of an enemy that takes more than one hit: [total] segments, the first [left]
  /// full, centred at ([cx], [cy]). The segment the last hit took drains over
  /// [healthDrainSeconds] with a white flash ([sinceHit] is the seconds since that hit); the rest
  /// that are gone are empty.
  static void healthBar(Canvas c, double cx, double cy,
      {required int total, required int left, double sinceHit = 99}) {
    final w = total * barSegmentWidth + (total - 1) * barSegmentGap;
    final x0 = cx - w / 2;
    final top = cy - barHeight / 2;
    // The dark backing and its outline.
    final back = RRect.fromRectAndRadius(
        Rect.fromLTWH(x0 - 3, top - 3, w + 6, barHeight + 6), const Radius.circular(5));
    c.drawRRect(back, _fill(const Color(0xE61A1210)));
    c.drawRRect(back, _stroke(const Color(0xFF0E0806), 1.5));
    for (var i = 0; i < total; i++) {
      final x = x0 + i * (barSegmentWidth + barSegmentGap);
      final seg = Rect.fromLTWH(x, top, barSegmentWidth, barHeight);
      final shape = RRect.fromRectAndRadius(seg, const Radius.circular(2.5));
      c.drawRRect(shape, _fill(const Color(0xFF3A2A22)));
      var fillW = 0.0;
      var flash = 0.0;
      if (i < left) {
        fillW = barSegmentWidth;
      } else if (i == left && sinceHit < healthDrainSeconds) {
        final k = (sinceHit / healthDrainSeconds).clamp(0.0, 1.0);
        fillW = barSegmentWidth * (1 - k);
        flash = 1 - k;
      }
      if (fillW > 0) {
        c.save();
        c.clipRRect(shape);
        c.drawRect(
          Rect.fromLTWH(x, top, fillW, barHeight),
          Paint()
            ..shader = Gradient.linear(Offset(0, top), Offset(0, top + barHeight),
                const [Color(0xFFFF7A5A), Color(0xFFD42F2F)]),
        );
        // A thin light line along the top edge.
        c.drawRect(Rect.fromLTWH(x, top + 1, fillW, 1.6), _fill(const Color(0x66FFFFFF)));
        c.restore();
      }
      if (flash > 0) {
        c.drawRRect(shape, _fill(Color.fromRGBO(255, 255, 255, 0.8 * flash)));
      }
    }
  }

  /// A strip on the floor from ([fromX], 0) to ([toX], 0), drawn in the enemy's own
  /// coordinates: its outline shows the whole reach and the fill grows to [filled] (0 to 1)
  /// from the enemy's side, with an arrow head at the far end.
  static void floorStrip(Canvas c,
      {required double fromX,
      required double toX,
      required double filled,
      Color color = const Color(0xFFFF4A3D)}) {
    final len = (toX - fromX).abs();
    if (len < 1) return;
    final dir = toX >= fromX ? 1.0 : -1.0;
    final left = math.min(fromX, toX);
    c.drawRect(Rect.fromLTWH(left, -5, len, 10),
        _fill(color.withValues(alpha: 0.18)));
    c.drawRect(Rect.fromLTWH(left, -5, len, 10),
        _stroke(color.withValues(alpha: 0.9), 2));
    final f = len * filled.clamp(0.0, 1.0);
    c.drawRect(
        Rect.fromLTWH(dir > 0 ? fromX : fromX - f, -5, f, 10),
        _fill(color.withValues(alpha: 0.65)));
    final head = Path()
      ..moveTo(toX, -14)
      ..lineTo(toX - dir * 14, -5)
      ..lineTo(toX, 4)
      ..close();
    c.drawPath(head, _fill(color));
  }

  /// The small red "!" bubble of a chaser that has just noticed the student: centred at
  /// ([cx], top - 14), bouncing a little with [t].
  static void noticeBang(Canvas c, double cx, double top, double t) {
    final bounce = math.sin(t * 14).abs() * 3;
    final cy = top - 14 - bounce;
    c.drawCircle(Offset(cx, cy), 11, _fill(const Color(0xFFE8433A)));
    c.drawCircle(Offset(cx, cy), 11, _stroke(const Color(0xFF5A100C), 2));
    final white = _fill(const Color(0xFFFFFFFF));
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - 1.8, cy - 6.5, 3.6, 8.5), const Radius.circular(1.6)),
        white);
    c.drawCircle(Offset(cx, cy + 5.5), 2, white);
  }
}
