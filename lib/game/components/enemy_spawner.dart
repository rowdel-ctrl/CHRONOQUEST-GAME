import 'dart:math';
import '../../models/question.dart';
import '../chrono_game.dart';
import 'enemy_component.dart';
import 'coin_component.dart';
import 'tile_platform_component.dart';
import '../../core/constants.dart';

/// Spawns enemies and coins ahead of the camera as the player advances
/// through the world. Each enemy carries one quiz question from the
/// pre-fetched list.
class EnemySpawner {
  final ChronoGame game;
  final List<Question> questions;
  double distanceTraveled = 0.0;
  double spawnInterval = GameConstants.spawnInterval;
  int nextIndex = 0;
  bool allEnemiesSpawned = false;

  /// The player's furthest-right `worldX` reached so far — the high-water
  /// mark spawning distance is measured from (GAMEPLAY-V2.md Section 14,
  /// Phase 1: distance used to accumulate from a compile-time constant
  /// forward speed, which desyncs the moment speed becomes player-controlled
  /// — standing still still "traveled", and backtracking re-triggered
  /// spawns). Only forward progress past the previous best adds distance, so
  /// standing still adds none and backtracking over already-spawned ground
  /// never re-spawns it.
  late double _furthestX;

  /// How many enemies have been spawned so far.
  int get spawnedCount => nextIndex;

  /// Total number of enemies (questions) for this level.
  int get totalEnemies => questions.length;

  /// Platform surfaces spawn between these heights above the ground, in world
  /// units. The player's jump peaks at about 128 (jumpForce² / 2·gravity), so
  /// the top of the range has to stay well under that or some platforms can't
  /// be reached from the ground — platform_layering_test.dart holds the max
  /// to `jumpPeak - 15` and proves a jump still lands on it at 60fps, at
  /// 30fps, and through a frame hitch.
  ///
  /// The old 60 floor put the lowest platforms at knee height on a 120-tall
  /// player: they read as steps to walk into rather than ledges to jump
  /// onto. Raised so the whole range sits between the player's shoulders
  /// and the top of their head, which is as high as the jump arc allows.
  static const double platformMinHeight = 90;
  static const double platformMaxHeight = 110;

  final Random _random = Random();

  double _coinTimer = 0;
  double _platformTimer = 0;

  EnemySpawner({required this.game, required this.questions}) {
    _furthestX = game.player.worldX;
  }

  void update(double dt) {
    final progressX = game.player.worldX;
    if (progressX > _furthestX) {
      distanceTraveled += progressX - _furthestX;
      _furthestX = progressX;
    }
    if (distanceTraveled >= spawnInterval && nextIndex < questions.length) {
      _spawnEnemy();
      distanceTraveled = 0;
    }
    if (nextIndex >= questions.length) allEnemiesSpawned = true;
    _coinTimer += dt;
    if (_coinTimer > 1.5 + _random.nextDouble() * 2.0) {
      _coinTimer = 0;
      if (!game.questionShowing) _spawnCoin();
    }
    _platformTimer += dt;
    if (_platformTimer > 5.0 + _random.nextDouble() * 5.0) {
      _platformTimer = 0;
      if (!game.questionShowing) _spawnPlatform();
    }
  }

  void _spawnEnemy() {
    final enemy = EnemyComponent(
      question: questions[nextIndex],
      eraId: game.currentEra,
    );
    game.world.add(enemy);
    nextIndex++;
  }

  void _spawnCoin() {
    final coin = CoinComponent();
    game.world.add(coin);
  }

  void _spawnPlatform() {
    final widthInTiles = 3 + _random.nextInt(4); // 3-6 tiles wide
    final surfaceY = game.groundY -
        platformMinHeight -
        _random.nextDouble() * (platformMaxHeight - platformMinHeight);
    final platform = TilePlatformComponent(
      widthInTiles: widthInTiles,
      surfaceY: surfaceY,
    );
    game.world.add(platform);
  }
}
