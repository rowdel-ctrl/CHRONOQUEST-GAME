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
    spawner = EnemySpawner(game: this);

    // Questions are intentionally bundled with the app — no backend
    // round-trip. Enemies no longer carry a question (GAMEPLAY-V2.md
    // Section 15, Phase 2), so only a boss level's fight-phase questions are
    // kept; the bank still returns bossWarmupQuestions + bossFightQuestions
    // for a boss level (QuestionBank._targetCount), but the warm-up slice
    // has nothing left to consume it and is discarded rather than plumbed
    // anywhere.
    if (isBossLevel) {
      final questions = QuestionBank.getQuestions(currentEra, currentLevel);
      bossQuestions = questions.skip(GameConstants.bossWarmupQuestions).toList();
    }
  }

  void updateSpawning(double dt) {
    spawner.update(dt);
    groundSpawner.update(dt);
  }
}
