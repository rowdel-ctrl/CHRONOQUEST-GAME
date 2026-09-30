import '../core/combat_constants.dart';
import '../core/constants.dart';
import '../data/question_bank.dart';
import '../data/question_pool.dart';
import 'chrono_game.dart';
import 'components/artifact_component.dart';
import 'components/enemy_spawner.dart';
import 'components/gap_component.dart';
import 'components/gate_component.dart';

/// Sets up and drives the ground/enemy spawners for [ChronoGame]. Split out
/// of chrono_game.dart's onLoad()/update() as part of the Phase 1 refactor
/// (GAMEPLAY-V2.md Section 15).
extension GameSpawning on ChronoGame {
  /// Called once from onLoad(), after `player` exists — EnemySpawner reads
  /// the player's starting worldX to seed its distance tracking.
  void setupSpawning() {
    groundSpawner = GroundSpawner(game: this);
    groundSpawner.spawnInitialGround();
    spawner = EnemySpawner(game: this);

    // Questions are intentionally bundled with the app — no backend
    // round-trip.
    questionPool = QuestionPool.forLevel(currentEra, currentLevel);

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

  /// Distributes gates and artifacts across the level's length.
  ///
  /// Gates are evenly spaced so passage is gated at regular intervals, and
  /// artifacts are spread between them. Both are kept clear of the level's
  /// very start (the player spawns there) and its very end (the level
  /// completes on reaching `lengthUnits`, and a gate the player can never
  /// be forced through guarantees nothing).
  void _placeAnswerPoints() {
    final length = currentLevelData.lengthUnits;
    const usableStart = GameConstants.playerX + 600;
    final usableEnd = length - 600;
    final usable = usableEnd - usableStart;
    if (usable <= 0) return;

    // Gates at even fractions: with 3 gates, at 1/4, 2/4 and 3/4 of the
    // usable stretch.
    const gateCount = CombatConstants.gatesPerLevel;
    for (var i = 1; i <= gateCount; i++) {
      final x = usableStart + usable * (i / (gateCount + 1));
      world.add(GateComponent(worldX: x));
    }

    // Artifacts offset off the gate rhythm so they sit between gates rather
    // than on top of them, and so the first answer point the player meets is
    // an artifact — charges come from artifacts, and walking into a gate
    // with no way to have earned anything yet would be a dead start.
    const artifactCount = CombatConstants.artifactsPerLevel;
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
  }

  void updateSpawning(double dt) {
    spawner.update(dt);
    groundSpawner.update(dt);
  }
}
