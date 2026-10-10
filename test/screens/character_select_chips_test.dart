// Character select's top corners use the shared menu chips, in the fixed order
// of the menu screens: Leaderboard top left; how to play, Profile and Settings
// top right, with Settings right-most. Profile is new here; it used to be
// reachable only after choosing a character.
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/screens/home/character_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame()
      : super(GameState(hearts: const HeartsState(count: 3, regenStartMs: null)));
  @override
  Duration? get heartCountdown => null;

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

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final size in const [Size(800, 360), Size(732, 320), Size(640, 360)]) {
    testWidgets('chips are in order and tappable at ${size.width.toInt()}x${size.height.toInt()}',
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
      for (final tip in ['Leaderboard', 'Paano Laruin', 'Profile', 'Settings']) {
        expect(find.byTooltip(tip).hitTestable(), findsOneWidget, reason: tip);
      }
    });
  }
}
