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

  group('the cave obstacles', () {
    // Every cave the game can make: each era, levels 1 to 12 (the pipe levels are
    // among them).
    final all = [
      for (final e in allEras)
        for (var l = 1; l <= 12; l++) (e.id, l),
    ];
    const room = CaveConstants.artifactX - 360;

    test('which obstacles come at which level', () {
      for (final l in [1, 2, 3]) {
        expect(CaveConstants.obstaclesFor(l), {CaveObstacle.spikes},
            reason: 'level $l');
      }
      for (final l in [4, 5]) {
        expect(CaveConstants.obstaclesFor(l),
            {CaveObstacle.spikes, CaveObstacle.stalactite},
            reason: 'level $l');
      }
      for (final l in [6, 7]) {
        expect(CaveConstants.obstaclesFor(l), {
          CaveObstacle.spikes,
          CaveObstacle.stalactite,
          CaveObstacle.crumblingSlab,
        }, reason: 'level $l');
      }
      for (final l in [8, 9, 10, 12]) {
        expect(CaveConstants.obstaclesFor(l), CaveObstacle.values.toSet(),
            reason: 'level $l');
      }
    });

    test('the right number of each, per level, in every cave', () {
      for (final (era, l) in all) {
        final c = CaveLayout.forLevel(era, l);
        final why = '$era $l';
        expect(c.spikes.length, CaveConstants.spikeClusters, reason: why);
        expect(c.stalactites.length, l >= 4 ? CaveConstants.stalactiteCount : 0,
            reason: why);
        final crumbling = c.platforms.where((p) => p.crumbling).length;
        if (l >= 6) {
          expect(crumbling, inInclusiveRange(1, CaveConstants.crumblingSlabsMax),
              reason: why);
        } else {
          expect(crumbling, 0, reason: why);
        }
        expect(c.crushers.length, l >= 8 ? CaveConstants.crusherCount : 0,
            reason: why);
        for (final s in c.spikes) {
          expect(s.count, inInclusiveRange(1, CaveConstants.spikeMaxInCluster),
              reason: why);
          expect(s.width, lessThanOrEqualTo(72), reason: why);
        }
      }
    });

    test('the same level is always the same obstacles', () {
      for (final (era, l) in all) {
        final a = CaveLayout.forLevel(era, l);
        final b = CaveLayout.forLevel(era, l);
        expect([for (final s in a.spikes) (s.x, s.count)],
            [for (final s in b.spikes) (s.x, s.count)]);
        expect(a.stalactites.map((s) => s.x), b.stalactites.map((s) => s.x));
        expect(a.crushers.map((s) => s.centerX), b.crushers.map((s) => s.centerX));
        expect(a.platforms.map((p) => p.crumbling),
            b.platforms.map((p) => p.crumbling));
      }
    });

    test('the first caves have only the two spike clusters', () {
      for (final era in ['spanish', 'modern']) {
        for (final l in [2, 3]) {
          final plain = CaveLayout.forLevel(era, l);
          expect(plain.platforms.every((p) => !p.crumbling), isTrue);
          expect(plain.stalactites, isEmpty);
          expect(plain.crushers, isEmpty);
          expect(plain.spikes.length, 2);
        }
      }
    });

    bool floorHolds(CaveLayout c, double l, double r) => c.floorHolds(l, r);
    bool inEnemyPatrol(CaveLayout c, double l, double r) => c.enemies
        .any((e) => r > e.x - 70 && l < e.x + 96 + 70);

    test('spikes: flat floor, run-up and landing, no pit, no patrol', () {
      for (final (era, l) in all) {
        final c = CaveLayout.forLevel(era, l);
        final why = '$era $l';
        for (final s in c.spikes) {
          expect(
              floorHolds(c, s.x - CaveConstants.spikeRunUp,
                  s.endX + CaveConstants.spikeLanding),
              isTrue,
              reason: '$why: spikes at ${s.x} need flat floor round them');
          for (final p in c.pits) {
            expect(s.endX <= p.x0 || s.x >= p.x1, isTrue, reason: '$why in a pit');
          }
          expect(inEnemyPatrol(c, s.x, s.endX), isFalse,
              reason: '$why: an enemy patrols over the spikes at ${s.x}');
          expect(s.endX + CaveConstants.spikeLanding, lessThanOrEqualTo(room),
              reason: '$why: the artifact room must stay empty');
        }
      }
    });

    test('stalactites: flat floor under them, no patrol, not in the room', () {
      for (final (era, l) in all) {
        final c = CaveLayout.forLevel(era, l);
        final why = '$era $l';
        for (final s in c.stalactites) {
          expect(
              floorHolds(c, s.x - CaveConstants.stalactiteRoom,
                  s.x + CaveConstants.stalactiteRoom),
              isTrue,
              reason: '$why: stalactite at ${s.x}');
          expect(inEnemyPatrol(c, s.x - 50, s.x + 50), isFalse,
              reason: '$why: an enemy patrols under the stalactite at ${s.x}');
          expect(s.x + CaveConstants.stalactiteRoom, lessThanOrEqualTo(room),
              reason: why);
        }
      }
    });

    test('crusher: 300 of flat floor each side, no patrol, no pit within 150',
        () {
      var seen = 0;
      for (final (era, l) in all) {
        final c = CaveLayout.forLevel(era, l);
        final why = '$era $l';
        for (final s in c.crushers) {
          seen++;
          expect(
              floorHolds(c, s.left - CaveConstants.crusherRoom,
                  s.right + CaveConstants.crusherRoom),
              isTrue,
              reason: '$why: crusher at ${s.centerX}');
          expect(inEnemyPatrol(c, s.left, s.right), isFalse, reason: why);
          for (final p in c.pits) {
            expect(p.x1 + 150 <= s.left || p.x0 - 150 >= s.right, isTrue,
                reason: '$why: a pit within 150 of the crusher');
          }
          expect(s.right + CaveConstants.crusherRoom, lessThanOrEqualTo(room),
              reason: why);
        }
      }
      expect(seen, greaterThan(20), reason: 'levels 8 and up have one each');
    });

    test('no obstacle stands in the artifact room, under a slab or on another',
        () {
      for (final (era, l) in all) {
        final c = CaveLayout.forLevel(era, l);
        final why = '$era $l';
        final spans = <(double, double)>[
          for (final s in c.spikes) (s.x, s.endX),
          for (final s in c.stalactites) (s.x - 50, s.x + 50),
          for (final s in c.crushers) (s.left, s.right),
        ];
        for (final (a, b) in spans) {
          expect(b, lessThan(room), reason: why);
          for (final p in c.platforms) {
            expect(b <= p.x || a >= p.endX, isTrue,
                reason: '$why: an obstacle under the slab at ${p.x}');
          }
        }
        for (var i = 0; i < spans.length; i++) {
          for (var j = i + 1; j < spans.length; j++) {
            final gap = spans[i].$1 < spans[j].$1
                ? spans[j].$1 - spans[i].$2
                : spans[i].$1 - spans[j].$2;
            expect(gap, greaterThan(150), reason: '$why: obstacles too close');
          }
        }
      }
    });

    test('a crumbling slab is one of the cave\'s own, so the floor never needs it',
        () {
      for (final (era, l) in all) {
        final c = CaveLayout.forLevel(era, l);
        for (final p in c.platforms.where((p) => p.crumbling)) {
          // The same walkability rules as any slab: it is above solid floor, at
          // a height the jump reaches, and nothing the floor needs stands on it.
          expect(c.floorHolds(p.x, p.endX), isTrue, reason: '$era $l');
          expect(CaveLayout.floorY - p.surfaceY,
              inInclusiveRange(CaveConstants.minPlatformRise,
                  CaveConstants.maxPlatformRise));
        }
        // The floor runs the whole way without the slabs: no pit is wider than a
        // jump, and every run of floor is long enough to take off and land.
        for (final pit in c.pits) {
          expect(pit.x1 - pit.x0, lessThanOrEqualTo(CaveConstants.maxPitWidth));
        }
      }
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
