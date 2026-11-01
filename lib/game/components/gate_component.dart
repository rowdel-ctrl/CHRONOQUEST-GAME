import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/combat_constants.dart';
import '../chrono_game.dart';

/// An era wall turned into a knowledge-gate (GAMEPLAY-V2.md Section 6).
///
/// A gate blocks the full height of the corridor and cannot be jumped. Since
/// 2026-10-04 it asks **no question of its own**: each level has one, at the
/// exit, and it opens by itself the moment the student reaches it with every
/// artifact in the level answered (right or wrong). Until then it only tells
/// them how many artifacts are left. The questions all live on the artifacts.
///
/// Replaces the old `WallComponent`, which used the same art but simply
/// dealt contact damage and could be walked through. A hazard that hurts
/// you and a gate that stops you are different objects; keeping both would
/// have meant two things made of the same sprite with opposite rules.
///
/// **Drawn in code, not from a sprite or the ground tileset** (2026-10-04
/// playtest: "the visual of the gate should be replaced"). Redrawn 2026-10-29
/// as an old stone gate ("Option A" of the gate mockup): a stepped stone front
/// with an arched doorway, an iron grille, a wax seal on the keystone and a
/// torch on each pillar. Its state reads at a glance: a red seal and a shut
/// grille while artifacts remain, a gold seal once every artifact is answered,
/// and, after [GateReveal] (gate_reveal.dart) has lifted the grille, warm light
/// in the doorway. The gate does not crumble: it stays, open, and the level
/// ends when the student walks into the doorway. Extends `PositionComponent with
/// HasPaint` so [render] can scale every colour by the paint's alpha.
class GateComponent extends PositionComponent
    with HasGameReference<ChronoGame>, HasPaint, CollisionCallbacks {
  /// World x this gate was placed at by the spawner.
  final double worldX;

  /// True once the grille is all the way up: the gate no longer blocks, and the
  /// student walks into the doorway.
  bool get opened => doorOpen >= 1;

  /// True once the student has walked into the open doorway, which is what ends
  /// the level (ChronoGame.enterEndGate).
  bool entered = false;

  /// Behind the student (whose priority is the default 0), so the hero is drawn
  /// in front of the gate while walking up to it and into its doorway.
  GateComponent({required this.worldX, this.isLevelExit = false})
      : super(priority: -1);

  /// The x the player is held at while this gate stands.
  double get blockX => position.x - CombatConstants.gateStandoff;

  /// The gate is sized in whole tiles of this many units, matching the
  /// platforms and ground beside it.
  static const double tileSize = 24;

  /// Seconds elapsed, for the torches, the seal's glow and the dust.
  double _t = 0;

  /// How far the grille has been lifted, 0 (shut) to 1 (up), set by
  /// [GateReveal] (gate_reveal.dart) while the camera is on the gate. It stays
  /// at 1 afterwards: the student walks into a doorway that is already open.
  double doorOpen = 0;

  /// Stone colour per era, so the gates match their surroundings.
  static const Map<String, Color> _stone = {
    'pre-colonial': Color(0xFF6E7B62),
    'spanish': Color(0xFF8A7F70),
    'nationalism': Color(0xFF7A7585),
    'american': Color(0xFF7C8591),
    'ww2': Color(0xFF6B7078),
    'modern': Color(0xFF787A8C),
  };

  static const Color _interior = Color(0xFF0B0E14);
  static const Color _iron = Color(0xFF3A4150);
  static const Color _ironEdge = Color(0xFF10141B);
  static const Color _brassDim = Color(0xFF8A6A26);
  static const Color _brass = Color(0xFFE6C46A);
  static const Color _glow = Color(0xFFFFF0B0);
  static const Color _glowEdge = Color(0xFFF0B84A);

  @override
  Future<void> onLoad() async {
    final cols = (CombatConstants.gateWidth / tileSize).ceil();
    final rows = (CombatConstants.gateHeight / tileSize).ceil();

    // Snap to whole tiles so nothing is ever part-drawn.
    size = Vector2(cols * tileSize, rows * tileSize);
    position = Vector2(worldX, game.groundY - size.y);

    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  /// The parts of the gate that never change while it stands: the stone front
  /// with its brick courses and steps, and the dark doorway. Recorded once and
  /// replayed every frame, so the per-frame work is the grille, the light, the
  /// seal, the torches and the dust. Built lazily because the stone colour
  /// depends on the era, which is known once the gate is mounted.
  ui.Picture? _body;

  /// The drawing was made on a 120 x 150 grid; this is its scale in game units.
  /// Above the arch's springing line (y 80 of the grid) it keeps that scale;
  /// below it the pillars stretch so the gate is as tall as the corridor needs.
  double get _s => size.x / 120;
  double _gx(double v) => v * _s;
  double _gy(double v) {
    const spring = 80.0, top = 22.0;
    final upper = (spring - top) * _s;
    if (v <= spring) return (v - top) * _s;
    return upper + (v - spring) * (size.y - upper) / (142 - spring);
  }

  /// The stepped stone front: a wide base, two steps and a raised centre.
  Path _frontPath() {
    final h = size.y;
    return Path()
      ..moveTo(_gx(6), h)
      ..lineTo(_gx(6), _gy(54))
      ..lineTo(_gx(18), _gy(54))
      ..lineTo(_gx(18), _gy(38))
      ..lineTo(_gx(34), _gy(38))
      ..lineTo(_gx(34), _gy(22))
      ..lineTo(_gx(86), _gy(22))
      ..lineTo(_gx(86), _gy(38))
      ..lineTo(_gx(102), _gy(38))
      ..lineTo(_gx(102), _gy(54))
      ..lineTo(_gx(114), _gy(54))
      ..lineTo(_gx(114), h)
      ..close();
  }

  /// The arched doorway, from the ground up to the curve under the frieze.
  Path _doorwayPath() {
    final h = size.y;
    final r = 28 * _s, cx = _gx(60), cy = _gy(80);
    return Path()
      ..moveTo(cx - r, h)
      ..lineTo(cx - r, cy)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r), pi, pi, false)
      ..lineTo(cx + r, h)
      ..close();
  }

  ui.Picture _recordBody() {
    final w = size.x, h = size.y;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    Paint p(Color c, {bool smooth = false}) => Paint()
      ..color = c
      ..isAntiAlias = smooth;

    final stone = _stone[game.currentEra] ?? const Color(0xFF7A7585);
    final dark = Color.lerp(stone, Colors.black, 0.4)!;
    final darker = Color.lerp(stone, Colors.black, 0.62)!;
    final light = Color.lerp(stone, Colors.white, 0.3)!;

    // The stone front, lit from the left.
    final front = _frontPath();
    canvas.drawPath(
      front,
      Paint()
        ..isAntiAlias = true
        ..shader = ui.Gradient.linear(
          Offset(_gx(6), 0),
          Offset(_gx(114), 0),
          [light, stone, dark],
          const [0, 0.55, 1],
        ),
    );

    // Brick courses, staggered, kept inside the front.
    canvas.save();
    canvas.clipPath(front);
    final mortar = p(dark.withValues(alpha: 0.65));
    var course = 0;
    for (var y = _gy(30); y < h + 17; y += 17, course++) {
      canvas.drawRect(Rect.fromLTWH(0, y, w, 1.4), mortar);
      for (var x = course.isEven ? 10.0 : 23.0; x < w; x += 26) {
        canvas.drawRect(Rect.fromLTWH(x, y - 17, 1.4, 17), mortar);
      }
    }
    canvas.restore();

    // The edge of each step catches the light.
    final trim = p(light.withValues(alpha: 0.7));
    canvas.drawRect(
        Rect.fromLTRB(_gx(18), _gy(54) - 1, _gx(34), _gy(54) + 0.4), trim);
    canvas.drawRect(
        Rect.fromLTRB(_gx(86), _gy(54) - 1, _gx(102), _gy(54) + 0.4), trim);
    canvas.drawRect(
        Rect.fromLTRB(_gx(34), _gy(38) - 1, _gx(86), _gy(38) + 0.4), trim);
    canvas.drawPath(
      front,
      p(darker, smooth: true)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    // The dark doorway. The grille, the light and the trim are per frame.
    canvas.drawPath(_doorwayPath(), p(_interior, smooth: true));
    return recorder.endRecording();
  }

  /// Draws the gate. Everything is multiplied by the paint's alpha so
  /// [open]'s fade-out takes the whole gate with it.
  ///
  /// Does nothing while the gate is off screen. It is drawn for the whole
  /// level otherwise, and the level's far end is not worth paying for from the
  /// first screen.
  @override
  void render(Canvas canvas) {
    if (position.x + size.x < game.cameraLeftEdgeX - 64 ||
        position.x > game.cameraRightEdgeX + 64) {
      return;
    }
    final fade = paint.color.a;
    Paint p(Color c, {bool smooth = false}) => Paint()
      ..color = c.withValues(alpha: c.a * fade)
      ..isAntiAlias = smooth;
    Paint line(Color c, double width) => p(c, smooth: true)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    final unlocked = requirementMet;
    final pulse = 0.5 + 0.5 * sin(_t * (unlocked ? 4 : 2));

    // The still parts, replayed from the recording. While fading out they are
    // drawn into a layer so the whole gate fades together.
    final body = _body ??= _recordBody();
    if (fade < 1) {
      canvas.saveLayer(Offset.zero & size.toSize(),
          Paint()..color = Colors.white.withValues(alpha: fade));
      canvas.drawPicture(body);
      canvas.restore();
    } else {
      canvas.drawPicture(body);
    }

    // Brass turns from dull to bright as the gate wakes up.
    final brass = Color.lerp(_brassDim, _brass,
        ((unlocked ? 0.5 : 0) + 0.5 * doorOpen).clamp(0.0, 1.0))!;

    _paintFrieze(canvas, p, line, brass);
    _paintDoorway(canvas, p, line, brass, unlocked, pulse);
    _paintSeal(canvas, p, line, unlocked, pulse);
    for (final x in [_gx(19), _gx(101)]) {
      _paintTorch(canvas, p, x);
    }
    if (doorOpen > 0 && doorOpen < 1) _paintDust(canvas, p);
  }

  void _paintFrieze(
    Canvas canvas,
    Paint Function(Color, {bool smooth}) p,
    Paint Function(Color, double) line,
    Color brass,
  ) {
    final l = line(brass, 1.4);
    canvas.drawLine(Offset(_gx(38), _gy(27)), Offset(_gx(82), _gy(27)), l);
    canvas.drawLine(Offset(_gx(38), _gy(46)), Offset(_gx(82), _gy(46)), l);
  }

  /// The grille, the glow behind it, and the brass trim round the doorway.
  void _paintDoorway(
    Canvas canvas,
    Paint Function(Color, {bool smooth}) p,
    Paint Function(Color, double) line,
    Color brass,
    bool unlocked,
    double pulse,
  ) {
    final w = size.x, h = size.y, s = _s;
    final fade = paint.color.a;
    final doorway = _doorwayPath();
    final left = _gx(32), right = _gx(88), top = _gy(50);

    canvas.save();
    canvas.clipPath(doorway);

    // What is behind the grille: embers while shut, a faint gold once every
    // artifact is answered, and warm light as the grille goes up.
    final lightAlpha =
        doorOpen > 0 ? doorOpen : (unlocked ? 0.18 + 0.12 * pulse : 0.0);
    final back = Rect.fromLTRB(left, top, right, h);
    if (lightAlpha > 0) {
      canvas.drawRect(
        back,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(w / 2, h - 12 * s),
            (right - left) * 1.25,
            [
              _glow.withValues(alpha: fade * lightAlpha),
              _glowEdge.withValues(alpha: fade * 0.55 * lightAlpha),
            ],
          ),
      );
    } else {
      canvas.drawRect(
        back,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(w / 2, h),
            (right - left) * 1.1,
            [
              const Color(0xFF7A2A22)
                  .withValues(alpha: fade * (0.45 + 0.15 * pulse)),
              const Color(0xFF0B0E14).withValues(alpha: 0),
            ],
          ),
      );
    }

    // The grille rides up into the arch, leaving its tips hanging at the top.
    final lift = doorOpen * (h - top - 16 * s);
    canvas.translate(0, -lift);
    final bar = p(_iron);
    final edge = p(_ironEdge.withValues(alpha: 0.9));
    final shine = p(const Color(0xFF6E7888).withValues(alpha: 0.6));
    final barW = 3 * s;
    for (var x = _gx(36); x <= _gx(84) + 0.1; x += 8 * s) {
      final r = Rect.fromLTWH(x - barW / 2, top, barW, h - top + 4);
      canvas.drawRect(r, bar);
      canvas.drawRect(Rect.fromLTWH(r.left, r.top, 0.9, r.height), shine);
      canvas.drawRect(Rect.fromLTWH(r.right - 0.8, r.top, 0.8, r.height), edge);
      // The pointed tip.
      canvas.drawPath(
        Path()
          ..moveTo(r.left, h + 4)
          ..lineTo(r.right, h + 4)
          ..lineTo(x, h + 4 + 5 * s)
          ..close(),
        bar,
      );
    }
    for (final fy in const [72.0, 98.0, 124.0]) {
      final y = _gy(fy);
      canvas.drawRect(Rect.fromLTWH(left - 2, y, right - left + 4, barW), bar);
      canvas.drawRect(Rect.fromLTWH(left - 2, y, right - left + 4, 0.9), shine);
    }
    canvas.restore();

    // The brass round the doorway.
    canvas.drawPath(doorway, line(brass, 2.4 * s));
  }

  /// The wax seal on the keystone: red and locked, gold once every artifact is
  /// answered, and gold with a tick once the grille is up.
  void _paintSeal(
    Canvas canvas,
    Paint Function(Color, {bool smooth}) p,
    Paint Function(Color, double) line,
    bool unlocked,
    double pulse,
  ) {
    final s = _s;
    final c = Offset(_gx(60), _gy(36.5));
    final r = 10.5 * s;
    final gold = unlocked;

    if (unlocked && doorOpen < 0.5) {
      canvas.drawCircle(c, r + 5 * s,
          p(_brass.withValues(alpha: 0.2 + 0.25 * pulse), smooth: true));
    }
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..isAntiAlias = true
        ..shader = ui.Gradient.radial(
          c.translate(-r * 0.3, -r * 0.35),
          r * 1.4,
          gold
              ? [
                  const Color(0xFFFFF3C2).withValues(alpha: paint.color.a),
                  const Color(0xFFD9B04F).withValues(alpha: paint.color.a)
                ]
              : [
                  const Color(0xFFD8584F).withValues(alpha: paint.color.a),
                  const Color(0xFF8A2018).withValues(alpha: paint.color.a)
                ],
        ),
    );
    canvas.drawCircle(
        c,
        r,
        line(
            gold ? const Color(0xFF6B4F16) : const Color(0xFF4A100C), 1.4 * s));

    if (doorOpen >= 0.5) {
      final tick = Path()
        ..moveTo(c.dx - 5 * s, c.dy + 0.5 * s)
        ..lineTo(c.dx - 1.6 * s, c.dy + 4 * s)
        ..lineTo(c.dx + 5 * s, c.dy - 4.5 * s);
      canvas.drawPath(tick, line(const Color(0xFF2B1D07), 2.2 * s));
      return;
    }
    // A small padlock: shut while artifacts remain, with the shackle lifted
    // once they are all answered.
    final lockInk = gold ? const Color(0xFF2B1D07) : const Color(0xFFFFE9D0);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: c.translate(0, 1.5 * s), width: 10 * s, height: 8 * s),
      Radius.circular(1.5 * s),
    );
    final shackle = Path()
      ..moveTo(c.dx - 3 * s, c.dy - 2.5 * s)
      ..lineTo(c.dx - 3 * s, c.dy - 5 * s)
      ..arcToPoint(Offset(c.dx + 3 * s, c.dy - 5 * s),
          radius: Radius.circular(3 * s))
      ..lineTo(c.dx + 3 * s, c.dy - (gold ? 6.4 : 2.5) * s);
    canvas.drawPath(shackle, line(lockInk, 1.7 * s));
    canvas.drawRRect(body, p(lockInk, smooth: true));
  }

  /// A torch on a pillar. The flame leans and flickers; each torch has its own
  /// rhythm so the pair never move together.
  void _paintTorch(
      Canvas canvas, Paint Function(Color, {bool smooth}) p, double cx) {
    final s = _s;
    final yb = size.y * 0.5; // top of the bracket
    final flick = 1 + 0.13 * sin(_t * 9 + cx);
    final lean = 1.2 * s * sin(_t * 5 + cx * 0.7);

    canvas.drawCircle(
        Offset(cx, yb - 12 * s),
        18 * s * flick,
        p(const Color(0xFFFF8A2A).withValues(alpha: 0.16 + 0.06 * flick),
            smooth: true));
    canvas.drawRect(Rect.fromLTWH(cx - 1.6 * s, yb + 2 * s, 3.2 * s, 16 * s),
        p(const Color(0xFF2B1D07)));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 4 * s, yb, 8 * s, 4 * s), Radius.circular(s)),
      p(const Color(0xFF5E4515), smooth: true),
    );

    Path flame(double scale) {
      final base = yb - 2 * s;
      final topY = base - 17 * s * flick * scale;
      final half = 6 * s * scale;
      return Path()
        ..moveTo(cx + lean * scale, topY)
        ..cubicTo(cx + 3.5 * s * scale, topY + 6 * s, cx + half,
            base - 9 * s * scale, cx + half, base - 5 * s * scale)
        ..arcToPoint(Offset(cx - half, base - 5 * s * scale),
            radius: Radius.circular(half))
        ..cubicTo(cx - half, base - 9 * s * scale, cx - 3.5 * s * scale,
            topY + 6 * s, cx + lean * scale, topY)
        ..close();
    }

    canvas.drawPath(flame(1), p(const Color(0xFFFF8A2A), smooth: true));
    canvas.drawPath(flame(0.55), p(const Color(0xFFFFE27A), smooth: true));
  }

  /// A few specks of stone shaken loose from the lintel while the grille moves.
  void _paintDust(Canvas canvas, Paint Function(Color, {bool smooth}) p) {
    final stone = _stone[game.currentEra] ?? const Color(0xFF7A7585);
    final dust = Color.lerp(stone, Colors.white, 0.35)!;
    final strength = sin(pi * doorOpen);
    for (var i = 0; i < 14; i++) {
      final seed = (i * 0.61803) % 1.0;
      final fall = (_t * (0.7 + 0.5 * seed) + seed * 3) % 1.0;
      final x = _gx(34) + (_gx(86) - _gx(34)) * ((i * 0.37 + seed) % 1.0);
      final y = _gy(40) + fall * 110;
      canvas.drawRect(
        Rect.fromLTWH(x, y, 2 * _s, 2 * _s),
        p(dust.withValues(alpha: 0.75 * strength * (1 - fall))),
      );
    }
  }

  /// Whether this gate should stop the player.
  ///
  /// Note there is deliberately no despawn check in [update] — unlike
  /// enemies and coins, a gate is never culled for being behind the camera.
  /// The player can walk back to one, and a gate that respawned closed
  /// would re-block a corridor they had already earned passage through.
  bool get isBlocking => !opened;

  /// Whether every artifact in the level has been answered.
  ///
  /// The end gate is the level's exit (playtest decision, 2026-10-03), and it
  /// stays shut until every artifact has been answered — right or wrong.
  /// Until then, walking into it shows a count of what is left, so the
  /// student is told why they are blocked instead of just being stopped.
  bool get requirementMet => game.canPassEndGate;

  /// Whether passing this gate completes the level. Every level's single
  /// gate is its exit, so this is true for all of them; it is kept as a flag
  /// so a gate could be placed elsewhere without ending the level.
  final bool isLevelExit;

  /// Opens the gate at once, with no trip and no animation.
  void open() => doorOpen = 1;
}
