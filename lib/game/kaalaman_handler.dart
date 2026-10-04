import '../core/combat_constants.dart';
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

  /// Slowly restores charges up to [CombatConstants.kaalamanRegenFloor]
  /// while the player is below it. The timer resets whenever the player is
  /// at or above the floor, so spending down to 0 always starts a full wait.
  void updateKaalamanRegen(double dt) {
    if (kaalaman >= CombatConstants.kaalamanRegenFloor) {
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

}
