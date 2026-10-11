// Every level can be finished, on the game's own code.
//
// tools/levelgen/paths.js finds a winning run for each level (the stick and the
// jump button, frame by frame) and saves it to test/fixtures/level_paths.json.
// This loads each level exactly as the game does (LevelLoader), builds its
// ground and platforms, and plays that run through the real PlayerComponent. The
// player must reach the end gate without falling once. It does not look at
// enemies: those are rules about placement (level_lint_test.dart), not movement.
//
// This is what catches the loader and the generator disagreeing about the ground
// (a layer offset, a block boundary), and the player's wall and landing rules
// changing under a level that was built for the old ones.
import 'dart:convert';
import 'dart:io';

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/level_loader.dart';
import 'package:flutter_test/flutter_test.dart';

import 'terrain_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final paths =
      jsonDecode(File('test/fixtures/level_paths.json').readAsStringSync())
          as Map<String, dynamic>;
  final levels = paths['levels'] as Map<String, dynamic>;

  test('there is a winning run for every generated level', () {
    final names = {
      for (final (e, l) in generatedLevelNames()) 'era${e}_$l',
    };
    expect(levels.keys.toSet(), names,
        reason: 'run `node tools/levelgen/paths.js` after generating levels');
  });

  for (final entry in levels.entries) {
    test('${entry.key}: the winning run reaches the end gate', () async {
      final xml = File('assets/tiles/levels/${entry.key}.tmx').readAsStringSync();
      final level = LevelLoader.parse(xml);
      final game = await terrainGame(
        ground: [
          for (final b in level.groundBlocks)
            (start: b.startX, end: b.endX, top: b.topY),
        ],
        platforms: [
          for (final p in level.entities.where((e) => e.type == 'platform'))
            (start: p.x, end: p.x + p.width, top: p.y),
        ],
      );
      standAt(game, level.spawnX);

      final run = entry.value as Map<String, dynamic>;
      var played = 0;
      for (final seg in run['frames'] as List) {
        final h = ((seg as List)[0] as num).toDouble();
        final jump = seg[1] == 1;
        final count = seg[2] as int;
        for (var i = 0; i < count; i++) {
          final fell = playFrame(game, h, jump && i == 0);
          played++;
          if (fell) {
            fail('fell at x=${game.player.position.x.toStringAsFixed(0)} '
                'after $played frames');
          }
        }
      }
      expect(game.player.position.x,
          greaterThanOrEqualTo((run['goalX'] as num).toDouble() - 1),
          reason: 'the run should end at the gate');
    });
  }
}

/// The levels the generator wrote, from the manifest the game itself reads.
/// The levels with a start and an end to run between: every authored level but
/// the boss arenas, which are one room with no gate (see boss_arena_test.dart).
Iterable<(int, int)> generatedLevelNames() => LevelLoader.authored
    .where((l) => l.$2 < allEras[l.$1 - 1].levels.length);

