/// Numbers of the boss fight (2026-11 "the attack is the timer", v2): a round starts when the
/// student walks up to a rune (or waits too long); then a wind-up, an attack that flies from the
/// boss to the hero while the question is open, and a result. After every second round a wave
/// of minions comes before the next rune.
///
/// Kept apart from combat_constants.dart on purpose, so the fight can be tuned in one place.
class BossAttackConstants {
  BossAttackConstants._();

  /// Rounds in a fight, and so the boss's health: one point per question answered right.
  static const int rounds = 22;

  /// Seconds to answer, by phase. Rounds 1-7 are phase 1, rounds 8-15 phase 2, rounds 16-22 phase 3.
  /// The attack reaches the hero exactly when this time is up, whatever its path.
  static const List<double> answerSeconds = [15, 12, 10];

  /// The last round of each phase.
  static const List<int> phaseLastRound = [7, 15, 22];

  /// A moment to take the room in before the first round.
  static const double introSeconds = 1.2;

  /// The boss glows and draws back before it throws. Its attack picture shows in the
  /// second half and for [throwPoseSeconds] after the throw.
  static const double windupSeconds = 0.6;
  static const double throwPoseSeconds = 0.5;

  /// A wrong answer: the attack rushes the rest of the way in this time, however far it was
  /// (from [rushMinSeconds] for an attack almost there, up to the sum with [rushExtraSeconds]).
  static const double rushMinSeconds = 0.2;
  static const double rushExtraSeconds = 0.5;

  /// A right answer: the attack is sent back to the boss in this time.
  static const double reflectSeconds = 0.5;

  /// The hero's counter always answers; if it somehow never does, the fight goes on after this.
  static const double counterTimeoutSeconds = 3.0;

  /// After a hit (on the boss or on the hero) the next round starts this long after.
  static const double restSeconds = 1.2;

  /// The question card stays up this long after the hit, so the right answer can be read.
  static const double cardLingerSeconds = 0.9;

  /// The boss shows hurt, flashes white, and is dizzy for this long.
  static const double hurtSeconds = 0.55;
  static const double dizzySeconds = 1.3;

  /// The screen shakes this long when the hero is hit.
  static const double hitShakeSeconds = 0.35;

  /// The boss lies defeated this long before the level is complete.
  static const double defeatSeconds = 1.0;

  /// The hero may walk right up to the boss but not past it: this far short of its middle
  /// (the boss is 120 wide and always faces the hero, on its left).
  static const double heroBossGap = 110;

  // ---------- the rune ----------

  /// A rune appears on the floor at least this far from the hero (if there is no such place,
  /// at the farthest one). Walking up to it makes the boss throw.
  static const double runeMinDistance = 450;

  /// The hero touches a rune when he is this close to it (world x).
  static const double runeTouchRange = 36;

  /// If no rune is touched for this long the boss throws anyway, so the fight cannot stop.
  static const double runeStallSeconds = 15;

  /// A rune never sits nearer than this to the edge of the floor it stands on.
  static const double runeEdgeMargin = 72;

  /// How long the rune takes to appear and to vanish when touched.
  static const double runeBornSeconds = 0.5;
  static const double runeTakenSeconds = 0.4;

  // ---------- minion waves ----------

  /// A wave comes after every this many rounds played (right or wrong).
  static const int waveEveryRounds = 2;

  /// Minions in a wave, by phase (index 0 is phase 1); never more than [waveMaxAlive] at once.
  static const List<int> waveSizes = [2, 3, 4];
  static const int waveMaxAlive = 6;

  /// Minions appear at least this far, and at most [waveSpawnMax] from the hero so they notice him.
  static const double waveSpawnMin = 200;
  static const double waveSpawnMax = 380;

  /// A moment between a wave's last minion falling and the next rune.
  static const double waveClearSeconds = 0.8;

  // ---------- power-ups ----------

  /// Time Freeze holds the clock and the attack this long, then they go on.
  static const double freezeSeconds = 8;

  /// Phase (1 to 3) of [round] (1 to 10).
  static int phaseOfRound(int round) {
    for (var i = 0; i < phaseLastRound.length; i++) {
      if (round <= phaseLastRound[i]) return i + 1;
    }
    return phaseLastRound.length;
  }

  /// Seconds to answer in [round].
  static double secondsForRound(int round) =>
      answerSeconds[phaseOfRound(round) - 1];
}
