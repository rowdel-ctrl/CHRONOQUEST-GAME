// The hero's legs move only while he really moves. Standing still (no pull on the
// joystick, or pushing into a wall) shows the first walk picture, not a run on the
// spot (user report, 2026-11-16).
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_input.dart';

Future<Sprite> _blank() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 1, 1));
  return Sprite(await recorder.endRecording().toImage(1, 1));
}

Future<ChronoGame> _game() async {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.images.prefix = 'assets/';
  final one = await _blank();
  SpriteAnimation anim(int n) => SpriteAnimation.spriteList(
      [for (var i = 0; i < n; i++) one],
      stepTime: 0.1);
  final player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(96, 120)
    ..position = Vector2(400, game.groundY - 120)
    ..walkAnimation = anim(4)
    ..jumpAnim = anim(1)
    ..hurtAnim = anim(1);
  player.animation = player.walkAnimation;
  player.game = game;
  game.player = player;
  final input = GameInput(game: game);
  input.joystick = JoystickComponent(background: CircleComponent(radius: 10));
  game.gameInput = input;
  return game;
}

void _run(ChronoGame game, double seconds) {
  for (var i = 0; i < (seconds * 60).round(); i++) {
    game.player.update(1 / 60);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('standing still keeps the first walk picture', () async {
    final game = await _game();
    _run(game, 1.0);
    expect(game.player.animationTicker!.currentIndex, 0);
    expect(game.player.playing, isFalse);
  });

  test('walking plays the walk pictures', () async {
    final game = await _game();
    game.gameInput.joystick.delta.setValues(10, 0);
    final seen = <int>{};
    for (var i = 0; i < 60; i++) {
      game.player.update(1 / 60);
      seen.add(game.player.animationTicker!.currentIndex);
    }
    expect(seen.length, greaterThan(1), reason: 'the legs cycle while he walks');
  });

  // The game also runs a very short step between the normal ones (seen on a tablet: dt 0.0001
  // after every 0.0167). A gentle push moved the hero under the old fixed limit in that step, which
  // read as "standing still" and reset the legs, so they froze unless the joystick was pulled to
  // the edge (user report, 2026-11-28).
  for (final pull in [1.0, 2.0, 3.0, 5.0, 10.0]) {
    test('a push of $pull/10 still moves the legs when short steps come between the normal ones',
        () async {
      final game = await _game();
      game.gameInput.joystick.delta.setValues(pull, 0);
      final seen = <int>{};
      for (var i = 0; i < 90; i++) {
        game.player.update(1 / 60);
        seen.add(game.player.animationTicker!.currentIndex);
        game.player.update(0.0001);
        seen.add(game.player.animationTicker!.currentIndex);
      }
      expect(seen.length, greaterThan(1), reason: 'the legs cycle at a push of $pull/10');
    });
  }

  test('standing still still shows the first picture when short steps come between the normal ones',
      () async {
    final game = await _game();
    game.gameInput.joystick.delta.setValues(0, 0);
    for (var i = 0; i < 60; i++) {
      game.player.update(1 / 60);
      game.player.update(0.0001);
    }
    expect(game.player.animationTicker!.currentIndex, 0);
    expect(game.player.playing, isFalse);
  });

  test('he stops, the legs go back to the first picture', () async {
    final game = await _game();
    game.gameInput.joystick.delta.setValues(10, 0);
    _run(game, 0.35);
    game.gameInput.joystick.delta.setValues(0, 0);
    _run(game, 0.2);
    expect(game.player.animationTicker!.currentIndex, 0);
    expect(game.player.playing, isFalse);
  });
}
