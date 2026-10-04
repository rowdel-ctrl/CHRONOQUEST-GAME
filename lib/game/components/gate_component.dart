import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
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
/// playtest: "the visual of the gate should be replaced"). It was a column of
/// ground tiles, which read as a wall of the same stuff as the floor rather
/// than a gate. It is now a stone gatehouse with a barred door, a padlock and a
/// lamp, so its state reads at a glance: a red lamp and a closed padlock while
/// artifacts remain, a green lamp, an open padlock and a glowing door once
/// every artifact is answered. Extends `PositionComponent with HasPaint`
/// because [open]'s `OpacityEffect` fades that paint, and [render] scales every
/// colour by it so the crumble still fades the whole gate.
class GateComponent extends PositionComponent
    with HasGameReference<ChronoGame>, HasPaint, CollisionCallbacks {
  /// World x this gate was placed at by the spawner.
  final double worldX;

  /// True once open — the gate is crumbling and no longer blocks.
  bool opened = false;

  GateComponent({required this.worldX, this.isLevelExit = false});

  /// The x the player is held at while this gate stands.
  double get blockX => position.x - CombatConstants.gateStandoff;

  /// The gate is sized in whole tiles of this many units, matching the
  /// platforms and ground beside it.
  static const double tileSize = 24;

  /// Seconds elapsed, for the lamp and door glow.
  double _t = 0;

  /// Stone colour per era, so the gates match their surroundings.
  static const Map<String, Color> _stone = {
    'pre-colonial': Color(0xFF6E7B62),
    'spanish': Color(0xFF8A7F70),
    'nationalism': Color(0xFF7A7585),
    'american': Color(0xFF7C8591),
    'ww2': Color(0xFF6B7078),
    'modern': Color(0xFF787A8C),
  };

  static const Color _wood = Color(0xFF3B2412);
  static const Color _iron = Color(0xFF15141A);
  static const Color _outline = Color(0xFF2E1608);
  static const Color _gold = Color(0xFFFFC531);
  static const Color _ok = Color(0xFF43A83E);
  static const Color _bad = Color(0xFFE8433A);

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

  /// The parts of the gate that never change while it stands: the stone body,
  /// brick courses, battlements, lintel, arched door and its bars. Recorded once
  /// and replayed every frame, so the per-frame work is the lamp, the door glow
  /// and the padlock only. Built lazily because the stone colour depends on the
  /// era, which is known once the gate is mounted.
  ui.Picture? _body;

  static const double _crown = 10;
  static const double _doorTop = 58;
  static const double _lockTop = 146;

  /// The door is a bit under half the gate's width, centred.
  double get _doorWidth => (size.x * 0.46).roundToDouble();
  double get _doorLeft => (size.x - _doorWidth) / 2;

  ui.Picture _recordBody() {
    final w = size.x, h = size.y;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    Paint p(Color c, {bool smooth = false}) => Paint()
      ..color = c
      ..isAntiAlias = smooth;

    final stone = _stone[game.currentEra] ?? const Color(0xFF7A7585);
    final dark = Color.lerp(stone, Colors.black, 0.35)!;
    final light = Color.lerp(stone, Colors.white, 0.2)!;

    // Body, from under the battlements down to the ground.
    canvas.drawRect(Rect.fromLTWH(0, _crown, w, h - _crown), p(stone));

    // Brick courses: a mortar line every 22 units, with the joints staggered
    // every 24 so a wide gate still reads as brickwork.
    var course = 0;
    for (var y = _crown + 22; y < h; y += 22, course++) {
      canvas.drawRect(Rect.fromLTWH(0, y, w, 2), p(dark));
      for (var jx = course.isEven ? 0.0 : 12.0; jx < w; jx += 24) {
        if (jx > 0 && jx < w - 2) {
          canvas.drawRect(Rect.fromLTWH(jx, y - 22, 2, 22), p(dark));
        }
      }
    }

    // Battlements, evenly spread along the top.
    final merlons = max(3, ((w + 6) / 18).round());
    for (var i = 0; i < merlons; i++) {
      final x = i * (w - 12) / (merlons - 1);
      canvas.drawRect(Rect.fromLTWH(x, 0, 12, _crown + 2), p(light));
      canvas.drawRect(Rect.fromLTWH(x, 0, 12, 2), p(Colors.white.withValues(alpha: 0.25)));
    }

    // The lintel over the door.
    canvas.drawRect(Rect.fromLTWH(0, _crown + 2, w, 34), p(light));
    canvas.drawRect(Rect.fromLTWH(0, _crown + 34, w, 3), p(dark));

    // The arched door and its iron bars.
    final dl = _doorLeft, dw = _doorWidth, dr = dl + dw;
    final door = Path()
      ..moveTo(dl, h)
      ..lineTo(dl, _doorTop + 12)
      ..quadraticBezierTo(w / 2, _doorTop - 6, dr, _doorTop + 12)
      ..lineTo(dr, h)
      ..close();
    canvas.drawPath(door, p(_wood, smooth: true));
    final bars = 2 * (w / 48).floor() + 1;
    for (var i = 0; i < bars; i++) {
      final x = dl + (i + 1) * dw / (bars + 1);
      canvas.drawRect(Rect.fromLTRB(x - 1.25, _doorTop + 6, x + 1.25, h), p(_iron));
    }
    canvas.drawRect(Rect.fromLTWH(dl, _doorTop + 40, dw, 3), p(_iron));
    canvas.drawRect(Rect.fromLTWH(dl, h - 60, dw, 3), p(_iron));
    canvas.drawPath(
      door,
      p(_outline, smooth: true)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    return recorder.endRecording();
  }

  /// Draws the gate: stone towers and battlements around an arched, barred
  /// door with a padlock, and a lamp above it. Everything is multiplied by the
  /// paint's alpha so [open]'s fade-out takes the whole gate with it.
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
    final w = size.x;
    final fade = paint.color.a;
    Paint p(Color c, {bool smooth = false}) => Paint()
      ..color = c.withValues(alpha: c.a * fade)
      ..isAntiAlias = smooth;
    Paint line(Color c, double width) => p(c, smooth: true)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    final unlocked = requirementMet;
    final pulse = unlocked ? 0.5 + 0.5 * sin(_t * 4) : 0.5 + 0.5 * sin(_t * 2);

    // The still parts, replayed from the recording. While fading out they are
    // drawn into a layer so the whole gate fades together.
    final body = _body ??= _recordBody();
    if (fade < 1) {
      canvas.saveLayer(Offset.zero & size.toSize(), Paint()..color = Colors.white.withValues(alpha: fade));
      canvas.drawPicture(body);
      canvas.restore();
    } else {
      canvas.drawPicture(body);
    }

    // The lamp over the door: red while artifacts remain, green once they are
    // all answered, with a glow that pulses.
    final lamp = unlocked ? _ok : _bad;
    final lampCentre = Offset(w / 2, _crown + 19);
    if (unlocked) {
      canvas.drawCircle(lampCentre, 13, p(lamp.withValues(alpha: 0.25 + 0.25 * pulse), smooth: true));
    }
    canvas.drawCircle(lampCentre, 7, p(_outline, smooth: true));
    canvas.drawCircle(lampCentre, 5.5, p(lamp.withValues(alpha: 0.65 + 0.35 * pulse), smooth: true));

    // The door glows green from within once it can be opened.
    if (unlocked) {
      final dl = _doorLeft, dr = dl + _doorWidth, h = size.y;
      final glow = Path()
        ..moveTo(dl, h)
        ..lineTo(dl, _doorTop + 12)
        ..quadraticBezierTo(w / 2, _doorTop - 6, dr, _doorTop + 12)
        ..lineTo(dr, h)
        ..close();
      canvas.drawPath(glow, p(_ok.withValues(alpha: 0.18 + 0.2 * pulse), smooth: true));
    }

    // The padlock, on the door at about shoulder height. It grows with the door
    // so a wide gate does not carry a tiny lock.
    final s = 0.25 + 0.75 * (w / 48);
    canvas.save();
    canvas.translate(w / 2 - 10 * s, _lockTop);
    canvas.scale(s);
    final shackle = line(const Color(0xFFB8B8C4), 3.2);
    if (unlocked) {
      // Open: the shackle swings up and out, attached on one side only.
      canvas.drawLine(const Offset(4, 0), const Offset(4, -10), shackle);
      canvas.drawArc(const Rect.fromLTWH(4, -20, 12, 12), pi, pi, false, shackle);
    } else {
      canvas.drawLine(const Offset(4, 0), const Offset(4, -8), shackle);
      canvas.drawLine(const Offset(16, 0), const Offset(16, -8), shackle);
      canvas.drawArc(const Rect.fromLTWH(4, -14, 12, 12), pi, pi, false, shackle);
    }
    final body2 = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 20, 17), const Radius.circular(3));
    canvas.drawRRect(body2, p(unlocked ? _ok : _gold, smooth: true));
    canvas.drawRRect(body2, line(_outline, 2));
    canvas.drawCircle(const Offset(10, 7), 2.4, p(_outline, smooth: true));
    canvas.drawRect(const Rect.fromLTWH(9, 8, 2, 5), p(_outline));
    canvas.restore();
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

  /// Crumble and stop blocking.
  void open() {
    if (opened) return;
    opened = true;
    game.audioService.playEnemyDefeat();
    add(
      SequenceEffect(
        [
          MoveEffect.by(Vector2(0, 12), EffectController(duration: 0.12)),
          OpacityEffect.fadeOut(EffectController(duration: 0.25)),
        ],
        onComplete: removeFromParent,
      ),
    );
  }
}
