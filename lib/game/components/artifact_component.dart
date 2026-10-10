import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/rendering.dart';
import 'package:flutter/material.dart';

import '../../core/combat_constants.dart';
import '../../models/question.dart';
import '../chrono_game.dart';

/// A floating answer point (GAMEPLAY-V2.md Section 6 — "the single most
/// important object in the game").
///
/// Walk into it and the question overlay opens. Answer correctly and you
/// *claim* it: +2 Kaalaman, it vanishes, and it lands in the Codex. Answer
/// wrongly and you lose no HP — the explanation panel shows exactly as it
/// does today, the artifact goes inert for 5 seconds, then re-lights and
/// serves a *different* question at a reduced reward.
class ArtifactComponent extends SpriteComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  /// World x this artifact was placed at by the spawner.
  final double worldX;

  /// Which of the five artifact sprites this shows. Only 5 exist for 6 eras
  /// (Section 6), so they repeat across eras, distinguished by the per-era
  /// tint applied in [onLoad].
  final int spriteIndex;

  /// True once claimed — it is being removed and must not re-open a
  /// question on a lingering collision frame.
  bool claimed = false;

  /// True while inert after a wrong answer. Section 6: it "stays in the
  /// world but goes inert for ~5 seconds, then re-lights".
  bool get isInert => _inertTimer > 0;
  double _inertTimer = 0;

  /// True once this artifact has been answered at all, right or wrong, so the
  /// end gate's tally counts it exactly once however many tries it takes.
  bool counted = false;

  /// True once answered wrongly at least once, which permanently reduces
  /// this artifact's reward for the rest of the attempt.
  bool attempted = false;

  int get reward => attempted
      ? CombatConstants.artifactRetryReward
      : CombatConstants.artifactReward;

  /// The question this artifact last served, so a retry can ask for a
  /// different one (Section 6: 'serves a different question').
  Question? lastQuestion;

  double _bobTime = 0;
  late final double _baseY;

  /// Drives the halo's pulse and the sparkles. Its own clock, so it keeps
  /// running while the bob does.
  double _glowTime = 0;

  /// The halo: bright gold in the middle fading out. Built once; the pulse
  /// scales the canvas instead of making a new shader every frame.
  static final Paint _haloPaint = Paint();
  static final Paint _sparklePaint = Paint();
  static Shader? _haloShader;

  /// World y of the ground this artifact stands over. Null means the base ground;
  /// a level with raised ground puts artifacts at the height of the ground under
  /// each one (the rest areas sit on the level's landscape).
  final double? surfaceY;

  ArtifactComponent({
    required this.worldX,
    required this.spriteIndex,
    this.surfaceY,
  });

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('collectibles/artifact_$spriteIndex.png');
    size = Vector2.all(CombatConstants.artifactSize);
    position = Vector2(
      worldX,
      (surfaceY ?? game.groundY) - CombatConstants.artifactHoverHeight,
    );
    _baseY = position.y;

    // No era tint any more. It washed the sprite into the (tinted) background,
    // so artifacts were hard to pick out (playtest, 2026-10-06); they are drawn
    // in their own colours with a glow behind them instead (see [render]).
    // Anything that changes the look later must use `decorator.replaceLast`,
    // never `decorator =`: assigning would discard the Transform2DDecorator
    // that applies position and scale, rendering the artifact at the origin
    // at the wrong size (Section 10's warning).
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (claimed) return;

    if (_inertTimer > 0) {
      _inertTimer -= dt;
      if (_inertTimer <= 0) _relight();
    }

    _glowTime += dt;
    _bobTime += dt * CombatConstants.artifactBobSpeed;
    position.y = _baseY + sin(_bobTime) * CombatConstants.artifactBobAmplitude;

    // Deliberately never culled behind the camera (GAMEPLAY-V2.md Section
    // 11, and see level_culling.dart). An artifact is authored content: the
    // player can walk past one, turn around and come back for it, and the
    // old "despawn behind the camera" rule deleted it in between — taking
    // its question, its charges and its Codex entry with it.
  }

  /// How far from the player, in world x, an artifact still draws its glow.
  /// Farther than the screen is wide, so nobody sees it pop in.
  static const double _glowRange = 900;

  @override
  void render(Canvas canvas) {
    // Behind the sprite, so drawn first. Not while inert (dull and spent) and
    // not when far off screen, where nobody would see it.
    if (!isInert && _glowVisible) _renderGlow(canvas);
    super.render(canvas);
  }

  bool get _glowVisible {
    try {
      return (position.x - game.player.position.x).abs() < _glowRange;
    } catch (_) {
      return true; // no player yet (a bare game in a test): just draw it
    }
  }

  void _renderGlow(Canvas canvas) {
    final centre = Offset(size.x / 2, size.y / 2);
    final radius = size.x * 1.15;
    final fade = opacity.clamp(0.0, 1.0); // follows the fade-out when claimed
    if (fade <= 0) return;

    _haloShader ??= const RadialGradient(
      colors: [Color(0xF2FFF0A0), Color(0x8CFFC531), Color(0x00FFC531)],
      stops: [0.0, 0.38, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));
    _haloPaint.shader = _haloShader;

    if (fade < 1) {
      canvas.saveLayer(null, Paint()..color = Colors.white.withValues(alpha: fade));
    }
    // The halo breathes: 86% to 100% of its size.
    final pulse = 0.86 + 0.14 * sin(_glowTime * 2.6);
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(radius * pulse);
    canvas.drawCircle(Offset.zero, 1, _haloPaint);
    canvas.restore();

    // A few sparkles drifting up and twinkling out, each on its own cycle.
    for (var i = 0; i < 7; i++) {
      final life = (_glowTime * 0.55 + i * 0.31) % 1.0;
      final a = sin(life * pi); // 0 at birth and death, 1 in the middle
      final angle = i * 0.9 * 2.1;
      final orbit = size.x * (0.42 + 0.28 * ((i * 37) % 5) / 5);
      final x = centre.dx + cos(angle) * orbit;
      final y = centre.dy + sin(angle) * orbit * 0.9 - life * size.x * 0.35;
      _sparklePaint.color = Color.fromRGBO(255, 252, 220, 0.95 * a);
      _drawStar(canvas, x, y, 2.4 + 1.6 * a);
    }
    if (fade < 1) canvas.restore();
  }

  /// A four-pointed twinkle.
  void _drawStar(Canvas canvas, double x, double y, double r) {
    final path = Path()
      ..moveTo(x, y - r)
      ..quadraticBezierTo(x, y, x + r, y)
      ..quadraticBezierTo(x, y, x, y + r)
      ..quadraticBezierTo(x, y, x - r, y)
      ..quadraticBezierTo(x, y, x, y - r);
    canvas.drawPath(path, _sparklePaint);
  }

  /// Whether walking into this should open a question right now.
  bool get isInteractable => !claimed && !isInert;

  /// Called after a wrong answer: dim and stop responding for a while, and
  /// permanently drop the reward for this artifact.
  void goInert() {
    attempted = true;
    _inertTimer = CombatConstants.artifactInertSeconds;
    // Visibly dimmed so the student can see it is temporarily spent rather
    // than wondering why walking into it does nothing.
    decorator.replaceLast(PaintDecorator.tint(Colors.black.withValues(alpha: 0.55)));
  }

  void _relight() {
    decorator.replaceLast(null);
  }

  /// Called after a correct answer: claim it and fade out.
  void claim() {
    if (claimed) return;
    claimed = true;
    add(
      SequenceEffect(
        [
          ScaleEffect.by(
            Vector2.all(1.4),
            EffectController(duration: 0.15),
          ),
          OpacityEffect.fadeOut(EffectController(duration: 0.2)),
        ],
        onComplete: removeFromParent,
      ),
    );
  }
}
