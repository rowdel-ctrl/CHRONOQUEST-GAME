// StretchToFillViewport replaces Flame's own FixedResolutionViewport
// (CameraComponent.withFixedResolution) so the game canvas fills the real
// device screen edge-to-edge — the old viewport preserved the virtual
// resolution's exact 16:9 aspect ratio, uniformly scaled, which pillarboxes
// (black bars on the sides) any device wider than 16:9, i.e. effectively
// every modern phone in landscape.
//
// The one thing that must not change is `ChronoGame.size` (== the camera
// viewport's `virtualSize`): every world-space constant (groundY, jump
// physics, platform heights, HUD margins) is tuned against that being a
// fixed 1280x720 on every device, regardless of the real canvas — that's
// exactly what fixed_resolution_test.dart already locks in, unchanged here.
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/chrono_game.dart';

/// Representative landscape canvases, all wider than the virtual 16:9 —
/// the case that used to pillarbox.
final _wideCanvases = <String, Vector2>{
  'common modern phone (19.5:9)': Vector2(2340, 1080),
  'tall modern phone (20:9)': Vector2(2400, 1080),
  '21:9 phone': Vector2(2520, 1080),
};

void main() {
  group('StretchToFillViewport', () {
    test('virtual resolution (world space) is unaffected on every device',
        () {
      _wideCanvases.forEach((label, canvas) {
        final game = ChronoGame()..onGameResize(canvas);

        expect(game.size.x, GameConstants.virtualWidth,
            reason: 'world width drifted with the canvas on $label');
        expect(game.size.y, GameConstants.virtualHeight,
            reason: 'world height drifted with the canvas on $label');
      });
    });

    test('the viewport fills the canvas exactly — no pillarbox/letterbox',
        () {
      _wideCanvases.forEach((label, canvas) {
        final game = ChronoGame()..onGameResize(canvas);

        expect(game.camera.viewport.size, canvas,
            reason: 'viewport left black bars on $label');
        expect(game.camera.viewport.position, Vector2.zero(),
            reason: 'viewport was offset instead of filling from the '
                'top-left on $label');
      });
    });

    test('groundY and jump-reachability math are unaffected by the canvas',
        () {
      // Same invariant fixed_resolution_test.dart checks for the old
      // viewport — must still hold with this one.
      final narrow = ChronoGame()..onGameResize(Vector2(812, 375));
      final wide = ChronoGame()..onGameResize(_wideCanvases.values.first);

      expect(narrow.groundY, wide.groundY);
    });

    test('a touch maps to the same world point it visually lands on, '
        'round-tripped through the viewport transform', () {
      _wideCanvases.forEach((label, canvas) {
        final game = ChronoGame()..onGameResize(canvas);
        final viewport = game.camera.viewport;

        // A handful of points across the real screen, including the exact
        // corners a HUD button margin would resolve against.
        final screenPoints = [
          Vector2.zero(),
          canvas,
          Vector2(canvas.x, 0),
          Vector2(0, canvas.y),
          Vector2(canvas.x / 2, canvas.y / 2),
        ];

        for (final screenPoint in screenPoints) {
          final worldPoint = viewport.globalToLocal(screenPoint);
          final roundTripped = viewport.localToGlobal(worldPoint);

          expect(roundTripped.x, closeTo(screenPoint.x, 0.01),
              reason: 'x round-trip drifted on $label at $screenPoint');
          expect(roundTripped.y, closeTo(screenPoint.y, 0.01),
              reason: 'y round-trip drifted on $label at $screenPoint');
        }

        // The canvas's exact center must map to the virtual resolution's
        // exact center — confirms the non-uniform scale is centered
        // correctly on both axes, not skewed toward one corner.
        final center = viewport.globalToLocal(
          Vector2(canvas.x / 2, canvas.y / 2),
        );
        expect(center.x, closeTo(GameConstants.virtualWidth / 2, 0.01),
            reason: 'horizontal center drifted on $label');
        expect(center.y, closeTo(GameConstants.virtualHeight / 2, 0.01),
            reason: 'vertical center drifted on $label');
      });
    });
  });
}
