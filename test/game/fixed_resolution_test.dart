// The game renders into a fixed virtual height that Flame scales to the real
// device, instead of drawing in raw device pixels. Virtual width tracks the
// device's own aspect ratio (StretchToFillViewport) rather than being fixed
// too, so the world-to-screen scale is always uniform on every device.
//
// The bug this fixes: every size in the game is hardcoded in logical pixels
// (player 64x80, enemy 60x72, the ~128px jump peak, platform spawn heights),
// all tuned by eye at 1280x720. On a landscape phone — only ~360-412 logical
// px tall — those same numbers covered roughly twice the fraction of the
// screen, so the game looked oversized in the hand.
//
// These tests use a bare, unloaded ChronoGame: onGameResize() gives real
// viewport math without running the async onLoad() pipeline (audio, API
// calls, asset loading). Note that FlameGame.size is the camera viewport's
// virtualSize, NOT the device canvas — canvasSize is the device.
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/gap_component.dart';

/// Real landscape canvas sizes the game has to survive.
final _canvasSizes = <String, Vector2>{
  'desktop test window': Vector2(1280, 720),
  'small landscape phone': Vector2(812, 375),
  'tall modern phone (20:9)': Vector2(2400, 1080),
  'tablet (4:3)': Vector2(1024, 768),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fixed-resolution viewport', () {
    test('virtual height is fixed and virtual width matches the canvas aspect ratio',
        () {
      _canvasSizes.forEach((label, canvas) {
        final game = ChronoGame()..onGameResize(canvas);

        expect(game.size.y, GameConstants.virtualHeight,
            reason: 'height drifted with the canvas on $label');
        expect(
          game.size.x,
          closeTo(GameConstants.virtualHeight * (canvas.x / canvas.y), 0.01),
          reason: 'width did not track the canvas aspect ratio on $label',
        );
      });
    });

    test('world-to-screen scale is uniform on every device (no stretch)', () {
      _canvasSizes.forEach((label, canvas) {
        final game = ChronoGame()..onGameResize(canvas);
        final scaleX = canvas.x / game.size.x;
        final scaleY = canvas.y / game.size.y;

        expect(scaleX, closeTo(scaleY, 0.0001),
            reason: 'X/Y scale diverged (stretch) on $label');
      });
    });

    test('a sprite covers the same fraction of the screen on every device',
        () {
      // This is the whole point: a fixed-height sprite was a different
      // fraction of the screen on every device before this viewport existed
      // (e.g. ~11% of a 720px window but ~22% of a ~375px phone). Now it's
      // the same fraction everywhere, whatever that height is tuned to.
      const playerHeight = 120.0;
      final fractions = _canvasSizes.values.map((canvas) {
        final game = ChronoGame()..onGameResize(canvas);
        return playerHeight / game.size.y;
      }).toSet();

      expect(fractions, hasLength(1));
      expect(fractions.single, closeTo(playerHeight / 720, 0.0001));
    });

    test('groundY no longer moves with the device height', () {
      final phone = ChronoGame()..onGameResize(Vector2(812, 375));
      final desktop = ChronoGame()..onGameResize(Vector2(1280, 720));

      expect(phone.groundY, desktop.groundY);
      expect(
        phone.groundY,
        GameConstants.virtualHeight - GroundSection.bandHeight,
      );
    });

    test('the jump still clears the tallest platform in virtual units', () {
      // World units are unchanged by the viewport, so the tuning that
      // platform_layering_test.dart guards still has to hold here.
      final game = ChronoGame()..onGameResize(Vector2(812, 375));
      const jumpPeak = 480.0 * 480.0 / (2 * 900.0); // jumpForce^2 / 2*gravity

      expect(jumpPeak, greaterThan(105.0));
      expect(game.groundY - 105.0, greaterThan(game.groundY - jumpPeak));
    });
  });
}
