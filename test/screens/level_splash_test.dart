// The splash over a level while it opens: era, level or BOSS, the student's hero, a
// fact that is true of the era (or the boss's own line), and a tap that skips it once
// the level is ready.
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/screens/splash/level_splash.dart';
import 'package:chronoquest/widgets/loading_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void _noMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Widget _splash(
    {String era = 'pre-colonial',
    int level = 3,
    bool ready = false,
    VoidCallback? onSkip}) {
  return MaterialApp(
    home: Scaffold(
      body: LevelSplash(
          eraId: era,
          level: level,
          charId: 'lapu',
          ready: ready,
          onSkip: onSkip),
    ),
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a level shows the era, the level number and a fact',
      (tester) async {
    _noMotion(tester);
    await tester.pumpWidget(_splash());
    await tester.pump();

    expect(find.text('SINAUNANG PILIPINAS'), findsOneWidget);
    expect(find.text('LEVEL'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(
        find.textContaining('Alam mo ba?', findRichText: true), findsOneWidget);
    expect(find.byType(LoadingLine), findsOneWidget);
  });

  testWidgets('the boss level says BOSS and quotes the boss', (tester) async {
    _noMotion(tester);
    final era = getEraById('pre-colonial');
    await tester.pumpWidget(_splash(level: era.levels.length));
    await tester.pump();

    expect(find.text('BOSS'), findsOneWidget);
    expect(find.text('LEVEL ${era.levels.length}'), findsOneWidget);
    expect(find.textContaining(era.bossDialogue, findRichText: true),
        findsOneWidget);
  });

  test('every level of every era has a fact from its own era', () {
    for (final era in allEras) {
      for (var level = 1; level <= era.levels.length; level++) {
        expect(LevelSplash.factFor(era.id, level), isNotEmpty,
            reason: '${era.id} level $level');
      }
    }
    // Different levels of one era show different facts while the era has them.
    expect(LevelSplash.factFor('pre-colonial', 1),
        isNot(LevelSplash.factFor('pre-colonial', 2)));
  });

  testWidgets('a tap skips it only once the level is ready', (tester) async {
    _noMotion(tester);
    var skips = 0;
    await tester.pumpWidget(_splash(onSkip: () => skips++));
    await tester.pump();
    await tester.tap(find.byType(LevelSplash));
    expect(skips, 0);

    await tester.pumpWidget(_splash(ready: true, onSkip: () => skips++));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<LoadingLine>(find.byType(LoadingLine)).progress, 1);
    await tester.tap(find.byType(LevelSplash));
    expect(skips, 1);
  });

  testWidgets('fits the usual landscape sizes', (tester) async {
    _noMotion(tester);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in const [Size(640, 360), Size(732, 320), Size(800, 360)]) {
      await tester.binding.setSurfaceSize(size);
      for (final level in [1, 10]) {
        await tester.pumpWidget(_splash(level: level));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$size level $level');
      }
    }
  });
}
