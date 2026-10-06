// Level lint: every `.tmx` in assets/tiles/levels is parsed by the game's own
// LevelLoader and checked against the rules a level must obey (GAMEPLAY-V2.md
// Section 11, "Generator design"). Hand-built and generated levels face the
// same checks, so a bad level cannot get in by either route.
//
// The checks prove each jump is inside the physics and the layout cannot
// softlock. They cannot prove a level is fun or fair; that is what playtests
// are for.
import 'dart:io';

import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/enemy_behavior.dart';
import 'package:chronoquest/game/level_loader.dart';
import 'package:flutter_test/flutter_test.dart';

/// Flat jump reach is 267 (250 u/s * 1.067 s) and only the 48-unit foot span has
/// to land, so a gap up to 48 + 90% of the reach (288) is crossable with margin.
const double _gapMin = 192;
const double _gapMax = 288;
const double _minGroundBetweenGaps = 240;
/// Above every enemy's hit area (99.9) so a student on a platform cannot be
/// touched, and under the verified ceiling of jumpPeak - 15 = 113.
const double _platformMinHeight = 104;
const double _platformMaxHeight = 112;
const double _groundSurfaceY = 660;
const double _platformTile = 24;
const double _enemyWidth = 90;
const double _artifactSize = 72;

/// A floor for every level. The generator holds itself to 600; the hand-built
/// fixture (test/fixtures) has two walkers 480 apart.
const double _minEnemySpacing = 400;

/// Only enforced on generated levels. The hand-built fixture predates the rule
/// and has a walker patrolling beside two artifacts.
const double _artifactClearance = 240;

/// Only enforced on generated levels. An enemy's whole patrol stays this far
/// from a gap edge, so a student landing from a jump is not hit at once.
const double _enemyGapClearance = 160;

/// The generator's section layout (tools/levelgen/rules.js): ten sections of
/// 2304 after a safe start of 1008, each holding a gap with a platform and an
/// enemy.
const double _safeStart = 1008;
const double _groupWidth = 2304;
const int _groups = 10;

/// Platform fights (tools/levelgen/rules.js): a gap too wide to jump with a wide
/// platform in the middle and an enemy on it. The longest crossable gap is the
/// 267 reach plus the 48-unit foot span, so these gaps need the platform.
const List<double> _fightGaps = [352, 384, 416];
const double _fightPlatformWidth = 240;
const double _fightLedgeMax = 112;
const int _fightFirstSection = 2; // 0-based: none in sections 1 and 2
const double _longestJump = 315;

final _fileName = RegExp(r'era(\d+)_(\d+)\.tmx$');

List<String> lintLevel(String xml, {required int eraNumber, required int levelIndex}) {
  final problems = <String>[];
  final era = allEras[eraNumber - 1];
  final level = LevelLoader.parse(xml);
  final generated = xml.contains('name="generator"');

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

  // ── ground and gaps ──────────────────────────────────────────────────────
  final spans = level.groundSpans;
  final gaps = <({double start, double end})>[];
  for (var i = 0; i < spans.length - 1; i++) {
    final start = spans[i].startX + spans[i].width;
    final end = spans[i + 1].startX;
    gaps.add((start: start, end: end));
    final w = end - start;
    if (w > _gapMax) {
      // Wider than any jump: only a platform fight may be this wide.
      problems.addAll(_lintFight(level, start, end, generated: generated));
    } else if (w < _gapMin) {
      problems.add('gap at ${start.toInt()} is ${w.toInt()} wide, outside '
          '${_gapMin.toInt()}-${_gapMax.toInt()}');
    }
    if (i >= 1 && spans[i].width < _minGroundBetweenGaps) {
      problems.add('only ${spans[i].width.toInt()} of ground before the gap at '
          '${start.toInt()}, need $_minGroundBetweenGaps');
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
    if (!level.isOverGround(a.x + _artifactSize / 2)) {
      problems.add('artifact at ${a.x.toInt()} is not over ground');
    }
  }

  // ── platforms ────────────────────────────────────────────────────────────
  for (final p in level.entities.where((e) => e.type == 'platform')) {
    final h = _groundSurfaceY - p.y;
    if (h < _platformMinHeight || h > _platformMaxHeight) {
      problems.add('platform at ${p.x.toInt()} is $h above ground, outside '
          '${_platformMinHeight.toInt()}-${_platformMaxHeight.toInt()}');
    }
    if (p.width % _platformTile != 0) {
      problems.add('platform at ${p.x.toInt()} is ${p.width} wide, not a multiple of 24');
    }
    if (!gaps.any((g) => p.x < g.end && p.x + p.width > g.start)) {
      problems.add('platform at ${p.x.toInt()} is not over a gap');
    }
  }

  // ── enemies ──────────────────────────────────────────────────────────────
  final enemies = level.entities.where((e) => e.type == 'enemy').toList()
    ..sort((a, b) => a.x.compareTo(b.x));
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
      for (final a in artifacts) {
        final distance = [left - (a.x + _artifactSize), a.x - right, 0.0]
            .reduce((x, y) => x > y ? x : y);
        if (distance < _artifactClearance) {
          problems.add('enemy at ${e.x.toInt()} patrols within '
              '${distance.toInt()} of the artifact at ${a.x.toInt()}, '
              'a student would be hit as the question closes');
        }
      }
      for (final g in gaps) {
        if (level.enemyIsOnPlatform(e)) continue; // a fight is over its gap
        final distance = [g.start - right, left - g.end, 0.0]
            .reduce((x, y) => x > y ? x : y);
        if (distance < _enemyGapClearance) {
          problems.add('enemy at ${e.x.toInt()} patrols within '
              '${distance.toInt()} of the gap at ${g.start.toInt()}, '
              'a student would be hit on landing');
        }
      }
    }

    if (!gaps.any((g) => g.end - g.start > _gapMax)) {
      problems.add('the level has no platform fight');
    }

    // Every section has a gap with a platform and an enemy.
    final platforms = level.entities.where((e) => e.type == 'platform').toList();
    for (var s = 0; s < _groups; s++) {
      final from = _safeStart + s * _groupWidth;
      final to = from + _groupWidth;
      final hasGap = gaps.any((g) =>
          g.start >= from &&
          g.start < to &&
          platforms.any((p) => p.x < g.end && p.x + p.width > g.start));
      if (!hasGap) problems.add('section ${s + 1} has no gap with a platform');
      if (!enemies.any((e) => e.x >= from && e.x < to)) {
        problems.add('section ${s + 1} has no enemy');
      }
    }
  }

  return problems;
}

/// The rules for one platform-fight gap (a gap wider than ${_gapMax.toInt()}).
List<String> _lintFight(LoadedLevel level, double start, double end,
    {required bool generated}) {
  final problems = <String>[];
  final w = end - start;
  final at = start.toInt();
  if (!_fightGaps.contains(w)) {
    problems.add('gap at $at is ${w.toInt()} wide, outside '
        '${_gapMin.toInt()}-${_gapMax.toInt()} and not a fight gap ($_fightGaps)');
    return problems;
  }
  if (w <= _longestJump) {
    problems.add('fight gap at $at can be jumped, so the platform is not required');
  }
  final over = level.entities
      .where((e) => e.type == 'platform' && e.x < end && e.x + e.width > start)
      .toList();
  if (over.length != 1) {
    problems.add('fight gap at $at has ${over.length} platforms, expected 1');
    return problems;
  }
  final p = over.single;
  if (p.width < _fightPlatformWidth) {
    problems.add('fight platform at ${p.x.toInt()} is ${p.width.toInt()} wide, '
        'under ${_fightPlatformWidth.toInt()}');
  }
  final before = p.x - start, after = end - (p.x + p.width);
  if (before < 0 || after < 0 || before > _fightLedgeMax || after > _fightLedgeMax) {
    problems.add('fight platform at ${p.x.toInt()} is ${before.toInt()} and '
        '${after.toInt()} from the ledges, outside 0-${_fightLedgeMax.toInt()}');
  }
  final guards = level.entities
      .where((e) =>
          e.type == 'enemy' &&
          level.enemyIsOnPlatform(e) &&
          (e.y - p.y).abs() < 1 &&
          e.x >= p.x &&
          e.x + _enemyWidth <= p.x + p.width)
      .toList();
  if (guards.length != 1) {
    problems.add('fight platform at ${p.x.toInt()} has ${guards.length} '
        'enemies, expected 1');
  } else if (guards.single.behavior == 'heavy') {
    problems.add('the enemy on the platform at ${p.x.toInt()} is a heavy');
  }
  if (generated && start < _safeStart + _fightFirstSection * _groupWidth) {
    problems.add('fight at $at is in the first sections');
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

  // The lint is only worth trusting if it can fail. Each case breaks one rule
  // in the hand-built fixture and expects the matching complaint.
  group('the lint catches a broken level', () {
    final base = File('test/fixtures/hand_built_level.tmx').readAsStringSync();

    List<String> lint(String xml, {int era = 1}) =>
        lintLevel(xml, eraNumber: era, levelIndex: 1);

    test('the unmodified reference level is clean', () {
      expect(lint(base), isEmpty);
    });

    test('a platform too high to jump onto', () {
      final bad = base.replaceFirst('y="552" width="96"', 'y="500" width="96"');
      expect(lint(bad), contains(predicate<String>((s) => s.contains('platform'))));
    });

    test('a platform low enough for an enemy to reach', () {
      final bad = base.replaceFirst('y="552" width="96"', 'y="570" width="96"');
      expect(lint(bad), contains(predicate<String>((s) => s.contains('platform'))));
    });

    test('a missing artifact', () {
      final bad = base.replaceFirst(
        RegExp(r'<object id="5" type="artifact"[\s\S]*?</object>'),
        '',
      );
      expect(lint(bad), contains(predicate<String>((s) => s.contains('9 artifacts'))));
    });

    test('a Heavy enemy in an era with no Heavy art', () {
      final bad = base.replaceFirst('name="kind" value="tribal_warrior"',
          'name="kind" value="tank"');
      expect(lint(bad), contains(predicate<String>((s) => s.contains('tank'))));
    });

    test('a second gate', () {
      final bad = base.replaceFirst(
          '<object id="23"', '<object id="99" type="gate" x="1400" y="660"/>\n  <object id="23"');
      expect(lint(bad), contains(predicate<String>((s) => s.contains('2 gates'))));
    });

    test('an enemy standing in a gap', () {
      final bad = base.replaceFirst('<object id="6" type="enemy" x="600"',
          '<object id="6" type="enemy" x="900"');
      expect(lint(bad), contains(predicate<String>((s) => s.contains('patrols off'))));
    });

    test('the wrong curriculum weeks', () {
      final bad = base.replaceFirst('name="weeks" value="1"', 'name="weeks" value="7"');
      expect(lint(bad), contains(predicate<String>((s) => s.contains('curriculum'))));
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

    test('a level with no platforms has no section with a gap to land on', () {
      final bad = base.replaceAll(
          RegExp(r'<object id="\d+" type="platform"[\s\S]*?</object>'), '');
      expect(lint(bad), complaint('section 1 has no gap with a platform'));
    });

    test('a fight whose platform has no enemy on it', () {
      // Spanish 3 has fights; move every platform enemy down onto the ground
      // far from any gap by deleting the objects whose y is above the ground.
      final bad = base.replaceAll(
          RegExp(r'<object id="\d+" type="enemy" x="[\d.]+" y="(?!660")[\d.]+">[\s\S]*?</object>'),
          '');
      expect(lint(bad), complaint('has 0 enemies, expected 1'));
    });

    test('a fight platform too narrow to hold its enemy', () {
      // The only 240-wide platforms are the fight platforms.
      final bad = base.replaceFirst('width="240"', 'width="96"');
      expect(lint(bad), complaint('under 240'));
    });

    test('an enemy right at a ledge', () {
      final level = LevelLoader.parse(base);
      final gapStart = level.groundSpans.first.startX + level.groundSpans.first.width;
      final enemy = level.entities.firstWhere((e) => e.type == 'enemy');
      // Move the first enemy so its patrol ends 40 short of the first gap.
      final x = gapStart - 40 - 90 - (enemy.patrol ?? 0);
      final bad = base.replaceFirstMapped(
        RegExp(r'(<object id="\d+" type="enemy" x=")[\d.]+'),
        (m) => '${m[1]}$x',
      );
      expect(lint(bad), complaint('of the gap at'));
    });
  });
}
