// StretchToFillViewport replaces Flame's own FixedResolutionViewport
// (CameraComponent.withFixedResolution) so the game canvas fills the real
// device screen edge-to-edge — the old viewport preserved the virtual
// resolution's exact 16:9 aspect ratio, uniformly scaled, which pillarboxes
// (black bars on the sides) any device wider than 16:9, i.e. effectively
// every modern phone in landscape.
//
// Virtual *height* must not change (`ChronoGame.size.y`): every world-space
// constant tuned against height (groundY, jump physics, platform heights)
// assumes it is a fixed 720 on every device, regardless of the real canvas —
// that's exactly what fixed_resolution_test.dart already locks in, unchanged
// here. Virtual *width* is expected to track each canvas's own aspect ratio
// (rather than also being fixed) — that's what keeps the world-to-screen
// scale uniform, so nothing stretches non-uniformly the way an earlier,
// fixed-both-dimensions version of this viewport did.
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/chrono_game.dart';

/// Representative landscape canvases, all wider than 16:9 — the case that
/// used to pillarbox under the old fixed-resolution viewport.
final _wideCanvases = <String, Vector2>{
  'common modern phone (19.5:9)': Vector2(2340, 1080),
  'tall modern phone (20:9)': Vector2(2400, 1080),
  '21:9 phone': Vector2(2520, 1080),
};

void main() {
  group('StretchToFillViewport', () {
    test(
        'virtual height is unaffected by the canvas; virtual width tracks its aspect ratio',
        () {
      _wideCanvases.forEach((label, canvas) {
        final game = ChronoGame()..onGameResize(canvas);

        expect(game.size.y, GameConstants.virtualHeight,
            reason: 'world height drifted with the canvas on $label');
        expect(
          game.size.x,
          closeTo(GameConstants.virtualHeight * (canvas.x / canvas.y), 0.01),
          reason: 'world width did not track the canvas aspect ratio on $label',
        );
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

    test('the world-to-screen scale is uniform on every device (no stretch)',
        () {
      _wideCanvases.forEach((label, canvas) {
        final game = ChronoGame()..onGameResize(canvas);
        final scaleX = canvas.x / game.size.x;
        final scaleY = canvas.y / game.size.y;

        expect(scaleX, closeTo(scaleY, 0.0001),
            reason: 'X/Y scale diverged (stretch) on $label');
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

        // The canvas's exact center must map to the (device-matched)
        // virtual size's exact center — confirms the scale is centered
        // correctly on both axes, not skewed toward one corner.
        final center = viewport.globalToLocal(
          Vector2(canvas.x / 2, canvas.y / 2),
        );
        expect(center.x, closeTo(game.size.x / 2, 0.01),
            reason: 'horizontal center drifted on $label');
        expect(center.y, closeTo(game.size.y / 2, 0.01),
            reason: 'vertical center drifted on $label');
      });
    });
  });
}
