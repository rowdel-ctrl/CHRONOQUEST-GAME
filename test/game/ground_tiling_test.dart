// GroundSection draws the level's ground from the same 16px tileset as the
// floating platforms. The initial section spans the whole level (a million
// world units), so render() must only draw the tiles under the camera —
// these tests pin that range down, since both failure modes are easy to
// introduce and hard to spot: clamping too wide silently costs tens of
// thousands of draw calls per frame, clamping too tight leaves a visible
// strip of missing ground at the edge of the screen.
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/components/gap_component.dart';

const double _tile = GroundSection.tileSize;

void main() {
  group('GroundSection.visibleTileRange', () {
    test('covers the camera window and nothing beyond it', () {
      // A 1280-wide camera sitting at local x=0 needs 1280/16 = 80 tiles,
      // plus the one straddling the right edge.
      final range = GroundSection.visibleTileRange(
        localLeft: 0,
        localRight: 1280,
        sectionWidth: 1000000,
      );

      expect(range.first, 0);
      expect(range.last, 81);
    });

    test('draws only a screenful, not the whole million-unit section', () {
      final range = GroundSection.visibleTileRange(
        localLeft: 500000,
        localRight: 500000 + 1280,
        sectionWidth: 1000000,
      );

      // The cost that matters is the tile count, not where the window sits.
      expect(range.last - range.first, lessThan(200));
    });

    test('includes the partially visible tile at each edge', () {
      // Camera edges deliberately land mid-tile: 100 is 6.25 tiles, formerly
      // a source of a 1-tile gap at the screen edge.
      final range = GroundSection.visibleTileRange(
        localLeft: 100,
        localRight: 300,
        sectionWidth: 1000000,
      );

      // floor(6.25) = 6 starts at world 96, left of the camera edge.
      expect(range.first, 6);
      // ceil(18.75) + 1 = 20 ends at world 320, right of the camera edge.
      expect(range.last, 20);
      expect(range.first * _tile, lessThanOrEqualTo(100));
      expect(range.last * _tile, greaterThanOrEqualTo(300));
    });

    test('never asks for a tile left of the section start', () {
      // The camera's left edge begins at -playerX, so early frames query a
      // negative local x. A negative index would read off the sheet.
      final range = GroundSection.visibleTileRange(
        localLeft: -240,
        localRight: 640,
        sectionWidth: 1000000,
      );

      expect(range.first, 0);
    });

    test('never runs past the end of a short section', () {
      final range = GroundSection.visibleTileRange(
        localLeft: 0,
        localRight: 1280,
        sectionWidth: 160, // 10 tiles
      );

      expect(range.last, 10);
    });
  });

  group('GroundSpawner', () {
    test('starts the ground left of world x=0, where the camera opens', () {
      // cameraLeftEdgeX is player.worldX - playerX, so it begins negative;
      // ground starting at 0 would leave a strip of empty background under
      // the player on the first frames.
      expect(GroundSpawner.startX, lessThan(-GameConstants.playerX));
    });
  });

  group('GroundSection.bandHeight', () {
    test('matches the offset ChronoGame.groundY uses for the surface', () {
      // groundY is size.y - bandHeight; if these drift apart the player
      // walks above or inside the drawn ground.
      expect(GroundSection.bandHeight, 60);
    });
  });

  group('GroundSection.capHeight', () {
    test('crops above the tile row where the art goes flat', () {
      // Rows 9-15 of tile (0,1) are a solid (39,32,52) fill. Drawing them
      // is what made the ground read as a void, so the cap has to stop
      // before row 9 — and has to stay inside the source tile.
      expect(GroundSection.capHeight, lessThanOrEqualTo(9));
      expect(GroundSection.capHeight, lessThan(GroundSection.tileSize));
      expect(GroundSection.capHeight, greaterThan(0));
    });

    test('leaves a body for the era colour to fill', () {
      expect(GroundSection.capHeight, lessThan(GroundSection.bandHeight));
    });
  });
}
