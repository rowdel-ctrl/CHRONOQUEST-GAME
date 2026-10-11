// The menu hearts pill: one heart, a count, a plus that opens the buy dialog.
// BILHIN spends the wallet's coins and adds a heart.
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/widgets/hearts_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Stands in for GameNotifier, whose constructor starts a Hive write that
/// never completes inside a widget test (see tutorial_screen_test.dart).
class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame(int hearts, int coins)
      : super(GameState(
          coins: coins,
          hearts: HeartsState(count: hearts, regenStartMs: null),
        ));

  int bought = 0;

  @override
  Duration? get heartCountdown => null;

  @override
  bool buyHeart() {
    if (state.hearts.count >= GameConstants.maxHearts ||
        state.coins < GameConstants.heartPriceCoins) {
      return false;
    }
    bought++;
    state = state.copyWith(
      coins: state.coins - GameConstants.heartPriceCoins,
      hearts: state.hearts.withHeart(),
    );
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

late _FakeGame _game;

Future<void> _pump(WidgetTester tester, {required int hearts, required int coins}) async {
  _game = _FakeGame(hearts, coins);
  await tester.binding.setSurfaceSize(const Size(800, 360));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameProvider.overrideWith((ref) => _game),
      ],
      child: const MaterialApp(
        home: Scaffold(body: Center(child: HeartsPill())),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('a heart costs 20 coins for now', () {
    expect(GameConstants.heartPriceCoins, 20);
  });

  testWidgets('shows a single count, not a row of hearts', (tester) async {
    await _pump(tester, hearts: 3, coins: 0);

    expect(find.textContaining('3', findRichText: true), findsWidgets);
    expect(find.textContaining('/5', findRichText: true), findsOneWidget);
    // One heart icon only.
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('plus opens the buy dialog with the price', (tester) async {
    await _pump(tester, hearts: 3, coins: 100);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Bumili ng Puso'), findsOneWidget);
    expect(find.text('${GameConstants.heartPriceCoins}'), findsOneWidget);
    expect(find.textContaining('3/5', findRichText: true), findsWidgets);
    expect(find.textContaining('4/5', findRichText: true), findsOneWidget);
  });

  testWidgets('BILHIN spends the coins and adds the heart', (tester) async {
    await _pump(tester, hearts: 3, coins: 50);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('BILHIN'));
    await tester.pumpAndSettle();

    expect(_game.bought, 1);
    expect(_game.state.hearts.count, 4);
    expect(_game.state.coins, 50 - GameConstants.heartPriceCoins);
    // The dialog is still open and now shows the new count.
    expect(find.text('Bumili ng Puso'), findsOneWidget);
    expect(find.textContaining('4/5', findRichText: true), findsWidgets);
  });

  testWidgets('BILHIN is off when the coins do not cover it', (tester) async {
    await _pump(tester, hearts: 3, coins: 19);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('BILHIN'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(_game.bought, 0);
  });

  testWidgets('too few coins says so', (tester) async {
    await _pump(tester, hearts: 3, coins: 5);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.textContaining('Kulang ang coins'), findsOneWidget);
  });

  testWidgets('a full pool is told there is nothing to buy', (tester) async {
    await _pump(tester, hearts: GameConstants.maxHearts, coins: 500);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Puno na ang Puso'), findsOneWidget);
    expect(find.text('BILHIN'), findsNothing);
  });

  testWidgets('the dialog closes', (tester) async {
    await _pump(tester, hearts: 3, coins: 100);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('KANSELAHIN'));
    await tester.pumpAndSettle();

    expect(find.text('Bumili ng Puso'), findsNothing);
  });
}
