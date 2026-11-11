import 'dart:math';
import 'dart:ui';

/// The drawings of the surprises that are made in code (the "!" bubble, the
/// dizzy stars, the crack, the rock, the thrown coin, shell and money bundle, the
/// rings). Ported from the approved mockup. Every function draws from a time given
/// to it, never from a clock, so every frame is the same picture for the same time.
///
/// Coordinates: the caller has moved the canvas so that the ground is at y = 0 and
/// things above the ground have negative y.
class SurpriseArt {
  SurpriseArt._();

  static const double tau = 2 * pi;
  static final Paint _p = Paint();

  /// The same pseudo-random number for the same [i], so debris falls the same way
  /// every frame.
  static double rnd(int i) {
    final s = sin(i * 127.1 + 3.7) * 43758.5453;
    return s - s.floorToDouble();
  }

  static double clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
  static double ease(double p) => 1 - (1 - p) * (1 - p);

  static Paint _fill(Color c) => _p
    ..style = PaintingStyle.fill
    ..strokeWidth = 1
    ..color = c;

  static Paint _stroke(Color c, double w) => _p
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..color = c;

  // ─── Warnings ──────────────────────────────────────────────────────────
  /// The yellow "!" bubble, bouncing, centred at [x] with its middle 16 above [top].
  static void bang(Canvas c, double x, double top, double t) {
    final bounce = sin(t * 14).abs() * 4;
    final cy = top - 16 - bounce;
    c.drawCircle(Offset(x, cy), 14, _fill(const Color(0xFFFFC83D)));
    c.drawCircle(Offset(x, cy), 14, _stroke(const Color(0xFF3A2A00), 2));
    final ink = _fill(const Color(0xFF3A2A00));
    c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x - 2.2, cy - 8, 4.4, 10.5),
            const Radius.circular(2)),
        ink);
    c.drawCircle(Offset(x, cy + 6.5), 2.4, ink);
  }

  /// An eight-pointed star.
  static void star(Canvas c, double x, double y, double r, double alpha) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final rr = i.isOdd ? r * 0.28 : r;
      final an = i * pi / 4;
      final px = x + cos(an) * rr, py = y + sin(an) * rr;
      i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
    }
    path.close();
    c.drawPath(
        path, _fill(const Color(0xFFFFF3B0).withValues(alpha: clamp01(alpha))));
  }

  /// Three stars circling above a dizzy head: [cx] its middle, [headY] the top of it.
  static void dizzyStars(Canvas c, double cx, double headY, double t) {
    for (var i = 0; i < 3; i++) {
      final a = t * 4 + i * 2.09;
      star(c, cx + cos(a) * 28, headY - 6 + sin(a) * 6, 6, 1);
    }
  }

  /// A soft golden glow behind a body centred at ([cx], [cy]).
  static void glow(Canvas c, double cx, double cy) {
    final shader = Gradient.radial(Offset(cx, cy), 90, [
      const Color(0x8CFFD65A),
      const Color(0x00FFD65A),
    ]);
    c.drawCircle(Offset(cx, cy), 90, Paint()..shader = shader);
  }

  /// Four sparkles twinkling round a golden body.
  static void sparkles(Canvas c, double cx, double cy, double t) {
    for (var i = 0; i < 4; i++) {
      final ph = (t * 1.6 + i * 0.25) % 1;
      star(c, cx + (rnd(i + 3) - 0.5) * 70, cy + (rnd(i + 8) - 0.5) * 80,
          7 * sin(ph * pi), 1);
    }
  }

  /// Three sweat drops sliding down beside a head (it is out of breath).
  static void sweat(Canvas c, double x, double headY, double t) {
    for (var i = 0; i < 3; i++) {
      final ph = (t * 1.3 + i / 3) % 1;
      c.drawOval(
          Rect.fromCenter(
              center: Offset(x + 26 + i * 4, headY + 10 + ph * 34),
              width: 6,
              height: 10),
          _fill(const Color(0xFF8CC8FF).withValues(alpha: 1 - ph)));
    }
  }

  // ─── On the ground ─────────────────────────────────────────────────────
  /// A red ring lying on the ground, centred at ([x], 3): where something will land.
  static void ring(
      Canvas c, double x, double rx, double alpha, double fillAlpha) {
    final oval =
        Rect.fromCenter(center: Offset(x, 3), width: rx * 2, height: rx * 0.44);
    c.drawOval(oval,
        _fill(const Color(0xFFFF6B5E).withValues(alpha: clamp01(fillAlpha))));
    c.drawOval(oval,
        _stroke(const Color(0xFFFF6B5E).withValues(alpha: clamp01(alpha)), 3));
  }

  /// The falling rock's shadow, growing: [p] is 0 to 1 over the warning.
  static void rockShadow(
      Canvas c, double x, double radius, double p, double alpha) {
    final rx = 8 + (radius - 8) * p;
    final oval = Rect.fromCenter(
        center: Offset(x, 3), width: rx * 2, height: (2.5 + 9 * p) * 2);
    c.drawOval(oval, _fill(Color.fromRGBO(8, 6, 14, (0.2 + 0.4 * p) * alpha)));
    c.drawOval(
        oval,
        _stroke(
            const Color(0xFFFF6B5E).withValues(alpha: (0.35 + 0.4 * p) * alpha),
            2.5));
  }

  /// The crack a ground pop opens, [cp] 0 to 1 as it opens, [fade] 1 to 0 as it goes.
  static void crack(Canvas c, double x, double cp, double fade) {
    if (fade <= 0 || cp <= 0) return;
    final glowShader = Gradient.radial(Offset(x, 4), 70, [
      Color.fromRGBO(190, 100, 255, 0.6 * fade),
      const Color(0x00BE64FF),
    ]);
    c.drawRect(
        Rect.fromLTWH(x - 80, -60, 160, 120), Paint()..shader = glowShader);
    final oval =
        Rect.fromCenter(center: Offset(x, 4), width: 76 * cp, height: 10);
    c.drawOval(oval, _fill(const Color(0xFF17101F).withValues(alpha: fade)));
    c.drawOval(
        oval, _stroke(const Color(0xFFC47CFF).withValues(alpha: fade), 2));
    final path = Path();
    const lines = [
      [-30.0, 16.0, -22.0, 26.0, -26.0, 36.0],
      [-6.0, 14.0, 4.0, 26.0, -2.0, 38.0],
      [24.0, 16.0, 18.0, 28.0, 30.0, 36.0],
    ];
    for (final l in lines) {
      path.moveTo(x + l[0] * cp, 8);
      path.lineTo(x + l[2] * cp, l[3] + 2);
      path.lineTo(x + l[4] * cp, l[5] + 4);
    }
    c.drawPath(
        path, _stroke(const Color(0xFF2A1A38).withValues(alpha: fade), 2.5));
  }

  /// Bits of earth and dark smoke thrown up while an enemy rises, [d] seconds in.
  static void riseDebris(Canvas c, double x, double d) {
    if (d < 0) return;
    const cols = [Color(0xFF2A1A38), Color(0xFF4A3320), Color(0xFF7A5A3A)];
    for (var i = 0; i < 8; i++) {
      final vx = (rnd(i + 2) - 0.5) * 240, vy = -(90 + rnd(i + 9) * 110);
      final yy = vy * d + 520 * d * d;
      if (yy > 2) continue;
      c.drawRect(
          Rect.fromLTWH(x + vx * d - 5, yy - 5, 10, 10), _fill(cols[i % 3]));
    }
  }

  // ─── The rock ──────────────────────────────────────────────────────────
  static const List<String> _rockMap = [
    '....oooooo....',
    '..ooLLLLLLoo..',
    '.oLLLLLLmmLLo.',
    'oLLLLLLmmmmmmo',
    'oLLLLmmmmmmmDo',
    'oLLLmmcmmmmDDo',
    'oLLmmmcmmmDDDo',
    'oLmmmmmcmmDDDo',
    'oLmmmmmmcDDDDo',
    '.ommmmmmDDDDDo',
    '.oommmDDDDDDo.',
    '..oooDDDDDDoo.',
    '....oooooooo..',
  ];
  static const Map<String, Color> _rockColors = {
    'o': Color(0xFF2A2433),
    'L': Color(0xFFCDC6DA),
    'm': Color(0xFF9A93A8),
    'D': Color(0xFF6D6680),
    'c': Color(0xFF3B3447),
  };
  static const int rockCols = 14;
  static const int rockRows = 13;

  static final Map<String, Path> _rockPaths = () {
    final out = <String, Path>{};
    for (var j = 0; j < _rockMap.length; j++) {
      for (var i = 0; i < _rockMap[j].length; i++) {
        final ch = _rockMap[j][i];
        if (!_rockColors.containsKey(ch)) continue;
        (out[ch] ??= Path())
            .addRect(Rect.fromLTWH(i.toDouble(), j.toDouble(), 1, 1));
      }
    }
    return out;
  }();

  /// How many pixel cells of the rock picture are painted (for tests).
  static int get rockCellCount => [
        for (final row in _rockMap)
          for (final ch in row.split(''))
            if (_rockColors.containsKey(ch)) 1
      ].length;

  /// The rock, 56 wide and 52 high, centred at ([x], [y]), turned by [rot].
  static void rock(Canvas c, double x, double y, double rot, [double sc = 1]) {
    c.save();
    c.translate(x, y);
    c.rotate(rot);
    c.scale(sc * 56 / rockCols, sc * 52 / rockRows);
    c.translate(-rockCols / 2, -rockRows / 2);
    _rockPaths.forEach((ch, path) {
      c.drawPath(
          path,
          Paint()
            ..isAntiAlias = false
            ..color = _rockColors[ch]!);
    });
    c.restore();
  }

  /// Nine pieces of a broken rock: they fly out from ([x], [y0]), bounce once and
  /// fade. [d] is the seconds since it broke.
  static void rockPieces(Canvas c, double x, double y0, double d, double life) {
    if (d < 0 || d > life) return;
    const cols = [
      Color(0xFF2A2433),
      Color(0xFF9A93A8),
      Color(0xFF6D6680),
      Color(0xFFCDC6DA)
    ];
    for (var i = 0; i < 9; i++) {
      final vx = (rnd(i + 5) - 0.5) * 260, vy = -(120 + rnd(i + 17) * 150);
      final sz = 9 + rnd(i + 31) * 10;
      final yg = -sz / 2;
      final disc = vy * vy - 2240 * (y0 - yg);
      final d1 = disc <= 0 ? 0.0 : (-vy + sqrt(disc)) / 1120;
      double px, py;
      if (d < d1) {
        py = y0 + vy * d + 560 * d * d;
        px = x + vx * d;
      } else {
        final dd = d - d1;
        py = yg - sin(dd * 9).abs() * 14 * max(0.0, 1 - dd * 2.2);
        px = x + vx * d1 + vx * dd * 0.2;
      }
      final alpha = d > life - 0.4 ? clamp01((life - d) / 0.4) : 1.0;
      c.save();
      c.translate(px, py);
      c.rotate(d * (4 + i) * (i.isOdd ? 1 : -1));
      final r = Rect.fromLTWH(-sz / 2, -sz / 2, sz, sz);
      c.drawRect(r, _fill(cols[i % 4].withValues(alpha: alpha)));
      c.drawRect(
          r, _stroke(const Color(0xFF2A2433).withValues(alpha: alpha), 1.5));
      c.restore();
    }
  }

  /// Dust puffs low on the ground at ([x], 0), [d] seconds after a landing.
  static void dust(Canvas c, double x, double d) {
    if (d < 0 || d > 0.7) return;
    for (var i = 0; i < 6; i++) {
      final dir = i < 3 ? -1 : 1, k = i % 3;
      c.drawCircle(
          Offset(x + dir * (14 + k * 14 + d * 90), -6 - k * 3 - d * 14),
          8 + k * 3 + d * 10,
          _fill(Color.fromRGBO(214, 196, 160, 0.5 * (1 - d / 0.7))));
    }
  }

  /// A white shock ring along the ground just after something lands.
  static void shockRing(Canvas c, double x, double d) {
    if (d < 0 || d >= 0.3) return;
    final r = 20 + d * 150;
    c.drawOval(
        Rect.fromCenter(center: Offset(x, 0), width: r * 2, height: r * 0.4),
        _stroke(Color.fromRGBO(255, 255, 255, 0.7 * (1 - d / 0.3)), 3));
  }

  // ─── Thrown things ─────────────────────────────────────────────────────
  /// A flat gold coin turning on its edge.
  static void coin(
      Canvas c, double x, double y, double spin, double alpha, double size) {
    final w = max(0.2, cos(spin).abs()) * size;
    final r = Rect.fromCenter(center: Offset(x, y), width: w, height: size);
    c.drawOval(r, _fill(const Color(0xFFFFC83D).withValues(alpha: alpha)));
    c.drawOval(r, _stroke(const Color(0xFF8A5A00).withValues(alpha: alpha), 2));
    c.drawOval(r.deflate(size * 0.22),
        _stroke(const Color(0xFFFFF0A8).withValues(alpha: alpha), 2));
  }

  /// A tank shell, nose to the right, turned by [angle].
  static void shell(Canvas c, double x, double y, double angle, double alpha) {
    c.save();
    c.translate(x, y);
    c.rotate(angle);
    final body = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-16, -7, 24, 14), const Radius.circular(3));
    c.drawRRect(body, _fill(const Color(0xFF8D9A6B).withValues(alpha: alpha)));
    final nose = Path()
      ..moveTo(8, -7)
      ..lineTo(20, 0)
      ..lineTo(8, 7)
      ..close();
    c.drawPath(nose, _fill(const Color(0xFF4A5238).withValues(alpha: alpha)));
    c.drawRect(const Rect.fromLTWH(-12, -7, 3, 14),
        _fill(const Color(0xFFD9B44A).withValues(alpha: alpha)));
    c.drawRRect(
        body, _stroke(const Color(0xFF2A2F1C).withValues(alpha: alpha), 2));
    c.restore();
  }

  /// A bundle of banknotes tied with a band, turned by [rot].
  static void bundle(Canvas c, double x, double y, double rot, double alpha) {
    c.save();
    c.translate(x, y);
    c.rotate(rot);
    const r = Rect.fromLTWH(-16, -10, 32, 20);
    c.drawRect(r, _fill(const Color(0xFF4F9A5A).withValues(alpha: alpha)));
    c.drawRect(const Rect.fromLTWH(-4, -10, 8, 20),
        _fill(const Color(0xFFEDE6C4).withValues(alpha: alpha)));
    c.drawRect(const Rect.fromLTWH(-16, -6, 32, 2),
        _fill(const Color(0xFF2F6B3A).withValues(alpha: alpha)));
    c.drawRect(r, _stroke(const Color(0xFF1F3F26).withValues(alpha: alpha), 2));
    c.restore();
  }

  /// A small burst where a thrown thing lands ([d] seconds after), in [color].
  static void landingPuff(Canvas c, double x, double d, Color color) {
    if (d < 0 || d > 0.45) return;
    final p = d / 0.45;
    for (var i = 0; i < 7; i++) {
      final a = -pi + (i / 6) * pi;
      c.drawCircle(
          Offset(x + cos(a) * (14 + p * 46), -8 + sin(a) * (10 + p * 34)),
          5 * (1 - p) + 1.5,
          _fill(color.withValues(alpha: 1 - p)));
    }
  }
}
