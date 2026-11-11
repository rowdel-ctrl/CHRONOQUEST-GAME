// The boss fight's question card (boss_question_card.dart): small, at the top centre of the screen so
// the hero, the boss and the attack stay in view; the bar is the attack's flight; only the card takes
// touches.
import 'package:chronoquest/game/overlays/boss_question_card.dart';
import 'package:chronoquest/game/overlays/question_widgets.dart';
import 'package:chronoquest/models/question.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Question _question({String text = 'Sino ang nagtatag ng Katipunan?'}) =>
    Question(
      id: 'b1',
      era: 'spanish',
      questionText: text,
      options: const [
        QuestionOption(label: 'A', text: 'Andres Bonifacio'),
        QuestionOption(label: 'B', text: 'Emilio Aguinaldo'),
        QuestionOption(label: 'C', text: 'Jose Rizal'),
        QuestionOption(label: 'D', text: 'Apolinario Mabini'),
      ],
      correctAnswer: 'A',
      explanation: 'Si Bonifacio ang Supremo ng Katipunan.',
    );

BossQuestionCard _card({
  Question? question,
  double fraction = 1,
  int seconds = 15,
  bool frozen = false,
  bool answered = false,
  String? selected,
  int freezes = 1,
  void Function(String)? onAnswer,
  VoidCallback? onFreeze,
}) =>
    BossQuestionCard(
      question: question ?? _question(),
      phaseTag: 'Phase 1 · 15 s',
      fraction: fraction,
      secondsLeft: seconds,
      frozen: frozen,
      answered: answered,
      selectedAnswer: selected,
      timeFreezeCount: freezes,
      onAnswer: onAnswer ?? (_) {},
      onTimeFreeze: onFreeze,
    );

Future<void> _pump(WidgetTester tester, Size size, Widget card,
    {Widget? behind}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Stack(children: [
        if (behind != null) Positioned.fill(child: behind),
        Positioned.fill(child: card),
      ]),
    ),
  ));
  await tester.pumpAndSettle();
}

Rect _rect(WidgetTester tester) => Rect.fromPoints(
      tester.getTopLeft(find.byKey(BossQuestionCard.cardKey)),
      tester.getBottomRight(find.byKey(BossQuestionCard.cardKey)),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const phones = {
    'phone 873x393': Size(873, 393),
    'small phone 640x360': Size(640, 360),
    'tablet 1024x768': Size(1024, 768),
    'wide 1280x720': Size(1280, 720),
  };

  group('where the card sits', () {
    for (final entry in phones.entries) {
      testWidgets('${entry.key}: top centre, never below the boss\'s head',
          (tester) async {
        final screen = entry.value;
        await _pump(tester, screen, _card());
        final r = _rect(tester);
        expect((r.center.dx - screen.width / 2).abs(), lessThan(1),
            reason: 'centred');
        expect(r.top, greaterThanOrEqualTo(BossQuestionCard.topInset - 1),
            reason: 'below the boss\'s name and health bar');
        expect(r.bottom,
            lessThanOrEqualTo(screen.height * BossQuestionCard.lowestShare + 1),
            reason:
                'the lower part of the screen is the hero, the boss and the attack');
        expect(r.width, lessThanOrEqualTo(screen.width * 0.56 + 1));
        expect(r.left, greaterThan(0));
        expect(r.right, lessThan(screen.width));
      });
    }

    testWidgets(
        'a very long question is scaled down, not allowed to grow over the boss',
        (tester) async {
      const screen = Size(873, 393);
      final long =
          'Ano ang tawag sa sinaunang sistema ng pagsulat ng mga Pilipino bago pa man '
                  'dumating ang mga Espanyol, na ginamit ng mga ninuno natin sa mga talaan at liham? ' *
              2;
      await _pump(tester, screen, _card(question: _question(text: long)));
      expect(_rect(tester).bottom,
          lessThanOrEqualTo(screen.height * BossQuestionCard.lowestShare + 1));
    });

    testWidgets(
        'only the card takes touches: the rest of the screen is the game\'s',
        (tester) async {
      var behind = 0;
      await _pump(
        tester,
        const Size(873, 393),
        _card(),
        behind: GestureDetector(
            behavior: HitTestBehavior.opaque, onTap: () => behind++),
      );
      await tester.tapAt(const Offset(80, 340)); // where the joystick is
      await tester.tapAt(const Offset(800, 340)); // where the buttons are
      expect(behind, 2);
      final inCard = _rect(tester).center;
      await tester.tapAt(inCard);
      expect(behind, 2, reason: 'a tap on the card does not reach the game');
    });
  });

  group('what it shows', () {
    testWidgets('the question, the four answers and the time', (tester) async {
      await _pump(
          tester, const Size(873, 393), _card(fraction: 0.6, seconds: 9));
      expect(find.text('Sino ang nagtatag ng Katipunan?'), findsOneWidget);
      expect(find.byType(AnswerButton), findsNWidgets(4));
      expect(find.text('Phase 1 · 15 s'), findsOneWidget);
      expect(find.text('9s'), findsOneWidget);
    });

    testWidgets(
        'the bar is the attack\'s flight: it empties as the attack comes',
        (tester) async {
      await _pump(
          tester, const Size(873, 393), _card(fraction: 0.25, seconds: 4));
      final bar =
          tester.widget<FractionallySizedBox>(find.byKey(CountdownBar.barKey));
      expect(bar.widthFactor, 0.25);
    });

    testWidgets('every answer can be tapped on a phone', (tester) async {
      final tapped = <String>[];
      await _pump(tester, const Size(640, 360), _card(onAnswer: tapped.add));
      for (final text in [
        'Andres Bonifacio',
        'Emilio Aguinaldo',
        'Jose Rizal',
        'Apolinario Mabini'
      ]) {
        await tester.tap(find.textContaining(text));
      }
      expect(tapped, ['A', 'B', 'C', 'D']);
    });

    testWidgets('answered right: TAMA! and the right answer marked',
        (tester) async {
      await _pump(tester, const Size(873, 393),
          _card(answered: true, selected: 'A', fraction: 0.5));
      expect(find.text('TAMA!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets(
        'answered wrong: MALI!, the right answer shown, the wrong one marked',
        (tester) async {
      await _pump(
          tester, const Size(873, 393), _card(answered: true, selected: 'C'));
      expect(find.text('MALI!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets,
          reason: 'the right answer is shown');
      expect(find.byIcon(Icons.cancel), findsWidgets,
          reason: 'the chosen one is marked wrong');
    });

    testWidgets('time ran out: MALI! and the right answer shown',
        (tester) async {
      await _pump(tester, const Size(873, 393),
          _card(answered: true, selected: '', fraction: 0, seconds: 0));
      expect(find.text('MALI!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
      expect(find.byIcon(Icons.cancel), findsOneWidget,
          reason: 'only the MALI! badge: no option was chosen to mark');
    });

    testWidgets('no explanation to wait for: the fight does not stop',
        (tester) async {
      await _pump(
          tester, const Size(873, 393), _card(answered: true, selected: 'B'));
      expect(find.textContaining('Si Bonifacio ang Supremo'), findsNothing);
      expect(find.text('SUSUNOD'), findsNothing);
    });
  });

  group('Time Freeze', () {
    testWidgets('tapping it calls back', (tester) async {
      var taps = 0;
      await _pump(tester, const Size(873, 393), _card(onFreeze: () => taps++));
      await tester.tap(find.byKey(BossQuestionCard.freezeKey));
      expect(taps, 1);
    });

    testWidgets(
        'with none left, already frozen, or after answering, it cannot be used',
        (tester) async {
      var taps = 0;
      for (final card in [
        _card(freezes: 0, onFreeze: () => taps++),
        _card(frozen: true, onFreeze: () => taps++),
        _card(answered: true, selected: 'A', onFreeze: () => taps++),
      ]) {
        await _pump(tester, const Size(873, 393), card);
        await tester.tap(find.byKey(BossQuestionCard.freezeKey),
            warnIfMissed: false);
      }
      expect(taps, 0);
    });

    testWidgets('while frozen the bar shows the snowflake', (tester) async {
      await _pump(tester, const Size(873, 393),
          _card(frozen: true, fraction: 0.5, seconds: 7));
      expect(find.byIcon(Icons.ac_unit), findsWidgets);
    });
  });
}
