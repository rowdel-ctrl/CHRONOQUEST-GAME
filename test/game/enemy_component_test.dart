// EnemyComponent tests for the camera-follow world-position model
// (see CAMERA_REBUILD_CHECKLIST.md). Enemies used to scroll themselves left
// every frame via `ChronoGame.worldScrollSpeed`; now they're static once
// spawned, and it's the camera moving past them (as the player's worldX
// advances) that creates the on-screen leftward motion.
//
// These tests use a bare, unloaded `ChronoGame` — `HasGameReference.game`
// has an explicit setter "useful in tests" (see flame's
// has_game_reference.dart), which lets EnemyComponent resolve `game`
// without running the real async onLoad() pipeline (audio, API calls,
// full parallax/player asset loading) that real gameplay needs.
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/models/question.dart';

Question _testQuestion() => Question(
      id: 'q1',
      era: 'spanish',
      questionText: 'test',
      options: const [],
      correctAnswer: '',
    );

ChronoGame _bareGame({required double playerWorldX}) {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.images.prefix = 'assets/';
  final player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(64, 80)
    ..position = Vector2(playerWorldX, game.groundY - 80);
  game.player = player;
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnemyComponent — world-position model', () {
    test(
        'stays at a fixed world position once spawned — the camera moving '
        'past it is what creates the on-screen scroll, not any velocity '
        'of its own', () {
      final game = _bareGame(playerWorldX: 0);
      final enemy =
          EnemyComponent(question: _testQuestion(), eraId: 'spanish')
            ..size = Vector2(60, 72)
            ..position = Vector2(500, 100)
            ..game = game;

      final startX = enemy.position.x;
      enemy.update(1 / 60);

      expect(enemy.position.x, startX);
    });

    test('does not despawn while still within or ahead of the camera view',
        () {
      final game = _bareGame(playerWorldX: 0);
      final enemy =
          EnemyComponent(question: _testQuestion(), eraId: 'spanish')
            ..size = Vector2(60, 72)
            ..position = Vector2(game.cameraRightEdgeX + 60, 100)
            ..game = game;

      enemy.update(1 / 60);

      expect(enemy.isRemoving, false);
    });

    test('despawns once the camera has fully passed it', () async {
      final game = _bareGame(playerWorldX: 0);
      final enemy = EnemyComponent(question: _testQuestion(), eraId: 'spanish');
      game.world.add(enemy);
      await game.ready();

      // Place it at a known world position, then advance the player far
      // enough that the camera's left edge has moved past the enemy.
      enemy.position.x = 200;
      game.player.position.x =
          200 + enemy.size.x + GameConstants.playerX + 50;

      // Call the component's own update() directly rather than
      // game.update() — cascading through the full tree while it also
      // mutates (removeFromParent) trips Flame's iterator, and this test
      // only needs to exercise EnemyComponent's despawn check anyway.
      enemy.update(1 / 60);
      await game.ready();

      expect(enemy.parent, isNull);
    });
  });
}
