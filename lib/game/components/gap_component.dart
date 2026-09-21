import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../chrono_game.dart';

/// A section of ground at a fixed world position: the grass cap from the
/// same 16px tileset the floating platforms use, over a flat per-era body.
///
/// The tileset has no dirt tile — every fill tile in it is near-black purple
/// (39,32,52) — so tiling the full 60px band made the ground read as a void
/// and flattened all five eras to the same colour. Only the lit cap is
/// tiled; the body below it stays era-coloured.
///
/// Gaps are created by NOT placing a GroundSection in a stretch — when the
/// player falls through, they lose a heart and respawn. The section itself
/// doesn't move; the camera moving past it as the player advances creates
/// the on-screen leftward motion.
class GroundSection extends PositionComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  /// Matches TilePlatformComponent.tileSize — both read the same sheet.
  static const double tileSize = 16;

  /// Height of the ground band. Matches ChronoGame.groundY, which puts the
  /// ground surface exactly this far above the bottom of the screen.
  static const double bandHeight = 60;

  /// How much of the top tile is drawn. Rows 0-8 of tile (0,1) are the grass
  /// and the lit soil edge beneath it; from row 9 down the tile is flat
  /// (39,32,52) fill, which is exactly the colour that made the fully tiled
  /// ground look like a hole. Cropping here keeps the art and drops the void.
  static const double capHeight = 9;

  /// Grid coordinates (row, col) into ground_tileset.png, 0-indexed from the
  /// top-left: (0,1) is the plain grass top, the same cap the platforms use.
  static const int _topRow = 0, _topCol = 1;

  /// Body colour under the cap, per era — carried over from the flat ground
  /// this replaced, so the eras stay visually distinct.
  static const Map<String, Color> _bodyColors = {
    'pre-colonial': Color(0xFF5D4E37),
    'spanish': Color(0xFF808080),
    'american': Color(0xFF8B6914),
    'ww2': Color(0xFF4A4A3A),
    'modern': Color(0xFF555555),
  };

  final double sectionWidth;

  late final Sprite _capTile;

  /// Tiles are drawn one by one at fractional world positions (the camera
  /// follows the player smoothly). With anti-aliasing/filtering on, each
  /// tile's edge blends with what's behind it and leaves faint seams — same
  /// fix, and same reason, as TilePlatformComponent.
  final Paint _tilePaint = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;

  GroundSection({
    required this.sectionWidth,
    required Vector2 sectionPosition,
  }) {
    position = sectionPosition;
  }

  Color get _bodyColor =>
      _bodyColors[game.currentEra] ?? const Color(0xFF5D4E37);

  @override
  Future<void> onLoad() async {
    final tileset = await game.loadSprite('tiles/ground_tileset.png');
    _capTile = Sprite(
      tileset.image,
      srcPosition: Vector2(_topCol * tileSize, _topRow * tileSize),
      srcSize: Vector2(tileSize, capHeight),
    );
    size = Vector2(sectionWidth, bandHeight);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (position.x + sectionWidth < game.cameraLeftEdgeX) {
      removeFromParent();
    }
  }

  @override
  void onMount() {
    super.onMount();
    game.groundSections.add(this);
  }

  @override
  void onRemove() {
    game.groundSections.remove(this);
    super.onRemove();
  }

  /// Half-open tile index range [first, last) to draw for a camera window,
  /// in this component's local coordinates. A section spans the whole level
  /// (see GroundSpawner), so looping its full width would be tens of
  /// thousands of draw calls every frame; clamping too tightly instead
  /// leaves a visible hole at the edge of the screen. Static so the range
  /// can be tested without loading the tileset.
  static ({int first, int last}) visibleTileRange({
    required double localLeft,
    required double localRight,
    required double sectionWidth,
  }) {
    return (
      first: max(0, (localLeft / tileSize).floor()),
      // +1 so a tile straddling the right edge is still drawn.
      last: min(
        (sectionWidth / tileSize).ceil(),
        (localRight / tileSize).ceil() + 1,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final range = visibleTileRange(
      localLeft: game.cameraLeftEdgeX - position.x,
      localRight: game.cameraRightEdgeX - position.x,
      sectionWidth: sectionWidth,
    );
    if (range.last <= range.first) return;

    // Body first, as one rect across the visible span rather than per tile.
    canvas.drawRect(
      Rect.fromLTRB(
        range.first * tileSize,
        capHeight,
        range.last * tileSize,
        bandHeight,
      ),
      Paint()..color = _bodyColor,
    );

    for (int i = range.first; i < range.last; i++) {
      _capTile.render(
        canvas,
        position: Vector2(i * tileSize, 0),
        size: Vector2(tileSize, capHeight),
        overridePaint: _tilePaint,
      );
    }
  }
}

/// Spawns ground sections with gaps between them.
class GroundSpawner {
  final ChronoGame game;

  GroundSpawner({required this.game});

  /// Where the level's ground starts, in world x. The camera's left edge
  /// begins at -GameConstants.playerX, so the ground has to extend left of
  /// world x=0 or the opening frames show a strip of empty background under
  /// the player.
  static const double startX = -GameConstants.playerX - 120;

  void spawnInitialGround() {
    final section = GroundSection(
      sectionWidth: 1000000,
      sectionPosition: Vector2(startX, game.groundY),
    );
    game.world.add(section);
  }

  void update(double dt) {}
}
