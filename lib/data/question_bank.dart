import 'dart:convert';
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

  /// Retrieves local MELC-aligned questions for a given Era and Level.
  ///
  /// Requires [loadAll] to have completed first; if it hasn't, this falls
  /// back to generated placeholder questions rather than throwing, since a
  /// quiz should never hard-crash the game.
  static List<Question> getQuestions(String era, int level) {
    final eraMap = _bank[era];
    if (eraMap == null) return _fallbackQuestions(era, level);

    final questions = eraMap[level];
    if (questions == null || questions.isEmpty) {
      return _fallbackQuestions(era, level);
    }

    final targetCount = level == 10
        ? GameConstants.bossWarmupQuestions + GameConstants.bossFightQuestions // 22
        : GameConstants.questionsPerLevel; // 5

    if (questions.length < targetCount) {
      final padded = List<Question>.from(questions);
      final startIndex = padded.length;
      final grade = questions.isNotEmpty ? questions.first.gradeLevel : 'grade5';

      padded.addAll(List.generate(targetCount - startIndex, (i) {
        final qNum = startIndex + i + 1;
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
      }));
      return padded;
    }

    return questions;
  }

  static List<Question> _fallbackQuestions(String era, int level) {
    final targetCount = level == 10
        ? GameConstants.bossWarmupQuestions + GameConstants.bossFightQuestions // 22
        : GameConstants.questionsPerLevel; // 5
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