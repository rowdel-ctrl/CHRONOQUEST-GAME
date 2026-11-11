import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/hero_move_constants.dart';
import 'art_scale.dart';

/// Everything the hero moves draw, in code (no pictures): the flying things, the
/// dash afterimages, the slash and the safe ring. Ported from the approved mockup
/// (wpn.js). Every flying shape is drawn at the origin and points towards +x; the
/// caller mirrors the canvas for a thing flying left.

const Color _gold = Color(0xFFFFC531);
const Color _coinGold = Color(0xFFFFD24A);
const Color _glow = Color(0xFFBFE6FF);
const Color _waveBlue = Color(0xFF8FD0FF);

final Paint _fill = Paint();
final Paint _line = Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round;

/// Draws one flying shape at the origin. [spin] is a growing number (radians) that
/// the coin, petals and pages turn with.
void paintHeroShape(Canvas canvas, HeroMoveShape shape,
    {required double spin}) {
  switch (shape) {
    case HeroMoveShape.star:
      canvas.save();
      canvas.rotate(spin);
      _star(canvas, 13, _coinGold);
      _star(canvas, 7, const Color(0xFFFFFFFF));
      canvas.restore();
    case HeroMoveShape.net:
      _net(canvas);
    case HeroMoveShape.bullet:
      _bullet(canvas);
    case HeroMoveShape.saber:
      _saberWave(canvas);
    case HeroMoveShape.petals:
      _petals(canvas, spin);
    case HeroMoveShape.page:
      _page(canvas, spin);
  }
}

/// A star of [r] with 8 points (16 corners alternating long and short).
void _star(Canvas canvas, double r, Color color) {
  final path = Path();
  for (var i = 0; i < 16; i++) {
    final a = i * pi / 8;
    final rr = i.isOdd ? r * 0.32 : r;
    final p = Offset(cos(a) * rr, sin(a) * rr);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  path.close();
  canvas.drawPath(path, _fill..color = color);
}

/// A bright arc bulging forwards: gold wide stroke under a thin white one.
void _crescent(Canvas canvas, double r,
    {Color outer = _gold, double alpha = 1}) {
  final rect = Rect.fromCircle(center: Offset(-r * 0.55, 0), radius: r);
  _line
    ..strokeWidth = 8
    ..color = outer.withValues(alpha: alpha);
  canvas.drawArc(rect, -0.95, 1.9, false, _line);
  _line
    ..strokeWidth = 3
    ..color = const Color(0xFFFFFFFF).withValues(alpha: alpha);
  canvas.drawArc(rect, -0.95, 1.9, false, _line);
}

/// Maria's net: five strands fanning out from behind, and a curved rim in front.
void _net(Canvas canvas) {
  _line
    ..strokeWidth = 2
    ..color = _gold;
  for (var k = -2; k <= 2; k++) {
    canvas.drawLine(const Offset(-26, 0), Offset(6, k * 9.0), _line);
  }
  final rim = Path()
    ..moveTo(4, -22)
    ..quadraticBezierTo(14, 0, 4, 22);
  canvas.drawPath(rim, _line);
}

/// Del Pilar's shot: a pale streak behind a small bright arc.
void _bullet(Canvas canvas) {
  _line
    ..strokeWidth = 2
    ..color = const Color(0xFFFFE9A0);
  canvas.drawLine(const Offset(-70, 0), Offset.zero, _line);
  canvas.save();
  canvas.translate(4, 0);
  _crescent(canvas, 10);
  canvas.restore();
}

/// Luna's saber wave: a big blue-white crescent with a soft glow.
void _saberWave(Canvas canvas) {
  const r = 34.0;
  final rect = Rect.fromCircle(center: const Offset(-r * 0.55, -4), radius: r);
  _line
    ..strokeWidth = 14
    ..color = _glow.withValues(alpha: 0.55)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  canvas.drawArc(rect, -0.95, 1.9, false, _line);
  _line.maskFilter = null;
  _line
    ..strokeWidth = 8
    ..color = _waveBlue;
  canvas.drawArc(rect, -0.95, 1.9, false, _line);
  _line
    ..strokeWidth = 3
    ..color = const Color(0xFFFFFFFF);
  canvas.drawArc(rect, -0.95, 1.9, false, _line);
}

/// Where each of Maria Clara's 9 petals sits, fixed so the gust does not shimmer.
final List<({double x, double y, double r, double turn})> _petalSpots = () {
  final rng = Random(5);
  return List.generate(9, (_) {
    final x = -rng.nextDouble() * 46;
    final y = (rng.nextDouble() - 0.5) * 60;
    final r = 4 + rng.nextDouble() * 4;
    final turn = (rng.nextDouble() - 0.5) * 2;
    return (x: x, y: y, r: r, turn: turn);
  });
}();

void _petals(Canvas canvas, double spin) {
  for (var i = 0; i < _petalSpots.length; i++) {
    final s = _petalSpots[i];
    canvas.save();
    canvas.translate(s.x, s.y);
    canvas.rotate(spin * s.turn);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s.r * 3.2, height: s.r * 2),
      _fill
        ..color = i.isOdd ? const Color(0xFFFFB8D0) : const Color(0xFFFFFFFF),
    );
    canvas.restore();
  }
}

/// One of Rizal's pages: a cream sheet with three lines of writing, wobbling.
void _page(Canvas canvas, double spin) {
  canvas.save();
  canvas.rotate(sin(spin) * 0.3);
  canvas.drawRect(const Rect.fromLTWH(-9, -11, 18, 22),
      _fill..color = const Color(0xFFF3EAD2));
  _fill.color = const Color(0xFF8A6A3A);
  for (var j = 0; j < 3; j++) {
    canvas.drawRect(Rect.fromLTWH(-6, -7 + j * 6.0, 12, 2), _fill);
  }
  canvas.restore();
}

// ─── Dash ───────────────────────────────────────────────────────────────────

/// Ghost copies of [sprite] trailing behind a dashing hero. Positions are in the
/// hero's own coordinates, the feet at ([footX], [footY]).
void paintDashAfterimages(
  Canvas canvas,
  Sprite sprite, {
  required double footX,
  required double footY,
  required bool facingRight,
}) {
  final dir = facingRight ? 1.0 : -1.0;
  final ghost = Paint()
    ..color = const Color(0xFFFFFFFF)
        .withValues(alpha: HeroMoveConstants.afterimageAlpha);
  for (var k = HeroMoveConstants.afterimages; k >= 1; k--) {
    paintArt(
      canvas,
      sprite,
      footX: footX - dir * k * HeroMoveConstants.afterimageSpacing,
      footY: footY,
      flip: !facingRight,
      overridePaint: ghost,
    );
  }
}

/// The slash crescent in front of a dashing hero: it grows and fades over the dash.
/// [progress] is 0..1 through the dash, [distance] how far it goes.
void paintDashSlash(
  Canvas canvas, {
  required double footX,
  required double footY,
  required bool facingRight,
  required double progress,
  required double distance,
}) {
  final alpha = sin(progress.clamp(0.0, 1.0) * pi);
  if (alpha <= 0) return;
  canvas.save();
  canvas.translate(footX + (facingRight ? 62 : -62), footY - 66);
  if (!facingRight) canvas.scale(-1, 1);
  _crescent(canvas, 22 + distance / 6, alpha: alpha);
  canvas.restore();
}

/// The pale blue ring around a hero who cannot be hurt for the moment.
void paintSafeRing(Canvas canvas,
    {required double footX, required double footY}) {
  _line
    ..strokeWidth = 3
    ..color = const Color(0xD978C8FF);
  canvas.drawOval(
      Rect.fromCenter(
          center: Offset(footX, footY - 52), width: 88, height: 132),
      _line);
}
