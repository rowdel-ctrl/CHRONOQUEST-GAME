import 'dart:math' as math;

import 'package:flame/components.dart' show Vector2;

import '../../core/cave_constants.dart';
import '../../core/constants.dart' show eraNumberFor;
import 'cave_obstacles.dart';

export 'cave_obstacles.dart';

/// One floating slab of the cave: where it starts, how many 24-unit tiles wide it
/// is, and the world y of its top (where the hero's feet land). A [crumbling] slab
/// falls away a moment after the hero lands on it, and comes back later.
class CavePlatform {
  final double x;
  final int widthInTiles;
  final double surfaceY;
  final bool crumbling;
  const CavePlatform(this.x, this.widthInTiles, this.surfaceY,
      {this.crumbling = false});

  double get width => widthInTiles * 24.0;
  double get endX => x + width;
}

/// One enemy of the cave: its left x on the floor, its sprite kind, and whether
/// it chases the student or only paces.
class CaveEnemySpot {
  final double x;
  final String kind;
  final bool chaser;
  const CaveEnemySpot(this.x, this.kind, {this.chaser = false});
}

/// The cave's map as plain data (nothing here is a component, so it can be checked
/// without a running game).
///
/// A cave is a stretch of floor with a few pits, a few floating slabs, rows and
/// arcs of coins, six or seven enemies of the era, then a flat room with the
/// artifact and the exit pipe. It is built from a few pieces in an order that
/// depends on the era and the level, so no two caves are the same walk, and the
/// same level is always the same cave.
///
/// Every cave can be walked: a pit is at most [CaveConstants.maxPitWidth] wide (a
/// full jump covers about 266), a slab's top is under the jump's peak of 128, an
/// enemy has solid floor under its whole patrol, and the artifact room is empty.
///
/// The obstacles ([CaveConstants.obstaclesFor]) are laid last, on the finished
/// floor, so they never change where the pits, slabs and enemies are. They sit only
/// on flat floor with room to run up and to land, never in a pit, in an enemy's
/// patrol, under a slab or in the artifact room; a slab that crumbles is an
/// optional extra (the floor is always walkable without it).
class CaveLayout {
  /// World y of the floor surface. Matches `ChronoGame.groundY` for the level
  /// maps (see `LoadedLevel.groundSurfaceY`).
  static const double floorY = 660;

  final String eraId;
  final int levelNo;
  final double mapWidth;

  /// The floor as runs of solid ground, left to right; the stretches between
  /// them are pits.
  final List<({double x0, double x1})> floor;
  final List<CavePlatform> platforms;

  /// Top-left corners of the 42x42 coins.
  final List<Vector2> coins;
  final List<CaveEnemySpot> enemies;

  /// The obstacles (see [CaveConstants.obstaclesFor] for which levels have which).
  final List<CaveSpikeSpot> spikes;
  final List<CaveStalactiteSpot> stalactites;
  final List<CaveCrusherSpot> crushers;

  final double spawnX;
  final double artifactX;
  final double exitX;

  const CaveLayout._({
    required this.eraId,
    required this.levelNo,
    required this.mapWidth,
    required this.floor,
    required this.platforms,
    required this.coins,
    required this.enemies,
    required this.spikes,
    required this.stalactites,
    required this.crushers,
    required this.spawnX,
    required this.artifactX,
    required this.exitX,
  });

  /// The pits, as (from x, to x).
  List<({double x0, double x1})> get pits => [
        for (var i = 0; i + 1 < floor.length; i++)
          (x0: floor[i].x1, x1: floor[i + 1].x0),
      ];

  /// Whether solid floor holds the whole span [left]..[right].
  bool floorHolds(double left, double right) =>
      floor.any((f) => left >= f.x0 && right <= f.x1);

  factory CaveLayout.forLevel(String eraId, int levelNo) {
    final rng = _Rng(eraNumberFor(eraId) * 1000 + levelNo * 37 + 11);
    final kinds =
        CaveConstants.enemyKinds[eraId] ?? CaveConstants.enemyKinds['spanish']!;

    const lo = floorY - CaveConstants.minPlatformRise;
    const hi = floorY - CaveConstants.maxPlatformRise;

    final floor = <({double x0, double x1})>[];
    final platforms = <CavePlatform>[];
    final coins = <Vector2>[];
    final enemies = <CaveEnemySpot>[];

    void coinRow(double from, double to, int n, double surface,
        {double lift = 0}) {
      for (var i = 0; i < n; i++) {
        final u = n == 1 ? .5 : i / (n - 1);
        final cx = from + (to - from) * u;
        coins.add(Vector2(cx - 21, surface - 80 - lift * math.sin(math.pi * u)));
      }
    }

    // The pieces, each laid from [x] and returning the x it ends at. Every piece
    // starts and ends on solid floor with room to land.
    var floorStart = 0.0;
    var x = CaveConstants.spawnX + 380; // clear of where the student lands
    var enemyNo = 0;

    void walker(double at) {
      final kind = kinds[enemyNo % kinds.length];
      enemies.add(CaveEnemySpot(at, kind, chaser: enemyNo.isOdd));
      enemyNo++;
    }

    double pieceRow(double at) {
      coinRow(at, at + 260, 6, floorY);
      walker(at + 420);
      return at + 760;
    }

    double piecePit(double at) {
      final w = 96.0 + rng.next(3) * 12; // 96, 108, 120
      floor.add((x0: floorStart, x1: at + 160));
      floorStart = at + 160 + w;
      coinRow(at + 160 - 20, at + 160 + w + 20, 5, floorY, lift: 110);
      return at + 160 + w + 360;
    }

    double pieceSlab(double at) {
      final tiles = 8 + rng.next(4) * 2; // 8..14
      final top = rng.next(2) == 0 ? lo : hi;
      platforms.add(CavePlatform(at + 40, tiles, top));
      coinRow(at + 60, at + 20 + tiles * 24.0, 5, top);
      walker(at + 40 + tiles * 24.0 / 2 - 45); // pacing on the floor below it
      return at + 40 + tiles * 24.0 + 420;
    }

    double pieceFoes(double at) {
      coinRow(at, at + 180, 4, floorY, lift: 70);
      walker(at + 300);
      walker(at + 620);
      return at + 980;
    }

    final pieces = <double Function(double)>[
      pieceRow, piecePit, pieceSlab, pieceFoes, //
    ];
    // Always one pit and one slab; then a mix, in an order of this level's own.
    final order = <int>[1, 2, 3, 0, 2, 3, 1, 0]..shuffle(math.Random(rng.seed));
    // The longest piece is under 1000 long, so one that starts before this ends
    // before the artifact room's run-up begins.
    const limit = CaveConstants.artifactX - 360 - 1000;
    for (final i in order) {
      if (x > limit) break;
      x = pieces[i](x);
    }

    // The artifact room: flat, empty of enemies, the exit pipe at its end.
    floor.add((x0: floorStart, x1: CaveConstants.mapWidth));
    coinRow(CaveConstants.artifactX - 360, CaveConstants.artifactX - 100, 4, floorY);
    coinRow(CaveConstants.artifactX + 120, CaveConstants.artifactX + 400, 4, floorY);

    // The obstacles, last, on the finished floor.
    final obstacles = _placeObstacles(
      seed: rng.seed + 7919,
      levelNo: levelNo,
      floor: floor,
      platforms: platforms,
      enemies: enemies,
    );
    final slabs = [
      for (var i = 0; i < platforms.length; i++)
        obstacles.crumblingSlabs.contains(i)
            ? CavePlatform(platforms[i].x, platforms[i].widthInTiles,
                platforms[i].surfaceY,
                crumbling: true)
            : platforms[i],
    ];

    coins.sort((a, b) => a.x.compareTo(b.x));
    return CaveLayout._(
      eraId: eraId,
      levelNo: levelNo,
      mapWidth: CaveConstants.mapWidth,
      floor: floor,
      platforms: slabs,
      coins: coins,
      enemies: enemies,
      spikes: obstacles.spikes,
      stalactites: obstacles.stalactites,
      crushers: obstacles.crushers,
      spawnX: CaveConstants.spawnX,
      artifactX: CaveConstants.artifactX,
      exitX: CaveConstants.exitPipeX,
    );
  }
}

/// Lays the obstacles [CaveConstants.obstaclesFor] gives [levelNo] on a finished
/// floor, the hardest to fit first. Deterministic: only [seed] chooses between the
/// places that fit.
CaveObstacles _placeObstacles({
  required int seed,
  required int levelNo,
  required List<({double x0, double x1})> floor,
  required List<CavePlatform> platforms,
  required List<CaveEnemySpot> enemies,
}) {
  final rng = _Rng(seed);
  final kinds = CaveConstants.obstaclesFor(levelNo);
  // Nothing from the artifact room's start on (its run-up is part of the room).
  const end = CaveConstants.artifactX - 360;

  bool floorHolds(double l, double r) =>
      floor.any((f) => l >= f.x0 && r <= f.x1);
  // An enemy's patrol corridor, as the walkability check measures it.
  bool clearOfEnemies(double l, double r, double margin) => enemies.every(
      (e) => r + margin <= e.x - 70 || l - margin >= e.x + 96 + 70);
  bool clearOfSlabs(double l, double r) =>
      platforms.every((p) => r + 30 <= p.x || l - 30 >= p.endX);

  final taken = <double>[];

  /// The left edge of a place for something [w] wide with [before] and [after] of
  /// flat floor each side, or null when the cave has none. [margin] is the clear
  /// space needed between the thing itself and any enemy's patrol.
  double? pick(double w, double before, double after, double margin) {
    for (final spacing in [
      CaveConstants.obstacleSpacing,
      CaveConstants.obstacleSpacing * 2 / 3,
      CaveConstants.obstacleSpacing / 2,
    ]) {
      final fits = <double>[];
      for (var x = CaveConstants.obstacleMinX; x + w + after <= end; x += 12) {
        if (floorHolds(x - before, x + w + after) &&
            clearOfEnemies(x, x + w, margin) &&
            clearOfSlabs(x, x + w) &&
            taken.every((t) => (t - (x + w / 2)).abs() >= spacing)) {
          fits.add(x);
        }
      }
      if (fits.isNotEmpty) {
        final x = fits[rng.next(fits.length)];
        taken.add(x + w / 2);
        return x;
      }
    }
    return null;
  }

  final crushers = <CaveCrusherSpot>[];
  if (kinds.contains(CaveObstacle.crusher)) {
    for (var i = 0; i < CaveConstants.crusherCount; i++) {
      final x = pick(CaveConstants.crusherWidth, CaveConstants.crusherRoom,
          CaveConstants.crusherRoom, 60);
      if (x != null) {
        crushers.add(CaveCrusherSpot(x + CaveConstants.crusherWidth / 2));
      }
    }
  }
  final stalactites = <CaveStalactiteSpot>[];
  if (kinds.contains(CaveObstacle.stalactite)) {
    const w = CaveConstants.stalactiteBaseWidth;
    for (var i = 0; i < CaveConstants.stalactiteCount; i++) {
      final x = pick(
          w, CaveConstants.stalactiteRoom, CaveConstants.stalactiteRoom, 50);
      if (x != null) stalactites.add(CaveStalactiteSpot(x + w / 2));
    }
  }
  final spikes = <CaveSpikeSpot>[];
  for (var i = 0; i < CaveConstants.spikeClusters; i++) {
    final count = 1 + rng.next(CaveConstants.spikeMaxInCluster);
    final x = pick(count * CaveConstants.spikeWidth, CaveConstants.spikeRunUp,
        CaveConstants.spikeLanding, 20);
    if (x != null) spikes.add(CaveSpikeSpot(x, count));
  }
  spikes.sort((a, b) => a.x.compareTo(b.x));
  stalactites.sort((a, b) => a.x.compareTo(b.x));

  // One or two of the cave's own slabs crumble.
  final crumbling = <int>{};
  if (kinds.contains(CaveObstacle.crumblingSlab) && platforms.isNotEmpty) {
    final n = math.min(
        1 + rng.next(CaveConstants.crumblingSlabsMax), platforms.length);
    final order = List<int>.generate(platforms.length, (i) => i);
    for (var i = 0; i < n; i++) {
      final j = i + rng.next(order.length - i);
      final t = order[i];
      order[i] = order[j];
      order[j] = t;
      crumbling.add(order[i]);
    }
  }

  return CaveObstacles(
    spikes: spikes,
    stalactites: stalactites,
    crushers: crushers,
    crumblingSlabs: crumbling,
  );
}

/// A small repeatable number source: the same seed gives the same cave.
class _Rng {
  _Rng(this.seed) : _s = seed & 0x7fffffff;
  final int seed;
  int _s;

  /// A whole number from 0 up to (not including) [n].
  int next(int n) {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return (_s >> 8) % n;
  }
}
