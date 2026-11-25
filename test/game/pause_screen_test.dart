// The pause screen: one big gold play button, with Settings and leave as small
// round buttons and one word under each.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/overlays/pause_overlay.dart';

Future<ChronoGame> _pump(WidgetTester tester, {Size size = const Size(800, 360), VoidCallback? onSettings, VoidCallback? onRestart}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final game = ChronoGame()..pauseEngine();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: PauseOverlayWidget(game: game, onQuit: () {}, onSettings: onSettings, onRestart: onRestart)),
  ));
  return game;
}

void main() {
  testWidgets('the play button is the big one, with a small button either side', (tester) async {
    await _pump(tester, onSettings: () {});

    Finder face(Key key, double side) => find.descendant(
        of: find.byKey(key),
        matching: find.byWidgetPredicate((w) => w is Container && w.constraints?.maxWidth == side));
    expect(face(PauseOverlayWidget.playKey, 88), findsOneWidget);
    expect(face(PauseOverlayWidget.settingsKey, 54), findsOneWidget);
    expect(face(PauseOverlayWidget.quitKey, 54), findsOneWidget);
    expect(find.byKey(PauseOverlayWidget.quitKey), findsOneWidget);
    expect(tester.getCenter(find.byKey(PauseOverlayWidget.settingsKey)).dx,
        lessThan(tester.getCenter(find.byKey(PauseOverlayWidget.playKey)).dx));
    expect(tester.getCenter(find.byKey(PauseOverlayWidget.quitKey)).dx,
        greaterThan(tester.getCenter(find.byKey(PauseOverlayWidget.playKey)).dx));
  });

  testWidgets('play puts the game back', (tester) async {
    final game = await _pump(tester);
    game.overlays.addEntry('PauseOverlay', (_, __) => const SizedBox());
    game.overlays.add('PauseOverlay');

    await tester.tap(find.byKey(PauseOverlayWidget.playKey));

    expect(game.overlays.isActive('PauseOverlay'), isFalse);
    expect(game.paused, isFalse);
  });

  testWidgets('without a settings route there is no settings button', (tester) async {
    await _pump(tester);
    expect(find.byKey(PauseOverlayWidget.settingsKey), findsNothing);
    expect(find.byKey(PauseOverlayWidget.quitKey), findsOneWidget);
  });

  testWidgets('touching the word under a button works too', (tester) async {
    var opened = 0;
    await _pump(tester, onSettings: () => opened++);
    await tester.tap(find.text('SETTINGS'));
    expect(opened, 1);
  });

  group('Ulitin (start the level again)', () {
    testWidgets('has no button when there is nothing to restart with', (tester) async {
      await _pump(tester);
      expect(find.byKey(PauseOverlayWidget.restartKey), findsNothing);
    });

    testWidgets('sits between play and leave, and asks before it restarts', (tester) async {
      var restarts = 0;
      await _pump(tester, onSettings: () {}, onRestart: () => restarts++);
      final x = tester.getCenter(find.byKey(PauseOverlayWidget.restartKey)).dx;
      expect(x, greaterThan(tester.getCenter(find.byKey(PauseOverlayWidget.playKey)).dx));
      expect(x, lessThan(tester.getCenter(find.byKey(PauseOverlayWidget.quitKey)).dx));
      expect(find.text('ULITIN'), findsOneWidget);

      await tester.tap(find.byKey(PauseOverlayWidget.restartKey));
      await tester.pumpAndSettle();
      expect(find.text('Ulitin ang Level?'), findsOneWidget);
      expect(restarts, 0, reason: 'nothing happens until it is confirmed');

      await tester.tap(find.byKey(const ValueKey('restart-cancel')));
      await tester.pumpAndSettle();
      expect(restarts, 0);
      expect(find.text('Ulitin ang Level?'), findsNothing);
    });

    testWidgets('confirming restarts and takes the pause menu down', (tester) async {
      var restarts = 0;
      final game = await _pump(tester, onRestart: () => restarts++);
      game.overlays.addEntry('PauseOverlay', (_, __) => const SizedBox());
      game.overlays.add('PauseOverlay');

      await tester.tap(find.byKey(PauseOverlayWidget.restartKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('restart-confirm')));
      await tester.pumpAndSettle();

      expect(restarts, 1);
      expect(game.overlays.isActive('PauseOverlay'), isFalse);
      expect(game.paused, isTrue, reason: 'the old level stays stopped while it is torn down');
    });

    for (final size in const [Size(732, 320), Size(640, 320), Size(800, 360)]) {
      testWidgets('all four buttons fit ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await _pump(tester, size: size, onSettings: () {}, onRestart: () {});
        for (final key in [
          PauseOverlayWidget.settingsKey,
          PauseOverlayWidget.playKey,
          PauseOverlayWidget.restartKey,
          PauseOverlayWidget.quitKey,
        ]) {
          final r = tester.getRect(find.byKey(key));
          expect(r.left, greaterThanOrEqualTo(0), reason: '$key');
          expect(r.right, lessThanOrEqualTo(size.width), reason: '$key');
          expect(r.bottom, lessThanOrEqualTo(size.height), reason: '$key');
        }
      });
    }
  });

  for (final size in const [Size(732, 320), Size(640, 320), Size(800, 360)]) {
    testWidgets('fits ${size.width.toInt()}x${size.height.toInt()} without scrolling', (tester) async {
      await _pump(tester, size: size, onSettings: () {});
      for (final key in [PauseOverlayWidget.playKey, PauseOverlayWidget.settingsKey, PauseOverlayWidget.quitKey]) {
        final r = tester.getRect(find.byKey(key));
        expect(r.top, greaterThanOrEqualTo(0));
        expect(r.bottom, lessThanOrEqualTo(size.height));
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(size.width));
      }
    });
  }
}
