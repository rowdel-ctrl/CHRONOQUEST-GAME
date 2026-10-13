// TINDAHAN: hearts and power-ups bought with coins.
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/models/student.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/screens/shop/shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Stands in for GameNotifier (whose constructor starts a Hive write that never
/// completes in a widget test) with the same buying rules.
class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame({int coins = 28, int hearts = 3})
      : super(GameState(
          coins: coins,
          powerUps: PowerUps(fiftyFifty: 2, shield: 1),
          hearts: HeartsState(count: hearts, regenStartMs: null),
        ));

  @override
  Duration? get heartCountdown => null;

  @override
  void refreshHearts() {}

  @override
  bool buyHeart() {
    if (state.hearts.count >= GameConstants.maxHearts ||
        state.coins < GameConstants.heartPriceCoins) {
      return false;
    }
    state = state.copyWith(
      coins: state.coins - GameConstants.heartPriceCoins,
      hearts: state.hearts.withHeart(),
    );
    return true;
  }

  @override
  bool buyAllHearts() {
    final missing = GameConstants.maxHearts - state.hearts.count;
    final cost = missing * GameConstants.heartPriceCoins;
    if (missing <= 0 || state.coins < cost) return false;
    var h = state.hearts;
    for (var i = 0; i < missing; i++) {
      h = h.withHeart();
    }
    state = state.copyWith(coins: state.coins - cost, hearts: h);
    return true;
  }

  @override
  bool buyPowerUp(PowerUpKind kind) {
    if (state.coins < kind.priceCoins) return false;
    final p = state.powerUps;
    switch (kind) {
      case PowerUpKind.fiftyFifty:
        p.fiftyFifty++;
      case PowerUpKind.shield:
        p.shield++;
      case PowerUpKind.timeFreeze:
        p.timeFreeze++;
    }
    state = state.copyWith(coins: state.coins - kind.priceCoins, powerUps: p);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

late _FakeGame _game;

Future<void> _open(
  WidgetTester tester, {
  int coins = 28,
  int hearts = 3,
  Size size = const Size(812, 375),
}) async {
  _game = _FakeGame(coins: coins, hearts: hearts);
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  await tester.pumpWidget(ProviderScope(
    overrides: [gameProvider.overrideWith((ref) => _game)],
    child: const MaterialApp(home: ShopScreen()),
  ));
  await tester.pump();
}


void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('lists the three power-ups with what is held and the price', (tester) async {
    await _open(tester);

    expect(find.byKey(ShopScreen.coinsKey), findsOneWidget);
    expect(find.text('28'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('×2'), findsOneWidget, reason: '50/50 held');
    expect(find.text('×1'), findsOneWidget, reason: 'shields held');
    expect(find.text('×0'), findsOneWidget, reason: 'time freezes held');
    for (final kind in PowerUpKind.values) {
      expect(find.byKey(ShopScreen.buyKey(kind)), findsOneWidget);
      expect(find.descendant(
        of: find.byKey(ShopScreen.buyKey(kind)),
        matching: find.text('${kind.priceCoins}'),
      ), findsOneWidget);
    }
  });

  testWidgets('a purchase takes the coins, adds one and says so', (tester) async {
    await _open(tester);

    await tester.tap(find.byKey(ShopScreen.buyKey(PowerUpKind.shield)));
    await tester.pump();

    expect(_game.state.coins, 28 - GameConstants.shieldPriceCoins);
    expect(_game.state.powerUps.shield, 2);
    expect(find.text('×2'), findsNWidgets(2), reason: '50/50 and shields both at 2 now');
    expect(find.byKey(ShopScreen.toastKey), findsOneWidget);
    expect(find.text('NABILI! SHIELD ×2'), findsOneWidget);

    // The message goes away on its own.
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(ShopScreen.toastKey), findsNothing);
  });

  testWidgets('what the coins do not cover cannot be bought and says how short', (tester) async {
    await _open(tester);

    // 28 coins against a Time Freeze at 30.
    expect(find.text('Kulang ng 2'), findsOneWidget);
    await tester.tap(find.byKey(ShopScreen.buyKey(PowerUpKind.timeFreeze)), warnIfMissed: false);
    await tester.pump();

    expect(_game.state.powerUps.timeFreeze, 0);
    expect(_game.state.coins, 28);
    expect(find.byKey(ShopScreen.toastKey), findsNothing);
  });

  testWidgets('buys one heart, or fills the pool at once', (tester) async {
    await _open(tester, coins: 100, hearts: 2);

    await tester.tap(find.byKey(ShopScreen.buyHeartKey));
    await tester.pump();
    expect(_game.state.hearts.count, 3);
    expect(_game.state.coins, 80);

    // Two missing now: PUNUIN (2) costs 40.
    expect(find.text('PUNUIN (2)'), findsOneWidget);
    await tester.tap(find.byKey(ShopScreen.fillHeartsKey));
    await tester.pump();
    expect(_game.state.hearts.count, GameConstants.maxHearts);
    expect(_game.state.coins, 40);
    expect(find.text('Puno na ang puso mo. Walang kailangang bilhin.'), findsOneWidget);
    expect(find.byKey(ShopScreen.buyHeartKey), findsNothing);
  });

  testWidgets('the fill button waits until all the missing hearts are affordable', (tester) async {
    await _open(tester, coins: 30, hearts: 2); // 3 missing = 60

    await tester.tap(find.byKey(ShopScreen.fillHeartsKey), warnIfMissed: false);
    await tester.pump();
    expect(_game.state.hearts.count, 2);
    expect(_game.state.coins, 30);

    // One at a time still works.
    await tester.tap(find.byKey(ShopScreen.buyHeartKey));
    await tester.pump();
    expect(_game.state.hearts.count, 3);
  });

  testWidgets('with too few coins for a heart it says how many are missing', (tester) async {
    await _open(tester, coins: 5, hearts: 3);
    expect(find.text('Kulang ng 15 coins'), findsOneWidget);
    await tester.tap(find.byKey(ShopScreen.buyHeartKey), warnIfMissed: false);
    await tester.pump();
    expect(_game.state.hearts.count, 3);
  });

  testWidgets('fits small phones, wide and narrow', (tester) async {
    for (final size in const [Size(640, 360), Size(732, 320), Size(390, 780)]) {
      await _open(tester, size: size, coins: 140, hearts: 2);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });
}
