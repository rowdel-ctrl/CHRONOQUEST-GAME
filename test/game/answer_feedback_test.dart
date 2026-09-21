import 'package:chronoquest/game/overlays/answer_feedback.dart';
import 'package:chronoquest/game/overlays/question_widgets.dart';
import 'package:chronoquest/models/question.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: 240, child: child))),
    );

Widget _button(AnswerState state) => SizedBox(
      height: 60,
      child: AnswerButton(
        option: const QuestionOption(label: 'B', text: 'Barangay'),
        state: state,
        selected: false,
        onTap: () {},
      ),
    );

void main() {
  // No network in tests: fall back to the default font instead of fetching.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Answer buttons show a right/wrong icon, not colour alone', () {
    testWidgets('no icon before answering', (tester) async {
      await tester.pumpWidget(_wrap(_button(AnswerState.neutral)));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.cancel), findsNothing);
      expect(find.text('B) Barangay'), findsOneWidget);
    });

    testWidgets('correct option gets a check', (tester) async {
      await tester.pumpWidget(_wrap(_button(AnswerState.correct)));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNothing);
    });

    testWidgets('wrong pick gets an X', (tester) async {
      await tester.pumpWidget(_wrap(_button(AnswerState.wrong)));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });
  });

  group('Feedback badge', () {
    testWidgets('says TAMA! with a check when correct', (tester) async {
      await tester.pumpWidget(
          _wrap(const AnswerFeedbackBadge(correct: true)));
      await tester.pumpAndSettle();
      expect(find.text('TAMA!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('says MALI! with an X when wrong', (tester) async {
      await tester.pumpWidget(
          _wrap(const AnswerFeedbackBadge(correct: false)));
      await tester.pumpAndSettle();
      expect(find.text('MALI!'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('pops in from zero scale and settles at full size',
        (tester) async {
      await tester.pumpWidget(
          _wrap(const AnswerFeedbackBadge(correct: true)));
      double scale() => tester
          .widget<Transform>(find.descendant(
            of: find.byType(AnswerFeedbackBadge),
            matching: find.byType(Transform),
          ))
          .transform
          .storage[0]; // x scale (getMaxScaleOnAxis also counts z, always 1)
      expect(scale(), lessThan(0.01));
      await tester.pumpAndSettle();
      expect(scale(), closeTo(1.0, 0.001));
    });
  });
}
