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
  bool explaining = false,
  VoidCallback? onContinue,
}) =>
    BossQuestionCard(
      explaining: explaining,
      onContinue: onContinue,
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
      final q = _question(text: long);
      await _pump(tester, screen, _card(question: q));
      expect(_rect(tester).bottom,
          lessThanOrEqualTo(screen.height * BossQuestionCard.roomFor(q).heightShare + 1));
    });

    testWidgets('even an enormous question never reaches below the roomiest limit', (tester) async {
      const screen = Size(732, 320);
      final q = _question(text: List.filled(400, 'salita').join(' '));
      await _pump(tester, screen, _card(question: q));
      expect(_rect(tester).bottom,
          lessThanOrEqualTo(screen.height * BossQuestionCard.roomiestShare + 1));
    });

    group('a long question gets more room', () {
      Question words(int n, {int optionWords = 3}) => Question(
            id: 'w$n',
            era: 'spanish',
            questionText: List.filled(n, 'salita').join(' '),
            options: [
              for (final l in ['A', 'B', 'C', 'D'])
                QuestionOption(label: l, text: List.filled(optionWords, 'sagot').join(' ')),
            ],
            correctAnswer: 'A',
          );

      test('a short card keeps the normal room, a 70-word card gets the roomiest', () {
        final short = BossQuestionCard.roomFor(words(14)); // 26 words
        expect(short.heightShare, BossQuestionCard.lowestShare);
        expect(short.widthShare, BossQuestionCard.normalWidthShare);
        final at40 = BossQuestionCard.roomFor(words(28)); // 40 words: still normal
        expect(at40.heightShare, BossQuestionCard.lowestShare);
        final big = BossQuestionCard.roomFor(words(58)); // 70 words
        expect(big.heightShare, closeTo(BossQuestionCard.roomiestShare, 1e-9));
        expect(big.widthShare, closeTo(BossQuestionCard.roomiestWidthShare, 1e-9));
        final huge = BossQuestionCard.roomFor(words(300));
        expect(huge.heightShare, closeTo(BossQuestionCard.roomiestShare, 1e-9), reason: 'it stops there');
      });

      test('the room grows smoothly with the words, never shrinks', () {
        var last = 0.0, lastWidth = 0.0;
        for (var n = 10; n <= 120; n += 5) {
          final r = BossQuestionCard.roomFor(words(n));
          expect(r.heightShare, greaterThanOrEqualTo(last));
          expect(r.widthShare, greaterThanOrEqualTo(lastWidth));
          last = r.heightShare;
          lastWidth = r.widthShare;
        }
      });

      for (final entry in {
        'small phone 732x320': const Size(732, 320),
        'small phone 640x360': const Size(640, 360),
        'modern phone 873x393': const Size(873, 393),
      }.entries) {
        testWidgets('${entry.key}: a 63-word card is wider than a short one, inside the screen and above the limit',
            (tester) async {
          final screen = entry.value;
          await _pump(tester, screen, _card(question: words(27, optionWords: 9)));
          final r = _rect(tester);
          expect(r.bottom, lessThanOrEqualTo(screen.height * BossQuestionCard.roomiestShare + 1));
          expect(r.top, greaterThanOrEqualTo(BossQuestionCard.topInset - 1));
          expect((r.center.dx - screen.width / 2).abs(), lessThan(1));
          expect(r.left, greaterThan(0));
          expect(r.right, lessThan(screen.width));

          final longWidth = tester.getSize(find.byKey(BossQuestionCard.cardKey)).width; // laid out, before any shrinking
          await _pump(tester, screen, _card());
          final shortWidth = tester.getSize(find.byKey(BossQuestionCard.cardKey)).width;
          expect(longWidth, greaterThan(shortWidth), reason: 'a long question is given width too');
        });
      }

      testWidgets('answering (the explanation) keeps the same room for the same question', (tester) async {
        const screen = Size(732, 320);
        final q = words(27, optionWords: 9);
        await _pump(tester, screen, _card(question: q));
        final before = _rect(tester);
        await _pump(tester, screen, _card(question: q, answered: true, selected: 'B', explaining: true, onContinue: () {}));
        final after = _rect(tester);
        expect(after.bottom, lessThanOrEqualTo(screen.height * BossQuestionCard.roomiestShare + 1));
        expect(before.bottom, lessThanOrEqualTo(screen.height * BossQuestionCard.roomiestShare + 1));
        expect(after.bottom, lessThanOrEqualTo(screen.height * BossQuestionCard.roomiestShare + 1));
      });
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

    testWidgets('while the attack is still moving the card does not explain yet',
        (tester) async {
      await _pump(
          tester, const Size(873, 393), _card(answered: true, selected: 'B'));
      expect(find.textContaining('Si Bonifacio ang Supremo'), findsNothing);
      expect(find.text('SUSUNOD'), findsNothing);
    });

    for (final (answer, badge) in [('A', 'TAMA!'), ('B', 'MALI!'), ('', 'MALI!')]) {
      testWidgets('once the hit has landed it shows the right answer and why ($badge)',
          (tester) async {
        var taps = 0;
        await _pump(
            tester,
            const Size(640, 360),
            _card(
                answered: true,
                selected: answer,
                explaining: true,
                onContinue: () => taps++));
        expect(find.text(badge), findsOneWidget);
        expect(find.textContaining('Tamang sagot: A) Andres Bonifacio'), findsOneWidget);
        expect(find.text('Paliwanag'), findsOneWidget);
        expect(find.textContaining('Si Bonifacio ang Supremo'), findsOneWidget);
        expect(find.textContaining('Sino ang nagtatag'), findsNothing,
            reason: 'the question and options make room for the explanation');
        // It stays inside the top part of the screen, above the boss.
        final rect = tester.getRect(find.byKey(BossQuestionCard.cardKey));
        expect(rect.bottom, lessThanOrEqualTo(360 * BossQuestionCard.lowestShare + 1));
        await tester.tap(find.text('SUSUNOD'));
        expect(taps, 1);
      });
    }
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
