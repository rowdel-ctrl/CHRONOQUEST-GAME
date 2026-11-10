// Character select's top corners use the shared menu chips, in the fixed order
// of the menu screens: Leaderboard top left; how to play, Profile and Settings
// top right, with Settings right-most. Profile is new here; it used to be
// reachable only after choosing a character. How to play is a round gold ? with
// the word PAANO. Under the heroes sit the coins and a TINDAHAN button.
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/screens/home/character_selection_screen.dart';
import 'package:chronoquest/widgets/hearts_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame()
      : super(GameState(
            coins: 340,
            hearts: const HeartsState(count: 3, regenStartMs: null)));
  @override
  Duration? get heartCountdown => null;

  @override
  bool isCharacterUnlocked(String characterId) => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(ProviderScope(
    overrides: [gameProvider.overrideWith((ref) => _FakeGame())],
    child: const MaterialApp(home: CharacterSelectionScreen()),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// The screen at '/', with '/tutorial' and '/shop' as stubs that say where we are.
Future<void> _pumpRouted(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const CharacterSelectionScreen()),
    GoRoute(
        path: '/tutorial', builder: (_, __) => const Text('route:tutorial')),
    GoRoute(path: '/shop', builder: (_, __) => const Text('route:shop')),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [gameProvider.overrideWith((ref) => _FakeGame())],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final size in const [Size(732, 320), Size(640, 360)]) {
    testWidgets(
        'chips are in order and tappable at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await _pump(tester, size);
      expect(tester.takeException(), isNull);

      final trophy = tester.getCenter(find.byTooltip('Leaderboard'));
      final book = tester.getCenter(find.byTooltip('Paano Laruin'));
      final profile = tester.getCenter(find.byTooltip('Profile'));
      final settings = tester.getCenter(find.byTooltip('Settings'));

      expect(trophy.dx, lessThan(size.width / 2), reason: 'top left');
      expect(book.dx, lessThan(profile.dx));
      expect(profile.dx, lessThan(settings.dx));
      expect(settings.dx, greaterThan(size.width - 60), reason: 'right-most');
      for (final tip in [
        'Leaderboard',
        'Paano Laruin',
        'Profile',
        'Settings'
      ]) {
        expect(find.byTooltip(tip).hitTestable(), findsOneWidget, reason: tip);
      }
    });
  }

  group('the how-to-play button', () {
    testWidgets(
        'is a round gold ? with the word PAANO, in the same place, and opens the tutorial',
        (tester) async {
      await _pumpRouted(tester, const Size(732, 320));
      expect(find.text('?'), findsOneWidget);
      expect(find.text('PAANO'), findsOneWidget);
      final help =
          tester.getCenter(find.byKey(CharacterSelectionScreen.helpKey));
      expect(help.dx, lessThan(tester.getCenter(find.byTooltip('Profile')).dx));
      expect(
          help.dx, greaterThan(tester.getCenter(find.byType(HeartsPill)).dx));
      final box = tester.getSize(find.byKey(CharacterSelectionScreen.helpKey));
      expect(box.width, greaterThanOrEqualTo(48));
      expect(box.height, greaterThanOrEqualTo(48));

      await tester.tap(find.byKey(CharacterSelectionScreen.helpKey));
      await tester.pumpAndSettle();
      expect(find.text('route:tutorial'), findsOneWidget);
    });
  });

  group('the coins and the shop', () {
    for (final size in const [Size(732, 320), Size(640, 360), Size(400, 700)]) {
      testWidgets(
          'show the wallet and a TINDAHAN button under the heroes at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await _pumpRouted(tester, size);
        expect(tester.takeException(), isNull);
        expect(
          find.descendant(
              of: find.byKey(CharacterSelectionScreen.coinsKey),
              matching: find.text('340')),
          findsOneWidget,
        );
        expect(find.text('TINDAHAN'), findsOneWidget);
        final roster = tester
            .getRect(find.byKey(CharacterSelectionScreen.rosterKey('boy')));
        final pill =
            tester.getRect(find.byKey(CharacterSelectionScreen.coinsKey));
        final shop =
            tester.getRect(find.byKey(CharacterSelectionScreen.shopKey));
        expect(pill.top, greaterThanOrEqualTo(roster.bottom),
            reason: 'under the roster');
        expect(shop.top, greaterThanOrEqualTo(roster.bottom));
        expect(pill.right, lessThanOrEqualTo(shop.left),
            reason: 'pill then button');
        expect(shop.bottom, lessThanOrEqualTo(size.height));
        expect(shop.right, lessThanOrEqualTo(size.width));
      });
    }

    testWidgets('TINDAHAN opens the shop', (tester) async {
      await _pumpRouted(tester, const Size(732, 320));
      await tester.tap(find.byKey(CharacterSelectionScreen.shopKey));
      await tester.pumpAndSettle();
      expect(find.text('route:shop'), findsOneWidget);
    });
  });
}
