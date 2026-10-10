import 'dart:typed_data';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:tiled/tiled.dart';

import '../core/combat_constants.dart';
import '../models/level.dart';
import 'components/artifact_component.dart';
import 'components/coin_component.dart';
import 'components/enemy_component.dart';
import 'components/gap_component.dart';
import 'components/gate_component.dart';
import 'components/terrain_component.dart';
import 'components/tile_platform_component.dart';
import 'generated_level_manifest.dart';
import 'game_collision.dart' show footSpanFraction;

/// One run of ground columns that share a surface height. A level's ground is a
/// row of these: flat stretches, the steps of a hill, a raised mesa, the pillars
/// between pits. Each becomes one [GroundSection] for collision.
class GroundBlock {
  final double startX;
  final double width;

  /// World y of the surface, where a standing player's feet are.
  final double topY;

  const GroundBlock({
    required this.startX,
    required this.width,
    required this.topY,
  });

  double get endX => startX + width;

  /// Tiles above the base ground, rounded: 0 is the base, 2 is 48 units up.
  int heightInTiles(double tileSize) =>
      ((LoadedLevel.groundSurfaceY - topY) / tileSize).round();
}

/// The `ground` tile layer, kept as drawn so the game can paint exactly what
/// the map says (the caps, edges and walls are chosen when the map is made).
class TerrainGrid {
  final int cols;
  final int rows;

  /// Edge of one tile cell in world units (24: the 16px art drawn at 1.5x).
  final double tileSize;

  /// World y of the top of row 0. The layer's own `offsety`.
  final double originY;

  /// One GID per cell, row by row; 0 is empty.
  final Uint8List gids;

  const TerrainGrid({
    required this.cols,
    required this.rows,
    required this.tileSize,
    required this.originY,
    required this.gids,
  });

  int gidAt(int col, int row) => gids[row * cols + col];
}

/// Loads a hand-authored Tiled level and turns it into game components
/// (GAMEPLAY-V2.md Section 11).
///
/// This replaces the runtime spawner, which generated "content" by dropping
/// an enemy every ~800 world units and coins on a timer — the reason Section
/// 11 says the game doesn't feel designed, "because it isn't. Nothing in it
/// was ever placed by a person."
///
/// Deliberately a plain data class rather than a Flame component: it parses
/// a `.tmx` into a description of what to build, and the caller builds it.
/// That keeps the parsing testable without a running game loop, which
/// matters because every interesting failure here (a typo'd object type, an
/// artifact at the wrong height, a missing `exit`) is a data error, not a
/// rendering one.
class LoadedLevel {
  /// Where the player starts, from the `spawn` object.
  final double spawnX;

  /// World x the player must reach to finish, from the `exit` object. This
  /// is what Phase 4 replaces `CombatConstants.lengthUnitsDefault` with:
  /// the level ends where the author put the exit, not at a global default.
  final double exitX;

  /// Solid ground spans as (startX, width) pairs: runs of columns with any
  /// ground at all, whatever its height. Pits are the stretches between them —
  /// Section 11: "gaps are just places you didn't paint ground".
  final List<({double startX, double width})> groundSpans;

  /// The ground as runs of one height each (see [GroundBlock]), left to right.
  /// A flat level is the same list as [groundSpans]; raised ground splits a span
  /// wherever the surface changes.
  final List<GroundBlock> groundBlocks;

  /// The ground tile layer, for drawing. Null when the map has none.
  final TerrainGrid? terrain;

  /// The ground as blocks, whatever the level was built from: [groundBlocks] when
  /// the map had them, else one block per span at the base height (a level made
  /// by hand in code, or a flat map).
  List<GroundBlock> get blocks => groundBlocks.isNotEmpty
      ? groundBlocks
      : [
          for (final s in groundSpans)
            GroundBlock(
              startX: s.startX,
              width: s.width,
              topY: groundSurfaceY,
            ),
        ];

  /// Everything on the `entities` object layer that isn't spawn/exit.
  final List<LevelEntity> entities;

  /// The curriculum block (Section 1). Read from map properties when
  /// present; the caller falls back to the era registry's value otherwise,
  /// so a map that omits it is still reportable rather than broken.
  final CurriculumTag? curriculum;

  /// Starting Kaalaman charges, if the map overrides the global default.
  final int? kaalamanStart;

  const LoadedLevel({
    required this.spawnX,
    required this.exitX,
    required this.groundSpans,
    required this.entities,
    this.groundBlocks = const [],
    this.terrain,
    this.curriculum,
    this.kaalamanStart,
  });

  /// True when [worldX] sits over a gap rather than solid ground. Used by
  /// the tests to prove a generated level has no unclearable hole, and
  /// available to the future generator for the same check.
  bool isOverGround(double worldX) => groundSpans.any(
        (s) => worldX >= s.startX && worldX < s.startX + s.width,
      );

  /// World y of the base ground surface. An enemy object's `y` is where its
  /// feet stand: this for an enemy on the base ground, the top of the raised
  /// ground or platform it stands on otherwise. Matches `ChronoGame.groundY`.
  static const double groundSurfaceY = 660;

  /// Whether [e] stands above the base ground: on raised ground or a platform.
  bool enemyIsOnPlatform(LevelEntity e) => e.y < groundSurfaceY - 1;

  /// The ground block [e] stands on: the one whose surface is at its feet and
  /// that holds the middle of the sprite. Null over a pit, or for an enemy
  /// placed on a platform.
  GroundBlock? blockUnder(LevelEntity e) {
    final centre = e.x + EnemyComponent.spriteWidth / 2;
    for (final b in blocks) {
      if ((b.topY - e.y).abs() < 1 && centre >= b.startX && centre <= b.endX) {
        return b;
      }
    }
    return null;
  }

  /// The ground block that holds world x [x], or null over a pit.
  GroundBlock? blockAt(double x) {
    for (final b in blocks) {
      if (x >= b.startX && x < b.endX) return b;
    }
    return null;
  }

  /// The platform [e] stands on: the one whose top is at the enemy's feet and
  /// whose span holds the middle of the sprite. Null for a ground enemy, or an
  /// enemy whose y matches no platform under it.
  LevelEntity? platformUnder(LevelEntity e) {
    if (!enemyIsOnPlatform(e)) return null;
    final centre = e.x + EnemyComponent.spriteWidth / 2;
    for (final p in entities) {
      if (p.type == 'platform' &&
          (p.y - e.y).abs() < 1 &&
          centre >= p.x &&
          centre <= p.x + p.width) {
        return p;
      }
    }
    return null;
  }

  /// Whether an enemy keeps its whole patrol corridor over what it stands on:
  /// one ground span, or the platform it was placed on. Measured with the same
  /// foot span the enemy obeys at runtime.
  bool enemyStaysOnSupport(LevelEntity e) {
    final range = e.behavior == 'heavy'
        ? 0.0
        : (e.patrol ?? CombatConstants.patrolRange);
    const inset = EnemyComponent.spriteWidth * (1 - footSpanFraction) / 2;
    final left = e.x - range + inset;
    final right = e.x + range + EnemyComponent.spriteWidth - inset;
    final block = blockUnder(e);
    if (block != null) return left >= block.startX && right <= block.endX;
    final platform = platformUnder(e);
    if (platform == null) return false;
    return left >= platform.x && right <= platform.x + platform.width;
  }

  /// Whether an enemy placed at [e] keeps its whole patrol corridor over the one
  /// block of ground it stands on, measured with the same foot span the enemy
  /// obeys at runtime. A heavy never moves, so its corridor is just where it
  /// stands.
  bool enemyStaysOnGround(LevelEntity e) {
    final range = e.behavior == 'heavy'
        ? 0.0
        : (e.patrol ?? CombatConstants.patrolRange);
    const inset = EnemyComponent.spriteWidth * (1 - footSpanFraction) / 2;
    final left = e.x - range + inset;
    final right = e.x + range + EnemyComponent.spriteWidth - inset;
    return blocks.any((b) => left >= b.startX && right <= b.endX);
  }
}

/// One authored object from the `entities` layer, normalised out of Tiled's
/// loose `type` + untyped-properties shape into something the builder can
/// switch on exhaustively.
class LevelEntity {
  final String type;
  final double x;
  final double y;
  final double width;
  final double height;

  /// `kind` — which enemy sprite (Section 11's object table).
  final String? kind;

  /// `behavior` — `walker` or `heavy`.
  final String? behavior;

  /// `patrol` — how far this enemy paces, in px.
  final double? patrol;

  /// `art` — which `artifact_N.png` an artifact uses.
  final String? art;

  const LevelEntity({
    required this.type,
    required this.x,
    required this.y,
    this.width = 0,
    this.height = 0,
    this.kind,
    this.behavior,
    this.patrol,
    this.art,
  });
}

/// Parses `.tmx` files into [LoadedLevel]s.
class LevelLoader {
  /// Asset path for a level, per Section 11's
  /// `assets/tiles/levels/era<N>_<n>.tmx` convention. [eraNumber] is the
  /// 1-based era index from Section 1's table, not the string era id —
  /// filenames use numbers so they sort in curriculum order.
  static String assetPathFor(int eraNumber, int levelIndex) =>
      'assets/tiles/levels/era${eraNumber}_$levelIndex.tmx';

  /// Levels that have a hand-authored `.tmx`, as `(eraNumber, levelIndex)`.
  ///
  /// An explicit manifest rather than probing the asset bundle: probing
  /// means a `rootBundle.loadString` that throws for every unauthored level
  /// — 42 caught exceptions per session today — and, worse, it makes
  /// "does this level exist" an async round-trip that widget tests cannot
  /// settle with `pump()` alone. The generator appends to this list as it
  /// emits files, so it stays the single source of truth.
  @visibleForTesting
  static Set<(int, int)> authored = const {
    ...generatedLevels, // written by tools/levelgen/generate.js
  };

  /// Whether a level file exists for this era/level. Phase 4 ships one
  /// hand-built reference level and generates the rest afterwards, so the
  /// game has to be able to ask before committing to the Tiled path.
  static bool exists(int eraNumber, int levelIndex) =>
      authored.contains((eraNumber, levelIndex));

  /// Loads and parses the level for [eraNumber]/[levelIndex].
  static Future<LoadedLevel> load(int eraNumber, int levelIndex) async {
    final xml = await rootBundle.loadString(
      assetPathFor(eraNumber, levelIndex),
    );
    return parse(xml);
  }

  /// Parses raw `.tmx` XML. Separated from [load] so tests can exercise the
  /// whole schema without a Flutter asset bundle.
  @visibleForTesting
  static LoadedLevel parse(String tmxXml) {
    // No external tilesets are resolved here: the loader only reads the
    // ground layer's GIDs (solid vs empty) and the object layer, neither of
    // which needs the tileset image. Passing an empty list keeps parsing
    // synchronous and test-friendly.
    final map = TileMapParser.parseTmx(tmxXml);

    final tileWidth = map.tileWidth.toDouble();
    final ground = _readGround(map);

    return LoadedLevel(
      spawnX: _singleObjectX(map, 'spawn') ?? 0,
      exitX: _singleObjectX(map, 'exit') ??
          (map.width * tileWidth), // fall back to the map's right edge
      groundSpans: ground.spans,
      groundBlocks: ground.blocks,
      terrain: ground.grid,
      entities: _readEntities(map),
      curriculum: _readCurriculum(map),
      kaalamanStart: map.properties.getValue<int>('kaalamanStart'),
    );
  }

  /// Reads the ground tile layer into spans, blocks and the grid to draw.
  ///
  /// A column counts as ground if *any* row in it has a non-zero GID, which is
  /// what makes "don't paint ground here" mean "pit" without the author having
  /// to mark pits explicitly. The first painted row of a column is its surface,
  /// so painting ground higher in a column raises it: that is all a hill, a
  /// mesa or a tower is. The layer's `offsety` says where row 0 sits in the
  /// world (the generator uses 12 so the base surface lands on 660).
  static ({
    List<({double startX, double width})> spans,
    List<GroundBlock> blocks,
    TerrainGrid? grid,
  }) _readGround(TiledMap map) {
    final layer = map.layers
        .whereType<TileLayer>()
        .where((l) => l.name == 'ground')
        .firstOrNull;
    final data = layer?.tileData;
    if (layer == null || data == null) {
      return (spans: const [], blocks: const [], grid: null);
    }

    final tileW = map.tileWidth.toDouble();
    final tileH = map.tileHeight.toDouble();
    final cols = map.width;
    final rows = map.height;
    final gids = Uint8List(cols * rows);
    final topRow = List<int>.filled(cols, -1);
    for (var row = 0; row < rows && row < data.length; row++) {
      for (var col = 0; col < cols && col < data[row].length; col++) {
        final gid = data[row][col].tile;
        if (gid == 0) continue;
        gids[row * cols + col] = gid > 255 ? 255 : gid;
        if (topRow[col] < 0) topRow[col] = row;
      }
    }

    final spans = <({double startX, double width})>[];
    final blocks = <GroundBlock>[];
    int? spanStart;
    int? blockStart;
    for (var col = 0; col <= cols; col++) {
      final solid = col < cols && topRow[col] >= 0;
      if (solid && spanStart == null) spanStart = col;
      if (!solid && spanStart != null) {
        spans.add((
          startX: spanStart * tileW,
          width: (col - spanStart) * tileW,
        ));
        spanStart = null;
      }
      final sameBlock = col < cols &&
          blockStart != null &&
          topRow[col] == topRow[blockStart];
      if (blockStart != null && !sameBlock) {
        blocks.add(GroundBlock(
          startX: blockStart * tileW,
          width: (col - blockStart) * tileW,
          topY: layer.offsetY + topRow[blockStart] * tileH,
        ));
        blockStart = null;
      }
      if (solid && blockStart == null) blockStart = col;
    }

    return (
      spans: spans,
      blocks: blocks,
      grid: TerrainGrid(
        cols: cols,
        rows: rows,
        tileSize: tileW,
        originY: layer.offsetY,
        gids: gids,
      ),
    );
  }

  static List<LevelEntity> _readEntities(TiledMap map) {
    final layer = map.layers
        .whereType<ObjectGroup>()
        .where((l) => l.name == 'entities')
        .firstOrNull;
    if (layer == null) return const [];

    final out = <LevelEntity>[];
    for (final o in layer.objects) {
      // Tiled 1.9 renamed "type" to "class"; `class_` is an alias for the
      // same field in this package, so reading `type` covers both.
      final type = o.type;
      if (type.isEmpty || type == 'spawn' || type == 'exit') continue;

      out.add(
        LevelEntity(
          type: type,
          x: o.x,
          y: o.y,
          width: o.width,
          height: o.height,
          kind: o.properties.getValue<String>('kind'),
          behavior: o.properties.getValue<String>('behavior'),
          // Tiled writes float properties as double, but an author who types
          // a whole number into an int field would produce an int — read
          // both rather than silently dropping the patrol range.
          patrol: o.properties.getValue<double>('patrol') ??
              o.properties.getValue<int>('patrol')?.toDouble(),
          art: o.properties.getValue<String>('art'),
        ),
      );
    }
    return out;
  }

  static double? _singleObjectX(TiledMap map, String type) {
    for (final layer in map.layers.whereType<ObjectGroup>()) {
      for (final o in layer.objects) {
        if (o.type == type) return o.x;
      }
    }
    return null;
  }

  /// Reads the Section 1 curriculum block from map-level custom properties.
  ///
  /// Section 11 allows this to live either in a side JSON file or in Tiled's
  /// map properties, "whichever is less friction" — map properties win
  /// because they travel with the level: a level can't be copied to a new
  /// file and silently lose the tag that makes it reportable.
  ///
  /// `weeks` is a comma-separated string ("8,9") rather than a list, because
  /// Tiled has no list property type.
  static CurriculumTag? _readCurriculum(TiledMap map) {
    final grade = map.properties.getValue<int>('grade');
    final term = map.properties.getValue<int>('term');
    if (grade == null || term == null) return null;

    final weeksRaw = map.properties.getValue<String>('weeks') ?? '';
    final weeks = weeksRaw
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();

    return CurriculumTag(grade: grade, term: term, weeks: weeks);
  }
}

/// Turns a parsed [LoadedLevel] into live components inside a game world.
///
/// Kept separate from parsing so the schema can be tested without a game,
/// and so the one place that decides *how* an authored object becomes a
/// component is findable — an unknown `type` warns loudly in debug rather
/// than being silently skipped, because a typo in Tiled is otherwise
/// invisible until someone notices an enemy missing from a level.
class LevelBuilder {
  /// Builds everything in [level] into [world].
  ///
  /// [groundY] is the world y of the ground surface and [eraId] selects
  /// enemy sprites and the gate's wall art.
  static void build({
    required LoadedLevel level,
    required Component world,
    required double groundY,
    required String eraId,
  }) {
    // One collision section per block of ground, at its own height, reaching
    // down to the bottom of the screen. They are not drawn: the terrain
    // component below paints the tiles the map holds.
    for (final block in level.blocks) {
      world.add(
        GroundSection(
          sectionWidth: block.width,
          sectionPosition: Vector2(block.startX, block.topY),
          sectionHeight: groundY - block.topY + GroundSection.bandHeight,
          drawn: false,
        ),
      );
    }
    final terrain = level.terrain;
    if (terrain != null) {
      world.add(TerrainComponent(grid: terrain, eraId: eraId));
      world.add(WaterComponent(grid: terrain, eraId: eraId));
    }

    for (final e in level.entities) {
      switch (e.type) {
        case 'enemy':
          if (!level.enemyStaysOnSupport(e)) {
            debugPrint(
              'LevelBuilder: enemy at x=${e.x} patrols off its ground span or '
              'platform and will turn back at the ledge. Move it onto solid '
              'ground, or set its y to the top of the platform it stands on.',
            );
          }
          world.add(
            EnemyComponent(
              eraId: eraId,
              enemyTypeOverride: e.kind,
              worldX: e.x,
              patrolRangeOverride: e.patrol,
              // Feet on a platform when the object's y is above the ground.
              surfaceY: e.y < groundY - 1 ? e.y : null,
            ),
          );

        case 'artifact':
          world.add(
            ArtifactComponent(
              worldX: e.x,
              spriteIndex: _artifactIndex(e.art),
              // The map puts each artifact on the ground under it; the base
              // ground is the default, so older maps behave as they did.
              surfaceY: e.y > 0 && e.y < groundY - 1 ? e.y : null,
            ),
          );

        case 'gate':
          // An authored gate at (or past) the exit is the level's end gate:
          // reaching it with every artifact answered completes the level.
          world.add(
            GateComponent(
              worldX: e.x,
              isLevelExit: e.x >= level.exitX - CombatConstants.gateWidth,
            ),
          );

        case 'coin':
          world.add(CoinComponent(spawnPosition: Vector2(e.x, e.y)));

        case 'platform':
          // Tiled gives a platform a pixel width; the component takes tiles.
          // Anchored by its top edge, which is exactly what `surfaceY`
          // means, so the authored y IS the landing plane — no offset.
          world.add(
            TilePlatformComponent(
              widthInTiles:
                  (e.width / TilePlatformComponent.tileSize).round().clamp(1, 64),
              surfaceY: e.y,
              spawnPosition: Vector2(e.x, e.y),
            ),
          );

        default:
          debugPrint(
            'LevelBuilder: ignoring unknown entity type "${e.type}" at '
            '(${e.x}, ${e.y}). Check the object\'s Class in Tiled.',
          );
      }
    }
  }

  /// Maps an `art` property ("artifact_3") to the 1-5 sprite index
  /// ArtifactComponent takes. Only five sprites exist for six eras (Section
  /// 6), so they repeat, distinguished by the per-era tint.
  static int _artifactIndex(String? art) {
    if (art == null) return 1;
    final n = int.tryParse(art.replaceAll(RegExp(r'[^0-9]'), ''));
    if (n == null || n < 1) return 1;
    return ((n - 1) % 5) + 1;
  }
}
