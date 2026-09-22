import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../chrono_game.dart';
import '../quiz_handler.dart';
import 'enemy_component.dart';
import 'coin_component.dart';
import 'wall_component.dart';
import 'crate_component.dart';

/// Player character — advances through the world at a constant forward
/// speed (`position.x` is the player's real world x-position, `worldX`),
/// student taps to jump. The camera follows `worldX` so the player always
/// renders at a fixed screen offset; the player never moves itself in
/// screen space. Displays real walk, jump, and hurt sprite animations.
class PlayerComponent extends SpriteAnimationComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  static const double gravity = 900.0;
  static const double jumpForce = -480.0;

  /// Constant forward speed, in world units/second, the player advances at.
  /// This is the single source of the game's forward motion — the camera,
  /// spawn positions, and despawn checks all derive from `worldX`, which
  /// increases at this rate.
  static const double forwardSpeed = 150.0;

  /// The player's real position in world space. Aliases `position.x` —
  /// obstacles/camera never subtract a scroll speed from themselves;
  /// instead this value increases every frame and everything else is
  /// positioned relative to it.
  double get worldX => position.x;

  double velocityY = 0.0;
  bool isOnGround = false;
  bool isHurt = false;
  final String characterId;

  late SpriteAnimation walkAnimation;
  late SpriteAnimation jumpAnim;
  late SpriteAnimation hurtAnim;

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

    // Constant forward advance through the world.
    position.x += forwardSpeed * dt;

    // Apply gravity
    if (!isOnGround) {
      velocityY += gravity * dt;
      position.y += velocityY * dt;
    }

    // Check if on any ground section
    bool onGround = false;
    for (final section in game.groundSections) {
      if (position.x + size.x > section.position.x &&
          position.x < section.position.x + section.size.x &&
          position.y + size.y >= section.position.y &&
          position.y + size.y <= section.position.y + 20) {
        position.y = section.position.y - size.y;
        velocityY = 0;
        onGround = true;
        break;
      }
    }
    // Check if on any elevated tile platform — only while falling/resting
    // (velocityY >= 0) so jumping up into a platform from below doesn't
    // snap the player onto its surface.
    if (!onGround && velocityY >= 0) {
      for (final platform in game.platforms) {
        if (position.x + size.x > platform.position.x &&
            position.x < platform.position.x + platform.size.x &&
            position.y + size.y >= platform.surfaceY &&
            position.y + size.y <= platform.surfaceY + 20) {
          position.y = platform.surfaceY - size.y;
          velocityY = 0;
          onGround = true;
          break;
        }
      }
    }

    // Landed after a jump — swap back from the jump pose to the running
    // animation. Without this, the player stayed frozen in the jump frame
    // for the rest of the level after the first jump.
    if (onGround && !isOnGround && !isHurt) {
      animation = walkAnimation;
    }
    isOnGround = onGround;

    // Fall in gap handling
    if (position.y > game.size.y + 50) {
      game.playerFellInGap();
    }
  }

  void jump() {
    if (isOnGround) {
      velocityY = jumpForce;
      isOnGround = false;
      animation = jumpAnim;
      game.audioService.playJump();
    }
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

    if (other is EnemyComponent && !game.questionShowing && !other.defeated) {
      game.showQuestion(other.question, other);
    }
    if (other is CoinComponent && !other.collected) {
      other.collect();
      game.collectCoin();
    }
    if (other is WallComponent && !isHurt) {
      // Player failed to jump over the wall in time — this used to snap
      // the player's position up onto the wall (looked like an automatic,
      // unintended jump) with no actual consequence. Now it deals damage,
      // consistent with falling in a gap, and the wall is removed so it
      // can't linger and double-hit on subsequent frames.
      other.removeFromParent();
      game.playerHitObstacle();
    }
    if (other is CrateComponent && !isHurt) {
      // Same obstacle behavior as WallComponent.
      other.removeFromParent();
      game.playerHitObstacle();
    }
  }
}
