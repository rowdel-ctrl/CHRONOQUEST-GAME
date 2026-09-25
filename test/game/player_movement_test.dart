// Phase 1 (GAMEPLAY-V2.md Section 15): the player's horizontal movement is
// now driven by the on-screen joystick instead of a constant auto-advance,
// and the ground/platform contact check that used to live inline in
// PlayerComponent.update() was split out into game_collision.dart. Both are
// covered here the same way scroll_sync_golden_test.dart covers the camera
// math: a bare, unloaded ChronoGame + PlayerComponent, so the movement math
// is checked directly without needing the real onLoad() pipeline (audio,
// API, sprite loading).
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_collision.dart';
import 'package:chronoquest/game/game_input.dart';

ChronoGame _bareGameWithPlayer({double playerWorldX = 400}) {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  final player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(96, 120)
    ..position = Vector2(playerWorldX, game.groundY - 120);
  player.game = game;
  game.player = player;

  // A bare joystick, never mounted — `delta` is a plain public Vector2 field
  // the test can set directly to fake a drag, without simulating a real
  // touch gesture.
  final input = GameInput(game: game);
  input.joystick = JoystickComponent(
    background: CircleComponent(radius: 10),
  );
  game.gameInput = input;

  return game;
}

void main() {
  group('Joystick-driven horizontal movement', () {
    test('pushing right moves the player right and faces right', () {
      final game = _bareGameWithPlayer();
      game.player.facingRight = false; // start facing the "wrong" way
      final startX = game.player.position.x;

      game.gameInput.joystick.delta.setValues(10, 0); // full right
      game.player.update(1 / 60);

      expect(game.player.position.x, greaterThan(startX));
      expect(game.player.facingRight, isTrue);
    });

    test('pushing left moves the player left and faces left', () {
      final game = _bareGameWithPlayer();
      final startX = game.player.position.x;

      game.gameInput.joystick.delta.setValues(-10, 0); // full left
      game.player.update(1 / 60);

      expect(game.player.position.x, lessThan(startX));
      expect(game.player.facingRight, isFalse);
    });

    test('a centered joystick leaves horizontal position unchanged', () {
      final game = _bareGameWithPlayer();
      final startX = game.player.position.x;

      game.gameInput.joystick.delta.setValues(0, 0);
      game.player.update(1 / 60);

      expect(game.player.position.x, startX);
    });

    test('the player cannot walk left of the level start', () {
      final game = _bareGameWithPlayer(playerWorldX: 20);

      game.gameInput.joystick.delta.setValues(-10, 0); // full left
      for (var i = 0; i < 10; i++) {
        game.player.update(1 / 60);
      }

      expect(game.player.position.x, 0);
    });
  });

  group('Ground contact resolution (game_collision.dart)', () {
    test('snaps onto a ground section the player is standing on', () {
      final game = _bareGameWithPlayer();
      final section = GroundSection(
        sectionWidth: 1000,
        sectionPosition: Vector2(0, 500),
      )..size = Vector2(1000, 60);
      game.groundSections.add(section);

      game.player.position =
          Vector2(400, 500 - game.player.size.y + 5); // feet just below
      game.player.velocityY = 50;

      final onGround = game.player.resolveGroundContact();

      expect(onGround, isTrue);
      expect(game.player.position.y, 500 - game.player.size.y);
      expect(game.player.velocityY, 0);
    });

    test('reports no contact with nothing underfoot', () {
      final game = _bareGameWithPlayer();
      game.player.position = Vector2(400, 100);

      expect(game.player.resolveGroundContact(), isFalse);
    });
  });
}
