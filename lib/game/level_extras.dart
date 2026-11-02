import 'package:flame/components.dart' show Vector2;

import 'level_loader.dart';

/// What the new rules add to an authored level without touching its `.tmx`: extra
/// coins and (in about half the levels) one heart on the high platforms, and a
/// flag about halfway. Worked out from the level alone and the same every time, so
/// a level plays the same on every try and on every phone.
class LevelExtras {
  /// A platform this far above the base ground counts as high (a jump reaches
  /// about 128, so these are the ones worth the climb).
  static const double highPlatformRise = 90;

  /// Coin and heart sizes, so they sit on the platform instead of in it.
  static const double coinLift = 50;
  static const double heartLift = 56;

  /// Extra coins on a high platform: at a quarter and three quarters of its width.
  static const List<double> coinFractions = [.25, .75];

  /// Keep clear of the start and the exit for a heart or a flag.
  static const double heartEdgeMargin = 700;
  static const double flagClearance = 170;

  /// Coins to add (top-left positions).
  final List<Vector2> bonusCoins;

  /// Where the heart goes (top-left), or null when this level has none.
  final Vector2? heart;

  /// The flag: pole x and the surface it stands on, or null when none fits.
  final ({double x, double surfaceY})? flag;

  /// Platforms that count as high.
  final List<LevelEntity> highPlatforms;

  /// Coins already in the map that lie on a high platform.
  final Set<LevelEntity> highAuthoredCoins;

  const LevelExtras({
    this.bonusCoins = const [],
    this.heart,
    this.flag,
    this.highPlatforms = const [],
    this.highAuthoredCoins = const {},
  });

  static const LevelExtras none = LevelExtras();

  /// How many coins on high platforms the level has in all.
  int get highCoinCount => highAuthoredCoins.length + bonusCoins.length;

  bool isHighCoin(LevelEntity e) => highAuthoredCoins.contains(e);

  /// Whether [levelNo] of [eraId] is one of the levels that hold a heart: a steady
  /// half of them, picked from the name so it never changes between tries.
  static bool levelHasHeart(String eraId, int levelNo) {
    var h = 17;
    for (final c in '$eraId:$levelNo'.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h.isEven;
  }

  static LevelExtras plan(
    LoadedLevel level, {
    required String eraId,
    required int levelNo,
    double groundY = LoadedLevel.groundSurfaceY,
  }) {
    if (level.isArena) return none;

    final platforms = level.entities
        .where((e) =>
            e.type == 'platform' && e.y <= groundY - highPlatformRise)
        .toList();

    // Coins already lying on a high platform.
    final authored = <LevelEntity>{};
    for (final c in level.entities.where((e) => e.type == 'coin')) {
      for (final p in platforms) {
        if (c.x >= p.x - 24 &&
            c.x <= p.x + p.width + 24 &&
            c.y <= p.y &&
            c.y >= p.y - 140) {
          authored.add(c);
          break;
        }
      }
    }

    // Two more on every high platform that carries fewer than two.
    final bonus = <Vector2>[];
    for (final p in platforms) {
      final have = authored
          .where((c) => c.x >= p.x - 24 && c.x <= p.x + p.width + 24)
          .length;
      if (have >= 2) continue;
      for (final f in coinFractions) {
        final x = p.x + p.width * f - 21;
        final taken = authored.any((c) => (c.x - x).abs() < 30);
        if (!taken) bonus.add(Vector2(x, p.y - coinLift));
      }
    }

    // The heart: on the highest platform that is not near the start or the exit.
    Vector2? heart;
    if (levelHasHeart(eraId, levelNo)) {
      LevelEntity? best;
      for (final p in platforms) {
        final mid = p.x + p.width / 2;
        if (mid < level.spawnX + heartEdgeMargin ||
            mid > level.exitX - heartEdgeMargin) {
          continue;
        }
        if (best == null || p.y < best.y) best = p;
      }
      if (best != null) {
        heart = Vector2(best.x + best.width / 2 - 22, best.y - heartLift);
      }
    }

    return LevelExtras(
      bonusCoins: bonus,
      heart: heart,
      flag: _flagSpot(level),
      highPlatforms: platforms,
      highAuthoredCoins: authored,
    );
  }

  /// A spot on solid ground about halfway between the start and the exit, away from
  /// artifacts and enemies; null if the level has no ground wide enough there.
  static ({double x, double surfaceY})? _flagSpot(LoadedLevel level) {
    final target = (level.spawnX + level.exitX) / 2;
    final crowd = [
      for (final e in level.entities)
        if (e.type == 'artifact' || e.type == 'enemy' || e.type == 'gate') e.x,
    ];
    GroundBlock? bestBlock;
    double? bestX;
    var bestDistance = double.infinity;
    for (final b in level.blocks) {
      if (b.width < 2 * flagClearance) continue;
      final lo = b.startX + 120, hi = b.endX - 120;
      if (hi < lo) continue;
      // Slide along the block from the point nearest the target until clear.
      final start = target.clamp(lo, hi);
      for (var step = 0; step < 16; step++) {
        final offset = (step.isEven ? 1 : -1) * 60.0 * ((step + 1) ~/ 2);
        final x = (start + offset);
        if (x < lo || x > hi) continue;
        if (crowd.any((c) => (c - x).abs() < flagClearance)) continue;
        final d = (x - target).abs();
        if (d < bestDistance) {
          bestDistance = d;
          bestBlock = b;
          bestX = x;
        }
        break;
      }
    }
    if (bestBlock == null || bestX == null) return null;
    return (x: bestX, surfaceY: bestBlock.topY);
  }
}
