// The quiz card has to show all four options (and, after a wrong answer, the
// explanation and Continue button) at once on a landscape phone.
//
// The bug this guards against: the card was a fixed 500 px column inside a
// scroll view, built for a ~720 px tall window. On a phone (~360-412 px tall)
// it scrolled, leaving options C and D below the fold with the timer running.
//
// Text renders in the test font (wider than Poppins), so these tests check
// what is robust to that — that the card fits, that taps land, that the
// desktop layout is untouched — rather than exact pixel heights. Whether the
// phone layout also *looks* right is checked in a real run.
import 'package:chronoquest/game/overlays/question_card.dart';
import 'package:chronoquest/game/overlays/question_layout.dart';
import 'package:chronoquest/models/question.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _explanation = 'Ang Pilipinas ay binubuo ng mahigit 7,000 isla na '
    'nahahati sa tatlong pangkat: Luzon, Visayas, at Mindanao.';

/// Real landscape sizes (logical px) the card has to fit.
const _phones = <String, Size>{
  '873x393 modern phone': Size(873, 393),
  '812x375 iPhone X': Size(812, 375),
  '667x375 iPhone 8': Size(667, 375),
  '640x360 small phone': Size(640, 360),
};
const _desktops = <String, Size>{
  '1280x720': Size(1280, 720),
  '1264x625 browser window': Size(1264, 625),
};

Question _question(String explanation) => Question(
      id: 'q1',
      era: 'pre-colonial',
      questionText: 'Ilang isla ang bumubuo sa kapuluan ng Pilipinas?',
      options: const [
        QuestionOption(label: 'A', text: 'Mahigit 7,000'),
        QuestionOption(label: 'B', text: 'Mahigit 500'),
        QuestionOption(label: 'C', text: 'Mahigit 1,000'),
        QuestionOption(label: 'D', text: 'Mahigit 3,000'),
      ],
      correctAnswer: 'A',
      explanation: explanation,
    );

class _Calls {
  final answers = <String>[];
  int continues = 0;
  int fiftyFifty = 0;
  int shields = 0;
}

Widget _card(
  _Calls calls, {
  bool answered = false,
  String? selected,
  List<String> hidden = const [],
  bool showPowerups = true,
  int fiftyFifty = 1,
  int shield = 1,
  String explanation = _explanation,
}) =>
    QuestionCard(
      question: _question(explanation),
      secondsElapsed: 4,
      answered: answered,
      selectedAnswer: selected,
      hiddenOptions: hidden,
      showPowerups: showPowerups,
      fiftyFiftyCount: fiftyFifty,
      shieldCount: shield,
      shieldActive: false,
      onAnswer: calls.answers.add,
      onContinue: () => calls.continues++,
      onFiftyFifty: () => calls.fiftyFifty++,
      onShield: () => calls.shields++,
    );

/// Mirrors how the overlay places the card: centred, given the whole canvas.
Future<void> _pump(
  WidgetTester tester,
  Size size,
  Widget card, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(body: Center(child: card)),
  ));
  await tester.pumpAndSettle();
}

/// On-screen rect after any FittedBox scaling (getRect would report the
/// unscaled size).
Rect _onScreen(WidgetTester tester, Finder finder) =>
    Rect.fromPoints(tester.getTopLeft(finder), tester.getBottomRight(finder));

/// How much the card was scaled down to fit: 1.0 means not at all.
double _scaleOf(WidgetTester tester) {
  final card = find.byKey(QuestionCard.cardKey);
  return _onScreen(tester, card).width / tester.getSize(card).width;
}

void expectOnScreen(WidgetTester tester, Finder finder, Size screen) {
  final rect = _onScreen(tester, finder);
  final bounds = (Offset.zero & screen).inflate(0.5);
  expect(bounds.contains(rect.topLeft) && bounds.contains(rect.bottomRight),
      isTrue,
      reason: '$rect is not inside $screen');
}

void main() {
  // No network in tests: fall back to the default font instead of fetching.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('QuestionLayout.forHeight', () {
    test('uses compact on landscape phone heights', () {
      for (final h in [360.0, 375.0, 393.0, 412.0]) {
        expect(QuestionLayout.forHeight(h), same(QuestionLayout.compact),
            reason: 'height $h');
      }
    });

    test('uses regular on desktop-sized heights', () {
      for (final h in [625.0, 720.0, 768.0, 1080.0]) {
        expect(QuestionLayout.forHeight(h), same(QuestionLayout.regular),
            reason: 'height $h');
      }
    });

    test('switches exactly at compactBelowHeight', () {
      const at = QuestionLayout.compactBelowHeight;
      expect(QuestionLayout.forHeight(at - 0.1), same(QuestionLayout.compact));
      expect(QuestionLayout.forHeight(at), same(QuestionLayout.regular));
    });

    test('an unbounded height falls back to regular', () {
      expect(QuestionLayout.forHeight(double.infinity),
          same(QuestionLayout.regular));
    });

    test('compact is genuinely more compact', () {
      expect(QuestionLayout.compact.optionHeight,
          lessThan(QuestionLayout.regular.optionHeight));
      expect(QuestionLayout.compact.padding,
          lessThan(QuestionLayout.regular.padding));
      // ...without shrinking the text into unreadability.
      expect(QuestionLayout.compact.optionFontSize, greaterThanOrEqualTo(13));
      expect(QuestionLayout.compact.questionFontSize,
          greaterThanOrEqualTo(15));
    });
  });

  group('On a landscape phone the whole card is on screen', () {
    for (final entry in _phones.entries) {
      final size = entry.value;

      testWidgets('${entry.key}: before answering', (tester) async {
        await _pump(tester, size, _card(_Calls()));

        expectOnScreen(tester, find.byKey(QuestionCard.cardKey), size);
        for (final text in ['A) Mahigit 7,000', 'B) Mahigit 500',
            'C) Mahigit 1,000', 'D) Mahigit 3,000', '50/50 ×1']) {
          expectOnScreen(tester, find.text(text), size);
        }
        expect(_scaleOf(tester), closeTo(1, 0.001),
            reason: 'compact layout should not need any scaling here');
      });

      testWidgets('${entry.key}: wrong answer with explanation',
          (tester) async {
        await _pump(tester, size,
            _card(_Calls(), answered: true, selected: 'D'));

        expectOnScreen(tester, find.byKey(QuestionCard.cardKey), size);
        expectOnScreen(tester, find.text('SUSUNOD'), size);
        expectOnScreen(tester, find.text('Paliwanag'), size);
        expectOnScreen(tester, find.text('C) Mahigit 1,000'), size);
        // The point of the compact layout: text stays close to full size.
        expect(_scaleOf(tester), greaterThan(0.85));
      });
    }
  });

  group('Taps still land after the card is scaled', () {
    testWidgets('every option can be tapped on a phone', (tester) async {
      final calls = _Calls();
      await _pump(tester, _phones.values.last, _card(calls));

      for (final label in ['A', 'B', 'C', 'D']) {
        await tester.tap(find.textContaining('$label) '));
      }
      expect(calls.answers, ['A', 'B', 'C', 'D']);
    });

    testWidgets('Continue works on a phone', (tester) async {
      final calls = _Calls();
      await _pump(tester, _phones.values.last,
          _card(calls, answered: true, selected: 'B'));

      await tester.tap(find.text('SUSUNOD'));
      expect(calls.continues, 1);
    });

    testWidgets('Continue works when the card is scaled down hard',
        (tester) async {
      final calls = _Calls();
      await _pump(tester, const Size(640, 360),
          _card(calls, answered: true, selected: 'B',
              explanation: List.filled(12, _explanation).join(' ')));
      expect(_scaleOf(tester), lessThan(1), reason: 'test needs a scaled card');

      await tester.tap(find.text('SUSUNOD'));
      expect(calls.continues, 1);
    });
  });

  group('Safety net for content that still does not fit', () {
    testWidgets('a very long explanation is scaled down, not cut off',
        (tester) async {
      const size = Size(640, 360);
      await _pump(tester, size, _card(_Calls(),
          answered: true, selected: 'B',
          explanation: List.filled(12, _explanation).join(' ')));

      expectOnScreen(tester, find.byKey(QuestionCard.cardKey), size);
      expectOnScreen(tester, find.text('SUSUNOD'), size);
      expect(_scaleOf(tester), lessThan(1));
    });

    testWidgets('a large system font is scaled down, not cut off',
        (tester) async {
      const size = Size(873, 393);
      await _pump(tester, size,
          _card(_Calls(), answered: true, selected: 'B'), textScale: 1.6);

      expectOnScreen(tester, find.byKey(QuestionCard.cardKey), size);
      expectOnScreen(tester, find.text('SUSUNOD'), size);
    });

    testWidgets('a screen narrower than the card scales it, not overflows',
        (tester) async {
      const size = Size(480, 700);
      await _pump(tester, size, _card(_Calls()));

      expectOnScreen(tester, find.byKey(QuestionCard.cardKey), size);
    });
  });

  group('Desktop layout is unchanged', () {
    for (final entry in _desktops.entries) {
      testWidgets('${entry.key}: 500 px card, never scaled', (tester) async {
        await _pump(tester, entry.value,
            _card(_Calls(), answered: true, selected: 'B'));

        expect(tester.getSize(find.byKey(QuestionCard.cardKey)).width, 500);
        expect(_scaleOf(tester), closeTo(1, 0.001));
        expectOnScreen(tester, find.byKey(QuestionCard.cardKey), entry.value);
      });
    }
  });

  group('Behaviour moved out of the overlay is intact', () {
    testWidgets('power-ups show before answering, not in the boss fight',
        (tester) async {
      await _pump(tester, _desktops.values.first, _card(_Calls()));
      expect(find.text('50/50 ×1'), findsOneWidget);
      expect(find.text('Shield ×1'), findsOneWidget);

      await _pump(tester, _desktops.values.first,
          _card(_Calls(), showPowerups: false));
      expect(find.textContaining('50/50'), findsNothing);
    });

    testWidgets('a wrong answer swaps the power-ups for the explanation',
        (tester) async {
      await _pump(tester, _desktops.values.first,
          _card(_Calls(), answered: true, selected: 'D'));

      expect(find.text('Paliwanag'), findsOneWidget);
      expect(find.text('SUSUNOD'), findsOneWidget);
      expect(find.textContaining('50/50'), findsNothing);
      expect(find.text('MALI!'), findsOneWidget);
    });

    testWidgets('a right answer shows no explanation', (tester) async {
      await _pump(tester, _desktops.values.first,
          _card(_Calls(), answered: true, selected: 'A'));

      expect(find.text('TAMA!'), findsOneWidget);
      expect(find.text('Paliwanag'), findsNothing);
    });

    testWidgets('50/50 hides the chosen options but keeps the grid steady',
        (tester) async {
      await _pump(tester, _desktops.values.first,
          _card(_Calls(), hidden: ['B', 'C']));

      expect(find.textContaining('B) '), findsNothing);
      expect(find.textContaining('C) '), findsNothing);
      expect(find.textContaining('A) '), findsOneWidget);
      expect(find.textContaining('D) '), findsOneWidget);
      // D stays in the second column of the second row, not shuffled up.
      expect(tester.getTopLeft(find.textContaining('D) ')).dy,
          greaterThan(tester.getTopLeft(find.textContaining('A) ')).dy));
    });

    testWidgets('power-up taps reach their callbacks', (tester) async {
      final calls = _Calls();
      await _pump(tester, _desktops.values.first, _card(calls));

      await tester.tap(find.text('50/50 ×1'));
      await tester.tap(find.text('Shield ×1'));
      expect([calls.fiftyFifty, calls.shields], [1, 1]);
    });

    testWidgets('an empty power-up cannot be used', (tester) async {
      final calls = _Calls();
      await _pump(tester, _desktops.values.first,
          _card(calls, fiftyFifty: 0, shield: 0));

      await tester.tap(find.text('50/50 ×0'));
      await tester.tap(find.text('Shield ×0'));
      expect([calls.fiftyFifty, calls.shields], [0, 0]);
    });
  });
}
