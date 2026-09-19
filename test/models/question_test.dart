import 'dart:math';

import 'package:chronoquest/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

Question _question({
  List<String> texts = const ['Tama', 'Mali 1', 'Mali 2', 'Mali 3'],
}) {
  const labels = ['A', 'B', 'C', 'D', 'E', 'F'];
  return Question(
    id: 'q1',
    era: 'spanish',
    questionText: 'test',
    options: [
      for (var i = 0; i < texts.length; i++)
        QuestionOption(label: labels[i], text: texts[i]),
    ],
    correctAnswer: 'A',
    elapsedSeconds: 7,
  );
}

String _correctText(Question q) =>
    q.options.firstWhere((o) => o.label == q.correctAnswer).text;

void main() {
  group('Question.withShuffledOptions', () {
    test('keeps the same option texts', () {
      final shuffled = _question().withShuffledOptions(Random(1));
      expect(
        shuffled.options.map((o) => o.text).toSet(),
        {'Tama', 'Mali 1', 'Mali 2', 'Mali 3'},
      );
    });

    test('relabels A, B, C, D in order', () {
      final shuffled = _question().withShuffledOptions(Random(1));
      expect(shuffled.options.map((o) => o.label), ['A', 'B', 'C', 'D']);
    });

    test('correctAnswer still points at the originally correct option', () {
      for (var seed = 0; seed < 30; seed++) {
        final shuffled = _question().withShuffledOptions(Random(seed));
        expect(_correctText(shuffled), 'Tama', reason: 'seed $seed');
      }
    });

    test('leaves the original instance untouched', () {
      final original = _question();
      original.withShuffledOptions(Random(1));
      expect(original.options.map((o) => o.text),
          ['Tama', 'Mali 1', 'Mali 2', 'Mali 3']);
      expect(original.correctAnswer, 'A');
    });

    test('different seeds produce more than one arrangement', () {
      final answers = {
        for (var seed = 0; seed < 30; seed++)
          _question().withShuffledOptions(Random(seed)).correctAnswer,
      };
      expect(answers.length, greaterThan(1));
    });

    test('identical option texts still mark the right position', () {
      // Options B and C share text with the correct one (A). Tracking the
      // correct option by text would be ambiguous here.
      final q = _question(texts: const ['Pareho', 'Pareho', 'Pareho', 'Iba']);
      for (var seed = 0; seed < 30; seed++) {
        final shuffled = q.withShuffledOptions(Random(seed));
        final correctIdx =
            shuffled.options.indexWhere((o) => o.label == shuffled.correctAnswer);
        expect(correctIdx, isNonNegative);
        expect(shuffled.options[correctIdx].text, 'Pareho');
      }
    });

    test('resets elapsedSeconds on the copy', () {
      expect(_question().withShuffledOptions(Random(1)).elapsedSeconds, 0);
    });

    test('question with no options is copied unchanged', () {
      final q = Question(
        id: 'q',
        era: 'spanish',
        questionText: 't',
        options: const [],
        correctAnswer: '',
      );
      final copy = q.withShuffledOptions(Random(1));
      expect(copy.options, isEmpty);
      expect(copy.correctAnswer, '');
    });
  });
}
