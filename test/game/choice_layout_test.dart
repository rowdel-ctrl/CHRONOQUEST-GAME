// The answer choices sit in two columns that read down: A over B on the left, C over D on the
// right (the user's rule, 2026-11-16), on the ordinary question card and on the boss's card.
import 'package:chronoquest/game/overlays/boss_question_card.dart';
import 'package:chronoquest/game/overlays/question_card.dart';
import 'package:chronoquest/models/question.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Question _q(int n) => Question(
      id: 'q',
      era: 'spanish',
      questionText: 'Tanong',
      options: [
        for (var i = 0; i < n; i++)
          QuestionOption(label: 'ABCD'[i], text: 'Sagot ${'ABCD'[i]}'),
      ],
      correctAnswer: 'A',
      explanation: '',
    );

Offset _at(WidgetTester tester, String letter) =>
    tester.getTopLeft(find.text('$letter) Sagot $letter'));

Future<void> _show(WidgetTester tester, Widget card) async {
  tester.view.physicalSize = const Size(900, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: card))));
  await tester.pumpAndSettle();
}

Widget _ordinary(Question q) => QuestionCard(
      question: q,
      secondsElapsed: 0,
      answered: false,
      selectedAnswer: null,
      hiddenOptions: const [],
      showPowerups: false,
      fiftyFiftyCount: 0,
      shieldCount: 0,
      shieldActive: false,
      onAnswer: (_) {},
      onContinue: () {},
      onFiftyFifty: () {},
      onShield: () {},
    );

Widget _boss(Question q) => BossQuestionCard(
      question: q,
      phaseTag: 'Phase 1 · 15 s',
      fraction: 1,
      secondsLeft: 15,
      frozen: false,
      answered: false,
      selectedAnswer: null,
      timeFreezeCount: 0,
      onAnswer: (_) {},
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final (name, build) in [('the ordinary card', _ordinary), ('the boss card', _boss)]) {
    testWidgets('$name: A over B on the left, C over D on the right', (tester) async {
      await _show(tester, build(_q(4)));
      final a = _at(tester, 'A'), b = _at(tester, 'B'), c = _at(tester, 'C'), d = _at(tester, 'D');
      expect(a.dx, b.dx, reason: 'A and B in one column');
      expect(c.dx, d.dx, reason: 'C and D in one column');
      expect(c.dx, greaterThan(a.dx), reason: 'C and D are the right-hand column');
      expect(b.dy, greaterThan(a.dy), reason: 'B is below A');
      expect(d.dy, greaterThan(c.dy), reason: 'D is below C');
      expect(a.dy, c.dy, reason: 'A and C share the top row');
      expect(b.dy, d.dy, reason: 'B and D share the second row');
    });

    testWidgets('$name: with three choices, A over B and C beside A', (tester) async {
      await _show(tester, build(_q(3)));
      final a = _at(tester, 'A'), b = _at(tester, 'B'), c = _at(tester, 'C');
      expect(a.dx, b.dx);
      expect(b.dy, greaterThan(a.dy));
      expect(c.dx, greaterThan(a.dx));
      expect(c.dy, a.dy);
    });
  }
}
