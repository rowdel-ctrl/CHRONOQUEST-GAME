import 'dart:math' as math;
import 'dart:ui';

import 'boss_attack_paint.dart';

/// The attacks that strike, ported from the approved mock-up (boss.js): the gold sword slash,
/// the katana slash, the pistol shots, the sonic blast, the flaming banknotes and the ghost
/// knights.

const List<int> _blue = [0x4A86E8, 0xBFE0FF, 0xFFFFFF];

/// Governor (Pananakop ng Espanya): a gold crescent flying at chest height.
void paintGoldSlash(Canvas c, BossAttackFrame f) {
  final ang = f.rev ? 0.0 : math.pi;
  for (var k = 6; k >= 2; k -= 2) {
    final pt = f.trail(k);
    crescent(c, pt.dx, pt.dy, ang, 1.15 - k * .05, .3 - k * .03);
  }
  crescent(c, f.x, f.y, ang, 1.15, 1);
}

/// Commander: a white-blue crescent low along the ground.
void paintKatanaSlash(Canvas c, BossAttackFrame f) {
  final ang = f.rev ? 0.0 : math.pi;
  for (var k = 7; k >= 2; k -= 2) {
    final pt = f.trail(k);
    crescent(c, pt.dx, pt.dy, ang, 1.25 - k * .06, .3 - k * .03, _blue);
  }
  crescent(c, f.x, f.y, ang, 1.25, 1, _blue);
  fillRect(c, f.x + (f.rev ? -50 : 50), f.y + 26, 40, 2, rgb(0xFFFFFF, .5));
}

void _bullet(Canvas c, Offset pt, double tail) {
  c.drawLine(
      pt, Offset(pt.dx + tail, pt.dy), strokePaint(rgb(0xFFE6A0, .7), 3));
  fillRect(c, pt.dx - 8, pt.dy - 3, 16, 6, rgb(0xFFE9A0));
  fillRect(c, pt.dx - 9, pt.dy - 1, 6, 2, rgb(0xFFFFFF));
}

/// General: two fast bullets with a streak behind each.
void paintPistol(Canvas c, BossAttackFrame f) {
  final tail = f.rev ? -26.0 : 26.0;
  for (final i in const [0, 6]) {
    _bullet(c, f.trail(i), tail);
  }
}

/// General, phase 3: three bullets, and behind them the arcs of a blue sonic blast.
void paintSonic(Canvas c, BossAttackFrame f) {
  final dir = f.rev ? 1.0 : -1.0;
  final tail = -dir * 22;
  final a0 = dir < 0 ? math.pi : 0.0;
  const idx = [16, 21, 26];
  for (var n = 0; n < 3; n++) {
    final pt = f.trail(idx[n]);
    final r = 22.0 + n * 8;
    final col =
        (n > 0 ? rgb(0xBFE0FF) : rgb(0x7FB8FF)).withValues(alpha: 1 - n * .25);
    c.drawArc(
        Rect.fromCircle(center: Offset(pt.dx - dir * r, pt.dy), radius: r),
        a0 - 1,
        2,
        false,
        strokePaint(col, 4.0 - n));
  }
  for (final i in const [0, 5, 10]) {
    _bullet(c, f.trail(i), tail);
  }
}

/// Corruption boss: five spinning banknotes in a flaming fan that opens as it comes.
void paintFan(Canvas c, BossAttackFrame f) {
  for (var k = 1; k < 12; k += 2) {
    final pt = f.trail(k);
    fillDisc(c, pt.dx + 8, pt.dy, 7 - k * .3, rgb(0xFF8A1F, .3));
  }
  for (var i = -2; i <= 2; i++) {
    final off = i * (8 + 12 * (f.rev ? 1 : f.p));
    c.save();
    c.translate(f.x, f.y + off);
    c.rotate(f.anim * 9 + i);
    c.scale(1.3, 1.3);
    fillRect(c, -12, -7, 24, 14, rgb(0xFF8A1F));
    fillRect(c, -9.5, -4.5, 19, 9, rgb(0x4FAE6A));
    fillRect(c, -3, -2.5, 6, 5, rgb(0x2F7A46));
    c.restore();
    fillDisc(c, f.x + 9, f.y + off, 5, rgb(0xFFD24A, .6));
  }
}

/// Two blue ghost knights with fleur-de-lis shields. [x], [y] are the first one's middle and
/// feet; the second marches behind it.
void paintKnights(Canvas c, double x, double y, double anim) {
  for (var i = 0; i < 2; i++) {
    final cx = x + i * 46;
    final by = y - math.sin(anim * 8 + i * 2).abs() * 2;
    final al = (i == 1 ? .8 : 1.0) * (.8 + .15 * math.sin(anim * 12 + i));
    Color col(int hex) => rgb(hex, al);
    glowDot(c, cx - 6, by - 40, 52, 0x7FB8FF, .22 * al);
    fillRect(c, cx - 9, by - 22, 7, 22, col(0x4F8FE8));
    fillRect(c, cx + 2, by - 22, 7, 22, col(0x4F8FE8));
    fillRect(c, cx - 12, by - 52, 24, 32, col(0x4F8FE8));
    fillRect(c, cx - 8, by - 68, 16, 16, col(0x7FB8FF));
    fillRect(c, cx - 8, by - 62, 16, 3, col(0x16305E));
    fillPolygon(
        c,
        [
          Offset(cx - 3, by - 68),
          Offset(cx + 5, by - 80),
          Offset(cx + 8, by - 66)
        ],
        col(0xBFE0FF));
    fillPolygon(
        c,
        [
          Offset(cx - 30, by - 56),
          Offset(cx - 10, by - 56),
          Offset(cx - 10, by - 34),
          Offset(cx - 20, by - 24),
          Offset(cx - 30, by - 34),
        ],
        col(0x9FCBFF));
    fillRect(c, cx - 21, by - 52, 3, 18, col(0x16305E));
    fillRect(c, cx - 26, by - 46, 13, 3, col(0x16305E));
    fillRect(c, cx - 24, by - 38, 9, 2, col(0x16305E));
  }
}
