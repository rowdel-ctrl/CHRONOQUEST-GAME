<?xml version="1.0" encoding="UTF-8"?>
<!--
  ChronoQuest ground tileset (GAMEPLAY-V2.md Section 11).

  Wraps the same assets/tiles/ground_tileset.png that GroundSection and
  TilePlatformComponent already read by hand-coded (row, col) constants.
  Section 11's caveat 1 calls those constants "pixel-verified correct" and
  says moving to Tiled means setting the sheet up once here instead — this
  file is that one-time setup.

  Geometry: 112x128 px, 16px tiles, 7 columns x 8 rows = 56 tiles. The maps use a
  24-unit grid (the art drawn at 1.5x, like the platforms, enemies and player), so
  tilerendersize="grid" with fillmode="stretch" makes Tiled draw them that size.

  What is where: rows 0-1 are orange earth and rows 2-3 blue stone, each with grass
  caps (GIDs 2/9/10 and 16/17/23/24), bare caps (5/4/6 and 19/18/20), left and right
  walls (11/13 and 25/27) and fill (12; 8 and 22 have a speck). 37 is the water
  surface, 30 a crate, 29/36/43 a ladder, 31-49 the foliage and background tiles.
  tools/levelgen/terrain.js picks the right tile for every cell when it writes a map.
  Tiled GIDs are 1-based in row-major order, so the grass cap the existing
  code calls (row 0, col 1) is firstgid + 1 = GID 2 in a map whose first
  tileset starts at 1.
-->
<tileset version="1.10" tiledversion="1.10.2" name="ground_tileset" tilewidth="16" tileheight="16" tilecount="56" columns="7" tilerendersize="grid" fillmode="stretch">
 <image source="ground_tileset.png" width="112" height="128"/>
</tileset>
