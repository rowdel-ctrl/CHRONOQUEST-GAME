// Which picture an artifact wears: era + a number 1..10 (60 icons).
import 'dart:io';

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/level_loader.dart';
import 'package:chronoquest/models/artifact_art.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every era has all ten icon files', () {
    for (final era in allEras) {
      for (var i = 1; i <= 10; i++) {
        final path = artifactAsset(era.id, i);
        expect(path, 'assets/collectibles/artifact_${era.id}_$i.png');
        expect(File(path).existsSync(), isTrue, reason: '$path is missing');
      }
    }
  });

  test('the era list used for the icons matches the game eras', () {
    expect(artifactEraIds, allEras.map((e) => e.id).toList());
  });

  test('the old generic pictures are still there (HUD, boss scroll)', () {
    for (var i = 1; i <= 5; i++) {
      expect(File('assets/collectibles/artifact_$i.png').existsSync(), isTrue);
    }
  });

  test('an index outside 1..10 becomes 1', () {
    expect(artifactAsset('spanish', 0),
        'assets/collectibles/artifact_spanish_1.png');
    expect(artifactAsset('spanish', 11),
        'assets/collectibles/artifact_spanish_1.png');
    expect(artifactAsset('spanish', -3),
        'assets/collectibles/artifact_spanish_1.png');
    expect(artifactAsset('modern', 10),
        'assets/collectibles/artifact_modern_10.png');
  });

  test('an unknown era falls back to the old generic picture, which exists',
      () {
    for (var i = 1; i <= 10; i++) {
      final path = artifactAsset('atlantis', i);
      expect(path, 'assets/collectibles/artifact_${((i - 1) % 5) + 1}.png');
      expect(File(path).existsSync(), isTrue, reason: '$path is missing');
    }
  });

  test('the Flame key is the asset path without the assets/ folder', () {
    expect(artifactImageKey('ww2', 4), 'collectibles/artifact_ww2_4.png');
  });

  group('map art property', () {
    test('old maps (art 1-5) show icons 1-5 for the first five artifacts', () {
      for (var n = 1; n <= 5; n++) {
        expect(LevelBuilder.artifactIconFor('artifact_$n', 0), n);
        expect(LevelBuilder.artifactIconFor('artifact_$n', 4), n);
      }
    });

    test('the second five artifacts of a level show icons 6-10', () {
      for (var n = 1; n <= 5; n++) {
        expect(LevelBuilder.artifactIconFor('artifact_$n', 5), n + 5);
        expect(LevelBuilder.artifactIconFor('artifact_$n', 9), n + 5);
      }
    });

    test('a generated level (offset cycle of 1-5 twice) uses all ten icons',
        () {
      for (var offset = 0; offset < 5; offset++) {
        final icons = {
          for (var k = 0; k < 10; k++)
            LevelBuilder.artifactIconFor(
                'artifact_${((k + offset) % 5) + 1}', k),
        };
        expect(icons, {for (var i = 1; i <= 10; i++) i});
      }
    });

    test('art 6-10 is taken as it is; junk becomes 1', () {
      expect(LevelBuilder.artifactIconFor('artifact_8', 0), 8);
      expect(LevelBuilder.artifactIconFor('artifact_10', 7), 10);
      expect(LevelBuilder.artifactIconFor('artifact_11', 0), 1);
      expect(LevelBuilder.artifactIconFor(null, 3), 1);
      expect(LevelBuilder.artifactIconFor('nope', 3), 1);
    });
  });
}
