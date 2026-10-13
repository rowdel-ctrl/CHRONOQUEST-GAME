// The boss question's 15-second clock, Time Freeze, and the boss card that
// shows them on a phone.
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/boss_countdown.dart';
import 'package:chronoquest/game/overlays/question_card.dart';
import 'package:chronoquest/game/overlays/question_widgets.dart';
import 'package:chronoquest/models/question.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Question _question() => Question(
      id: 'b1',
      era: 'spanish',
      questionText: 'Sino ang nagtatag ng Katipunan?',
      options: const [
        QuestionOption(label: 'A', text: 'Andres Bonifacio'),
        QuestionOption(label: 'B', text: 'Emilio Aguinaldo'),
        QuestionOption(label: 'C', text: 'Jose Rizal'),
        QuestionOption(label: 'D', text: 'Apolinario Mabini'),
      ],
      correctAnswer: 'A',
      explanation: 'Si Bonifacio ang Supremo ng Katipunan.',
    );

Widget _bossCard({
  required double fraction,
  required int seconds,
  bool frozen = false,
  int freezes = 1,
  bool answered = false,
  String? selected,
  VoidCallback? onFreeze,
}) =>
    QuestionCard(
      question: _question(),
      secondsElapsed: 0,
      answered: answered,
      selectedAnswer: selected,
      hiddenOptions: const [],
      showPowerups: false,
      fiftyFiftyCount: 1,
      shieldCount: 1,
      shieldActive: false,
      onAnswer: (_) {},
      onContinue: () {},
      onFiftyFifty: () {},
      onShield: () {},
      countdownFraction: fraction,
      countdownSeconds: seconds,
      countdownFrozen: frozen,
      timeFreezeCount: freezes,
      onTimeFreeze: onFreeze,
    );

Future<void> _pump(WidgetTester tester, Size size, Widget card) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: card))));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('BossCountdown', () {
    test('starts with the full 15 seconds', () {
      final c = BossCountdown();
      expect(c.secondsLeft, GameConstants.bossAnswerSeconds);
      expect(c.fraction, 1);
      expect(c.expired, isFalse);
    });

    test('runs down, and running out is flagged once at zero', () {
      final c = BossCountdown();
      c.tick(7.5);
      expect(c.fraction, closeTo(0.5, 1e-9));
      c.tick(7.4);
      expect(c.expired, isFalse);
      c.tick(1);
      expect(c.expired, isTrue);
      expect(c.secondsLeft, 0);
      c.tick(5); // never goes below zero
      expect(c.secondsLeft, 0);
    });

    test('Time Freeze stops the clock for the rest of the question', () {
      final c = BossCountdown();
      c.tick(10);
      c.freeze();
      c.tick(100);
      expect(c.frozen, isTrue);
      expect(c.secondsLeft, closeTo(5, 1e-9));
      expect(c.expired, isFalse);
    });
  });

  test('a wave has two minions, then three from the third wave on', () {
    expect([for (var i = 0; i < 6; i++) minionsInWave(i)], [2, 2, 3, 3, 3, 3]);
  });

  test('six right answers beat the boss', () {
    expect(GameConstants.bossQuestionsToWin, 6);
    expect(GameConstants.bossHealth, 6);
  });

  // A level where the teacher set a timer: an ordinary question with a clock.
  group('a timed question in an ordinary level', () {
    Widget timedCard({double fraction = 0.5, int seconds = 22}) => QuestionCard(
          question: _question(),
          secondsElapsed: 0,
          answered: false,
          selectedAnswer: null,
          hiddenOptions: const [],
          showPowerups: true,
          fiftyFiftyCount: 1,
          shieldCount: 1,
          shieldActive: false,
          onAnswer: (_) {},
          onContinue: () {},
          onFiftyFifty: () {},
          onShield: () {},
          countdownFraction: fraction,
          countdownSeconds: seconds,
        );

    testWidgets('shows the clock and still offers 50/50 and Shield, but not Time Freeze', (tester) async {
      await _pump(tester, const Size(812, 375), timedCard());
      expect(find.byType(CountdownBar), findsOneWidget);
      expect(find.byType(TimerChip), findsNothing);
      expect(find.text('22s'), findsOneWidget);
      expect(find.textContaining('50/50'), findsOneWidget);
      expect(find.textContaining('Shield'), findsOneWidget);
      expect(find.textContaining('Time Freeze'), findsNothing);
    });
  });

  group('the boss card', () {
    testWidgets('shows the bar instead of the count-up chip', (tester) async {
      await _pump(tester, const Size(812, 375), _bossCard(fraction: 0.6, seconds: 9));
      expect(find.byType(CountdownBar), findsOneWidget);
      expect(find.byType(TimerChip), findsNothing);
      expect(find.text('9s'), findsOneWidget);
    });

    testWidgets('the bar empties as time goes', (tester) async {
      await _pump(tester, const Size(812, 375), _bossCard(fraction: 0.25, seconds: 4));
      final bar = tester.widget<FractionallySizedBox>(find.byKey(CountdownBar.barKey));
      expect(bar.widthFactor, 0.25);
    });

    testWidgets('Time Freeze is offered, and tapping it calls back', (tester) async {
      var taps = 0;
      await _pump(tester, const Size(812, 375),
          _bossCard(fraction: 1, seconds: 15, onFreeze: () => taps++));
      expect(find.textContaining('Time Freeze'), findsOneWidget);
      expect(find.textContaining('50/50'), findsNothing);
      await tester.tap(find.textContaining('Time Freeze'));
      expect(taps, 1);
    });

    testWidgets('with none left, or already frozen, it cannot be used', (tester) async {
      var taps = 0;
      await _pump(tester, const Size(812, 375),
          _bossCard(fraction: 1, seconds: 15, freezes: 0, onFreeze: () => taps++));
      await tester.tap(find.textContaining('Time Freeze'), warnIfMissed: false);
      expect(taps, 0);

      await _pump(tester, const Size(812, 375),
          _bossCard(fraction: 0.5, seconds: 7, frozen: true, onFreeze: () => taps++));
      await tester.tap(find.textContaining('Time Freeze'), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('a timeout shows the explanation and Continue', (tester) async {
      await _pump(
        tester,
        const Size(667, 375),
        _bossCard(fraction: 0, seconds: 0, answered: true, selected: ''),
      );
      expect(find.textContaining('Si Bonifacio ang Supremo'), findsOneWidget);
    });

    testWidgets('fits a small phone', (tester) async {
      const screen = Size(640, 360);
      await _pump(tester, screen, _bossCard(fraction: 1, seconds: 15));
      final rect = Rect.fromPoints(
        tester.getTopLeft(find.byKey(QuestionCard.cardKey)),
        tester.getBottomRight(find.byKey(QuestionCard.cardKey)),
      );
      expect((Offset.zero & screen).inflate(0.5).contains(rect.topLeft), isTrue);
      expect((Offset.zero & screen).inflate(0.5).contains(rect.bottomRight), isTrue);
    });
  });
}
