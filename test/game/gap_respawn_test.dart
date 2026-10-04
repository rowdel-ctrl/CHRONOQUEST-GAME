// Phase 4 gap handling (GAMEPLAY-V2.md Section 11 / the Phase 4 prompt):
// "falling in a gap costs 1 HP and respawns on the last solid ground you
// stood on".
//
// This behaviour is genuinely new, not a port. Before Phase 4 the ground was
// a single unbroken 1,000,000-unit slab laid by GroundSpawner, so a "gap"
// could not exist and `respawn()` deliberately kept worldX — the player had
// fallen off the bottom of the screen, not into anything. Tiled levels have
// real gaps, so respawning in place would drop the player straight back down
// the same hole and drain the whole heart pool in seconds.
//
// These tests cover the anchor bookkeeping rather than driving a full
// `respawn()`: that call ends by assigning `walkAnimation`, a `late` field
// only set in `onLoad()` from real sprite assets, which a bare headless game
// cannot load. The anchor *is* the new logic — where a fall puts you — so it
// is what is pinned here; the animation swap is unchanged from Phase 1.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/level_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('respawn anchor', () {
    test('defaults to the player start offset before any ground contact', () {
      // So a fall that happens before the player has ever touched ground
      // still has somewhere valid to go.
      final player = PlayerComponent(characterId: 'rizal');
      expect(player.respawnAnchorX, GameConstants.playerX);
    });

    test('is settable, which is how the level loader seeds it from `spawn`',
        () {
      final player = PlayerComponent(characterId: 'rizal');
      player.respawnAnchorX = 1234;
      expect(player.respawnAnchorX, 1234);
    });
  });

  group('authored levels seed the anchor from the spawn object', () {
    test('era1_1 spawn position matches what the loader reports', () {
      // The loader puts the player at `spawnX` and sets the anchor to the
      // same value (see GameSpawning._buildTiledLevel), so a fall before the
      // first ground contact returns the player to the level start rather
      // than to a hardcoded default that may sit over a gap.
      final tmx =
          // ignore: avoid_slow_async_io
          _readReference();
      final level = LevelLoader.parse(tmx);
      expect(level.spawnX, 220);
      expect(level.isOverGround(level.spawnX), isTrue,
          reason: 'the anchor the loader seeds must itself be solid ground');
    });
  });

  group('gap geometry in the reference level', () {
    late LoadedLevel level;
    setUp(() => level = LevelLoader.parse(_readReference()));

    test('has at least one real gap to fall into', () {
      expect(level.groundSpans.length, greaterThan(1));
    });

    test('every gap has solid ground before it to anchor onto', () {
      for (var i = 1; i < level.groundSpans.length; i++) {
        final previous = level.groundSpans[i - 1];
        expect(previous.width, greaterThan(0),
            reason: 'a gap with no solid ground before it would leave a '
                'falling player with no valid anchor');
      }
    });

    test('a point inside a gap is not over ground', () {
      final first = level.groundSpans.first;
      final insideGap = first.startX + first.width + 8;
      expect(level.isOverGround(insideGap), isFalse);
    });
  });
}

String _readReference() =>
    File('test/fixtures/hand_built_level.tmx').readAsStringSync();
