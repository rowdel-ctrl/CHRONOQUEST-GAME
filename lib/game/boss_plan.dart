import 'dart:math';

import '../core/boss_attack_constants.dart';
import '../core/constants.dart';
import '../models/question.dart';

/// How a boss fight is laid out: 22 rounds, three phases that get harder (less time to
/// answer), a wrong answer asked again at the back. Plain Dart, so it can be tested without
/// a running game.
class BossPlan {
  BossPlan._();

  /// Rounds in a fight (the boss's health).
  static const int rounds = BossAttackConstants.rounds;

  /// Seconds to answer a question, by phase (index 0 is phase 1).
  static const List<double> answerSeconds = [GameConstants.bossAnswerSeconds, 12, 10];

  /// The first round that has the boss's extra attack (phase 3), when it has one.
  static int get extraFromRound => BossAttackConstants.phaseLastRound[1] + 1;

  /// Phase (1 to 3) of [round] (1 is the first round).
  static int phaseOfRound(int round) => BossAttackConstants.phaseOfRound(round);

  /// Seconds to answer in [round].
  static double secondsForRound(int round) => answerSeconds[phaseOfRound(round) - 1];

  /// "Tanong 7 ng 22": the round being played, counting the ones already won.
  static String roundTag(int round, int total) => 'Tanong $round ng $total';

  /// "Phase 2 · 12 s".
  static String phaseTag(int round) =>
      'Phase ${phaseOfRound(round)} · ${secondsForRound(round).round()} s';
}

/// The questions of one boss fight, in the order they are asked.
///
/// [BossPlan.rounds] (22) questions come from the level's pool (a boss level holds 22: its own
/// lesson's 10, then 12 of review): about half from the lesson's own, the rest from the review,
/// each part in a random order, the lesson's own first. A question answered wrong goes to the
/// back of the line and is asked again until it is right, so the boss falls when every one of
/// the 22 has been answered right once.
class BossQuestions {
  BossQuestions(List<Question> pool, {Random? random, int rounds = BossPlan.rounds})
      : _random = random ?? Random(),
        total = min(rounds, pool.length) {
    final own = pool.sublist(0, min(GameConstants.bossWarmupQuestions, pool.length));
    final review = pool.sublist(own.length);
    // The same share as the lesson's own questions have in a full pool (10 of 22).
    var fromOwn = (total * GameConstants.bossWarmupQuestions /
            (GameConstants.bossWarmupQuestions + GameConstants.bossFightQuestions))
        .round()
        .clamp(0, own.length);
    var fromReview = total - fromOwn;
    if (fromReview > review.length) {
      fromReview = review.length;
      fromOwn = total - fromReview;
    }
    _line
      ..addAll((List<Question>.of(own)..shuffle(_random)).take(fromOwn))
      ..addAll((List<Question>.of(review)..shuffle(_random)).take(fromReview));
  }

  final Random _random;

  /// How many questions the fight holds; the boss's health.
  final int total;

  final List<Question> _line = [];
  int _asked = 0;
  int _solved = 0;

  /// Questions served so far, the ones asked again included.
  int get asked => _asked;

  /// Questions answered right.
  int get solved => _solved;

  /// The round being played: one more than the questions answered right.
  int get round => _solved + 1;

  bool get isDone => _line.isEmpty;

  /// The next question, its options shuffled, or null when none is left.
  Question? next() {
    if (_line.isEmpty) return null;
    final q = _line.removeAt(0);
    _asked++;
    return q.withShuffledOptions(_random);
  }

  void solve() => _solved++;

  /// Puts a question answered wrong at the back of the line.
  void again(Question q) => _line.add(q);
}
