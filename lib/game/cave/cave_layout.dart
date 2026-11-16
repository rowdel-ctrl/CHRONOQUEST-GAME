import 'dart:math' as math;

import 'package:flame/components.dart' show Vector2;

import '../../core/cave_constants.dart';
import '../../core/constants.dart' show eraNumberFor;

/// One floating slab of the cave: where it starts, how many 24-unit tiles wide it
/// is, and the world y of its top (where the hero's feet land).
class CavePlatform {
  final double x;
  final int widthInTiles;
  final double surfaceY;
  const CavePlatform(this.x, this.widthInTiles, this.surfaceY);

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

    coins.sort((a, b) => a.x.compareTo(b.x));
    return CaveLayout._(
      eraId: eraId,
      levelNo: levelNo,
      mapWidth: CaveConstants.mapWidth,
      floor: floor,
      platforms: platforms,
      coins: coins,
      enemies: enemies,
      spawnX: CaveConstants.spawnX,
      artifactX: CaveConstants.artifactX,
      exitX: CaveConstants.exitPipeX,
    );
  }
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
