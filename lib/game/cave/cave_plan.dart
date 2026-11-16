import '../../core/cave_constants.dart';
import '../../core/combat_constants.dart';
import '../level_loader.dart';

/// Where a level's pipe stands, and which artifact it takes the place of.
class CavePipe {
  /// World x of the pipe's middle, and the world y of the ground it stands on.
  final double centerX;
  final double surfaceY;

  /// The artifact object that is not placed in the road: it is the cave's.
  final LevelEntity artifact;

  const CavePipe(this.centerX, this.surfaceY, this.artifact);
}

/// Decides where a level's pipe goes.
///
/// The level map is not changed: the road stays as it was authored and solved. One
/// of its ten artifacts (one near the middle of the road, not the golden one) is
/// taken to the cave and so is not placed, and a pipe stands on flat ground (the
/// base ground or the top of a mesa) as near to where it was as is safe. Safe means:
///
/// - on one block of ground with [CaveConstants.pipeClearSide] free on both
///   sides of the pipe's body, so there is room to take off and to land and no pit
///   or wall of raised ground nearby that could trap the student against it;
/// - no enemy's whole pacing corridor within that room;
/// - nothing else of the road close by (a gate, the halfway flag, a ground pop or a
///   falling rock, another artifact).
class CavePlan {
  /// The pipe for [level], or null when no place is safe (the level then simply
  /// has no pipe and its ten artifacts stay on the road).
  static CavePipe? plan(LoadedLevel level) {
    final artifacts = [
      for (final e in level.entities)
        if (e.type == 'artifact') e,
    ]..sort((a, b) => a.x.compareTo(b.x));
    if (artifacts.length < 3) return null;

    // The artifact taken to the cave: the non-golden one nearest the middle.
    final middle = (artifacts.length - 1) / 2;
    LevelEntity? taken;
    var best = double.infinity;
    for (var i = 0; i < artifacts.length; i++) {
      if (artifacts[i].golden) continue;
      final gap = (i - middle).abs();
      if (gap < best) {
        best = gap;
        taken = artifacts[i];
      }
    }
    if (taken == null) return null;

    // The place for the pipe: the safe spot nearest to where that artifact was.
    final target = taken.x + CombatConstants.artifactSize / 2;
    double? bestX, bestY;
    var bestDistance = double.infinity;
    for (final block in level.blocks) {
      for (var c = block.startX; c <= block.endX; c += 24) {
        if (!isSafeSpot(level, c, ignoring: taken)) continue;
        final d = (c - target).abs();
        if (d < bestDistance) {
          bestDistance = d;
          bestX = c;
          bestY = block.topY;
        }
      }
    }
    if (bestX == null || bestY == null) return null;
    return CavePipe(bestX, bestY, taken);
  }

  /// Whether a pipe centred on world x [centre] is safe in [level]. [ignoring] is
  /// the artifact that is being taken to the cave (it is not placed, so it is no
  /// obstacle).
  static bool isSafeSpot(LoadedLevel level, double centre,
      {LevelEntity? ignoring}) {
    const clear = CaveConstants.pipeClearSide + CaveConstants.pipeBodyWidth / 2;
    final block = level.blockAt(centre);
    if (block == null) return false;
    if (centre - clear < block.startX || centre + clear > block.endX) {
      return false;
    }
    for (final other in level.entities) {
      if (identical(other, ignoring)) continue;
      switch (other.type) {
        case 'enemy':
          // The enemy's whole pacing corridor must stay clear of the pipe and the
          // room to take off and land beside it.
          final range = other.behavior == 'heavy'
              ? 0.0
              : (other.patrol ?? CombatConstants.patrolRange);
          final left = other.x - range, right = other.x + 90 + range;
          if (right > centre - clear && left < centre + clear) return false;
        case 'artifact':
          if ((other.x + CombatConstants.artifactSize / 2 - centre).abs() <
              clear) {
            return false;
          }
        case 'gate':
        case 'halfway_flag':
        case 'ground_pop':
        case 'falling_rock':
          if ((other.x - centre).abs() < clear) return false;
      }
    }
    return true;
  }
}
