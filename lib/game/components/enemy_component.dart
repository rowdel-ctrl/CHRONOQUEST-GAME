import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../chrono_game.dart';

/// Enemy that walks left toward the player.
/// Renders 2-frame walk cycle from image files.
class EnemyComponent extends SpriteAnimationComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  final Question question;
  final String eraId;
  static const double moveSpeed = 90.0;
  bool defeated = false;

  late final String _enemyType;

  // Cached velocity for zero-allocation updates
  final Vector2 _velocity = Vector2.zero();

  EnemyComponent({required this.question, required this.eraId});

  @override
  Future<void> onLoad() async {
    _enemyType = _getEnemyTypeForEra(eraId);

    // Load the 2-frame walking cycle
    final frame1 = await game.loadSprite('enemies/${_enemyType}_1.png');
    final frame2 = await game.loadSprite('enemies/${_enemyType}_2.png');

    animation = SpriteAnimation.spriteList(
      [frame1, frame2],
      stepTime: 0.3,
    );

    size = Vector2(60, 72);
    position = Vector2(
      game.size.x + 60,
      game.groundY - size.y,
    );
    add(
      TextComponent(
        text: '?',
        position: Vector2(size.x / 2, -14),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.yellow,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!defeated) {
      _velocity.setValues(-moveSpeed, 0);
      position.addScaled(_velocity, dt);
      if (position.x < -size.x) {
        removeFromParent();
      }
    }
  }

  void defeat() {
    defeated = true;
    game.audioService.playEnemyDefeat();
    removeFromParent();
  }

  String _getEnemyTypeForEra(String era) {
    final enemies = {
      'pre-colonial': ['tribal_warrior', 'dark_spirit'],
      'spanish': ['spanish_soldier', 'tax_collector'],
      'american': ['american_soldier', 'propaganda'],
      'ww2': ['japanese_soldier', 'tank'],
      'modern': ['corruption_figure', 'misinfo_cloud'],
    };
    final list = enemies[era] ?? ['spanish_soldier'];
    return list[Random().nextInt(list.length)];
  }
}
