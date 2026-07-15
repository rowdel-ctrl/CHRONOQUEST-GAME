import 'dart:math';
import '../../models/question.dart';
import '../chrono_game.dart';
import 'enemy_component.dart';
import 'wall_component.dart';
import 'coin_component.dart';

/// Spawns enemies, walls, and coins at intervals as the world scrolls.
/// Each enemy carries one quiz question from the pre-fetched list.
class EnemySpawner {
  final ChronoGame game;
  final List<Question> questions;
  double distanceTraveled = 0.0;
  double spawnInterval = 500.0;
  int nextIndex = 0;
  bool allEnemiesSpawned = false;

  final Random _random = Random();
  double _wallTimer = 0;
  double _coinTimer = 0;

  EnemySpawner({required this.game, required this.questions});

  void update(double dt) {
    distanceTraveled += ChronoGame.worldScrollSpeed * dt;

    // Spawn enemy at interval
    if (distanceTraveled >= spawnInterval && nextIndex < questions.length) {
      _spawnEnemy();
      distanceTraveled = 0;
    }

    if (nextIndex >= questions.length) {
      allEnemiesSpawned = true;
    }

    // Spawn walls periodically
    _wallTimer += dt;
    if (_wallTimer > 3.0 + _random.nextDouble() * 4.0) {
      _wallTimer = 0;
      if (!game.questionShowing) {
        _spawnWall();
      }
    }

    // Spawn coins periodically
    _coinTimer += dt;
    if (_coinTimer > 1.5 + _random.nextDouble() * 2.0) {
      _coinTimer = 0;
      if (!game.questionShowing) {
        _spawnCoin();
      }
    }
  }

  void _spawnEnemy() {
    final enemy = EnemyComponent(
      question: questions[nextIndex],
      eraId: game.currentEra,
    );
    game.add(enemy);
    nextIndex++;
  }

  void _spawnWall() {
    final wall = WallComponent();
    game.add(wall);
  }

  void _spawnCoin() {
    final coin = CoinComponent();
    game.add(coin);
  }
}
