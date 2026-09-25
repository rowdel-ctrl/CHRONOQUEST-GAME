import 'components/player_component.dart';

/// Ground/platform contact resolution for [PlayerComponent] — a hand-rolled
/// AABB test against `game.groundSections` and `game.platforms`, not a Flame
/// hitbox or collision callback. Split out of player_component.dart's
/// update() as part of the Phase 1 refactor (GAMEPLAY-V2.md Section 15).
///
/// This is also the exact spot GAMEPLAY-V2.md Section 11 (caveat 2) flags as
/// the one-way-platform logic Phase 4's Tiled migration has to re-point at
/// Tiled-sourced platform objects — kept in its own file for that reason,
/// not just line-budget hygiene.
extension PlayerGroundCollision on PlayerComponent {
  /// Snaps onto the first ground section or platform the player's feet are
  /// touching this frame and zeroes vertical velocity. Returns whether
  /// ground contact was made.
  ///
  /// Platforms only count while falling or resting (`velocityY >= 0`), which
  /// is the "one-way" part: jumping up into a platform from below doesn't
  /// snap the player onto its surface.
  bool resolveGroundContact() {
    for (final section in game.groundSections) {
      if (position.x + size.x > section.position.x &&
          position.x < section.position.x + section.size.x &&
          position.y + size.y >= section.position.y &&
          position.y + size.y <= section.position.y + 20) {
        position.y = section.position.y - size.y;
        velocityY = 0;
        return true;
      }
    }
    if (velocityY >= 0) {
      for (final platform in game.platforms) {
        if (position.x + size.x > platform.position.x &&
            position.x < platform.position.x + platform.size.x &&
            position.y + size.y >= platform.surfaceY &&
            position.y + size.y <= platform.surfaceY + 20) {
          position.y = platform.surfaceY - size.y;
          velocityY = 0;
          return true;
        }
      }
    }
    return false;
  }
}
