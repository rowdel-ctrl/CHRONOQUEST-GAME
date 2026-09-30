import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/combat_constants.dart';
import '../chrono_game.dart';
import 'enemy_component.dart';

/// The transient attack hitbox spawned when the player swings
/// (GAMEPLAY-V2.md Section 3: "a short forward hitbox in the facing
/// direction, ~0.25s"). Added to `world`, not the player, so it isn't
/// subject to the player's own render-flip transform — its
/// position/size already account for facing when it's constructed.
///
/// Rendered as a plain translucent rectangle for now rather than the
/// Kenney slash-arc art Section 3 calls for — no such asset exists in this
/// project yet, and referencing one that doesn't would throw at runtime.
/// Same "plumbing now, real asset later" split Phase 0 used for audio and
/// game_input.dart already uses for the joystick/HUD buttons.
class AttackHitboxComponent extends PositionComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  double _elapsed = 0;

  /// Enemies already hit by this swing — guards against a Heavy (2 HP)
  /// registering more than one hit from the same 0.25s-lived hitbox if it
  /// stays overlapping across multiple collision-detection frames.
  final Set<EnemyComponent> _alreadyHit = {};

  AttackHitboxComponent({required super.position, required super.size});

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
    add(
      RectangleComponent(
        size: size,
        paint: Paint()..color = Colors.yellowAccent.withValues(alpha: 0.5),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= CombatConstants.attackHitboxDuration) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is EnemyComponent && !other.defeated && !_alreadyHit.contains(other)) {
      _alreadyHit.add(other);
      other.takeHit();
    }
  }
}
