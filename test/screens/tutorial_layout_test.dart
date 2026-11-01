// The tutorial is shown in landscape on phones whose height is only 320-412
// logical px. An earlier layout stacked everything vertically and overflowed
// below about 400px, hiding the title and body. These tests step through
// every page at several landscape sizes (and a portrait one) and fail on any
// layout overflow. The pictures loop for ever, so the phone's "remove
// animations" is on, which stands them still.
import 'package:chronoquest/models/control_scheme.dart';
import 'package:chronoquest/providers/control_scheme_provider.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/screens/tutorial/tutorial_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Stands in for GameNotifier, whose constructor starts a Hive write that
/// never completes inside a widget test (see tutorial_screen_test.dart).
class _QuietGameNotifier extends StateNotifier<GameState>
    implements GameNotifier {
  _QuietGameNotifier() : super(GameState());

  @override
  Duration? get heartCountdown => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stands in for the saved choice of movement controls (it reads Hive).
class _Scheme extends StateNotifier<ControlScheme>
    implements ControlSchemeNotifier {
  _Scheme() : super(ControlScheme.joystick);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app() => ProviderScope(
      overrides: [
        gameProvider.overrideWith((ref) => _QuietGameNotifier()),
        controlSchemeProvider.overrideWith((ref) => _Scheme()),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/tutorial',
          routes: [
            GoRoute(
              path: '/tutorial',
              builder: (context, state) => const TutorialScreen(),
            ),
          ],
        ),
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const sizes = {
    '640x360 landscape': Size(640, 360),
    '732x320 short landscape': Size(732, 320),
    '800x360 landscape': Size(800, 360),
    '360x640 portrait': Size(360, 640),
  };

  for (final entry in sizes.entries) {
    testWidgets('no page overflows at ${entry.key}', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await tester.binding.setSurfaceSize(entry.value);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      var pages = 0;
      while (true) {
        pages++;
        expect(tester.takeException(), isNull,
            reason: 'page $pages overflowed at ${entry.key}');
        if (find.byKey(TutorialScreen.doneButtonKey).evaluate().isNotEmpty) {
          break;
        }
        await tester.tap(find.byKey(TutorialScreen.nextButtonKey));
        await tester.pumpAndSettle();
        expect(pages, lessThan(30), reason: 'never reached the last page');
      }

      expect(pages, 6);
    });
  }

  testWidgets('the pictures run with motion on, without errors',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(732, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app());
    // Walk through every page letting each picture play for a while: the
    // timelines reach their floats, hits and the frozen bar.
    for (var page = 0; page < 6; page++) {
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(tester.takeException(), isNull,
          reason: 'page ${page + 1} while playing');
      if (find.byKey(TutorialScreen.doneButtonKey).evaluate().isNotEmpty) break;
      await tester.tap(find.byKey(TutorialScreen.nextButtonKey));
      await tester.pump(const Duration(milliseconds: 500));
    }
  });
}
