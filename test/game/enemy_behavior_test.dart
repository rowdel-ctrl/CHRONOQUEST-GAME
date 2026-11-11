// Walker/Chaser/Heavy behaviour (GAMEPLAY-V2.md Section 5, and the 2026-11-02 changes:
// a walker turns to a student who comes close, the three spirit-type enemies chase,
// and a Heavy flashes and lunges) and the enemyTypeTable each maps to.
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
        final expectedHp = switch (entry.value.behavior) {
          EnemyBehavior.walker => CombatConstants.walkerHp,
          EnemyBehavior.chaser => CombatConstants.chaserHp,
          EnemyBehavior.heavy => CombatConstants.heavyHp,
        };
        expect(entry.value.maxHp, expectedHp,
            reason: '${entry.key} HP does not match its behaviour\'s '
                'CombatConstants value');
      }
    });

    test('has 4 Walkers, 3 Chasers and 3 Heavies', () {
      int count(EnemyBehavior b) =>
          enemyTypeTable.values.where((d) => d.behavior == b).length;

      expect(count(EnemyBehavior.walker), 4);
      expect(count(EnemyBehavior.chaser), 3);
      expect(count(EnemyBehavior.heavy), 3);
    });

    test('the spirit, propaganda and cloud enemies are the chasers', () {
      for (final sprite in ['dark_spirit', 'propaganda', 'misinfo_cloud']) {
        expect(enemyTypeTable[sprite]!.behavior, EnemyBehavior.chaser,
            reason: sprite);
      }
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

  /// Puts the (bare) game's student [dx] units to the right of [enemy]'s middle,
  /// on the same ground.
  void placePlayerBeside(ChronoGame game, EnemyComponent enemy, double dx) {
    final p = game.player;
    p.position = Vector2(
      enemy.position.x + enemy.size.x / 2 + dx - p.size.x / 2,
      enemy.position.y + enemy.size.y - p.size.y,
    );
  }

  group('Walker notices a student', () {
    test('turns to face one who comes close, once', () async {
      final game = _bareGame();
      final enemy = await _mountEnemy(game, 'spanish_soldier');
      placePlayerBeside(game, enemy, -150); // to its left
      enemy.update(1 / 60);
      expect(enemy.patrolDirection, -1);
      // Walking on, it does not keep snapping back to face them every frame.
      for (var i = 0; i < 400; i++) {
        enemy.update(1 / 60);
      }
      expect(enemy.patrolDirection, anyOf(-1, 1));
    });

    test('ignores one far away', () async {
      final game = _bareGame();
      final enemy = await _mountEnemy(game, 'spanish_soldier');
      final start = enemy.patrolDirection;
      placePlayerBeside(game, enemy, -(CombatConstants.walkerNoticeRange + 200));
      enemy.update(1 / 60);
      expect(enemy.patrolDirection, start);
    });
  });

  group('Chaser', () {
    test('walks towards a student who comes close, slower than they walk',
        () async {
      final game = _bareGame();
      final enemy = await _mountEnemy(game, 'dark_spirit');
      placePlayerBeside(game, enemy, -300);
      final before = enemy.position.x;
      for (var i = 0; i < 60; i++) {
        enemy.update(1 / 60);
      }
      expect(enemy.position.x, lessThan(before), reason: 'it came closer');
      expect(before - enemy.position.x,
          closeTo(CombatConstants.chaserSpeed, 3),
          reason: 'one second at chaserSpeed');
      expect(CombatConstants.chaserSpeed, lessThan(250),
          reason: 'a student can outrun it');
      expect(enemy.patrolDirection, -1, reason: 'and faces them');
    });

    test('never goes further than its leash from where it stood', () async {
      final game = _bareGame();
      // blasts: false keeps it a plain chaser; a blast kind stops and fuses at 100.
      final enemy = EnemyComponent(
          eraId: 'spanish', enemyTypeOverride: 'dark_spirit', blasts: false);
      game.world.add(enemy);
      await game.ready();
      final spawn = enemy.position.x;
      placePlayerBeside(game, enemy, -400);
      for (var i = 0; i < 60 * 10; i++) {
        enemy.update(1 / 60);
      }
      expect(spawn - enemy.position.x,
          lessThanOrEqualTo(CombatConstants.chaserLeash + 0.01));
    });

    test('does not chase a student on another level', () async {
      final game = _bareGame();
      final enemy = await _mountEnemy(game, 'dark_spirit');
      placePlayerBeside(game, enemy, -300);
      game.player.position.y -= CombatConstants.sameLevelTolerance + 100;
      final before = enemy.position.x;
      enemy.update(1 / 60);
      // It only paces (at patrolSpeed), it does not run at chaserSpeed.
      expect((enemy.position.x - before).abs(),
          lessThanOrEqualTo(CombatConstants.patrolSpeed / 60 + 0.01));
    });

    test('dies to one hit', () async {
      final game = _bareGame();
      final enemy = await _mountEnemy(game, 'dark_spirit');
      enemy.takeHit();
      expect(enemy.defeated, true);
    });
  });

  group('Heavy lunge', () {
    test('flashes first, then lunges towards the student, then rests', () async {
      final game = _bareGame();
      final enemy = await _mountEnemy(game, 'tank');
      final start = enemy.position.x;
      placePlayerBeside(game, enemy, -200);

      enemy.update(1 / 60);
      expect(enemy.isWindingUp, true, reason: 'the warning comes first');
      expect(enemy.position.x, start, reason: 'and it does not move during it');

      var t = 0.0;
      while (!enemy.isLunging && t < 2) {
        enemy.update(1 / 60);
        t += 1 / 60;
      }
      expect(enemy.isLunging, true);
      expect(t, closeTo(CombatConstants.lungeWindup, 0.1));

      while (enemy.isLunging && t < 3) {
        enemy.update(1 / 60);
        t += 1 / 60;
      }
      expect(start - enemy.position.x, greaterThan(60),
          reason: 'it moved a good way towards the student (to the left)');
      expect(start - enemy.position.x,
          lessThanOrEqualTo(CombatConstants.lungeLeash + 0.01));
      expect(enemy.isLunging, false);
    });

    test('a hit during the wind-up stops it', () async {
      final game = _bareGame();
      final enemy = await _mountEnemy(game, 'tank');
      placePlayerBeside(game, enemy, -200);
      enemy.update(1 / 60);
      expect(enemy.isWindingUp, true);
      enemy.takeHit();
      expect(enemy.isWindingUp, false);
      expect(enemy.defeated, false);
    });

    test('does nothing while the student is far away', () async {
      final game = _bareGame();
      final enemy = await _mountEnemy(game, 'tank');
      placePlayerBeside(game, enemy, -(CombatConstants.lungeTriggerRange + 300));
      for (var i = 0; i < 120; i++) {
        enemy.update(1 / 60);
      }
      expect(enemy.isWindingUp, false);
      expect(enemy.isLunging, false);
    });

    test('goes back to where it stood once the student leaves', () async {
      final game = _bareGame();
      final enemy = await _mountEnemy(game, 'tank');
      final start = enemy.position.x;
      placePlayerBeside(game, enemy, -200);
      for (var i = 0; i < 60 * 3; i++) {
        enemy.update(1 / 60);
      }
      expect(enemy.position.x, isNot(start));
      placePlayerBeside(game, enemy, -2000);
      for (var i = 0; i < 60 * 12; i++) {
        enemy.update(1 / 60);
      }
      expect(enemy.position.x, start);
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
