import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../chrono_game.dart';
import '../level_loader.dart' show TerrainGrid;

/// What an era's ground is made of: which tileset image to draw and the colour
/// of the earth inside it.
///
/// The tileset has two sets of caps, edges and walls (orange earth in rows 0-1,
/// blue stone in rows 2-3) and a near-black fill. Painting the fill in one earth
/// colour per era is what keeps the six eras apart and stops the ground reading
/// as a black slab. The images are pre-made by tools/levelgen/recolor.js, which
/// holds the same colours: change one, change both.
class EraTerrain {
  const EraTerrain._();

  /// The earth colour inside the ground, per era.
  static const Map<String, Color> bodyColors = {
    'pre-colonial': Color(0xFF5D4E37), // brown earth
    'spanish': Color(0xFF6B7280), // slate stone
    'nationalism': Color(0xFF7A5A3E), // clay
    'american': Color(0xFF4F6B7A), // blue-grey
    'ww2': Color(0xFF4A4A3A), // olive
    'modern': Color(0xFF555860), // concrete
  };

  static Color bodyColor(String eraId) =>
      bodyColors[eraId] ?? bodyColors['pre-colonial']!;

  /// Asset path (under assets/) of the era's tileset image.
  static String sheetPath(String eraId) => bodyColors.containsKey(eraId)
      ? 'tiles/ground_$eraId.png'
      : 'tiles/ground_tileset.png';
}

/// Draws a Tiled level's `ground` layer: every cell the map holds, with the cap,
/// edge, wall or fill tile the map chose for it (GAMEPLAY-V2.md Section 11).
///
/// Collision does not come from here. The level builder makes one
/// `GroundSection` per block of ground for that, and this only paints, so what
/// the player sees is exactly the tile layer a person would see in Tiled.
///
/// Draws only the columns the camera can see, and all of them in one
/// `drawRawAtlas` call: a screen of ground is a couple of thousand tiles.
class TerrainComponent extends Component with HasGameReference<ChronoGame> {
  /// Behind platforms (-1), enemies and the player (0).
  static const int renderPriority = -2;

  /// Size of a tile in the source sheet.
  static const double sourceTile = 16;
  static const int sheetColumns = 7;

  /// The crate tile (GID 30) is a 12x12 box inside a 16x16 tile with a margin
  /// round it. It is drawn cropped to the box, so a pile of crates is solid.
  static const int crateGid = 30;
  static const double crateX = 3, crateY = 2, crateSize = 12;

  /// How far each tile is drawn past its cell, so neighbours overlap instead of
  /// leaving a hairline seam at fractional camera positions.
  static const double bleed = 0.5;

  /// Where the grass sits relative to the body fill: the fill starts this far
  /// below the surface, so the cap's rounded corners stay clear.
  static const double bodyInset = 6;

  final TerrainGrid grid;
  final String eraId;

  late final ui.Image _sheet;

  /// The first painted row of each column, or -1 for a pit.
  late final Int16List _topRow;

  final Paint _tilePaint = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;

  /// Darkens the earth towards the bottom of the screen, so tall ground has
  /// depth instead of one flat colour. A vertical gradient in world y, so one
  /// shader serves every stretch of ground.
  static final Paint _shade = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00000000), Color(0x59000000)],
    ).createShader(const Rect.fromLTWH(0, 380, 10, 340));

  Float32List _transforms = Float32List(0);
  Float32List _rects = Float32List(0);

  TerrainComponent({required this.grid, required this.eraId})
      : super(priority: renderPriority);

  @override
  Future<void> onLoad() async {
    _sheet = await game.images.load(EraTerrain.sheetPath(eraId));
    _topRow = Int16List(grid.cols);
    for (var c = 0; c < grid.cols; c++) {
      _topRow[c] = -1;
      for (var r = 0; r < grid.rows; r++) {
        if (grid.gidAt(c, r) != 0) {
          _topRow[c] = r;
          break;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final ts = grid.tileSize;
    final first = max(0, (game.cameraLeftEdgeX / ts).floor());
    final last = min(grid.cols, (game.cameraRightEdgeX / ts).ceil() + 1);
    if (last <= first) return;

    // The earth inside the ground, one rectangle per stretch of equal height.
    final body = Paint()..color = EraTerrain.bodyColor(eraId);
    final bottom = grid.originY + grid.rows * ts;
    final shades = <Rect>[];
    var runStart = first;
    for (var c = first + 1; c <= last; c++) {
      if (c < last && _topRow[c] == _topRow[runStart]) continue;
      final top = _topRow[runStart];
      if (top >= 0) {
        final rect = Rect.fromLTRB(
          runStart * ts,
          grid.originY + top * ts + bodyInset,
          c * ts,
          bottom,
        );
        canvas.drawRect(rect, body);
        shades.add(rect);
      }
      runStart = c;
    }

    // The tiles themselves, as one batch.
    final cap = (last - first) * grid.rows;
    if (_transforms.length < cap * 4) {
      _transforms = Float32List(cap * 4);
      _rects = Float32List(cap * 4);
    }
    final scale = (ts + bleed) / sourceTile;
    var n = 0;
    for (var c = first; c < last; c++) {
      final top = _topRow[c];
      if (top < 0) continue;
      for (var r = top; r < grid.rows; r++) {
        final gid = grid.gidAt(c, r);
        if (gid == 0) continue;
        final sx = ((gid - 1) % sheetColumns) * sourceTile;
        final sy = ((gid - 1) ~/ sheetColumns) * sourceTile;
        final crate = gid == crateGid;
        final i = n * 4;
        _rects[i] = crate ? sx + crateX : sx;
        _rects[i + 1] = crate ? sy + crateY : sy;
        _rects[i + 2] = crate ? sx + crateX + crateSize : sx + sourceTile;
        _rects[i + 3] = crate ? sy + crateY + crateSize : sy + sourceTile;
        _transforms[i] = crate ? (ts + bleed) / crateSize : scale; // scos
        _transforms[i + 1] = 0; // ssin
        _transforms[i + 2] = c * ts;
        _transforms[i + 3] = grid.originY + r * ts;
        n++;
      }
    }
    if (n == 0) return;
    canvas.drawRawAtlas(
      _sheet,
      Float32List.sublistView(_transforms, 0, n * 4),
      Float32List.sublistView(_rects, 0, n * 4),
      null,
      null,
      null,
      _tilePaint,
    );

    // Last, over the tiles: the earth darkens towards the bottom of the screen.
    for (final rect in shades) {
      canvas.drawRect(rect, _shade);
    }
  }
}

/// Water at the bottom of every pit, drawn in FRONT of the player so someone who
/// falls in sinks behind its surface instead of dropping past it. A pit is a
/// hazard with a fall of its own (a heart and a respawn); the water only says so.
class WaterComponent extends Component with HasGameReference<ChronoGame> {
  static const int renderPriority = 8;

  /// World y of the water surface; the ground band is 60 tall, so this is 30
  /// above the bottom of the screen.
  static const double surfaceY = 690;

  /// The surface tile (GID 37) cropped to its water rows.
  static const int surfaceGid = 37;
  static const double surfaceRows = 11;

  final TerrainGrid grid;
  final String eraId;

  late final ui.Image _sheet;

  /// Pits as (startX, endX): runs of empty columns with ground on both sides.
  late final List<({double startX, double endX})> _pits;

  final Paint _tilePaint = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;
  final Paint _body = Paint()..color = const Color(0xEB2F6F96);

  WaterComponent({required this.grid, required this.eraId})
      : super(priority: renderPriority);

  @override
  Future<void> onLoad() async {
    _sheet = await game.images.load(EraTerrain.sheetPath(eraId));
    final solid = List<bool>.generate(grid.cols, (c) {
      for (var r = 0; r < grid.rows; r++) {
        if (grid.gidAt(c, r) != 0) return true;
      }
      return false;
    });
    final pits = <({double startX, double endX})>[];
    int? start;
    for (var c = 0; c <= grid.cols; c++) {
      final pit = c < grid.cols && !solid[c];
      if (pit && start == null) start = c;
      if (!pit && start != null) {
        if (start > 0 && c < grid.cols) {
          pits.add((startX: start * grid.tileSize, endX: c * grid.tileSize));
        }
        start = null;
      }
    }
    _pits = pits;
  }

  @override
  void render(Canvas canvas) {
    final left = game.cameraLeftEdgeX;
    final right = game.cameraRightEdgeX;
    final ts = grid.tileSize;
    const srcX = ((surfaceGid - 1) % TerrainComponent.sheetColumns) *
        TerrainComponent.sourceTile;
    const srcY = ((surfaceGid - 1) ~/ TerrainComponent.sheetColumns) *
        TerrainComponent.sourceTile;
    final scale = ts / TerrainComponent.sourceTile;

    for (final pit in _pits) {
      if (pit.endX < left || pit.startX > right) continue;
      final a = max(pit.startX, left - ts);
      final b = min(pit.endX, right + ts);
      final bodyTop = surfaceY + surfaceRows * scale - 2;
      canvas.drawRect(
        Rect.fromLTRB(a, bodyTop, b, grid.originY + grid.rows * ts + 20),
        _body,
      );
      // One surface tile per tile of pit, not one more.
      final firstTile = ((a - pit.startX) / ts).floor();
      final count = ((min(b, pit.endX) - pit.startX) / ts).ceil() - firstTile;
      final transforms = Float32List(count * 4);
      final rects = Float32List(count * 4);
      for (var i = 0; i < count; i++) {
        final x = pit.startX + (firstTile + i) * ts;
        final k = i * 4;
        rects[k] = srcX;
        rects[k + 1] = srcY;
        rects[k + 2] = srcX + TerrainComponent.sourceTile;
        rects[k + 3] = srcY + surfaceRows;
        transforms[k] = scale;
        transforms[k + 1] = 0;
        transforms[k + 2] = x;
        transforms[k + 3] = surfaceY;
      }
      canvas.drawRawAtlas(_sheet, transforms, rects, null, null, null, _tilePaint);
    }
  }
}
