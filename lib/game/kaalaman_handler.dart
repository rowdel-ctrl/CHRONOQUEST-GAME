import '../core/combat_constants.dart';
import 'answer_point_handler.dart';
import 'chrono_game.dart';

/// Kaalaman (attack charge) grant/spend for [ChronoGame]. Split out as an
/// extension the same way quiz_handler.dart/game_spawning.dart/
/// game_collision.dart already are, rather than a separate state class —
/// `kaalaman` is a plain level-local field on [ChronoGame] (see its own
/// doc comment), the same shape `hearts` already uses.
extension KaalamanHandler on ChronoGame {
  /// Whether a swing may start. The charge itself is only spent when the
  /// swing connects (see AttackHitboxComponent), so a miss costs nothing.
  bool get canAttack => kaalaman >= CombatConstants.attackChargeCost;

  /// Spends one charge if the player has any. Returns false (and changes
  /// nothing) when they don't.
  bool trySpendCharge() {
    if (kaalaman <= 0) return false;
    kaalaman -= CombatConstants.attackChargeCost;
    notifyState();
    return true;
  }

  /// Restores one charge every [CombatConstants.kaalamanRegenSeconds] whenever the
  /// bar is below full (2026-11-02; it used to refill only a student at 0, and
  /// only to 1). The timer is idle while the bar is full, so spending the first
  /// charge from a full bar starts a full wait.
  void updateKaalamanRegen(double dt) {
    if (kaalaman >= CombatConstants.kaalamanDisplayMax) {
      kaalamanRegenTimer = 0;
      return;
    }
    kaalamanRegenTimer += dt;
    if (kaalamanRegenTimer >= CombatConstants.kaalamanRegenSeconds) {
      kaalamanRegenTimer = 0;
      kaalaman += 1;
      notifyState();
    }
  }

  /// An answer was given (an artifact's or the boss's). Keeps the streak, and every
  /// third right answer in a row gives one extra charge. Returns true when it did.
  bool noteAnswer({required bool correct}) {
    final bonus = stats.answered(correct);
    if (bonus) grantCharges(CombatConstants.streakBonusCharges);
    return bonus;
  }
}
