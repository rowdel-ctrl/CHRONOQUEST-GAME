import 'dart:math';

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/data/question_bank.dart';
import 'package:chronoquest/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

List<Question> _pool(int size) => [
      for (var i = 0; i < size; i++)
        Question(
          id: 'q$i',
          era: 'spanish',
          questionText: 'Tanong $i',
          options: const [
            QuestionOption(label: 'A', text: 'Tama'),
            QuestionOption(label: 'B', text: 'Mali 1'),
            QuestionOption(label: 'C', text: 'Mali 2'),
            QuestionOption(label: 'D', text: 'Mali 3'),
          ],
          correctAnswer: 'A',
        ),
    ];

void main() {
  group('QuestionBank.selectQuestions', () {
    test('draws exactly target distinct questions from a larger pool', () {
      final drawn = QuestionBank.selectQuestions(_pool(15), 5, Random(1));
      expect(drawn.length, 5);
      expect(drawn.map((q) => q.id).toSet().length, 5);
    });

    test('different seeds draw different subsets', () {
      final subsets = {
        for (var seed = 0; seed < 10; seed++)
          (QuestionBank.selectQuestions(_pool(15), 5, Random(seed))
                  .map((q) => q.id)
                  .toList()
                ..sort())
              .join(','),
      };
      expect(subsets.length, greaterThan(1));
    });

    test('returns the whole pool when it is smaller than the target', () {
      final drawn = QuestionBank.selectQuestions(_pool(3), 5, Random(1));
      expect(drawn.map((q) => q.id).toSet(), {'q0', 'q1', 'q2'});
    });

    test('does not modify the pool it draws from', () {
      final pool = _pool(15);
      QuestionBank.selectQuestions(pool, 5, Random(1));
      expect(pool.map((q) => q.id), [for (var i = 0; i < 15; i++) 'q$i']);
    });
  });

  group('QuestionBank.getQuestions (bank not loaded)', () {
    test('returns a level-sized fallback list', () {
      expect(
        QuestionBank.getQuestions('spanish', 1, random: Random(1)).length,
        GameConstants.questionsPerLevel,
      );
    });

    test('boss level returns warm-up plus boss questions', () {
      expect(
        QuestionBank.getQuestions('spanish', 10, random: Random(1)).length,
        GameConstants.bossWarmupQuestions + GameConstants.bossFightQuestions,
      );
    });

    test('correct answer is not always A', () {
      final answers = {
        for (var seed = 0; seed < 10; seed++)
          ...QuestionBank.getQuestions('spanish', 1, random: Random(seed))
              .map((q) => q.correctAnswer),
      };
      expect(answers.length, greaterThan(1));
    });

    test('correct answer always marks the right text', () {
      for (final q in QuestionBank.getQuestions('spanish', 1, random: Random(3))) {
        final correct = q.options.firstWhere((o) => o.label == q.correctAnswer);
        expect(correct.text, 'Dr. Jose Rizal');
      }
    });
  });
}
