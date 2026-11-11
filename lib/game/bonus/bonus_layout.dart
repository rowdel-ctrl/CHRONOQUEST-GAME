import 'dart:math' as math;

import 'package:flame/components.dart' show Vector2;

import '../../core/bonus_constants.dart';

/// One floating stone slab of the bonus map: where it starts, how many 24-unit
/// tiles wide it is, and the world y of its top (where the hero's feet land).
class BonusPlatform {
  final double x;
  final int widthInTiles;
  final double surfaceY;
  const BonusPlatform(this.x, this.widthInTiles, this.surfaceY);

  double get width => widthInTiles * 24.0;
  double get endX => x + width;
}

/// One walker of the bonus round: its left x on the ground and its sprite kind.
class BonusEnemySpot {
  final double x;
  final String kind;
  const BonusEnemySpot(this.x, this.kind);
}

/// The bonus round's map, as plain data (nothing here is a component, so it can
/// be checked without a running game).
///
/// A stone floor with NO pits and NO water, seven floating slabs at the two jump
/// heights the level generator uses (104 and 112 above the floor, both under the
/// jump's peak of 128), rows and arcs of coins along the way, and five walkers on
/// the floor between the slabs. The coins are laid on the path a student takes
/// walking right, so the full round pays about what the approved mockup showed.
class BonusLayout {
  /// World y of the floor surface. Matches `ChronoGame.groundY`.
  static const double floorY = 660;

  /// Slab tops: 104 and 112 above the floor.
  static const double _lo = floorY - 104;
  static const double _hi = floorY - 112;

  static const List<BonusPlatform> _platforms = [
    BonusPlatform(640, 14, _lo),
    BonusPlatform(1380, 18, _hi),
    BonusPlatform(2100, 12, _lo),
    BonusPlatform(2760, 16, _hi),
    BonusPlatform(3560, 14, _lo),
  ];

  /// Where the coins lie: (from x, to x, how many, surface under them, arc lift).
  /// A lift of 0 is a straight row; above 0 the coins rise and fall like a jump.
  static const List<(double, double, int, double, double)> _groups = [
    (380, 560, 4, floorY, 0),
    (590, 720, 3, floorY, 90),
    (740, 940, 6, _lo, 0),
    (990, 1120, 3, floorY, 70),
    (1140, 1300, 4, floorY, 0),
    (1310, 1420, 3, floorY, 90),
    (1450, 1760, 7, _hi, 0),
    (1830, 1950, 3, floorY, 70),
    (1990, 2130, 3, floorY, 90),
    (2150, 2350, 5, _lo, 0),
    (2420, 2540, 3, floorY, 70),
    (2560, 2720, 4, floorY, 0),
    (2680, 2790, 3, floorY, 90),
    (2820, 3100, 6, _hi, 0),
    (3170, 3290, 3, floorY, 70),
    (3320, 3480, 4, floorY, 0),
    (3480, 3580, 2, floorY, 90),
    (3600, 3860, 5, _lo, 0),
  ];

  /// Where the five walkers stand (left x), on the floor in the gaps between slabs.
  static const List<double> _enemyXs = [1060, 1900, 2560, 3340, 3990];

  /// Every x below is laid out for a short walk and stretched by this, so the walk
  /// from the start to the last coin takes about 17.5 seconds at the hero's full
  /// speed of 250 a second: a student who jumps, fights and stops for a moment sees
  /// most of it in the 20 seconds, never all.
  static const double _stretch = 1.2;

  /// How many coins the map holds: about 58 (the mockup said 55 to 60).
  static const int coinTotal = 58;

  final String eraId;
  final double mapWidth;
  final List<BonusPlatform> platforms;

  /// Top-left corners of the 42x42 coins, left to right.
  final List<Vector2> coins;
  final List<BonusEnemySpot> enemies;

  const BonusLayout._({
    required this.eraId,
    required this.mapWidth,
    required this.platforms,
    required this.coins,
    required this.enemies,
  });

  /// The map for [eraId]: the same stone and the same coins everywhere, with the
  /// era's own walkers.
  factory BonusLayout.forEra(String eraId) {
    final counts = [for (final g in _groups) g.$3];
    // Trim the fattest rows (or fatten the thinnest) until the total is exact, so
    // the map keeps its rhythm whatever the group sizes above add up to.
    int sum() => counts.fold(0, (a, b) => a + b);
    while (sum() > coinTotal) {
      var b = 0;
      for (var i = 0; i < counts.length; i++) {
        if (counts[i] > counts[b]) b = i;
      }
      counts[b]--;
    }
    while (sum() < coinTotal) {
      var b = 0;
      for (var i = 0; i < counts.length; i++) {
        if (counts[i] < counts[b]) b = i;
      }
      counts[b]++;
    }

    final coins = <Vector2>[];
    for (var gi = 0; gi < _groups.length; gi++) {
      final (x0, x1, _, surface, lift) = _groups[gi];
      final n = counts[gi];
      for (var i = 0; i < n; i++) {
        final u = n == 1 ? 0.5 : i / (n - 1);
        final cx = (x0 + (x1 - x0) * u) * _stretch;
        // The coin's top-left: 80 above the surface at the lowest, rising with the arc.
        final top = surface - 80 - lift * math.sin(math.pi * u);
        coins.add(Vector2(cx - 21, top));
      }
    }
    coins.sort((a, b) => a.x.compareTo(b.x));

    final kinds = BonusConstants.enemyKinds[eraId] ??
        BonusConstants.enemyKinds['spanish']!;
    return BonusLayout._(
      eraId: eraId,
      mapWidth: BonusConstants.mapWidth,
      platforms: [
        for (final p in _platforms)
          BonusPlatform(p.x * _stretch, p.widthInTiles, p.surfaceY),
      ],
      coins: coins,
      enemies: [
        for (var i = 0; i < _enemyXs.length; i++)
          BonusEnemySpot(_enemyXs[i] * _stretch, kinds[i % kinds.length]),
      ],
    );
  }

  /// The x of the last coin: past it a student has nothing left to collect.
  double get coinsEndX => coins.isEmpty ? 0 : coins.last.x + 42;
}
