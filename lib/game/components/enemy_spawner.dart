import 'dart:math';
import '../../models/question.dart';
import '../chrono_game.dart';
import 'enemy_component.dart';
import 'player_component.dart';
import 'wall_component.dart';
import 'coin_component.dart';
import 'crate_component.dart';
import 'tile_platform_component.dart';
import '../../core/constants.dart';

/// Spawns enemies, walls, and coins ahead of the camera as the player
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

  final Random _random = Random();
  double _wallTimer = 0;
  double _coinTimer = 0;
  double _crateTimer = 0;
  double _platformTimer = 0;

  EnemySpawner({required this.game, required this.questions});

  void update(double dt) {
    distanceTraveled += PlayerComponent.forwardSpeed * dt;
    if (distanceTraveled >= spawnInterval && nextIndex < questions.length) {
      _spawnEnemy();
      distanceTraveled = 0;
    }
    if (nextIndex >= questions.length) allEnemiesSpawned = true;
    _wallTimer += dt;
    if (_wallTimer > 3.0 + _random.nextDouble() * 4.0) {
      _wallTimer = 0;
      if (!game.questionShowing) _spawnWall();
    }
    _coinTimer += dt;
    if (_coinTimer > 1.5 + _random.nextDouble() * 2.0) {
      _coinTimer = 0;
      if (!game.questionShowing) _spawnCoin();
    }
    _crateTimer += dt;
    if (_crateTimer > 4.0 + _random.nextDouble() * 4.0) {
      _crateTimer = 0;
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

  void _spawnWall() {
    final wall = WallComponent();
    game.world.add(wall);
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
    final surfaceY = game.groundY - 60 - _random.nextDouble() * 100;
    final platform = TilePlatformComponent(
      widthInTiles: widthInTiles,
      surfaceY: surfaceY,
    );
    game.world.add(platform);
  }
}
