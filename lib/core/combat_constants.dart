/// All Phase 2 combat/Kaalaman tuning numbers in one place (GAMEPLAY-V2.md
/// Section 15, Phase 2 prompt: "Put all tuning numbers... in one clearly
/// named constants file so they can be adjusted without hunting"). Every
/// value here is a starting guess to be corrected by playtesting — see
/// Section 4's "guesses that must be tuned by playing" note in the design
/// doc, which applies to these numbers just as much as the Kaalaman ones
/// it was written about.
class CombatConstants {
  // ─── Kaalaman charges (Section 4) ──────────────────────────────────────
  /// Every level starts with the bar FULL (playtest 2026-10-30: starting at 0 left a
  /// student who answered wrong with no attack and a wait). Attacks that land spend
  /// charges, and a correct answer gives them back (+2).
  static const int kaalamanStart = kaalamanDisplayMax;

  /// How many orbs/segments the HUD bar holds: the most a student can have, so
  /// what the bar shows is what there is (charges are capped here).
  static const int kaalamanDisplayMax = 10;
  static const int attackChargeCost = 1;

  /// Whenever the bar is below full, one charge comes back every this many
  /// seconds (2026-11-02, the new rules: it used to refill only a student at 0, and
  /// only up to 1). 20 until 2026-10-30 (playtest: "the regeneration is too long"),
  /// then 6 at 0 charges, now 8 at any level below full.
  static const double kaalamanRegenSeconds = 8.0;

  /// Answering this many in a row right gives one extra charge on top of the
  /// artifact's own reward, and again at every further multiple.
  static const int streakForBonus = 3;
  static const int streakBonusCharges = 1;

  /// A boss arena has no artifacts to collect on the way in, so the fight opens
  /// with the bar full too. The minions pay for the next wave.
  static const int bossStartCharges = kaalamanDisplayMax;

  // ─── Attack hitbox (Section 3: "a short forward hitbox... ~0.25s") ─────
  /// 64 until 2026-10-06, then 80: walking went from 210 to 250 units/s, so the
  /// same box left less time to hit an enemy before touching it.
  static const double attackHitboxWidth = 80;
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

  /// A Walker turns to face a student who comes this close on its own level.
  static const double walkerNoticeRange = 320;

  // ─── Chaser (the spirit, propaganda and cloud enemies) ──────────────────
  /// Walks towards a student who comes within [chaserNoticeRange] on its own
  /// level, slower than the student's 250, never further than [chaserLeash] from
  /// where it stood, and never off a ledge. Out of range it walks home and paces.
  static const double chaserNoticeRange = 440;
  static const double chaserSpeed = 140; // 110 until 2026-11-10
  static const double chaserLeash = 380;

  // ─── Blast chasers (dark spirit, propaganda, misinfo cloud) ─────────────
  /// While chasing, one that gets this close (centre to centre, same level) stops and
  /// fuses for [blastFuse] seconds, flashing with a red ring on the ground. If the
  /// fuse runs out it bursts: one heart for a student inside [blastRadius] sideways
  /// whose feet are less than [blastHeight] above its feet (a jump clears it). A hit
  /// during the fuse pops it harmlessly. A self-burst pays no coins.
  static const double blastArmRange = 100;
  static const double blastFuse = 0.7;
  static const double blastRadius = 110;
  static const double blastHeight = 60;

  /// The flicker speeds up from [blastFlashFrom] to [blastFlashTo] flashes a second
  /// over the fuse, and the body swells from 1.0 to [blastSwell].
  static const double blastFlashFrom = 4;
  static const double blastFlashTo = 14;
  static const double blastSwell = 1.2;

  /// How long a burst picture (EnemyBurstComponent) lives, and how big the harmless
  /// pop is next to a real burst.
  static const double burstDuration = 0.8;
  static const double popBurstScale = 0.5;

  // ─── Dash chasers (a soldier the map made a chaser) ─────────────────────
  /// Close to a student ([dashArmRange]) it crouches for [dashCrouch] (the warning:
  /// a squash and an orange flash), dashes [dashDistance] units in [dashDuration],
  /// then stands tired for [dashTired] before it chases again. Touching a student
  /// costs a heart as for any enemy; a jump over it avoids that.
  static const double dashArmRange = 140;
  static const double dashCrouch = 0.35;
  static const double dashDuration = 0.3;
  static const double dashDistance = 130;
  static const double dashTired = 0.7;
  static const double dashSquashY = 0.88;
  static const double dashSquashX = 1.06;

  /// How far apart in height two things can be and still count as "on the same
  /// level" (a jump reaches about 128).
  static const double sameLevelTolerance = 150;

  // ─── Heavy lunge ─────────────────────────────────────────────────────────
  /// A Heavy flashes for [lungeWindup] seconds, then lunges a short way towards
  /// the student, then needs [lungeRecover] to get its breath back.
  static const double lungeTriggerRange = 260;
  static const double lungeWindup = 0.6;
  static const double lungeDuration = 0.3;
  static const double lungeSpeed = 480;
  static const double lungeRecover = 0.8;
  static const double lungeCooldown = 1.0;

  /// A lunge never takes a Heavy further than this from where it stood.
  static const double lungeLeash = 200;

  // ─── Enemy HP (Section 5 table) ─────────────────────────────────────────
  static const int walkerHp = 1;
  static const int chaserHp = 1;
  static const int heavyHp = 2;

  // ─── Contact damage / knockback / i-frames (Section 5) ──────────────────
  /// The part of an enemy that hurts, as a fraction of its drawn box (the art has
  /// transparent margins, so the whole box would hurt from a visible gap away).
  static const double enemyHitWidthFraction = 0.55;
  static const double enemyHitHeightFraction = 0.85;

  /// The part of the player that an enemy can hurt: about the drawn body, not the
  /// whole 96-wide sprite box (the art has 15 to 20 units of empty margin each
  /// side, so enemies hurt from a visible gap away; playtest 2026-10-26: "the
  /// enemy could not reach me but I lost a heart"). With the full box a jump
  /// over a walker could not be done at all at full speed (0 frames of leeway); with
  /// this one a take-off window of about 10 frames works.
  static const double playerHurtWidthFraction = 0.6;

  /// The hurt part stops this far above the feet, so a jump that only just clears
  /// an enemy's head is not punished by a few units of foot.
  static const double playerHurtFeetGrace = 12;

  /// How far a hit shoves the player, away from whatever was touched, in world
  /// units. Playtest (2026-10-04): the old 44-unit shove left the player inside
  /// the enemy's reach, and the 1.5s of invincibility that follows was long
  /// enough to simply walk through it. 160 put a clear gap between them.
  ///
  /// Raised to 180 on 2026-10-06 when walking speed went from 210 to 250,
  /// which grew the walking left in the invincibility window. The numbers that
  /// make it hold, at the 250 units/s walking speed: after the
  /// [knockbackDuration] of lost control there are (1.5 - 0.3) * 250 = 300
  /// units of invincible walking left, but getting back through the enemy
  /// takes the 180 pushed away plus about 146 to cross its hit area and the
  /// player's own width, so 326. It cannot be done before the invincibility
  /// ends. `contact_damage_test.dart` pins this arithmetic.
  ///
  /// Raised to 210 on 2026-10-26, when the part of the player that can be hurt
  /// shrank from the whole 96-wide box to 0.6 of it ([playerHurtWidthFraction]):
  /// crossing the enemy is now 210 + 49.5 + 57.6 = 317 against the same 300 of
  /// invincible walking.
  static const double knockbackDistance = 210;

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

  // ─── Death sequence ──────────────────────────────────────────────────────
  // Section 5 asked for a ~0.3s flash, grow and fade. Playtest (2026-10-06)
  // wanted more punch, so it is now a white flash, then the enemy is knocked
  // away from the player, spinning and shrinking, with a burst of sparks and a
  // shock ring, and fades out at the end of the flight: about half a second.
  static const double deathFlashDuration = 0.08;
  static const double deathFlightDuration = 0.42;
  static const double deathDuration = deathFlashDuration + deathFlightDuration;

  /// How far the knocked-out enemy flies: away from the player, and up.
  static const double deathFlightPush = 70;
  static const double deathFlightRise = 90;

  /// Radians it spins through during the flight (a bit under 1.5 turns).
  static const double deathSpin = 2.4;

  // ─── Coin drops on death ─────────────────────────────────────────────────
  static const int coinDropMin = 2;
  static const int coinDropMax = 3;

  // ─── Level length / distance goal ────────────────────────────────────────
  /// Placeholder until Phase 4's Tiled levels replace this with a real exit
  /// object (GAMEPLAY-V2.md Section 14) — levels are still 100% procedural,
  /// so there is no real per-level length to author yet.
  ///
  /// Derived from Section 1's "a level is roughly 2 minutes": at
  /// PlayerComponent.forwardSpeed (210 units/s then, 250 now), 2 minutes of continuous
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
  /// 96x120 player. 56 until 2026-10-06 (playtest: "a little small"), now 72.
  static const double artifactSize = 72;

  /// How high above the ground an artifact floats, and its gentle bob. The top
  /// edge: 158 keeps the middle where it was (150 at the old size of 56).
  static const double artifactHoverHeight = 158;
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

  /// How tall the gate is drawn: 180, which snaps to 8 tiles (192). A gate blocks
  /// the full corridor whatever the student's height (the stop is a sideways
  /// clamp in PlayerComponent.update, so a jump never goes over it), and 180 is
  /// well above the highest a jump reaches (about 128). It was 260 until
  /// 2026-10-29 ("why is the gate so tall"). Still far taller than the old 40x50
  /// WallComponent it replaces. Widened from 48 to
  /// 144 (6 tiles) after playtesting: at 48 it was half as wide as the player and
  /// read as a post, not a gate. The generator leaves 120 of floor past the exit
  /// so it fits (tools/levelgen/rules.js, exitMargin).
  static const double gateWidth = 144;
  static const double gateHeight = 180;

  /// How far in front of a gate the player is stopped, so they don't stand
  /// visually inside it while the question is open.
  static const double gateStandoff = 8;
}
