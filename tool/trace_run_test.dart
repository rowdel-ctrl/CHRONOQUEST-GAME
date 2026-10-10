// Development tool: replays one level's winning run (test/fixtures/level_paths.json)
// through the real PlayerComponent and prints where the player is every N frames,
// to compare against tools/levelgen/sim.js when the two disagree.
//
//   flutter test tool/trace_run_test.dart --dart-define=TRACE_LEVEL=era5_4
import 'dart:convert';
import 'dart:io';

import 'package:chronoquest/game/level_loader.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/game/terrain_harness.dart';

const _level = String.fromEnvironment('TRACE_LEVEL');
const _every = int.fromEnvironment('TRACE_EVERY', defaultValue: 200);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('trace', () async {
    if (_level.isEmpty) return;
    final paths = jsonDecode(File('test/fixtures/level_paths.json').readAsStringSync())
        as Map<String, dynamic>;
    final run = (paths['levels'] as Map<String, dynamic>)[_level] as Map<String, dynamic>;
    // ignore: invalid_use_of_visible_for_testing_member
    final level = LevelLoader.parse(File('assets/tiles/levels/$_level.tmx').readAsStringSync());
    final game = await terrainGame(
      ground: [for (final b in level.groundBlocks) (start: b.startX, end: b.endX, top: b.topY)],
      platforms: [
        for (final p in level.entities.where((e) => e.type == 'platform'))
          (start: p.x, end: p.x + p.width, top: p.y),
      ],
    );
    standAt(game, level.spawnX);
    var f = 0;
    for (final seg in run['frames'] as List) {
      final h = ((seg as List)[0] as num).toDouble();
      for (var i = 0; i < (seg[2] as int); i++) {
        final fell = playFrame(game, h, seg[1] == 1 && i == 0);
        f++;
        if (f % _every == 0 || fell) {
          // ignore: avoid_print
          print('$f,${game.player.position.x.toStringAsFixed(1)},'
              '${game.player.position.y.toStringAsFixed(1)},${game.player.isOnGround}');
        }
        if (fell) return;
      }
    }
  });
}
