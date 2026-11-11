import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../chrono_game.dart';
import '../components/tile_platform_component.dart';

/// The same pseudo-random number between 0 and 1 for the same [i], every time:
/// stars, crystals and hanging rocks stay where they are from frame to frame.
double bonusRnd(num i) {
  final s = sin(i * 127.1 + 3.7) * 43758.5453;
  return s - s.floorToDouble();
}

/// The bonus round sky: a deep purple one with stars, a big golden moon, far
/// floating islands and near hills, drawn behind the world. Ported from the
/// approved mockup. The stars and hills slide by as the camera moves; the stars
/// twinkle on their own clock.
class BonusBackdrop extends PositionComponent
    with HasGameReference<ChronoGame> {
  BonusBackdrop() : super(priority: -10);

  double _t = 0;
  Size _shaderFor = Size.zero;
  Paint? _sky, _moonGlow, _moon, _warm;
  final Paint _p = Paint();

  @override
  Future<void> onLoad() async {
    size = game.size.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  void _buildShaders(Size s, double ground) {
    if (_shaderFor == s && _sky != null) return;
    _shaderFor = s;
    _sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0D0626),
          Color(0xFF2B1262),
          Color(0xFF6A2A7E),
          Color(0xFFC1743F),
        ],
        stops: [0, .45, .8, 1],
      ).createShader(Rect.fromLTWH(0, 0, s.width, ground));
    final mx = s.width * .74, my = 190.0;
    _moonGlow = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x80FFD66E), Color(0x00FFD66E)],
      ).createShader(Rect.fromCircle(center: Offset(mx, my), radius: 250));
    _moon = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-.3, -.3),
        colors: [Color(0xFFFFF3C0), Color(0xFFF1B84C)],
      ).createShader(Rect.fromCircle(center: Offset(mx, my), radius: 96));
    _warm = Paint()..color = const Color(0x29FFBE50);
  }

  @override
  void render(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;
    final ground = game.groundY;
    _buildShaders(Size(w, h), ground);
    final camX = game.cameraLeftEdgeX;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _sky!);

    // Stars: each slides at its own slow speed and twinkles.
    final span = w + 300;
    for (var i = 0; i < 80; i++) {
      final x = ((bonusRnd(i) * span - camX * (.04 + bonusRnd(i + 3) * .05)) %
                      span +
                  span) %
              span -
          150;
      final y = bonusRnd(i + 70) * ground * .6;
      if (x < 0 || x > w) continue;
      final tw = .45 + .55 * sin(_t * (1.4 + bonusRnd(i + 9) * 2) + i).abs();
      final r = 1.8 + bonusRnd(i + 20) * 3;
      _p.color = Color.fromRGBO(255, 244, 200, tw);
      canvas.drawRect(Rect.fromLTWH(x, y, r, r), _p);
      if (i % 9 == 0) _sparkle(canvas, x, y, 11, tw * .8);
    }

    // The big golden moon.
    final mx = w * .74, my = 190.0;
    canvas.drawCircle(Offset(mx, my), 250, _moonGlow!);
    canvas.drawCircle(Offset(mx, my), 94, _moon!);
    _p.color = const Color(0x59B46E1E);
    for (final c in const [
      (-28.0, -16.0, 19.0),
      (30.0, 18.0, 15.0),
      (-20.0, 24.0, 10.0),
    ]) {
      canvas.drawCircle(Offset(mx + c.$1, my + c.$2), c.$3, _p);
    }

    // Far floating islands, two rows.
    for (var k = -1; k < 4; k++) {
      for (var j = 0; j < 2; j++) {
        final x = k * 1500.0 + j * 760 + 240 - (camX * .2) % 1500;
        final y = ground * .33 + j * 100 + sin(_t * .8 + j * 2 + k) * 10;
        final iw = 190.0 + j * 76;
        if (x < -300 || x > w + 300) continue;
        _p.color = const Color(0xFF2A1458);
        canvas.drawPath(
          Path()
            ..moveTo(x - iw / 2, y)
            ..lineTo(x + iw / 2, y)
            ..lineTo(x + iw * .2, y + 72 + j * 16)
            ..lineTo(x - iw * .1, y + 110 + j * 20)
            ..lineTo(x - iw * .35, y + 60)
            ..close(),
          _p,
        );
        _p.color = const Color(0xFF3D2078);
        canvas.drawRect(Rect.fromLTWH(x - iw / 2, y - 8, iw, 12), _p);
        _p.color = const Color(0xFFFFC83D);
        canvas.drawPath(
          Path()
            ..moveTo(x - 9, y - 8)
            ..lineTo(x, y - 42 - j * 12)
            ..lineTo(x + 10, y - 8)
            ..close(),
          _p,
        );
      }
    }

    // Near hills and ruins.
    _p.color = const Color(0xFF3A1A6A);
    final hills = Path()..moveTo(0, h);
    for (var x = 0.0; x <= w; x += 12) {
      final wx = x + camX * .45;
      final bump = (wx / 300).floor() % 3 == 0 ? -28.0 : 0.0;
      hills.lineTo(
          x,
          ground -
              130 -
              sin(wx * .0055) * 56 -
              sin(wx * .0135 + 1) * 26 +
              bump);
    }
    hills
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(hills, _p);
    canvas.drawRect(Rect.fromLTWH(0, ground - 100, w, 100), _warm!);
  }

  void _sparkle(Canvas canvas, double x, double y, double r, double a) {
    _p.color = Color.fromRGBO(255, 233, 160, a);
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final rr = i.isOdd ? r * .25 : r;
      final an = i * pi / 4;
      final px = x + cos(an) * rr, py = y + sin(an) * rr;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, _p);
  }
}

/// The stone floor of the bonus round: violet brick with a gold edge and gold
/// crystals standing on it, from the left end of the map to the right. No pits.
class BonusGroundComponent extends PositionComponent
    with HasGameReference<ChronoGame> {
  final double length;
  BonusGroundComponent({required this.length}) : super(priority: -2);

  final Paint _p = Paint();
  final Paint _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = const Color(0x80100528);

  @override
  Future<void> onLoad() async {
    position = Vector2(0, game.groundY);
    size = Vector2(length, game.size.y - game.groundY);
  }

  @override
  void render(Canvas canvas) {
    final left = max(0.0, game.cameraLeftEdgeX - 40);
    final right = min(length, game.cameraRightEdgeX + 40);
    if (right <= left) return;
    final bandH = size.y;
    _p.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF4B2A82), Color(0xFF241048)],
    ).createShader(Rect.fromLTWH(left, 0, right - left, bandH));
    canvas.drawRect(Rect.fromLTRB(left, 0, right, bandH), _p);
    _p.shader = null;
    // Gold edge.
    _p.color = const Color(0xFFF2C14E);
    canvas.drawRect(Rect.fromLTRB(left, 0, right, 10), _p);
    _p.color = const Color(0xFFFFE9A0);
    canvas.drawRect(Rect.fromLTRB(left, 0, right, 4), _p);
    // Brick joints.
    final first = (left / 128).floor() * 128.0;
    final joints = Path();
    for (var x = first; x < right; x += 128) {
      joints
        ..moveTo(x, 10)
        ..lineTo(x, 36)
        ..moveTo(x + 64, 36)
        ..lineTo(x + 64, bandH);
    }
    joints
      ..moveTo(left, 36)
      ..lineTo(right, 36);
    canvas.drawPath(joints, _line);
    // Gold crystals standing on the edge.
    for (var i = 0; i < 120; i++) {
      final x = 150 + i * 61 + bonusRnd(i) * 30;
      if (x < left - 20 || x > right + 20) continue;
      final hh = 22 + bonusRnd(i + 4) * 26;
      _p.color = const Color(0xFFE9B43C);
      canvas.drawPath(
        Path()
          ..moveTo(x - 9, 2)
          ..lineTo(x, -hh)
          ..lineTo(x + 11, 2)
          ..close(),
        _p,
      );
      _p.color = const Color(0xFFFFF0A8);
      canvas.drawRect(Rect.fromLTWH(x - 2, -hh + 7, 4, hh * .5), _p);
    }
  }
}

/// A floating stone slab: violet stone with a gold top and a hanging rock
/// underneath. It is a `TilePlatformComponent` for everything that matters
/// (where the hero lands, the hit box, the list the player checks) and draws
/// itself differently.
class BonusPlatformComponent extends TilePlatformComponent {
  BonusPlatformComponent({
    required super.widthInTiles,
    required super.surfaceY,
    required Vector2 super.spawnPosition,
  });

  final Paint _p = Paint();

  @override
  void render(Canvas canvas) {
    final w = size.x;
    // The rock hanging under it.
    _p.color = const Color(0xFF2D1A52);
    final rock = Path()..moveTo(8, 30);
    for (var i = 0; i <= 8; i++) {
      final px = 8 + (w - 16) * i / 8;
      final d = (i.isOdd ? 26.0 : 8.0) + bonusRnd(i + position.x) * 28;
      rock.lineTo(px, 30 + d);
    }
    rock
      ..lineTo(w - 8, 30)
      ..close();
    canvas.drawPath(rock, _p);
    // The slab.
    final slab = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, 32), const Radius.circular(6));
    _p.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF6A45A8), Color(0xFF43286F)],
    ).createShader(Rect.fromLTWH(0, 0, w, 32));
    canvas.drawRRect(slab, _p);
    _p.shader = null;
    _p.color = const Color(0xFFF2C14E);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, 8), _p);
    _p.color = const Color(0xFFFFE9A0);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, 3), _p);
    _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0x7314083A);
    final joints = Path();
    for (var x = 72.0; x < w - 20; x += 72) {
      joints
        ..moveTo(x, 8)
        ..lineTo(x, 32);
    }
    canvas.drawPath(joints, _p);
    _p.style = PaintingStyle.fill;
  }
}
