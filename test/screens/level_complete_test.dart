// The level-complete card: it fits a short landscape phone without scrolling,
// says x/10 for ten artifacts, and shows one dot per artifact.
import 'package:chronoquest/screens/game/level_complete_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _show(
  WidgetTester tester, {
  required Size size,
  int level = 2,
  int correct = 10,
  int total = 10,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: LevelCompleteScreen(
      eraId: 'pre-colonial',
      level: level,
      result: LevelCompleteResult(score: 535, correct: correct, total: total),
    ),
  ));
  await tester.pump(const Duration(seconds: 2)); // stars and pop-in
}

double _maxScroll(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position.maxScrollExtent;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('fits a short landscape phone without scrolling', () {
    for (final size in const [Size(800, 360), Size(732, 320), Size(640, 360)]) {
      for (final level in [2, 3, 7]) {
        testWidgets('level $level at ${size.width.toInt()}x${size.height.toInt()}',
            (tester) async {
          await _show(tester, size: size, level: level);

          expect(tester.takeException(), isNull);
          expect(_maxScroll(tester), 0,
              reason: 'the card is taller than the screen, so it scrolls');
        });
      }
    }
  });

  testWidgets('says x/10 and draws a dot for each artifact', (tester) async {
    await _show(tester, size: const Size(800, 360), correct: 7, total: 10);

    expect(find.text('7/10 TAMA'), findsOneWidget);
    final dots = find.descendant(
      of: find.byKey(LevelCompleteScreen.dotsKey),
      matching: find.byType(Container),
    );
    expect(dots, findsNWidgets(10));

    final colours = [
      for (final c in tester.widgetList<Container>(dots))
        (c.decoration as BoxDecoration).color,
    ];
    expect(colours.where((c) => c != Colors.transparent).length, 7,
        reason: 'seven right, three missed');
    expect(colours.take(7).every((c) => c != Colors.transparent), isTrue,
        reason: 'the right ones come first');
  });

  testWidgets('no dots when the total is not a level of artifacts', (tester) async {
    await _show(tester, size: const Size(800, 360), correct: 0, total: 0);
    expect(find.byKey(LevelCompleteScreen.dotsKey), findsNothing);
  });

  testWidgets('a narrow screen falls back to one column and still lays out',
      (tester) async {
    await _show(tester, size: const Size(400, 700), level: 3);
    expect(tester.takeException(), isNull);
    expect(find.text('SUSUNOD'), findsOneWidget);
    expect(find.text('Nakakuha ng 50/50!'), findsOneWidget);
  });

  testWidgets('stars follow the share right', (tester) async {
    await _show(tester, size: const Size(800, 360), correct: 10, total: 10);
    expect(find.byIcon(Icons.star), findsNWidgets(3));
  });
}
