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

  test('level 1 is padded to the level size with placeholders last', () {
    final qs = QuestionBank.getQuestions('pre-colonial', 1, random: Random(1));
    expect(qs.length, GameConstants.questionsPerLevel);

    final firstPlaceholder = qs.indexWhere(_isPlaceholder);
    // Real questions come first, then only placeholders.
    expect(firstPlaceholder, isNonNegative);
    expect(qs.skip(firstPlaceholder).every(_isPlaceholder), isTrue);
    expect(qs.take(firstPlaceholder).any(_isPlaceholder), isFalse);
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
    final texts = <String>{};
    for (var seed = 0; seed < 10; seed++) {
      final qs = QuestionBank.getQuestions('pre-colonial', 1, random: Random(seed));
      texts.add(_correctText(qs.firstWhere((q) => q.id == 'pre_1_1')));
    }
    expect(texts, {'Teoryang Austronesian'});
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
