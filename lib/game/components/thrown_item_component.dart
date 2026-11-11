import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/surprise_constants.dart';
import '../chrono_game.dart';
import '../surprise_art.dart';
import '../surprise_rules.dart';

/// What a thrower throws: a coin (the tax collector), a shell (the tank) or a bundle
/// of money (the corruption figure). All drawn in code.
enum ThrownKind { coin, shell, bundle }

ThrownKind thrownKindFor(String enemyType) {
  switch (enemyType) {
    case 'tank':
      return ThrownKind.shell;
    case 'corruption_figure':
      return ThrownKind.bundle;
    default:
      return ThrownKind.coin;
  }
}

/// The ring on the ground and the item flying to it, for one throw.
///
/// Created when the thrower begins its flash, so the ring shows from then on: the
/// warning is [SurpriseConstants.throwWindup] plus [SurpriseConstants.throwFlight]
/// long. Only the ring hurts: when the item lands, a student inside the ring with
/// their feet less than [SurpriseConstants.ringClearHeight] above the ground loses
/// one heart. The item itself, flying, never hurts. It lives in the world, not on the
/// thrower, so it still lands if the thrower is beaten after letting go.
///
/// Every timer counts frames (`update(dt)`), never a clock.
class ThrownItemComponent extends PositionComponent
    with HasGameReference<ChronoGame> {
  final ThrownKind kind;

  /// Where the item leaves the thrower's hand, in world coordinates.
  final Vector2 from;

  /// Where it lands: world x, and the ground's y there.
  final double targetX;
  final double groundY;
  final double windup;
  final double flight;

  double _age = 0;
  double _landedAt = -1;
  bool _cancelled = false;

  /// Whether the student was hurt by this one (for tests).
  bool hurt = false;

  /// Called once when the item has landed or the throw was cancelled.
  final void Function()? onFinished;

  ThrownItemComponent({
    required this.kind,
    required this.from,
    required this.targetX,
    required this.groundY,
    this.windup = SurpriseConstants.throwWindup,
    this.flight = SurpriseConstants.throwFlight,
    this.onFinished,
  }) : super(position: Vector2(targetX, groundY), priority: 6);

  double get age => _age;

  /// Seconds into the throw at which it lands.
  double get landsAt => windup + flight;

  bool get landed => _landedAt >= 0;

  /// True once it has landed or was cancelled: the thrower may throw again.
  bool get finished => landed || _cancelled;

  /// Whether the item has left the hand yet.
  bool get inFlight => !finished && _age >= windup;

  /// The throw is called off (the thrower was hit during its flash): the ring goes.
  void cancel() {
    if (finished) return;
    _cancelled = true;
    onFinished?.call();
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_cancelled) return;
    _age += dt;
    if (!landed && _age >= landsAt) _land();
    if (landed && _age - _landedAt > 0.75) removeFromParent();
  }

  void _land() {
    _landedAt = _age;
    final p = game.player;
    final centre = p.position.x + p.size.x / 2;
    final feet = p.position.y + p.size.y;
    if (SurpriseRules.insideZone(
      centreX: centre,
      feetY: feet,
      spotX: targetX,
      groundY: groundY,
      radius: SurpriseConstants.ringRadius,
      clearHeight: SurpriseConstants.ringClearHeight,
    )) {
      hurt = true;
      p.takeHazardHit(knockbackDirection: centre >= targetX ? 1 : -1);
    }
    game.audioService.playLand();
    onFinished?.call();
  }

  Color get _puffColor {
    switch (kind) {
      case ThrownKind.coin:
        return const Color(0xFFFFE680);
      case ThrownKind.shell:
        return const Color(0xFFFF9A3D);
      case ThrownKind.bundle:
        return const Color(0xFFB8E0B0);
    }
  }

  @override
  void render(Canvas canvas) {
    // Local origin: the middle of the ring on the ground.
    canvas.save();
    canvas.translate(0, 0);
    _drawRing(canvas);
    if (inFlight) _drawFlying(canvas);
    if (landed) _drawLanded(canvas, _age - _landedAt);
    canvas.restore();
  }

  void _drawRing(Canvas canvas) {
    final grow = SurpriseArt.clamp01(_age / 0.25);
    final fade = landed ? max(0.0, 1 - (_age - _landedAt) / 0.3) : 1.0;
    if (fade <= 0) return;
    SurpriseArt.ring(
      canvas,
      0,
      SurpriseConstants.ringRadius * SurpriseArt.ease(grow),
      0.85 * fade,
      (0.22 + 0.2 * sin(_age * 9)) * fade,
    );
  }

  void _drawFlying(Canvas canvas) {
    final u = ((_age - windup) / flight).clamp(0.0, 1.0);
    final fx = from.x - targetX;
    final fy = from.y - groundY;
    final x = fx + (0 - fx) * u;
    final y =
        fy + ((-17) - fy) * u - SurpriseConstants.throwArc * 4 * u * (1 - u);
    switch (kind) {
      case ThrownKind.coin:
        SurpriseArt.coin(canvas, x, y, _age * 10, 1, 34);
      case ThrownKind.shell:
        // Nose points along the way it is going.
        final dy = ((-17) - fy) - SurpriseConstants.throwArc * 4 * (1 - 2 * u);
        final dx = -fx;
        SurpriseArt.shell(canvas, x, y, atan2(dy, dx == 0 ? 1 : dx), 1);
      case ThrownKind.bundle:
        SurpriseArt.bundle(canvas, x, y, _age * 6, 1);
    }
  }

  void _drawLanded(Canvas canvas, double d) {
    SurpriseArt.landingPuff(canvas, 0, d, _puffColor);
    if (d < 0.45) {
      final a = 1 - d / 0.45;
      final bob = sin(d * 12).abs() * 12 * a;
      if (kind == ThrownKind.coin) {
        SurpriseArt.coin(canvas, 0, -17 - bob, 0, a, 30);
      } else if (kind == ThrownKind.bundle) {
        SurpriseArt.bundle(canvas, 0, -10 - bob, 0, a);
      }
    }
  }
}
