import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../chrono_game.dart';
import 'enemy_component.dart';
import '../../core/constants.dart';

/// Boss component — displays actual images for idle, attack, and defeated states.
class BossComponent extends SpriteComponent with HasGameReference<ChronoGame> {
  final String eraId;
  int health = GameConstants.bossHealth;
  int maxHealth = GameConstants.bossHealth;
  bool reachedCenter = false;
  static const double walkSpeed = 50.0;
  bool isDefeated = false;

  late Sprite idleSprite;
  late Sprite attackSprite;
  late Sprite defeatedSprite;

  // Cached velocity
  final Vector2 _velocity = Vector2.zero();
  int _bossQuestionIndex = 0;

  BossComponent({required this.eraId});

  @override
  Future<void> onLoad() async {
    final bossName = _getBossNameForEra(eraId);
    idleSprite     = await game.loadSprite('bosses/${bossName}_idle.png');
    attackSprite   = await game.loadSprite('bosses/${bossName}_attack.png');
    defeatedSprite = await game.loadSprite('bosses/${bossName}_defeated.png');

    sprite = idleSprite;
    size = Vector2(120, 140);
    position = Vector2(game.size.x + 20, game.groundY - size.y);
    game.audioService.playBossAppear();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDefeated) return;

    if (!reachedCenter) {
      _velocity.setValues(-walkSpeed, 0);
      position.addScaled(_velocity, dt);
      final centerX = game.size.x / 2 - size.x / 2;
      if (position.x <= centerX) {
        position.x = centerX;
        reachedCenter = true;
        _showBossQuestion();
      }
    }
  }

  void takeDamage() {
    health--;
    sprite = attackSprite;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!isDefeated) {
        sprite = idleSprite;
      }
    });

    if (health <= 0) {
      defeat();
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!isDefeated) {
          _showBossQuestion();
        }
      });
    }
  }

  void defeat() {
    isDefeated = true;
    sprite = defeatedSprite;
    game.audioService.playBossDefeat();
    game.overlays.remove('BossHealthOverlay');
    Future.delayed(const Duration(seconds: 1), () {
      removeFromParent();
      game.levelComplete();
    });
  }

  void _showBossQuestion() {
    if (_bossQuestionIndex >= game.bossQuestions.length) return;
    final q = game.bossQuestions[_bossQuestionIndex];
    _bossQuestionIndex++;
    game.showBossQuestion(q, this);
  }

  String _getBossNameForEra(String era) {
    const names = {
      'pre-colonial': 'bakunawa',
      'spanish':      'governor',
      'american':     'general',
      'ww2':          'commander',
      'modern':       'corruption_boss',
    };
    return names[era] ?? 'governor';
  }
}