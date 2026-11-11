import 'dart:math';

import '../core/boss_attack_constants.dart';
import '../core/constants.dart';

/// The clock on one boss question: [GameConstants.bossAnswerSeconds] in the first phase and
/// less in the next two (BossPlan.answerSeconds). Running out counts as a wrong answer. Time
/// Freeze stops it for [BossAttackConstants.freezeSeconds] and then it goes on (it used to
/// stop for the rest of the question, which gave unlimited thinking time).
///
/// Plain Dart, ticked by whoever shows the question, so it can be tested
/// without a running game.
class BossCountdown {
  BossCountdown({this.seconds = GameConstants.bossAnswerSeconds})
      : _left = seconds;

  final double seconds;
  double _left;
  double _frozenLeft = 0;
  bool _usedFreeze = false;

  double get secondsLeft => _left;

  /// 1 when the clock starts, 0 when it has run out.
  double get fraction => seconds <= 0 ? 0 : (_left / seconds).clamp(0.0, 1.0);

  /// Whether Time Freeze is holding the clock right now.
  bool get frozen => _frozenLeft > 0;

  /// Seconds of freeze left (0 when it is not holding).
  double get frozenLeft => _frozenLeft;

  /// Whether Time Freeze was already used on this question (one use each).
  bool get usedFreeze => _usedFreeze;

  bool get expired => _left <= 0;

  void tick(double dt) {
    if (expired) return;
    if (_frozenLeft > 0) {
      _frozenLeft = max(0, _frozenLeft - dt);
      return;
    }
    _left = max(0, _left - dt);
  }

  /// Holds the clock for [forSeconds] (8 by default). A second use on the same question
  /// does nothing.
  void freeze([double forSeconds = BossAttackConstants.freezeSeconds]) {
    if (_usedFreeze || expired) return;
    _usedFreeze = true;
    _frozenLeft = forSeconds;
  }
}
