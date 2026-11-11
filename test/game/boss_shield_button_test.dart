// The Shield button on the screen during the boss fight: it shows how many are left, lights up
// while the bubble is on, and switches it on at any moment with one tap (not only from a
// question card).
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/overlays/hud_overlay.dart';
import 'package:chronoquest/models/student.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

ChronoGame _game(int shields) {
  final game = ChronoGame();
  game.playerPowerUps = PowerUps(shield: shields);
  if (game.audioService.soundEnabled) game.audioService.toggleSound(); // no audio plugin in tests
  return game;
}

Widget _button(ChronoGame game) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: ListenableBuilder(
            listenable: game,
            builder: (_, __) => BossShieldButton(game: game),
          ),
        ),
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows how many shields are left', (tester) async {
    await tester.pumpWidget(_button(_game(2)));
    expect(find.text('×2'), findsOneWidget);
    expect(find.byIcon(Icons.shield), findsOneWidget);
  });

  testWidgets('one tap switches the Shield on, takes one from the stock, and a second tap does nothing',
      (tester) async {
    final game = _game(2);
    await tester.pumpWidget(_button(game));
    await tester.tap(find.byKey(BossShieldButton.shieldKey));
    await tester.pump();
    expect(game.shieldActive, isTrue);
    expect(game.playerPowerUps.shield, 1);
    expect(find.text('×1'), findsOneWidget);
    await tester.tap(find.byKey(BossShieldButton.shieldKey));
    await tester.pump();
    expect(game.playerPowerUps.shield, 1, reason: 'already on: nothing more is used');
  });

  testWidgets('it reports the use, so the wallet pays for it', (tester) async {
    final game = _game(1);
    final used = <String>[];
    game.onPowerUpUsed = used.add;
    await tester.pumpWidget(_button(game));
    await tester.tap(find.byKey(BossShieldButton.shieldKey));
    await tester.pump();
    expect(used, ['shield']);
  });

  testWidgets('with none left it does nothing', (tester) async {
    final game = _game(0);
    await tester.pumpWidget(_button(game));
    await tester.tap(find.byKey(BossShieldButton.shieldKey), warnIfMissed: false);
    await tester.pump();
    expect(game.shieldActive, isFalse);
    expect(game.activateShield(), isFalse);
  });
}
