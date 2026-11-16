import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart'
    show
        Alignment,
        FontWeight,
        LinearGradient,
        RadialGradient,
        TextDirection,
        TextPainter,
        TextSpan,
        TextStyle;

import 'cave_look.dart';

// The painters of the six era caves. Everything is drawn in code, in game units.
//
// Three kinds of drawing, each with its own origin:
//  * the screen layers ([CaveEraArt.wall]): origin is the screen, but y is in "mockup
//    units" where the floor line is [kMockGround] (282), so the painters read like
//    the pictures they were designed from; the backdrop shifts the canvas so that
//    line lands on the real floor and draws everything that has to reach the ceiling
//    from [kReach] (far above) down;
//  * the ceiling ([CaveEraArt.ceil]): origin is the top of the screen, the rock
//    hangs from y = 36 and things hang from that;
//  * the floor, props and slabs: origin is the floor surface (y = 0), up is negative.
//
// Nothing here is solid: the floor and slabs keep their own hit boxes.

/// The floor line in the units the screen-layer painters are written in.
const double kMockGround = 282;

/// A y far above the screen: wall pieces that reach the ceiling start here.
const double kReach = -420;

const Color _w = Color(0xFFFFFFFF);
const Color _k = Color(0xFF000000);

Color _a(Color c, double a) => c.withValues(alpha: a);

/// Pen: the paints and paths the painters reuse, so a frame allocates almost
/// nothing. Set [c] (and [vw]) before every use.
class CaveInk {
  late Canvas c;

  /// The visible width in the units the painters draw in.
  double vw = 800;

  final Paint _p = Paint();
  final Paint _h = Paint()..blendMode = BlendMode.plus;
  final Path _path = Path();
  static final Map<int, Shader> _halos = {};
  static final Map<int, TextPainter> _texts = {};

  void rect(double x, double y, double w, double h, Color col) {
    _p
      ..color = col
      ..style = PaintingStyle.fill;
    c.drawRect(Rect.fromLTWH(x, y, w, h), _p);
  }

  void rrect(double x, double y, double w, double h, double r, Color col) {
    _p
      ..color = col
      ..style = PaintingStyle.fill;
    c.drawRRect(RRect.fromLTRBR(x, y, x + w, y + h, Radius.circular(r)), _p);
  }

  void circle(double x, double y, double r, Color col) {
    _p
      ..color = col
      ..style = PaintingStyle.fill;
    c.drawCircle(Offset(x, y), r, _p);
  }

  void oval(double cx, double cy, double rx, double ry, Color col) {
    _p
      ..color = col
      ..style = PaintingStyle.fill;
    c.drawOval(Rect.fromLTRB(cx - rx, cy - ry, cx + rx, cy + ry), _p);
  }

  void tri(double x1, double y1, double x2, double y2, double x3, double y3,
      Color col) {
    _path
      ..reset()
      ..moveTo(x1, y1)
      ..lineTo(x2, y2)
      ..lineTo(x3, y3)
      ..close();
    _p
      ..color = col
      ..style = PaintingStyle.fill;
    c.drawPath(_path, _p);
  }

  void quad(double x1, double y1, double x2, double y2, double x3, double y3,
      double x4, double y4, Color col) {
    _path
      ..reset()
      ..moveTo(x1, y1)
      ..lineTo(x2, y2)
      ..lineTo(x3, y3)
      ..lineTo(x4, y4)
      ..close();
    _p
      ..color = col
      ..style = PaintingStyle.fill;
    c.drawPath(_path, _p);
  }

  /// A filled shape: [build] adds to the path, which starts empty.
  void fill(Color col, void Function(Path p) build) {
    _path.reset();
    build(_path);
    _p
      ..color = col
      ..style = PaintingStyle.fill;
    c.drawPath(_path, _p);
  }

  /// A line shape of [w] wide, with round ends.
  void stroke(Color col, double w, void Function(Path p) build) {
    _path.reset();
    build(_path);
    _p
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    c.drawPath(_path, _p);
    _p.style = PaintingStyle.fill;
  }

  void line(double x1, double y1, double x2, double y2, double w, Color col) {
    _p
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(x1, y1), Offset(x2, y2), _p);
    _p.style = PaintingStyle.fill;
  }

  void ring(double x, double y, double r, double w, Color col) {
    _p
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;
    c.drawCircle(Offset(x, y), r, _p);
    _p.style = PaintingStyle.fill;
  }

  void box(double x, double y, double w, double h, double sw, Color col) {
    _p
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw;
    c.drawRect(Rect.fromLTWH(x, y, w, h), _p);
    _p.style = PaintingStyle.fill;
  }

  /// A soft light: a round glow that adds to what is under it. The shaders are
  /// cached by colour and strength (in steps of 5%), never made per frame.
  void halo(double x, double y, double r, Color col, double a) {
    final q = (a.clamp(0.0, 1.0) * 20).round();
    if (q == 0) return;
    final key = col.toARGB32() * 31 + q;
    final shader = _halos[key] ??= RadialGradient(
      colors: [_a(col, q / 20), _a(col, 0)],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));
    _h.shader = shader;
    c.save();
    c.translate(x, y);
    c.scale(r);
    c.drawCircle(Offset.zero, 1, _h);
    c.restore();
  }

  /// A teardrop flame that flickers with [t].
  void flame(
      double x, double y, double s, double t, int seed, Color c1, Color c2) {
    final f =
        1 + .12 * math.sin(t * 13 + seed * 5) + .06 * math.sin(t * 23 + seed);
    c.save();
    c.translate(x, y);
    c.scale(s, s * f);
    fill(
        c1,
        (p) => p
          ..moveTo(0, -18)
          ..cubicTo(10, -6, 9, 6, 0, 8)
          ..cubicTo(-9, 6, -10, -6, 0, -18));
    fill(
        c2,
        (p) => p
          ..moveTo(0, -9)
          ..cubicTo(5, -2, 4, 4, 0, 5)
          ..cubicTo(-4, 4, -5, -2, 0, -9));
    c.restore();
  }

  /// Text drawn with a cached layout. [x] is the middle (or the left edge).
  void text(String s, double size, Color col, double x, double y,
      {bool center = false}) {
    final key = Object.hash(s, size, col.toARGB32());
    final tp = _texts[key] ??= TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              color: col, fontSize: size, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(center ? x - tp.width / 2 : x, y - tp.height * .8));
  }

  /// Calls [fn] for every repeat of something spaced [period] apart that is on
  /// screen, with its screen x and its number. [off] is how far the layer has slid.
  void each(double period, double off, void Function(double x, int i) fn) {
    final i0 = (off / period).floor() - 1;
    final i1 = ((off + vw) / period).ceil() + 1;
    for (var i = i0; i <= i1; i++) {
      fn(i * period - off, i);
    }
  }
}

/// One thing that stands on the cave floor: its width (for finding room) and how
/// to draw it with its middle at x = 0 and the floor at y = 0.
class CaveProp {
  final double width;
  final void Function(CaveInk k, CaveLook l, double t, int n) draw;
  const CaveProp(this.width, this.draw);
}

/// The painters of one era's cave.
abstract class CaveEraArt {
  const CaveEraArt();

  static const Map<String, CaveEraArt> _byId = {
    'pre': _PreArt(),
    'spa': _SpaArt(),
    'nat': _NatArt(),
    'ame': _AmeArt(),
    'ww2': _Ww2Art(),
    'mod': _ModArt(),
  };

  static CaveEraArt of(CaveLook l) => _byId[l.id] ?? _byId['spa']!;

  /// The wall decor and the lights on it (screen layers, mockup units). [cx] is
  /// the camera's x, [t] the time in seconds.
  void wall(CaveInk k, double cx, double t, CaveLook l);

  /// The ceiling and what hangs from it (origin at the top of the screen).
  void ceil(CaveInk k, double cx, double t, CaveLook l);

  /// The floor's surface texture over world x [x0]..[x1] (floor at y = 0).
  void floorTex(CaveInk k, double x0, double x1, double t, CaveLook l);

  /// The things that stand on the floor, in the order they are placed.
  List<CaveProp> get props;

  /// A slab [w] wide, its top at y = 0 and its left edge at x = 0.
  void plat(CaveInk k, double w, CaveLook l);

  // ─── shared pieces ──────────────────────────────────────────────────────

  /// A ceiling of rock with a ragged underside and stalactites.
  void rockCeil(CaveInk k, CaveLook l, double cx) {
    k.fill(l.rock0, (p) {
      p.moveTo(0, -80);
      p.lineTo(k.vw, -80);
      for (var x = k.vw + 20; x >= -20; x -= 20) {
        final wx = x + cx * .9;
        p.lineTo(x, 28 + caveRnd((wx / 20).floor()) * 16);
      }
      p.close();
    });
    k.rect(0, -80, k.vw, 90, _a(_w, .05));
    k.each(90, cx * .9, (x, i) {
      final len = 30 + caveRnd(i + 11) * 44;
      k.tri(x, 36, x + 14, 36 + len, x + 28, 36, l.rock1);
      k.tri(x + 4, 36, x + 14, 36 + len, x + 14, 36, _a(_w, .1));
    });
  }
}

// ═══ Sinaunang Pilipinas: a jungle cave ═══════════════════════════════════

class _PreArt extends CaveEraArt {
  const _PreArt();

  @override
  void wall(CaveInk k, double cx, double t, CaveLook l) {
    const ochre = Color(0x66D98B4A);
    k.each(430, cx * .4, (x, i) {
      final kk = ((i % 4) + 4) % 4;
      final y = 118 + (caveRnd(i) * 26).floorToDouble();
      switch (kk) {
        case 0: // a hand print
          k.circle(x + 60, y + 30, 14, ochre);
          for (var a = 0; a < 5; a++) {
            final an = -2.6 + a * .55;
            k.line(
                x + 60 + math.cos(an) * 12,
                y + 30 + math.sin(an) * 12,
                x + 60 + math.cos(an) * 30,
                y + 30 + math.sin(an) * 30,
                3,
                ochre);
          }
        case 1: // a spiral
          k.stroke(ochre, 3, (p) {
            var first = true;
            for (var a = 0.0; a <= math.pi * 7; a += .2) {
              final r = 2 + a * 1.6;
              final px = x + 60 + math.cos(a) * r,
                  py = y + 30 + math.sin(a) * r;
              if (first) {
                p.moveTo(px, py);
                first = false;
              } else {
                p.lineTo(px, py);
              }
            }
          });
        case 2: // two hunters
          for (var m = 0; m < 2; m++) {
            final px = x + 30 + m * 46.0;
            k.ring(px, y, 6, 3, ochre);
            k.line(px, y + 6, px, y + 34, 3, ochre);
            k.line(px, y + 16, px + (m == 1 ? -18 : 18), y + 4, 3, ochre);
            k.line(px, y + 34, px - 8, y + 50, 3, ochre);
            k.line(px, y + 34, px + 8, y + 50, 3, ochre);
          }
        default: // the sun
          k.ring(x + 60, y + 25, 12, 3, ochre);
          for (var a = 0; a < 10; a++) {
            final an = a * .628;
            k.line(
                x + 60 + math.cos(an) * 18,
                y + 25 + math.sin(an) * 18,
                x + 60 + math.cos(an) * 28,
                y + 25 + math.sin(an) * 28,
                3,
                ochre);
          }
      }
    });
    // Fireflies.
    final span = k.vw + 80;
    for (var i = 0; i < 12; i++) {
      final x = ((i * 173 + t * (8 + i % 4 * 3) - cx * .8) % span) - 40;
      final y = 90 + ((i * 61) % 150) + math.sin(t * 1.5 + i) * 12;
      final a = .5 + .5 * math.sin(t * 3 + i * 2);
      k.halo(x, y, 16, const Color(0xFFC8FF9A), .5 * a);
      k.rect(x - 1, y - 1, 2, 2, Color.fromRGBO(235, 255, 200, .5 + .5 * a));
    }
  }

  @override
  void ceil(CaveInk k, double cx, double t, CaveLook l) {
    rockCeil(k, l, cx);
    // Hanging vines.
    k.each(120, cx * .7, (x, i) {
      if (caveRnd(i + 3) < .35) return;
      final len = 40 + caveRnd(i) * 80, sw = math.sin(t * 1.2 + i) * 4;
      k.stroke(const Color(0xFF1D5A3A), 3, (p) {
        p.moveTo(x, 34);
        p.quadraticBezierTo(x + sw * .6, 34 + len * .5, x + sw, 34 + len);
      });
      for (var j = 1; j <= 3; j++) {
        k.oval(x + sw * j / 4 + (j.isOdd ? 6 : -6), 34 + len * j / 4, 7, 3,
            const Color(0xFF2C8A52));
      }
    });
  }

  @override
  void floorTex(CaveInk k, double x0, double x1, double t, CaveLook l) {
    for (var x = (x0 / 18).ceil() * 18.0; x < x1; x += 18) {
      final r = caveRnd(x / 18);
      if (r < .55) {
        k.tri(x, 2, x + 4, -4 - r * 8, x + 8, 2, const Color(0xFF2F7A49));
      }
    }
    for (var x = (x0 / 40).ceil() * 40.0; x < x1; x += 40) {
      final r = caveRnd(x / 40 + 9);
      k.oval(x + r * 20, 22 + r * 24, 6 + r * 6, 3 + r * 3, _a(_k, .22));
    }
  }

  @override
  List<CaveProp> get props => _props;
  static final List<CaveProp> _props = [
    CaveProp(
        40, (k, l, t, n) => _stalagmite(k, l, (30 + (n % 2) * 18).toDouble())),
    CaveProp(70, (k, l, t, n) {
      for (var j = 0; j < 3; j++) {
        final px = j * 16.0 - 14, hh = (14 + j % 2 * 8 + (n % 3)).toDouble();
        k.rect(px - 2, -hh, 4, hh, const Color(0xFFD9F2C8));
        final pul = .8 + .2 * math.sin(t * 2.5 + n + j);
        k.fill(Color.fromRGBO(108, 240, 184, pul), (p) {
          p.addArc(Rect.fromLTRB(px - 9, -hh - 6, px + 9, -hh + 6), math.pi,
              math.pi);
          p.close();
        });
      }
      k.halo(0, -20, 70, l.glow, .36);
    }),
    CaveProp(40, (k, l, t, n) => _stalagmite(k, l, 48)),
  ];

  static void _stalagmite(CaveInk k, CaveLook l, double h) {
    k.tri(-16, 0, 0, -h, 16, 0, l.rock1);
    k.tri(-4, 0, 0, -h, 0, 0, _a(_w, .1));
  }

  @override
  void plat(CaveInk k, double w, CaveLook l) {
    k.fill(l.rock0, (p) {
      p.moveTo(6, 10);
      for (var i = 0; i <= 8; i++) {
        p.lineTo(6 + (w - 12) * i / 8,
            20 + (i.isOdd ? 18 : 6) + caveRnd(i + w) * 10);
      }
      p.lineTo(w - 6, 10);
      p.close();
    });
    k.rect(0, 0, w, 20, l.rock1);
    for (var x = 4.0; x < w - 4; x += 12) {
      k.tri(x, 1, x + 3, -6 - caveRnd(x + w) * 4, x + 7, 1,
          const Color(0xFF2F7A49));
    }
    for (final x in [18.0, 60.0, w - 20]) {
      k.stroke(const Color(0xFF1D5A3A), 2, (p) {
        p.moveTo(x, 26);
        p.quadraticBezierTo(x + 4, 40, x, 52);
      });
    }
  }
}

// ═══ Pananakop ng Espanya: a stone dungeon ═══════════════════════════════

class _SpaArt extends CaveEraArt {
  const _SpaArt();

  @override
  void wall(CaveInk k, double cx, double t, CaveLook l) {
    k.each(240, cx * .4, (x, i) {
      k.rect(x, kReach, 22, 282 - kReach, _a(_w, .05));
      k.rect(x, kReach, 6, 282 - kReach, _a(_w, .05));
      k.stroke(
          _a(_w, .08),
          14,
          (p) => p.addArc(
              Rect.fromCircle(center: Offset(x + 131, 150), radius: 89),
              math.pi,
              math.pi));
      k.fill(_a(_k, .34), (p) {
        p.moveTo(x + 44, 282);
        p.lineTo(x + 44, 150);
        p.arcTo(Rect.fromCircle(center: Offset(x + 131, 150), radius: 87),
            math.pi, math.pi, false);
        p.lineTo(x + 218, 282);
        p.close();
      });
      if (i.isEven) {
        for (var bx = x + 56; bx < x + 210; bx += 15) {
          k.line(bx, 80 + (bx - (x + 131)).abs() * .15, bx, 282, 3,
              const Color(0xFF3B4150));
        }
        k.line(x + 46, 190, x + 216, 190, 3, const Color(0xFF3B4150));
      }
    });
    // Faint blocks of stone low on the wall.
    for (var y = 100.0; y < 282; y += 30) {
      k.each(90, cx * .4 + (y % 60 == 0 ? 0 : 45), (x, i) {
        k.rect(x, y, 86, 26, _a(_w, .025));
      });
    }
    // Chains hanging from the vault are in [ceil]; the torches are here.
    k.each(480, cx * .7 + 100, (x, i) {
      const y = 124.0;
      k.rect(x - 3, y, 6, 28, const Color(0xFF2A2E38));
      k.rect(x - 10, y - 3, 20, 6, const Color(0xFF2A2E38));
      k.halo(x, y - 14, 120, const Color(0xFFFF9A3A),
          .3 + .05 * math.sin(t * 9 + i));
      k.flame(
          x, y - 12, 1, t, i, const Color(0xFFFF9A3A), const Color(0xFFFFE28A));
    });
  }

  @override
  void ceil(CaveInk k, double cx, double t, CaveLook l) {
    k.rect(0, -80, k.vw, 118, l.rock0);
    k.each(64, cx * .9, (x, i) {
      k.rect(x + 2, 2, 60, 15, _a(_w, .06));
      k.rect(x + 34, 20, 60, 15, _a(_w, .06));
    });
    k.rect(0, 36, k.vw, 6, l.rock1);
    k.rect(0, 36, k.vw, 2, _a(_w, .1));
    k.each(150, cx * .9, (x, i) {
      k.tri(x, 42, x + 8, 42 + 14 + caveRnd(i) * 18, x + 16, 42, l.rock1);
    });
    // Chains.
    k.each(300, cx * .7, (x, i) {
      if (i.isOdd) return;
      final len = 60 + caveRnd(i) * 50;
      for (var y = 42.0; y < 42 + len; y += 9) {
        k.stroke(
            const Color(0xFF2A2E38),
            3,
            (p) => p.addOval(Rect.fromCenter(
                center: Offset(x + math.sin(t + i) * 2, y),
                width: 6,
                height: 10)));
      }
    });
  }

  @override
  void floorTex(CaveInk k, double x0, double x1, double t, CaveLook l) {
    k.line(x0, 30, x1, 30, 2, _a(_k, .3));
    for (var x = (x0 / 70).ceil() * 70.0; x < x1; x += 70) {
      k.line(x, 10, x, 30, 2, _a(_k, .3));
      k.line(x + 35, 30, x + 35, 52, 2, _a(_k, .3));
    }
  }

  @override
  List<CaveProp> get props => _props;
  static final List<CaveProp> _props = [
    CaveProp(80, (k, l, t, n) {
      _barrel(k, -18, 0, const Color(0xFF6A4A2C));
      _barrel(k, 18, 0, const Color(0xFF5A3D24));
    }),
    CaveProp(80, (k, l, t, n) {
      _crate(k, -20, 0, 40, const Color(0xFF7A5A38));
      _crate(k, 20, 0, 32, const Color(0xFF6A4A2C));
      _crate(k, 0, -40, 30, const Color(0xFF7A5A38));
    }),
    CaveProp(56, (k, l, t, n) {
      const balls = [(-18, 0), (0, 0), (18, 0), (-9, 1), (9, 1), (0, 2)];
      for (final b in balls) {
        k.circle(b.$1.toDouble(), -8 - b.$2 * 15.0, 9, const Color(0xFF2B2D34));
        k.circle(b.$1 - 3.0, -11 - b.$2 * 15.0, 3, _a(_w, .2));
      }
    }),
  ];

  @override
  void plat(CaveInk k, double w, CaveLook l) {
    k.rect(0, 12, w, 26, l.rock0);
    for (var r = 0; r < 3; r++) {
      for (var x = r.isOdd ? -18.0 : 0.0; x < w; x += 36) {
        final a = math.max(x, 0.0), b = math.min(x + 34, w);
        if (b > a) {
          k.rect(a, r * 12.0, b - a, 11, r == 0 ? l.rock1 : l.rock0);
          k.rect(a, r * 12.0, b - a, 2, _a(_w, .08));
        }
      }
    }
    k.rect(0, 0, w, 5, l.lip);
    for (final x in [12.0, w - 12]) {
      k.line(x, 0, x, -60, 3, const Color(0xFF2A2E38));
    }
  }
}

// ═══ Nasyonalismo: a Katipunan hideout ═══════════════════════════════════

class _NatArt extends CaveEraArt {
  const _NatArt();

  static const Color _wood = Color(0xFF4A2E18);

  @override
  void wall(CaveInk k, double cx, double t, CaveLook l) {
    k.each(34, cx * .35, (x, i) {
      k.rect(x, kReach, 32, 282 - kReach, _a(_w, .025 + .025 * (i & 1)));
    });
    k.each(300, cx * .5, (x, i) {
      k.rect(x, kReach, 18, 282 - kReach, _wood);
      k.rect(
          x, kReach, 4, 282 - kReach, const Color.fromRGBO(255, 220, 150, .12));
      k.line(x + 18, 212, x + 64, 162, 9, _wood);
    });
    k.rect(0, 56, k.vw, 12, _wood);
    k.rect(0, 56, k.vw, 3, const Color.fromRGBO(255, 220, 150, .14));
    // The red banners with a white K.
    k.each(700, cx * .6 + 200, (x, i) {
      final sw = math.sin(t * 1.4 + i) * 2;
      k.fill(const Color(0xFFB3262A), (p) {
        p.moveTo(x, 68);
        p.lineTo(x + 58, 68);
        p.lineTo(x + 58 + sw, 150);
        p.lineTo(x + 29 + sw, 138);
        p.lineTo(x + sw, 150);
        p.close();
      });
      k.rect(x + 42, 68, 16, 76, _a(_k, .2));
      k.text('K', 34, _w, x + 29 + sw * .5, 114, center: true);
    });
    // Lanterns on chains.
    k.each(380, cx * .7, (x, i) {
      final sw = math.sin(t * 1.1 + i) * 3;
      const y = 118.0;
      k.line(x, 68, x + sw, y - 12, 2, const Color(0xFF2A1A0E));
      k.halo(x + sw, y, 110, l.glow, .32 + .04 * math.sin(t * 7 + i));
      k.rect(x + sw - 8, y - 12, 16, 4, const Color(0xFF2A1A0E));
      k.rect(x + sw - 8, y + 12, 16, 4, const Color(0xFF2A1A0E));
      k.rect(x + sw - 6, y - 8, 12, 20, l.glow);
      k.rect(x + sw - 3, y - 4, 6, 12, l.glow2);
    });
  }

  @override
  void ceil(CaveInk k, double cx, double t, CaveLook l) {
    k.rect(0, -80, k.vw, 112, const Color(0xFF2A170D));
    k.each(46, cx * .9, (x, i) => k.rect(x, -80, 2, 112, _a(_w, .05)));
    k.rect(0, 32, k.vw, 4, _a(_k, .35));
  }

  @override
  void floorTex(CaveInk k, double x0, double x1, double t, CaveLook l) {
    k.line(x0, 18, x1, 18, 2, _a(_k, .32));
    k.line(x0, 36, x1, 36, 2, _a(_k, .32));
    for (var x = (x0 / 90).ceil() * 90.0; x < x1; x += 90) {
      k.line(x, 8, x, 18, 2, _a(_k, .32));
      k.line(x + 45, 18, x + 45, 36, 2, _a(_k, .32));
      k.rect(x + 6, 12, 3, 3, _a(_w, .18));
    }
  }

  @override
  List<CaveProp> get props => _props;
  static final List<CaveProp> _props = [
    CaveProp(90, (k, l, t, n) {
      _crate(k, -22, 0, 44, const Color(0xFF7A5230));
      _crate(k, 20, 0, 34, const Color(0xFF6A4528));
    }),
    CaveProp(70, (k, l, t, n) {
      for (final x in [-15.0, 15.0]) {
        k.oval(x, -14, 16, 16, const Color(0xFFB79A68));
        k.rect(x - 6, -32, 12, 6, const Color(0xFF8A6E44));
      }
    }),
    CaveProp(100, (k, l, t, n) {
      k.rect(-40, -34, 80, 8, const Color(0xFF6A4528));
      k.rect(-34, -26, 6, 26, const Color(0xFF6A4528));
      k.rect(28, -26, 6, 26, const Color(0xFF6A4528));
      k.rect(-25, -40, 24, 6, const Color(0xFFF2E6C4));
      k.rect(-21, -46, 18, 6, const Color(0xFFE8DCB8));
      k.rect(16, -48, 6, 14, const Color(0xFFF5EAD0));
      k.halo(19, -52, 80, l.glow, .42);
      k.flame(
          19, -54, .35, t, 4, const Color(0xFFFFB340), const Color(0xFFFFF3C0));
    }),
  ];

  @override
  void plat(CaveInk k, double w, CaveLook l) {
    k.rect(0, 0, w, 18, _wood);
    k.rect(0, 0, w, 6, l.rock1);
    for (var x = 24.0; x < w; x += 24) {
      k.line(x, 0, x, 18, 2, _a(_k, .4));
    }
    k.rect(10, 18, 8, 22, const Color(0xFF2A1A0E));
    k.rect(w - 18, 18, 8, 22, const Color(0xFF2A1A0E));
    k.line(14, 24, 14, -40, 2, const Color(0xFFB79A68));
    k.line(w - 14, 24, w - 14, -40, 2, const Color(0xFFB79A68));
  }
}

// ═══ Amerikano: a mine ═══════════════════════════════════════════════════

class _AmeArt extends CaveEraArt {
  const _AmeArt();

  static const Color _timber = Color(0xFF5A3D1E);

  @override
  void wall(CaveInk k, double cx, double t, CaveLook l) {
    for (var s = 0; s < 6; s++) {
      final col = _a(_w, .03 + (s % 2) * .015);
      k.stroke(col, 12, (p) {
        for (var x = -10.0; x <= k.vw + 10; x += 20) {
          final y = 64 + s * 36 + math.sin((x + cx * .3) * .02 + s * 1.7) * 8;
          if (x == -10) {
            p.moveTo(x, y);
          } else {
            p.lineTo(x, y);
          }
        }
      });
    }
    // Timber frames.
    k.each(260, cx * .45, (x, i) {
      k.rect(x, kReach, 16, 282 - kReach, _timber);
      k.rect(x + 200, kReach, 16, 282 - kReach, _timber);
      k.rect(x - 10, 38, 236, 16, _timber);
      k.rect(
          x, kReach, 4, 282 - kReach, const Color.fromRGBO(255, 230, 160, .14));
      k.rect(x + 200, kReach, 4, 282 - kReach,
          const Color.fromRGBO(255, 230, 160, .14));
      k.rect(x - 10, 38, 236, 3, const Color.fromRGBO(255, 230, 160, .14));
      k.line(x + 16, 112, x + 56, 54, 8, _timber);
      k.line(x + 200, 112, x + 160, 54, 8, _timber);
    });
    // The string of bulbs.
    k.each(130, cx * .7, (x, i) {
      k.stroke(const Color(0xFF1B1208), 2, (p) {
        p.moveTo(x, 50);
        p.quadraticBezierTo(x + 65, 76, x + 130, 50);
      });
      final bx = x + 65;
      const by = 72.0;
      final fl = (i % 5 == 0) ? (.7 + .3 * math.sin(t * 17 + i)) : 1.0;
      k.halo(bx, by + 8, 100, const Color(0xFFFFE9A0), .34 * fl);
      k.circle(bx, by + 8, 5, const Color(0xFFFFF4C8));
      k.rect(bx - 3, by - 2, 6, 5, const Color(0xFF3A2A14));
    });
  }

  @override
  void ceil(CaveInk k, double cx, double t, CaveLook l) {
    rockCeil(k, l, cx);
    k.rect(0, 36, k.vw, 8, _timber);
    k.rect(0, 36, k.vw, 2, const Color.fromRGBO(255, 230, 160, .14));
  }

  @override
  void floorTex(CaveInk k, double x0, double x1, double t, CaveLook l) {
    for (var x = (x0 / 30).ceil() * 30.0; x < x1; x += 30) {
      final r = caveRnd(x / 30 + 5);
      k.rect(x + r * 12, 26 + r * 22, 4 + r * 5, 3, _a(_k, .22));
    }
    for (var x = (x0 / 26).ceil() * 26.0; x < x1; x += 26) {
      k.rect(x, -2, 18, 7, const Color(0xFF4A3418));
    }
    k.rect(x0, -5, x1 - x0, 3, const Color.fromRGBO(210, 214, 222, .7));
    k.rect(x0, -5, x1 - x0, 1, const Color.fromRGBO(255, 255, 255, .3));
  }

  @override
  List<CaveProp> get props => _props;
  static final List<CaveProp> _props = [
    CaveProp(90, (k, l, t, n) {
      const y = -5.0;
      k.quad(-34, y - 34, 34, y - 34, 26, y - 6, -26, y - 6,
          const Color(0xFF5B5F68));
      k.rect(-34, y - 34, 68, 4, _a(_w, .14));
      for (var j = 0; j < 8; j++) {
        k.circle(
            -24 + j * 7.0, y - 38 - (j % 3) * 3, 5, const Color(0xFFFFD24A));
      }
      k.halo(0, y - 40, 60, const Color(0xFFFFD24A), .28);
      k.circle(-18, y - 3, 6, const Color(0xFF1B1208));
      k.circle(18, y - 3, 6, const Color(0xFF1B1208));
    }),
    CaveProp(80, (k, l, t, n) {
      _barrel(k, -18, 0, const Color(0xFF6A4A28));
      _barrel(k, 18, 0, const Color(0xFF5A3E22));
    }),
    CaveProp(50, (k, l, t, n) {
      _crate(k, 0, 0, 40, const Color(0xFF7A5A30));
      k.halo(0, -52, 80, const Color(0xFFFFE9A0), .4);
      k.rect(-5, -56, 10, 14, const Color(0xFF3A2A14));
      k.rect(-3, -54, 6, 10, const Color(0xFFFFE9A0));
    }),
  ];

  @override
  void plat(CaveInk k, double w, CaveLook l) {
    k.rect(0, 12, w, 12, const Color(0xFF3A2814));
    k.rect(0, 0, w, 14, const Color(0xFF7A5A30));
    for (var x = 30.0; x < w; x += 30) {
      k.line(x, 0, x, 14, 2, _a(_k, .4));
    }
    k.rect(0, 0, w, 3, const Color.fromRGBO(255, 230, 160, .2));
    for (final x in [8.0, w - 8]) {
      k.circle(x, 6, 2.5, const Color(0xFFB8BCC4));
    }
    k.rect(6, 24, 12, 18, _timber);
    k.rect(w - 18, 24, 12, 18, _timber);
  }
}

// ═══ Hapon: a bunker ═════════════════════════════════════════════════════

class _Ww2Art extends CaveEraArt {
  const _Ww2Art();

  @override
  void wall(CaveInk k, double cx, double t, CaveLook l) {
    k.each(170, cx * .45, (x, i) {
      k.rect(x, kReach, 16, 282 - kReach, _a(_w, .06));
      k.rect(x + 16, kReach, 4, 282 - kReach, _a(_k, .25));
      for (var y = 100.0; y < 282; y += 30) {
        k.circle(x + 8, y, 2, _a(_w, .14));
      }
    });
    k.rect(0, 200, k.vw, 6, const Color.fromRGBO(210, 180, 60, .16));
    k.each(170, cx * .45, (x, i) => k.rect(x + 28, 120, 110, 70, _a(_w, .035)));
    // Barbed wire.
    const wire = Color(0xFF6B7570);
    k.stroke(wire, 2, (p) {
      for (var x = -10.0; x <= k.vw + 10; x += 6) {
        final y = 50 + math.sin((x + cx * .7) * .12) * 6;
        if (x == -10) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
    });
    k.each(14, cx * .7, (x, i) {
      final y = 50 + math.sin((x + cx * .7) * .12) * 6;
      k.line(x - 3, y - 3, x + 3, y + 3, 2, wire);
      k.line(x + 3, y - 3, x - 3, y + 3, 2, wire);
    });
    // Caged bulbs.
    k.each(240, cx * .7, (x, i) {
      final bx = x + 60;
      const by = 78.0;
      final fl =
          (i % 3 == 0) ? (.55 + .45 * math.sin(t * 9 + i * 3).abs()) : 1.0;
      k.line(bx, 50, bx, by - 8, 2, const Color(0xFF1B2024));
      k.halo(bx, by + 4, 110, l.glow, .34 * fl);
      k.circle(bx, by + 4, 6, l.glow2);
      k.box(bx - 9, by - 6, 18, 20, 1.5, const Color(0xFF2A3238));
    });
    // The searchlight sweeping across.
    final bx = 330 + math.sin(t * .45) * 180;
    k.halo(bx, 40, 60, l.glow2, .18);
    k.quad(bx - 10, kReach, bx + 10, kReach, bx + 110, 282, bx - 40, 282,
        const Color.fromRGBO(180, 220, 255, .07));
  }

  @override
  void ceil(CaveInk k, double cx, double t, CaveLook l) {
    k.rect(0, -80, k.vw, 116, l.rock0);
    k.each(170, cx * .9, (x, i) {
      k.rect(x, -80, 14, 116, _a(_w, .1));
      k.circle(x + 7, 8, 2, _a(_w, .2));
      k.circle(x + 7, 24, 2, _a(_w, .2));
    });
    k.rect(0, 36, k.vw, 6, const Color.fromRGBO(120, 140, 140, .4));
    k.rect(0, 36, k.vw, 2, _a(_w, .1));
  }

  @override
  void floorTex(CaveInk k, double x0, double x1, double t, CaveLook l) {
    for (var x = (x0 / 120).ceil() * 120.0; x < x1; x += 120) {
      k.line(x, 8, x, 58, 2, _a(_k, .3));
    }
    for (var x = (x0 / 40).ceil() * 40.0; x < x1; x += 40) {
      k.quad(x, 14, x + 14, 14, x + 6, 22, x - 8, 22,
          const Color.fromRGBO(210, 180, 60, .35));
    }
  }

  @override
  List<CaveProp> get props => _props;
  static final List<CaveProp> _props = [
    CaveProp(110, (k, l, t, n) {
      const rows = [(0, 4), (1, 4), (2, 4), (0, 3), (1, 3), (0, 2)];
      // A wall of sandbags: 3 rows, 4 / 3 / 2 bags.
      for (final r in rows) {
        _sandbag(k, -51 + r.$1 * 34.0 + (4 - r.$2) * 17, -(4 - r.$2) * 11.0);
      }
    }),
    CaveProp(60, (k, l, t, n) {
      _crate(k, -16, 0, 40, const Color(0xFF4B5A3C));
      _crate(k, 24, 0, 32, const Color(0xFF3E4C32));
      k.rect(-28, -26, 24, 3, _a(_w, .35));
    }),
    CaveProp(60, (k, l, t, n) {
      const steel = Color(0xFF4B5560);
      k.line(-14, 0, 14, -34, 5, steel);
      k.line(14, 0, -14, -34, 5, steel);
      k.line(0, -3, 0, -40, 5, steel);
    }),
    CaveProp(70, (k, l, t, n) {
      _barrel(k, 0, 0, const Color(0xFF566B4A));
      for (final x in [-26.0, 26.0]) {
        _sandbag(k, x, 0);
      }
    }),
  ];

  @override
  void plat(CaveInk k, double w, CaveLook l) {
    k.rect(0, 8, w, 12, const Color(0xFF2A3330));
    k.rect(0, 0, w, 10, const Color(0xFF58655E));
    for (var x = 0.0; x < w - 8; x += 24) {
      k.quad(x, 8, x + 10, 8, x + 16, 20, x + 6, 20,
          const Color.fromRGBO(210, 180, 60, .5));
    }
    k.rect(0, 0, w, 2, _a(_w, .2));
    for (final x in [10.0, w - 10]) {
      k.line(x, 20, x, 40, 3, const Color(0xFF2A3330));
    }
  }
}

// ═══ Modern: a neon tunnel ═══════════════════════════════════════════════

class _ModArt extends CaveEraArt {
  const _ModArt();

  @override
  void wall(CaveInk k, double cx, double t, CaveLook l) {
    final line = _a(_w, .045);
    k.each(120, cx * .35, (x, i) => k.line(x, kReach, x, 282, 2, line));
    for (var y = -8.0; y < 282; y += 64) {
      k.line(0, y, k.vw, y, 2, line);
    }
    // The cable tray.
    k.rect(0, 96, k.vw, 12, _a(_w, .06));
    const cables = [
      (Color(0xFF46E0FF), 98.0),
      (Color(0xFFFF4FD8), 101.0),
      (Color(0xFFFFE24A), 104.0)
    ];
    for (final c in cables) {
      k.rect(0, c.$2, k.vw, 2, _a(c.$1, .5));
    }
    // Neon strips.
    k.each(400, cx * .5, (x, i) {
      final col = i.isOdd ? l.glow2 : l.glow;
      k.rect(x, kReach, 5, 282 - kReach, col);
      k.halo(x + 2, 160, 110, col, .3);
    });
    // The LABAS sign.
    k.each(900, cx * .6 + 150, (x, i) {
      k.rect(x, 120, 120, 44, const Color(0xFF0A0E20));
      k.halo(x + 60, 142, 120, l.glow, .24);
      k.box(x + 1, 121, 118, 42, 2, l.glow);
      k.text('LABAS', 20, l.glow, x + 12, 150);
      k.line(x + 94, 142, x + 106, 142, 2, l.glow);
      k.line(x + 100, 134, x + 106, 142, 2, l.glow);
      k.line(x + 100, 150, x + 106, 142, 2, l.glow);
    });
    // Sparks of light rising.
    final span = k.vw + 60;
    for (var i = 0; i < 16; i++) {
      final x = ((i * 137 - cx * .8) % span) - 30;
      final y = 282 - ((i * 53 + t * (20 + i % 4 * 8)) % 260);
      final col = i.isOdd ? l.glow2 : l.glow;
      k.halo(x, y, 12, col, .45);
      k.rect(x - 1, y - 1, 2, 2, col);
    }
  }

  @override
  void ceil(CaveInk k, double cx, double t, CaveLook l) {
    k.rect(0, -80, k.vw, 118, l.rock0);
    k.rect(0, 22, k.vw, 5, _a(_w, .06));
    k.rect(0, 30, k.vw, 3, _a(_w, .06));
    k.each(260, cx * .9, (x, i) {
      k.rect(x + 40, 34, 120, 5, const Color(0xFFDFF8FF));
      k.halo(x + 100, 38, 130, l.glow, .3);
      k.quad(x + 40, 38, x + 160, 38, x + 200, 130, x, 130, _a(l.glow, .07));
    });
  }

  @override
  void floorTex(CaveInk k, double x0, double x1, double t, CaveLook l) {
    for (var x = (x0 / 80).ceil() * 80.0; x < x1; x += 80) {
      k.line(x, 8, x, 58, 2, _a(_k, .35));
    }
    k.rect(x0, 14, x1 - x0, 2, _a(l.glow, .4));
    k.rect(x0, 8, x1 - x0, 14, _a(_w, .05));
  }

  @override
  List<CaveProp> get props => _props;
  static final List<CaveProp> _props = [
    CaveProp(60, (k, l, t, n) {
      k.rect(-24, -38, 10, 38, const Color(0xFF5B4A38));
      k.rect(20, -38, 10, 38, const Color(0xFF5B4A38));
      k.oval(-4, -24, 7, 22, const Color(0xFF7A6448));
      k.rect(-4, -2, 40, 2, const Color(0xFF463928));
    }),
    CaveProp(80, (k, l, t, n) {
      k.rect(-35, -34, 70, 34, const Color(0xFF12142A));
      for (var x = -33.0; x < 31; x += 14) {
        k.quad(x, -34, x + 8, -34, x - 2, 0, x - 10, 0, l.glow2);
      }
      k.halo(0, -20, 80, l.glow2, .2);
    }),
    CaveProp(50, (k, l, t, n) {
      k.rect(-19, -36, 38, 36, const Color(0xFF20263F));
      k.rect(-13, -30, 26, 3, l.glow);
      k.rect(-13, -22, 14, 3, l.glow2);
      k.halo(0, -26, 60, l.glow, .26);
    }),
    CaveProp(50, (k, l, t, n) {
      k.rect(-20, -78, 40, 78, const Color(0xFF161A32));
      k.box(-19, -77, 38, 76, 2, const Color(0xFF2D3558));
      for (var r = 0; r < 8; r++) {
        final on = math.sin(t * 4 + r * 2.3) > 0;
        k.rect(-12, -70 + r * 8.5, 6, 3, on ? l.glow : const Color(0xFF16324A));
        k.rect(2, -70 + r * 8.5, 6, 3,
            r % 3 == 0 ? l.glow2 : const Color(0xFF3A2040));
      }
      k.halo(0, -40, 90, l.glow, .22);
    }),
  ];

  @override
  void plat(CaveInk k, double w, CaveLook l) {
    k.rect(0, 8, w, 12, const Color(0xFF161A32));
    k.rect(0, 0, w, 10, l.rock1);
    for (var x = 6.0; x < w - 6; x += 14) {
      k.rect(x, 3, 7, 4, _a(_k, .35));
    }
    k.rect(0, 0, w, 2, l.glow);
    k.rect(0, 18, w, 2, l.glow2);
    k.halo(w / 2, 20, 90, l.glow2, .2);
    k.rect(10, 20, 4, 22, const Color(0xFF2D3558));
    k.rect(w - 14, 20, 4, 22, const Color(0xFF2D3558));
  }
}

// ─── pieces shared by several eras ──────────────────────────────────────

void _barrel(CaveInk k, double x, double y, Color col) {
  k.rrect(x - 17, y - 42, 34, 42, 6, col);
  k.rect(x - 14, y - 40, 6, 38, _a(_w, .12));
  k.rect(x - 17, y - 32, 34, 4, _a(_k, .35));
  k.rect(x - 17, y - 12, 34, 4, _a(_k, .35));
}

void _crate(CaveInk k, double x, double y, double s, Color col) {
  k.rect(x - s / 2, y - s, s, s, col);
  k.box(x - s / 2 + 1.5, y - s + 1.5, s - 3, s - 3, 3, _a(_k, .4));
  k.line(x - s / 2, y - s, x + s / 2, y, 3, _a(_k, .4));
  k.rect(x - s / 2, y - s, s, 4, _a(_w, .1));
}

void _sandbag(CaveInk k, double x, double y) {
  k.oval(x, y - 6, 15, 7, const Color(0xFF8A7A55));
  k.fill(_a(_k, .25),
      (p) => p.addArc(Rect.fromLTRB(x - 15, y - 7, x + 15, y + 1), 0, math.pi));
  k.rect(x - 8, y - 10, 12, 2, _a(_w, .14));
}

/// Gradients the scenery shares (made once per size by the components).
LinearGradient caveWallGradient(CaveLook l) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [l.wallTop, l.wallMid, l.wallBottom],
      stops: const [0, .6, 1],
    );
