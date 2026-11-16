// The underground cave's maps (cave/cave_layout.dart) and where the pipe goes in a
// level (cave/cave_plan.dart). Every cave of every pipe level has to be walkable
// by a student with the jump the game gives, and every pipe level has to have a
// safe place for its pipe.
import 'dart:io';

import 'package:chronoquest/core/cave_constants.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/cave/cave_layout.dart';
import 'package:chronoquest/game/cave/cave_plan.dart';
import 'package:chronoquest/game/level_loader.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every (era id, level) that has a pipe.
Iterable<(String, int)> get _pipeLevels sync* {
  for (final e in CaveConstants.pipeLevels.entries) {
    for (final l in e.value) {
      yield (e.key, l);
    }
  }
}

void main() {
  group('which levels have a pipe', () {
    test('at least half of each era\'s ordinary levels, never level 1, never a boss', () {
      for (final era in allEras) {
        final ordinary = era.levels.length - 1; // the last one is the boss room
        final set = CaveConstants.pipeLevels[era.id]!;
        expect(set.length * 2, greaterThanOrEqualTo(ordinary),
            reason: '${era.id}: ${set.length} of $ordinary');
        expect(set.contains(1), isFalse, reason: era.id);
        expect(set.every((l) => l >= 2 && l <= ordinary), isTrue,
            reason: '${era.id} has a pipe in a level that does not exist or in the boss room');
      }
    });
  });

  group('the cave maps', () {
    test('there are as many as there are pipe levels', () {
      expect(_pipeLevels.length, greaterThanOrEqualTo(18));
    });

    for (final (era, level) in _pipeLevels) {
      test('$era $level can be walked', () {
        final c = CaveLayout.forLevel(era, level);

        // The pieces every cave has.
        expect(c.pits, isNotEmpty, reason: 'one pit at least');
        expect(c.platforms, isNotEmpty, reason: 'one slab at least');
        expect(c.enemies.length, greaterThanOrEqualTo(5));
        expect(c.coins.length, greaterThanOrEqualTo(25));

        // A pit the jump can clear, with room to take off and to land.
        for (final p in c.pits) {
          expect(p.x1 - p.x0, lessThanOrEqualTo(CaveConstants.maxPitWidth));
        }
        for (var i = 0; i < c.floor.length; i++) {
          expect(c.floor[i].x1 - c.floor[i].x0, greaterThan(300),
              reason: 'floor stretch $i is too short to take off or land');
        }

        // Slabs the jump can reach.
        for (final p in c.platforms) {
          final rise = CaveLayout.floorY - p.surfaceY;
          expect(rise, inInclusiveRange(CaveConstants.minPlatformRise, CaveConstants.maxPlatformRise));
          expect(c.floorHolds(p.x, p.endX), isTrue,
              reason: 'a slab over a pit could not be reached from the floor');
        }

        // Every enemy has solid floor under its whole patrol and none is near the
        // artifact room.
        for (final e in c.enemies) {
          expect(c.floorHolds(e.x - 70, e.x + 96 + 70), isTrue,
              reason: 'enemy at ${e.x} would patrol over a pit');
          expect(e.x + 96 + 70, lessThan(c.artifactX - 360));
        }

        // The artifact room: flat floor from before the artifact to the end.
        expect(c.floorHolds(c.artifactX - 500, c.mapWidth), isTrue);
        expect(c.exitX, greaterThan(c.artifactX + 300));
        expect(c.exitX + 200, lessThan(c.mapWidth));

        // Coins lie inside the map.
        for (final coin in c.coins) {
          expect(coin.x, inInclusiveRange(0, c.mapWidth));
        }
      });
    }

    test('the same level is always the same cave, and levels differ', () {
      final a = CaveLayout.forLevel('spanish', 2);
      final b = CaveLayout.forLevel('spanish', 2);
      final c = CaveLayout.forLevel('spanish', 4);
      expect(a.coins.map((v) => v.x).toList(), b.coins.map((v) => v.x).toList());
      expect(a.coins.map((v) => v.x).toList(),
          isNot(c.coins.map((v) => v.x).toList()));
    });
  });

  group('where the pipe stands in a level', () {
    LoadedLevel load(String era, int level) => LevelLoader.parse(File(
            'assets/tiles/levels/era${eraNumberFor(era)}_$level.tmx')
        .readAsStringSync());

    for (final (era, level) in _pipeLevels) {
      test('$era $level has a safe place for its pipe', () {
        final map = load(era, level);
        final plan = CavePlan.plan(map);
        expect(plan, isNotNull,
            reason: 'no flat, clear ground in $era $level for a pipe');
        expect(CavePlan.isSafeSpot(map, plan!.centerX, ignoring: plan.artifact),
            isTrue);
        // The level still counts its ten, and the one taken is not the golden one.
        expect(map.entities.where((e) => e.type == 'artifact').length, 10);
        expect(plan.artifact.golden, isFalse);
        // The pipe stands on the ground the plan says.
        expect(map.blockAt(plan.centerX)!.topY, plan.surfaceY);
        // It is in the road, not at the very start or the very end.
        final xs = [
          for (final e in map.entities)
            if (e.type == 'artifact') e.x,
        ]..sort();
        expect(plan.centerX, greaterThan(xs[1]));
        expect(plan.centerX, lessThan(xs[xs.length - 2]));
      });
    }

    test('the artifact taken to the cave is one near the middle of the road', () {
      final map = load('spanish', 2);
      final plan = CavePlan.plan(map)!;
      final xs = [
        for (final e in map.entities)
          if (e.type == 'artifact') e.x,
      ]..sort();
      expect(xs.indexOf(plan.artifact.x), inInclusiveRange(3, 6));
    });

    test('a spot beside an enemy is not safe', () {
      final map = load('spanish', 2);
      final enemy = map.entities.firstWhere((e) => e.type == 'enemy');
      expect(CavePlan.isSafeSpot(map, enemy.x + 45), isFalse);
    });

    test('the clear space covers a jump on and off the pipe', () {
      expect(CaveConstants.pipeClearSide, greaterThanOrEqualTo(CombatConstants.artifactSize));
    });
  });
}
