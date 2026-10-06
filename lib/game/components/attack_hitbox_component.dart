import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/combat_constants.dart';
import '../chrono_game.dart';
import '../kaalaman_handler.dart';
import 'enemy_component.dart';

/// The transient attack hitbox spawned when the player swings
/// (GAMEPLAY-V2.md Section 3: "a short forward hitbox in the facing
/// direction, ~0.25s"). Added to `world`, not the player, so it isn't
/// subject to the player's own render-flip transform — its
/// position/size already account for facing when it's constructed.
///
/// What the student sees is a slash: a white crescent that sweeps from above to
/// below the hero's front in the first part of the swing, trailing off and
/// fading, with a bright spark at its leading edge. The box that actually
/// hits is the rectangle of [size]; the crescent is only drawn over it.
class AttackHitboxComponent extends PositionComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  double _elapsed = 0;

  /// Which way the slash is drawn. The hitbox itself is placed by the caller.
  final bool facingRight;

  /// When set, the box keeps its place relative to this component while it
  /// lasts, so a swing made on the move travels with the hero instead of being
  /// left behind (at walking speed the hero covers about 60 units in a swing).
  final PositionComponent? follow;
  late final Vector2 _followOffset;

  /// Enemies already hit by this swing — guards against a Heavy (2 HP)
  /// registering more than one hit from the same 0.25s-lived hitbox if it
  /// stays overlapping across multiple collision-detection frames.
  final Set<EnemyComponent> _alreadyHit = {};

  /// One swing costs one charge no matter how many enemies it catches, and
  /// costs nothing if it catches none.
  bool _chargeSpent = false;

  AttackHitboxComponent({
    required super.position,
    required super.size,
    this.facingRight = true,
    this.follow,
  }) {
    _followOffset = follow == null ? Vector2.zero() : position - follow!.position;
  }

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    final target = follow;
    if (target != null) position = target.position + _followOffset;
    _elapsed += dt;
    if (_elapsed >= CombatConstants.attackHitboxDuration) {
      removeFromParent();
    }
  }

  /// The slash's angles: it starts a little above straight ahead and sweeps
  /// down through it.
  static const double _startAngle = -55 * pi / 180;
  static const double _sweepAngle = 110 * pi / 180;

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / CombatConstants.attackHitboxDuration).clamp(0.0, 1.0);
    // The swing itself takes the first 60% of the time; the rest is the glow
    // dying away.
    final swept = Curves.easeOutCubic.transform((t / 0.6).clamp(0.0, 1.0));
    final fade = 1 - Curves.easeIn.transform(((t - 0.4) / 0.6).clamp(0.0, 1.0));
    if (swept <= 0 || fade <= 0) return;

    canvas.save();
    if (!facingRight) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }

    final pivot = Offset(0, size.y / 2);
    final outer = size.x * 1.05;
    final inner = outer * 0.6;
    final head = _startAngle + _sweepAngle * swept;
    // The tail follows the head, so the crescent is a trail, not a growing wedge.
    final tail = _startAngle + _sweepAngle * max(0.0, swept - 0.6);
    final span = head - tail;

    final crescent = Path()
      ..arcTo(Rect.fromCircle(center: pivot, radius: outer), tail, span, true)
      ..arcTo(Rect.fromCircle(center: pivot, radius: inner), head, -span, false)
      ..close();

    canvas.drawPath(
      crescent,
      Paint()..color = Colors.white.withValues(alpha: 0.85 * fade),
    );
    canvas.drawPath(
      crescent,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.yellowAccent.withValues(alpha: fade),
    );

    // A spark at the leading edge, and a few speed lines behind the hero.
    final tip = pivot + Offset.fromDirection(head, outer * 0.82);
    canvas.drawCircle(tip, 7 * fade + 2, Paint()..color = Colors.white.withValues(alpha: fade));
    final lines = Paint()
      ..color = Colors.white.withValues(alpha: 0.7 * fade)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (var i = -1; i <= 1; i++) {
      final y = pivot.dy + i * 16;
      canvas.drawLine(Offset(-4, y), Offset(-4 - 18 * swept, y), lines);
    }
    canvas.restore();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is EnemyComponent && !other.defeated && !_alreadyHit.contains(other)) {
      _alreadyHit.add(other);
      if (!_chargeSpent) {
        _chargeSpent = true;
        game.trySpendCharge();
      }
      other.takeHit();
    }
  }
}
