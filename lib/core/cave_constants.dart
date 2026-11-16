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
}
