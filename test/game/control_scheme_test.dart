// The movement controls can be the joystick or a pair of left/right arrow
// buttons (Settings > Kontrol). These cover the input itself (what each scheme
// reports and which components it mounts), that the player moves on it, and
// that the pause menu offers a way into Settings.
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_input.dart';
import 'package:chronoquest/game/game_spawning.dart';
import 'package:chronoquest/game/overlays/pause_overlay.dart';
import 'package:chronoquest/models/control_scheme.dart';

/// A game that builds the real on-screen controls without the audio and
/// character art the full onLoad() needs.
class _InputGame extends ChronoGame {
  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    camera.viewfinder.anchor = Anchor.topLeft;
    player = PlayerComponent(characterId: 'rizal')
      ..size = Vector2(96, 120)
      ..position = Vector2(0, groundY - 120);
    gameInput = GameInput(game: this, scheme: controlScheme);
    gameInput.setup();
    setupSpawning();
  }
}

Future<_InputGame> _mount(WidgetTester tester, ControlScheme scheme) async {
  final game = _InputGame()..controlScheme = scheme;
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 2400,
        height: 1080,
        child: GameWidget(game: game),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  return game;
}

int _buttons(ChronoGame g) =>
    g.camera.viewport.children.whereType<HudButtonComponent>().length;
int _joysticks(ChronoGame g) =>
    g.camera.viewport.children.whereType<JoystickComponent>().length;

ChronoGame _bareGameWithArrows() {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  final player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(96, 120)
    ..position = Vector2(400, game.groundY - 120);
  player.game = game;
  game.player = player;
  game.gameInput = GameInput(game: game, scheme: ControlScheme.arrows);
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ControlScheme', () {
    test('reads its saved name, and falls back to the joystick otherwise', () {
      expect(ControlScheme.fromName('arrows'), ControlScheme.arrows);
      expect(ControlScheme.fromName('joystick'), ControlScheme.joystick);
      expect(ControlScheme.fromName(null), ControlScheme.joystick);
      expect(ControlScheme.fromName('gamepad'), ControlScheme.joystick,
          reason: 'a bad stored value must never leave a student without controls');
    });
  });

  group('arrow input', () {
    test('right, left, both and neither', () {
      final input = _bareGameWithArrows().gameInput;

      expect(input.horizontal, 0);
      input.setRightHeld(true);
      expect(input.horizontal, 1);
      input.setLeftHeld(true);
      expect(input.horizontal, 0, reason: 'holding both cancels out');
      input.setRightHeld(false);
      expect(input.horizontal, -1);
      input.setLeftHeld(false);
      expect(input.horizontal, 0);
    });

    test('the player walks right, left and stands still on arrows', () {
      final game = _bareGameWithArrows();
      final start = game.player.position.x;

      game.gameInput.setRightHeld(true);
      game.player.update(1 / 60);
      expect(game.player.position.x, greaterThan(start));
      expect(game.player.facingRight, isTrue);

      game.gameInput.setRightHeld(false);
      final stopped = game.player.position.x;
      game.player.update(1 / 60);
      expect(game.player.position.x, stopped);

      game.gameInput.setLeftHeld(true);
      game.player.update(1 / 60);
      expect(game.player.position.x, lessThan(stopped));
      expect(game.player.facingRight, isFalse);
    });

    test('an arrow walks at full speed', () {
      final game = _bareGameWithArrows();
      final start = game.player.position.x;
      game.gameInput.setRightHeld(true);
      game.player.update(1 / 60);
      expect(game.player.position.x - start,
          closeTo(PlayerComponent.forwardSpeed / 60, 0.001));
    });
  });

  group('the controls on screen', () {
    testWidgets('joystick scheme: a joystick plus Jump and Attack',
        (tester) async {
      final game = await _mount(tester, ControlScheme.joystick);
      expect(_joysticks(game), 1);
      expect(_buttons(game), 2);
    });

    testWidgets('arrows scheme: two arrows plus Jump and Attack, no joystick',
        (tester) async {
      final game = await _mount(tester, ControlScheme.arrows);
      expect(_joysticks(game), 0);
      expect(_buttons(game), 4);
    });

    testWidgets('switching schemes swaps the movement controls only',
        (tester) async {
      final game = await _mount(tester, ControlScheme.joystick);

      game.gameInput.setScheme(ControlScheme.arrows);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      expect(_joysticks(game), 0);
      expect(_buttons(game), 4);

      game.gameInput.setScheme(ControlScheme.joystick);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      expect(_joysticks(game), 1);
      expect(_buttons(game), 2);
    });

    testWidgets('a held arrow is dropped when the scheme changes',
        (tester) async {
      final game = await _mount(tester, ControlScheme.arrows);
      game.gameInput.setRightHeld(true);
      expect(game.gameInput.horizontal, 1);

      game.gameInput.setScheme(ControlScheme.joystick);
      game.gameInput.setScheme(ControlScheme.arrows);
      expect(game.gameInput.horizontal, 0,
          reason: 'nothing should keep walking after a switch');
    });
  });

  group('pause menu', () {
    Widget app(ChronoGame game, {VoidCallback? onSettings}) => MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/game',
            routes: [
              GoRoute(
                path: '/game',
                builder: (context, state) => Scaffold(
                  body: PauseOverlayWidget(
                    game: game,
                    onQuit: () {},
                    onSettings: onSettings,
                  ),
                ),
              ),
            ],
          ),
        );

    testWidgets('has a Settings button that opens settings', (tester) async {
      var opened = 0;
      await tester.binding.setSurfaceSize(const Size(800, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app(ChronoGame()..pauseEngine(),
          onSettings: () => opened++));

      expect(find.text('ITULOY'), findsOneWidget);
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('UMALIS'), findsOneWidget);

      await tester.tap(find.text('SETTINGS'));
      expect(opened, 1);
    });

    testWidgets('fits a short sideways phone without scrolling away buttons',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(640, 320));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app(ChronoGame()..pauseEngine(), onSettings: () {}));

      for (final label in ['ITULOY', 'SETTINGS', 'UMALIS']) {
        final box = tester.getRect(find.text(label));
        expect(box.bottom, lessThanOrEqualTo(320), reason: '$label is off screen');
        expect(box.top, greaterThanOrEqualTo(0), reason: '$label is off screen');
      }
    });

    testWidgets('without a settings route the button is hidden',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app(ChronoGame()..pauseEngine()));
      expect(find.text('SETTINGS'), findsNothing);
      expect(find.text('UMALIS'), findsOneWidget);
    });
  });
}
