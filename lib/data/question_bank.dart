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

  /// The eras with a corresponding `assets/data/questions_<era>.json` file.
  static const List<String> _eraIds = [
    'pre-colonial',
    'spanish',
    'american',
    'ww2',
    'modern',
  ];

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

  /// How many questions a level asks: the boss level's warm-up plus boss
  /// phase, or [GameConstants.questionsPerLevel] for every other level.
  static int _targetCount(int level) => level == 10
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
    final targetCount = _targetCount(level);

    final pool = _bank[era]?[level];
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