import 'dart:math';

import '../core/constants.dart';
import '../models/question.dart';

/// How a boss fight is laid out. The fight asks every question of the level's pool once
/// (a boss level holds 22: its own lesson's 10, then 12 of review). Three phases get harder:
/// less time to answer and more minions in a wave.
///
/// Plain Dart, so it can be tested without a running game.
class BossPlan {
  BossPlan._();

  /// Seconds to answer a question, by phase.
  static const List<double> answerSeconds = [GameConstants.bossAnswerSeconds, 12, 10];

  /// Minions in a wave, by phase.
  static const List<int> minionsPerWave = [2, 3, 4];

  /// A wave of minions comes after every this many questions.
  static const int questionsPerWave = 2;

  /// From phase 2 the boss also attacks with each wave: it flashes for this long
  /// (the warning) and sends a shockwave along the floor. Phase 2 sends one, phase 3
  /// two, the second after the shorter warning.
  static const double telegraphSeconds = 1.0;
  static const double secondTelegraphSeconds = 0.6;

  /// Before each question the boss glows gold and the screen says which one is coming,
  /// for this long, so a question never just appears.
  static const double leadInSeconds = 0.9;

  /// In an arena the question waits on a scroll that appears at least this far from the
  /// student, who has to walk to it.
  static const double scrollMinDistance = 450;

  /// A scroll is kept this far from a minion, if there is a spot that allows it.
  static const double scrollMinionGap = 250;

  /// A new wave is not sent while this many minions are still alive.
  static const int maxLiveMinions = 6;

  /// "Tanong 7 ng 22": the question about to be asked, counting the ones already right.
  static String questionTag(int solved, int total) => 'Tanong ${solved + 1} ng $total';

  /// Where the scroll appears: a spot at least [scrollMinDistance] from the student (x) and,
  /// when possible, at least [scrollMinionGap] from every minion. With no such spot the
  /// farthest one. Null when the arena has no spots.
  static ({double x, double y})? scrollSpot(
    List<({double x, double y})> spots,
    double playerX,
    List<double> minionXs,
    Random random,
  ) {
    if (spots.isEmpty) return null;
    final far = spots.where((s) => (s.x - playerX).abs() >= scrollMinDistance).toList();
    if (far.isEmpty) {
      return ([...spots]..sort((a, b) => (b.x - playerX).abs().compareTo((a.x - playerX).abs()))).first;
    }
    final clear = far.where((s) => minionXs.every((m) => (m - s.x).abs() >= scrollMinionGap)).toList();
    final pool = clear.isEmpty ? far : clear;
    return pool[random.nextInt(pool.length)];
  }

  /// How [total] questions split over the three phases: 10, 6 and 6 of 22 (the lesson's own
  /// questions, then the review in two halves), and in the same proportion for any other size.
  static List<int> phaseSizes(int total) {
    if (total <= 0) return const [0, 0, 0];
    final first = (total * 10 / 22).round().clamp(1, total);
    final rest = total - first;
    final second = (rest / 2).round();
    return [first, second, rest - second];
  }

  /// The phase (0, 1 or 2) of the question at [index] (0 is the first) in a pool of [total].
  static int phaseOf(int index, int total) {
    var end = 0;
    final sizes = phaseSizes(total);
    for (var phase = 0; phase < sizes.length; phase++) {
      end += sizes[phase];
      if (index < end) return phase;
    }
    return sizes.length - 1;
  }
}

/// The questions of one boss fight, in the order they are asked.
///
/// Every question comes once, the lesson's own first (the pool lists them first), each phase in
/// a random order. A question answered wrong goes to the back of the line and is asked again
/// until it is right, so the boss falls only when every question has been answered right once.
class BossQuestions {
  BossQuestions(List<Question> pool, {Random? random})
      : _random = random ?? Random(),
        total = pool.length {
    var from = 0;
    for (final size in BossPlan.phaseSizes(total)) {
      _line.addAll(pool.sublist(from, from + size)..shuffle(_random));
      from += size;
    }
  }

  final Random _random;

  /// How many questions the fight holds; the boss's health.
  final int total;

  final List<Question> _line = [];
  final Set<String> _again = {};
  int _firstServed = 0;
  int _asked = 0;
  int _solved = 0;
  int _announced = 0;
  bool _finalAnnounced = false;

  /// Phase (0 to 2) of the question served last. A question asked again belongs to the last.
  int phase = 0;

  /// Whether the question served last was the only one left.
  bool isFinal = false;

  /// Questions served so far, the ones asked again included.
  int get asked => _asked;

  /// Questions answered right.
  int get solved => _solved;

  bool get isDone => _line.isEmpty;

  /// The next question, its options shuffled, or null when none is left.
  Question? next() {
    if (_line.isEmpty) return null;
    final q = _line.removeAt(0);
    _asked++;
    final repeat = _again.remove(q.id);
    if (!repeat) _firstServed++;
    phase = repeat ? BossPlan.phaseSizes(total).length - 1 : BossPlan.phaseOf(_firstServed - 1, total);
    isFinal = _line.isEmpty;
    return q.withShuffledOptions(_random);
  }

  /// What to announce before the question just served, once: the last question, or the start of
  /// phase 2 or 3. Null for any other.
  String? takeBanner() {
    if (isFinal && !_finalAnnounced) {
      _finalAnnounced = true;
      return 'FINAL QUESTION';
    }
    if (phase > _announced) {
      _announced = phase;
      return 'PHASE ${phase + 1}';
    }
    return null;
  }

  void solve() => _solved++;

  /// Puts a question answered wrong at the back of the line.
  void again(Question q) {
    _line.add(q);
    _again.add(q.id);
  }
}
