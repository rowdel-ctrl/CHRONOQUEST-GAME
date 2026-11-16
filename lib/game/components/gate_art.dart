import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// The six era gates, drawn in code (ported from the approved gate mockup).
///
/// Every gate is [width] x [height] (200 x 220) with a [doorWidth] x
/// [doorHeight] (104 x 134) opening at the bottom centre. The drawing works in
/// the gate's own coordinates: x from 0 at its left edge, y from 0 at its top,
/// the ground at y = [height]. Things such as roofs, sentry boxes and torches
/// stick out past that box on purpose.
///
/// Each era is split in layers so the still parts can be recorded once
/// (`ui.Picture`) and the moving parts drawn every frame:
///   1. [paintBack]      still: shadow, walls, posts, roofs
///   2. [paintBackLive]  moving: shell chimes, lamp globes, searchlight, LED
///   3. the doorway      (GateComponent): dark interior, glow, [paintPanel] lifted
///   4. [paintFront]     still: arch ring, cloth, emblem, torch poles
///   5. [paintFrontLive] moving: torch flames, banners, parols, lanterns
/// then the lamp ([paintLamp]), the step-in guide ([paintGuide]) and specks.
enum GateKind { bamboo, stone, wood, brick, sandbag, concrete }

class GateArt {
  GateArt._();

  static const double width = 200;
  static const double height = 220;
  static const double doorX = 48;
  static const double doorWidth = 104;
  static const double doorHeight = 134;
  static const double doorY = height - doorHeight; // 86
  static const double centreX = width / 2; // 100

  /// The gate each era stands in. Anything unknown gets the stone one.
  static GateKind kindForEra(String era) => switch (era) {
        'pre-colonial' => GateKind.bamboo,
        'spanish' => GateKind.stone,
        'nationalism' => GateKind.wood,
        'american' => GateKind.brick,
        'ww2' => GateKind.sandbag,
        'modern' => GateKind.concrete,
        _ => GateKind.stone,
      };

  /// Stone and concrete gates have an arched opening, the rest a square one.
  static bool hasArch(GateKind k) =>
      k == GateKind.stone || k == GateKind.concrete;

  static Color trim(GateKind k) => switch (k) {
        GateKind.bamboo => _hx(0x6e4d1a),
        GateKind.stone => _hx(0x4b3f30),
        GateKind.wood => _hx(0x2e1f0f),
        GateKind.brick => _hx(0xe8dfc8),
        GateKind.sandbag => _hx(0x3b4249),
        GateKind.concrete => _hx(0x7fd6ff),
      };

  /// The colour of the specks drifting up past the gate.
  static Color motes(GateKind k) => switch (k) {
        GateKind.bamboo => _hx(0xd6f58a),
        GateKind.stone => _hx(0xffd98a),
        GateKind.wood => _hx(0xffb05a),
        GateKind.brick => _hx(0xfff0b0),
        GateKind.sandbag => _hx(0xcfd6c0),
        GateKind.concrete => _hx(0x9be8ff),
      };

  /// Where the lamp (the old wax seal) sits: the era's emblem.
  static Offset lampAt(GateKind k) => switch (k) {
        GateKind.bamboo => const Offset(centreX, doorY - 53),
        GateKind.stone => const Offset(centreX, doorY - 52),
        GateKind.wood => const Offset(centreX, doorY - 50),
        GateKind.brick => const Offset(centreX, doorY - 50),
        GateKind.sandbag => const Offset(centreX, doorY - 19),
        GateKind.concrete => const Offset(centreX, doorY - 30),
      };

  /// The opening, from its top to the ground.
  static Path doorPath(GateKind k) =>
      _openPath(doorX, doorY, doorWidth, doorHeight, hasArch(k));

  // ───────────────────────────── drawing helpers ─────────────────────────────

  static final Paint _fp = Paint()..isAntiAlias = true;
  static final Paint _sp = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke;

  static Color _hx(int rgb, [double a = 1]) =>
      Color(0xFF000000 | rgb).withValues(alpha: a.clamp(0.0, 1.0));
  static Color _rgba(int r, int g, int b, double a) =>
      Color.fromRGBO(r, g, b, a.clamp(0.0, 1.0));
  static Color _white(double a) => _rgba(255, 255, 255, a);
  static Color _black(double a) => _rgba(0, 0, 0, a);

  static Paint _fill(Color c) => _fp
    ..shader = null
    ..maskFilter = null
    ..color = c;

  static Paint _stroke(Color c, double w,
          {StrokeCap cap = StrokeCap.butt,
          StrokeJoin join = StrokeJoin.miter}) =>
      _sp
        ..shader = null
        ..maskFilter = null
        ..color = c
        ..strokeWidth = w
        ..strokeCap = cap
        ..strokeJoin = join;

  static double _lerp(double a, double b, double u) => a + (b - a) * u;

  /// A repeatable pseudo-random number in 0..1 for [n].
  static double _rnd(double n) {
    final s = sin(n * 127.1 + 311.7) * 43758.5453;
    return s - s.floorToDouble();
  }

  static void _rect(
          Canvas c, Color col, double x, double y, double w, double h) =>
      c.drawRect(Rect.fromLTWH(x, y, w, h), _fill(col));

  static void _circle(Canvas c, Color col, double x, double y, double r) =>
      c.drawCircle(Offset(x, y), r, _fill(col));

  static void _oval(
          Canvas c, Color col, double x, double y, double rx, double ry) =>
      c.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: ry * 2),
          _fill(col));

  static Path _polyPath(List<double> p) {
    final path = Path()..moveTo(p[0], p[1]);
    for (var i = 2; i + 1 < p.length; i += 2) {
      path.lineTo(p[i], p[i + 1]);
    }
    return path..close();
  }

  static void _poly(Canvas c, Color col, List<double> p) =>
      c.drawPath(_polyPath(p), _fill(col));

  static void _line(Canvas c, Color col, double w, double x1, double y1,
          double x2, double y2,
          {StrokeCap cap = StrokeCap.butt}) =>
      c.drawLine(Offset(x1, y1), Offset(x2, y2), _stroke(col, w, cap: cap));

  /// The top half of a circle (what the mockup's `arc(.., PI, 0)` draws).
  static void _arcTop(Canvas c, Paint p, double x, double y, double r) =>
      c.drawArc(
          Rect.fromCircle(center: Offset(x, y), radius: r), pi, pi, false, p);

  static Path _openPath(double x, double y, double w, double h, bool arch) {
    final p = Path()..moveTo(x, y + h);
    final r = w / 2;
    if (arch) {
      p
        ..lineTo(x, y + r)
        ..arcTo(Rect.fromCircle(center: Offset(x + r, y + r), radius: r), pi,
            pi, false);
    } else {
      p
        ..lineTo(x, y)
        ..lineTo(x + w, y);
    }
    return p
      ..lineTo(x + w, y + h)
      ..close();
  }

  static Path _star5(double x, double y, double ro, double ri,
      [double rot = -pi / 2]) {
    final path = Path();
    for (var k = 0; k < 10; k++) {
      final r = k.isOdd ? ri : ro, an = rot + k * pi / 5;
      final px = x + cos(an) * r, py = y + sin(an) * r;
      k == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
    }
    return path..close();
  }

  static void _sunDisc(
      Canvas c, double x, double y, double r, int rays, Color col, double rot) {
    for (var i = 0; i < rays; i++) {
      final a = rot + i * 2 * pi / rays;
      final path = Path()
        ..moveTo(x + cos(a - .1) * r, y + sin(a - .1) * r)
        ..lineTo(x + cos(a) * r * 1.55, y + sin(a) * r * 1.55)
        ..lineTo(x + cos(a + .1) * r, y + sin(a + .1) * r)
        ..close();
      c.drawPath(path, _fill(col));
    }
    _circle(c, col, x, y, r);
  }

  static void _leaf(
      Canvas c, double x, double y, double len, double ang, Color col) {
    c.save();
    c.translate(x, y);
    c.rotate(ang);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(len * .5, -len * .22, len, 0)
      ..quadraticBezierTo(len * .5, len * .18, 0, 0)
      ..close();
    c.drawPath(path, _fill(col));
    _line(c, _black(.25), 1, 0, 0, len, 0);
    c.restore();
  }

  /// A left-to-right light and shadow wash over a column.
  static void _shade(
      Canvas c, double x, double y, double w, double h, double l, double d) {
    final p = Paint()
      ..shader = ui.Gradient.linear(
        Offset(x, 0),
        Offset(x + w, 0),
        [_white(l), _white(0), _black(0), _black(d)],
        const [0, .35, .7, 1],
      );
    c.drawRect(Rect.fromLTWH(x, y, w, h), p);
  }

  /// A wall of blocks or bricks in staggered rows, each a little lighter or
  /// darker than the next.
  static void _blocks(Canvas c, double x, double y, double w, double h,
      Color base, Color mortar, double bw, double bh, double vary) {
    c.save();
    c.clipRect(Rect.fromLTWH(x, y, w, h));
    var r = 0;
    for (var yy = y; yy < y + h; yy += bh, r++) {
      var col = 0;
      for (var xx = x - (r.isOdd ? bw / 2 : 0); xx < x + w; xx += bw, col++) {
        final k = _rnd(r * 31 + col * 7 + x);
        _rect(c, base, xx, yy, bw, bh);
        _rect(c, k > .5 ? _white((k - .5) * vary) : _black((.5 - k) * vary), xx,
            yy, bw, bh);
        _rect(c, _white(.13), xx + 1, yy + 1.2, bw - 2, 1.4);
        _rect(c, mortar, xx, yy, bw, 1.3);
        _rect(c, mortar, xx, yy, 1.3, bh);
      }
    }
    c.restore();
  }

  // ─────────────────────────────── text ────────────────────────────────────

  static TextPainter? _haltText;
  static TextPainter? _pasokText;
  static final Paint _tint = Paint();

  static TextPainter _label(String text, double size, Color color,
      {double spacing = 0}) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: spacing,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  /// Draws [tp] with its baseline at [baseline] and its middle at [x].
  static void _paintText(Canvas c, TextPainter tp, double x, double baseline) {
    final up = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(c, Offset(x - tp.width / 2, baseline - up));
  }

  // ─────────────────────────────── layer 1: back ───────────────────────────

  /// The still parts behind the doorway, including the shadow on the ground.
  static void paintBack(Canvas c, GateKind k) {
    _oval(c, _black(.28), centreX, height + 3, width * .62, 8);
    switch (k) {
      case GateKind.bamboo:
        _bambooBack(c);
      case GateKind.stone:
        _stoneBack(c);
      case GateKind.wood:
        _woodBack(c);
      case GateKind.brick:
        _brickBack(c);
      case GateKind.sandbag:
        _sandbagBack(c);
      case GateKind.concrete:
        _concreteBack(c);
    }
  }

  /// The moving parts behind the doorway. [led] is the concrete ring's colour.
  static void paintBackLive(Canvas c, GateKind k, double t, Color led) {
    switch (k) {
      case GateKind.bamboo:
        _bambooChimes(c, t);
      case GateKind.stone:
        break;
      case GateKind.wood:
        _sunDisc(c, centreX, doorY - 50, 18, 14, _hx(0xe8b72a), t * .15);
      case GateKind.brick:
        _brickLive(c, t);
      case GateKind.sandbag:
        _searchlight(c, t);
      case GateKind.concrete:
        _concreteLive(c, t, led);
    }
  }

  static void _bambooBack(Canvas c) {
    const w = width, top = 0.0, oy = doorY, gy = height;
    for (final px in const [0.0, w - 48]) {
      for (var i = 0; i < 4; i++) {
        final px2 = px + i * 12;
        _rect(c, i.isOdd ? _hx(0x8fb350) : _hx(0xa6c862), px2, top + 44, 11,
            gy - top - 44);
        _rect(c, _white(.3), px2 + 1.5, top + 44, 2, gy - top - 44);
        _rect(c, _black(.24), px2 + 8, top + 44, 3, gy - top - 44);
        for (var yy = top + 58 + (i * 9) % 26; yy < gy - 4; yy += 28) {
          _rect(c, _hx(0x4d6b24), px2, yy, 11, 2.4);
        }
      }
      for (final yy in const [gy - 36, gy - 100, top + 82]) {
        _rect(c, _hx(0xb9873a), px - 3, yy, 54, 8);
        _rect(c, _white(.25), px - 3, yy, 54, 2);
        for (var xx = px - 2; xx < px + 50; xx += 6) {
          _line(c, _hx(0x6e4d1a), 1.3, xx, yy, xx + 4, yy + 8);
        }
      }
    }
    // The cross beam: two bamboo poles.
    for (var k = 0; k < 2; k++) {
      final by = oy - 20 + k * 11;
      _rect(c, k == 1 ? _hx(0x8fb350) : _hx(0xa6c862), -8, by, w + 16, 10);
      _rect(c, _white(.3), -8, by + 1, w + 16, 2);
      for (var xx = 6.0; xx < w; xx += 34) {
        _rect(c, _hx(0x4d6b24), xx, by, 2.4, 10);
      }
    }
    // The thatch roof, a fringe and crossed sticks on the ridge.
    const rl = -26.0, rr = w + 26, eave = top + 50, ridge = top + 4;
    final roof = Path()
      ..moveTo(rl, eave)
      ..lineTo(34, ridge)
      ..lineTo(w - 34, ridge)
      ..lineTo(rr, eave)
      ..close();
    c.drawPath(
      roof,
      Paint()
        ..isAntiAlias = true
        ..shader = ui.Gradient.linear(const Offset(0, ridge),
            const Offset(0, eave), [_hx(0xe2c46a), _hx(0xb98f35)]),
    );
    c.save();
    c.clipPath(roof);
    for (var i = 0; i <= 34; i++) {
      final u = i / 34;
      _line(c, _rgba(110, 80, 20, .5), 1.2, _lerp(34, w - 34, u), ridge,
          _lerp(rl, rr, u), eave);
    }
    for (final f in const [.38, .7]) {
      final yy = _lerp(ridge, eave, f);
      _line(c, _rgba(90, 60, 10, .65), 2, rl, yy, rr, yy);
    }
    c.restore();
    for (var xx = rl + 3; xx < rr; xx += 5) {
      _line(c, _hx(0x8a6a22), 1.6, xx, eave, xx + 1, eave + 6 + _rnd(xx) * 6);
    }
    for (final ax in const [34.0, w - 34]) {
      final sticks = Path()
        ..moveTo(ax - 9, ridge + 8)
        ..lineTo(ax + 9, ridge - 16)
        ..moveTo(ax + 9, ridge + 8)
        ..lineTo(ax - 9, ridge - 16);
      c.drawPath(sticks, _stroke(_hx(0x8fb350), 3));
    }
    // Banana leaves at the foot.
    for (var j = 0; j < 2; j++) {
      final lx = j == 1 ? w + 6 : -6.0;
      for (var i = 0; i < 5; i++) {
        _leaf(
            c,
            lx,
            gy,
            46.0 + i * 5,
            j == 1 ? -(pi - .3 - i * .5) : -(.3 + i * .5),
            i.isOdd ? _hx(0x4f9a3b) : _hx(0x62b34a));
      }
    }
  }

  static void _bambooChimes(Canvas c, double t) {
    const oy = doorY;
    for (var j = 0; j < 2; j++) {
      final hx = j == 0 ? doorX + 14 : doorX + doorWidth - 14;
      for (var i = 0; i < 4; i++) {
        final sx = hx + sin(t * 2 + i + j) * 2.5, sy = oy + 6 + i * 12;
        _line(c, _hx(0x6e4d1a), 1, hx, oy + 2, sx, sy);
        _oval(c, _hx(0xf4ecd8), sx, sy + 3, 3.4, 5);
        c.drawOval(
            Rect.fromCenter(center: Offset(sx, sy + 3), width: 6.8, height: 10),
            _stroke(_hx(0xc9b88a), 1));
      }
    }
  }

  static void _stoneBack(Canvas c) {
    const w = width, top = 0.0, gy = height, cx = centreX;
    final mortar = _rgba(60, 52, 44, .7);
    // The wall with a battlement along the top.
    _blocks(
        c, 0, top + 22, w, gy - top - 22, _hx(0xb9ae98), mortar, 28, 15, .2);
    for (var xx = 0.0; xx < w - 4; xx += 28) {
      _blocks(c, xx + 2, top + 6, 17, 17, _hx(0xc4baa4), mortar, 17, 8.5, .16);
    }
    _rect(c, _hx(0xd8cdb4), -2, top + 21, w + 4, 4);
    _shade(c, 0, top + 6, w, gy - top - 6, .18, .3);
    // Two sentry boxes (garitas) at the corners.
    for (final gx in const [-4.0, w - 24]) {
      _blocks(c, gx, top - 16, 28, 34, _hx(0xcfc4ac), _rgba(60, 52, 44, .6), 14,
          8, .14);
      _shade(c, gx, top - 16, 28, 34, .2, .3);
      _poly(c, _hx(0x7a6f5d),
          [gx + 6, top + 18, gx + 22, top + 18, gx + 14, top + 30]);
      final slit = Path()
        ..moveTo(gx + 8, top + 10)
        ..lineTo(gx + 8, top - 4)
        ..arcTo(Rect.fromCircle(center: Offset(gx + 14, top - 4), radius: 6),
            pi, pi, false)
        ..lineTo(gx + 20, top + 10)
        ..close();
      c.drawPath(slit, _fill(_hx(0x15110c)));
      final roof =
          _polyPath([gx - 3, top - 16, gx + 14, top - 36, gx + 31, top - 16]);
      c.drawPath(roof, _fill(_hx(0xb0502f)));
      c.save();
      c.clipPath(roof);
      _rect(c, _black(.25), gx + 14, top - 36, 17, 20);
      c.restore();
      _circle(c, _hx(0xe6c46a), gx + 14, top - 38, 3);
    }
    // The stone cross on the middle.
    _rect(c, _hx(0xe1d6bd), cx - 4, top - 34, 8, 44);
    _rect(c, _hx(0xe1d6bd), cx - 13, top - 24, 26, 7);
    _rect(c, _black(.2), cx + 1, top - 34, 3, 44);
    // Moss at the foot.
    for (var i = 0; i < 9; i++) {
      _oval(c, _rgba(86, 130, 60, .45), 8 + _rnd(i * 1.0) * 40,
          gy - 4 - _rnd(i + 9.0) * 10, 6 + _rnd(i + 3.0) * 8, 4);
      _oval(c, _rgba(86, 130, 60, .45), w - 8 - _rnd(i + 20.0) * 40,
          gy - 4 - _rnd(i + 30.0) * 10, 6 + _rnd(i + 5.0) * 8, 4);
    }
  }

  static void _woodBack(Canvas c) {
    const w = width, top = 0.0, oy = doorY, gy = height, cx = centreX;
    // Two log posts carved with a column of diamonds.
    for (final px in const [0.0, w - 48]) {
      for (var i = 0; i < 4; i++) {
        _rect(c, i.isOdd ? _hx(0x7a4f27) : _hx(0x8f5f30), px + i * 12, top + 40,
            12, gy - top - 40);
        _rect(c, _black(.25), px + i * 12 + 10, top + 40, 2, gy - top - 40);
        for (var yy = top + 60 + i * 13; yy < gy - 6; yy += 41) {
          _rect(c, _black(.18), px + i * 12 + 3, yy, 1.4, 14);
        }
      }
      _shade(c, px, top + 40, 48, gy - top - 40, .18, .35);
      for (var yy = top + 70; yy < gy - 20; yy += 34) {
        _poly(c, _hx(0xe8b72a),
            [px + 24, yy - 10, px + 33, yy, px + 24, yy + 10, px + 15, yy]);
        _circle(c, _hx(0x7a1f1a), px + 24, yy, 3);
      }
      _rect(c, _hx(0x3a2a1a), px - 4, gy - 12, 56, 12);
      _rect(c, _white(.15), px - 4, gy - 12, 56, 2);
    }
    // The cross beam with round log ends.
    _rect(c, _hx(0x8f5f30), -12, oy - 30, w + 24, 30);
    for (var i = 1; i < 4; i++) {
      _rect(c, _black(.25), -12, oy - 30 + i * 7.5, w + 24, 1.4);
    }
    _rect(c, _hx(0x3a2a1a), -12, oy - 4, w + 24, 4);
    for (final ex in const [-12.0, w + 12]) {
      _oval(c, _hx(0xc99a5b), ex, oy - 15, 7, 15);
      c.drawOval(
          Rect.fromCenter(center: Offset(ex, oy - 15), width: 7, height: 16),
          _stroke(_hx(0x6e4d1a), 1.4));
    }
    // The clay-tile roof with a gable.
    const rl = -20.0, rr = w + 20, base = oy - 30;
    final roof = _polyPath([rl, base, cx, top - 4, rr, base]);
    c.drawPath(roof, _fill(_hx(0x8a3b2a)));
    c.save();
    c.clipPath(roof);
    var row = 0;
    for (var yy = base - 8; yy > top - 6; yy -= 9, row++) {
      final col = row.isOdd ? _hx(0xa6472f) : _hx(0x94402c);
      for (var xx = rl - (row.isOdd ? 7.0 : 0); xx < rr; xx += 14) {
        c.drawArc(Rect.fromCircle(center: Offset(xx + 7, yy), radius: 7.4), 0,
            pi, false, _fill(col));
      }
    }
    _poly(c, _hx(0x3b1b12), [cx - 46, base, cx, top + 22, cx + 46, base]);
    c.restore();
    final edge = Path()
      ..moveTo(rl, base)
      ..lineTo(cx, top - 4)
      ..lineTo(rr, base);
    c.drawPath(edge, _stroke(_hx(0x3b1b12), 3));
  }

  static void _brickBack(Canvas c) {
    const w = width, top = 0.0, ox = doorX, ow = doorWidth, oy = doorY;
    const gy = height, cx = centreX;
    // Two brick pillars with white stone corners and capitals.
    for (final px in const [0.0, w - 48]) {
      _blocks(c, px, top + 62, 48, gy - top - 62, _hx(0xb5573a),
          _rgba(240, 225, 200, .55), 20, 9, .2);
      _shade(c, px, top + 62, 48, gy - top - 62, .2, .34);
      for (var yy = gy - 18; yy > top + 66; yy -= 24) {
        _rect(c, _hx(0xefe9db), px, yy, 10, 12);
        _rect(c, _hx(0xefe9db), px + 38, yy, 10, 12);
      }
      _rect(c, _hx(0xefe9db), px - 5, top + 54, 58, 10);
      _rect(c, _hx(0xd8d0bd), px - 5, top + 62, 58, 3);
      _rect(c, _hx(0xefe9db), px - 4, gy - 12, 56, 12);
      _rect(c, _hx(0xd8d0bd), px - 4, gy - 12, 56, 2);
      // The lamp post: its base and pole. The globe is moving, see _brickLive.
      _rect(c, _hx(0xefe9db), px + 14, top + 40, 20, 14);
      _rect(c, _hx(0x2b2f36), px + 22, top + 26, 4, 14);
    }
    // The entablature with little teeth, then a pediment with stars.
    _rect(c, _hx(0xefe9db), -6, oy - 30, w + 12, 20);
    _rect(c, _hx(0xd8d0bd), -6, oy - 12, w + 12, 3);
    for (var xx = -2.0; xx < w; xx += 9) {
      _rect(c, _hx(0xc9c2b0), xx, oy - 22, 5, 7);
    }
    _poly(c, _hx(0xefe9db),
        [ox - 14, oy - 30, cx, oy - 78, ox + ow + 14, oy - 30]);
    _poly(
        c, _hx(0x7a2b22), [ox + 4, oy - 32, cx, oy - 70, ox + ow - 4, oy - 32]);
    for (final dx in const [-34.0, 34.0]) {
      c.drawPath(_star5(cx + dx, oy - 42, 6, 2.6), _fill(_hx(0xefe9db)));
    }
  }

  static void _brickLive(Canvas c, double t) {
    const w = width, top = 0.0;
    for (final px in const [0.0, w - 48]) {
      final gl = .75 + .25 * sin(t * 4 + px);
      _circle(c, _rgba(255, 230, 140, .25 * gl), px + 24, top + 20, 26);
      _circle(c, _rgba(255, 240, 170, gl), px + 24, top + 18, 11);
      c.drawCircle(Offset(px + 24, top + 18), 11, _stroke(_hx(0x2b2f36), 2));
      _rect(c, _hx(0x2b2f36), px + 20, top + 5, 8, 3);
    }
    // Bunting across the top, on a sagging wire.
    for (var i = 0; i <= 13; i++) {
      final u = i / 13;
      final bx = _lerp(24, w - 24, u), by = top + 22 + sin(u * pi) * 24;
      _poly(
          c,
          const [
            Color(0xFFB5333A),
            Color(0xFFEFE9DB),
            Color(0xFF2C4A8A)
          ][i % 3],
          [bx - 6, by, bx + 6, by, bx, by + 14 + sin(t * 3 + i) * 1.5]);
    }
    final wire = Path();
    for (var i = 0; i <= 20; i++) {
      final u = i / 20;
      final bx = _lerp(24, w - 24, u), by = top + 22 + sin(u * pi) * 24;
      i == 0 ? wire.moveTo(bx, by) : wire.lineTo(bx, by);
    }
    c.drawPath(wire, _stroke(_hx(0x2b2f36), 1.2));
  }

  static void _bags(Canvas c, double x, double y, double w2, double h2) {
    _rect(c, _hx(0x2f3a24), x, y, w2, h2);
    var r = 0;
    for (var yy = y + h2 - 16; yy > y - 6; yy -= 15, r++) {
      for (var xx = x - (r.isOdd ? 12.0 : 0); xx < x + w2; xx += 25) {
        final bx = max(x, xx), bw = min(x + w2, xx + 23) - bx;
        if (bw < 3) continue;
        final k = _rnd(r * 13 + xx);
        final rr = RRect.fromRectAndRadius(
            Rect.fromLTWH(bx, yy, bw, 14), const Radius.circular(6));
        c.drawRRect(rr, _fill(k > .5 ? _hx(0xb9a977) : _hx(0xa4965f)));
        if (bw > 6) _rect(c, _white(.16), bx + 3, yy + 2, bw - 6, 2);
        c.drawRRect(rr, _stroke(_hx(0x5c5434), 1));
      }
    }
  }

  static void _sandbagBack(Canvas c) {
    const w = width, top = 0.0, oy = doorY, gy = height;
    // Left: a watchtower on a sandbag base.
    _bags(c, 0, top + 96, 48, gy - top - 96);
    _rect(c, _hx(0x5a4630), 4, top + 38, 6, 60);
    _rect(c, _hx(0x5a4630), 38, top + 38, 6, 60);
    _rect(c, _hx(0x7a5a36), -8, top + 30, 64, 14);
    for (var xx = -6.0; xx < 54; xx += 9) {
      _rect(c, _black(.25), xx, top + 30, 1.4, 14);
    }
    _rect(c, _hx(0x4d3b26), -6, top + 4, 60, 28);
    _rect(c, _hx(0x10151a), 2, top + 12, 44, 10);
    _poly(c, _hx(0x7d878d), [-14, top + 8, 24, top - 10, 62, top + 8]);
    for (var xx = -8.0; xx < 60; xx += 7) {
      _line(c, _black(.3), 1.2, xx, top + 7, 24 + (xx - 24) * .4, top - 9);
    }
    // Right: a thick sandbag wall with barbed wire and a camouflage net.
    _bags(c, w - 48, top + 74, 48, gy - top - 74);
    final wireP = _stroke(_hx(0x2b2f36), 1.6);
    for (var i = 0; i < 6; i++) {
      c.drawCircle(Offset(w - 44 + i * 8.5, top + 66), 6, wireP);
    }
    final barbs = Path()..moveTo(w - 50, top + 60);
    for (var i = 0; i < 12; i++) {
      barbs.lineTo(w - 48 + i * 4.5, top + 60 + (i % 2) * 10);
    }
    c.drawPath(barbs, _stroke(_hx(0x2b2f36), 1.6));
    _poly(c, _rgba(74, 90, 52, .88),
        [54, top + 36, w - 44, top + 56, w - 44, top + 74, 70, top + 52]);
    for (var xx = 60.0; xx < w - 44; xx += 10) {
      _line(c, _rgba(30, 40, 20, .7), 1, xx, top + 38 + xx * .1, xx + 6,
          top + 70);
    }
    // The steel beam over the door, striped.
    _rect(c, _hx(0x4a545c), 40, oy - 34, w - 80, 30);
    _rect(c, _hx(0x2b3138), 40, oy - 34, w - 80, 4);
    c.save();
    c.clipRect(const Rect.fromLTWH(40, oy - 12, w - 80, 8));
    for (var xx = 28.0; xx < w - 30; xx += 16) {
      _poly(c, _hx(0xe8b72a),
          [xx, oy - 4, xx + 8, oy - 4, xx + 16, oy - 12, xx + 8, oy - 12]);
    }
    c.restore();
    for (var xx = 52.0; xx < w - 50; xx += 24) {
      _circle(c, _hx(0x8f9aa3), xx, oy - 24, 2.2);
    }
  }

  static void _searchlight(Canvas c, double t) {
    const top = 0.0;
    final sa = -.42 + sin(t * .9) * .3;
    c.save();
    c.translate(52, top + 20);
    c.rotate(sa);
    final beam = Path()
      ..moveTo(0, -3)
      ..lineTo(150, -26)
      ..lineTo(150, 26)
      ..lineTo(0, 3)
      ..close();
    c.drawPath(
      beam,
      Paint()
        ..isAntiAlias = true
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(150, 0),
          [_rgba(255, 248, 200, .34), _rgba(255, 248, 200, 0)],
        ),
    );
    _rect(c, _hx(0x20252a), -4, -7, 14, 14);
    _rect(c, _hx(0xfff2a8), 8, -5, 4, 10);
    c.restore();
  }

  static void _concreteBack(Canvas c) {
    const w = width, top = 0.0, gy = height, cx = centreX;
    const ringY = top + 112, r = 100.0;
    // The glass disc inside the ring.
    final disc = Path()
      ..moveTo(0, ringY)
      ..arcTo(Rect.fromCircle(center: const Offset(cx, ringY), radius: r), pi,
          pi, false)
      ..close();
    c.drawPath(
      disc,
      Paint()
        ..isAntiAlias = true
        ..shader = ui.Gradient.radial(
          const Offset(cx, ringY),
          r,
          [_rgba(60, 110, 170, .55), _rgba(15, 24, 48, .92)],
          const [.08, 1],
        ),
    );
    final grid = _rgba(127, 214, 255, .3);
    for (var k = 1; k <= 4; k++) {
      _arcTop(c, _stroke(grid, 1), cx, ringY, r * k / 5);
    }
    for (var i = 0; i < 6; i++) {
      final a = pi + (i + .5) * pi / 6;
      _line(c, grid, 1, cx, ringY, cx + cos(a) * r, ringY + sin(a) * r);
    }
    // The ring: concrete and a steel line.
    _arcTop(c, _stroke(_hx(0x8f96a8), 16), cx, ringY, r + 8);
    _arcTop(c, _stroke(_hx(0xd7dde8), 3), cx, ringY, r + 15);
    // Two concrete slabs with seams.
    for (final px in const [0.0, w - 48]) {
      _poly(c, _hx(0x7f8696),
          [px - 4, gy, px - 4, ringY, px + 52, ringY, px + 52, gy]);
      _shade(c, px - 4, ringY, 56, gy - ringY, .22, .36);
      for (var yy = ringY + 24; yy < gy; yy += 34) {
        _rect(c, _black(.22), px - 4, yy, 56, 1.6);
      }
      _rect(c, _black(.2), px + 24, ringY, 1.6, gy - ringY);
    }
    _rect(c, _hx(0xd7dde8), -8, gy - 8, w + 16, 8);
    _rect(c, _hx(0x9aa3b5), -8, gy - 3, w + 16, 3);
  }

  static void _concreteLive(Canvas c, double t, Color led) {
    const w = width, gy = height, cx = centreX, ringY = 112.0, r = 100.0;
    // Chevrons that climb the glass.
    for (var i = 0; i < 3; i++) {
      final u = (t * .5 + i / 3) % 1.0, yy = ringY - 20 - u * 60;
      final path = Path()
        ..moveTo(cx - 14, yy + 7)
        ..lineTo(cx, yy - 5)
        ..lineTo(cx + 14, yy + 7);
      c.drawPath(path, _stroke(_rgba(127, 214, 255, .7 * sin(u * pi)), 2));
    }
    // The LED line round the ring, with a glow.
    final glow = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..color = led
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    _arcTop(c, glow, cx, ringY, r);
    _arcTop(c, _stroke(led, 3.4), cx, ringY, r);
    // And a cyan strip on each slab.
    for (var j = 0; j < 2; j++) {
      final px = j == 0 ? 0.0 : w - 48;
      final x = px + (j == 1 ? 6 : 38), y = ringY + 12, h = gy - ringY - 34;
      c.drawRect(
          Rect.fromLTWH(x, y, 4, h),
          Paint()
            ..color = led
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      _rect(c, _hx(0x7fd6ff), x, y, 4, h);
    }
  }

  // ─────────────────────────────── layer 3: the door panel ─────────────────

  /// The door itself, drawn at the opening and lifted by the caller.
  static void paintPanel(Canvas c, GateKind k) {
    const x = doorX, y = doorY, w = doorWidth, h = doorHeight + 6;
    switch (k) {
      case GateKind.bamboo:
        var i = 0;
        for (var xx = x; xx < x + w; xx += 9, i++) {
          _rect(c, i.isOdd ? _hx(0x9fc25a) : _hx(0x86a947), xx, y, 8, h);
          for (var yy = y + 12; yy < y + h; yy += 28) {
            _rect(c, _hx(0x4d6b24), xx, yy, 8, 2);
          }
          _rect(c, _white(.25), xx + 1, y, 1.6, h);
        }
        for (final yy in [y + 26, y + h * .5, y + h - 26]) {
          _rect(c, _hx(0xb9873a), x, yy, w, 6);
          _rect(c, _hx(0x6e4d1a), x, yy + 5, w, 1.4);
        }
      case GateKind.stone:
        _rect(c, _hx(0x6a4a2c), x, y, w, h);
        for (var xx = x + 13; xx < x + w; xx += 13) {
          _rect(c, _hx(0x4b331e), xx, y, 1.6, h);
          _rect(c, _white(.08), xx + 2, y, 1.4, h);
        }
        for (final yy in [y + 30, y + h * .5, y + h - 30]) {
          _rect(c, _hx(0x2b2d33), x, yy, w, 6);
        }
        for (var xx = x + 8; xx < x + w; xx += 16) {
          for (final yy in [y + 14, y + h * .5 + 14, y + h - 16]) {
            _circle(c, _hx(0xc9c2b0), xx, yy, 2.2);
          }
        }
        _rect(c, _hx(0xc9c2b0), x + w / 2 - 1.5, y, 3, h);
        final ring = _stroke(_hx(0x2b2d33), 3);
        c.drawCircle(const Offset(x + w / 2 - 10, y + h * .62), 6, ring);
        c.drawCircle(const Offset(x + w / 2 + 10, y + h * .62), 6, ring);
      case GateKind.wood:
        var i = 0;
        for (var xx = x; xx < x + w; xx += 13, i++) {
          _rect(c, i.isOdd ? _hx(0x8a5a2e) : _hx(0x744a24), xx, y, 12, h);
          _rect(c, _black(.2), xx + 5, y, 1.2, h);
        }
        _rect(c, _hx(0x3a2812), x, y + h * .22, w, 7);
        _rect(c, _hx(0x3a2812), x, y + h * .72, w, 7);
        _line(c, _hx(0x3a2812), 7, x, y + h * .22, x + w, y + h * .75);
        for (final yy in [y + h * .22 + 3, y + h * .72 + 3]) {
          for (final xx in [x + 7, x + w - 7]) {
            _circle(c, _hx(0x9aa3b0), xx, yy, 3);
          }
        }
      case GateKind.brick:
        _rect(c, _hx(0x16191f), x, y, w, h);
        for (var xx = x + 3; xx < x + w; xx += 10) {
          _rect(c, _hx(0x2b2f36), xx, y, 3.4, h);
          _poly(c, _hx(0x2b2f36),
              [xx - 1, y + h, xx + 4.4, y + h, xx + 1.7, y + h + 6]);
          _circle(c, _hx(0xe8b72a), xx + 1.7, y + 3, 2.6);
        }
        for (final yy in [y + 16, y + h * .5, y + h - 14]) {
          _rect(c, _hx(0x2b2f36), x, yy, w, 3.6);
        }
        final scroll = _stroke(_hx(0x2b2f36), 2.4);
        for (var j = 0; j < 4; j++) {
          final sx = x + 13 + j * 26;
          c.drawArc(
              Rect.fromCircle(center: Offset(sx, y + h * .5 - 9), radius: 8),
              0,
              pi * 1.7,
              false,
              scroll);
          c.drawArc(
              Rect.fromCircle(center: Offset(sx, y + h * .5 + 9), radius: 8),
              pi,
              pi * 1.7,
              false,
              scroll);
        }
        _circle(c, _hx(0xe8b72a), x + w / 2, y + h * .5, 8);
        c.drawPath(_star5(x + w / 2, y + h * .5, 5, 2.2), _fill(_hx(0x16191f)));
      case GateKind.sandbag:
        _rect(c, _hx(0x59636c), x, y, w, h);
        _shade(c, x, y, w, h, .2, .3);
        for (var yy = y + 24; yy < y + h; yy += 32) {
          _rect(c, _hx(0x3b4249), x, yy, w, 4);
          _rect(c, _white(.12), x, yy + 4, w, 1.4);
        }
        for (var xx = x - 8; xx < x + w; xx += 18) {
          _poly(c, _hx(0xe8b72a), [
            xx,
            y + h,
            xx + 9,
            y + h,
            xx + 18,
            y + h - 12,
            xx + 9,
            y + h - 12
          ]);
        }
        for (var yy = y + 10; yy < y + h - 16; yy += 32) {
          for (final xx in [x + 8, x + w - 8]) {
            _circle(c, _hx(0x2b3138), xx, yy, 2.4);
          }
        }
      case GateKind.concrete:
        c.drawRect(
          const Rect.fromLTWH(x, y, w, h),
          Paint()
            ..shader = ui.Gradient.linear(
              const Offset(x, y),
              const Offset(x + w, y + h),
              [
                _rgba(170, 222, 255, .85),
                _rgba(110, 170, 230, .75),
                _rgba(170, 222, 255, .85)
              ],
              const [0, .5, 1],
            ),
        );
        for (var xx = x; xx <= x + w + 1; xx += w / 3) {
          _rect(c, _hx(0xd7dde8), xx - 1.5, y, 3.4, h);
        }
        for (var yy = y + 30; yy < y + h; yy += 44) {
          _rect(c, _hx(0xd7dde8), x, yy, w, 3);
        }
        _rect(c, _white(.4), x + 8, y + 8, 7, h - 16);
        _rect(c, _white(.4), x + w / 2 + 8, y + 14, 5, h - 40);
    }
  }

  // ─────────────────────────────── layer 4: front ──────────────────────────

  static void paintFront(Canvas c, GateKind k) {
    switch (k) {
      case GateKind.bamboo:
        _bambooFront(c);
      case GateKind.stone:
        _stoneFront(c);
      case GateKind.wood:
        _woodFront(c);
      case GateKind.brick:
        c.drawRect(
            const Rect.fromLTWH(
                doorX - 2.5, doorY - 2.5, doorWidth + 5, doorHeight + 3),
            _stroke(_hx(0xefe9db), 5));
      case GateKind.sandbag:
        _sandbagFront(c);
      case GateKind.concrete:
        final p = Path()
          ..moveTo(doorX, height)
          ..lineTo(doorX, doorY + doorWidth / 2)
          ..arcTo(
              Rect.fromCircle(
                  center: const Offset(centreX, doorY + doorWidth / 2),
                  radius: doorWidth / 2),
              pi,
              pi,
              false)
          ..lineTo(doorX + doorWidth, height);
        c.drawPath(p, _stroke(_rgba(215, 221, 232, .9), 4));
    }
  }

  static void paintFrontLive(Canvas c, GateKind k, double t) {
    switch (k) {
      case GateKind.bamboo:
        for (final tx in const [-16.0, width + 16]) {
          _flame(c, tx, height - 90, t);
        }
      case GateKind.stone:
        _stoneLanterns(c, t);
      case GateKind.wood:
        _woodLive(c, t);
      case GateKind.brick:
      case GateKind.sandbag:
      case GateKind.concrete:
        break;
    }
  }

  static void _flame(Canvas c, double x, double y, double t) {
    final fl = 1 + .13 * sin(t * 9 + x), r = 18 * fl;
    _circle(c, _rgba(255, 138, 42, .18), x, y - 12, r);
    final tipX = x + 1.2 * sin(t * 5 + x), tipY = y - 17 * fl;
    final path = Path()
      ..moveTo(tipX, tipY)
      ..quadraticBezierTo(x + 7, y - 6, x + 5, y - 2)
      ..lineTo(x - 5, y - 2)
      ..quadraticBezierTo(x - 7, y - 6, tipX, tipY)
      ..close();
    c.drawPath(path, _fill(_hx(0xff8a2a)));
    _oval(c, _hx(0xffe27a), x, y - 5, 2.6, 5.5 * fl);
  }

  static void _bambooFront(Canvas c) {
    const ox = doorX, ow = doorWidth, oy = doorY, cx = centreX;
    // The woven cloth over the door.
    const px = ox, py = oy - 2, pw = ow, ph = 26.0;
    _rect(c, _hx(0x2b1d12), px, py, pw, ph);
    c.save();
    c.clipRect(const Rect.fromLTWH(px, py, pw, ph));
    for (var row = 0; row < 3; row++) {
      for (var i = -1; i < 9; i++) {
        final dx = px + i * 13 + (row.isOdd ? 6.5 : 0), dy = py + 5 + row * 8;
        _poly(c, row.isOdd ? _hx(0xe8b72a) : _hx(0xc0392b),
            [dx, dy - 5, dx + 6, dy, dx, dy + 5, dx - 6, dy]);
      }
    }
    _rect(c, _hx(0xe8b72a), px, py, pw, 3);
    _rect(c, _hx(0xe8b72a), px, py + ph - 3, pw, 3);
    c.restore();
    c.drawRect(const Rect.fromLTWH(px, py, pw, ph), _stroke(_hx(0x6e4d1a), 2));
    // The emblem the lamp sits on.
    _circle(c, _hx(0x5b3a18), cx, oy - 53, 17);
    c.drawCircle(const Offset(cx, oy - 53), 17, _stroke(_hx(0xe8b72a), 2));
    // The torch poles (the flames move, see paintFrontLive).
    for (final tx in const [-16.0, width + 16]) {
      _rect(c, _hx(0x7a5a2a), tx - 2.5, height - 84, 5, 84);
      _rect(c, _hx(0x4a3418), tx - 6, height - 90, 12, 7);
    }
  }

  static void _stoneFront(Canvas c) {
    const ow = doorWidth, oy = doorY, cx = centreX;
    const r = ow / 2, ccy = oy + r;
    // The arch ring of voussoirs and a keystone.
    _arcTop(c, _stroke(_hx(0xddd2b9), 14), cx, ccy, r + 7);
    final seam = _rgba(60, 52, 44, .7);
    for (var i = 0; i <= 14; i++) {
      final a = pi + i * pi / 14;
      _line(c, seam, 1.3, cx + cos(a) * r, ccy + sin(a) * r,
          cx + cos(a) * (r + 14), ccy + sin(a) * (r + 14));
    }
    _poly(c, _hx(0xeee4cc),
        [cx - 8, oy - 15, cx + 8, oy - 15, cx + 6, oy + 2, cx - 6, oy + 2]);
    // The coat of arms: a shield. The lamp sits on it.
    const sy = oy - 52;
    final shield = Path()
      ..moveTo(cx - 20, sy - 18)
      ..lineTo(cx + 20, sy - 18)
      ..lineTo(cx + 20, sy + 4)
      ..quadraticBezierTo(cx + 18, sy + 20, cx, sy + 26)
      ..quadraticBezierTo(cx - 18, sy + 20, cx - 20, sy + 4)
      ..close();
    c.drawPath(shield, _fill(_hx(0xa3262a)));
    c.drawPath(shield, _stroke(_hx(0xe6c46a), 2.4));
  }

  static void _stoneLanterns(Canvas c, double t) {
    const ox = doorX, ow = doorWidth, oy = doorY;
    for (var j = 0; j < 2; j++) {
      final lx = j == 0 ? ox - 18 : ox + ow + 18;
      final bracket = Path()
        ..moveTo(lx + (j == 1 ? 10 : -10), oy + 4)
        ..lineTo(lx, oy + 4)
        ..lineTo(lx, oy + 10);
      c.drawPath(bracket, _stroke(_hx(0x2b2d33), 2.5));
      final fl = .7 + .3 * sin(t * 7 + lx);
      _circle(c, _rgba(255, 200, 90, .22 * fl), lx, oy + 26, 24);
      _rect(c, _hx(0x2b2d33), lx - 8, oy + 10, 16, 4);
      _poly(c, _hx(0x2b2d33), [lx - 9, oy + 10, lx, oy + 2, lx + 9, oy + 10]);
      _rect(c, _hx(0x2b2d33), lx - 7, oy + 38, 14, 4);
      _rect(c, _rgba(255, 214, 110, .7 + .3 * fl), lx - 6, oy + 14, 12, 24);
      _rect(c, _hx(0x2b2d33), lx - 1, oy + 14, 2, 24);
    }
  }

  static void _woodFront(Canvas c) {
    const oy = doorY, cx = centreX;
    // Two crossed bolos over the door.
    for (final a in const [-1.0, 1.0]) {
      final blade = Path()
        ..moveTo(cx - 24 * a, oy - 26)
        ..quadraticBezierTo(cx, oy - 18 - 4 * a, cx + 24 * a, oy - 6);
      c.drawPath(blade, _stroke(_hx(0xd6dde6), 4, cap: StrokeCap.round));
      _line(c, _hx(0x5b3a18), 6, cx + 24 * a, oy - 6, cx + 34 * a, oy - 2,
          cap: StrokeCap.round);
    }
  }

  static void _woodLive(Canvas c, double t) {
    const w = width, oy = doorY;
    // Red banners with a white sun hang in front of the posts.
    for (var j = 0; j < 2; j++) {
      final bx = j == 0 ? 8.0 : w - 40;
      final sw = sin(t * 2.5 + j * 2) * 3;
      _poly(c, _hx(0xb3262d), [
        bx,
        oy - 2,
        bx + 32,
        oy - 2,
        bx + 32 + sw,
        oy + 78,
        bx + 16 + sw,
        oy + 66,
        bx + sw,
        oy + 78
      ]);
      _rect(c, _white(.12), bx, oy - 2, 6, 78);
      _sunDisc(c, bx + 16 + sw * .4, oy + 30, 7, 8, Colors.white, 0);
    }
    // Parol lanterns at the eaves.
    for (var j = 0; j < 2; j++) {
      final px = j == 0 ? -8.0 : w + 8;
      final p = .6 + .4 * sin(t * 3 + j * 2);
      _line(c, _hx(0x3a2a1a), 1.2, px, oy - 30, px, oy - 16);
      _circle(c, _rgba(255, 200, 90, .25 * p), px, oy - 4, 22);
      c.drawPath(_star5(px, oy - 4, 13, 6),
          _fill(j == 1 ? _hx(0xe8463c) : _hx(0xffd24a)));
      _circle(c, Colors.white, px, oy - 4, 3);
      final tails = Path()
        ..moveTo(px, oy + 8)
        ..lineTo(px - 3, oy + 20)
        ..moveTo(px, oy + 8)
        ..lineTo(px + 3, oy + 20);
      c.drawPath(tails, _stroke(j == 1 ? _hx(0xffd24a) : _hx(0xe8463c), 2));
    }
  }

  static void _sandbagFront(Canvas c) {
    const w = width, top = 0.0;
    // A stencilled sign on the right wall.
    _rect(c, _hx(0xd9d4c2), w - 42, top + 104, 36, 22);
    c.drawRect(const Rect.fromLTWH(w - 42, top + 104, 36, 22),
        _stroke(_hx(0x2b3138), 1.6));
    final tp = _haltText ??= _label('HALT', 11, _hx(0xb3262d));
    _paintText(c, tp, w - 24, top + 119);
  }

  // ─────────────────────── lamp, step-in guide, specks, dust ───────────────

  /// The lamp (the old wax seal): red while artifacts remain, gold when they
  /// are all answered (with an open padlock), and a gold tick once the door is up.
  static void paintLamp(
      Canvas c, Offset at, bool unlocked, double open, double t) {
    final cx = at.dx, cy = at.dy;
    final pulse = .5 + .5 * sin(t * (unlocked ? 4 : 2));
    if (unlocked && open < .5) {
      _circle(c, _rgba(230, 196, 106, .2 + .25 * pulse), cx, cy, 16);
    }
    c.drawCircle(
      Offset(cx, cy),
      10.5,
      Paint()
        ..isAntiAlias = true
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          12,
          unlocked
              ? [_hx(0xfff3c2), _hx(0xd9b04f)]
              : [_hx(0xd8584f), _hx(0x8a2018)],
          null,
          TileMode.clamp,
          null,
          Offset(cx - 3, cy - 3),
          1,
        ),
    );
    c.drawCircle(Offset(cx, cy), 10.5,
        _stroke(unlocked ? _hx(0x6b4f16) : _hx(0x4a100c), 1.4));
    final ink = unlocked ? _hx(0x2b1d07) : _hx(0xffe9d0);
    if (open >= .5) {
      final tick = Path()
        ..moveTo(cx - 5, cy + .5)
        ..lineTo(cx - 1.6, cy + 4)
        ..lineTo(cx + 5, cy - 4.5);
      c.drawPath(tick, _stroke(_hx(0x2b1d07), 2.2));
      return;
    }
    _rect(c, ink, cx - 5, cy - 1, 10, 7.5);
    final shackle = Path()
      ..moveTo(cx - 3, cy - 1)
      ..lineTo(cx - 3, cy - 4)
      ..arcTo(
          Rect.fromCircle(center: Offset(cx, cy - 4), radius: 3), pi, pi, false)
      ..lineTo(cx + 3, unlocked ? cy - 6.4 : cy - 1);
    c.drawPath(shackle, _stroke(ink, 1.7));
  }

  /// With the door up: a glowing mat on the ground in the doorway, three
  /// arrows to its left pointing at it, and the word PASOK in the doorway.
  static void paintGuide(Canvas c, double t) {
    final p = .5 + .5 * sin(t * 5);
    const gy = height;
    final mat = RRect.fromRectAndRadius(
        const Rect.fromLTWH(doorX + 4, gy - 3, doorWidth - 8, 9),
        const Radius.circular(3));
    c.drawRRect(
      mat,
      Paint()
        ..isAntiAlias = true
        ..shader = ui.Gradient.linear(
          const Offset(0, gy - 4),
          const Offset(0, gy + 6),
          [_rgba(255, 224, 138, .6 + .35 * p), _rgba(255, 200, 80, .15)],
        ),
    );
    final arrowColor = _rgba(255, 224, 138, .35 + .5 * p);
    for (var i = 0; i < 3; i++) {
      final ax = -46.0 + i * 12 + p * 6, ay = gy - 18;
      _poly(c, arrowColor, [ax, ay - 9, ax + 10, ay, ax, ay + 9, ax + 3, ay]);
    }
    final tp = _pasokText ??= _label('PASOK', 12, Colors.white);
    final box = Rect.fromLTWH(centreX - tp.width / 2 - 2, gy - 112 - tp.height,
        tp.width + 4, tp.height + 6);
    c.saveLayer(
        box,
        _tint
          ..colorFilter = ColorFilter.mode(
              _rgba(255, 236, 170, .7 + .3 * p), BlendMode.srcIn));
    _paintText(c, tp, centreX, gy - 112);
    c.restore();
  }

  /// Specks drifting up past the gate.
  static void paintSpecks(Canvas c, GateKind k, double t) {
    final col = motes(k);
    for (var i = 0; i < 12; i++) {
      final sd = _rnd(i + 5.0), f = (t * (.05 + .05 * sd) + sd) % 1.0;
      _rect(
          c,
          col.withValues(alpha: .55 * sin(f * pi)),
          -40 + _rnd(i * 1.0) * (width + 80) + sin(t + i) * 6,
          height - 8 - f * 190,
          2,
          2);
    }
  }

  /// Specks shaken loose from the lintel while the door moves.
  static void paintDust(Canvas c, double t, double open) {
    if (open <= 0 || open >= 1) return;
    final st = sin(pi * open);
    for (var i = 0; i < 14; i++) {
      final sd = (i * .618) % 1.0, f = (t * (.7 + .5 * sd) + sd * 3) % 1.0;
      _rect(c, _rgba(235, 225, 210, .75 * st * (1 - f)),
          28 + (width - 56) * ((i * .37 + sd) % 1.0), 60 + f * 110, 3, 3);
    }
  }
}
