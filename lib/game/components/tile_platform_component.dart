import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import '../chrono_game.dart';

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
  static const double tileSize = 16;

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
    size = Vector2(widthInTiles * tileSize, tileSize * 2);
    if (spawnPosition != null) {
      position = spawnPosition;
    }
  }

  @override
  Future<void> onLoad() async {
    final tileset = await game.loadSprite('tiles/ground_tileset.png');
    _sheet = SpriteSheet(image: tileset.image, srcSize: Vector2.all(tileSize));

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

  @override
  void update(double dt) {
    super.update(dt);
    if (position.x < game.cameraLeftEdgeX - size.x) {
      removeFromParent();
    }
  }

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
        size: Vector2.all(tileSize),
        overridePaint: _tilePaint,
      );
    }
  }
}
