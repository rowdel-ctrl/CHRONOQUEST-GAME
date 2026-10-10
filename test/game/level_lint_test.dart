// Level lint: every `.tmx` in assets/tiles/levels is parsed by the game's own
// LevelLoader and checked against the rules a level must obey (GAMEPLAY-V2.md
// Section 11, "Generator design"). Hand-built and generated levels face the
// same checks, so a bad level cannot get in by either route.
//
// These are the rules about placement: ground heights, pits, platforms, enemies,
// artifacts. That the level can actually be finished is a different question,
// answered by level_playthrough_test.dart, which plays a winning run on the game's
// own player.
//
// The checks cannot prove a level is fun or fair; that is what playtests are for.
import 'dart:io';

import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/enemy_behavior.dart';
import 'package:chronoquest/game/level_loader.dart';
import 'package:flutter_test/flutter_test.dart';

/// The ground tile: 24 units, the art drawn at 1.5x.
const double _tile = 24;

/// A pit a student jumps in one go. The generator plays every level with a jump
/// 5% slower and lower than the real one and a pit up to 288 passes.
const double _gapMin = 192;
const double _gapMax = 288;
const double _pitMin = 4 * _tile;

/// The tallest step a student is asked to jump up (96, under the jump's 128 peak)
/// and the tallest ground anywhere (a tower, climbed in 2-tile steps).
const int _maxRiseTiles = 4;
const int _maxHeightTiles = 16;

const double _groundSurfaceY = 660;
const double _platformTile = 24;
const double _enemyWidth = 90;
const double _artifactSize = 72;

/// A platform floats at least this far above the base ground (so it is a ledge,
/// not a lump on the floor) and at most a jump above the highest ground beside it.
const double _platformMinAbove = 48;
const double _platformMaxAbove = 112;

/// A floor for every level. The generator holds itself to 600; the hand-built
/// fixture (test/fixtures) has two walkers 480 apart.
const double _minEnemySpacing = 400;

/// Only enforced on generated levels. The hand-built fixture predates the rule
/// and has a walker patrolling beside two artifacts.
const double _artifactClearance = 240;

/// Only enforced on generated levels. An enemy's whole patrol stays this far
/// from a hazard edge of its ground (a pit, or a rise or drop of two tiles or
/// more), so a student landing from a jump is not hit at once.
const double _enemyEdgeClearance = 160;

/// The generator's section layout (tools/levelgen/rules.js): ten sections of
/// 2304 after a safe start of 1008, each holding an enemy and something to cross.
const double _safeStart = 1008;
const double _groupWidth = 2304;
const double _restWidth = 576;
const int _groups = 10;
const double _fightFirstSection = 2; // 0-based: no platform fights in sections 1 and 2

final _fileName = RegExp(r'era(\d+)_(\d+)\.tmx$');

List<String> lintLevel(String xml, {required int eraNumber, required int levelIndex}) {
  final problems = <String>[];
  final era = allEras[eraNumber - 1];
  final level = LevelLoader.parse(xml);
  final generated = xml.contains('name="generator"');
  final blocks = level.blocks;

  // ── identity ─────────────────────────────────────────────────────────────
  final eraProp = RegExp(r'name="era"\s+value="([^"]+)"').firstMatch(xml)?.group(1);
  final levelProp =
      RegExp(r'name="level"\s+type="int"\s+value="(\d+)"').firstMatch(xml)?.group(1);
  if (eraProp != era.id) problems.add('era property is "$eraProp", file says ${era.id}');
  if (levelProp != '$levelIndex') {
    problems.add('level property is $levelProp, file says $levelIndex');
  }

  final c = level.curriculum;
  final weeks = era.levelWeeks[levelIndex - 1];
  if (c == null) {
    problems.add('missing curriculum block');
  } else if (c.grade != era.grade || c.term != era.term || '${c.weeks}' != '$weeks') {
    problems.add('curriculum ${c.grade}/${c.term}/${c.weeks} does not match the '
        'registry ${era.grade}/${era.term}/$weeks');
  }

  // ── start and end ────────────────────────────────────────────────────────
  if (!level.isOverGround(level.spawnX)) problems.add('spawn is not over ground');
  if (!level.isOverGround(level.exitX)) problems.add('exit is not over ground');
  if (generated && level.blockAt(level.spawnX)?.topY != _groundSurfaceY) {
    problems.add('spawn is not on the base ground');
  }

  // ── terrain: rises, heights and pits ─────────────────────────────────────
  for (var i = 0; i + 1 < blocks.length; i++) {
    final a = blocks[i], b = blocks[i + 1];
    if ((a.endX - b.startX).abs() > 0.5) continue; // a pit lies between them
    final rise = (a.topY - b.topY) / _tile;
    if (rise > _maxRiseTiles) {
      problems.add('a rise of ${(rise * _tile).toInt()} at ${b.startX.toInt()}, '
          'over ${(_maxRiseTiles * _tile).toInt()}');
    }
  }
  for (final b in blocks) {
    final h = b.heightInTiles(_tile);
    if (h > _maxHeightTiles) {
      problems.add('ground at ${b.startX.toInt()} is ${(h * _tile).toInt()} high, '
          'over ${(_maxHeightTiles * _tile).toInt()}');
    }
    if (generated && h > 0 && b.startX < _safeStart) {
      problems.add('raised ground at ${b.startX.toInt()} is inside the safe start');
    }
  }
  final spans = level.groundSpans;
  final platforms = level.entities.where((e) => e.type == 'platform').toList();
  final pits = <({double start, double end})>[];
  for (var i = 0; i < spans.length - 1; i++) {
    final start = spans[i].startX + spans[i].width;
    final end = spans[i + 1].startX;
    pits.add((start: start, end: end));
    final w = end - start;
    final over = platforms.where((p) => p.x < end && p.x + p.width > start).length;
    if (w < _pitMin) problems.add('pit at ${start.toInt()} is only ${w.toInt()} wide');
    if (w > _gapMax && over == 0) {
      problems.add('pit at ${start.toInt()} is ${w.toInt()} wide with no platform');
    }
    if (generated && w > 1152) problems.add('pit at ${start.toInt()} is ${w.toInt()} wide, over 1152');
    if (generated && over == 0 && w > 240) {
      problems.add('platformless pit at ${start.toInt()} is ${w.toInt()} wide, over 240');
    }
    if (generated && start < _safeStart) {
      problems.add('pit at ${start.toInt()} is inside the safe start');
    }
    if (w < _gapMin && w >= _pitMin && !generated) {
      // hand-built levels may have narrower pits; nothing to add
    }
  }

  // ── the one end gate and the artifacts ───────────────────────────────────
  final gates = level.entities.where((e) => e.type == 'gate').toList();
  final artifacts = level.entities.where((e) => e.type == 'artifact').toList();
  if (gates.length != 1) {
    problems.add('${gates.length} gates, expected exactly 1');
  } else if (gates.single.x < level.exitX - CombatConstants.gateWidth) {
    problems.add('the gate is not at the exit');
  } else if (generated &&
      gates.single.x + CombatConstants.gateWidth >
          level.groundSpans.last.startX + level.groundSpans.last.width) {
    problems.add('the gate runs off the end of the map');
  }
  if (artifacts.length != CombatConstants.artifactsPerLevel) {
    problems.add('${artifacts.length} artifacts, expected '
        '${CombatConstants.artifactsPerLevel}');
  }
  const validArt = {
    'artifact_1', 'artifact_2', 'artifact_3', 'artifact_4', 'artifact_5',
  };
  for (final a in artifacts) {
    if (!validArt.contains(a.art)) problems.add('artifact at ${a.x.toInt()} has art ${a.art}');
    if (gates.isNotEmpty && a.x >= gates.first.x) {
      problems.add('artifact at ${a.x.toInt()} is past the gate');
    }
    // An artifact stands on the ground under it, at that ground's height.
    final under = level.blockAt(a.x + _artifactSize / 2);
    if (under == null || (under.topY - a.y).abs() > 1) {
      problems.add('artifact at ${a.x.toInt()} is not standing on the ground (y ${a.y.toInt()})');
    }
  }

  // ── platforms ────────────────────────────────────────────────────────────
  for (final p in platforms) {
    if (p.width % _platformTile != 0) {
      problems.add('platform at ${p.x.toInt()} is ${p.width} wide, not a multiple of 24');
    }
    // The highest ground or platform within a jump of either end: what a student
    // launches from to reach this one (a second-tier platform is reached from the
    // first).
    var nearest = _groundSurfaceY;
    for (final b in blocks) {
      if (b.startX < p.x + p.width + 300 && b.endX > p.x - 300 && b.topY < nearest) {
        nearest = b.topY;
      }
    }
    for (final q in platforms) {
      if (identical(q, p)) continue;
      if (q.x < p.x + p.width + 300 && q.x + q.width > p.x - 300 && q.y < nearest) {
        nearest = q.y;
      }
    }
    final above = nearest - p.y;
    if (above > _platformMaxAbove) {
      problems.add('platform at ${p.x.toInt()} is ${above.toInt()} above the ground '
          'beside it, over ${_platformMaxAbove.toInt()}');
    }
    if (_groundSurfaceY - p.y < _platformMinAbove) {
      problems.add('platform at ${p.x.toInt()} lies on the ground, only '
          '${(_groundSurfaceY - p.y).toInt()} above the base');
    }
    for (var x = p.x; x < p.x + p.width; x += _tile) {
      final b = level.blockAt(x);
      if (b != null && b.topY < p.y + 32 + 56) {
        problems.add('platform at ${p.x.toInt()} sits in the ground at ${x.toInt()}');
        break;
      }
    }
  }

  // ── enemies ──────────────────────────────────────────────────────────────
  final enemies = level.entities.where((e) => e.type == 'enemy').toList()
    ..sort((a, b) => a.x.compareTo(b.x));
  bool onPlatform(LevelEntity e) =>
      level.blockUnder(e) == null && level.platformUnder(e) != null;
  for (final e in enemies) {
    if (!era.enemyTypes.contains(e.kind)) {
      problems.add('enemy at ${e.x.toInt()} is "${e.kind}", not one of ${era.enemyTypes}');
    }
    final want = enemyTypeTable[e.kind]?.behavior;
    final isHeavy = want == EnemyBehavior.heavy;
    if (e.behavior != (isHeavy ? 'heavy' : 'walker')) {
      problems.add('enemy "${e.kind}" at ${e.x.toInt()} has behavior ${e.behavior}');
    }
    if (!level.enemyStaysOnSupport(e)) {
      problems.add('enemy at ${e.x.toInt()} patrols off its ground');
    }
  }
  for (var i = 1; i < enemies.length; i++) {
    if (enemies[i].x - enemies[i - 1].x < _minEnemySpacing) {
      problems.add('enemies at ${enemies[i - 1].x.toInt()} and ${enemies[i].x.toInt()} '
          'are under ${_minEnemySpacing.toInt()} apart');
    }
  }

  // ── fairness (generated levels only) ─────────────────────────────────────
  if (generated) {
    for (final e in enemies) {
      final range = e.behavior == 'heavy' ? 0.0 : (e.patrol ?? CombatConstants.patrolRange);
      final left = e.x - range;
      final right = e.x + range + _enemyWidth;
      if (left < _safeStart) problems.add('enemy at ${e.x.toInt()} patrols into the safe start');
      for (final a in artifacts) {
        final distance = [left - (a.x + _artifactSize), a.x - right, 0.0]
            .reduce((x, y) => x > y ? x : y);
        if (distance < _artifactClearance) {
          problems.add('enemy at ${e.x.toInt()} patrols within '
              '${distance.toInt()} of the artifact at ${a.x.toInt()}, '
              'a student would be hit as the question closes');
        }
      }
      if (onPlatform(e)) {
        if (e.behavior == 'heavy') {
          problems.add('the enemy on the platform at ${e.x.toInt()} is a heavy');
        }
        if (e.x < _safeStart + _fightFirstSection * _groupWidth) {
          problems.add('a platform fight at ${e.x.toInt()} is in the first sections');
        }
        continue; // a platform fight is over its pit by design
      }
      final block = level.blockUnder(e);
      if (block != null) {
        // A hazard edge: a pit beside the block, or a rise or drop of 2+ tiles.
        bool hazard(GroundBlock? n) =>
            n == null || (n.topY - block.topY).abs() >= 2 * _tile - 0.5;
        GroundBlock? neighbour(double x) {
          final b = level.blockAt(x);
          return b == block ? null : b;
        }
        final leftHazard = hazard(neighbour(block.startX - 1));
        final rightHazard = hazard(neighbour(block.endX + 1));
        if (leftHazard && left - block.startX < _enemyEdgeClearance) {
          problems.add('enemy at ${e.x.toInt()} patrols within '
              '${(left - block.startX).toInt()} of the left edge of its ground, '
              'a student would be hit on landing');
        }
        if (rightHazard && block.endX - right < _enemyEdgeClearance) {
          problems.add('enemy at ${e.x.toInt()} patrols within '
              '${(block.endX - right).toInt()} of the right edge of its ground, '
              'a student would be hit on landing');
        }
      }
    }

    if (!enemies.any(onPlatform)) problems.add('the level has no platform fight');

    // Every section has an enemy and something to cross.
    for (var s = 0; s < _groups; s++) {
      final from = _safeStart + s * _groupWidth;
      final to = from + _groupWidth;
      if (!enemies.any((e) => e.x >= from && e.x < to)) {
        problems.add('section ${s + 1} has no enemy');
      }
      // Something to cross: a pit, or the ground changing height, in the challenge
      // part of the section (not the rest area at its end).
      final heights = <double>{};
      for (var x = from; x < to - _restWidth; x += _tile) {
        heights.add(level.blockAt(x)?.topY ?? -1);
      }
      if (heights.length < 2) problems.add('section ${s + 1} has no terrain to cross');
    }

    // Coins are on the ground or in the air, never inside it.
    for (final coin in level.entities.where((e) => e.type == 'coin')) {
      final b = level.blockAt(coin.x + 21);
      if (b != null && coin.y + 42 > b.topY + 4) {
        problems.add('coin at (${coin.x.toInt()}, ${coin.y.toInt()}) is inside the ground');
      }
    }
  }

  return problems;
}

List<File> _levelFiles() => Directory('assets/tiles/levels')
    .listSync()
    .whereType<File>()
    .where((f) => _fileName.hasMatch(f.path))
    .toList()
  ..sort((a, b) => a.path.compareTo(b.path));

void main() {
  group('every level file passes the lint', () {
    for (final file in _levelFiles()) {
      final m = _fileName.firstMatch(file.path)!;
      final eraNumber = int.parse(m.group(1)!);
      final levelIndex = int.parse(m.group(2)!);

      test('era${eraNumber}_$levelIndex.tmx', () {
        final problems = lintLevel(
          file.readAsStringSync(),
          eraNumber: eraNumber,
          levelIndex: levelIndex,
        );
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  });

  test('the manifest lists exactly the files on disk', () {
    final onDisk = {
      for (final f in _levelFiles())
        (
          int.parse(_fileName.firstMatch(f.path)!.group(1)!),
          int.parse(_fileName.firstMatch(f.path)!.group(2)!),
        ),
    };
    expect(LevelLoader.authored, onDisk,
        reason: 'a map on disk but not in the manifest never loads; one in the '
            'manifest but not on disk crashes the level');
  });

  test('no level is a boss level', () {
    // Bosses are Phase 5 and keep the procedural fallback until then; a
    // boss .tmx would route through a fight that does not exist yet.
    for (final (eraNumber, levelIndex) in LevelLoader.authored) {
      final era = allEras[eraNumber - 1];
      expect(levelIndex, lessThan(era.levelWeeks.length),
          reason: 'era$eraNumber level $levelIndex is the boss');
    }
  });

  test('the levels are not flat: every one has raised ground and pits', () {
    for (final file in _levelFiles()) {
      final level = LevelLoader.parse(file.readAsStringSync());
      final raised = level.blocks.where((b) => b.heightInTiles(_tile) > 0).length;
      expect(raised, greaterThanOrEqualTo(8), reason: file.path);
      expect(level.groundSpans.length, greaterThanOrEqualTo(4), reason: '${file.path} pits');
      expect(level.blocks.map((b) => b.heightInTiles(_tile)).reduce((a, b) => a > b ? a : b),
          greaterThanOrEqualTo(3),
          reason: '${file.path} has something taller than a step');
    }
  });

  // The lint is only worth trusting if it can fail. Each case breaks one rule
  // in the hand-built fixture and expects the matching complaint.
  group('the lint catches a broken level', () {
    final base = File('test/fixtures/hand_built_level.tmx').readAsStringSync();

    List<String> lint(String xml, {int era = 1}) =>
        lintLevel(xml, eraNumber: era, levelIndex: 1);
    Matcher complaint(String text) =>
        contains(predicate<String>((s) => s.contains(text)));

    test('the unmodified reference level is clean', () {
      expect(lint(base), isEmpty);
    });

    test('a platform too high to jump onto', () {
      final bad = base.replaceFirst('y="552" width="96"', 'y="500" width="96"');
      expect(lint(bad), complaint('platform'));
    });

    test('a platform lying on the ground', () {
      final bad = base.replaceFirst('y="552" width="96"', 'y="630" width="96"');
      expect(lint(bad), complaint('platform'));
    });

    test('a missing artifact', () {
      final bad = base.replaceFirst(
        RegExp(r'<object id="5" type="artifact"[\s\S]*?</object>'),
        '',
      );
      expect(lint(bad), complaint('9 artifacts'));
    });

    test('a Heavy enemy in an era with no Heavy art', () {
      final bad = base.replaceFirst('name="kind" value="tribal_warrior"',
          'name="kind" value="tank"');
      expect(lint(bad), complaint('tank'));
    });

    test('a second gate', () {
      final bad = base.replaceFirst(
          '<object id="23"', '<object id="99" type="gate" x="1400" y="660"/>\n  <object id="23"');
      expect(lint(bad), complaint('2 gates'));
    });

    test('an enemy standing in a gap', () {
      final bad = base.replaceFirst('<object id="6" type="enemy" x="600"',
          '<object id="6" type="enemy" x="900"');
      expect(lint(bad), complaint('patrols off'));
    });

    test('the wrong curriculum weeks', () {
      final bad = base.replaceFirst('name="weeks" value="1"', 'name="weeks" value="7"');
      expect(lint(bad), complaint('curriculum'));
    });
  });

  // The rules that only apply to generated levels, tried on spanish 3.
  group('the lint catches a broken generated level', () {
    final base = File('assets/tiles/levels/era2_3.tmx').readAsStringSync();
    List<String> lint(String xml) => lintLevel(xml, eraNumber: 2, levelIndex: 3);
    Matcher complaint(String text) =>
        contains(predicate<String>((s) => s.contains(text)));

    test('the unmodified level is clean', () {
      expect(lint(base), isEmpty);
    });

    test('a level with no enemies leaves every section without one', () {
      final bad = base.replaceAll(
          RegExp(r'<object id="\d+" type="enemy"[\s\S]*?</object>'), '');
      expect(lint(bad), complaint('section 1 has no enemy'));
      expect(lint(bad), complaint('section 10 has no enemy'));
    });

    test('a level with no platform fight', () {
      // Take every enemy that is not on the ground or on raised ground off its
      // platform's height by dropping the platform objects.
      final bad = base.replaceAll(
          RegExp(r'<object id="\d+" type="platform"[\s\S]*?/>'), '');
      expect(lint(bad), complaint('platform'));
    });

    test('a pit too wide to jump with no platform over it', () {
      final bad = base.replaceAll(
          RegExp(r'<object id="\d+" type="platform"[\s\S]*?/>'), '');
      expect(lint(bad), complaint('with no platform'));
    });

    test('an enemy right at a ledge', () {
      final level = LevelLoader.parse(base);
      final m = RegExp(r'(<object id="\d+" type="enemy" x=")([\d.]+)(" y="[\d.]+">)')
          .firstMatch(base)!;
      final enemy = level.entities
          .firstWhere((e) => e.type == 'enemy' && e.x == double.parse(m.group(2)!));
      final block = level.blockUnder(enemy)!;
      // Move the enemy so its patrol ends 40 short of the end of its ground.
      final x = block.endX - 40 - _enemyWidth - (enemy.patrol ?? 0);
      final bad = base.replaceFirst(m.group(0)!, '${m.group(1)}$x${m.group(3)}');
      expect(lint(bad), complaint('edge of its ground'));
    });

    test('a coin buried in the ground', () {
      final level = LevelLoader.parse(base);
      final coin = level.entities.firstWhere(
          (e) => e.type == 'coin' && level.blockAt(e.x + 21) != null);
      final bad = base.replaceFirst(
        'type="coin" x="${coin.x.toInt()}" y="${coin.y.toInt()}"',
        'type="coin" x="${coin.x.toInt()}" y="700"',
      );
      expect(lint(bad), complaint('inside the ground'));
    });
  });
}
