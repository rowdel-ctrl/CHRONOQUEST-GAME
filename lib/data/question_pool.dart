import 'dart:math';

import '../models/question.dart';
import 'question_bank.dart';

/// One level attempt's supply of questions.
///
/// Phase 3 (GAMEPLAY-V2.md Section 14) needs semantics the old flat-list
/// [QuestionBank.getQuestions] could not express: *serve one unused question
/// from this level's pool*, and *serve a different one on retry*. That is
/// per-attempt state, so it lives on an instance owned by the running game
/// rather than in `QuestionBank`'s statics — two levels played in one
/// session must not share a served-set, and nothing should leak between
/// runs.
///
/// **Exhaustion is expected, not exceptional.** Each non-boss level has only
/// 5 authored questions today, while a level asks for 10-15 draws (3 gates
/// plus 4-6 artifacts, each retryable). Rather than pad with obviously-fake
/// placeholder text, the pool recycles real questions once every one has
/// been served, and records that it had to — see [recycleCount] and
/// [hasRecycled], which exist so a starved level is visible in tests and
/// logs instead of quietly degrading.
class QuestionPool {
  QuestionPool({
    required List<Question> questions,
    Random? random,
  })  : _all = List<Question>.unmodifiable(questions),
        _random = random ?? Random();

  /// Builds a pool from the bundled content for [era]/[level].
  factory QuestionPool.forLevel(String era, int level, {Random? random}) =>
      QuestionPool(
        questions: QuestionBank.poolFor(era, level),
        random: random,
      );

  final List<Question> _all;
  final Random _random;

  /// Ids already served this attempt. Cleared only when every question has
  /// been used and the pool recycles.
  final Set<String> _served = {};

  int _recycleCount = 0;

  /// How many times the pool has been exhausted and started over. 0 means
  /// every question served so far was distinct.
  int get recycleCount => _recycleCount;

  bool get hasRecycled => _recycleCount > 0;

  /// Total authored questions backing this pool.
  int get size => _all.length;

  bool get isEmpty => _all.isEmpty;

  /// Questions not yet served in the current cycle.
  int get remaining => _all.length - _served.length;

  /// Serves one question, preferring any not yet used this attempt.
  ///
  /// [exclude] is the question the caller is replacing — a retry passes the
  /// one just answered wrong so the student is guaranteed to see something
  /// different, which is exactly the "re-serves a genuinely different
  /// question" acceptance criterion. It is honoured even when it forces a
  /// recycle, unless the pool holds only that single question.
  ///
  /// Options are reshuffled per serve: the source JSON lists the correct
  /// answer first for every question, so serving them unshuffled would make
  /// "A" always right.
  Question? draw({Question? exclude}) {
    if (_all.isEmpty) return null;

    var candidates = _unservedExcluding(exclude);

    if (candidates.isEmpty) {
      // Every question has been served this cycle (or the only unserved one
      // is the very question we must not repeat) — start a new cycle and
      // say so, then re-apply the exclusion against the full pool.
      _recycleCount++;
      _served.clear();
      candidates = _unservedExcluding(exclude);
      // Only reachable when the pool holds a single question, which cannot
      // satisfy "serve something different". Serving it again beats
      // blocking the player at a gate forever.
      if (candidates.isEmpty) candidates = List<Question>.from(_all);
    }

    final picked = candidates[_random.nextInt(candidates.length)];
    _served.add(picked.id);
    return picked.withShuffledOptions(_random);
  }

  List<Question> _unservedExcluding(Question? exclude) => _all
      .where((q) => !_served.contains(q.id) && q.id != exclude?.id)
      .toList();

  /// Draws [count] questions in one go, for callers that still want a batch
  /// (the boss fight asks all of its questions from one list).
  List<Question> drawMany(int count) {
    final drawn = <Question>[];
    for (var i = 0; i < count; i++) {
      final q = draw();
      if (q == null) break;
      drawn.add(q);
    }
    return drawn;
  }
}
