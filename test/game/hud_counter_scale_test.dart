// An earlier version of StretchToFillViewport fixed both virtual width and
// height and stretched them non-uniformly to fill non-16:9 screens, which
// rendered the round on-screen controls — joystick ring, knob, and the
// Jump/Attack buttons — as visibly squashed ovals, needing a dedicated
// counter-scale to fix.
//
// The viewport now lets virtual width track each device's own aspect ratio
// instead, so the world-to-screen scale is always uniform and the controls
// render as true circles with no counter-scaling machinery at all. These
// tests confirm that guarantee holds for the real, mounted controls.
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_input.dart';
import 'package:chronoquest/game/game_spawning.dart';

/// Landscape canvases, all wider than 16:9 — the aspect ratios that used to
/// stretch and distort the controls under the old fixed-width viewport.
final _wideCanvases = <String, Vector2>{
  'common modern phone (19.5:9)': Vector2(2340, 1080),
  'tall modern phone (20:9)': Vector2(2400, 1080),
  '21:9 phone': Vector2(2520, 1080),
};

/// ChronoGame without the audio and character art the real onLoad() pulls
/// in — this is about HUD geometry, and the controls are plain shapes.
class _HudGame extends ChronoGame {
  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    camera.viewfinder.anchor = Anchor.topLeft;
    player = PlayerComponent(characterId: 'rizal')
      ..size = Vector2(96, 120)
      ..position = Vector2(0, groundY - 120);
    gameInput = GameInput(game: this);
    gameInput.setup();
    setupSpawning();
  }
}

/// What a component actually renders at: its own scale composed with the
/// viewport's own world-to-screen scale.
Vector2 _renderedScale(PositionComponent component, ChronoGame game) {
  final worldScale = Vector2(
    game.camera.viewport.size.x / game.size.x,
    game.camera.viewport.size.y / game.size.y,
  );
  return Vector2(
    component.scale.x * worldScale.x,
    component.scale.y * worldScale.y,
  );
}

Future<_HudGame> _mountedGame(WidgetTester tester, Vector2 canvas) async {
  final game = _HudGame();
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: canvas.x,
        height: canvas.y,
        child: GameWidget(game: game),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  return game;
}

void main() {
  group('the real controls', () {
    testWidgets('joystick and both buttons render round, not oval, on every wide canvas',
        (tester) async {
      for (final canvas in _wideCanvases.values) {
        final game = await _mountedGame(tester, canvas);

        final controls = <PositionComponent>[
          game.gameInput.joystick,
          ...game.camera.viewport.children.whereType<HudButtonComponent>(),
        ];
        expect(controls, hasLength(3),
            reason: 'expected joystick + 2 buttons');

        for (final control in controls) {
          final rendered = _renderedScale(control, game);
          expect(rendered.x, closeTo(rendered.y, 0.0001),
              reason: '${control.runtimeType} renders distorted');
        }
      }
    });

    testWidgets('controls stay anchored to the real screen edges',
        (tester) async {
      final canvas = _wideCanvases.values.first;
      final game = await _mountedGame(tester, canvas);
      final joystick = game.gameInput.joystick;

      final left = joystick.position.x -
          joystick.anchor.x * joystick.scaledSize.x;
      final bottom = joystick.position.y +
          (1 - joystick.anchor.y) * joystick.scaledSize.y;

      expect(left, greaterThanOrEqualTo(0));
      expect(left, lessThan(game.size.x / 4),
          reason: 'joystick drifted away from the left edge');
      expect(bottom, closeTo(game.size.y - 45, 1.0),
          reason: 'joystick lost its 45-unit bottom margin');
    });

    testWidgets('controls stay round after a resize', (tester) async {
      final game = await _mountedGame(tester, Vector2(1280, 720));
      expect(_renderedScale(game.gameInput.joystick, game).x,
          closeTo(_renderedScale(game.gameInput.joystick, game).y, 0.0001));

      game.onGameResize(_wideCanvases['21:9 phone']!);
      await tester.pump(const Duration(milliseconds: 16));

      final rendered = _renderedScale(game.gameInput.joystick, game);
      expect(rendered.x, closeTo(rendered.y, 0.0001),
          reason: 'controls went stale (stretched) after a resize');
    });
  });
}
