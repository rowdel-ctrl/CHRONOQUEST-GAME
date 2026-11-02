import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../backdrop/backdrop_art.dart';
import '../backdrop/era_look.dart';
import '../backdrop/pixel_art.dart';
import '../chrono_game.dart';

/// The world behind the player: sky, sun and drifting clouds, far hills, distant
/// buildings of the era, three rows of trees, slanting light, mist and things in the
/// air (fireflies, petals, embers). Each row scrolls at its own speed from how far
/// the camera actually moved, so it can never drift out of step with the ground.
///
/// Replaces the old four-picture `ParallaxBackground`. Everything is drawn in code
/// from the numbers in [EraLook] (nothing to download), and the scenery is a handful
/// of small pixel pictures made once when the level opens.
///
/// With the phone's "remove animations" on, the clouds, light, mist and particles stand
/// still. The rows still scroll with the camera: that is the game moving, not a
/// decoration.
class WorldBackdrop extends PositionComponent with HasGameReference<ChronoGame> {
  WorldBackdrop({this.eraId, this.animate}) : super(priority: -10);

  /// null: the game's current era.
  final String? eraId;

  /// null: follow the phone's setting.
  final bool? animate;

  /// How fast each row scrolls, as a fraction of the world's own speed.
  static const double hillsSpeed = .03;
  static const double farSpeed = .12;
  static const double sceneSpeed = .20;
  static const double midSpeed = .34;
  static const double nearSpeed = .58;

  late EraLook look;
  EraArt? _art;
  bool _moving = true;
  double _t = 0;
  double _camX = 0;
  final List<_Mote> _motes = [];
  Size _shaderSize = Size.zero;

  Paint? _sky, _sunGlow, _ray, _mist;
  final Paint _tile = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;
  final Paint _fill = Paint();

  @override
  Future<void> onLoad() async {
    look = EraLook.of(eraId ?? game.currentEra);
    _moving = animate ??
        !ui.PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    _art = await buildEraArt(look);
    size = game.size.clone();
    position = Vector2.zero();
    final rnd = Rand(97);
    for (var i = 0; i < 34; i++) {
      _motes.add(_Mote(rnd.next(), rnd.next(), rnd.range(0, 6.28),
          rnd.range(.4, 1.2), rnd.range(1, 3), rnd.range(.4, 1.1)));
    }
  }

  @override
  void onRemove() {
    _art?.dispose();
    _art = null;
    super.onRemove();
  }

  /// Builds the sky, glow, light and mist paints for the current screen size.
  void _shaders() {
    final w = size.x, h = size.y;
    if (_shaderSize == Size(w, h)) return;
    _shaderSize = Size(w, h);
    _sky = Paint()
      ..shader = ui.Gradient.linear(Offset.zero, Offset(0, h * .8),
          [Color(look.skyTop), Color(look.skyBottom)]);
    final sun = Offset(w * look.sunX, h * look.sunY);
    _sunGlow = Paint()
      ..shader = ui.Gradient.radial(sun, h * look.sunRadius * 4.4,
          [Color(look.sun).withValues(alpha: .55), const Color(0x00000000)]);
    _ray = Paint()
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.linear(Offset.zero, Offset(0, h * .8), [
        Color(look.ray).withValues(alpha: look.rayAlpha),
        Color(look.ray).withValues(alpha: 0)
      ]);
    _mist = Paint()
      ..shader = ui.Gradient.linear(Offset(0, h * .5), Offset(0, h * .93), [
        Color(look.mist).withValues(alpha: 0),
        Color(look.mist).withValues(alpha: .26),
        Color(look.mist).withValues(alpha: 0),
      ], const [
        0,
        .6,
        1
      ]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_art == null) return;
    if (size.x != game.size.x || size.y != game.size.y) size = game.size.clone();
    _camX = game.cameraLeftEdgeX;
    if (!_moving) return;
    _t += dt;
    final w = size.x, h = size.y;
    for (final m in _motes) {
      m.step(dt, _t, look.particles, w, h);
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final art = _art;
    if (art == null) return;
    _shaders();
    final w = size.x, h = size.y;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _sky!);
    _drawSun(canvas, w, h);
    _drawClouds(canvas, w, h);

    final speeds = [hillsSpeed, farSpeed, sceneSpeed, midSpeed, nearSpeed];
    final layers = art.layers;
    for (var i = 0; i < layers.length; i++) {
      _drawLayer(canvas, layers[i], speeds[i], w, h);
    }
    _drawRays(canvas, w, h);
    canvas.drawRect(Rect.fromLTWH(0, h * .5, w, h * .43), _mist!);
    _drawMistPuffs(canvas, w, h);
    _drawMotes(canvas, w, h);
  }

  void _drawLayer(ui.Canvas canvas, ui.Image img, double speed, double w, double h) {
    final tw = kTileW * (h / kTileH);
    final src = Rect.fromLTWH(0, 0, kTileW.toDouble(), kTileH.toDouble());
    var x = -((_camX * speed) % tw);
    if (x > 0) x -= tw;
    while (x < w) {
      canvas.drawImageRect(
          img, src, Rect.fromLTWH(x.roundToDouble(), 0, tw + 1, h), _tile);
      x += tw;
    }
  }

  void _drawSun(ui.Canvas canvas, double w, double h) {
    final c = Offset(w * look.sunX, h * look.sunY);
    final r = h * look.sunRadius;
    canvas.drawCircle(c, r * 4.4, _sunGlow!);
    canvas.drawCircle(c, r, _fill..color = Color(look.sun));
  }

  void _drawClouds(ui.Canvas canvas, double w, double h) {
    _fill.color = const Color(0x38FFFFFF);
    final span = w + 480;
    for (var i = 0; i < 4; i++) {
      final cx = (((i * 420 - _camX * .02 - _t * 8) % span) + span) % span - 240;
      final cy = h * (.12 + i * .08);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 300, height: 40), _fill);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx + 70, cy - 14), width: 170, height: 34), _fill);
    }
  }

  void _drawRays(ui.Canvas canvas, double w, double h) {
    for (var i = 0; i < 5; i++) {
      final base = w * (.1 + i * .2);
      final sway = _moving ? math.sin(_t * .35 + i * 1.7) * 34 : 0;
      final x = base + sway - ((_camX * .06) % 90);
      final width = 80.0 + (i % 3) * 34;
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + width, 0)
        ..lineTo(x + width - h * .3, h * .8)
        ..lineTo(x - h * .3, h * .8)
        ..close();
      canvas.drawPath(path, _ray!);
    }
  }

  void _drawMistPuffs(ui.Canvas canvas, double w, double h) {
    _fill.color = Color(look.mist).withValues(alpha: .13);
    final span = w + 700;
    for (var i = 0; i < 5; i++) {
      final x = (((i * 400 - _t * 20 - _camX * .25) % span) + span) % span - 350;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, h * (.68 + (i % 2) * .03)), width: 520, height: 56),
          _fill);
    }
  }

  void _drawMotes(ui.Canvas canvas, double w, double h) {
    for (final m in _motes) {
      m.paint(canvas, _t, look, w, h, _fill, _moving);
    }
  }
}

/// One thing drifting in the air.
class _Mote {
  _Mote(this.fx, this.fy, this.phase, this.speed, this.size, this.depth) {
    x = fx;
    y = fy;
  }

  final double fx, fy, phase, speed, size, depth;

  /// Position as a fraction of the screen.
  double x = 0, y = 0;

  void step(double dt, double t, ParticleKind kind, double w, double h) {
    x -= dt * .03 * depth;
    switch (kind) {
      case ParticleKind.fireflies:
        x += math.sin(t * speed + phase) * dt * .012;
        y += math.cos(t * speed * 1.3 + phase) * dt * .02;
      case ParticleKind.petals:
      case ParticleKind.leaves:
        y += (.03 + size * .012) * dt;
        x += math.sin(t * speed * 2 + phase) * dt * .02 - dt * .02;
      case ParticleKind.embers:
        y -= (.025 + size * .02) * dt;
        x += math.sin(t * speed + phase) * dt * .014;
      case ParticleKind.dust:
        y += math.sin(t * speed + phase) * dt * .01;
    }
    if (x < -.02) x = 1.02;
    if (y > 1.02) y = -.02;
    if (y < -.02) y = 1.02;
  }

  void paint(ui.Canvas canvas, double t, EraLook look, double w, double h,
      Paint paint, bool moving) {
    final px = x * w, py = y * h;
    final color = Color(look.particleColor);
    final twinkle = moving ? .35 + .65 * math.sin(t * speed * 1.7 + phase).abs() : .7;
    switch (look.particles) {
      case ParticleKind.fireflies:
        paint.color = color.withValues(alpha: .18 * twinkle);
        canvas.drawCircle(Offset(px, py), 18 * depth + 6, paint);
        paint.color = const Color(0xFFFFFFC8).withValues(alpha: twinkle);
        canvas.drawRect(Rect.fromCenter(center: Offset(px, py), width: 5, height: 5), paint);
      case ParticleKind.petals:
      case ParticleKind.leaves:
        paint.color = color.withValues(alpha: .85);
        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(moving ? t * speed + phase : phase);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 14 * depth, height: 7 * depth), paint);
        canvas.restore();
      case ParticleKind.embers:
        if (size > 1.8) {
          paint.color = color.withValues(alpha: .25 * twinkle);
          canvas.drawCircle(Offset(px, py), 14, paint);
          paint.color = const Color(0xFFFFD890).withValues(alpha: twinkle);
          canvas.drawRect(Rect.fromCenter(center: Offset(px, py), width: 5, height: 5), paint);
        } else {
          paint.color = const Color(0xFFD2D2D2).withValues(alpha: .35 * twinkle);
          canvas.drawRect(Rect.fromLTWH(px, py, 4, 4), paint);
        }
      case ParticleKind.dust:
        paint.color = color.withValues(alpha: .35 * twinkle);
        canvas.drawRect(Rect.fromCenter(center: Offset(px, py), width: 4 * depth + 1, height: 4 * depth + 1), paint);
    }
  }
}
