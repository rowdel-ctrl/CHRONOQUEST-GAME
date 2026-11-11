/// Every number of the golden artifact and its bonus round in one place (the
/// 2026-11 update). Kept apart from `combat_constants.dart` on purpose.
class BonusConstants {
  // ─── The golden artifact ─────────────────────────────────────────────────
  /// One artifact in each level, from this level on, is golden (the map marks it
  /// with `golden="true"`). Never in the first level, never in a boss level.
  static const int firstGoldenLevel = 2;

  // ─── The portal in the level ─────────────────────────────────────────────
  /// How long the portal stays open for a walk-in, after it has finished opening.
  static const double portalSeconds = 5.0;

  /// Seconds the portal takes to open, and to close again. While it opens it
  /// cannot be entered, so a student who answered standing on top of the spot
  /// is not swallowed at once.
  static const double portalOpenSeconds = 0.8;
  static const double portalCloseSeconds = 0.45;

  /// Drawn size of the standing portal, feet on the ground under the artifact.
  static const double portalWidth = 96;
  static const double portalHeight = 150;

  /// The hero is inside when the middle of the body is within this of the
  /// portal's middle (sideways) and the feet are inside its height.
  static const double portalEnterHalfWidth = 34;

  /// How long the portal glows after the hero is back, then closes.
  static const double portalReturnGlowSeconds = 1.1;

  // ─── The bonus round ─────────────────────────────────────────────────────
  static const double roundSeconds = 20.0;

  /// Coins an enemy knocks out of the bonus counter, never below 0. No heart.
  static const int enemyPenalty = 5;

  /// The map: a long stretch of floating stone, one stone floor, no pits, no water.
  /// At the hero's walking speed (250 a second) the walk from the start to the last
  /// coin takes about 17.5 seconds, so a student who keeps moving sees most of it and
  /// one who stops to fight or misses a jump does not see all.
  static const double mapWidth = 6400;
  static const double spawnX = 260;

  /// The hero's own enemies: how many walk about, and how far each paces.
  static const double enemyPatrol = 70;

  /// The seconds the BONUS banner stays up, and the pause on the tally before
  /// the coins fly to the wallet.
  static const double bannerSeconds = 1.6;

  /// How long the count-up of the tally takes.
  static const double tallyCountSeconds = 1.1;

  /// Seconds the tally stays up after the count has finished.
  static const double tallyHoldSeconds = 1.3;

  /// The wipe in and out of the round (a gold circle growing from the portal).
  static const double wipeSeconds = 0.55;

  /// The walkers of the bonus round, by era id: era-appropriate art. A walker
  /// override makes each one pace even when its kind would normally chase or lunge.
  static const Map<String, List<String>> enemyKinds = {
    'pre-colonial': ['tribal_warrior', 'dark_spirit'],
    'spanish': ['spanish_soldier', 'tax_collector'],
    'nationalism': ['spanish_soldier', 'tax_collector'],
    'american': ['american_soldier', 'propaganda'],
    'ww2': ['japanese_soldier', 'tank'],
    'modern': ['corruption_figure', 'misinfo_cloud'],
  };
}
