// The tutorial has to actually let a student page through every step, and
// Skip/Done both have to mark it as seen (via a real Hive write) so it
// doesn't relaunch itself on every visit to character selection.
//
// TutorialScreen calls go_router's context.canPop()/pop()/go(), which throw
// without a real GoRouter ancestor, so it's always wrapped in one here. What
// this file deliberately does NOT assert is which screen is visible after
// Skip/Done: that write is real Hive disk I/O, which needs `runAsync` to
// ever resolve in a widget test (pumpAndSettle's fake clock never lets it
// complete on its own — confirmed by a 10-minute hang without runAsync).
// Under runAsync, though, the Poppins font this screen renders schedules its
// own real background load that rejects (allowRuntimeFetching is false in
// tests, and Poppins isn't bundled) — normally that stays harmlessly
// dangling for the rest of a fake-time test, but runAsync gives it real time
// to actually settle, and its rejection then surfaces as a spurious failure
// unrelated to navigation. Fighting that interaction further wasn't worth
// it: the storage side effect (checked below) is reliable, and the actual
// navigation is verified in a real run per this project's own testing
// convention (see HANDOFF.md's "Definition of perfect").
import 'dart:io';

import 'package:chronoquest/screens/tutorial/tutorial_screen.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

GoRouter _router() => GoRouter(
      initialLocation: '/tutorial',
      routes: [
        GoRoute(
          path: '/character-selection',
          builder: (context, state) =>
              const Scaffold(body: Text('character selection stand-in')),
        ),
        GoRoute(
          path: '/tutorial',
          builder: (context, state) => const TutorialScreen(),
        ),
      ],
    );

Widget _app() => ProviderScope(
      child: MaterialApp.router(routerConfig: _router()),
    );

/// Taps a Skip/Done button and waits for the real Hive write `_finish()`
/// awaits to actually complete. `pumpAndSettle()` alone doesn't wait for it
/// (it only tracks pending frames, not stray unawaited real-world Futures),
/// so this polls the flag it writes under `runAsync` instead.
Future<void> _tapAndAwaitWrite(WidgetTester tester, Key buttonKey) async {
  await tester.runAsync(() async {
    await tester.tap(find.byKey(buttonKey));
    for (var i = 0; i < 200 && !StorageService.hasSeenTutorial(); i++) {
      await Future.delayed(const Duration(milliseconds: 25));
    }
  });
}

void main() {
  final hiveDir =
      Directory.systemTemp.createTempSync('chronoquest_tutorial_test_').path;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    // Plain Hive.init (not StorageService.initHive's Hive.initFlutter) avoids
    // the path_provider platform channel widget tests don't have. A fresh
    // system-temp dir per run means a crashed run never leaves a stale lock
    // file behind for the next one to collide with.
    Hive.init(hiveDir);
    await Hive.openBox('chronoquest');
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      Directory(hiveDir).deleteSync(recursive: true);
    } catch (_) {
      // best-effort cleanup only
    }
  });

  tearDown(() async {
    await StorageService.appBox.clear();
  });

  testWidgets('renders the first step on open', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('ANG IYONG BAYANI'), findsOneWidget);
    expect(find.byKey(TutorialScreen.nextButtonKey), findsOneWidget);
    expect(find.byKey(TutorialScreen.doneButtonKey), findsNothing);
  });

  testWidgets('Next advances through every step to the last', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(TutorialScreen.nextButtonKey));
      await tester.pumpAndSettle();
    }

    expect(find.text('GAMITIN ANG POWER-UP'), findsOneWidget);
    expect(find.byKey(TutorialScreen.doneButtonKey), findsOneWidget);
    expect(find.byKey(TutorialScreen.nextButtonKey), findsNothing);
  });

  testWidgets('Skip marks the tutorial as seen', (tester) async {
    expect(StorageService.hasSeenTutorial(), isFalse);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _tapAndAwaitWrite(tester, TutorialScreen.skipButtonKey);

    expect(StorageService.hasSeenTutorial(), isTrue);
  });

  testWidgets('Done on the last step marks the tutorial as seen',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(TutorialScreen.nextButtonKey));
      await tester.pumpAndSettle();
    }
    await _tapAndAwaitWrite(tester, TutorialScreen.doneButtonKey);

    expect(StorageService.hasSeenTutorial(), isTrue);
  });
}
