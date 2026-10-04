import 'dart:io';

import 'package:chronoquest/game/level_loader.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parses the hand-built reference map from disk rather than a fixture
/// string. It is the original `era1_1` prototype, kept in test/fixtures when
/// that level became a generated one, so the loader stays pinned against a map
/// a person made as well as against the generator's output
/// (GAMEPLAY-V2.md Section 11).
String _referenceTmx() =>
    File('test/fixtures/hand_built_level.tmx').readAsStringSync();

void main() {
  group('LevelLoader.assetPathFor', () {
    test('follows Section 11 era<N>_<n>.tmx convention', () {
      expect(
        LevelLoader.assetPathFor(1, 1),
        'assets/tiles/levels/era1_1.tmx',
      );
      expect(
        LevelLoader.assetPathFor(6, 5),
        'assets/tiles/levels/era6_5.tmx',
      );
    });
  });

  group('LevelLoader.parse — reference level era1_1', () {
    late LoadedLevel level;

    setUp(() => level = LevelLoader.parse(_referenceTmx()));

    test('reads the spawn position', () {
      expect(level.spawnX, 220);
    });

    test('reads the exit position, which becomes the level length', () {
      expect(level.exitX, 3140);
    });

    test('exit is beyond spawn, so the level can actually be finished', () {
      expect(level.exitX, greaterThan(level.spawnX));
    });

    test('reads the curriculum block from map properties (Section 1)', () {
      expect(level.curriculum, isNotNull);
      expect(level.curriculum!.grade, 5);
      expect(level.curriculum!.term, 1);
      expect(level.curriculum!.weeks, [1]);
    });

    test('reads the per-level starting charge override', () {
      expect(level.kaalamanStart, 1);
    });

    group('ground spans', () {
      test('are split into separate runs by the authored gaps', () {
        // Three solid stretches, because the map has two gaps in it.
        expect(level.groundSpans.length, 3);
      });

      test('start at world x 0', () {
        expect(level.groundSpans.first.startX, 0);
      });

      test('leave a real gap the player can fall through', () {
        final first = level.groundSpans[0];
        final second = level.groundSpans[1];
        final gapStart = first.startX + first.width;
        expect(gapStart, lessThan(second.startX));
        expect(second.startX - gapStart, 192);
      });

      test('the second gap is also real and harder', () {
        final second = level.groundSpans[1];
        final third = level.groundSpans[2];
        final gapStart = second.startX + second.width;
        expect(third.startX - gapStart, 208);
      });

      test('every gap is wider than the player, or it cannot be fallen into',
          () {
        // The original 96px gap exactly matched the 96px player sprite, so
        // some part of the player always overlapped a ledge and they walked
        // straight across. The collision fix (a centred foot span) is the
        // real cure, but a gap narrower than the sprite is a bad gap
        // regardless — it reads as a hole and behaves like a seam.
        const playerWidth = 96.0;
        for (var i = 0; i < level.groundSpans.length - 1; i++) {
          final gapStart =
              level.groundSpans[i].startX + level.groundSpans[i].width;
          final gapWidth = level.groundSpans[i + 1].startX - gapStart;
          expect(gapWidth, greaterThan(playerWidth),
              reason: 'gap at $gapStart is ${gapWidth}px, not wider than the '
                  '${playerWidth}px player');
        }
      });

      test('every gap is inside the jump arc, so none is a forced fall', () {
        // gravity 900 and jumpForce -480 give 1.067s of airtime; at the
        // 210 u/s top speed that is 224px of horizontal reach. A gap wider
        // than that, plus the 48px foot span that only has to land, cannot be
        // cleared on foot. This reference level stays under the plain reach.
        const jumpReach = 224.0;
        for (var i = 0; i < level.groundSpans.length - 1; i++) {
          final gapStart =
              level.groundSpans[i].startX + level.groundSpans[i].width;
          final gapWidth = level.groundSpans[i + 1].startX - gapStart;
          expect(gapWidth, lessThan(jumpReach),
              reason: 'gap at $gapStart is ${gapWidth}px, beyond the '
                  '${jumpReach}px the tuned jump arc can clear');
        }
      });

      test('isOverGround is false inside a gap and true on solid ground', () {
        final first = level.groundSpans[0];
        final gapMiddle = first.startX + first.width + 40;
        expect(level.isOverGround(gapMiddle), isFalse);
        expect(level.isOverGround(level.spawnX), isTrue);
      });

      test('the spawn point is on solid ground', () {
        expect(level.isOverGround(level.spawnX), isTrue);
      });

      test('the exit is on solid ground, so the level is completable', () {
        expect(level.isOverGround(level.exitX), isTrue);
      });
    });

    group('entities', () {
      test('spawn and exit are not emitted as buildable entities', () {
        expect(
          level.entities.where((e) => e.type == 'spawn' || e.type == 'exit'),
          isEmpty,
        );
      });

      test('reads enemies with their kind, behavior and patrol range', () {
        final enemies = level.entities.where((e) => e.type == 'enemy').toList();
        expect(enemies.length, 4);

        final walker = enemies.first;
        expect(walker.kind, 'tribal_warrior');
        expect(walker.behavior, 'walker');
        expect(walker.patrol, 150);

        // Era 1 has no Heavy sprite (Section 1's art mapping gives it
        // tribal_warrior and dark_spirit, both walkers), so variety comes
        // from a shorter patrol leash rather than a different behaviour.
        final shortLeash = enemies.firstWhere((e) => e.kind == 'dark_spirit');
        expect(shortLeash.behavior, 'walker');
        expect(shortLeash.patrol, 60);
      });

      test('only uses enemy sprites era 1 actually has art for', () {
        // The loader passes `kind` straight to EnemyComponent, which loads
        // `assets/enemies/<kind>_1.png`. A name with no art throws at load
        // time, which a parse-only test cannot see — hence this check.
        const eraOneSprites = {'tribal_warrior', 'dark_spirit'};
        for (final e in level.entities.where((e) => e.type == 'enemy')) {
          expect(eraOneSprites, contains(e.kind));
        }
      });

      test('reads all ten artifacts with a valid art property', () {
        final artifacts =
            level.entities.where((e) => e.type == 'artifact').toList();
        expect(artifacts.length, 10);
        // Only five sprites exist, so the ids repeat.
        const valid = {
          'artifact_1', 'artifact_2', 'artifact_3', 'artifact_4', 'artifact_5',
        };
        for (final a in artifacts) {
          expect(valid, contains(a.art));
        }
      });

      test('no artifact floats over a gap, where it could not be reached', () {
        for (final a in level.entities.where((e) => e.type == 'artifact')) {
          // Only the horizontal centre matters: an artifact hovers 150 above
          // ground, so what has to be solid is where the student stands to
          // reach it.
          expect(level.isOverGround(a.x + 28), isTrue,
              reason: 'artifact at x=${a.x} is over a gap');
        }
      });

      test('reads the single end gate', () {
        // One gate per level since 2026-10-03: it replaces the exit and
        // opens only once every artifact has been answered.
        final gates =
            level.entities.where((e) => e.type == 'gate').toList();
        expect(gates.length, 1);
        expect(gates.single.x, greaterThan(level.exitX - 100),
            reason: 'the gate is the exit, so it belongs at the level end');
      });

      test('reads coins', () {
        expect(level.entities.where((e) => e.type == 'coin').length, 8);
      });

      test('reads platforms with a width Tiled authored in pixels', () {
        final platforms =
            level.entities.where((e) => e.type == 'platform').toList();
        expect(platforms.length, 2);
        expect(platforms.every((p) => p.width > 0), isTrue);
      });
    });

    group('design invariants the loader must preserve', () {
      test('the first answer point the player meets is an artifact', () {
        // Charges come only from artifacts, so meeting a gate first would be
        // a dead start — the Phase 3 invariant, now enforced by authoring
        // rather than by the old procedural placement.
        final answerPoints = level.entities
            .where((e) => e.type == 'artifact' || e.type == 'gate')
            .toList()
          ..sort((a, b) => a.x.compareTo(b.x));
        expect(answerPoints.first.type, 'artifact');
      });

      test('every artifact comes before the end gate', () {
        // The gate is the exit and requires every artifact to have been
        // answered, so an artifact placed past it could never be reached.
        final gateX = level.entities
            .firstWhere((e) => e.type == 'gate')
            .x;
        for (final a in level.entities.where((e) => e.type == 'artifact')) {
          expect(a.x, lessThan(gateX),
              reason: 'artifact at x=${a.x} sits past the end gate');
        }
      });

      test('every gate has an artifact before it to earn a charge from', () {
        final sorted = level.entities
            .where((e) => e.type == 'artifact' || e.type == 'gate')
            .toList()
          ..sort((a, b) => a.x.compareTo(b.x));

        var artifactsSeen = 0;
        for (final e in sorted) {
          if (e.type == 'artifact') {
            artifactsSeen++;
          } else {
            expect(
              artifactsSeen,
              greaterThan(0),
              reason: 'gate at x=${e.x} has no artifact before it',
            );
          }
        }
      });

      test('platforms sit 104-112 above the ground, clear of every enemy',
          () {
        // groundY for a 720-tall map with a 60px ground band.
        const groundSurfaceY = 660.0;
        for (final p in level.entities.where((e) => e.type == 'platform')) {
          final heightAboveGround = groundSurfaceY - p.y;
          expect(
            heightAboveGround,
            inInclusiveRange(104, 112),
            reason: 'platform at x=${p.x} is $heightAboveGround above ground, '
                'outside 104-112: lower and an enemy can touch a student on it, '
                'higher and the jump cannot reach it',
          );
        }
      });

      test('every gap has a platform over it, so no gap is a forced fall', () {
        for (var i = 0; i < level.groundSpans.length - 1; i++) {
          final gapStart =
              level.groundSpans[i].startX + level.groundSpans[i].width;
          final gapEnd = level.groundSpans[i + 1].startX;
          final hasPlatform = level.entities.any(
            (e) =>
                e.type == 'platform' &&
                e.x + e.width > gapStart &&
                e.x < gapEnd,
          );
          expect(
            hasPlatform,
            isTrue,
            reason: 'gap $gapStart-$gapEnd has no platform over it',
          );
        }
      });

      test('every enemy patrols entirely over solid ground', () {
        // An enemy placed over a gap hovered in mid-air on device. The
        // runtime turns walkers back at a ledge, but authored data should
        // not rely on that: the whole patrol corridor, measured with the
        // same foot span the enemy obeys, must sit inside one ground span.
        final enemies = level.entities.where((e) => e.type == 'enemy');
        expect(enemies, isNotEmpty);
        for (final e in enemies) {
          expect(
            level.enemyStaysOnGround(e),
            isTrue,
            reason: 'enemy at x=${e.x} (patrol ${e.patrol}) leaves its '
                'ground span; spans: ${level.groundSpans}',
          );
        }
      });

      test('no entity is placed beyond the exit', () {
        for (final e in level.entities) {
          expect(
            e.x,
            lessThanOrEqualTo(level.exitX),
            reason: '${e.type} at x=${e.x} is past the exit at ${level.exitX} '
                'and can never be reached',
          );
        }
      });
    });
  });

  group('LoadedLevel.enemyStaysOnGround', () {
    const level = LoadedLevel(
      spawnX: 0,
      exitX: 1000,
      groundSpans: [
        (startX: 0.0, width: 400.0),
        (startX: 600.0, width: 400.0),
      ],
      entities: [],
    );

    test('accepts a patrol that stays inside one span', () {
      expect(
        level.enemyStaysOnGround(const LevelEntity(
            type: 'enemy', x: 150, y: 0, behavior: 'walker', patrol: 100)),
        isTrue,
      );
    });

    test('rejects an enemy standing in the gap', () {
      expect(
        level.enemyStaysOnGround(const LevelEntity(
            type: 'enemy', x: 450, y: 0, behavior: 'walker', patrol: 0)),
        isFalse,
      );
    });

    test('rejects a patrol that reaches over the gap', () {
      expect(
        level.enemyStaysOnGround(const LevelEntity(
            type: 'enemy', x: 250, y: 0, behavior: 'walker', patrol: 150)),
        isFalse,
      );
    });

    test('a heavy only needs the spot it stands on', () {
      expect(
        level.enemyStaysOnGround(const LevelEntity(
            type: 'enemy', x: 250, y: 0, behavior: 'heavy', patrol: 500)),
        isTrue,
      );
    });
  });

  group('LoadedLevel — enemies on platforms', () {
    // Ground 0..500 and 900..2000 with a 400-wide gap, a 192-wide platform in it
    // (600..792, top at 552, which is 108 above the 660 ground).
    LoadedLevel level(List<LevelEntity> enemies) => LoadedLevel(
          spawnX: 0,
          exitX: 2000,
          groundSpans: const [
            (startX: 0.0, width: 500.0),
            (startX: 900.0, width: 1100.0),
          ],
          entities: [
            const LevelEntity(type: 'platform', x: 600, y: 552, width: 192),
            ...enemies,
          ],
        );
    LevelEntity enemy(double x, double y, {double patrol = 36, String behavior = 'walker'}) =>
        LevelEntity(type: 'enemy', x: x, y: y, behavior: behavior, patrol: patrol);

    test('an enemy whose feet are above the ground is on a platform', () {
      final l = level([]);
      expect(l.enemyIsOnPlatform(enemy(651, 552)), isTrue);
      expect(l.enemyIsOnPlatform(enemy(100, 660)), isFalse);
    });

    test('finds the platform under it', () {
      final l = level([]);
      final p = l.platformUnder(enemy(651, 552));
      expect(p, isNotNull);
      expect(p!.x, 600);
      expect(l.platformUnder(enemy(100, 660)), isNull);
    });

    test('a centred patrol that fits the platform stays on it', () {
      expect(level([]).enemyStaysOnSupport(enemy(651, 552, patrol: 36)), isTrue);
    });

    test('a patrol that reaches past the platform edge does not', () {
      // Centred, a 75 patrol puts the foot span 1.5 units past each end.
      expect(level([]).enemyStaysOnSupport(enemy(651, 552, patrol: 76)), isFalse);
    });

    test('an enemy standing in the gap beside the platform is not supported', () {
      expect(level([]).enemyStaysOnSupport(enemy(500, 552, patrol: 0)), isFalse);
    });

    test('an enemy at platform height with no platform under it is not supported',
        () {
      // Same y as the platform, but over the far ground: nothing holds it up.
      expect(level([]).enemyStaysOnSupport(enemy(1500, 552, patrol: 0)), isFalse);
    });

    test('a y that matches no platform top is not supported', () {
      expect(level([]).enemyStaysOnSupport(enemy(651, 500, patrol: 0)), isFalse);
    });

    test('a ground enemy is still checked against the ground', () {
      final l = level([]);
      expect(l.enemyStaysOnSupport(enemy(100, 660, patrol: 100)), isTrue);
      expect(l.enemyStaysOnSupport(enemy(450, 660, patrol: 100)), isFalse,
          reason: 'its patrol reaches the gap');
    });
  });

  group('LevelLoader.parse — schema edge cases', () {
    test('a map with no curriculum properties parses with a null tag', () {
      const tmx = '''
<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" orientation="orthogonal" renderorder="right-down"
     width="4" height="2" tilewidth="16" tileheight="16" infinite="0"
     nextlayerid="3" nextobjectid="2">
 <layer id="1" name="ground" width="4" height="2">
  <data encoding="csv">0,0,0,0,2,2,2,2</data>
 </layer>
 <objectgroup id="2" name="entities">
  <object id="1" type="spawn" x="16" y="16"/>
 </objectgroup>
</map>''';
      final level = LevelLoader.parse(tmx);
      expect(level.curriculum, isNull);
      expect(level.kaalamanStart, isNull);
    });

    test('weeks parses a comma-separated list, since Tiled has no list type',
        () {
      const tmx = '''
<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" orientation="orthogonal" renderorder="right-down"
     width="2" height="1" tilewidth="16" tileheight="16" infinite="0"
     nextlayerid="2" nextobjectid="1">
 <properties>
  <property name="grade" type="int" value="6"/>
  <property name="term" type="int" value="2"/>
  <property name="weeks" value="8, 9"/>
 </properties>
 <layer id="1" name="ground" width="2" height="1">
  <data encoding="csv">2,2</data>
 </layer>
</map>''';
      final level = LevelLoader.parse(tmx);
      expect(level.curriculum!.weeks, [8, 9]);
    });

    test('a map with no exit falls back to its right edge', () {
      const tmx = '''
<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" orientation="orthogonal" renderorder="right-down"
     width="10" height="1" tilewidth="16" tileheight="16" infinite="0"
     nextlayerid="2" nextobjectid="1">
 <layer id="1" name="ground" width="10" height="1">
  <data encoding="csv">2,2,2,2,2,2,2,2,2,2</data>
 </layer>
</map>''';
      expect(LevelLoader.parse(tmx).exitX, 160);
    });

    test('ground that fills every column yields one unbroken span', () {
      const tmx = '''
<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" orientation="orthogonal" renderorder="right-down"
     width="5" height="1" tilewidth="16" tileheight="16" infinite="0"
     nextlayerid="2" nextobjectid="1">
 <layer id="1" name="ground" width="5" height="1">
  <data encoding="csv">2,2,2,2,2</data>
 </layer>
</map>''';
      final spans = LevelLoader.parse(tmx).groundSpans;
      expect(spans.length, 1);
      expect(spans.single.startX, 0);
      expect(spans.single.width, 80);
    });

    test('a trailing gap does not emit a zero-width span', () {
      const tmx = '''
<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" orientation="orthogonal" renderorder="right-down"
     width="5" height="1" tilewidth="16" tileheight="16" infinite="0"
     nextlayerid="2" nextobjectid="1">
 <layer id="1" name="ground" width="5" height="1">
  <data encoding="csv">2,2,0,0,0</data>
 </layer>
</map>''';
      final spans = LevelLoader.parse(tmx).groundSpans;
      expect(spans.length, 1);
      expect(spans.single.width, 32);
    });

    test('an unknown entity type is still parsed, for the builder to warn on',
        () {
      const tmx = '''
<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" orientation="orthogonal" renderorder="right-down"
     width="2" height="1" tilewidth="16" tileheight="16" infinite="0"
     nextlayerid="3" nextobjectid="2">
 <layer id="1" name="ground" width="2" height="1">
  <data encoding="csv">2,2</data>
 </layer>
 <objectgroup id="2" name="entities">
  <object id="1" type="treasure_chest" x="32" y="48"/>
 </objectgroup>
</map>''';
      final level = LevelLoader.parse(tmx);
      expect(level.entities.single.type, 'treasure_chest');
    });
  });
}
