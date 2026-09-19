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
  // the top-left. These are a best-effort reading of the reference art —
  // open the actual PNG in an image viewer (16px grid, 7 cols x 8 rows,
  // 0-indexed) and adjust these four if a tile looks wrong once it's
  // rendering in the game.
  static const int _topLeftRow = 0, _topLeftCol = 1;
  static const int _topMidRow = 0, _topMidCol = 2;
  static const int _topRightRow = 0, _topRightCol = 5;
  static const int _fillRow = 1, _fillCol = 2;

  /// How many tiles wide this platform is.
  final int widthInTiles;

  /// World y-coordinate of the platform's top surface, i.e. where the
  /// player's feet land — not the component's top-left render position.
  final double surfaceY;

  late final SpriteSheet _sheet;

  TilePlatformComponent({
    required this.widthInTiles,
    required this.surfaceY,
    Vector2? spawnPosition,
  }) {
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
      );

      final fillTile = _sheet.getSprite(_fillRow, _fillCol);
      fillTile.render(
        canvas,
        position: Vector2(i * tileSize, tileSize),
        size: Vector2.all(tileSize),
      );
    }
  }
}
