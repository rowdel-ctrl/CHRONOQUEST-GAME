import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/surprise_constants.dart';
import '../chrono_game.dart';
import '../enemy_behavior.dart';
import '../surprise_art.dart';
import '../surprise_rules.dart';
import 'enemy_component.dart';

enum GroundPopPhase { dormant, warn, rise, fade }

/// A spot in the path where an enemy comes up out of the ground (the map's
/// `ground_pop` object: x is the middle of the spot, y the ground there).
///
/// It sleeps, drawing nothing, until a student is between
/// [SurpriseConstants.popTriggerNear] and [SurpriseConstants.popTriggerFar] away and
/// the game has room for another surprise. Then a crack opens in the ground with a
/// "!" for [SurpriseConstants.popWarn] seconds. Then the era's own walker (a dark
/// spirit in the first era) rises out of it ([EnemySurprise.popper]): it can be hit
/// from the first moment and cannot hurt until it is fully up
/// ([SurpriseConstants.popRise] s). Then the crack fades. It happens once.
///
/// Every timer counts frames (`update(dt)`).
class GroundPopComponent extends PositionComponent
    with HasGameReference<ChronoGame> {
  final String eraId;
  final double spotX;
  final double surfaceY;

  GroundPopPhase phase = GroundPopPhase.dormant;
  double _t = 0;
  SurpriseRegistry? _counted;

  /// The enemy it raised, once it has (for tests).
  EnemyComponent? enemy;

  GroundPopComponent({
    required this.eraId,
    required this.spotX,
    required this.surfaceY,
  }) : super(position: Vector2(spotX, surfaceY), priority: -1);

  /// Seconds into the current phase, for tests.
  double get phaseTime => _t;

  void _release() {
    _counted?.finish(this);
    _counted = null;
  }

  @override
  void onRemove() {
    _release();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    switch (phase) {
      case GroundPopPhase.dormant:
        if (_studentInRange() && game.surprises.tryStart(this)) {
          _counted = game.surprises;
          phase = GroundPopPhase.warn;
          _t = 0;
          game.audioService.playHeavyWindup();
        }
      case GroundPopPhase.warn:
        _t += dt;
        if (_t >= SurpriseConstants.popWarn) {
          _raise();
          phase = GroundPopPhase.rise;
          _t = 0;
        }
      case GroundPopPhase.rise:
        _t += dt;
        if (_t >= SurpriseConstants.popRise) {
          phase = GroundPopPhase.fade;
          _t = 0;
          _release();
        }
      case GroundPopPhase.fade:
        _t += dt;
        if (_t >= 0.8) removeFromParent();
    }
  }

  bool _studentInRange() {
    final s = game.studentOrNull;
    if (s == null) return false;
    final dx = (s.position.x + s.size.x / 2 - spotX).abs();
    final dy = (s.position.y + s.size.y - surfaceY).abs();
    return dx >= SurpriseConstants.popTriggerNear &&
        dx <= SurpriseConstants.popTriggerFar &&
        dy <= 150;
  }

  void _raise() {
    final e = EnemyComponent(
      eraId: eraId,
      enemyTypeOverride: SurpriseRules.popKindFor(eraId),
      worldX: spotX - EnemyComponent.spriteWidth / 2,
      patrolRangeOverride: SurpriseConstants.popPatrol,
      surfaceY: surfaceY < game.groundY - 1 ? surfaceY : null,
      behaviorOverride: EnemyBehavior.walker,
      surprise: EnemySurprise.popper,
    );
    enemy = e;
    game.world.add(e);
  }

  @override
  void render(Canvas canvas) {
    if (phase == GroundPopPhase.dormant) return;
    final cp = switch (phase) {
      GroundPopPhase.warn => SurpriseArt.clamp01(_t / 0.3),
      _ => 1.0,
    };
    final fade =
        phase == GroundPopPhase.fade ? SurpriseArt.clamp01(1 - _t / 0.8) : 1.0;
    SurpriseArt.crack(canvas, 0, cp, fade);
    if (phase == GroundPopPhase.warn) SurpriseArt.bang(canvas, 0, -66, _t);
  }
}
