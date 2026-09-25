import '../core/constants.dart';
import '../data/question_bank.dart';
import 'chrono_game.dart';
import 'components/enemy_spawner.dart';
import 'components/gap_component.dart';

/// Sets up and drives the ground/enemy spawners for [ChronoGame]. Split out
/// of chrono_game.dart's onLoad()/update() as part of the Phase 1 refactor
/// (GAMEPLAY-V2.md Section 15) — behavior is unchanged.
extension GameSpawning on ChronoGame {
  /// Called once from onLoad(), after `player` exists — EnemySpawner reads
  /// the player's starting worldX to seed its distance tracking.
  void setupSpawning() {
    groundSpawner = GroundSpawner(game: this);
    groundSpawner.spawnInitialGround();

    // Questions are intentionally bundled with the app — no backend
    // round-trip.
    final questions = QuestionBank.getQuestions(currentEra, currentLevel);
    if (isBossLevel) {
      // Split into warm-up (regular enemies) and boss-phase (asked while
      // fighting).
      final warmup = questions.take(GameConstants.bossWarmupQuestions).toList();
      bossQuestions = questions.skip(GameConstants.bossWarmupQuestions).toList();
      spawner = EnemySpawner(game: this, questions: warmup);
    } else {
      spawner = EnemySpawner(game: this, questions: questions);
    }
  }

  void updateSpawning(double dt) {
    spawner.update(dt);
    groundSpawner.update(dt);
  }
}
