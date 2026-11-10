// The level-complete screen: the hero cheers in its win pose, the stars, the
// level's artifacts (lit for a right answer, dark for a miss), what was earned
// and one gold button. It fits a short landscape phone and a tall narrow one.
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/badge_defs.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/screens/game/level_complete_screen.dart';
import 'package:chronoquest/widgets/new_badge.dart';
import 'package:chronoquest/widgets/living_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame(String hero)
      : super(GameState(
            selectedCharacterId: hero,
            hearts: const HeartsState(count: 3, regenStartMs: null)));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _show(
  WidgetTester tester, {
  required Size size,
  String eraId = 'pre-colonial',
  int level = 2,
  int correct = 10,
  int total = 10,
  int coins = 35,
  bool animations = true,
  List<EarnedBadge> badges = const [],
  List<bool> answers = const [],
  String hero = 'boy',
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: !animations);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => LevelCompleteScreen(
        eraId: eraId,
        level: level,
        result: LevelCompleteResult(
            score: 535,
            correct: correct,
            total: total,
            coins: coins,
            badges: badges,
            answers: answers),
      ),
    ),
    GoRoute(
      path: '/level-select/:eraId',
      builder: (_, __) => const Scaffold(body: Text('levels stand-in')),
    ),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [gameProvider.overrideWith((ref) => _FakeGame(hero))],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pump(const Duration(seconds: 2)); // stars and pop-in
}

/// The stars drawn full and empty.
int _filled(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .where((i) =>
        i.image is AssetImage &&
        (i.image as AssetImage).assetName == 'assets/ui/star_full.png')
    .length;

int _empty(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .where((i) =>
        i.image is AssetImage &&
        (i.image as AssetImage).assetName == 'assets/ui/star_empty.png')
    .length;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('new badges', () {
    EarnedBadge badge(String id) {
      final f = badgeFamilyOf(id)!;
      return EarnedBadge(f, f.steps.firstWhere((s) => s.id == id));
    }

    testWidgets('slide in over the screen with the badge and its gift',
        (tester) async {
      await _show(tester,
          size: const Size(732, 320), badges: [badge('perfect:1')]);
      expect(find.byKey(NewBadgeStrip.stripKey), findsOneWidget);
      expect(find.text('Perpekto! · Tanso'), findsOneWidget);
      expect(find.text('+5 coins'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // And the screen is still all there, with its button.
      expect(
          find.byKey(LevelCompleteScreen.goKey).hitTestable(), findsOneWidget);
    });

    testWidgets('are not there when none were earned', (tester) async {
      await _show(tester, size: const Size(732, 320));
      expect(find.byKey(NewBadgeStrip.stripKey), findsNothing);
    });
  });

  group('fits a phone, with the button on screen', () {
    for (final size in const [Size(732, 320), Size(640, 360), Size(400, 700)]) {
      for (final level in [2, 3, 7]) {
        testWidgets(
            'level $level at ${size.width.toInt()}x${size.height.toInt()}',
            (tester) async {
          await _show(tester, size: size, level: level);

          expect(tester.takeException(), isNull);
          final button = tester.getRect(find.byKey(LevelCompleteScreen.goKey));
          expect(button.bottom, lessThanOrEqualTo(size.height));
          expect(button.top, greaterThanOrEqualTo(0));
          expect(find.byKey(LevelCompleteScreen.goKey).hitTestable(),
              findsOneWidget);
        });
      }
    }
  });

  testWidgets(
      'has few words: the title, the score, what was earned and the button',
      (tester) async {
    await _show(tester,
        size: const Size(732, 320), level: 4, correct: 7, total: 8);

    expect(find.text('LEVEL 4 TAPOS!'), findsOneWidget);
    expect(find.text('7/8'), findsOneWidget);
    expect(find.text('SUSUNOD'), findsOneWidget);
    expect(find.textContaining('TAMA'), findsNothing);
    expect(find.textContaining('PUNTOS'), findsNothing);
    expect(find.textContaining('COINS'), findsNothing);
    expect(find.text('Pananakop ng Espanya'), findsNothing,
        reason: 'no era name on this screen');
    expect(find.text('Sinaunang Pilipinas'), findsNothing);
  });

  group('the hero and the artifacts', () {
    String assetOf(Image i) => (i.image as AssetImage).assetName;
    Color? tileColor(WidgetTester tester, int i) => (tester
            .widget<Container>(find.descendant(
                of: find.byKey(LevelCompleteScreen.artifactKey(i)),
                matching: find.byType(Container)))
            .decoration as BoxDecoration)
        .color;

    testWidgets('the hero cheers in its win pose, for whichever hero is chosen',
        (tester) async {
      await _show(tester, size: const Size(732, 320));
      expect(
          tester
              .widgetList<Image>(find.descendant(
                  of: find.byKey(LevelCompleteScreen.heroKey),
                  matching: find.byType(Image)))
              .map(assetOf),
          ['assets/characters/boy_win.png']);

      await tester.pumpWidget(const SizedBox());
      await _show(tester, size: const Size(732, 320), hero: 'girl');
      expect(
          tester
              .widgetList<Image>(find.descendant(
                  of: find.byKey(LevelCompleteScreen.heroKey),
                  matching: find.byType(Image)))
              .map(assetOf),
          ['assets/characters/girl_win.png']);
    });

    testWidgets(
        'ten artifact tiles of the level\'s era, with the count and the label',
        (tester) async {
      await _show(tester,
          size: const Size(732, 320), eraId: 'spanish', correct: 7, total: 10);
      expect(find.text('MGA ARTIFACT NA NAKUHA'), findsOneWidget);
      expect(find.text('7/10'), findsOneWidget);
      for (var i = 0; i < 10; i++) {
        expect(find.byKey(LevelCompleteScreen.artifactKey(i)), findsOneWidget,
            reason: 'artifact $i');
        expect(
            tester
                .widgetList<Image>(find.descendant(
                    of: find.byKey(LevelCompleteScreen.artifactKey(i)),
                    matching: find.byType(Image)))
                .map(assetOf),
            ['assets/collectibles/artifact_spanish_${i + 1}.png']);
      }
      expect(find.byKey(LevelCompleteScreen.artifactKey(10)), findsNothing);
      // Two rows of five.
      expect(
          tester.getTopLeft(find.byKey(LevelCompleteScreen.artifactKey(4))).dy,
          tester.getTopLeft(find.byKey(LevelCompleteScreen.artifactKey(0))).dy);
      expect(
          tester.getTopLeft(find.byKey(LevelCompleteScreen.artifactKey(5))).dy,
          greaterThan(tester
              .getTopLeft(find.byKey(LevelCompleteScreen.artifactKey(0)))
              .dy));
    });

    testWidgets('with only a count, the first N are lit and the rest are dark',
        (tester) async {
      await _show(tester, size: const Size(732, 320), correct: 7, total: 10);
      for (var i = 0; i < 10; i++) {
        expect(tileColor(tester, i),
            i < 7 ? AppColors.surface : isNot(AppColors.surface),
            reason: 'artifact $i');
      }
    });

    testWidgets('with the answers, exactly the right ones are lit',
        (tester) async {
      const right = [
        true,
        true,
        false,
        true,
        true,
        true,
        false,
        true,
        true,
        false
      ];
      await _show(tester,
          size: const Size(732, 320), correct: 7, total: 10, answers: right);
      for (var i = 0; i < 10; i++) {
        expect(tileColor(tester, i) == AppColors.surface, right[i],
            reason: 'artifact $i');
      }
      expect(find.bySemanticsLabel('Artifact 3, hindi nakuha'), findsOneWidget);
      expect(find.bySemanticsLabel('Artifact 1, nakuha'), findsOneWidget);
    });

    testWidgets('a level with fewer questions shows as many tiles as it has',
        (tester) async {
      await _show(tester, size: const Size(732, 320), correct: 7, total: 8);
      expect(find.byKey(LevelCompleteScreen.artifactKey(7)), findsOneWidget);
      expect(find.byKey(LevelCompleteScreen.artifactKey(8)), findsNothing);
      expect(find.text('7/8'), findsOneWidget);
    });
  });

  testWidgets('no score when the total is not a level of artifacts',
      (tester) async {
    await _show(tester, size: const Size(732, 320), correct: 0, total: 0);
    expect(find.byKey(LevelCompleteScreen.scoreKey), findsNothing);
    expect(find.byKey(LevelCompleteScreen.artifactsKey), findsNothing,
        reason: 'no tiles for a level with no questions');
  });

  group('the stars follow the share right', () {
    testWidgets('90% or more: three full stars', (tester) async {
      await _show(tester, size: const Size(732, 320), correct: 9, total: 10);
      // One more full star is the one beside the points.
      expect(_filled(tester), 3 + 1);
      expect(_empty(tester), 0);
    });

    testWidgets('70% to 89%: two full, one empty', (tester) async {
      await _show(tester, size: const Size(732, 320), correct: 7, total: 10);
      expect(_filled(tester), 2 + 1);
      expect(_empty(tester), 1);
    });

    testWidgets('under 70%: one full, two empty', (tester) async {
      await _show(tester, size: const Size(732, 320), correct: 4, total: 10);
      expect(_filled(tester), 1 + 1);
      expect(_empty(tester), 2);
    });
  });

  group('the lantern night behind the stars matches the result', () {
    testWidgets('three stars: the night is behind the result', (tester) async {
      await _show(tester, size: const Size(732, 320), correct: 10, total: 10);
      expect(find.byKey(LevelCompleteScreen.backdropKey), findsOneWidget);
      expect(
          tester
              .widget<LivingBackdrop>(
                  find.byKey(LevelCompleteScreen.backdropKey))
              .color,
          isNotNull);
    });

    testWidgets('two stars: the night is behind the result too',
        (tester) async {
      await _show(tester, size: const Size(732, 320), correct: 7, total: 10);
      expect(find.byKey(LevelCompleteScreen.backdropKey), findsOneWidget);
    });

    testWidgets('one star: no light at all', (tester) async {
      await _show(tester, size: const Size(732, 320), correct: 4, total: 10);
      expect(find.byKey(LevelCompleteScreen.backdropKey), findsNothing);
    });
  });

  testWidgets('the level 3 and level 7 gifts are named, other levels have none',
      (tester) async {
    await _show(tester, size: const Size(732, 320), level: 3);
    expect(find.text('Nakakuha ng 50/50!'), findsOneWidget);

    await _show(tester, size: const Size(732, 320), level: 7);
    expect(find.text('Nakakuha ng Shield!'), findsOneWidget);

    await _show(tester, size: const Size(732, 320), level: 5);
    expect(find.byKey(LevelCompleteScreen.giftKey), findsNothing);
  });

  testWidgets('a narrow screen still lays out, with the gift', (tester) async {
    await _show(tester, size: const Size(400, 700), level: 3);
    expect(tester.takeException(), isNull);
    expect(find.text('SUSUNOD'), findsOneWidget);
    expect(find.text('Nakakuha ng 50/50!'), findsOneWidget);
  });

  testWidgets(
      'shows the points and the coins earned in this attempt as one line',
      (tester) async {
    await _show(tester, size: const Size(732, 320), coins: 35);

    expect(find.byKey(LevelCompleteScreen.coinsKey), findsOneWidget);
    expect(find.text('+35'), findsOneWidget);
    expect(find.text('+535'), findsOneWidget,
        reason: 'the points are still there');
  });

  testWidgets('no coins in the line when none were picked up', (tester) async {
    await _show(tester, size: const Size(732, 320), coins: 0);

    expect(find.byKey(LevelCompleteScreen.coinsKey), findsNothing);
    expect(find.text('+535'), findsOneWidget);
  });

  test('a result made without coins (an old deep link) shows none', () {
    expect(LevelCompleteResult.empty.coins, 0);
  });

  testWidgets('SUSUNOD goes back to the levels of the era', (tester) async {
    await _show(tester, size: const Size(732, 320));
    await tester.tap(find.byKey(LevelCompleteScreen.goKey));
    await tester.pumpAndSettle();
    expect(find.text('levels stand-in'), findsOneWidget);
  });

  testWidgets(
      'with animations off the stars are all there at once and nothing moves',
      (tester) async {
    await _show(tester,
        size: const Size(732, 320), correct: 10, total: 10, animations: false);
    expect(tester.hasRunningAnimations, isFalse);
    expect(_filled(tester), 3 + 1);
  });
}
