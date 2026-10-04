// The tutorial is shown in landscape on phones whose height is only 320-412
// logical px. An earlier layout stacked everything vertically and overflowed
// below about 400px, hiding the title and body. These tests step through
// every page at several landscape sizes (and a portrait one) and fail on any
// layout overflow.
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/screens/tutorial/tutorial_screen.dart';
import 'package:chronoquest/widgets/game_ui.dart';
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app() => ProviderScope(
      overrides: [gameProvider.overrideWith((ref) => _QuietGameNotifier())],
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
    '900x412 landscape': Size(900, 412),
    '360x640 portrait': Size(360, 640),
  };

  for (final entry in sizes.entries) {
    testWidgets('no page overflows at ${entry.key}', (tester) async {
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

      expect(pages, greaterThan(1));
    });
  }

  testWidgets('the card and button are not covered by the backdrop scrim',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // The scrim is the first child of the backdrop's Stack, so everything
    // else — card, text, button — paints above it at full brightness.
    final stack = tester.widget<Stack>(
      find
          .descendant(
            of: find.byType(GameBackdrop),
            matching: find.byType(Stack),
          )
          .first,
    );
    expect(stack.children.first, isA<ColoredBox>());
    expect(stack.children.length, 2);
    expect(stack.children.last, isNot(isA<ColoredBox>()));
  });
}
