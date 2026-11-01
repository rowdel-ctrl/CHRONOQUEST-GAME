// The end of an era: the gold medal, "TAPOS!", the two scores and the gain as round
// chips, the coins, and one button. It says plainly when the scores cannot be shown.
import 'dart:async';

import 'package:chronoquest/models/badge_defs.dart';
import 'package:chronoquest/models/quiz_result.dart';
import 'package:chronoquest/screens/game/era_complete_screen.dart';
import 'package:chronoquest/widgets/era_medal.dart';
import 'package:chronoquest/widgets/new_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

QuizResult _result(String era, String type, int percentage, {int level = 1}) => QuizResult(
      era: era,
      level: level,
      type: type,
      correctAnswersCount: percentage ~/ 10,
      totalQuestions: 10,
      percentage: percentage,
      timeTakenTotal: 60,
      questionSnapshots: const [],
    );

Future<void> _open(
  WidgetTester tester, {
  String eraId = 'spanish',
  int coins = 30,
  Future<List<QuizResult>> Function()? load,
  Size size = const Size(732, 320),
  bool animations = true,
  List<EarnedBadge> badges = const [],
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
    GoRoute(
      path: '/',
      builder: (_, __) => EraCompleteScreen(
        eraId: eraId,
        coins: coins,
        badges: badges,
        loadResults: load ??
            () async => [
                  _result('spanish', 'pre_test', 80, level: 1),
                  _result('spanish', 'pre_test', 90, level: 2),
                  _result('spanish', 'post_test', 95, level: 5),
                  _result('pre-colonial', 'pre_test', 10, level: 1),
                  _result('pre-colonial', 'post_test', 20, level: 10),
                ],
      ),
    ),
    GoRoute(
      path: '/era-selection',
      builder: (_, __) => const Scaffold(body: Text('eras stand-in')),
    ),
  ]);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

String _text(WidgetTester tester, Key chip) => tester
    .widgetList<Text>(find.descendant(of: find.byKey(chip), matching: find.byType(Text)))
    .single
    .data!;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('new badges', () {
    EarnedBadge badge(String id) {
      final f = badgeFamilyOf(id)!;
      return EarnedBadge(f, f.steps.firstWhere((s) => s.id == id));
    }

    testWidgets('a boss medal gets a pop-up once the scores are in, and TULOY closes it', (tester) async {
      await _open(tester, badges: [badge('era:spanish'), badge('perfect:1')]);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(BossBadgeCard.cardKey), findsOneWidget);
      expect(find.text('Natalo mo ang Governor!'), findsOneWidget);
      await tester.tap(find.byKey(BossBadgeCard.goKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(BossBadgeCard.cardKey), findsNothing);
      expect(find.text('TAPOS!'), findsOneWidget, reason: 'the era screen is still there');
    });

    testWidgets('other badges are a strip, not a pop-up', (tester) async {
      await _open(tester, badges: [badge('perfect:1')]);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(BossBadgeCard.cardKey), findsNothing);
      expect(find.byKey(NewBadgeStrip.stripKey), findsOneWidget);
    });

    testWidgets('none earned, none shown', (tester) async {
      await _open(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(BossBadgeCard.cardKey), findsNothing);
      expect(find.byKey(NewBadgeStrip.stripKey), findsNothing);
    });

    testWidgets('a pop-up fits a short landscape phone', (tester) async {
      await _open(tester,
          size: const Size(640, 320),
          badges: [badge('era:spanish'), badge('perfect:1'), badge('stars3:1'), badge('bossclean')]);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('shows the era medal with this era\'s number, TAPOS! and the era name', (tester) async {
    await _open(tester, eraId: 'spanish');

    expect(find.text('TAPOS!'), findsOneWidget);
    expect(find.text('Pananakop ng Espanya'), findsOneWidget);
    expect(tester.widget<EraMedal>(find.byKey(EraCompleteScreen.medalKey)).number, 2);

    await _open(tester, eraId: 'modern');
    expect(tester.widget<EraMedal>(find.byKey(EraCompleteScreen.medalKey)).number, 6);
  });

  testWidgets('the two scores and the gain are round chips with one number each', (tester) async {
    await _open(tester);

    expect(_text(tester, EraCompleteScreen.levelsKey), '85%', reason: 'the average of 80 and 90');
    expect(_text(tester, EraCompleteScreen.bossKey), '95%');
    expect(_text(tester, EraCompleteScreen.gainKey), '+10%', reason: 'the boss, 95, less 85');
  });

  testWidgets('only this era\'s results count', (tester) async {
    await _open(tester, eraId: 'spanish');
    expect(_text(tester, EraCompleteScreen.levelsKey), '85%', reason: 'not dragged down by the other era');
  });

  testWidgets('a boss worse than the levels shows a negative gain, not a made-up plus', (tester) async {
    await _open(tester, load: () async => [
          _result('spanish', 'pre_test', 90),
          _result('spanish', 'post_test', 70),
        ]);
    expect(_text(tester, EraCompleteScreen.gainKey), '-20%');
  });

  testWidgets('shows the coins the boss paid, and no chip when there are none', (tester) async {
    await _open(tester, coins: 30);
    expect(_text(tester, EraCompleteScreen.coinsKey), '+30');

    await _open(tester, coins: 0);
    expect(find.byKey(EraCompleteScreen.coinsKey), findsNothing);
  });

  group('when the scores are not there', () {
    testWidgets('no boss result yet: no chips for them, and it says so', (tester) async {
      await _open(tester, load: () async => [_result('spanish', 'pre_test', 80)]);

      expect(find.byKey(EraCompleteScreen.levelsKey), findsNothing);
      expect(find.byKey(EraCompleteScreen.gainKey), findsNothing);
      expect(find.text('Kulang pa ang data sa scores mo.'), findsOneWidget);
      expect(find.byKey(EraCompleteScreen.goKey), findsOneWidget, reason: 'the student can still go on');
    });

    testWidgets('the server cannot be reached: it says that, with no made-up numbers', (tester) async {
      await _open(tester, load: () async => throw Exception('offline'));

      expect(find.text('Hindi ma-load ang scores mo ngayon.'), findsOneWidget);
      expect(find.byKey(EraCompleteScreen.bossKey), findsNothing);
      expect(find.byKey(EraCompleteScreen.goKey), findsOneWidget);
    });

    testWidgets('a spinner while the results come', (tester) async {
      final wait = Completer<List<QuizResult>>();
      await _open(tester, load: () => wait.future);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      wait.complete([_result('spanish', 'pre_test', 80), _result('spanish', 'post_test', 90)]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(EraCompleteScreen.bossKey), findsOneWidget);
    });
  });

  testWidgets('has few words: no learning-gain essay, no explanations', (tester) async {
    await _open(tester);
    expect(find.textContaining('Natuto'), findsNothing);
    expect(find.textContaining('Napakagaling'), findsNothing);
    expect(find.textContaining('Average sa mga Level'), findsNothing);
    expect(find.text('ERA TAPOS NA!'), findsNothing);
  });

  testWidgets('SUSUNOD goes on to the era list', (tester) async {
    await _open(tester);
    await tester.tap(find.byKey(EraCompleteScreen.goKey));
    await tester.pumpAndSettle();
    expect(find.text('eras stand-in'), findsOneWidget);
  });

  testWidgets('with animations off nothing moves and there is no confetti', (tester) async {
    await _open(tester, animations: false);
    expect(tester.hasRunningAnimations, isFalse);
  });

  for (final size in const [Size(732, 320), Size(640, 360), Size(400, 700)]) {
    testWidgets('fits ${size.width.toInt()}x${size.height.toInt()}, button on screen', (tester) async {
      await _open(tester, size: size);

      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(EraCompleteScreen.goKey));
      expect(find.byKey(EraCompleteScreen.goKey).hitTestable(), findsOneWidget);
    });
  }
}
