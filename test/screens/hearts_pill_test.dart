// The menu hearts pill: one heart, a count, a plus that opens the shop.
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/widgets/hearts_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Stands in for GameNotifier, whose constructor starts a Hive write that
/// never completes inside a widget test (see tutorial_screen_test.dart).
class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame(int hearts)
      : super(GameState(hearts: HeartsState(count: hearts, regenStartMs: null)));

  @override
  Duration? get heartCountdown => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, {required int hearts}) async {
  await tester.binding.setSurfaceSize(const Size(800, 360));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const Scaffold(body: Center(child: HeartsPill())),
    ),
    GoRoute(
      path: '/shop',
      builder: (_, __) => const Scaffold(body: Text('shop stand-in')),
    ),
  ]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [gameProvider.overrideWith((ref) => _FakeGame(hearts))],
      child: MaterialApp.router(routerConfig: router),
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
    await _pump(tester, hearts: 3);

    expect(find.textContaining('3', findRichText: true), findsWidgets);
    expect(find.textContaining('/5', findRichText: true), findsOneWidget);
    // One heart icon only.
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('plus opens the shop', (tester) async {
    await _pump(tester, hearts: 3);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('shop stand-in'), findsOneWidget);
  });

  testWidgets('plus still opens the shop when the pool is full', (tester) async {
    // The shop says there is nothing to buy; the button never does nothing.
    await _pump(tester, hearts: GameConstants.maxHearts);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('shop stand-in'), findsOneWidget);
  });
}
