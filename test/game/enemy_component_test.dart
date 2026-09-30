// EnemyComponent tests for the camera-follow world-position model
// (see CAMERA_REBUILD_CHECKLIST.md) and despawn behaviour. Patrol movement
// itself (Walker behaviour) is covered by enemy_behavior_test.dart — these
// force a Heavy via `enemyTypeOverride` (a @visibleForTesting seam, since
// eraId alone picks randomly between one Walker and one Heavy sprite —
// see enemy_behavior.dart's table, and EnemyComponent's own doc comment)
// specifically because a Heavy "barely moves" (deliberately zero patrol
// movement this phase), which is what isolates the world-position/despawn
// assertions below from patrol motion.
//
// EnemyComponent's behaviour/HP are resolved in onLoad() (from the sprite
// type chosen there), not the constructor, so — unlike some other bare-game
// tests in this codebase — these mount a real component via
// `game.world.add(enemy); await game.ready();` rather than setting `..game`
// directly and skipping onLoad().
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/player_component.dart';

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
        'a Heavy stays at a fixed world position once spawned — the camera '
        'moving past it is what creates the on-screen scroll, not any '
        'velocity of its own', () async {
      final game = _bareGame(playerWorldX: 0);
      final enemy = EnemyComponent(eraId: 'ww2', enemyTypeOverride: 'tank');
      game.world.add(enemy);
      await game.ready();
      // Set after onLoad() completes — onLoad() itself sets a spawn
      // position, which would otherwise overwrite this once the pending
      // load resolves.
      enemy.position = Vector2(500, 100);

      final startX = enemy.position.x;
      enemy.update(1 / 60);

      expect(enemy.position.x, startX);
    });

    test('does not despawn while still within or ahead of the camera view',
        () async {
      final game = _bareGame(playerWorldX: 0);
      final enemy = EnemyComponent(eraId: 'ww2', enemyTypeOverride: 'tank')
        ..position = Vector2(game.cameraRightEdgeX + 60, 100);
      game.world.add(enemy);
      await game.ready();

      enemy.update(1 / 60);

      expect(enemy.isRemoving, false);
    });

    test('despawns once the camera has fully passed it', () async {
      final game = _bareGame(playerWorldX: 0);
      final enemy = EnemyComponent(eraId: 'ww2', enemyTypeOverride: 'tank');
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
