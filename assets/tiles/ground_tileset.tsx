<?xml version="1.0" encoding="UTF-8"?>
<!--
  ChronoQuest ground tileset (GAMEPLAY-V2.md Section 11).

  Wraps the same assets/tiles/ground_tileset.png that GroundSection and
  TilePlatformComponent already read by hand-coded (row, col) constants.
  Section 11's caveat 1 calls those constants "pixel-verified correct" and
  says moving to Tiled means setting the sheet up once here instead — this
  file is that one-time setup.

  Geometry: 112x128 px, 16px tiles, 7 columns x 8 rows = 56 tiles.
  Tiled GIDs are 1-based in row-major order, so the grass cap the existing
  code calls (row 0, col 1) is firstgid + 1 = GID 2 in a map whose first
  tileset starts at 1.
-->
<tileset version="1.10" tiledversion="1.10.2" name="ground_tileset" tilewidth="16" tileheight="16" tilecount="56" columns="7">
 <image source="ground_tileset.png" width="112" height="128"/>
</tileset>
