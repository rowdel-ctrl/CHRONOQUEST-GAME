import 'chrono_game.dart';
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
/// How much of the character's width counts as "feet" for ground support,
/// as a fraction centred on the sprite.
///
/// 0.5 means the middle half of the sprite has to be over something solid.
/// Lower values make ledges more forgiving to stand on and gaps harder to
/// fall into; 1.0 restores the pre-Phase-4 behaviour where any overlap at
/// all counted, which made a gap narrower than the sprite impossible to
/// fall through.
const double footSpanFraction = 0.5;

extension GroundQueries on ChronoGame {
  /// Whether the horizontal span [left]..[right] lies entirely over one
  /// ground section. Walkers use this to turn around at a ledge instead of
  /// strolling out over a gap.
  ///
  /// With no ground registered at all (a bare test game) there is nothing to
  /// be unsupported by, so the answer is true and patrols stay unconstrained.
  bool isGroundUnder(double left, double right) {
    if (groundSections.isEmpty) return true;
    for (final section in groundSections) {
      if (left >= section.position.x &&
          right <= section.position.x + section.size.x) {
        return true;
      }
    }
    return false;
  }
}

extension PlayerGroundCollision on PlayerComponent {
  /// Snaps onto the first ground section or platform the player's feet are
  /// touching this frame and zeroes vertical velocity. Returns whether
  /// ground contact was made.
  ///
  /// Platforms only count while falling or resting (`velocityY >= 0`), which
  /// is the "one-way" part: jumping up into a platform from below doesn't
  /// snap the player onto its surface.
  bool resolveGroundContact() {
    // Horizontal support is tested against a narrow band under the
    // character's CENTRE, not their full width.
    //
    // This matters as of Phase 4, and it is why the first Tiled gaps did
    // nothing. The old test asked "does any part of my bounding box overlap
    // this section?" — with a 96px-wide player and a 96px gap, one edge was
    // always still over the ledge on either side, so the player was never
    // unsupported and simply walked across thin air. Widening the gap past
    // the sprite width would have hidden it, not fixed it: the same test
    // also let you stand with a single pixel on a ledge and hang in space.
    //
    // A foot span is what "standing on something" actually means. Kept
    // deliberately forgiving (it does not require the whole sprite to be
    // supported) so edges stay generous to land on, which is what the tuned
    // jump arc was built around.
    final footHalfWidth = size.x * footSpanFraction / 2;
    final footLeft = position.x + size.x / 2 - footHalfWidth;
    final footRight = position.x + size.x / 2 + footHalfWidth;

    for (final section in game.groundSections) {
      if (footRight > section.position.x &&
          footLeft < section.position.x + section.size.x &&
          position.y + size.y >= section.position.y &&
          position.y + size.y <= section.position.y + 20) {
        position.y = section.position.y - size.y;
        velocityY = 0;
        return true;
      }
    }
    if (velocityY >= 0) {
      for (final platform in game.platforms) {
        if (footRight > platform.position.x &&
            footLeft < platform.position.x + platform.size.x &&
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
