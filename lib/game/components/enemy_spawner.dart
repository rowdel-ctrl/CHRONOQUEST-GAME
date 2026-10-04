import 'dart:math';
import '../chrono_game.dart';
import 'enemy_component.dart';
import 'coin_component.dart';
import 'tile_platform_component.dart';
import '../../core/constants.dart';

/// Spawns enemies, coins and platforms ahead of the camera as the player
/// advances through the world.
///
/// Enemies no longer carry a question (GAMEPLAY-V2.md Section 15, Phase 2:
/// contact no longer opens the quiz), so there's no fixed per-level roster
/// to spawn through — any Walker or Heavy is behaviourally interchangeable
/// with any other. Enemies now spawn periodically off distance travelled,
/// uncapped, the same rhythm coins and platforms already use on their own
/// independent timers below, rather than working through a finite list.
class EnemySpawner {
  final ChronoGame game;
  double distanceTraveled = 0.0;
  double spawnInterval = GameConstants.spawnInterval;

  /// The player's furthest-right `worldX` reached so far — the high-water
  /// mark spawning distance is measured from (GAMEPLAY-V2.md Section 14,
  /// Phase 1: distance used to accumulate from a compile-time constant
  /// forward speed, which desyncs the moment speed becomes player-controlled
  /// — standing still still "traveled", and backtracking re-triggered
  /// spawns). Only forward progress past the previous best adds distance, so
  /// standing still adds none and backtracking over already-spawned ground
  /// never re-spawns it.
  late double _furthestX;

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
  /// Raised again to 104 (2026-10-04): an enemy's hit area reaches 99.9 above
  /// the ground, so anything lower lets an enemy touch a student standing on
  /// the platform.
  static const double platformMinHeight = 104;

  /// Bumped to exactly `jumpPeak - 15` (113) — the ceiling
  /// `platform_layering_test.dart`'s "spawn no higher than the jump can
  /// reach" test already enforces, so this can't be raised further without
  /// that test failing loudly first.
  static const double platformMaxHeight = 113;

  final Random _random = Random();

  double _coinTimer = 0;
  double _platformTimer = 0;

  EnemySpawner({required this.game}) {
    _furthestX = game.player.worldX;
  }

  void update(double dt) {
    final progressX = game.player.worldX;
    if (progressX > _furthestX) {
      distanceTraveled += progressX - _furthestX;
      _furthestX = progressX;
    }
    if (distanceTraveled >= spawnInterval) {
      _spawnEnemy();
      distanceTraveled = 0;
    }
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
    final enemy = EnemyComponent(eraId: game.currentEra);
    game.world.add(enemy);
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
