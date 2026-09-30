import '../core/combat_constants.dart';
import 'chrono_game.dart';

/// Kaalaman (attack charge) grant/spend for [ChronoGame]. Split out as an
/// extension the same way quiz_handler.dart/game_spawning.dart/
/// game_collision.dart already are, rather than a separate state class —
/// `kaalaman` is a plain level-local field on [ChronoGame] (see its own
/// doc comment), the same shape `hearts` already uses.
extension KaalamanHandler on ChronoGame {
  /// Spends one charge if the player has any. Returns false (and changes
  /// nothing) when they don't — the caller (PlayerComponent.attack()) is
  /// what turns that into the "no charges" feedback (GAMEPLAY-V2.md
  /// Section 3), not this extension.
  bool trySpendCharge() {
    if (kaalaman <= 0) return false;
    kaalaman -= CombatConstants.attackChargeCost;
    notifyState();
    return true;
  }

  /// Debug-only: grants CombatConstants.debugGrantAmount charges, capped at
  /// CombatConstants.kaalamanCap. Bound to a keyboard key (see
  /// ChronoGame.onKeyEvent) so combat can be tested before Phase 3's real
  /// artifact rewards exist.
  void debugGrantCharges() {
    kaalaman = (kaalaman + CombatConstants.debugGrantAmount)
        .clamp(0, CombatConstants.kaalamanCap);
    notifyState();
  }
}
