// Walker/Heavy behaviour (GAMEPLAY-V2.md Section 5) and the enemyTypeTable
// each maps to. Chaser is explicitly skipped this phase — the three
// sprites that would use it run as Walkers instead, already covered by the
// table assertions below (they're plain entries with behavior: walker).
//
// Uses EnemyComponent's `enemyTypeOverride` (@visibleForTesting) to force a
// specific sprite type rather than relying on eraId's random pick between
// one Walker and one Heavy — see enemy_component_test.dart's doc comment
// for why that randomness makes eraId alone insufficient for a
// deterministic test.
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/enemy_behavior.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/player_component.dart';

ChronoGame _bareGame() {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.images.prefix = 'assets/';
  final player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(64, 80)
    ..position = Vector2(0, game.groundY - 80);
  game.player = player;
  return game;
}

Future<EnemyComponent> _mountEnemy(ChronoGame game, String enemyType) async {
  final enemy = EnemyComponent(eraId: 'spanish', enemyTypeOverride: enemyType);
  game.world.add(enemy);
  await game.ready();
  return enemy;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('enemyTypeTable', () {
    test('every key matches CombatConstants HP values', () {
      for (final entry in enemyTypeTable.entries) {
        final expectedHp = entry.value.behavior == EnemyBehavior.walker
            ? CombatConstants.walkerHp
            : CombatConstants.heavyHp;
        expect(entry.value.maxHp, expectedHp,
            reason: '${entry.key} HP does not match its behaviour\'s '
                'CombatConstants value');
      }
    });

    test('has exactly 7 Walkers and 3 Heavies (Section 5\'s table)', () {
      final walkers = enemyTypeTable.values
          .where((d) => d.behavior == EnemyBehavior.walker)
          .length;
      final heavies = enemyTypeTable.values
          .where((d) => d.behavior == EnemyBehavior.heavy)
          .length;

      expect(walkers, 7);
      expect(heavies, 3);
    });

    test('covers every sprite every era can pick', () {
      const eraSprites = [
        'tribal_warrior', 'dark_spirit', // pre-colonial
        'spanish_soldier', 'tax_collector', // spanish
        'american_soldier', 'propaganda', // american
        'japanese_soldier', 'tank', // ww2
        'corruption_figure', 'misinfo_cloud', // modern
      ];
      for (final sprite in eraSprites) {
        expect(enemyTypeTable.containsKey(sprite), true,
            reason: '$sprite is missing from enemyTypeTable');
      }
    });
  });

  group('Walker patrol', () {
    test('moves at patrolSpeed and reverses at patrolRange', () async {
      final game = _bareGame();
      final enemy = await _mountEnemy(game, 'spanish_soldier');
      final spawnX = enemy.position.x;

      final beforeX = enemy.position.x;
      enemy.update(1 / 60);
      final movedBy = enemy.position.x - beforeX;

      expect(movedBy.abs(), closeTo(CombatConstants.patrolSpeed / 60, 0.01),
          reason: 'a Walker should move patrolSpeed worth of distance per '
              'second, not stand still');

      // Advance far enough (many frames) that a full patrol leg completes
      // and the enemy must have turned around at least once.
      final directionsSeen = <double>{};
      var lastX = enemy.position.x;
      for (var i = 0; i < 600; i++) {
        enemy.update(1 / 60);
        directionsSeen.add((enemy.position.x - lastX).sign);
        lastX = enemy.position.x;
        // Never wander further than patrolRange from spawn.
        expect((enemy.position.x - spawnX).abs(),
            lessThanOrEqualTo(CombatConstants.patrolRange + 0.01),
            reason: 'a Walker must not exceed its patrol range');
      }

      expect(directionsSeen.length, 2,
          reason: 'a Walker patrolling back and forth must move both ways');
    });
  });

  group('Walker facing', () {
    test('patrolDirection flips when the Walker turns around', () async {
      // The sprite is drawn from patrolDirection (see EnemyComponent.render),
      // so a direction that never flips is what made enemies look like they
      // were sliding backwards on the return leg.
      final game = _bareGame();
      final enemy = await _mountEnemy(game, 'spanish_soldier');
      final startDirection = enemy.patrolDirection;

      // Walk until the far edge of the patrol range forces a turn.
      var flipped = false;
      for (var i = 0; i < 600 && !flipped; i++) {
        enemy.update(1 / 60);
        if (enemy.patrolDirection != startDirection) flipped = true;
      }

      expect(flipped, true,
          reason: 'a Walker must reverse facing when it reaches its range');
    });

    test('a Heavy never changes facing, since it never walks', () async {
      final game = _bareGame();
      final enemy = await _mountEnemy(game, 'tank');
      final startDirection = enemy.patrolDirection;

      for (var i = 0; i < 600; i++) {
        enemy.update(1 / 60);
      }

      expect(enemy.patrolDirection, startDirection);
    });
  });

  group('Heavy — barely moves', () {
    test('does not move on its own across many frames', () async {
      final game = _bareGame();
      final enemy = await _mountEnemy(game, 'tank');
      final startX = enemy.position.x;

      for (var i = 0; i < 300; i++) {
        enemy.update(1 / 60);
      }

      expect(enemy.position.x, startX,
          reason: 'a Heavy "barely moves" (Section 5) — zero patrol '
              'movement this phase');
    });
  });

  group('HP-to-death', () {
    test('a Walker dies on the first hit', () async {
      final game = _bareGame();
      final enemy = await _mountEnemy(game, 'spanish_soldier');

      enemy.takeHit();

      expect(enemy.defeated, true);
    });

    test('a Heavy survives the first hit and dies on the second', () async {
      final game = _bareGame();
      final enemy = await _mountEnemy(game, 'tank');

      enemy.takeHit();
      expect(enemy.defeated, false,
          reason: 'a Heavy takes 2 hits — the first must not kill it');

      enemy.takeHit();
      expect(enemy.defeated, true);
    });

    test('a defeated enemy ignores further hits', () async {
      final game = _bareGame();
      final enemy = await _mountEnemy(game, 'spanish_soldier');

      enemy.takeHit();
      expect(enemy.defeated, true);

      // Should not throw, and should not somehow re-trigger the death
      // sequence a second time.
      enemy.takeHit();
      expect(enemy.defeated, true);
    });
  });
}
