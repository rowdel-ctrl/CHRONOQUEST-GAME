import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/surprise_constants.dart';
import '../chrono_game.dart';
import '../surprise_art.dart';
import '../surprise_rules.dart';

enum FallingRockPhase { dormant, warn, drop, landed }

/// A spot where a rock falls (the map's `falling_rock` object: x is the middle of the
/// spot, y the ground there).
///
/// It sleeps, drawing nothing, until a student is between
/// [SurpriseConstants.rockTriggerNear] and [SurpriseConstants.rockTriggerFar] away and
/// the game has room for another surprise. Then a round shadow grows on the ground with
/// a "!" for [SurpriseConstants.rockWarn] seconds, then the rock drops for
/// [SurpriseConstants.rockDrop] seconds. When it lands the screen shakes a moment and
/// it breaks into harmless pieces and dust. It hurts only a student standing inside the
/// shadow at that moment (one heart): one who stepped out, or whose feet are
/// [SurpriseConstants.rockClearHeight] or more above the ground, is untouched. It happens
/// once.
///
/// Every timer counts frames (`update(dt)`).
class FallingRockComponent extends PositionComponent
    with HasGameReference<ChronoGame> {
  final double spotX;
  final double surfaceY;

  FallingRockPhase phase = FallingRockPhase.dormant;
  double _t = 0;
  double _age = 0;
  SurpriseRegistry? _counted;
  bool _shaking = false;

  /// Whether the landing hurt the student (for tests).
  bool hurt = false;

  FallingRockComponent({required this.spotX, required this.surfaceY})
      : super(position: Vector2(spotX, surfaceY), priority: 6);

  /// Seconds into the current phase, for tests.
  double get phaseTime => _t;

  void _release() {
    _counted?.finish(this);
    _counted = null;
  }

  @override
  void onRemove() {
    _release();
    if (_shaking) game.cameraShake.setZero();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    switch (phase) {
      case FallingRockPhase.dormant:
        if (_studentInRange() && game.surprises.tryStart(this)) {
          _counted = game.surprises;
          phase = FallingRockPhase.warn;
          _t = 0;
          game.audioService.playHeavyWindup();
        }
      case FallingRockPhase.warn:
        _t += dt;
        if (_t >= SurpriseConstants.rockWarn) {
          phase = FallingRockPhase.drop;
          _t = 0;
        }
      case FallingRockPhase.drop:
        _t += dt;
        if (_t >= SurpriseConstants.rockDrop) _land();
      case FallingRockPhase.landed:
        _t += dt;
        _shake();
        if (_t >= 0.3) _release();
        if (_t >= SurpriseConstants.rockDebris) removeFromParent();
    }
  }

  bool _studentInRange() {
    final s = game.studentOrNull;
    if (s == null) return false;
    final dx = (s.position.x + s.size.x / 2 - spotX).abs();
    final dy = (s.position.y + s.size.y - surfaceY).abs();
    return dx >= SurpriseConstants.rockTriggerNear &&
        dx <= SurpriseConstants.rockTriggerFar &&
        dy <= 150;
  }

  void _land() {
    phase = FallingRockPhase.landed;
    _t = 0;
    final s = game.studentOrNull;
    if (s != null) {
      final centre = s.position.x + s.size.x / 2;
      if (SurpriseRules.insideZone(
        centreX: centre,
        feetY: s.position.y + s.size.y,
        spotX: spotX,
        groundY: surfaceY,
        radius: SurpriseConstants.rockRadius,
        clearHeight: SurpriseConstants.rockClearHeight,
      )) {
        hurt = true;
        s.takeHazardHit(knockbackDirection: centre >= spotX ? 1 : -1);
      }
    }
    game.audioService.playLand();
    _shake();
  }

  /// The short screen shake after the landing.
  void _shake() {
    final d = _t;
    if (d < SurpriseConstants.rockShakeSeconds) {
      final k = 1 - d / SurpriseConstants.rockShakeSeconds;
      game.cameraShake.setValues(
        sin(d * 90) * SurpriseConstants.rockShakeAmount * k,
        cos(d * 80) * SurpriseConstants.rockShakeAmount * 0.66 * k,
      );
      _shaking = true;
    } else if (_shaking) {
      game.cameraShake.setZero();
      _shaking = false;
    }
  }

  @override
  void render(Canvas canvas) {
    switch (phase) {
      case FallingRockPhase.dormant:
        return;
      case FallingRockPhase.warn:
        final p = SurpriseArt.clamp01(_t / SurpriseConstants.rockWarn);
        SurpriseArt.rockShadow(canvas, 0, SurpriseConstants.rockRadius, p, 1);
        SurpriseArt.bang(canvas, 0, -60, _t);
      case FallingRockPhase.drop:
        SurpriseArt.rockShadow(canvas, 0, SurpriseConstants.rockRadius, 1, 1);
        final u = SurpriseArt.clamp01(_t / SurpriseConstants.rockDrop);
        final bottom = -SurpriseConstants.rockStartHeight * (1 - u * u);
        SurpriseArt.rock(canvas, 0, bottom - 26, _age * 3);
      case FallingRockPhase.landed:
        final a = SurpriseArt.clamp01(1 - _t / 0.25);
        if (a > 0) {
          SurpriseArt.rockShadow(canvas, 0, SurpriseConstants.rockRadius, 1, a);
        }
        SurpriseArt.rockPieces(
            canvas, 0, -26, _t, SurpriseConstants.rockDebris);
        SurpriseArt.dust(canvas, 0, _t);
        SurpriseArt.shockRing(canvas, 0, _t);
    }
  }
}
