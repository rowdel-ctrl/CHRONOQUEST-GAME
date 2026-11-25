import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/combat_constants.dart';
import '../chrono_game.dart';
import 'gate_art.dart';

/// The end gate (GAMEPLAY-V2.md Section 6).
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
/// **Drawn in code, not from a sprite or the ground tileset.** Redrawn
/// 2026-11-16 as six era gates (see [GateArt], gate_art.dart): bamboo and thatch
/// for Sinaunang Pilipinas, Intramuros stone for the Spanish era, Katipunan
/// wood for nationalism, brick for the American era, a sandbag checkpoint for
/// the Japanese war and a concrete and glass ring for modern times. Each is
/// [CombatConstants.gateWidth] x [CombatConstants.gateHeight] (200 x 220), with
/// a 104 x 134 door centred at the bottom. Its state reads at a glance: a red
/// lamp and a shut door while artifacts remain, a gold lamp once every artifact
/// is answered, and, after [GateReveal] (gate_reveal.dart) has lifted the door,
/// a glowing mat in the doorway with arrows and the word PASOK. The gate does
/// not crumble: it stays, open, and the level ends when the middle of the
/// student steps into the doorway (checkGateEntered, [enterX]). Extends
/// `PositionComponent with HasPaint` so [render] can fade the whole gate with
/// the paint's alpha.
class GateComponent extends PositionComponent
    with HasGameReference<ChronoGame>, HasPaint, CollisionCallbacks {
  /// World x this gate was placed at by the spawner.
  final double worldX;

  /// True once the door is all the way up: the gate no longer blocks, and the
  /// student walks into the doorway.
  bool get opened => doorOpen >= 1;

  /// True once the student has walked into the open doorway, which is what ends
  /// the level (ChronoGame.enterEndGate).
  bool entered = false;

  /// How far into the doorway the student's middle must get: just past the doorway's near
  /// edge, so about half of him is inside. A student reported still having to walk to the end
  /// of the gate (first it was the far pillar, then the middle of the doorway).
  static const double enterInset = 12;

  /// The world x the middle of the student has to reach for the level to end.
  double get enterX => position.x + GateArt.doorX + enterInset;

  /// Behind the student (whose priority is the default 0), so the hero is drawn
  /// in front of the gate while walking up to it and into its doorway.
  GateComponent({required this.worldX, this.isLevelExit = false})
      : super(priority: -1);

  /// The x the player is held at while this gate stands.
  double get blockX => position.x - CombatConstants.gateStandoff;

  /// The platforms and ground beside the gate are made of tiles this big. The
  /// gate itself is no longer snapped to them (it is exactly 200 x 220, which
  /// is not a whole number of tiles); its door is centred, so the middle of the
  /// doorway is always `size.x / 2` from its left edge.
  static const double tileSize = 24;

  /// Seconds elapsed, for the flames, the lamp's glow and the dust.
  double _t = 0;

  /// How far the door has been lifted, 0 (shut) to 1 (up), set by
  /// [GateReveal] (gate_reveal.dart) while the camera is on the gate. It stays
  /// at 1 afterwards: the student walks into a doorway that is already open.
  double doorOpen = 0;

  @override
  Future<void> onLoad() async {
    size = Vector2(CombatConstants.gateWidth, CombatConstants.gateHeight);
    position = Vector2(worldX, game.groundY - size.y);

    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  /// Which of the six gates this is. Known once the gate is mounted, because it
  /// depends on the era.
  GateKind? _kind;

  /// The parts that never change while the gate stands, recorded once and
  /// replayed every frame: the shadow, wall and roof behind the door; the door
  /// itself; and the ornaments in front of it. The per-frame work is what moves
  /// (flames, chimes, banners, searchlight), the doorway light, the lamp, the
  /// mat and the dust.
  ui.Picture? _back;
  ui.Picture? _panel;
  ui.Picture? _front;

  ui.Picture _record(void Function(Canvas) draw) {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    return recorder.endRecording();
  }

  /// How far past the gate's box something is still drawn: roofs, torches,
  /// sentry boxes, the arrows in front of it and the banana leaves all stick
  /// out. The gate is skipped when this margin is off screen.
  static const double _margin = 120;

  /// Draws the gate. The whole gate is multiplied by the paint's alpha, so a
  /// fade-out takes all of it.
  ///
  /// Does nothing while the gate is off screen. It is drawn for the whole
  /// level otherwise, and the level's far end is not worth paying for from the
  /// first screen.
  @override
  void render(Canvas canvas) {
    if (position.x + size.x < game.cameraLeftEdgeX - _margin ||
        position.x > game.cameraRightEdgeX + _margin) {
      return;
    }
    final fade = paint.color.a;
    final kind = _kind ??= GateArt.kindForEra(game.currentEra);
    final back = _back ??= _record((c) => GateArt.paintBack(c, kind));
    final panel = _panel ??= _record((c) => GateArt.paintPanel(c, kind));
    final front = _front ??= _record((c) => GateArt.paintFront(c, kind));

    final unlocked = requirementMet;
    final open = doorOpen.clamp(0.0, 1.0);

    if (fade < 1) {
      canvas.saveLayer(
        Rect.fromLTWH(
            -_margin, -_margin, size.x + 2 * _margin, size.y + 2 * _margin),
        Paint()..color = Colors.white.withValues(alpha: fade),
      );
    }

    // Behind the door.
    canvas.drawPicture(back);
    final led = open >= 1
        ? const Color(0xFF6CF0B8)
        : unlocked
            ? const Color(0xFFFFD24A)
            : const Color(0xFFFF5A4F);
    GateArt.paintBackLive(canvas, kind, _t, led);

    // The doorway: what is behind the door, then the door, which lifts.
    _paintDoorway(canvas, kind, panel, unlocked, open);
    canvas.drawPath(
        GateArt.doorPath(kind),
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = GateArt.trim(kind));

    // In front of the door.
    canvas.drawPicture(front);
    GateArt.paintFrontLive(canvas, kind, _t);
    GateArt.paintLamp(canvas, GateArt.lampAt(kind), unlocked, open, _t);
    if (open >= 1) GateArt.paintGuide(canvas, _t);
    GateArt.paintSpecks(canvas, kind, _t);
    GateArt.paintDust(canvas, _t, open);

    if (fade < 1) canvas.restore();
  }

  /// The dark doorway with its glow, and the door lifting into the top.
  void _paintDoorway(Canvas canvas, GateKind kind, ui.Picture panel,
      bool unlocked, double open) {
    const ox = GateArt.doorX,
        oy = GateArt.doorY,
        ow = GateArt.doorWidth,
        oh = GateArt.doorHeight,
        cx = GateArt.centreX,
        gy = GateArt.height;
    const doorRect = Rect.fromLTWH(ox, oy, ow, oh);

    canvas.save();
    canvas.clipPath(GateArt.doorPath(kind));
    canvas.drawRect(doorRect, Paint()..color = const Color(0xFF0B0E14));

    // What is behind the door: embers while shut, a faint gold once every
    // artifact is answered, and warm light as the door goes up.
    final lightAlpha = open > 0
        ? open
        : (unlocked ? 0.16 + 0.1 * (0.5 + 0.5 * sin(_t * 4)) : 0.0);
    if (lightAlpha > 0) {
      canvas.drawRect(
        doorRect,
        Paint()
          ..shader = ui.Gradient.radial(
            const Offset(cx, gy - 8),
            ow * 1.2,
            [
              const Color(0xFFFFF0B0).withValues(alpha: lightAlpha),
              const Color(0xFFF0B84A).withValues(alpha: 0.5 * lightAlpha),
            ],
          ),
      );
    } else {
      canvas.drawRect(
        doorRect,
        Paint()
          ..shader = ui.Gradient.radial(
            const Offset(cx, gy),
            ow,
            [
              const Color(0xFF7A2A22)
                  .withValues(alpha: 0.4 + 0.12 * sin(_t * 2)),
              const Color(0xFF0B0E14).withValues(alpha: 0),
            ],
          ),
      );
    }

    // The door rides up into the lintel, leaving its foot just inside the top.
    canvas.translate(0, -open * (oh - 16));
    canvas.drawPicture(panel);
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

  /// Opens the gate at once, with no trip and no animation.
  void open() => doorOpen = 1;
}
