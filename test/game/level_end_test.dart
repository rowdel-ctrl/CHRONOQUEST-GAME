// Phase 4: a level ends at its authored Tiled `exit` object rather than at
// the global `CombatConstants.lengthUnitsDefault` placeholder
// (GAMEPLAY-V2.md Section 11).
//
// `Level.lengthUnits` was explicitly documented as a placeholder "Phase 4's
// Tiled `exit` object replaces". These tests pin that swap, and that the
// pre-Phase-4 fallback still applies to the 42 levels with no map yet.
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/level_loader.dart';

ChronoGame _game() {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('levelEndX', () {
    test('falls back to Level.lengthUnits when no map is authored', () {
      final game = _game()
        ..currentEra = 'spanish'
        ..currentLevel = 2;

      expect(game.tiledLevel, isNull);
      expect(game.levelEndX, CombatConstants.lengthUnitsDefault);
    });

    test('uses the authored exit once a Tiled level is loaded', () {
      final game = _game();
      game.tiledLevel = LevelLoader.parse(
        File('test/fixtures/hand_built_level.tmx').readAsStringSync(),
      );

      expect(game.levelEndX, 3140);
      expect(
        game.levelEndX,
        isNot(CombatConstants.lengthUnitsDefault),
        reason: 'an authored level must not silently keep using the '
            'procedural placeholder length',
      );
    });

    test('the authored exit is much shorter than the placeholder default', () {
      // The 25000-unit default was tuned to make the *procedural* spawner
      // produce a ~2-minute level. An authored level is paced by what the
      // author placed, so it has no reason to match that number — and if a
      // map ever did, it would be a sign the exit had not been read.
      final level = LevelLoader.parse(
        File('test/fixtures/hand_built_level.tmx').readAsStringSync(),
      );
      expect(level.exitX, lessThan(CombatConstants.lengthUnitsDefault));
    });
  });

  group('LevelLoader.authored manifest', () {
    test('lists the first level', () {
      expect(LevelLoader.exists(1, 1), isTrue);
    });

    test('does not claim levels that have no .tmx yet', () {
      // The generator adds entries here as it writes files; until then the
      // game must fall back to the spawner rather than try to load a file
      // that is not there. A level past the last of its era is not one.
      expect(LevelLoader.exists(6, 6), isFalse);
      expect(LevelLoader.exists(2, 6), isFalse);
      expect(LevelLoader.exists(1, 11), isFalse);
    });

    test('every boss level has an arena', () {
      for (var e = 1; e <= allEras.length; e++) {
        expect(LevelLoader.exists(e, allEras[e - 1].levels.length), isTrue,
            reason: 'era $e has no boss arena');
      }
    });

    test('every authored entry has a real file on disk', () {
      for (final (era, level) in LevelLoader.authored) {
        final path = LevelLoader.assetPathFor(era, level);
        expect(File(path).existsSync(), isTrue,
            reason: '$path is in the authored manifest but missing on disk');
      }
    });

    test('every authored entry is also declared in pubspec assets', () {
      // A .tmx that exists on disk but is not bundled loads fine in tests
      // (which read the filesystem) and fails at runtime (which reads the
      // asset bundle) — the exact kind of gap that only shows up on device.
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('assets/tiles/levels/'));
    });
  });
}
