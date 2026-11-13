import 'dart:ui' show Offset;

import '../core/bonus_constants.dart';
import '../core/combat_constants.dart';
import 'bonus/bonus_session.dart';
import 'chrono_game.dart';
import 'components/artifact_component.dart';
import 'components/golden_portal_component.dart';

/// The level's side of the golden artifact and its bonus round: opening the
/// portal after a first-try right answer, handing the hero over to the round when
/// the portal is walked into, and picking the level up again, exactly as it was,
/// when the hero comes back. The round itself is `bonus/bonus_game.dart`.
///
/// Kept apart from `answer_point_handler.dart`, which only calls
/// [openGoldenPortal] from its one right-answer branch.
extension BonusHandler on ChronoGame {
  /// Whether a bonus portal may open in this level at all: from level 2 on,
  /// never in a boss level, and only the one time.
  bool get canOfferBonus =>
      currentLevel >= BonusConstants.firstGoldenLevel &&
      !isBossLevel &&
      !bonus.offered &&
      !levelEnded;

  /// A golden artifact was just answered right on the first try: open its portal
  /// where it stood. Does nothing for an ordinary artifact, or when this level
  /// has already offered its one portal.
  void openGoldenPortal(ArtifactComponent artifact) {
    if (!artifact.golden || !canOfferBonus) return;
    bonus.offered = true;
    final portal = GoldenPortalComponent(
      centerX: artifact.worldX + CombatConstants.artifactSize / 2,
      surfaceY: artifact.surfaceY ?? groundY,
    );
    bonus.portal = portal;
    world.add(portal);
    audioService.playPowerup();
  }

  /// The hero has walked into the open portal: hold the level still and show the
  /// round. Nothing here runs again until the round is over and [finishBonus] has
  /// put the level back to work.
  Future<void> enterBonusPortal(GoldenPortalComponent portal) async {
    if (!portal.canEnter ||
        bonus.away ||
        levelEnded ||
        questionShowing ||
        gateReveal != null) {
      return;
    }
    final show = bonus.onEnter;
    if (show == null) {
      // Nothing to show the round with (a bare game): the portal just closes.
      portal.close();
      return;
    }
    bonus.away = true;
    bonus.played = true;
    portal.beginEnter();
    audioService.playTeleport();
    audioService.playBonusBgm();
    pauseEngine();
    BonusResult? result;
    try {
      result = await show(BonusRequest(
        eraId: currentEra,
        levelNo: currentLevel,
        characterId: selectedCharacterId,
        controlScheme: controlScheme.name,
        portalOnScreen: _portalOnScreen(portal),
      ));
    } catch (_) {
      result = null; // the round could not be shown: carry on as normal
    }
    audioService.playBgm(currentEra); // the era's own music again
    finishBonus(result);
  }

  /// The hero is back (or the round could not be shown): the coins won are added
  /// to the level's own count (the wallet already has them), the portal glows and
  /// closes, and the level carries on from the exact moment it was held.
  void finishBonus(BonusResult? result) {
    if (!bonus.away) return;
    bonus.away = false;
    final coins = result?.coins ?? 0;
    if (coins > 0) {
      playerCoins += coins;
      bonus.coinsWon += coins;
    }
    final portal = bonus.portal;
    if (portal != null && !portal.isGone) portal.beginReturn();
    if (isMounted && !levelEnded) resumeEngine();
    notifyState();
  }

  Offset _portalOnScreen(GoldenPortalComponent portal) {
    final c = portal.worldCenter;
    double frac(double v) => v.isFinite ? v.clamp(0.0, 1.0) : 0.5;
    return Offset(
      frac((c.x - cameraLeftEdgeX) / size.x),
      frac(c.y / size.y),
    );
  }
}
