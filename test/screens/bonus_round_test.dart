// The bonus round screen: a gold circle opens over the level, the 20 seconds run, a
// tally counts the coins, the wallet gets them once, and the circle closes back onto
// the portal. Leaving early (pause menu, back button) pays what was collected so far.
import 'dart:io';

import 'package:chronoquest/core/bonus_constants.dart';
import 'package:chronoquest/game/bonus/bonus_game.dart';
import 'package:chronoquest/game/bonus/bonus_session.dart';
import 'package:chronoquest/game/overlays/bonus_hud.dart';
import 'package:chronoquest/game/overlays/bonus_tally.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/services/audio_service.dart';
import 'package:chronoquest/screens/game/bonus_round_screen.dart';
import 'package:chronoquest/services/server_clock.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart' show AudioPool;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

const _goKey = ValueKey('go-to-bonus');

class _Harness {
  final GameNotifier wallet;
  final String studentId;
  BonusResult? result;
  bool returned = false;
  _Harness(this.wallet, this.studentId);
}

int _students = 0;

Future<_Harness> _open(WidgetTester tester, {int startCoins = 100}) async {
  // A new student each time, so one test never starts with what another saved.
  final studentId = 'bonus-screen-student-${_students++}';
  await tester.binding.setSurfaceSize(const Size(1000, 460));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final wallet = GameNotifier(clock: ServerClock.fixed(DateTime.utc(2020, 1, 1, 12)))
    ..loadWallet(studentId);
  if (wallet.state.coins != startCoins) {
    wallet.addCoins(startCoins - wallet.state.coins);
  }
  final h = _Harness(wallet, studentId);
  await tester.pumpWidget(ProviderScope(
    overrides: [gameProvider.overrideWith((ref) => wallet)],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: _goKey,
              onPressed: () async {
                h.result = await Navigator.of(context).push<BonusResult>(
                  BonusRoundScreen.route(const BonusRequest(
                    eraId: 'pre-colonial',
                    levelNo: 3,
                    characterId: 'rizal',
                    controlScheme: 'joystick',
                    portalOnScreen: Offset(.4, .6),
                  )),
                );
                h.returned = true;
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.byKey(_goKey));
  await tester.pump();
  return h;
}

BonusGame _gameOf(WidgetTester tester) =>
    tester.widget<GameWidget<BonusGame>>(find.byType(GameWidget<BonusGame>)).game!;

/// Lets the round load, the circle open and the clock start.
Future<BonusGame> _untilRunning(WidgetTester tester) async {
  for (var i = 0; i < 120; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(GameWidget<BonusGame>).evaluate().isNotEmpty &&
        _gameOf(tester).running &&
        _gameOf(tester).player.isLoaded) {
      return _gameOf(tester);
    }
  }
  fail('the round never started');
}

Future<void> _forward(WidgetTester tester, double seconds) async {
  var left = seconds;
  while (left > 0) {
    final step = left < .1 ? left : .1;
    await tester.pump(Duration(milliseconds: (step * 1000).round()));
    left -= step;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageDir =
      Directory.systemTemp.createTempSync('chronoquest_bonus_screen_test_').path;

  setUpAll(() async {
    // No sound plugin in a test: the sound switch is off, as for a student who muted it.
    AudioService().setSoundEnabled(false);
    AudioService().poolFactory =
        (file) => Future<AudioPool>.error(StateError('no sound in a test'));
    GoogleFonts.config.allowRuntimeFetching = false;
    Hive.init(storageDir);
    await Hive.openBox('chronoquest');
  });


  testWidgets('opens with the gold HUD: BONUS, the 20 s bar, the counter and the no-heart chip',
      (tester) async {
    final h = await _open(tester);
    final game = await _untilRunning(tester);

    expect(find.text('BONUS'), findsOneWidget);
    expect(find.text('Walang mawawalang puso'), findsOneWidget);
    expect(find.byKey(BonusHudWidget.barKey), findsOneWidget);
    expect(find.text('20 s'), findsOneWidget);
    expect(find.byKey(BonusHudWidget.counterKey), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('BONUS ROUND!'), findsOneWidget, reason: 'the opening banner');

    game.collectCoin();
    game.collectCoin();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('2'), findsOneWidget);
    expect(h.returned, isFalse);

    // Leave so no timers are left running.
    await tester.tap(find.byKey(BonusHudWidget.pauseKey));
    await tester.pump();
    await tester.tap(find.byKey(BonusPauseWidget.leaveKey));
    await _forward(tester, 1.2);
  });

  testWidgets('the 20 seconds run, the tally counts, the wallet gets the coins once, and the level is back',
      (tester) async {
    final h = await _open(tester);
    final game = await _untilRunning(tester);

    for (var i = 0; i < 30; i++) {
      game.collectCoin();
    }
    game.loseLife(); // an enemy: 30 - 5 = 25
    expect(game.counter, 25);
    expect(h.wallet.state.coins, 100, reason: 'nothing is paid while the round runs');

    game.forceTimeUp();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Tapos na ang oras!'), findsOneWidget);
    expect(find.byKey(BonusTallyWidget.panelKey), findsOneWidget);

    // Part way through the count the total is still climbing.
    await _forward(tester, .9);
    final partial = tester.widget<Text>(find.byKey(BonusTallyWidget.totalKey)).data!;
    expect(partial, startsWith('Bonus +'));
    expect(h.wallet.state.coins, 100, reason: 'not yet paid before the count ends');

    // The count ends on the real number and the wallet has it.
    await _forward(tester, 1.0);
    expect(find.text('Bonus +25 coins'), findsOneWidget);
    expect(find.text('Nakuhang coins'), findsOneWidget);
    expect(find.text('Natanggal ng kalaban'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(BonusTallyWidget.panelKey), matching: find.text('-5')),
        findsOneWidget);
    expect(h.wallet.state.coins, 125);
    expect(StorageService.getWallet(h.studentId)!['coins'], 125,
        reason: 'saved on the phone like every level coin');

    // Then the circle closes and the level is shown again with the result.
    await _forward(tester, 3.0);
    expect(h.returned, isTrue);
    expect(find.byKey(_goKey), findsOneWidget);
    expect(h.result!.coins, 25);
    expect(h.result!.grabbed, 30);
    expect(h.result!.knockedLoose, 5);
    expect(h.result!.leftEarly, isFalse);
    expect(h.wallet.state.coins, 125, reason: 'paid once, not again on the way out');
  });

  testWidgets('a tap on the tally shows the final count at once, and the next tap goes back',
      (tester) async {
    final h = await _open(tester);
    final game = await _untilRunning(tester);
    for (var i = 0; i < 10; i++) {
      game.collectCoin();
    }
    game.forceTimeUp();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byKey(BonusTallyWidget.panelKey), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Bonus +10 coins'), findsOneWidget);
    expect(h.wallet.state.coins, 110);

    await tester.tap(find.byKey(BonusTallyWidget.panelKey), warnIfMissed: false);
    await _forward(tester, 1.0);
    expect(h.returned, isTrue);
    expect(h.result!.coins, 10);
    expect(h.wallet.state.coins, 110);
  });

  testWidgets('pause holds the round; Ituloy goes on; Lumabas pays what was collected and goes back',
      (tester) async {
    final h = await _open(tester);
    final game = await _untilRunning(tester);
    for (var i = 0; i < 8; i++) {
      game.collectCoin();
    }

    await tester.tap(find.byKey(BonusHudWidget.pauseKey));
    await tester.pump();
    expect(game.paused, isTrue);
    expect(find.text('PAUSE'), findsOneWidget);
    expect(find.text('Kung lalabas ka, makukuha mo ang 8 coins.'), findsOneWidget);
    final left = game.timeLeft;
    await _forward(tester, 2);
    expect(game.timeLeft, left, reason: 'the clock is held with the game');

    await tester.tap(find.byKey(BonusPauseWidget.playKey));
    await tester.pump();
    expect(game.paused, isFalse);
    expect(find.text('PAUSE'), findsNothing);

    await tester.tap(find.byKey(BonusHudWidget.pauseKey));
    await tester.pump();
    await tester.tap(find.byKey(BonusPauseWidget.leaveKey));
    await _forward(tester, 1.2);

    expect(h.returned, isTrue);
    expect(h.result!.coins, 8);
    expect(h.result!.leftEarly, isTrue);
    expect(h.wallet.state.coins, 108);
    expect(find.byKey(_goKey), findsOneWidget);
  });

  testWidgets('the back button opens the pause menu, and again it closes it', (tester) async {
    final h = await _open(tester);
    final game = await _untilRunning(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(game.paused, isTrue);
    expect(find.text('PAUSE'), findsOneWidget);
    expect(h.returned, isFalse, reason: 'back never drops the student out of the round by accident');

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(game.paused, isFalse);
    expect(find.text('PAUSE'), findsNothing);

    // Out of the round for the test's sake.
    await tester.tap(find.byKey(BonusHudWidget.pauseKey));
    await tester.pump();
    await tester.tap(find.byKey(BonusPauseWidget.leaveKey));
    await _forward(tester, 1.2);
    expect(h.returned, isTrue);
    expect(h.result!.coins, 0);
    expect(h.wallet.state.coins, 100, reason: 'nothing collected, nothing paid');
  });

  testWidgets('the round is 20 seconds long on its clock, and the bar shows it', (tester) async {
    await _open(tester);
    final game = await _untilRunning(tester);
    expect(game.clock.value, closeTo(BonusConstants.roundSeconds, .6));

    await _forward(tester, 3);
    expect(game.timeLeft, lessThan(BonusConstants.roundSeconds - 2));
    expect(find.text('${game.timeLeft.ceil()} s'), findsOneWidget);

    await tester.tap(find.byKey(BonusHudWidget.pauseKey));
    await tester.pump();
    await tester.tap(find.byKey(BonusPauseWidget.leaveKey));
    await _forward(tester, 1.2);
  });
}
