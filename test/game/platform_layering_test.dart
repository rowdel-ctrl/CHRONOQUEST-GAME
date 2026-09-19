import 'package:chronoquest/game/components/enemy_spawner.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/components/tile_platform_component.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tile platforms', () {
    test('render behind the player, so the player is never painted over', () {
      final platform = TilePlatformComponent(widthInTiles: 3, surfaceY: 0);
      final player = PlayerComponent(characterId: 'rizal');
      expect(platform.priority, lessThan(player.priority));
    });

    test('spawn no higher than the jump can reach, with room to spare', () {
      // Peak height of a jump: v² / (2g).
      const jumpPeak = PlayerComponent.jumpForce *
          PlayerComponent.jumpForce /
          (2 * PlayerComponent.gravity);
      expect(
        EnemySpawner.platformMaxHeight,
        lessThanOrEqualTo(jumpPeak - 15),
      );
    });

    test('spawn height range is valid', () {
      expect(EnemySpawner.platformMinHeight,
          lessThan(EnemySpawner.platformMaxHeight));
    });
  });
}
