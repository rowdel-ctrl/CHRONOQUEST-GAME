import 'dart:math';

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/data/question_bank.dart';
import 'package:chronoquest/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

// Kept separate from question_bank_test.dart: loadAll() fills static state,
// which would turn that file's "bank not loaded" fallback tests into
// real-data tests.
bool _isPlaceholder(Question q) => q.questionText.startsWith('Dagdag na tanong');

String _correctText(Question q) =>
    q.options.firstWhere((o) => o.label == q.correctAnswer).text;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(QuestionBank.loadAll);

  test('a level with a full lesson of questions needs no placeholders', () {
    for (final era in ['pre-colonial', 'spanish', 'nationalism']) {
      final qs = QuestionBank.getQuestions(era, 1, random: Random(1));
      expect(qs.length, GameConstants.questionsPerLevel, reason: era);
      expect(qs.any(_isPlaceholder), isFalse, reason: era);
    }
  });

  test('level 1 real questions come only from the level 1 pool', () {
    final qs = QuestionBank.getQuestions('pre-colonial', 1, random: Random(1));
    final real = qs.where((q) => !_isPlaceholder(q));
    expect(real, isNotEmpty);
    expect(real.every((q) => q.id.startsWith('pre_1_')), isTrue);
  });

  test('every attempt reshuffles options: correct label is not always A', () {
    final labels = {
      for (var seed = 0; seed < 10; seed++)
        ...QuestionBank.getQuestions('pre-colonial', 1, random: Random(seed))
            .map((q) => q.correctAnswer),
    };
    expect(labels.length, greaterThan(1));
  });

  test('a question keeps its correct answer text across reshuffles', () {
    // A level has more questions than it asks (15 a Linggo), so each attempt picks some of them.
    final texts = <String, Set<String>>{};
    for (var seed = 0; seed < 20; seed++) {
      for (final q in QuestionBank.getQuestions('pre-colonial', 1, random: Random(seed))) {
        (texts[q.id] ??= {}).add(_correctText(q));
      }
    }
    expect(texts, isNotEmpty);
    texts.forEach((id, set) => expect(set.length, 1, reason: '$id changed its right answer'));
  });

  test('boss level returns 22 distinct questions', () {
    final qs = QuestionBank.getQuestions('pre-colonial', 10, random: Random(1));
    expect(
      qs.length,
      GameConstants.bossWarmupQuestions + GameConstants.bossFightQuestions,
    );
    expect(qs.map((q) => q.id).toSet().length, qs.length);
  });

  test('boss level order changes between attempts', () {
    final orders = {
      for (var seed = 0; seed < 5; seed++)
        QuestionBank.getQuestions('pre-colonial', 10, random: Random(seed))
            .map((q) => q.id)
            .join(','),
    };
    expect(orders.length, greaterThan(1));
  });
}
