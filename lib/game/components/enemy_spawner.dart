import 'dart:math';
import '../../models/question.dart';
import '../chrono_game.dart';
import 'enemy_component.dart';
import 'player_component.dart';
import 'coin_component.dart';
import 'crate_component.dart';
import 'tile_platform_component.dart';
import '../../core/constants.dart';

/// Spawns enemies, crates, and coins ahead of the camera as the player
/// advances through the world. Each enemy carries one quiz question from
/// the pre-fetched list.
class EnemySpawner {
  final ChronoGame game;
  final List<Question> questions;
  double distanceTraveled = 0.0;
  double spawnInterval = GameConstants.spawnInterval;
  int nextIndex = 0;
  bool allEnemiesSpawned = false;

  /// How many enemies have been spawned so far.
  int get spawnedCount => nextIndex;

  /// Total number of enemies (questions) for this level.
  int get totalEnemies => questions.length;

  /// Platform surfaces spawn between these heights above the ground, in world
  /// units. The player's jump peaks at about 128 (jumpForce² / 2·gravity), so
  /// the top of the range has to stay well under that or some platforms can't
  /// be reached from the ground.
  static const double platformMinHeight = 60;
  static const double platformMaxHeight = 105;

  final Random _random = Random();

  /// Two independent crate timers. Ground obstacles used to be a mix of
  /// era-specific wall sprites (WallComponent, obstacles/*_wall.png) and
  /// crates; crates replaced the wall art, and keeping both timers with
  /// their original intervals preserves the combined obstacle cadence.
  double _crateTimerA = 0;
  double _crateTimerB = 0;
  double _coinTimer = 0;
  double _platformTimer = 0;

  EnemySpawner({required this.game, required this.questions});

  void update(double dt) {
    distanceTraveled += PlayerComponent.forwardSpeed * dt;
    if (distanceTraveled >= spawnInterval && nextIndex < questions.length) {
      _spawnEnemy();
      distanceTraveled = 0;
    }
    if (nextIndex >= questions.length) allEnemiesSpawned = true;
    _crateTimerA += dt;
    if (_crateTimerA > 3.0 + _random.nextDouble() * 4.0) {
      _crateTimerA = 0;
      if (!game.questionShowing) _spawnCrate();
    }
    _coinTimer += dt;
    if (_coinTimer > 1.5 + _random.nextDouble() * 2.0) {
      _coinTimer = 0;
      if (!game.questionShowing) _spawnCoin();
    }
    _crateTimerB += dt;
    if (_crateTimerB > 4.0 + _random.nextDouble() * 4.0) {
      _crateTimerB = 0;
      if (!game.questionShowing) _spawnCrate();
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

  void _spawnCrate() {
    final crate = CrateComponent();
    game.world.add(crate);
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
