import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../core/combat_constants.dart';
import '../core/constants.dart';
import '../data/question_bank.dart';
import '../data/question_pool.dart';
import 'chrono_game.dart';
import 'components/artifact_component.dart';
import 'components/enemy_spawner.dart';
import 'components/gap_component.dart';
import 'components/gate_component.dart';
import 'level_loader.dart';

/// Sets up and drives level content for [ChronoGame]. Split out of
/// chrono_game.dart's onLoad()/update() as part of the Phase 1 refactor
/// (GAMEPLAY-V2.md Section 15).
///
/// **Phase 4 is migrating this from generation to loading.** Section 11
/// replaces the runtime spawner with hand-authored Tiled maps. Both paths
/// live here during the migration: a level with a `.tmx` loads it, and one
/// without still falls back to the procedural spawner, so the game stays
/// playable for all 43 levels while only `era1_1` has a real map. The
/// fallback (and `GroundSpawner`/`EnemySpawner` with it) goes away once
/// every level has been authored.
extension GameSpawning on ChronoGame {
  /// Called once from onLoad(), after `player` exists.
  ///
  /// Async because the Tiled path reads a file from the asset bundle. The
  /// caller awaits it, so nothing can observe a half-built level.
  Future<void> setupSpawning() async {
    // Questions are intentionally bundled with the app — no backend
    // round-trip.
    questionPool = QuestionPool.forLevel(currentEra, currentLevel);

    final loaded = await _tryLoadTiledLevel();
    if (loaded != null) {
      _buildTiledLevel(loaded);
      return;
    }

    _setupProceduralLevel();
  }

  /// Loads this level's `.tmx` if one has been authored, else null.
  ///
  /// Failures are deliberately soft: a missing file is the normal case
  /// during the migration, and a malformed one should not black-screen a
  /// student mid-lesson — both fall through to the procedural path, which
  /// is known to produce a playable level.
  Future<LoadedLevel?> _tryLoadTiledLevel() async {
    final eraNumber = eraNumberFor(currentEra);
    if (eraNumber == 0) return null;
    if (!LevelLoader.exists(eraNumber, currentLevel)) return null;
    try {
      return await LevelLoader.load(eraNumber, currentLevel);
    } catch (e) {
      // A malformed or missing map must not black-screen a student
      // mid-lesson: fall through to the procedural path, which is known to
      // produce a playable level.
      debugPrint('LevelLoader: falling back to the spawner for '
          '$currentEra/$currentLevel — $e');
      return null;
    }
  }

  /// Instantiates an authored level and points the player at its spawn.
  void _buildTiledLevel(LoadedLevel level) {
    LevelBuilder.build(
      level: level,
      world: world,
      groundY: groundY,
      eraId: currentEra,
    );

    tiledLevel = level;
    artifactsTotal = level.entities.where((e) => e.type == 'artifact').length;

    player.position = Vector2(level.spawnX, groundY - player.size.y);
    // Seed the fall-respawn anchor, so falling into a gap before ever
    // touching ground still returns the player somewhere they can stand.
    player.respawnAnchorX = level.spawnX;

    if (level.kaalamanStart != null) {
      kaalaman = level.kaalamanStart!;
    }

    // Boss levels still draw their question list up front — the boss asks a
    // fixed sequence, a different shape from the pool's serve-one-at-a-time.
    // Section 15 defers the boss rework to Phase 5.
    if (isBossLevel) {
      bossQuestions = QuestionBank.getQuestions(currentEra, currentLevel)
          .skip(GameConstants.bossWarmupQuestions)
          .toList();
    }
  }

  /// The pre-Phase-4 path: procedural ground and runtime spawners.
  void _setupProceduralLevel() {
    final ground = GroundSpawner(game: this);
    ground.spawnInitialGround();
    groundSpawner = ground;
    spawner = EnemySpawner(game: this);

    if (isBossLevel) {
      // Boss levels keep the old batch draw: the boss asks a fixed list of
      // questions in sequence, which is a different shape from the pool's
      // serve-one-at-a-time. Section 15 defers the boss rework to Phase 5.
      bossQuestions = QuestionBank.getQuestions(currentEra, currentLevel)
          .skip(GameConstants.bossWarmupQuestions)
          .toList();
    } else {
      // Artifacts and gates are laid out for the whole level up front
      // rather than spawned on a distance timer like enemies. Section 6
      // asks for an exact count of each ("3 gates in every level"), which a
      // rolling timer cannot guarantee — the level would end mid-interval
      // having placed some other number.
      _placeAnswerPoints();
    }
  }

  /// Distributes the level's artifacts and its single end gate.
  ///
  /// Artifacts are spread evenly across the level, and one gate stands near
  /// the end as the level's exit. The gate asks nothing: it opens once every
  /// artifact has been answered (GAMEPLAY-V2.md Section 6). Everything is
  /// kept clear of the level's very start, where the player spawns.
  ///
  /// This used to place three gates part-way through, which became a
  /// softlock the moment gates required every artifact to be answered: the
  /// first gate sat at 1/4 of the level with only one artifact behind it, so
  /// the student was stopped and told to find artifacts they could not reach.
  /// One gate after all the artifacts makes that impossible by construction.
  void _placeAnswerPoints() {
    final length = currentLevelData.lengthUnits;
    const usableStart = GameConstants.playerX + 600;
    final usableEnd = length - 600;
    final usable = usableEnd - usableStart;
    if (usable <= 0) return;

    const artifactCount = CombatConstants.artifactsPerLevel;
    artifactsTotal = artifactCount;
    for (var i = 0; i < artifactCount; i++) {
      final x = usableStart + usable * ((i + 0.5) / artifactCount);
      world.add(
        ArtifactComponent(
          worldX: x,
          // Cycle the five sprites; only 5 exist for 6 eras (Section 6), so
          // they repeat, distinguished by the per-era tint.
          spriteIndex: (i % 5) + 1,
        ),
      );
    }

    world.add(GateComponent(worldX: usableEnd, isLevelExit: true));
  }

  /// Drives the runtime spawners, on levels that still use them.
  ///
  /// Both are null on an authored level (everything in it was placed by a
  /// person at load time, so there is nothing to spawn) and also during the
  /// window before the now-async `setupSpawning()` has finished. Null-checked
  /// rather than branching on `tiledLevel`, because that window exists on
  /// both paths.
  void updateSpawning(double dt) {
    // Only the enemy spawner has per-frame work; GroundSpawner lays its one
    // section at setup and had an empty update(), removed in Phase 4.
    spawner?.update(dt);
  }
}
