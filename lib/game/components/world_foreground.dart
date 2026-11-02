import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../backdrop/backdrop_art.dart';
import '../backdrop/era_look.dart';
import '../chrono_game.dart';

/// What passes in front of the player: dark leaves and vines hanging from the top,
/// tufts of grass along the bottom, a thin bank of mist, a wash of the era's colour and
/// darker corners. It scrolls faster than the ground, which is what gives the scene
/// its depth. Drawn over the world but under the on-screen controls, and it takes no
/// taps.
///
/// With the phone's "remove animations" on, the grass stops swaying and the mist stops
/// drifting; the leaves and grass still scroll with the camera.
class WorldForeground extends PositionComponent
    with HasGameReference<ChronoGame> {
  WorldForeground({this.eraId, this.animate}) : super(priority: -5);

  /// null: the game's current era.
  final String? eraId;

  /// null: follow the phone's setting.
  final bool? animate;

  /// Scroll speeds, as a fraction of the world's own speed (more than 1: nearer than
  /// the ground).
  static const double leavesSpeed = 1.2;
  static const double grassSpeed = 1.3;

  /// Gap between grass tufts, and the tallest one, in screen units. The ground band
  /// is 60 high, so the grass stays inside it and never covers the player's feet.
  static const double tuftGap = 22;
  static const double tuftMax = 46;

  late EraLook look;
  ui.Image? _leaves;
  bool _moving = true;
  double _t = 0;
  double _camX = 0;
  Size _shaderSize = Size.zero;
  Paint? _vignette, _bank;
  final Paint _fill = Paint();
  final Paint _tile = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;

  @override
  Future<void> onLoad() async {
    look = EraLook.of(eraId ?? game.currentEra);
    _moving = animate ??
        !ui.PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    _leaves = await foregroundTopPixels(look).toImage();
    size = game.size.clone();
    position = Vector2.zero();
  }

  @override
  void onRemove() {
    _leaves?.dispose();
    _leaves = null;
    super.onRemove();
  }

  void _shaders() {
    final w = size.x, h = size.y;
    if (_shaderSize == Size(w, h)) return;
    _shaderSize = Size(w, h);
    _vignette = Paint()
      ..shader = ui.Gradient.radial(
          Offset(w / 2, h / 2),
          math.max(w, h) * .62,
          [const Color(0x00080410), const Color(0x8C080410)],
          const [.45, 1]);
    _bank = Paint()
      ..shader = ui.Gradient.linear(Offset(0, h * .72), Offset(0, h), [
        Color(look.mist).withValues(alpha: 0),
        Color(look.mist).withValues(alpha: .20),
      ]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_leaves == null) return;
    if (size.x != game.size.x || size.y != game.size.y) size = game.size.clone();
    _camX = game.cameraLeftEdgeX;
    if (_moving) _t += dt;
  }

  @override
  void render(ui.Canvas canvas) {
    final leaves = _leaves;
    if (leaves == null) return;
    _shaders();
    final w = size.x, h = size.y;

    canvas.drawRect(Rect.fromLTWH(0, h * .72, w, h * .28), _bank!);
    _fill.color = Color(look.mist).withValues(alpha: .10);
    final span = w + 700;
    for (var i = 0; i < 4; i++) {
      final x = (((i * 450 - _t * 26 - _camX * .45) % span) + span) % span - 350;
      canvas.drawOval(
          Rect.fromCenter(center: Offset(x, h * (.88 + (i % 2) * .03)), width: 560, height: 60),
          _fill);
    }

    _drawLeaves(canvas, leaves, w, h);
    _drawGrass(canvas, w, h);

    _fill.color = Color(look.grade);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _fill);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _vignette!);
  }

  void _drawLeaves(ui.Canvas canvas, ui.Image img, double w, double h) {
    final s = h / kTileH;
    final tw = kTileW * s, th = 40 * s;
    final src = Rect.fromLTWH(0, 0, kTileW.toDouble(), 40);
    _tile.color = const Color(0xEBFFFFFF);
    var x = -((_camX * leavesSpeed) % tw);
    if (x > 0) x -= tw;
    while (x < w) {
      canvas.drawImageRect(
          img, src, Rect.fromLTWH(x.roundToDouble(), -th * .15, tw + 1, th), _tile);
      x += tw;
    }
  }

  /// Tufts along the bottom edge: dark triangles, each with its own height, leaning
  /// a little with the wind. All in one path, so it is one draw call.
  void _drawGrass(ui.Canvas canvas, double w, double h) {
    final path = Path();
    final first = ((_camX * grassSpeed) / tuftGap).floor();
    final count = (w / tuftGap).ceil() + 3;
    for (var i = 0; i < count; i++) {
      final n = first + i;
      final x = n * tuftGap - _camX * grassSpeed;
      final height = 22 + _hash(n) * (tuftMax - 22);
      final sway = _moving ? math.sin(_t * 2.2 + n * .8) * 6 : 0;
      path
        ..moveTo(x, h)
        ..lineTo(x + 10 + sway, h - height)
        ..lineTo(x + 22, h)
        ..close();
    }
    canvas.drawPath(path, _fill..color = Color(look.foreground));
  }

  /// A steady number from 0 to 1 for each tuft, so a tuft keeps its height as it
  /// scrolls past.
  static double _hash(int n) {
    final v = math.sin(n * 127.1 + 311.7) * 43758.5453;
    return v - v.floorToDouble();
  }
}
