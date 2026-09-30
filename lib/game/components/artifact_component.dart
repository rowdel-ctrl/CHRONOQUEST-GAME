import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/rendering.dart';
import 'package:flutter/material.dart';

import '../../core/combat_constants.dart';
import '../../models/question.dart';
import '../chrono_game.dart';
import 'parallax_background.dart';

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

  ArtifactComponent({required this.worldX, required this.spriteIndex});

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('collectibles/artifact_$spriteIndex.png');
    size = Vector2.all(CombatConstants.artifactSize);
    position = Vector2(
      worldX,
      game.groundY - CombatConstants.artifactHoverHeight,
    );
    _baseY = position.y;

    // Per-era tint so the same five sprites read differently across six
    // eras. `replaceLast`, never `decorator =` — assigning would discard
    // the Transform2DDecorator that applies position and scale, rendering
    // the artifact at the origin at the wrong size (Section 10's warning).
    final tint = ParallaxBackground.eraTints[game.currentEra];
    if (tint != null) {
      decorator.replaceLast(PaintDecorator.tint(tint));
    }

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

    _bobTime += dt * CombatConstants.artifactBobSpeed;
    position.y = _baseY + sin(_bobTime) * CombatConstants.artifactBobAmplitude;

    // Despawn well behind the camera, same as every other world component.
    if (position.x < game.cameraLeftEdgeX - size.x) {
      removeFromParent();
    }
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
    final tint = ParallaxBackground.eraTints[game.currentEra];
    decorator.replaceLast(
      tint != null ? PaintDecorator.tint(tint) : null,
    );
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
