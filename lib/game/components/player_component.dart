import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../chrono_game.dart';
import '../game_collision.dart';
import '../quiz_handler.dart';
import 'enemy_component.dart';
import 'coin_component.dart';
import 'wall_component.dart';

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

    // Joystick-driven horizontal movement (GAMEPLAY-V2.md Section 3):
    // relativeDelta.x is already normalised to [-1, 1] by how far the knob
    // is pulled from center, so this both sets speed and direction.
    final horizontalInput = game.gameInput.joystick.relativeDelta.x;
    if (horizontalInput != 0) {
      position.x += forwardSpeed * horizontalInput * dt;
      facingRight = horizontalInput > 0;
    }
    // Never walk back past the level's start — there's no ground or
    // background authored to the left of it (Phase 4 gives levels real
    // bounds via Tiled).
    if (position.x < 0) position.x = 0;

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

    // Fall in gap handling
    if (position.y > game.size.y + 50) {
      game.playerFellInGap();
    }
  }

  @override
  void render(Canvas canvas) {
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
  }
}
