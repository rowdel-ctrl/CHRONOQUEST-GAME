import 'dart:ui' show Offset;

import '../components/golden_portal_component.dart';

/// What the level hands to the bonus round screen when the hero walks into the
/// portal.
class BonusRequest {
  final String eraId;
  final int levelNo;
  final String characterId;

  /// The movement controls the student is using (a `ControlScheme` name), so the
  /// round has the same ones.
  final String controlScheme;

  /// Where the portal is on the level's screen, as fractions of its width and
  /// height: the gold circle that wipes into the round starts there.
  final Offset portalOnScreen;

  const BonusRequest({
    required this.eraId,
    required this.levelNo,
    required this.characterId,
    required this.controlScheme,
    this.portalOnScreen = const Offset(0.5, 0.5),
  });
}

/// How the round ended. The coins were paid into the wallet by the round itself,
/// exactly once; this is only for the level to show and remember.
class BonusResult {
  /// The coins paid: what was in the bonus counter at the end.
  final int coins;

  /// Every coin picked up, and how many an enemy knocked out of the counter.
  final int grabbed;
  final int knockedLoose;

  /// True when the student left before the 20 seconds were up.
  final bool leftEarly;

  const BonusResult({
    required this.coins,
    this.grabbed = 0,
    this.knockedLoose = 0,
    this.leftEarly = false,
  });
}

/// The level's side of the golden artifact: whether its portal has been offered,
/// whether the student is in the round right now, and who shows the round. One of
/// these lives on each `ChronoGame`.
class BonusSession {
  /// True once a portal has opened in this level, whatever came of it. One bonus
  /// round at most per level, so a second golden artifact (there is none) or a
  /// portal that is somehow opened twice never offers another.
  bool offered = false;

  /// True once the hero has walked in and the round has been played (or left).
  bool played = false;

  /// True from the walk-in until the hero is back: the level is held still.
  bool away = false;

  /// The portal standing in the level now, if any.
  GoldenPortalComponent? portal;

  /// Shows the round and gives back how it ended (null if it was torn down). Set
  /// by the game screen; null in a bare game, where a portal then just closes.
  Future<BonusResult?> Function(BonusRequest request)? onEnter;

  /// The coins the student has taken home from the round(s) in this level.
  int coinsWon = 0;
}
