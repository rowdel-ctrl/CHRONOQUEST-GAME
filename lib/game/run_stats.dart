import '../core/combat_constants.dart';

/// What happened in one try of a level, kept for the rules that look back over it:
/// the streak of right answers, falls into a river, power-ups used, the coins on
/// the high platforms and the halfway flag. Plain Dart, so it can be tested
/// without a running game.
class RunStats {
  int correctStreak = 0;
  int bestStreak = 0;
  int wrongAnswers = 0;
  int falls = 0;
  int powerUpsUsed = 0;
  int highCoinsTotal = 0;
  int highCoinsTaken = 0;

  /// The halfway flag has been reached (a heart was given, once per try).
  bool flagReached = false;

  /// World x of the flag once reached: a fall never puts the student back before it.
  double? checkpointX;

  /// An answer was given. Returns true when it earns the streak bonus: every
  /// [CombatConstants.streakForBonus]th right answer in a row.
  bool answered(bool correct) {
    if (!correct) {
      wrongAnswers++;
      correctStreak = 0;
      return false;
    }
    correctStreak++;
    if (correctStreak > bestStreak) bestStreak = correctStreak;
    return correctStreak % CombatConstants.streakForBonus == 0;
  }

  /// Every coin on a high platform was taken, and there were some to take.
  bool get tookHighRoad => highCoinsTotal > 0 && highCoinsTaken >= highCoinsTotal;

  bool get noFall => falls == 0;
  bool get noPowerUp => powerUpsUsed == 0;
}
