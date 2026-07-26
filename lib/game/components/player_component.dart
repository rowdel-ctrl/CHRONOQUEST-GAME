import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../chrono_game.dart';
import 'enemy_component.dart';
import 'coin_component.dart';
import 'wall_component.dart';
/// Player character — runs at fixed X position, student taps to jump.
/// Displays real walk, jump, and hurt sprite animations.
class PlayerComponent extends SpriteAnimationComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  static const double gravity = 900.0;
  static const double jumpForce = -480.0;

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
    size = Vector2(64, 80);
    position = Vector2(80, game.groundY - size.y);

    // Load walk frames as individual sprites and build the animation sequence
    final walkSprites = <Sprite>[];
    for (int i = 1; i <= 4; i++) {
      try {
        walkSprites.add(await game.loadSprite('characters/${characterId}_walk_$i.png'));
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
    isOnGround = onGround;

    // Fall in gap handling
    if (position.y > game.size.y + 50) {
      game.playerFellInGap();
    }

    // Ground clamp fallback
    if (position.y >= game.groundY - size.y && !isOnGround) {
      position.y = game.groundY - size.y;
      velocityY = 0;
      isOnGround = true;
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

  void respawn() {
    position = Vector2(80, game.groundY - size.y);
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
    if (other is WallComponent) {
      if (position.y + size.y > other.position.y && velocityY >= 0) {
        position.y = other.position.y - size.y;
        velocityY = 0;
        isOnGround = true;
        animation = walkAnimation;
      }
    }
  }
}