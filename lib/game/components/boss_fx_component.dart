import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart' show FontWeight, Shadow, TextStyle;

import 'boss_attack_paint.dart';

/// What a hit looks like. Each attack uses one (see [BossBurstComponent]).
enum BossBurstKind { water, coin, ghost, volley, slash, bag, muzzle }

enum _Bit { square, ring, coin, bill, glow, cross }

class _Piece {
  _Piece(
    this.bit,
    this.life, {
    this.vx = 0,
    this.vy = 0,
    this.g = 0,
    this.size = 3,
    this.color = const Color(0xFFFFFFFF),
    this.r0 = 0,
    this.r1 = 0,
    this.width = 3,
    this.rot = 0,
    this.vr = 0,
    this.rgbHex = 0xFFFFFF,
  });

  final _Bit bit;
  final double life;
  double t = 0;
  double x = 0, y = 0, vx, vy, g, size, r0, r1, width, rot, vr;
  Color color;
  int rgbHex;
}

/// A short burst of sparks, rings and coins where an attack lands (on the hero, or on the
/// boss when it is sent back), ported from the approved mock-up. Counted in [update] with the
/// frame's `dt`, and gone by itself.
class BossBurstComponent extends PositionComponent {
  BossBurstComponent({
    required this.kind,
    required Vector2 at,
    this.onBoss = false,
    int seed = 1,
    Color tint = const Color(0xFFFFE6A0),
  })  : _random = math.Random(seed),
        super(position: at.clone(), priority: 16) {
    _build(tint);
  }

  final BossBurstKind kind;
  final bool onBoss;
  final math.Random _random;
  final List<_Piece> _pieces = [];

  /// Pieces still alive (for tests).
  int get pieceCount => _pieces.length;

  double _r() => _random.nextDouble();

  void _squares(int n, List<int> cols, double speed, double spread, double g,
      double life, double sz) {
    for (var i = 0; i < n; i++) {
      final an = -math.pi / 2 + (_r() - .5) * spread;
      final s = speed * (.35 + _r() * .65);
      _pieces.add(_Piece(_Bit.square, life * (.7 + _r() * .5),
          vx: math.cos(an) * s,
          vy: math.sin(an) * s,
          g: g,
          size: sz + (_r() * 3).floor() * 2,
          color: rgb(cols[_random.nextInt(cols.length)])));
    }
  }

  void _ring(double r0, double r1, double life, int col, double w) => _pieces
      .add(_Piece(_Bit.ring, life, r0: r0, r1: r1, color: rgb(col), width: w));

  void _glow(double r, double life, int col) =>
      _pieces.add(_Piece(_Bit.glow, life, r1: r, rgbHex: col));

  void _coins(int n, double speed) {
    for (var i = 0; i < n; i++) {
      _pieces.add(_Piece(_Bit.coin, 1.1 + _r() * .3,
          vx: (_r() - .5) * speed * .9,
          vy: -(.35 + _r() * .65) * speed,
          g: 640,
          size: 5 + _r() * 2,
          rot: _r() * 6,
          vr: 8 + _r() * 8));
    }
  }

  void _build(Color tint) {
    switch (kind) {
      case BossBurstKind.water:
        _ring(6, 84, .55, 0xD6F1FF, 5);
        _ring(2, 52, .45, 0x5CB8FF, 3);
        _squares(46, const [0xFFFFFF, 0xBFE8FF, 0x6CC0FF, 0x2F86E0], 440, 2.8,
            640, .95, 4);
        _squares(16, const [0xFFFFFF, 0xBFE8FF], 300, 5, 700, .7, 3);
      case BossBurstKind.coin:
        _ring(8, 86, .55, 0xFFD24A, 5);
        _ring(4, 50, .4, 0xFFF2B0, 3);
        _coins(10, 340);
      case BossBurstKind.ghost:
        _glow(62, .3, 0x78B4FF);
        _ring(6, 72, .4, 0xBFE0FF, 4);
        _squares(
            24, const [0xBFE0FF, 0x5FA8FF, 0xFFFFFF], 380, 3.2, 500, .8, 3);
      case BossBurstKind.volley:
        _ring(4, 44, .3, 0xFFF0B0, 3);
        _squares(
            26, const [0xFFFFFF, 0xFFE9A0, 0xFFB400], 420, 3.4, 500, .7, 3);
        _glow(46, .2, 0xFFE696);
      case BossBurstKind.slash:
        _glow(56, .22, 0xFFFFFF);
        _pieces.add(_Piece(_Bit.cross, .34));
        _ring(6, 70, .4, 0xFFB0A0, 4);
        _squares(20, const [0xFFFFFF, 0xFFD7D0, 0xFF6B5E, 0xC0C0D0], 400, 3.2,
            520, .75, 3);
      case BossBurstKind.bag:
        _ring(4, 56, .35, 0xFFD34D, 3);
        _coins(24, 440);
        for (var i = 0; i < 8; i++) {
          _pieces.add(_Piece(_Bit.bill, 1.1 + _r() * .3,
              vx: (_r() - .5) * 300,
              vy: -(.3 + _r() * .7) * 320,
              g: 560,
              rot: _r() * 6,
              vr: 6 + _r() * 6));
        }
      case BossBurstKind.muzzle:
        _glow(40, .2, tint.toARGB32() & 0xFFFFFF);
        _squares(10, const [0xFFFFFF, 0xFFE9A0], 260, 6, 300, .35, 3);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (var i = _pieces.length - 1; i >= 0; i--) {
      final p = _pieces[i]..t += dt;
      if (p.t >= p.life) {
        _pieces.removeAt(i);
        continue;
      }
      p.vy += p.g * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rot += p.vr * dt;
    }
    if (_pieces.isEmpty) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    for (final p in _pieces) {
      final u = p.t / p.life;
      switch (p.bit) {
        case _Bit.square:
          fillRect(canvas, p.x, p.y, p.size, p.size,
              p.color.withValues(alpha: (1 - u * u).clamp(0.0, 1.0)));
        case _Bit.ring:
          final rr = p.r0 + (p.r1 - p.r0) * (1 - (1 - u) * (1 - u));
          canvas.drawCircle(
              Offset.zero,
              rr,
              strokePaint(
                  p.color.withValues(alpha: (1 - u).clamp(0.0, 1.0)), p.width));
        case _Bit.glow:
          final rr = p.r1 * (.6 + u * .6);
          glowDot(canvas, 0, 0, rr, p.rgbHex, (1 - u).clamp(0.0, 1.0));
        case _Bit.coin:
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.scale(math.max(.2, math.cos(p.rot).abs()), 1);
          final a = (1 - u * u * u).clamp(0.0, 1.0);
          fillDisc(canvas, 0, 0, p.size, rgb(0xA76B0C, a));
          fillDisc(canvas, 0, 0, p.size - 1.5, rgb(0xFFCF3D, a));
          canvas.restore();
        case _Bit.bill:
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(p.rot);
          final a = (1 - u * u * u).clamp(0.0, 1.0);
          fillRect(canvas, -7, -3.5, 14, 7, rgb(0x4FAE6A, a));
          fillRect(canvas, -2, -2, 4, 4, rgb(0x2F7A46, a));
          canvas.restore();
        case _Bit.cross:
          final l = 14 + 34 * Curves.easeInOut.transform(math.min(1, u * 2.5));
          final a = (1 - u * u).clamp(0.0, 1.0);
          for (final (col, w, k) in [
            (rgb(0xFFFFFF, a), 4 * (1 - u) + 1, 1.0),
            (rgb(0xFF6B5E, a * .78), 2.0, .78),
          ]) {
            final paint = strokePaint(col, w, round: true);
            canvas.drawLine(
                Offset(-l * k, -l * k), Offset(l * k, l * k), paint);
            canvas.drawLine(
                Offset(l * k, -l * k), Offset(-l * k, l * k), paint);
          }
      }
    }
  }
}

/// A short word that rises and fades ("-1").
class BossFloatText extends TextComponent {
  BossFloatText(
      {required String text, required Vector2 at, required Color color})
      : super(
          text: text,
          position: at.clone(),
          anchor: Anchor.bottomCenter,
          priority: 20,
          textRenderer: TextPaint(
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: color,
              shadows: const [
                Shadow(color: Color(0xFF1A0E06), offset: Offset(2, 2)),
                Shadow(color: Color(0xFF1A0E06), offset: Offset(-2, 2)),
                Shadow(color: Color(0xFF1A0E06), offset: Offset(2, -2)),
                Shadow(color: Color(0xFF1A0E06), offset: Offset(-2, -2)),
              ],
            ),
          ),
        );

  static const double lifetime = 1.0;

  @override
  Future<void> onLoad() async {
    add(MoveByEffect(Vector2(0, -50),
        EffectController(duration: lifetime, curve: Curves.easeOut)));
    add(OpacityEffect.fadeOut(
      EffectController(duration: 0.35, startDelay: lifetime - 0.35),
      onComplete: removeFromParent,
    ));
  }
}
