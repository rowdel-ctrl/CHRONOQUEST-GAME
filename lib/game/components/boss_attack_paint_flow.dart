import 'dart:math' as math;
import 'dart:ui';

import 'boss_attack_paint.dart';

/// The round, flowing attacks, ported from the approved mock-up (boss.js): the water jet,
/// the whirlpool, the money vortex and the green whirlwind.

/// Bakunawa's water jet: a smooth stream, thin at the mouth and thick at its rounded head,
/// with droplets and spray. Sent back, it is a bright wave.
void paintWater(Canvas c, BossAttackFrame f) {
  if (f.rev) {
    _waterWave(c, f);
    return;
  }
  const n = 66;
  final pts = <Offset>[];
  for (var k = 0; k < n && pts.length < 22; k += 3) {
    pts.add(f.trail(k));
  }
  final len = pts.length;
  final t0 = f.anim * 14;
  double wd(int k) => 2 + math.pow(1 - k / len, 1.3) * 15;
  double off(int k) => math.sin(k * .7 + t0) * (k * .28);
  Offset at(int k, double side) => Offset(pts[k].dx, pts[k].dy + off(k) + side);

  Path band(double mul) {
    final path = Path();
    var first = true;
    for (var k = len - 1; k >= 0; k--) {
      final o = at(k, -wd(k) * mul);
      first ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      first = false;
    }
    for (var k = 0; k < len; k++) {
      final o = at(k, wd(k) * mul);
      path.lineTo(o.dx, o.dy);
    }
    return path..close();
  }

  // a soft glow under the stream
  c.drawPath(band(.9), fillPaint(rgb(0x7FD6FF, .28)));
  // the body of the jet
  final tail = pts[len - 1], head = pts[0];
  if ((head.dx - tail.dx).abs() > 1) {
    final shader = Gradient.linear(
      Offset(tail.dx, 0),
      Offset(head.dx, 0),
      [rgb(0x2F86E0, .35), rgb(0x4AA6F0), rgb(0xD6F1FF)],
      [0, .55, 1],
    );
    c.drawPath(
        band(.5),
        Paint()
          ..style = PaintingStyle.fill
          ..shader = shader);
  } else {
    c.drawPath(band(.5), fillPaint(rgb(0x4AA6F0)));
  }
  // a bright core line and foam streaks
  Path line(int from, int to, double side) {
    final path = Path();
    var first = true;
    for (var k = from; k >= to; k--) {
      final o = at(k, wd(k) * side);
      first ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      first = false;
    }
    return path;
  }

  c.drawPath(line(len - 1, 0, -.15),
      strokePaint(rgb(0xFFFFFF, .85), 2.5, round: true));
  if (len > 4) {
    c.drawPath(line(len - 1, 3, .3),
        strokePaint(rgb(0xFFFFFF, .45), 1.5, round: true));
  }
  // droplets flying off
  for (var k = 0; k < 10; k++) {
    final pt = pts[math.min(len - 1, 1 + k * 2)];
    final dy = math.sin(k * 2.3 + t0 * .8) * (8 + k * 1.2) * (k.isOdd ? 1 : -1);
    final col = k % 3 != 0
        ? rgb(0xBFE8FF, .85 - k * .05)
        : rgb(0xFFFFFF, .85 - k * .05);
    fillDisc(c, pt.dx - 4 + (k % 3) * 3, pt.dy + dy, math.max(.8, 2.4 - k * .1),
        col);
  }
  // the rounded head with a spray behind it
  final hx = head.dx, hy = head.dy;
  final headShader = Gradient.radial(
    Offset(hx, hy),
    17,
    [rgb(0xFFFFFF), rgb(0xBFE8FF), rgb(0x3489E6)],
    [0, .55, 1],
    TileMode.clamp,
    null,
    Offset(hx - 3, hy - 3),
    2,
  );
  c.drawCircle(
      Offset(hx, hy),
      16,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = headShader);
  c.drawCircle(Offset(hx, hy), 16, strokePaint(rgb(0xFFFFFF, .9), 2));
  for (var k = 0; k < 5; k++) {
    fillDisc(c, hx + 14 + k * 3, hy + (k - 2) * 7 + math.sin(t0 + k) * 2,
        3.2 - k * .3, k.isOdd ? rgb(0xFFFFFF) : rgb(0xBFE8FF));
  }
}

void _waterWave(Canvas c, BossAttackFrame f) {
  for (var k = 66 - 1; k >= 2; k -= 2) {
    final pt = f.trail(k);
    fillRect(
        c,
        pt.dx - 12,
        pt.dy - 8 + math.sin(k.toDouble()) * 8,
        8,
        8,
        (k % 4 != 0 ? rgb(0x6CC0FF) : rgb(0xD6F1FF))
            .withValues(alpha: math.max(0, 1 - k / 66)));
  }
  c.save();
  c.translate(f.x, f.y);
  final shader = Gradient.linear(const Offset(-30, 0), const Offset(14, 0),
      [rgb(0x2F86E0), rgb(0xBFE8FF)]);
  final path = Path()
    ..arcTo(Rect.fromCircle(center: Offset.zero, radius: 34), -1.3, 2.6, true)
    ..arcTo(Rect.fromCircle(center: const Offset(-16, 0), radius: 30), 1.3,
        -2.6, false)
    ..close();
  c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = shader);
  c.drawArc(Rect.fromCircle(center: Offset.zero, radius: 34), -1.15, 2.3, false,
      strokePaint(rgb(0xFFFFFF), 3));
  for (var k = 0; k < 6; k++) {
    fillRect(c, 30 + (k % 2) * 4, -26.0 + k * 10, 4, 4, rgb(0xFFFFFF, .9));
  }
  c.restore();
}

/// Bakunawa, phase 3: a standing whirlpool that rolls along the floor.
void paintWhirl(Canvas c, BossAttackFrame f) {
  final t = f.anim * 10, x = f.x, base = f.y + 14 + 2;
  const h = 70.0;
  for (var k = 3; k >= 1; k--) {
    final pt = f.trail(k * 2);
    strokeOval(c, pt.dx, base, 24, 5, rgb(0x7FC8FF, .22), 2);
  }
  final shader = Gradient.linear(Offset(0, base - h), Offset(0, base),
      [rgb(0xBEE8FF, .12), rgb(0x2F86E0, .6)]);
  final cone = Path()
    ..moveTo(x - 9, base - h)
    ..lineTo(x + 9, base - h)
    ..lineTo(x + 26, base)
    ..lineTo(x - 26, base)
    ..close();
  c.drawPath(
      cone,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = shader);
  for (var i = 0; i < 7; i++) {
    final fr = i / 6;
    final y = base - 6 - fr * h;
    final rx = 26 - fr * 14 + math.sin(t + i) * 2;
    final ph = t * 1.4 + i * 1.1;
    final rect = Rect.fromCenter(
        center: Offset(x + math.sin(ph) * 3, y),
        width: rx * 2,
        height: (5 + fr * 2) * 2);
    c.drawArc(rect, ph % tau, 4.6, false,
        strokePaint(i.isOdd ? rgb(0xE8F6FF) : rgb(0x7FC8FF), 3.2, round: true));
  }
  for (var k = 0; k < 9; k++) {
    final a2 = t * 1.6 + k * .7, rr = 22 + (k % 3) * 6;
    fillDisc(c, x + math.cos(a2) * rr * (1 - k / 12), base - 8 - (k * 7) % h,
        2.4, (k.isOdd ? rgb(0xFFFFFF) : rgb(0xBFE8FF)).withValues(alpha: .9));
  }
  c.drawArc(Rect.fromCenter(center: Offset(x, base), width: 60, height: 12),
      math.pi, math.pi, false, strokePaint(rgb(0xFFFFFF), 2.5));
}

/// Corruption boss, phase 3: a purple vortex of banknotes.
void paintVortex(Canvas c, BossAttackFrame f) {
  glowDot(c, f.x, f.y, 44, 0xB36BFF, .3);
  for (var k = 3; k >= 1; k--) {
    final pt = f.trail(k * 2);
    strokeOval(c, pt.dx, pt.dy, 8, 22, rgb(0xB36BFF, .25), 3);
  }
  strokeOval(c, f.x, f.y, 13, 30, rgb(0xB36BFF), 4);
  strokeOval(c, f.x, f.y, 8, 20, rgb(0xE0B8FF), 2.5);
  for (var j = 0; j < 5; j++) {
    final an = f.anim * 6 + j * 1.2566;
    c.save();
    c.translate(f.x + math.cos(an) * 13, f.y + math.sin(an) * 30);
    c.rotate(an);
    fillRect(c, -7, -3.5, 14, 7, rgb(0x4FAE6A));
    fillRect(c, -2, -2, 4, 4, rgb(0x2F7A46));
    c.restore();
  }
}

/// Commander, phase 3: a green whirlwind ring that grows as it comes.
void paintWind(Canvas c, BossAttackFrame f) {
  final sc = .5 + .9 * f.p;
  final sp = f.anim * 40;
  for (var k = 3; k >= 1; k--) {
    final pt = f.trail(k * 2);
    strokeOval(c, pt.dx, pt.dy, 8 * sc, 22 * sc, rgb(0x58D36A, .25), 3);
  }
  dashedOval(c, f.x, f.y, 12 * sc, 28 * sc, rgb(0x58D36A), 4,
      dash: 12, gap: 7, offset: -sp);
  dashedOval(c, f.x, f.y, 8 * sc, 20 * sc, rgb(0xD8FFD0), 2.5,
      dash: 12, gap: 7, offset: sp);
}
