import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import '../chrono_game.dart';
import 'terrain_component.dart' show EraTerrain;

/// Floating platform built from slices of the 16x16 ground tileset
/// (ground_tileset.png — a 7-column x 8-row grid of 16px tiles). Renders a
/// left-edge tile, repeated mid tiles, and a right-edge tile across the top
/// row, with a fill tile underneath for thickness.
///
/// Spawns at a fixed world position ahead of the camera and stays there;
/// the camera moving past it creates the on-screen leftward motion — same
/// pattern as WallComponent/GroundSection.
class TilePlatformComponent extends PositionComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  /// On-screen size of one tile. The source tiles are 16px (see
  /// [_sheet]'s srcSize); drawing them 1.5x larger puts platforms in the
  /// same visual register as the 96x120 player and 90x108 enemies instead
  /// of leaving a 3-tile platform narrower than the player standing on it.
  /// Both the component's `size` and its hitbox derive from this, and the
  /// landing plane is [surfaceY] — so platforms get wider and thicker, but
  /// none of them move, and no jump gets harder to make.
  static const double tileSize = 24;

  /// Size of one tile in the source sheet, which is unchanged — the sheet
  /// is still a grid of 16px tiles, they are just drawn larger.
  static const double sourceTileSize = 16;

  /// How far the underside hangs below the grass cap.
  ///
  /// A platform is anchored by its TOP edge (`position.y` == [surfaceY],
  /// which is where the player's feet land), so all of its thickness hangs
  /// downward, into the gap between the platform and the ground. Drawing
  /// the underside as a second full tile made that thickness 2 x [tileSize]
  /// = 48: at the lowest spawn height (60 above the ground) it left only
  /// 12 units of air underneath, so the platform read as a block resting on
  /// the floor that you walk into sideways, rather than a ledge you jump
  /// onto. This keeps total thickness at the 32 it was before the tiles
  /// were scaled up, so scaling made platforms wider and chunkier without
  /// ever reaching further down. The fill tile it crops is flat colour,
  /// so cropping it is invisible.
  static const double undersideHeight = 8;

  /// Top of the grass cap to the bottom of the underside.
  static const double thickness = tileSize + undersideHeight;

  // Grid coordinates (row, column) into ground_tileset.png, 0-indexed from
  // the top-left. Uses the grass-topped dirt set in the top-left of the
  // sheet: (1,1)/(1,2) are the grass caps with left/right borders, (0,1) is
  // plain grass top, (1,4) is the plain dark fill. The fill row's ends use
  // the plain (no grass) wall tiles (1,3)/(1,5) so the orange side border
  // keeps running down instead of stopping after the top row.
  static const int _topLeftRow = 1, _topLeftCol = 1;
  static const int _topMidRow = 0, _topMidCol = 1;
  static const int _topRightRow = 1, _topRightCol = 2;
  static const int _fillLeftRow = 1, _fillLeftCol = 3;
  static const int _fillRow = 1, _fillCol = 4;
  static const int _fillRightRow = 1, _fillRightCol = 5;

  /// How many tiles wide this platform is.
  final int widthInTiles;

  /// World y-coordinate of the platform's top surface, i.e. where the
  /// player's feet land — not the component's top-left render position.
  final double surfaceY;

  late final SpriteSheet _sheet;

  /// Tiles are drawn one by one at fractional world positions (the camera
  /// follows the player smoothly). With anti-aliasing/filtering on, each
  /// tile's edge is blended with the background, leaving faint seams between
  /// tiles. Turning both off snaps neighbouring edges to the same pixel.
  final Paint _tilePaint = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;

  /// Drawn behind the player (whose priority is the default 0). Platforms are
  /// one-way — the player passes through from below — so the player has to
  /// render in front, or a platform spawned later would paint over them.
  static const int renderPriority = -1;

  TilePlatformComponent({
    required this.widthInTiles,
    required this.surfaceY,
    Vector2? spawnPosition,
  }) : super(priority: renderPriority) {
    size = Vector2(widthInTiles * tileSize, thickness);
    if (spawnPosition != null) {
      position = spawnPosition;
    }
  }

  @override
  Future<void> onLoad() async {
    // The era's own copy of the tileset, the one the terrain is drawn from, so a
    // platform and the ground beside it are made of the same earth.
    final tileset = await game.loadSprite(EraTerrain.sheetPath(game.currentEra));
    _sheet =
        SpriteSheet(image: tileset.image, srcSize: Vector2.all(sourceTileSize));

    if (position.isZero()) {
      position = Vector2(game.cameraRightEdgeX + 20, surfaceY);
    }
    add(RectangleHitbox());
  }

  @override
  void onMount() {
    super.onMount();
    game.platforms.add(this);
  }

  @override
  void onRemove() {
    game.platforms.remove(this);
    super.onRemove();
  }

  // No update() override: platforms are never culled behind the camera (see
  // level_culling.dart). Deleting one the player had already passed removed
  // it from `game.platforms` too, so backtracking onto a ledge dropped the
  // player straight through where it used to be.

  @override
  void render(Canvas canvas) {
    for (int i = 0; i < widthInTiles; i++) {
      final Sprite topTile;
      if (i == 0) {
        topTile = _sheet.getSprite(_topLeftRow, _topLeftCol);
      } else if (i == widthInTiles - 1) {
        topTile = _sheet.getSprite(_topRightRow, _topRightCol);
      } else {
        topTile = _sheet.getSprite(_topMidRow, _topMidCol);
      }
      topTile.render(
        canvas,
        position: Vector2(i * tileSize, 0),
        size: Vector2.all(tileSize),
        overridePaint: _tilePaint,
      );

      final Sprite fillTile;
      if (i == 0) {
        fillTile = _sheet.getSprite(_fillLeftRow, _fillLeftCol);
      } else if (i == widthInTiles - 1) {
        fillTile = _sheet.getSprite(_fillRightRow, _fillRightCol);
      } else {
        fillTile = _sheet.getSprite(_fillRow, _fillCol);
      }
      fillTile.render(
        canvas,
        position: Vector2(i * tileSize, tileSize),
        size: Vector2(tileSize, undersideHeight),
        overridePaint: _tilePaint,
      );
    }
  }
}
