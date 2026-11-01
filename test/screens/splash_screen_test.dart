// The opening splash: it shows the name and the loading line at once, moves the line
// as the game loads, stays up for its minimum, then fades into the app. A failed load
// does not leave the student on the splash.
import 'package:chronoquest/screens/splash/splash_screen.dart';
import 'package:chronoquest/widgets/cq_tile.dart';
import 'package:chronoquest/widgets/loading_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void _noMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows the tile, the name and the line', (tester) async {
    _noMotion(tester);
    final progress = BootProgress();
    addTearDown(progress.dispose);
    await tester
        .pumpWidget(MaterialApp(home: SplashScreen(progress: progress)));
    await tester.pump();

    expect(find.byType(CqTile), findsOneWidget);
    expect(find.byType(LoadingLine), findsOneWidget);
    // The name is dropped in letter by letter.
    for (final letter in 'CHRONOQUEST'.split('').toSet()) {
      expect(find.text(letter), findsWidgets, reason: 'letter $letter');
    }
    expect(find.text('KASAYSAYAN NG PILIPINAS'), findsOneWidget);
    expect(find.textContaining('v1.'), findsOneWidget);
  });

  testWidgets('the line follows how far the game has got, with the chosen hero',
      (tester) async {
    _noMotion(tester);
    final progress = BootProgress();
    addTearDown(progress.dispose);
    await tester
        .pumpWidget(MaterialApp(home: SplashScreen(progress: progress)));
    await tester.pump();
    expect(tester.widget<LoadingLine>(find.byType(LoadingLine)).progress, 0);

    progress.hero.value = 'luna';
    progress.value.value = 0.8;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final line = tester.widget<LoadingLine>(find.byType(LoadingLine));
    expect(line.progress, closeTo(0.8, 0.001));
    expect(line.charId, 'luna');
  });

  testWidgets('stays up for its minimum, then shows the app', (tester) async {
    _noMotion(tester);
    await tester.pumpWidget(BootApp(
      load: (p) async => p.value.value = 0.5,
      app: () => const MaterialApp(home: Scaffold(body: Text('the app'))),
      minimum: const Duration(milliseconds: 600),
    ));
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('the app'), findsNothing);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('the app'), findsNothing,
        reason: 'still inside the minimum');

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 500)); // the fade
    expect(find.text('the app'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('a load that fails still opens the app', (tester) async {
    _noMotion(tester);
    final old = FlutterError.onError;
    final reported = <FlutterErrorDetails>[];
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = old);

    await tester.pumpWidget(BootApp(
      load: (p) async => throw StateError('no storage'),
      app: () => const MaterialApp(home: Scaffold(body: Text('the app'))),
      minimum: const Duration(milliseconds: 200),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('the app'), findsOneWidget);
    expect(reported.single.exception, isA<StateError>());
  });

  testWidgets('fits a short landscape phone without overflow', (tester) async {
    _noMotion(tester);
    await tester.binding.setSurfaceSize(const Size(732, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final progress = BootProgress();
    addTearDown(progress.dispose);
    await tester
        .pumpWidget(MaterialApp(home: SplashScreen(progress: progress)));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
