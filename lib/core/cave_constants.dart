/// Every number of the underground cave in one place (the 2026-11 update).
///
/// In some levels a pipe stands in the road. The student walks onto it, goes down
/// into a cave of their own, answers that level's last artifact there and comes
/// back up the same pipe. The cave artifact is one of the level's 10, so a level
/// still has exactly 10 and its end gate opens only once the cave artifact is
/// answered: the pipe is not optional in a level that has one.
class CaveConstants {
  /// The levels that have a pipe, by era id. At least half of each era's levels
  /// (the boss room is never one): the even ones, plus the last ordinary level
  /// when the era has an odd number of them. Level 1 never has one: the first
  /// level of an era teaches the ordinary run.
  static const Map<String, Set<int>> pipeLevels = {
    'pre-colonial': {2, 4, 6, 8, 9},
    'spanish': {2, 4},
    'nationalism': {2, 4, 6},
    'american': {2, 4, 6, 7},
    'ww2': {2, 4, 6, 7},
    'modern': {2, 4},
  };

  /// Whether [levelNo] of [eraId] has a pipe.
  static bool hasPipe(String eraId, int levelNo) =>
      pipeLevels[eraId]?.contains(levelNo) ?? false;

  // ─── The pipe ────────────────────────────────────────────────────────────
  /// Drawn size of the standing pipe: the body, the wider rim, and how high the
  /// top is above the ground. 72 is three tiles: a wall the student has to jump
  /// (the jump peaks at 128), and a top wide enough to stand on.
  static const double pipeBodyWidth = 96;
  static const double pipeRimWidth = 120;
  static const double pipeHeight = 72;

  /// The student is "on" the pipe when the middle of the body is within this of the
  /// pipe's middle and the feet are on its top. Standing there for [pipeStandSeconds]
  /// takes them down (up).
  static const double pipeEnterHalfWidth = 44;
  static const double pipeStandSeconds = 0.25;

  /// How much flat ground, either side of the artifact the pipe replaces, must be
  /// free of enemies and pits for the pipe to go there.
  static const double pipeClearSide = 100;

  /// The arrow and the "SA ILALIM" sign show when the student is this close
  /// (world units), so the pipe is found without the sign shouting from afar.
  static const double pipeSignRange = 700;

  // ─── The cave ────────────────────────────────────────────────────────────
  /// World x where the student lands, the x of the artifact and of the exit pipe,
  /// and the width of the whole map. About 60 to 90 seconds of walking, fighting
  /// and jumping at the hero's 250 a second, plus the question.
  static const double spawnX = 220;
  static const double artifactX = 7200;
  static const double exitPipeX = 7800;
  static const double mapWidth = 8400;

  /// How wide a pit may be (a full-speed jump covers about 266) and how high a
  /// platform top may be above the floor (the jump peaks at 128).
  static const double maxPitWidth = 130;
  static const double minPlatformRise = 96;
  static const double maxPlatformRise = 112;

  /// The cave's enemies, by era id: era-appropriate art (same as the bonus round).
  static const Map<String, List<String>> enemyKinds = {
    'pre-colonial': ['tribal_warrior', 'dark_spirit'],
    'spanish': ['spanish_soldier', 'tax_collector'],
    'nationalism': ['spanish_soldier', 'tax_collector'],
    'american': ['american_soldier', 'propaganda'],
    'ww2': ['japanese_soldier', 'tank'],
    'modern': ['corruption_figure', 'misinfo_cloud'],
  };

  /// Seconds the wipe in and out of the cave takes.
  static const double fadeSeconds = 0.5;

  // ─── The four obstacles of the cave ───────────────────────────────────────
  /// Which obstacles a cave has, by the number of the level it belongs to. The
  /// spikes come first and every later step keeps what the one before had:
  /// level 3 and under: spikes; 4 and 5: and stalactites; 6 and 7: and crumbling
  /// slabs; 8 and up: and the stone crusher.
  static Set<CaveObstacle> obstaclesFor(int levelNo) => {
        CaveObstacle.spikes,
        if (levelNo >= firstStalactiteLevel) CaveObstacle.stalactite,
        if (levelNo >= firstCrumblingLevel) CaveObstacle.crumblingSlab,
        if (levelNo >= firstCrusherLevel) CaveObstacle.crusher,
      };

  static const int firstStalactiteLevel = 4;
  static const int firstCrumblingLevel = 6;
  static const int firstCrusherLevel = 8;

  /// How many of each a cave has (the crumbling slabs are 1 or 2 of the cave's
  /// own slabs, so this is the most).
  static const int spikeClusters = 2;
  static const int stalactiteCount = 2;
  static const int crumblingSlabsMax = 2;
  static const int crusherCount = 1;

  // Spikes: a cluster of 1 to 3, each 24 wide and 40 tall, on flat floor with
  // room to run up to it and to land after it (one jump clears the widest).
  static const double spikeWidth = 24;
  static const double spikeHeight = 40;
  static const int spikeMaxInCluster = 3;
  static const double spikeRunUp = 260;
  static const double spikeLanding = 200;

  // Stalactite: wakes when the hero is between these distances to its left. The
  // warning and the fall use the surprise numbers (SurpriseConstants.rockWarn,
  // rockDrop, rockRadius, rockClearHeight), so a stalactite is as fair as a rock.
  static const double stalactiteTriggerNear = 220;
  static const double stalactiteTriggerFar = 520;
  static const double stalactiteBaseWidth = 64;

  /// How high above the floor the tip hangs while it waits.
  static const double stalactiteTipHeight = 420;

  /// Flat floor wanted each side of the spot.
  static const double stalactiteRoom = 220;

  // Crumbling slab: shakes after the hero lands, falls, comes back later.
  static const double crumbleShake = 0.6;
  static const double crumbleFall = 0.45;

  /// Seconds from the end of the fall to the slab coming back.
  static const double crumbleGone = 3.0;
  static const double crumbleReturn = 0.4;

  // Stone crusher: a block on a chain over flat floor. One cycle is up (waits),
  // shakes with a "!" (the warning), slams, holds on the floor, rises.
  static const double crusherWidth = 100;
  static const double crusherHeight = 70;

  /// How far the bottom of the block is above the floor while it waits (the hero
  /// is 120 tall and walks under it).
  static const double crusherRestHeight = 175;
  static const double crusherUp = 1.5;
  static const double crusherWarn = 0.6;
  static const double crusherSlam = 0.3;
  static const double crusherHold = 0.3;
  static const double crusherRise = 0.6;
  static const double crusherCycle =
      crusherUp + crusherWarn + crusherSlam + crusherHold + crusherRise;

  /// Flat floor wanted each side of the crusher, and the clear space round the
  /// block itself (no enemy's patrol under it).
  static const double crusherRoom = 300;

  /// The crusher only runs while the hero is this close (it costs nothing far away).
  static const double crusherActiveRange = 1100;

  // Where obstacles may go: not before this x (clear of where the hero lands),
  // and every obstacle is at least this far from the next one.
  static const double obstacleMinX = 800;
  static const double obstacleSpacing = 600;
}

/// The four obstacles a cave can have.
enum CaveObstacle { spikes, stalactite, crumblingSlab, crusher }
