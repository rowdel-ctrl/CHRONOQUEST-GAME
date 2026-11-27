// The clock on a level's question: the teacher's number when there is one, otherwise a default that
// is never "for ever" and grows for a long question. (The boss fight has its own clock.)
import 'package:chronoquest/data/question_bank.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/overlays/question_overlay.dart';
import 'package:chronoquest/game/overlays/question_widgets.dart';
import 'package:chronoquest/models/question.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Question _question({int questionWords = 10, int optionWords = 2}) => Question(
      id: 'q1',
      era: 'spanish',
      questionText: List.filled(questionWords, 'salita').join(' '),
      options: [
        for (final l in ['A', 'B', 'C', 'D'])
          QuestionOption(label: l, text: List.filled(optionWords, 'sagot').join(' ')),
      ],
      correctAnswer: 'A',
      explanation: 'Dahil iyon ang tama.',
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(() => QuestionBank.applyTimer(null));

  group('QuestionBank.levelSecondsFor', () {
    test('with no number from the teacher a short question gets the default, never 0', () {
      expect(QuestionBank.defaultLevelSeconds, 45);
      expect(QuestionBank.levelSecondsFor('spanish', 1), 45);
      expect(QuestionBank.levelSecondsFor('spanish', 1, question: _question()), 45);
    });

    test('a long question gets reading time on top of the default', () {
      final long = _question(questionWords: 27, optionWords: 9); // 63 words
      expect(QuestionBank.levelSecondsFor('spanish', 1, question: long), 57);
      final huge = _question(questionWords: 80, optionWords: 20);
      expect(QuestionBank.levelSecondsFor('spanish', 1, question: huge), 45 + 25);
    });

    test('the teacher\'s number is used as it is, with no reading time on top', () {
      QuestionBank.applyTimer({'spanish': {'2': 20}});
      final long = _question(questionWords: 27, optionWords: 9);
      expect(QuestionBank.levelSecondsFor('spanish', 2, question: long), 20);
      expect(QuestionBank.levelSecondsFor('spanish', 3, question: long), 57, reason: 'another level: the default');
    });

    test('every level of every era has a clock', () {
      for (final era in ['pre-colonial', 'spanish', 'nationalism', 'american', 'ww2', 'modern']) {
        for (var level = 1; level <= 10; level++) {
          expect(QuestionBank.levelSecondsFor(era, level), greaterThan(0), reason: '$era $level');
        }
      }
    });
  });

  group('the question overlay of a level', () {
    Future<ChronoGame> pump(WidgetTester tester, Question q) async {
      tester.view.physicalSize = const Size(873, 393);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final game = ChronoGame()
        ..currentEra = 'spanish'
        ..currentLevel = 2
        ..currentQuestion = q;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: QuestionOverlayWidget(game: game, onAnswer: (_) {})),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      return game;
    }

    testWidgets('shows a countdown even when the teacher set no timer', (tester) async {
      await pump(tester, _question());
      expect(find.byType(CountdownBar), findsOneWidget);
    });

    testWidgets('time runs out: the question is answered wrong and the explanation shows', (tester) async {
      await pump(tester, _question());
      expect(find.byType(ExplanationPanel), findsNothing);
      await tester.pump(const Duration(seconds: 44));
      expect(find.byType(ExplanationPanel), findsNothing, reason: 'the default is 45 s');
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(ExplanationPanel), findsOneWidget);
    });

    testWidgets('a long question gets more time before it runs out', (tester) async {
      await pump(tester, _question(questionWords: 27, optionWords: 9));
      await tester.pump(const Duration(seconds: 50));
      expect(find.byType(ExplanationPanel), findsNothing, reason: '45 s + 12 s for reading');
      await tester.pump(const Duration(seconds: 9));
      expect(find.byType(ExplanationPanel), findsOneWidget);
    });

    testWidgets('the teacher\'s number sets the time', (tester) async {
      QuestionBank.applyTimer({'spanish': {'2': 20}});
      await pump(tester, _question());
      await tester.pump(const Duration(seconds: 19));
      expect(find.byType(ExplanationPanel), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(ExplanationPanel), findsOneWidget);
    });
  });
}
