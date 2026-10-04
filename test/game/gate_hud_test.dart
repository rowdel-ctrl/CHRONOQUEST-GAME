// The gate indicator: once every artifact is answered the student is told the
// gate is ready and how far away it is. A chip stays for the rest of the level
// and a message appears once, then goes away.
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/overlays/gate_hud.dart';
import 'package:chronoquest/widgets/gate_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// A game whose distance to the gate is whatever the test says, so the widget
/// is tested on its own, without building a level.
class _Game extends ChronoGame {
  double? units;

  @override
  double? gateDistanceUnits() => units;
}

Future<void> _pump(WidgetTester tester, _Game game) async {
  await tester.binding.setSurfaceSize(const Size(800, 360));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: GateHud(game: game)))),
  );
}

/// Tears the widget down so its timers are cancelled before the test ends.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

final _message = find.textContaining('Nasagot na ang lahat ng artifact');

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('distance is whole metres, rounded up so it never reads 0 early', () {
    expect(gateMetres(0), 0);
    expect(gateMetres(1), 1);
    expect(gateMetres(100), 1);
    expect(gateMetres(101), 2);
    expect(gateMetres(12345), 124);
  });

  testWidgets('shows nothing while artifacts remain', (tester) async {
    final game = _Game()..units = null;
    await _pump(tester, game);

    expect(find.byType(GateIcon), findsNothing);
    expect(_message, findsNothing);
    await _unmount(tester);
  });

  testWidgets('shows the chip and the message when the gate is ready',
      (tester) async {
    final game = _Game()..units = 12345;
    await _pump(tester, game);

    expect(find.text('124 m'), findsOneWidget);
    expect(_message, findsOneWidget);
    expect(find.textContaining('124 m sa unahan'), findsOneWidget);
    // The gate icon (a gate with an open padlock) is on the chip and in the
    // message, not the generic padlock from the icon font.
    expect(find.byType(GateIcon), findsNWidgets(2));
    expect(find.byIcon(Icons.lock_open), findsNothing);
    await _unmount(tester);
  });

  testWidgets('the message goes away after a few seconds, the chip stays',
      (tester) async {
    final game = _Game()..units = 12345;
    await _pump(tester, game);
    expect(_message, findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 400));

    expect(_message, findsNothing);
    expect(find.text('124 m'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('the message appears once, not again as the student walks',
      (tester) async {
    final game = _Game()..units = 12345;
    await _pump(tester, game);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_message, findsNothing);

    game.units = 8000;
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('80 m'), findsOneWidget, reason: 'the chip follows the walk');
    expect(_message, findsNothing);
    await _unmount(tester);
  });

  testWidgets('the distance counts down as the student walks', (tester) async {
    final game = _Game()..units = 5000;
    await _pump(tester, game);
    expect(find.text('50 m'), findsOneWidget);

    game.units = 1999;
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('20 m'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('the message waits for the question window to close',
      (tester) async {
    final game = _Game()
      ..units = 12345
      ..questionShowing = true;
    await _pump(tester, game);

    expect(find.text('124 m'), findsOneWidget);
    expect(_message, findsNothing, reason: 'a question is still on screen');

    game.questionShowing = false;
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(_message, findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('the chip disappears once the gate has opened', (tester) async {
    final game = _Game()..units = 500;
    await _pump(tester, game);
    expect(find.text('5 m'), findsOneWidget);

    game.units = null; // the gate opened
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(GateIcon), findsNothing);
    await _unmount(tester);
  });
}
