import 'dart:math' as math;
import 'dart:ui';

import '../boss_attack_profile.dart';
import 'boss_attack_paint_flow.dart';
import 'boss_attack_paint_strike.dart';

/// Everything a painter needs to draw one attack at one moment. All in world units.
class BossAttackFrame {
  const BossAttackFrame({
    required this.kind,
    required this.x,
    required this.y,
    required this.p,
    required this.q,
    required this.rev,
    required this.anim,
    required this.trail,
  });

  final BossAttackKind kind;

  /// The head of the attack.
  final double x, y;

  /// How far it has come (0 at the boss, 1 at the hero).
  final double p;

  /// While it is sent back: how far it has gone back (0 to 1). Otherwise 0.
  final double q;

  /// True while it is sent back at the boss.
  final bool rev;

  /// Seconds since it was thrown, for spinning and wobbling.
  final double anim;

  /// Where the head was [k] steps ago (a step is `kind.trail.step` of progress). Past the
  /// number of steps the kind keeps, the last one is returned.
  final Offset Function(int k) trail;
}

/// Draws one attack. [alpha] below 1 fades all of it (ghost knights vanishing).
void paintBossAttack(Canvas canvas, BossAttackFrame f, {double alpha = 1}) {
  if (alpha <= 0) return;
  if (alpha < 1) {
    canvas.saveLayer(
        null, Paint()..color = Color.fromRGBO(255, 255, 255, alpha));
  }
  switch (f.kind) {
    case BossAttackKind.water:
      paintWater(canvas, f);
    case BossAttackKind.whirl:
      paintWhirl(canvas, f);
    case BossAttackKind.vortex:
      paintVortex(canvas, f);
    case BossAttackKind.wind:
      paintWind(canvas, f);
    case BossAttackKind.gslash:
      paintGoldSlash(canvas, f);
    case BossAttackKind.slash:
      paintKatanaSlash(canvas, f);
    case BossAttackKind.pistol:
      paintPistol(canvas, f);
    case BossAttackKind.sonic:
      paintSonic(canvas, f);
    case BossAttackKind.fan:
      paintFan(canvas, f);
    case BossAttackKind.knights:
    case BossAttackKind.ghost:
      paintKnights(canvas, f.x, f.y, f.anim);
  }
  if (alpha < 1) canvas.restore();
}

// ---------- small drawing helpers shared by the painters ----------

const double tau = math.pi * 2;
final Paint _paint = Paint();

/// A colour from 0xRRGGBB with an opacity.
Color rgb(int hex, [double a = 1]) =>
    Color(0xFF000000 | hex).withValues(alpha: a.clamp(0.0, 1.0));

/// A fresh fill paint (shared and reset on every use).
Paint fillPaint(Color c) => _paint
  ..style = PaintingStyle.fill
  ..shader = null
  ..maskFilter = null
  ..strokeCap = StrokeCap.butt
  ..color = c;

Paint strokePaint(Color c, double w, {bool round = false}) => _paint
  ..style = PaintingStyle.stroke
  ..shader = null
  ..maskFilter = null
  ..strokeWidth = w
  ..strokeCap = round ? StrokeCap.round : StrokeCap.butt
  ..color = c;

void fillRect(Canvas c, double x, double y, double w, double h, Color col) =>
    c.drawRect(Rect.fromLTWH(x, y, w, h), fillPaint(col));

void fillDisc(Canvas c, double x, double y, double r, Color col) =>
    c.drawCircle(Offset(x, y), r, fillPaint(col));

void strokeOval(Canvas c, double x, double y, double rx, double ry, Color col,
        double w) =>
    c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: ry * 2),
        strokePaint(col, w));

void fillPolygon(Canvas c, List<Offset> pts, Color col) {
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final p in pts.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  c.drawPath(path..close(), fillPaint(col));
}

/// A soft round glow.
void glowDot(Canvas c, double x, double y, double r, int rgbHex, double a) {
  final shader = Gradient.radial(
    Offset(x, y),
    r,
    [rgb(rgbHex, a), rgb(rgbHex, 0)],
  );
  c.drawCircle(
      Offset(x, y),
      r,
      _paint
        ..style = PaintingStyle.fill
        ..maskFilter = null
        ..shader = shader);
  _paint.shader = null;
}

/// An ellipse outline drawn as dashes that crawl along it (the whirlwind ring).
void dashedOval(
    Canvas c, double x, double y, double rx, double ry, Color col, double w,
    {required double dash, required double gap, required double offset}) {
  final path = Path()
    ..addOval(
        Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: ry * 2));
  final paint = strokePaint(col, w);
  for (final metric in path.computeMetrics()) {
    final period = dash + gap;
    var d = -(offset % period);
    while (d < metric.length) {
      final a = math.max(0.0, d);
      final b = math.min(metric.length, d + dash);
      if (b > a) c.drawPath(metric.extractPath(a, b), paint);
      d += period;
    }
  }
}

/// A crescent: the gold sword slash, the white-blue katana slash. [ang] turns it (pi faces
/// left), [sc] scales it, [a] is its opacity, [cols] the three colours of its gradient.
void crescent(Canvas c, double x, double y, double ang, double sc, double a,
    [List<int> cols = const [0xFF9F1C, 0xFFD84A, 0xFFF6C8]]) {
  if (a <= 0) return;
  c.save();
  c.translate(x, y);
  c.rotate(ang);
  c.scale(sc, sc);
  final shader = Gradient.linear(
    const Offset(-26, 0),
    const Offset(20, 0),
    [rgb(cols[0], a), rgb(cols[1], a), rgb(cols[2], a)],
    [0, .7, 1],
  );
  final path = Path()
    ..arcTo(Rect.fromCircle(center: Offset.zero, radius: 30), -1.15, 2.3, true)
    ..arcTo(Rect.fromCircle(center: const Offset(-12, 0), radius: 27), 1.15,
        -2.3, false)
    ..close();
  c.drawPath(
      path,
      _paint
        ..style = PaintingStyle.fill
        ..maskFilter = null
        ..shader = shader);
  _paint.shader = null;
  c.restore();
}

/// A pointed star (the dizzy stars, sparkles).
void star(Canvas c, double x, double y, double r, Color col) {
  final path = Path();
  for (var i = 0; i < 16; i++) {
    final an = i * math.pi / 8;
    final rr = i.isOdd ? r * .32 : r;
    final px = x + math.cos(an) * rr, py = y + math.sin(an) * rr;
    i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
  }
  c.drawPath(path..close(), fillPaint(col));
}
