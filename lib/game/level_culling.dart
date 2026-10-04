import 'chrono_game.dart';

/// Whether a world object that has fallen behind the camera may be deleted.
///
/// **Phase 4 changed the answer to "almost never" (GAMEPLAY-V2.md Section
/// 11).** Before Phase 1 the player was locked to a fixed screen x and the
/// world scrolled past them, so anything left behind was genuinely
/// unreachable and deleting it was free. Phase 1 unlocked the player's x and
/// made the camera follow them, which means the player can now turn around
/// and walk back — and from Phase 4 the level is authored, so an object
/// culled behind them is a coin, enemy or artifact a *person placed* that
/// silently disappears.
///
/// The failure this prevents is specific and was easy to miss: walk right
/// past an artifact without claiming it, walk back, and it is gone — not
/// "respawned at the wrong place", simply absent, with its question and its
/// Codex entry unreachable for the rest of the attempt.
///
/// So objects that belong to the authored level are never culled. The only
/// thing still worth deleting is an object that is both far behind the
/// player *and* cheap to lose — which, now that the spawner is gone, is
/// nothing at all. [cullMarginX] exists so a future runtime-spawned effect
/// (hit sparks, debris) can opt in without reintroducing the old bug for
/// level content.
extension LevelCulling on ChronoGame {
  /// How far behind the camera's left edge an object must be before it is
  /// even a candidate for culling. Deliberately enormous: a level is at most
  /// a few thousand units long (`Level.lengthUnits`), so in practice nothing
  /// authored ever passes this.
  static const double cullMarginX = 100000;

  /// True when [worldX] is far enough behind the camera that deleting the
  /// object there cannot affect a player who turns around.
  ///
  /// Authored level content should not call this at all — it should simply
  /// never cull. This is for transient, regenerable effects only.
  bool isFarBehindCamera(double worldX) =>
      worldX < cameraLeftEdgeX - cullMarginX;
}
