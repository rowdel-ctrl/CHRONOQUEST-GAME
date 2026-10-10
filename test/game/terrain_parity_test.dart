// The level generator plays every level before it keeps it (tools/levelgen/
// solve.js, on a JavaScript port of the player's movement in sim.js). That proof
// is only worth anything while the port behaves like the game. These tests play
// the same scripted moves, from test/fixtures/terrain_parity.json, through the
// real PlayerComponent and check it ends exactly where the port did: walking up
// a one-tile step, stopping at a wall, jumping onto a mesa, crossing a pit.
//
// If one fails after a change to movement or ground contact, run
// `node tools/levelgen/parity.js` to see what the port now does, fix whichever
// side is wrong, and regenerate the levels.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'terrain_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixture =
      jsonDecode(File('test/fixtures/terrain_parity.json').readAsStringSync())
          as Map<String, dynamic>;

  for (final raw in fixture['scenarios'] as List) {
    final sc = raw as Map<String, dynamic>;
    test(sc['name'] as String, () async {
      Surface surface(List<dynamic> v) => (
            start: (v[0] as num).toDouble(),
            end: (v[1] as num).toDouble(),
            top: (v[2] as num).toDouble(),
          );
      final game = await terrainGame(
        ground: [for (final g in sc['ground'] as List) surface(g as List)],
        platforms: [for (final p in sc['platforms'] as List) surface(p as List)],
      );
      standAt(game, ((sc['start'] as Map)['x'] as num).toDouble());

      var fell = false;
      for (final f in sc['frames'] as List) {
        final frame = f as List;
        if (playFrame(game, (frame[0] as num).toDouble(), frame[1] == 1)) {
          fell = true;
          break;
        }
      }

      final expected = sc['expect'] as Map<String, dynamic>;
      expect(fell, expected['fell'], reason: 'fell out of the level');
      if (fell) return; // a respawn moves the player; only the fall is compared
      expect(game.player.position.x, closeTo((expected['x'] as num).toDouble(), 0.01));
      expect(game.player.position.y, closeTo((expected['y'] as num).toDouble(), 0.01));
      expect(game.player.isOnGround, expected['onGround']);
    });
  }
}
