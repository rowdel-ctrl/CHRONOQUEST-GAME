import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import '../answer_point_handler.dart';
import '../boss_countdown.dart';
import '../chrono_game.dart';
import '../quiz_handler.dart';
import '../../core/constants.dart';
import '../../models/question.dart';
import 'enemy_component.dart';

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

  // The fight: a question, then a wave of minions, then the next question.
  Question? _lastQuestion;
  final List<EnemyComponent> _minions = [];
  int _wave = 0;
  bool _waveActive = false;
  double _waveTime = 0;

  /// Seconds until the next thing happens (the wave arriving, or the next
  /// question). Counted in [update], so it stops while a question is open.
  double _pause = 0;
  VoidCallback? _afterPause;

  BossComponent({required this.eraId});

  @override
  Future<void> onLoad() async {
    final bossName = getEraById(eraId).bossName;
    idleSprite     = await game.loadSprite('bosses/${bossName}_idle.png');
    attackSprite   = await game.loadSprite('bosses/${bossName}_attack.png');
    defeatedSprite = await game.loadSprite('bosses/${bossName}_defeated.png');

    sprite = idleSprite;
    size = Vector2(120, 140);
    position = Vector2(game.cameraRightEdgeX + 20, game.groundY - size.y);
    game.audioService.playBossAppear();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDefeated) return;

    // Recomputed every frame since the camera keeps advancing with the
    // player — this is the world x that currently sits at screen-center.
    final centerX = game.cameraLeftEdgeX + game.size.x / 2 - size.x / 2;
    if (!reachedCenter) {
      _velocity.setValues(-walkSpeed, 0);
      position.addScaled(_velocity, dt);
      if (position.x <= centerX) {
        position.x = centerX;
        reachedCenter = true;
        _showBossQuestion();
      }
    } else {
      // Stay locked at screen-center as the world advances underneath.
      position.x = centerX;
      _updateFight(dt);
    }
  }

  void _updateFight(double dt) {
    if (_afterPause != null) {
      _pause -= dt;
      if (_pause <= 0) {
        final next = _afterPause!;
        _afterPause = null;
        next();
      }
      return;
    }
    if (!_waveActive) return;

    _waveTime += dt;
    // A minion still loading is not mounted yet, so it is not "gone" until it
    // has loaded and then left the world.
    _minions.removeWhere((m) => m.defeated || (m.isLoaded && !m.isMounted));
    if (_minions.isEmpty || _waveTime >= GameConstants.bossWaveTimeoutSeconds) {
      _waveActive = false;
      _after(0.5, _showBossQuestion);
    }
  }

  void _after(double seconds, VoidCallback what) {
    _pause = seconds;
    _afterPause = what;
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
      _after(0.8, _spawnWave);
    }
  }

  /// A wrong answer, or the clock running out: the boss takes no damage, and
  /// the minions come all the same.
  void missed() {
    if (isDefeated) return;
    _after(0.8, _spawnWave);
  }

  void _spawnWave() {
    final count = minionsInWave(_wave++);
    // Just past the right edge, so they walk into view and the student has to
    // go and meet them.
    final firstX = game.cameraRightEdgeX + 40;
    for (var i = 0; i < count; i++) {
      final minion = EnemyComponent(
        eraId: eraId,
        worldX: firstX + i * 130,
        onDefeated: () {
          game.grantCharges(1);
          game.audioService.playPowerup();
        },
      );
      _minions.add(minion);
      game.world.add(minion);
    }
    _waveActive = true;
    _waveTime = 0;
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
    // A different question each time; a wrong answer is never repeated at once.
    final q = game.drawQuestion(exclude: _lastQuestion);
    if (q == null) {
      defeat(); // a boss with no questions cannot be fought
      return;
    }
    _lastQuestion = q;
    game.showBossQuestion(q, this);
  }
}