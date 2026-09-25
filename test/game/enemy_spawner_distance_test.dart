// EnemySpawner used to accumulate spawn distance from a compile-time
// constant (`PlayerComponent.forwardSpeed * dt`), which was correct only
// while the player auto-advanced at a fixed rate. Phase 1 makes forward
// speed player-controlled, so that math desyncs from real movement:
// standing still would still "travel", and walking backward over
// already-spawned ground would re-trigger spawns on the way back. This
// covers the fix (GAMEPLAY-V2.md Section 14, Phase 1) — distance is now
// measured from the player's furthest-right worldX, a high-water mark.
//
// `spawner.update()` really does spawn a real EnemyComponent when distance
// crosses the threshold (game.world.add(enemy), same as production code),
// which kicks off that component's real async onLoad() (sprite loading) —
// same situation enemy_component_test.dart documents. So this needs
// TestWidgetsFlutterBinding + images.prefix, and `await game.ready()` after
// any update() that might spawn, or the pending load leaks into whichever
// test runs next.
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/enemy_spawner.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/models/question.dart';

Question _question(String id) => Question(
      id: id,
      era: 'pre-colonial',
      questionText: 'Ano ang pinakamaliit na yunit ng pamayanan?',
      options: const [
        QuestionOption(label: 'A', text: 'Barangay'),
        QuestionOption(label: 'B', text: 'Bayan'),
      ],
      correctAnswer: 'Barangay',
    );

ChronoGame _bareGameWithPlayer() {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.images.prefix = 'assets/';
  final player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(96, 120)
    ..position = Vector2(0, game.groundY - 120);
  game.player = player;
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnemySpawner distance tracking', () {
    test('standing still never accumulates spawn distance', () async {
      final game = _bareGameWithPlayer();
      final spawner = EnemySpawner(
          game: game, questions: [_question('1'), _question('2')]);

      for (var i = 0; i < 300; i++) {
        spawner.update(1 / 60);
      }
      await game.ready();

      expect(spawner.spawnedCount, 0,
          reason: 'no forward progress should mean no spawns');
    });

    test('crossing spawnInterval worth of real forward progress spawns one',
        () async {
      final game = _bareGameWithPlayer();
      final spawner = EnemySpawner(
          game: game, questions: [_question('1'), _question('2')]);

      game.player.position.x = GameConstants.spawnInterval;
      spawner.update(1 / 60);
      await game.ready();

      expect(spawner.spawnedCount, 1);
      expect(spawner.distanceTraveled, 0);
    });

    test('backtracking past already-spawned ground never re-spawns it',
        () async {
      final game = _bareGameWithPlayer();
      final spawner = EnemySpawner(
        game: game,
        questions: [_question('1'), _question('2'), _question('3')],
      );

      game.player.position.x = GameConstants.spawnInterval;
      spawner.update(1 / 60);
      await game.ready();
      expect(spawner.spawnedCount, 1);

      // Walk back to the start, then forward again over the same ground.
      game.player.position.x = 0;
      spawner.update(1 / 60);
      game.player.position.x = GameConstants.spawnInterval;
      spawner.update(1 / 60);
      await game.ready();

      expect(spawner.spawnedCount, 1,
          reason: 'crossing already-covered ground should not re-spawn');
    });

    test('progress beyond the previous best resumes accumulating', () async {
      final game = _bareGameWithPlayer();
      final spawner = EnemySpawner(
        game: game,
        questions: [_question('1'), _question('2')],
      );

      game.player.position.x = GameConstants.spawnInterval;
      spawner.update(1 / 60);
      await game.ready();
      expect(spawner.spawnedCount, 1);

      game.player.position.x = GameConstants.spawnInterval * 2;
      spawner.update(1 / 60);
      await game.ready();
      expect(spawner.spawnedCount, 2);
    });
  });
}
