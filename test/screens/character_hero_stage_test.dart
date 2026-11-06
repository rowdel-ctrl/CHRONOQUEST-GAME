// Pick your hero: one big hero with light in its own colour, a short name, one
// button, and a row of all seven to tap or swipe between.
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/screens/home/character_selection_screen.dart';
import 'package:chronoquest/widgets/living_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame({String selected = 'boy'})
      : super(GameState(
          selectedCharacterId: selected,
          hearts: const HeartsState(count: 3, regenStartMs: null),
        ));

  final chosen = <String>[];

  @override
  Duration? get heartCountdown => null;

  @override
  void refreshHearts() {}

  @override
  bool isCharacterUnlocked(String id) =>
      allCharacters.firstWhere((c) => c.id == id).unlockCost == 0;

  @override
  void selectCharacter(String id) => chosen.add(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

late _FakeGame _game;

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(732, 320),
  String selected = 'boy',
  bool animations = false,
  List<String>? landedOn,
}) async {
  _game = _FakeGame(selected: selected);
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
    GoRoute(path: '/', builder: (_, __) => const CharacterSelectionScreen()),
    GoRoute(
      path: '/era-selection',
      builder: (_, __) {
        landedOn?.add('/era-selection');
        return const Scaffold(body: Text('eras stand-in'));
      },
    ),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [gameProvider.overrideWith((ref) => _game)],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

String _name(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(CharacterSelectionScreen.nameKey)).data!;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('the arrows', () {
    testWidgets('there is one each side of the hero, 48 to hit',
        (tester) async {
      await _pump(tester);
      for (final key in [
        CharacterSelectionScreen.prevKey,
        CharacterSelectionScreen.nextKey
      ]) {
        expect(find.byKey(key), findsOneWidget);
        final size = tester.getSize(find.byKey(key));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      expect(
          tester.getCenter(find.byKey(CharacterSelectionScreen.prevKey)).dx,
          lessThan(tester
              .getCenter(find.byKey(CharacterSelectionScreen.nextKey))
              .dx));
    });

    testWidgets(
        'the right arrow shows the next hero and the left one the one before',
        (tester) async {
      await _pump(tester, selected: 'rizal'); // the fourth of seven
      await tester.tap(find.byKey(CharacterSelectionScreen.nextKey));
      await tester.pump();
      expect(_name(tester), 'Luna');

      await tester.tap(find.byKey(CharacterSelectionScreen.prevKey));
      await tester.pump();
      await tester.tap(find.byKey(CharacterSelectionScreen.prevKey));
      await tester.pump();
      expect(_name(tester), 'Lapu-Lapu');
    });

    testWidgets('an arrow with nowhere to go is dim and does nothing',
        (tester) async {
      await _pump(tester, selected: 'boy');
      Opacity dim(Key key) => tester.widget<Opacity>(
          find.descendant(of: find.byKey(key), matching: find.byType(Opacity)));
      expect(dim(CharacterSelectionScreen.prevKey).opacity, lessThan(0.5));
      expect(dim(CharacterSelectionScreen.nextKey).opacity, 1);

      await tester.tap(find.byKey(CharacterSelectionScreen.prevKey));
      await tester.pump();
      expect(_name(tester), 'Lalaki');
    });

    testWidgets('and the right one is dim on the last hero', (tester) async {
      await _pump(tester, selected: 'delpilar');
      Opacity dim(Key key) => tester.widget<Opacity>(
          find.descendant(of: find.byKey(key), matching: find.byType(Opacity)));
      expect(dim(CharacterSelectionScreen.nextKey).opacity, lessThan(0.5));
      expect(dim(CharacterSelectionScreen.prevKey).opacity, 1);
    });

    testWidgets('they nudge sideways when the phone allows motion',
        (tester) async {
      await _pump(tester, animations: true);
      double x() => tester
          .getTopLeft(find.byKey(CharacterSelectionScreen.nextKey).first)
          .dx;
      final glyph = find.descendant(
          of: find.byKey(CharacterSelectionScreen.nextKey),
          matching: find.byType(Container));
      final before = tester.getTopLeft(glyph.first).dx;
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.getTopLeft(glyph.first).dx, isNot(before),
          reason: 'the arrow moved');
      expect(x(), isNotNull);
    });

    testWidgets('they stand still when the phone removes animations',
        (tester) async {
      await _pump(tester, animations: false);
      final still = find.descendant(
          of: find.byKey(CharacterSelectionScreen.nextKey),
          matching: find.byType(Container));
      final a = tester.getTopLeft(still.first).dx;
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.getTopLeft(still.first).dx, a);
    });

    testWidgets(
        'the hero walks in from the left the first time, then stands in place',
        (tester) async {
      CharacterSelectionScreen.resetOpening();
      await _pump(tester, animations: true); // about 300 ms in
      final hero = find.byKey(const ValueKey('hero_boy'));
      final early = tester.getCenter(hero).dx;
      await tester.pump(const Duration(milliseconds: 2400));
      final rest = tester.getCenter(hero).dx;
      expect(early, lessThan(rest - 40),
          reason: 'it was still on its way in from the left');
      await tester.pump(const Duration(seconds: 1));
      expect((tester.getCenter(hero).dx - rest).abs(), lessThan(1),
          reason: 'and then it stays put');
    });

    testWidgets('a later visit only pops the hero in, where it stands',
        (tester) async {
      CharacterSelectionScreen.resetOpening();
      await _pump(tester, animations: true);
      await tester.pump(const Duration(milliseconds: 2500));
      // The screen is opened again in the same run of the game.
      await _pump(tester, animations: true);
      final hero = find.byKey(const ValueKey('hero_boy'));
      final early = tester.getCenter(hero).dx;
      await tester.pump(const Duration(milliseconds: 2500));
      expect((tester.getCenter(hero).dx - early).abs(), lessThan(2));
    });
  });

  testWidgets('starts on the hero the student chose last time', (tester) async {
    await _pump(tester, selected: 'bonifacio');
    expect(_name(tester), 'Bonifacio');
  });

  testWidgets('shows the short name, big, and nothing about the era',
      (tester) async {
    await _pump(tester, selected: 'rizal');
    expect(_name(tester), 'Rizal');
    expect(find.text('Jose Rizal'), findsNothing);
    expect(find.text('Batang Lalaki'), findsNothing);
    for (final c in allCharacters) {
      expect(find.text(c.era), findsNothing);
      expect(find.text(c.description), findsNothing);
    }
    expect(find.text('PILIIN ANG'), findsNothing);
  });

  testWidgets('every hero has a tile, 48 wide and at least 48 tall to hit',
      (tester) async {
    await _pump(tester);
    for (final c in allCharacters) {
      final tile = find.byKey(CharacterSelectionScreen.rosterKey(c.id));
      expect(tile, findsOneWidget, reason: c.id);
      final size = tester.getSize(tile);
      expect(size.width, greaterThanOrEqualTo(48), reason: c.id);
      expect(size.height, greaterThanOrEqualTo(48), reason: c.id);
    }
  });

  testWidgets('tapping a tile shows that hero', (tester) async {
    await _pump(tester);

    for (final c in allCharacters) {
      await tester.tap(find.byKey(CharacterSelectionScreen.rosterKey(c.id)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_name(tester), c.shortName, reason: c.id);
    }
  });

  testWidgets(
      'a hero that costs coins shows its price and a lock; a free one does not',
      (tester) async {
    await _pump(tester);
    expect(find.byKey(CharacterSelectionScreen.priceKey), findsNothing);

    final paid = allCharacters.firstWhere((c) => c.unlockCost > 0);
    await tester.tap(find.byKey(CharacterSelectionScreen.rosterKey(paid.id)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
        tester.widget<Text>(find.byKey(CharacterSelectionScreen.priceKey)).data,
        '${paid.unlockCost}');
    expect(find.byKey(CharacterSelectionScreen.unlockKey), findsOneWidget);

    await tester.tap(find.byKey(CharacterSelectionScreen.rosterKey('girl')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(CharacterSelectionScreen.priceKey), findsNothing);
  });

  testWidgets(
      'a swipe on the hero goes to the next one, and back, and stops at the ends',
      (tester) async {
    await _pump(tester, selected: 'girl');
    final hero = find.byKey(const ValueKey('hero_girl'));
    expect(_name(tester), 'Babae');

    await tester.fling(hero, const Offset(-300, 0), 1500);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_name(tester), 'Lapu-Lapu');

    await tester.fling(find.byKey(const ValueKey('hero_lapu')),
        const Offset(300, 0), 1500);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_name(tester), 'Babae');

    await tester.fling(find.byKey(const ValueKey('hero_girl')),
        const Offset(300, 0), 1500);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_name(tester), 'Lalaki');

    await tester.fling(find.byKey(const ValueKey('hero_boy')),
        const Offset(300, 0), 1500);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_name(tester), 'Lalaki', reason: 'nothing before the first');
  });

  testWidgets('PILIIN chooses the hero and goes on to the eras',
      (tester) async {
    final landed = <String>[];
    await _pump(tester, landedOn: landed);
    await tester.tap(find.byKey(CharacterSelectionScreen.rosterKey('girl')));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(CharacterSelectionScreen.chooseKey));
    await tester.pump(const Duration(milliseconds: 300));

    expect(_game.chosen, ['girl']);
    expect(landed, ['/era-selection']);
  });

  testWidgets('the light behind the hero takes the hero\'s own colour',
      (tester) async {
    await _pump(tester);
    expect(characterColor('boy'), isNot(characterColor('luna')));
    expect(find.byKey(const ValueKey('backdrop_boy')), findsOneWidget);

    await tester.tap(find.byKey(CharacterSelectionScreen.rosterKey('luna')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('backdrop_luna')), findsOneWidget);
    expect(tester.widget<LivingBackdrop>(find.byType(LivingBackdrop)).color,
        characterColor('luna'));
  });

  test('every hero has its own colour, not the default gold', () {
    final colors = allCharacters.map((c) => characterColor(c.id)).toSet();
    expect(colors.length, allCharacters.length);
    expect(colors.contains(AppColors.accent), isFalse);
  });

  testWidgets('moves when animations are on', (tester) async {
    await _pump(tester, animations: true);
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('is still when the phone removes animations', (tester) async {
    await _pump(tester);
    expect(tester.hasRunningAnimations, isFalse);
  });

  for (final size in const [Size(732, 320), Size(640, 360), Size(400, 700), Size(320, 640)]) {
    testWidgets('fits ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await _pump(tester, size: size, animations: true);
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.byKey(CharacterSelectionScreen.chooseKey).hitTestable(),
          findsOneWidget);
      for (final c in allCharacters) {
        final r = tester
            .getRect(find.byKey(CharacterSelectionScreen.rosterKey(c.id)));
        expect(r.right, lessThanOrEqualTo(size.width), reason: c.id);
        expect(r.bottom, lessThanOrEqualTo(size.height), reason: c.id);
      }
      // The locked hero's price too.
      await tester.tap(find.byKey(CharacterSelectionScreen.rosterKey('luna')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.byKey(CharacterSelectionScreen.unlockKey).hitTestable(),
          findsOneWidget);
    });
  }
}
