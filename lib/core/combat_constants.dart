
/// All Phase 2 combat/Kaalaman tuning numbers in one place (GAMEPLAY-V2.md
/// Section 15, Phase 2 prompt: "Put all tuning numbers... in one clearly
/// named constants file so they can be adjusted without hunting"). Every
/// value here is a starting guess to be corrected by playtesting — see
/// Section 4's "guesses that must be tuned by playing" note in the design
/// doc, which applies to these numbers just as much as the Kaalaman ones
/// it was written about.
class CombatConstants {
  // ─── Kaalaman charges (Section 4) ──────────────────────────────────────
  /// Every level starts at 0 (Section 4). Artifacts are the only source of
  /// charges — Phase 3 restored this after Phase 2 temporarily started at 3
  /// so combat was testable before artifacts existed.
  static const int kaalamanStart = 0;
  /// How many orbs/segments the HUD bar is scaled to. Not a limit: charges
  /// are bounded by content (5 artifacts x 2), so nothing is clamped to it.
  static const int kaalamanDisplayMax = 10;
  static const int attackChargeCost = 1;

  /// A student at 0 charges slowly earns one back, so they can never be
  /// stranded without an attack. Regeneration stops at this floor; only
  /// artifacts push a player above it.
  static const int kaalamanRegenFloor = 1;
  static const double kaalamanRegenSeconds = 20.0;

  /// Section 4 sanctions a tutorial freebie: "Levels 1-2 of each era may
  /// grant 1 as a tutorial freebie." Without it the very first level opens
  /// with a dead attack button until the first artifact is claimed.
  static const int kaalamanTutorialLevels = 2;
  static const int kaalamanTutorialStart = 1;

  // ─── Attack hitbox (Section 3: "a short forward hitbox... ~0.25s") ─────
  static const double attackHitboxWidth = 64;
  static const double attackHitboxHeight = 90;
  static const double attackHitboxDuration = 0.25;

  /// Not specified by the design doc (only "with a cooldown so it can't be
  /// spammed") — set so the charge economy (cost 1 per hit) runs out
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
  /// How far a hit shoves the player, away from whatever was touched, in world
  /// units. Playtest (2026-10-04): the old 44-unit shove left the player inside
  /// the enemy's reach, and the 1.5s of invincibility that follows was long
  /// enough to simply walk through it. 160 puts a clear gap between them.
  ///
  /// The numbers that make that true, all at the 210 units/s walking speed:
  /// after the [knockbackDuration] of lost control there are
  /// (1.5 - 0.3) * 210 = 252 units of invincible walking left, but getting
  /// back through the enemy takes the 160 pushed away plus about 146 to cross
  /// its hit area and the player's own width, so 306. It cannot be done before
  /// the invincibility ends. `contact_damage_test.dart` pins this arithmetic.
  static const double knockbackDistance = 160;

  /// Seconds the shove lasts, and so how long the player cannot steer: the
  /// student is "hit-stunned" for this long, so they cannot walk straight
  /// back into the enemy while it is still on them.
  static const double knockbackDuration = 0.3;

  /// Speed of the shove, derived so it covers [knockbackDistance] exactly in
  /// [knockbackDuration]. World units/second.
  static const double knockbackForce = knockbackDistance / knockbackDuration;

  /// Section 5 says "~1s". Raised to 1.5 after the 2026-10-03 playtest: with
  /// contact damage now re-checked every frame of an overlap (it used to fire
  /// only when an overlap began), 1s was not long enough to walk clear of an
  /// enemy before the next hit landed.
  static const double invincibilityDuration = 1.5;

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

  // ─── Artifacts and gates (Section 6) ─────────────────────────────────────
  /// Charges granted for claiming an artifact first try, and after a wrong
  /// attempt at the same artifact. "Being wrong costs you time and power,
  /// which are the things you actually care about in the moment."
  static const int artifactReward = 2;
  static const int artifactRetryReward = 1;

  /// How long a wrongly-answered artifact stays inert before re-lighting.
  static const double artifactInertSeconds = 5.0;

  /// Drawn size of an artifact. Larger than a coin (42) so it reads as a
  /// deliberate objective rather than pickup clutter, smaller than the
  /// 96x120 player.
  static const double artifactSize = 56;

  /// How high above the ground an artifact floats, and its gentle bob.
  static const double artifactHoverHeight = 150;
  static const double artifactBobAmplitude = 6;
  static const double artifactBobSpeed = 2.2;

  /// Artifacts per level: 10, matching `GameConstants.questionsPerLevel`
  /// (changed from 5 on 2026-10-04). Artifacts are mandatory now — the end
  /// gate stays shut until every one has been answered — so this is also how
  /// many questions a student must meet. Levels have only about 5 written
  /// questions today, so the pool recycles and each appears about twice; that
  /// ends when the question bank reaches its 10-15 per level target.
  static const int artifactsPerLevel = 10;

  /// Gates per level: exactly one, standing at the exit. It asks no question
  /// and opens when every artifact has been answered (Section 6's 2026-10-03
  /// and 2026-10-04 corrections).
  static const int gatesPerLevel = 1;

  /// A gate blocks the full corridor height and cannot be jumped, so it is
  /// far taller than the old 40x50 WallComponent it replaces. Widened from 48 to
  /// 144 (6 tiles) after playtesting: at 48 it was half as wide as the player and
  /// read as a post, not a gate. The generator leaves 120 of floor past the exit
  /// so it fits (tools/levelgen/rules.js, exitMargin).
  static const double gateWidth = 144;
  static const double gateHeight = 260;

  /// How far in front of a gate the player is stopped, so they don't stand
  /// visually inside it while the question is open.
  static const double gateStandoff = 8;

}
