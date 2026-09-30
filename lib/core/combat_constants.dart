import 'package:flutter/services.dart';

/// All Phase 2 combat/Kaalaman tuning numbers in one place (GAMEPLAY-V2.md
/// Section 15, Phase 2 prompt: "Put all tuning numbers... in one clearly
/// named constants file so they can be adjusted without hunting"). Every
/// value here is a starting guess to be corrected by playtesting — see
/// Section 4's "guesses that must be tuned by playing" note in the design
/// doc, which applies to these numbers just as much as the Kaalaman ones
/// it was written about.
class CombatConstants {
  // ─── Kaalaman charges (Section 4) ──────────────────────────────────────
  /// **Temporarily 3, not the 0 Section 4 specifies.** Artifacts are the
  /// real source of charges and don't exist until Phase 3, and the debug
  /// grant below needs a physical keyboard — so on a touch device a level
  /// starting at 0 leaves the attack button permanently dead and combat
  /// impossible to playtest at all. Set back to 0 in Phase 3, once
  /// answering an artifact's question actually awards charges.
  static const int kaalamanStart = 3;
  static const int kaalamanCap = 6;
  static const int attackChargeCost = 1;

  /// How many charges one debug-key press grants, capped at [kaalamanCap].
  /// Only reachable via a physical/connected keyboard — see
  /// [debugChargeGrantKey] — and is meant to be deleted once Phase 3 wires
  /// up real artifact rewards.
  static const int debugGrantAmount = 3;

  // ─── Attack hitbox (Section 3: "a short forward hitbox... ~0.25s") ─────
  static const double attackHitboxWidth = 64;
  static const double attackHitboxHeight = 90;
  static const double attackHitboxDuration = 0.25;

  /// Not specified by the design doc (only "with a cooldown so it can't be
  /// spammed") — set so the charge economy (cap 6, cost 1/swing) runs out
  /// before the cooldown itself would ever limit attack rate, keeping this a
  /// feel-tuning knob rather than the real rate limiter.
  static const double attackCooldown = 0.4;

  // ─── Enemy patrol (Walker behaviour, Section 5) ─────────────────────────
  /// Not specified beyond "patrols back and forth within a set range" —
  /// picked well under GameConstants.spawnInterval (1400) so a patrolling
  /// Walker can't wander into the next spawn's territory.
  static const double patrolRange = 150;
  static const double patrolSpeed = 40;

  // ─── Enemy HP (Section 5 table) ─────────────────────────────────────────
  static const int walkerHp = 1;
  static const int heavyHp = 2;

  // ─── Contact damage / knockback / i-frames (Section 5) ──────────────────
  /// Initial horizontal velocity imparted away from whatever was touched,
  /// world units/second. Chosen so knockback's total travel
  /// (force * duration) is a visible shove well under one patrol range.
  static const double knockbackForce = 220;
  static const double knockbackDuration = 0.2;

  /// "~1s" per Section 5.
  static const double invincibilityDuration = 1.0;

  /// Seconds per visibility toggle while invincible — the flashing effect.
  static const double flashInterval = 0.1;

  // ─── Death sequence (Section 5: "SequenceEffect... over ~0.3s") ─────────
  // Split evenly across the three named sub-effects since the design doc
  // doesn't give a sub-split, summing to exactly the ~0.3s it specifies.
  static const double deathColorEffectDuration = 0.1;
  static const double deathScaleEffectDuration = 0.1;
  static const double deathOpacityEffectDuration = 0.1;
  static const double deathScaleFactor = 1.3;

  // ─── Coin drops on death ─────────────────────────────────────────────────
  static const int coinDropMin = 2;
  static const int coinDropMax = 3;

  // ─── Level length / distance goal ────────────────────────────────────────
  /// Placeholder until Phase 4's Tiled levels replace this with a real exit
  /// object (GAMEPLAY-V2.md Section 14) — levels are still 100% procedural,
  /// so there is no real per-level length to author yet.
  ///
  /// Derived from Section 1's "a level is roughly 2 minutes": at
  /// PlayerComponent.forwardSpeed (210 units/s), 2 minutes of continuous
  /// forward walking is ~25000 units. Real play is slower than that
  /// (fighting, jumping, backtracking), so this is a floor on level length
  /// rather than an exact runtime.
  ///
  /// The previous 4000 was set by a bad rule of thumb — "5x the spawn
  /// interval, so several things spawn" — without checking it against that
  /// 2-minute target. It produced ~19-second levels holding only ~5
  /// enemies, so a player who killed three and kept walking hit the level
  /// end almost immediately and got a win screen that read like a bug.
  static const double lengthUnitsDefault = 25000;

  // ─── Debug ────────────────────────────────────────────────────────────────
  /// K for "Kaalaman". Desktop/connected-keyboard only by nature — not a
  /// shipped mobile control, and meant to be deleted once Phase 3 lands real
  /// artifact rewards, so it deliberately lives here rather than behind a
  /// DevFlags-style --dart-define gate (that mechanism is reserved for
  /// things that must be provably unreachable in a release build, like
  /// DEV_SKIP_AUTH bypassing login — an unreachable keyboard shortcut on a
  /// touch device carries no equivalent risk).
  static const LogicalKeyboardKey debugChargeGrantKey = LogicalKeyboardKey.keyK;
}
