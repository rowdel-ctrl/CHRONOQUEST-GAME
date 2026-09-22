// The player reacts visibly to both quiz outcomes, not just the bad one.
//
// A wrong answer has always routed through ChronoGame.loseLife(), which calls
// player.triggerHurt(). A correct answer awarded score and defeated the enemy
// but left the player running as if nothing had happened, which is what the
// adviser's "hit animation on correct answer" note was about.
//
// There's no dedicated cheer art for any character (assets/characters/ has
// only _walk_1-4, _jump and _hurt per character), so triggerCheer() reuses the
// already-loaded jump pose. That makes the distinction invisible to a
// screenshot — a cheering player and a jumping player render the same frame —
// so it's asserted here instead, where the animation the player was actually
// switched to can be checked directly.
//
// Uses a bare, unloaded ChronoGame like the other tests in this directory
// (see enemy_component_test.dart's header): the real onLoad() pipeline pulls
// audio, API calls and sprite loading that these assertions don't need, so the
// two animations triggerCheer() switches between are assigned directly.
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/quiz_handler.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/models/question.dart';

const _correct = 'Barangay';

Question _question() => Question(
      id: 'q1',
      era: 'pre-colonial',
      questionText: 'Ano ang pinakamaliit na yunit ng pamayanan?',
      options: const [
        QuestionOption(label: 'A', text: _correct),
        QuestionOption(label: 'B', text: 'Bayan'),
      ],
      correctAnswer: _correct,
    );

/// A distinct single-frame animation per call, so `same()` comparisons below
/// actually distinguish walk from jump from hurt. Built from a 1x1 recorded
/// image rather than a real asset: SpriteAnimation asserts on an empty frame
/// list, but nothing here cares what the frame looks like.
Future<SpriteAnimation> _blankAnim() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 1, 1));
  final image = await recorder.endRecording().toImage(1, 1);
  return SpriteAnimation.spriteList([Sprite(image)], stepTime: 1.0);
}

Future<ChronoGame> _bareGame() async {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.images.prefix = 'assets/';

  final player = PlayerComponent(characterId: 'lapu')
    ..size = Vector2(96, 120)
    ..position = Vector2(0, game.groundY - 120)
    ..walkAnimation = await _blankAnim()
    ..jumpAnim = await _blankAnim()
    ..hurtAnim = await _blankAnim();
  player.animation = player.walkAnimation;
  // The wrong-answer case goes through loseLife() -> triggerHurt(), which
  // reaches for game.audioService and so needs a resolvable game reference.
  // (triggerCheer() deliberately touches no such thing.)
  player.game = game;

  game.player = player;
  game.currentQuestion = _question();
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Answering a question changes what the player is doing', () {
    test('a correct answer switches the player off the walk cycle', () async {
      final game = await _bareGame();

      game.handleAnswer(_correct);

      expect(game.player.animation, same(game.player.jumpAnim),
          reason: 'a correct answer should play the cheer pose');
      expect(game.player.animation, isNot(same(game.player.walkAnimation)));
    });

    test('a correct answer still awards score', () async {
      final game = await _bareGame();

      game.handleAnswer(_correct);

      expect(game.score, greaterThan(0));
    });

    test('a wrong answer plays the hurt pose, not the cheer', () async {
      final game = await _bareGame();

      game.handleAnswer('Bayan');

      expect(game.player.animation, same(game.player.hurtAnim));
      expect(game.player.animation, isNot(same(game.player.jumpAnim)));
    });

    test('cheering never overrides an in-progress hurt reaction', () async {
      final game = await _bareGame();
      game.player.isHurt = true;
      game.player.animation = game.player.hurtAnim;

      game.player.triggerCheer();

      expect(game.player.animation, same(game.player.hurtAnim),
          reason: 'triggerCheer() bails out while isHurt is set');
    });
  });
}
