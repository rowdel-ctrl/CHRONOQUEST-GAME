// The HUD's resource bars and gate/artifact progress pill. A bare ChronoGame
// is enough: the overlay only reads plain fields and listens for changes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/overlays/hud_overlay.dart';
import 'package:chronoquest/game/overlays/hud_widgets.dart';
import 'package:chronoquest/widgets/gate_icon.dart';

Future<void> _pumpHud(WidgetTester tester, ChronoGame game) async {
  await tester.binding.setSurfaceSize(const Size(800, 360));
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: HudOverlayWidget(game: game))),
  );
  await tester.pump();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows hearts as a bar with a count', (tester) async {
    final game = ChronoGame()..hearts = 4;
    await _pumpHud(tester, game);

    expect(find.text('4/${GameConstants.maxHearts}'), findsOneWidget);
  });

  testWidgets('no "joystick to move" hint covers the screen at level start',
      (tester) async {
    // It sat over the middle of the level until the first jump, and the
    // tutorial already teaches the controls.
    final game = ChronoGame();
    await _pumpHud(tester, game);

    expect(find.textContaining('JOYSTICK'), findsNothing);
  });

  testWidgets('no level indicator is shown any more', (tester) async {
    final game = ChronoGame()..currentLevel = 3;
    await _pumpHud(tester, game);

    expect(find.textContaining('LVL'), findsNothing);
  });

  testWidgets('progress pill counts artifacts answered, right or wrong',
      (tester) async {
    // Answered, not claimed: the end gate opens on engagement, so a counter
    // tracking only correct answers would under-report progress.
    final game = ChronoGame()
      ..artifactsTotal = 5
      ..artifactsClaimed = 2
      ..artifactsAnswered = 3;
    await _pumpHud(tester, game);

    expect(find.textContaining('3/5', findRichText: true), findsOneWidget);
    expect(find.textContaining('2/5', findRichText: true), findsNothing);
  });

  testWidgets('progress pill marks the gate open once all are answered',
      (tester) async {
    final game = ChronoGame()
      ..artifactsTotal = 5
      ..artifactsAnswered = 5;
    await _pumpHud(tester, game);

    // The level progress bar has a gate icon of its own, so look in the pill.
    expect(
      find.descendant(
          of: find.byType(HudProgressPill), matching: find.byType(GateIcon)),
      findsOneWidget,
    );
  });

  testWidgets('progress pill updates when the game notifies', (tester) async {
    final game = ChronoGame()..artifactsTotal = 5;
    await _pumpHud(tester, game);
    expect(find.textContaining('0/5', findRichText: true), findsOneWidget);

    game.artifactsAnswered = 2;
    game.notifyState();
    await tester.pump();

    expect(find.textContaining('2/5', findRichText: true), findsOneWidget);
  });

  testWidgets('pill is hidden when the level has no artifacts',
      (tester) async {
    final game = ChronoGame();
    await _pumpHud(tester, game);

    // The pill widget is still in the tree; it just renders nothing, so the
    // artifact icon it would otherwise show is absent.
    expect(find.byType(HudProgressPill), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(HudProgressPill),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
  });

  testWidgets('Kaalaman above the display scale does not overflow the bar',
      (tester) async {
    final game = ChronoGame()..kaalaman = CombatConstants.kaalamanDisplayMax + 3;
    await _pumpHud(tester, game);

    expect(tester.takeException(), isNull);
  });
}
