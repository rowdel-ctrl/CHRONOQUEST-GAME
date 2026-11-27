// Tap to pick, tap again to confirm (the user's idea, 2026-11-28): a slipped thumb on an answer
// button used to lock in a wrong answer at once. Now the first tap only lights the option up with
// "TAP ULIT"; a second tap on the same option answers; a tap on another option moves the pick.
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/overlays/answer_feedback.dart';
import 'package:chronoquest/game/overlays/boss_question_card.dart';
import 'package:chronoquest/game/overlays/question_card.dart';
import 'package:chronoquest/game/overlays/question_overlay.dart';
import 'package:chronoquest/game/overlays/question_widgets.dart';
import 'package:chronoquest/models/question.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Question _question({String id = 'q1'}) => Question(
      id: id,
      era: 'spanish',
      questionText: 'Sino ang nagtatag ng Katipunan?',
      options: const [
        QuestionOption(label: 'A', text: 'Bonifacio'),
        QuestionOption(label: 'B', text: 'Rizal'),
        QuestionOption(label: 'C', text: 'Luna'),
        QuestionOption(label: 'D', text: 'Mabini'),
      ],
      correctAnswer: 'A',
      explanation: 'Si Bonifacio ang Supremo.',
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('the question overlay of a level', () {
    late List<String> given;

    Future<ChronoGame> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(873, 393);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      given = [];
      final game = ChronoGame()
        ..currentEra = 'spanish'
        ..currentLevel = 2
        ..currentQuestion = _question();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: QuestionOverlayWidget(game: game, onAnswer: given.add)),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      return game;
    }

    Future<void> tap(WidgetTester tester, String text) async {
      await tester.tap(find.text(text));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('one tap only picks: nothing is answered, the option says TAP ULIT',
        (tester) async {
      await pump(tester);
      expect(find.byType(PickedTag), findsNothing);
      await tap(tester, 'B) Rizal'); // a wrong one, by a slip

      expect(find.byType(PickedTag), findsOneWidget);
      expect(find.text('TAP ULIT'), findsOneWidget);
      expect(find.byType(ExplanationPanel), findsNothing,
          reason: 'a wrong pick is not a wrong answer yet');
      expect(find.text('MALI!'), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(given, isEmpty);
    });

    testWidgets('a second tap on the same option answers it', (tester) async {
      await pump(tester);
      await tap(tester, 'B) Rizal');
      await tap(tester, 'B) Rizal');

      expect(find.text('MALI!'), findsOneWidget);
      expect(find.byType(ExplanationPanel), findsOneWidget);
      expect(find.byType(PickedTag), findsNothing, reason: 'the pick is over once it is answered');
    });

    testWidgets('a tap on another option moves the pick, nothing is answered',
        (tester) async {
      await pump(tester);
      await tap(tester, 'B) Rizal');
      await tap(tester, 'C) Luna');

      expect(find.byType(PickedTag), findsOneWidget);
      expect(find.byType(ExplanationPanel), findsNothing);
      expect(find.text('MALI!'), findsNothing);
      // The tag sits on C now, not B: tapping C again answers C.
      await tap(tester, 'C) Luna');
      expect(find.text('MALI!'), findsOneWidget);
    });

    testWidgets('the slip is fixed: pick the wrong one, change to the right one, confirm it',
        (tester) async {
      await pump(tester);
      await tap(tester, 'D) Mabini');
      await tap(tester, 'A) Bonifacio');
      expect(given, isEmpty);
      await tap(tester, 'A) Bonifacio');
      expect(find.text('TAMA!'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(given, ['A'], reason: 'a right answer moves the game on');
    });

    testWidgets('after an answer, more taps do nothing', (tester) async {
      await pump(tester);
      await tap(tester, 'B) Rizal');
      await tap(tester, 'B) Rizal');
      await tap(tester, 'A) Bonifacio');
      await tap(tester, 'A) Bonifacio');
      expect(find.byType(PickedTag), findsNothing);
      expect(find.text('MALI!'), findsOneWidget);
    });
  });

  group('the cards show the pick', () {
    testWidgets('QuestionCard: only the picked option has the tag', (tester) async {
      tester.view.physicalSize = const Size(873, 393);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QuestionCard(
            question: _question(),
            secondsElapsed: 0,
            answered: false,
            selectedAnswer: null,
            pickedAnswer: 'C',
            hiddenOptions: const [],
            showPowerups: false,
            fiftyFiftyCount: 0,
            shieldCount: 0,
            shieldActive: false,
            onAnswer: (_) {},
            onContinue: () {},
            onFiftyFifty: () {},
            onShield: () {},
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PickedTag), findsOneWidget);
    });

    testWidgets('BossQuestionCard: the picked option has the tag, and not once answered',
        (tester) async {
      tester.view.physicalSize = const Size(873, 393);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Widget card({required bool answered}) => MaterialApp(
            home: Scaffold(
              body: BossQuestionCard(
                question: _question(),
                phaseTag: 'Phase 1',
                fraction: 1,
                secondsLeft: 10,
                frozen: false,
                answered: answered,
                selectedAnswer: answered ? 'C' : null,
                pickedAnswer: 'C',
                timeFreezeCount: 0,
                onAnswer: (_) {},
              ),
            ),
          );
      await tester.pumpWidget(card(answered: false));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PickedTag), findsOneWidget);
      await tester.pumpWidget(card(answered: true));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PickedTag), findsNothing);
    });
  });
}
