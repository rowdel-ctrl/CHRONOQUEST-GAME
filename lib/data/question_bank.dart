import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import '../models/question.dart';
import '../core/constants.dart';

/// Loads MELC-aligned quiz questions from JSON assets
/// (`assets/data/questions_<era>.json`) instead of hardcoding them as Dart
/// literals. Content edits now only require updating the JSON files, not
/// touching or recompiling Dart code.
///
/// Call [QuestionBank.loadAll] once during app startup (e.g. in main() before
/// runApp, or in a loading screen) before any call to [getQuestions].
class QuestionBank {
  static final Map<String, Map<int, List<Question>>> _bank = {};
  static bool _loaded = false;

  /// Levels whose questions the student's teacher has changed, downloaded by
  /// `QuestionSync`. A level listed here replaces the bundled one; every other
  /// level keeps what shipped in the app, so a phone that has never been online
  /// plays exactly as before.
  static final Map<String, Map<int, List<Question>>> _synced = {};

  /// Questions a teacher chose to always ask in a level (`{era: {level: [id]}}`).
  /// Used only together with a downloaded level; see [picksFor].
  static final Map<String, Map<int, List<String>>> _picks = {};

  static List<Question>? _poolOf(String era, int level) =>
      _synced[era]?[level] ?? _bank[era]?[level];

  /// The eras with a corresponding `assets/data/questions_<era>.json` file —
  /// one per registry era. A missing/not-yet-written file (e.g. the new
  /// 'nationalism' era added in Phase 0.5) is not an error: [loadAll]'s
  /// try/catch below falls through to generated placeholder questions for
  /// it, the same as any era whose pool runs short for a given level.
  static List<String> get _eraIds => allEras.map((e) => e.id).toList();

  /// Loads and parses every era's question JSON into memory. Safe to call
  /// more than once — subsequent calls are a no-op.
  static Future<void> loadAll() async {
    if (_loaded) return;

    for (final eraId in _eraIds) {
      try {
        final raw = await rootBundle
            .loadString('assets/data/questions_$eraId.json');
        final Map<String, dynamic> decoded = json.decode(raw);

        final Map<int, List<Question>> levelMap = {};
        decoded.forEach((levelKey, questionsJson) {
          final level = int.parse(levelKey);
          levelMap[level] = (questionsJson as List<dynamic>)
              .map((q) => Question.fromJson(q as Map<String, dynamic>))
              .toList();
        });

        _bank[eraId] = levelMap;
      } catch (e) {
        // Missing/corrupt JSON for an era shouldn't crash the whole app —
        // getQuestions() falls back to generated placeholder questions
        // for any era/level that didn't load.
        // ignore: avoid_print
        print('QuestionBank: failed to load questions for $eraId: $e');
      }
    }

    _loaded = true;
  }

  /// Uses the questions a teacher published ([levels] is the download:
  /// `{era: {level: [question, ...]}}`) in place of the bundled ones, and
  /// returns how many levels it took.
  ///
  /// The server checks all of this before it publishes; the game checks again
  /// because what it holds may be old, damaged or from another version. A
  /// question that cannot be played is dropped, and a level left with fewer
  /// questions than shipped (or than the game asks, if that is fewer) keeps the
  /// bundled ones, so a download can never leave a level thinner than it was.
  static int applySynced(Map<String, dynamic> levels, {Object? picks}) {
    _synced.clear();
    _picks.clear();
    var used = 0;
    levels.forEach((era, byLevel) {
      if (!_eraIds.contains(era) || byLevel is! Map) return;
      byLevel.forEach((levelKey, list) {
        final level = int.tryParse('$levelKey');
        if (level == null || list is! List) return;
        final questions = <Question>[];
        for (final raw in list) {
          final q = _parsePlayable(raw);
          if (q != null) questions.add(q);
        }
        final shipped = _bank[era]?[level]?.length ?? 0;
        final floor = min(shipped, _targetCount(era, level));
        if (questions.isEmpty || questions.length < floor) return;
        (_synced[era] ??= {})[level] = questions;
        used++;
      });
    });
    _applyPicks(picks);
    return used;
  }

  /// Reads the teacher's chosen questions (`{era: {level: [id]}}`). A pick is kept
  /// only for a level that took the download and only if the question is in
  /// it, and at most as many as the level asks. Anything else is ignored.
  static void _applyPicks(Object? raw) {
    if (raw is! Map) return;
    raw.forEach((era, byLevel) {
      if (byLevel is! Map) return;
      byLevel.forEach((levelKey, ids) {
        final level = int.tryParse('$levelKey');
        final pool = level == null ? null : _synced[era]?[level];
        if (level == null || pool == null || ids is! List) return;
        final inPool = pool.map((q) => q.id).toSet();
        final chosen = <String>[];
        for (final id in ids) {
          if (id is String && inPool.contains(id) && !chosen.contains(id)) chosen.add(id);
        }
        if (chosen.isEmpty) return;
        (_picks[era as String] ??= {})[level] =
            chosen.take(_targetCount(era, level)).toList();
      });
    });
  }

  /// The ids the teacher wants asked in this level, or none.
  static Set<String> picksFor(String era, int level) =>
      (_picks[era]?[level] ?? const <String>[]).toSet();

  /// Goes back to the bundled questions only (on logout).
  static void clearSynced() {
    _synced.clear();
    _picks.clear();
  }

  /// The levels currently using downloaded questions, as `era/level` keys.
  @visibleForTesting
  static Set<String> get syncedLevels => {
        for (final e in _synced.entries)
          for (final l in e.value.keys) '${e.key}/$l',
      };

  /// Forgets everything loaded, so a test can start from the bundled assets.
  @visibleForTesting
  static void resetForTest() {
    _bank.clear();
    _synced.clear();
    _picks.clear();
    _loaded = false;
  }

  static Question? _parsePlayable(Object? raw) {
    if (raw is! Map) return null;
    try {
      final q = Question.fromJson(Map<String, dynamic>.from(raw));
      final labels = q.options.map((o) => o.label).toSet();
      final playable = q.id.isNotEmpty &&
          q.questionText.trim().isNotEmpty &&
          q.options.length >= 2 &&
          labels.length == q.options.length &&
          q.options.every((o) => o.label.isNotEmpty && o.text.trim().isNotEmpty) &&
          labels.contains(q.correctAnswer);
      return playable ? q : null;
    } catch (_) {
      return null;
    }
  }

  /// How many questions a level asks: the boss level's warm-up plus boss
  /// phase, or [GameConstants.questionsPerLevel] for every other level. Which
  /// level number is "the boss level" is era-specific (Section 1's level
  /// counts are uneven), so this needs the era, not just the level index.
  static int _targetCount(String era, int level) =>
      level == getEraById(era).levels.length
          ? GameConstants.bossWarmupQuestions + GameConstants.bossFightQuestions
          : GameConstants.questionsPerLevel;

  /// Retrieves local MELC-aligned questions for a given Era and Level.
  ///
  /// Each call is a fresh attempt: when the level's pool holds more questions
  /// than the level needs, a random subset is drawn, and every returned
  /// question has its options reshuffled. Pass [random] to make this
  /// deterministic (tests).
  ///
  /// Requires [loadAll] to have completed first; if it hasn't, this falls
  /// back to generated placeholder questions rather than throwing, since a
  /// quiz should never hard-crash the game.
  static List<Question> getQuestions(String era, int level, {Random? random}) {
    final rng = random ?? Random();
    final targetCount = _targetCount(era, level);

    final pool = _poolOf(era, level);
    final List<Question> questions;
    if (pool == null || pool.isEmpty) {
      questions = _fallbackQuestions(era, level, targetCount);
    } else {
      questions = selectQuestions(pool, targetCount, rng);
      // Short pool: placeholders go after the real questions, not among them.
      if (questions.length < targetCount) {
        questions.addAll(
          _placeholderQuestions(
            era,
            level,
            pool.first.gradeLevel,
            from: questions.length,
            to: targetCount,
          ),
        );
      }
    }

    // The cached pool stays in source order; shuffle per attempt so the
    // correct answer moves around every time (source data is all "A").
    return questions.map((q) => q.withShuffledOptions(rng)).toList();
  }

  /// Draws up to [target] distinct questions from [pool] in random order.
  /// Returns the whole pool (shuffled) if it has [target] or fewer.
  @visibleForTesting
  static List<Question> selectQuestions(
    List<Question> pool,
    int target,
    Random random,
  ) {
    return (List<Question>.from(pool)..shuffle(random)).take(target).toList();
  }

  /// The whole authored pool for a level, in source order, or an empty list
  /// if nothing loaded for it. Unlike [getQuestions] this neither samples,
  /// pads nor shuffles — [QuestionPool] owns those decisions now, because
  /// serving questions one at a time across an attempt needs state that a
  /// static, stateless draw can't keep (GAMEPLAY-V2.md Section 14, Phase 3:
  /// "rework QuestionBank from a list into a pool").
  static List<Question> poolFor(String era, int level) =>
      List<Question>.unmodifiable(_poolOf(era, level) ?? const <Question>[]);

  /// Whether real authored content exists for this era/level, as opposed to
  /// [getQuestions] silently substituting generated placeholders.
  static bool hasRealQuestions(String era, int level) =>
      (_poolOf(era, level)?.isNotEmpty) ?? false;

  static List<Question> _placeholderQuestions(
    String era,
    int level,
    String gradeLevel, {
    required int from,
    required int to,
  }) {
    final grade = gradeLevel.isNotEmpty ? gradeLevel : 'grade5';
    return List.generate(to - from, (i) {
      final qNum = from + i + 1;
      return Question(
        id: '${era}_${level}_$qNum',
        era: era,
        level: level,
        gradeLevel: grade,
        questionText: 'Dagdag na tanong $qNum para sa $era antas $level. (Kailangang palitan ng totoong tanong)',
        options: const [
          QuestionOption(label: 'A', text: 'Tamang Sagot'),
          QuestionOption(label: 'B', text: 'Maling Sagot 1'),
          QuestionOption(label: 'C', text: 'Maling Sagot 2'),
          QuestionOption(label: 'D', text: 'Maling Sagot 3'),
        ],
        correctAnswer: 'A',
        explanation: 'Paliwanag ng placeholder.',
      );
    });
  }

  static List<Question> _fallbackQuestions(
    String era,
    int level,
    int targetCount,
  ) {
    return List.generate(
      targetCount,
      (i) => Question(
        id: '${era}_${level}_$i',
        era: era,
        level: level,
        questionText: 'Tanong ${i + 1}: Sino ang pambansang bayani ng Pilipinas?',
        options: const [
          QuestionOption(label: 'A', text: 'Dr. Jose Rizal'),
          QuestionOption(label: 'B', text: 'Andres Bonifacio'),
          QuestionOption(label: 'C', text: 'Apolinario Mabini'),
          QuestionOption(label: 'D', text: 'Emilio Aguinaldo'),
        ],
        correctAnswer: 'A',
        explanation: 'Si Dr. Jose Rizal ang ating Pambansang Bayani.',
      ),
    );
  }
}