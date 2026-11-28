import '../../core/cave_constants.dart';

// The four obstacles of the cave as plain data and plain rules (nothing here is a
// component, so the layout and the tests can use it without a running game). The
// components that draw and play them are in cave_obstacle_components.dart.

/// A cluster of 1 to 3 stalagmite spikes standing on the floor, [x] its left edge.
class CaveSpikeSpot {
  final double x;
  final int count;
  const CaveSpikeSpot(this.x, this.count);

  double get width => count * CaveConstants.spikeWidth;
  double get endX => x + width;
  double get centerX => x + width / 2;
}

/// A stalactite hanging over the floor, [x] the middle of its spot (and of the
/// shadow that grows under it).
class CaveStalactiteSpot {
  final double x;
  const CaveStalactiteSpot(this.x);
}

/// A stone crusher on a chain, [centerX] the middle of the block.
class CaveCrusherSpot {
  final double centerX;
  const CaveCrusherSpot(this.centerX);

  double get left => centerX - CaveConstants.crusherWidth / 2;
  double get right => centerX + CaveConstants.crusherWidth / 2;
}

/// What the crusher block does, in order, over one cycle.
enum CrusherPhase { up, warn, slam, hold, rise }

/// The stone crusher's cycle as a pure function of time: up 1.5 s, shaking 0.6 s
/// (the warning), slam 0.3 s, hold 0.3 s, rise 0.6 s; 3.3 s in all.
class CrusherCycle {
  CrusherCycle._();

  /// Where in the cycle [t] seconds of running time falls, 0 up to the cycle's
  /// length.
  static double wrap(double t) {
    const c = CaveConstants.crusherCycle;
    final r = t % c;
    return r < 0 ? r + c : r;
  }

  static CrusherPhase phaseAt(double t) {
    var r = wrap(t);
    if (r < CaveConstants.crusherUp) return CrusherPhase.up;
    r -= CaveConstants.crusherUp;
    if (r < CaveConstants.crusherWarn) return CrusherPhase.warn;
    r -= CaveConstants.crusherWarn;
    if (r < CaveConstants.crusherSlam) return CrusherPhase.slam;
    r -= CaveConstants.crusherSlam;
    if (r < CaveConstants.crusherHold) return CrusherPhase.hold;
    return CrusherPhase.rise;
  }

  /// Seconds into the phase [t] is in.
  static double timeInPhase(double t) {
    var r = wrap(t);
    for (final len in [
      CaveConstants.crusherUp,
      CaveConstants.crusherWarn,
      CaveConstants.crusherSlam,
      CaveConstants.crusherHold,
    ]) {
      if (r < len) return r;
      r -= len;
    }
    return r;
  }

  /// How far the bottom of the block is above the floor at [t].
  static double bottomHeightAt(double t) {
    const rest = CaveConstants.crusherRestHeight;
    final p = timeInPhase(t);
    switch (phaseAt(t)) {
      case CrusherPhase.up:
      case CrusherPhase.warn:
        return rest;
      case CrusherPhase.slam:
        final u = (p / CaveConstants.crusherSlam).clamp(0.0, 1.0);
        return rest * (1 - u * u); // speeds up as it falls
      case CrusherPhase.hold:
        return 0;
      case CrusherPhase.rise:
        final u = (p / CaveConstants.crusherRise).clamp(0.0, 1.0);
        return rest * (u * u * (3 - 2 * u)); // eased at both ends
    }
  }

  /// Only a block that is moving down or resting on the floor hurts.
  static bool hurts(CrusherPhase phase) =>
      phase == CrusherPhase.slam || phase == CrusherPhase.hold;
}

/// What the cave's pieces add up to once the obstacles are placed on them.
class CaveObstacles {
  final List<CaveSpikeSpot> spikes;
  final List<CaveStalactiteSpot> stalactites;
  final List<CaveCrusherSpot> crushers;

  /// The indexes (in the layout's platform list) of the slabs that crumble.
  final Set<int> crumblingSlabs;

  const CaveObstacles({
    this.spikes = const [],
    this.stalactites = const [],
    this.crushers = const [],
    this.crumblingSlabs = const {},
  });
}
