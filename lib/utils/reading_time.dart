import '../models/question.dart';

/// Reading time for a long question, shared by the boss fight's clock and the level clock.
///
/// A card (the question and its four choices) of [freeWords] words or fewer is read in the normal time.
/// Each word beyond that adds [secondsPerExtraWord] seconds, up to [maxBonus]. The questions of the
/// DepEd lessons run to 60 words and more, so a clock made for a 25-word question would lose them.
class ReadingTime {
  ReadingTime._();

  static const int freeWords = 30;
  static const double secondsPerExtraWord = 0.35;
  static const int maxBonus = 25;

  /// Words on the card: the question and every choice.
  static int cardWords(Question q) {
    int count(String s) => s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return count(q.questionText) + q.options.fold<int>(0, (a, o) => a + count(o.text));
  }

  /// Seconds added for reading a long card (0 for a short one).
  static int bonus(Question q) {
    final extra = cardWords(q) - freeWords;
    if (extra <= 0) return 0;
    return (extra * secondsPerExtraWord).round().clamp(0, maxBonus);
  }
}
