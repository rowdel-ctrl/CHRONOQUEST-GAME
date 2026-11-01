// A level lost: the hurt hero in red light, "SUBUKAN ULIT!", the hearts left and
// three buttons (ULIT, the shop, back). With no hearts ULIT waits.
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/screens/game/level_failed_screen.dart';
import 'package:chronoquest/widgets/game_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame(int hearts, this._countdown, String hero)
      : super(GameState(
          selectedCharacterId: hero,
          hearts: HeartsState(count: hearts, regenStartMs: null),
        ));

  final Duration? _countdown;

  @override
  bool get canStartLevel => state.hearts.count > 0;

  @override
  Duration? get heartCountdown => _countdown;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(
  WidgetTester tester, {
  int hearts = 3,
  Duration? countdown,
  String hero = 'rizal',
  Size size = const Size(732, 320),
  bool animations = false,
  List<String>? landedOn,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: !animations);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const LevelFailedScreen(eraId: 'spanish', level: 4)),
    GoRoute(
      path: '/game/:eraId/:level',
      builder: (_, state) {
        landedOn?.add('/game/${state.pathParameters['eraId']}/${state.pathParameters['level']}');
        return const Scaffold(body: Text('game stand-in'));
      },
    ),
    GoRoute(
      path: '/shop',
      builder: (_, __) {
        landedOn?.add('/shop');
        return const Scaffold(body: Text('shop stand-in'));
      },
    ),
    GoRoute(
      path: '/level-select/:eraId',
      builder: (_, state) {
        landedOn?.add('/level-select/${state.pathParameters['eraId']}');
        return const Scaffold(body: Text('levels stand-in'));
      },
    ),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [gameProvider.overrideWith((ref) => _FakeGame(hearts, countdown, hero))],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

GameButton _retry(WidgetTester tester) =>
    tester.widget<GameButton>(find.byKey(LevelFailedScreen.retryKey));

String _assetOf(Image i) => (i.image as AssetImage).assetName;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('says SUBUKAN ULIT! and nothing else in words', (tester) async {
    await _open(tester);

    expect(find.text('SUBUKAN ULIT!'), findsOneWidget);
    expect(find.textContaining('Naubos'), findsNothing);
    expect(find.textContaining('Tip'), findsNothing);
    expect(find.textContaining('history'), findsNothing);
    expect(find.textContaining('Wala nang puso'), findsNothing);
  });

  testWidgets('shows the student\'s own hero, hurt', (tester) async {
    await _open(tester, hero: 'luna');
    final hero = tester.widget<Image>(find.byKey(LevelFailedScreen.heroKey));
    expect(_assetOf(hero), 'assets/characters/luna_hurt.png');
  });

  testWidgets('draws the hearts: the full ones first, then the empty ones', (tester) async {
    await _open(tester, hearts: 3);

    final hearts = tester
        .widgetList<Image>(find.descendant(
          of: find.byKey(LevelFailedScreen.heartsKey),
          matching: find.byType(Image),
        ))
        .map(_assetOf)
        .toList();
    expect(hearts.length, GameConstants.maxHearts);
    expect(hearts.take(3).every((a) => a == 'assets/ui/heart_full.png'), isTrue);
    expect(hearts.skip(3).every((a) => a == 'assets/ui/heart_empty.png'), isTrue);
  });

  group('with hearts left', () {
    testWidgets('ULIT is ready, there is no clock, and it starts the level again', (tester) async {
      final landed = <String>[];
      await _open(tester, hearts: 2, landedOn: landed);

      expect(_retry(tester).onPressed, isNotNull);
      expect(find.byKey(LevelFailedScreen.timerKey), findsNothing);

      await tester.tap(find.byKey(LevelFailedScreen.retryKey));
      await tester.pumpAndSettle();
      expect(landed, ['/game/spanish/4']);
    });
  });

  group('with no hearts', () {
    testWidgets('ULIT waits and a small clock says when the next heart comes', (tester) async {
      await _open(tester, hearts: 0, countdown: const Duration(minutes: 12, seconds: 5));

      expect(_retry(tester).onPressed, isNull);
      expect(tester.widget<Text>(find.byKey(LevelFailedScreen.timerKey)).data, '12:05');
    });

    testWidgets('with no clock yet (offline) it says to go online', (tester) async {
      await _open(tester, hearts: 0, countdown: null);

      expect(_retry(tester).onPressed, isNull);
      expect(tester.widget<Text>(find.byKey(LevelFailedScreen.timerKey)).data, 'Mag-online');
    });
  });

  testWidgets('the shop and the way back are icons, and work', (tester) async {
    final landed = <String>[];
    await _open(tester, landedOn: landed);
    expect(find.byTooltip('Tindahan'), findsOneWidget);
    expect(find.byTooltip('Bumalik'), findsOneWidget);
    expect(find.text('TINDAHAN'), findsNothing);
    expect(find.text('BUMALIK'), findsNothing);

    await tester.tap(find.byKey(LevelFailedScreen.shopKey));
    await tester.pumpAndSettle();
    expect(landed, ['/shop']);

    await _open(tester, landedOn: landed);
    await tester.tap(find.byKey(LevelFailedScreen.backKey));
    await tester.pumpAndSettle();
    expect(landed.last, '/level-select/spanish');
  });

  testWidgets('the red light moves, and stands still when the phone removes animations',
      (tester) async {
    await _open(tester, animations: true);
    expect(tester.hasRunningAnimations, isTrue);

    await _open(tester, animations: false);
    expect(tester.hasRunningAnimations, isFalse);
  });

  for (final size in const [Size(732, 320), Size(640, 360), Size(400, 700)]) {
    testWidgets('fits ${size.width.toInt()}x${size.height.toInt()}, all three buttons reachable',
        (tester) async {
      await _open(tester, size: size, hearts: 0, countdown: const Duration(minutes: 29, seconds: 59));

      expect(tester.takeException(), isNull);
      for (final key in [LevelFailedScreen.retryKey, LevelFailedScreen.shopKey, LevelFailedScreen.backKey]) {
        await tester.ensureVisible(find.byKey(key));
        expect(find.byKey(key).hitTestable(), findsOneWidget, reason: '$key');
      }
    });
  }
}
