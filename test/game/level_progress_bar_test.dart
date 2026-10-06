// The progress bar along the bottom of a level: how far the hero is from the
// start to the gate.
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/overlays/level_progress_bar.dart';
import 'package:chronoquest/widgets/gate_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the fraction walked', () {
    double f(double x) =>
        LevelProgressBar.fractionFor(playerX: x, startX: 200, endX: 1200);

    test('is 0 at the start and 1 at the end', () {
      expect(f(200), 0);
      expect(f(1200), 1);
    });

    test('is proportional in between', () {
      expect(f(700), closeTo(0.5, 1e-9));
      expect(f(450), closeTo(0.25, 1e-9));
    });

    test('never leaves 0..1, even when knocked back or past the exit', () {
      expect(f(-500), 0);
      expect(f(5000), 1);
    });

    test('a level with no length shows nothing walked', () {
      expect(LevelProgressBar.fractionFor(playerX: 10, startX: 100, endX: 100), 0);
    });
  });

  testWidgets('shows the gate and reads out the percentage', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = ChronoGame();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: LevelProgressBar(game: game),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(GateIcon), findsOneWidget, reason: 'the bar leads to the gate');
    expect(find.bySemanticsLabel('0% ng level ang natapos'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink()); // stops its timer
  });

  testWidgets('fits a short phone without overflowing', (tester) async {
    for (final w in [640.0, 800.0, 900.0]) {
      await tester.binding.setSurfaceSize(Size(w, 360));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: LevelProgressBar(game: ChronoGame()),
          ),
        ),
      ));
      expect(tester.takeException(), isNull, reason: 'width $w');
    }
    await tester.binding.setSurfaceSize(null);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
