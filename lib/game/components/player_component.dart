import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/combat_constants.dart';
import '../answer_point_handler.dart';
import '../chrono_game.dart';
import '../game_collision.dart';
import '../kaalaman_handler.dart';
import 'artifact_component.dart';
import 'attack_hitbox_component.dart';
import 'enemy_component.dart';
import 'coin_component.dart';
import 'gate_component.dart';

/// Player character — `position.x` is the player's real world x-position,
/// `worldX`. Horizontal movement is driven by the on-screen joystick
/// (`game.gameInput.joystick`, GAMEPLAY-V2.md Section 3), student taps the
/// jump button to jump. The camera follows `worldX` so the player always
/// renders at a fixed screen offset; the player never moves itself in
/// screen space. Displays real walk, jump, and hurt sprite animations.
class PlayerComponent extends SpriteAnimationComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  static const double gravity = 900.0;
  static const double jumpForce = -480.0;

  /// Top horizontal speed, in world units/second, the joystick can command
  /// in either direction. Previously an unconditional auto-advance rate
  /// applied every frame regardless of input (GAMEPLAY-V2.md Section 3);
  /// same value, now scaled by the joystick's `relativeDelta.x` instead —
  /// the camera, spawn positions, and despawn checks still derive from
  /// `worldX`, which is what actually moves.
  ///
  /// Raised from the original 150 after playtesting found walking too slow.
  /// Nothing needed retuning alongside it: `ParallaxBackground` derives its
  /// scroll speed from this constant by ratio rather than a hardcoded
  /// number (see its own doc comment), and the spawner measures distance
  /// from the player's actual worldX rather than assuming a fixed speed, so
  /// both already track this value automatically.
  static const double forwardSpeed = 210.0;

  /// The player's real position in world space. Aliases `position.x` —
  /// obstacles/camera never subtract a scroll speed from themselves;
  /// instead this value increases every frame and everything else is
  /// positioned relative to it.
  double get worldX => position.x;

  double velocityY = 0.0;
  bool isOnGround = false;
  bool isHurt = false;

  /// Which way the character is drawn facing, toggled whenever the
  /// joystick's horizontal pull changes sign. Mirrored in `render()` via a
  /// local canvas transform rather than `flipHorizontallyAroundCenter()`:
  /// that method compensates a non-center anchor by nudging `position.x`
  /// (confirmed against the installed Flame source — for `Anchor.topLeft`
  /// it adds the full sprite width), and here `position.x` IS `worldX`, read
  /// by the camera, collision, and the spawner's distance tracking. A
  /// transform-based flip would silently displace all of them by ±size.x
  /// every time the player changes direction.
  bool facingRight = true;

  final String characterId;

  late SpriteAnimation walkAnimation;
  late SpriteAnimation jumpAnim;
  late SpriteAnimation hurtAnim;

  /// Time left before another `attack()` can spawn a new hitbox
  /// (CombatConstants.attackCooldown) — counted down every frame, not a
  /// `Future.delayed`, so it can be checked synchronously from `attack()`.
  double _attackCooldownRemaining = 0;

  /// True from the moment contact damage lands until
  /// `CombatConstants.invincibilityDuration` elapses — gates *all* further
  /// contact damage (enemy or wall) during that window, independent of
  /// `isHurt`/`triggerHurt()`'s own, shorter 600ms animation-swap-back
  /// timer. The two are sibling reactions to the same damage event with
  /// genuinely different durations, tracked separately on purpose — see
  /// `_takeContactDamage()`.
  bool invincible = false;
  double _iframeTimer = 0;

  /// Toggled during the invincibility window to flash the sprite. `render()`
  /// skips drawing entirely while this is false.
  bool _flashVisible = true;
  double _flashTimer = 0;

  /// Whether the sprite is currently drawn — false only mid-flash during
  /// the invincibility window. Exposed so tests can assert the flash never
  /// leaves the player permanently invisible once the window ends.
  @visibleForTesting
  bool get isFlashVisible => _flashVisible;

  /// Horizontal velocity imparted by the most recent contact-damage
  /// knockback, decremented toward zero over
  /// `CombatConstants.knockbackDuration`. Added on top of joystick-driven
  /// movement in `update()`, not instead of it — the player can still steer
  /// during a knockback.
  double _knockbackVelocityX = 0;
  double _knockbackRemaining = 0;

  PlayerComponent({required this.characterId});

  @override
  Future<void> onLoad() async {
    // 1.5x the native 52x68 art, same ratio as before (was 64x80 — barely
    // bigger than a 60x72 enemy, so the hero didn't read as the hero). The
    // boss already upscales its own native art by roughly this much (80x90
    // -> 120x140), so this brings the player closer to that same treatment
    // instead of sitting almost flush with regular enemies.
    size = Vector2(96, 120);
    position = Vector2(0, game.groundY - size.y);

    // Load walk frames as individual sprites and build the animation sequence
    final walkSprites = <Sprite>[];
    for (int i = 1; i <= 4; i++) {
      try {
        walkSprites.add(
            await game.loadSprite('characters/${characterId}_walk_$i.png'));
      } catch (e) {
        // Safe fallback placeholder if asset fails to load
        debugPrint('Failed to load character walk frame $i: $e');
      }
    }

    if (walkSprites.isNotEmpty) {
      walkAnimation = SpriteAnimation.spriteList(walkSprites, stepTime: 0.15);
    } else {
      // Emergency blank animation fallback
      walkAnimation = SpriteAnimation.spriteList([], stepTime: 1.0);
    }

    // Load single jump and hurt frames
    jumpAnim = SpriteAnimation.spriteList(
      [await game.loadSprite('characters/${characterId}_jump.png')],
      stepTime: 1.0,
    );
    hurtAnim = SpriteAnimation.spriteList(
      [await game.loadSprite('characters/${characterId}_hurt.png')],
      stepTime: 0.3,
    );

    animation = walkAnimation;
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_attackCooldownRemaining > 0) _attackCooldownRemaining -= dt;

    // Joystick-driven horizontal movement (GAMEPLAY-V2.md Section 3):
    // relativeDelta.x is already normalised to [-1, 1] by how far the knob
    // is pulled from center, so this both sets speed and direction.
    final horizontalInput = game.gameInput.joystick.relativeDelta.x;
    if (horizontalInput != 0) {
      position.x += forwardSpeed * horizontalInput * dt;
      facingRight = horizontalInput > 0;
    }

    // Knockback from contact damage — added on top of joystick movement,
    // not instead of it, so the player can still steer while shoved back.
    // Decays linearly to zero over CombatConstants.knockbackDuration rather
    // than cutting off sharply, so it reads as a shove losing momentum
    // instead of an abrupt stop.
    if (_knockbackRemaining > 0) {
      position.x += _knockbackVelocityX * dt;
      _knockbackRemaining -= dt;
      if (_knockbackRemaining <= 0) _knockbackVelocityX = 0;
    }

    // Never walk back past the level's start — there's no ground or
    // background authored to the left of it (Phase 4 gives levels real
    // bounds via Tiled).
    if (position.x < 0) position.x = 0;

    // A standing gate is a hard stop (GAMEPLAY-V2.md Section 6: "blocks the
    // full height of the corridor — you cannot jump it"). Clamped here in
    // update() rather than on collision so it holds on every frame the
    // player pushes against it, and so it works whether they arrive walking,
    // falling or knocked back. Only gates ahead of the player block: one
    // already passed must not pull them back.
    for (final gate in game.world.children.whereType<GateComponent>()) {
      if (!gate.isBlocking) continue;
      final limit = gate.blockX - size.x;
      if (position.x > limit && position.x < gate.position.x + gate.size.x) {
        position.x = limit;
      }
    }

    // Apply gravity
    if (!isOnGround) {
      velocityY += gravity * dt;
      position.y += velocityY * dt;
    }

    final onGround = resolveGroundContact();

    // Landed after a jump — swap back from the jump pose to the running
    // animation. Without this, the player stayed frozen in the jump frame
    // for the rest of the level after the first jump.
    if (onGround && !isOnGround && !isHurt) {
      animation = walkAnimation;
    }
    isOnGround = onGround;

    // Invincibility-frame flashing (GAMEPLAY-V2.md Section 5: "~1s of
    // invincibility frames (flashing sprite)"). Deliberately independent of
    // isHurt/triggerHurt()'s own timer — see _takeContactDamage().
    if (invincible) {
      _iframeTimer -= dt;
      _flashTimer -= dt;
      if (_flashTimer <= 0) {
        _flashTimer = CombatConstants.flashInterval;
        _flashVisible = !_flashVisible;
      }
      if (_iframeTimer <= 0) {
        invincible = false;
        _flashVisible = true;
      }
    }

    // Fall in gap handling
    if (position.y > game.size.y + 50) {
      game.playerFellInGap();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_flashVisible) return;

    if (facingRight) {
      super.render(canvas);
      return;
    }
    // Mirror the drawn sprite within its own bounding box: translate to the
    // right edge, then scale -1 so drawing runs back over [0, size.x]. Only
    // affects this render call's canvas — position/transform (and therefore
    // worldX and the hitbox) are untouched. Restored before children (the
    // hitbox) render, so it can't leak into their transform either.
    canvas.save();
    canvas.translate(size.x, 0);
    canvas.scale(-1, 1);
    super.render(canvas);
    canvas.restore();
  }

  void jump() {
    if (isOnGround) {
      velocityY = jumpForce;
      isOnGround = false;
      animation = jumpAnim;
      game.audioService.playJump();
    }
  }

  /// Swings the attack hitbox in the facing direction (GAMEPLAY-V2.md
  /// Section 3). Gated by both cooldown and charge cost — spending the
  /// charge is what can fail "with a small 'no charges' shake" per the
  /// design doc; the shake itself isn't built yet, this just declines to
  /// spawn a hitbox when there's nothing to spend.
  void attack() {
    if (_attackCooldownRemaining > 0) return;
    if (!game.trySpendCharge()) return;

    _attackCooldownRemaining = CombatConstants.attackCooldown;

    final hitboxSize = Vector2(
      CombatConstants.attackHitboxWidth,
      CombatConstants.attackHitboxHeight,
    );
    final offsetX = facingRight ? size.x : -hitboxSize.x;
    final offsetY = (size.y - hitboxSize.y) / 2;
    game.world.add(
      AttackHitboxComponent(
        position: position + Vector2(offsetX, offsetY),
        size: hitboxSize,
      ),
    );
  }

  void triggerHurt() {
    isHurt = true;
    animation = hurtAnim;
    game.audioService.playHurt();
    Future.delayed(const Duration(milliseconds: 600), () {
      isHurt = false;
      if (isOnGround) {
        animation = walkAnimation;
      }
    });
  }

  /// Brief celebratory pose on a correct quiz answer. There's no dedicated
  /// "cheer" art yet, so this reuses the already-loaded jump pose as a
  /// stand-in reaction — same idea as triggerHurt(), just a happy trigger
  /// instead of a damage one. Uses its own delayed revert rather than
  /// relying on update()'s on-ground-transition reset, since that only
  /// fires when isOnGround flips false->true (i.e. landing a jump), which
  /// never happens here if the player was already on the ground.
  void triggerCheer() {
    if (isHurt) return;
    animation = jumpAnim;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (isOnGround && !isHurt) {
        animation = walkAnimation;
      }
    });
  }

  void respawn() {
    // Only vertical state resets — worldX keeps advancing; the player fell
    // in a gap, they didn't warp backward in the world.
    position.y = game.groundY - size.y;
    velocityY = 0;
    isOnGround = true;
    animation = walkAnimation;
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is EnemyComponent && !other.defeated) {
      // Contact damage (GAMEPLAY-V2.md Section 5), not the quiz — enemies
      // no longer open it on contact. Knockback pushes away from wherever
      // the enemy actually is, in whichever direction that is.
      _takeContactDamage(
        knockbackDirection: worldX < other.position.x ? -1 : 1,
      );
    }
    if (other is CoinComponent && !other.collected) {
      other.collect();
      game.collectCoin();
    }
    if (other is ArtifactComponent && other.isInteractable) {
      // Walk into it and the question opens (GAMEPLAY-V2.md Section 6).
      // No damage, ever — an artifact is an opportunity, not a hazard.
      game.showArtifactQuestion(other);
    }
    if (other is GateComponent && other.isBlocking && !other.questionPending) {
      // Gates block rather than hurt. The hold is applied in update() so it
      // survives every frame the player leans on it, not just this one.
      game.showGateQuestion(other);
    }
  }

  /// The one place contact damage (enemy touch or wall) is decided from.
  /// Early-returns while [invincible] is already true — this is the "don't
  /// get chain-hit" guard (Section 5), and it's what stops a wall from
  /// landing a second hit inside an enemy's own i-frame window, or vice
  /// versa, regardless of which triggered first. Deliberately separate
  /// from `isHurt`/`triggerHurt()`'s own, shorter 600ms animation-swap-back
  /// timer: invincibility (1.0s) is a render-layer flash, hurt (0.6s) is
  /// which animation frames play, and the two windows don't share a clock.
  void _takeContactDamage({required int knockbackDirection}) {
    if (invincible) return;

    game.loseLife();
    _knockbackVelocityX = CombatConstants.knockbackForce * knockbackDirection;
    _knockbackRemaining = CombatConstants.knockbackDuration;
    invincible = true;
    _iframeTimer = CombatConstants.invincibilityDuration;
  }
}
