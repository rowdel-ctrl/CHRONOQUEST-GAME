import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import '../answer_point_handler.dart';
import '../boss_countdown.dart';
import '../chrono_game.dart';
import '../quiz_handler.dart';
import '../../core/constants.dart';
import '../../models/question.dart';
import '../level_loader.dart';
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

  /// The boss arena this fight happens in, or null for the old open-ground
  /// fight. In an arena the boss is already standing where the map put it and
  /// the camera does not follow the player out of the room.
  final LoadedLevel? arena;

  BossComponent({required this.eraId, this.arena});

  @override
  Future<void> onLoad() async {
    final bossName = getEraById(eraId).bossName;
    idleSprite     = await game.loadSprite('bosses/${bossName}_idle.png');
    attackSprite   = await game.loadSprite('bosses/${bossName}_attack.png');
    defeatedSprite = await game.loadSprite('bosses/${bossName}_defeated.png');

    sprite = idleSprite;
    size = Vector2(120, 140);
    final room = arena?.boss;
    if (room != null) {
      // Standing in place, the question coming after a moment to take the room in.
      position = Vector2(room.x - size.x / 2, room.y - size.y);
      reachedCenter = true;
      _after(1.8, _showBossQuestion);
    } else {
      position = Vector2(game.cameraRightEdgeX + 20, game.groundY - size.y);
    }
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
      // Stay locked at screen-center as the world advances underneath. In an
      // arena the boss keeps the place the map gave it.
      if (arena == null) position.x = centerX;
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

  /// Where the [count] minions of a wave stand (left x, and the surface they
  /// stand on, or null for the base ground).
  ///
  /// In an arena they come from the map's spots, the ones furthest from the
  /// player first and alternating sides, so a wave is spread across the room
  /// and never lands on the student. With no arena they stand just past the
  /// right edge of the screen, as before.
  List<({double x, double? surfaceY})> _spotsForWave(int count) {
    final spots = arena?.minionSpawns ?? const [];
    if (spots.isEmpty) {
      final firstX = game.cameraRightEdgeX + 40;
      return [for (var i = 0; i < count; i++) (x: firstX + i * 130, surfaceY: null)];
    }
    final playerX = game.player.worldX + game.player.size.x / 2;
    final byDistance = [...spots]
      ..sort((a, b) => (b.x - playerX).abs().compareTo((a.x - playerX).abs()));
    final out = <({double x, double? surfaceY})>[];
    for (var i = 0; i < count; i++) {
      final s = byDistance[i % byDistance.length];
      // Two minions never share a spot: the next one is nudged along.
      final nudge = (i ~/ byDistance.length) * 90.0;
      out.add((
        x: s.x - EnemyComponent.spriteWidth / 2 + nudge,
        surfaceY: s.y < game.groundY - 1 ? s.y : null,
      ));
    }
    return out;
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
    final spots = _spotsForWave(count);
    for (var i = 0; i < count; i++) {
      final minion = EnemyComponent(
        eraId: eraId,
        worldX: spots[i].x,
        surfaceY: spots[i].surfaceY,
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