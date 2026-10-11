import 'dart:math';

import '../core/constants.dart';

/// The clock on one boss question: [GameConstants.bossAnswerSeconds] to
/// answer. Running out counts as a wrong answer. Time Freeze stops it for the
/// rest of that question.
///
/// Plain Dart, ticked by whoever shows the question, so it can be tested
/// without a running game.
class BossCountdown {
  BossCountdown({this.seconds = GameConstants.bossAnswerSeconds})
      : _left = seconds;

  final double seconds;
  double _left;
  bool _frozen = false;

  double get secondsLeft => _left;

  /// 1 when the clock starts, 0 when it has run out.
  double get fraction => seconds <= 0 ? 0 : (_left / seconds).clamp(0.0, 1.0);

  bool get frozen => _frozen;
  bool get expired => _left <= 0;

  void tick(double dt) {
    if (_frozen || expired) return;
    _left = max(0, _left - dt);
  }

  /// Stops the clock until the question is answered.
  void freeze() => _frozen = true;
}

/// How many minions come after answer number [wave] (0 is the first): two,
/// then three from the third wave on.
int minionsInWave(int wave) => min(3, 2 + wave ~/ 2);
