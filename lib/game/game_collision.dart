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

/// How far below a surface a foot still counts as standing on it (landing).
const double groundBand = 28;

/// A block that rises more than this above the feet is a wall: even one 24-unit
/// tile has to be jumped, never walked up. Both are mirrored by
/// tools/levelgen/sim.js, which the generator plays levels with;
/// test/game/terrain_parity_test.dart keeps them in step.
const double wallBand = 12;

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

  /// Whether the span [left]..[right] lies entirely over one platform whose top
  /// is at [surfaceY]. An enemy standing on a platform uses this to turn round
  /// at its edge, the way a ground enemy does at a ledge.
  bool isPlatformUnder(double left, double right, double surfaceY) {
    for (final p in platforms) {
      if ((p.surfaceY - surfaceY).abs() < 1 &&
          left >= p.position.x &&
          right <= p.position.x + p.size.x) {
        return true;
      }
    }
    return false;
  }

  /// Whether the span lies entirely over one thing whose top is at [surfaceY]: a
  /// platform, or a block of raised ground. What an enemy above the base ground
  /// checks before each step, so it turns round at the edge of its mesa the way
  /// one on a platform does.
  bool isSurfaceUnder(double left, double right, double surfaceY) {
    if (isPlatformUnder(left, right, surfaceY)) return true;
    for (final s in groundSections) {
      if ((s.position.y - surfaceY).abs() < 1 &&
          left >= s.position.x &&
          right <= s.position.x + s.size.x) {
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

    // The highest ground the feet are at: with raised ground, two sections can
    // both be within reach (the foot span over a step), and the higher one is
    // the one being stood on.
    final feet = position.y + size.y;
    double? best;
    for (final section in game.groundSections) {
      if (footRight > section.position.x &&
          footLeft < section.position.x + section.size.x &&
          feet >= section.position.y &&
          feet <= section.position.y + groundBand &&
          (best == null || section.position.y < best)) {
        best = section.position.y;
      }
    }
    if (best == null && velocityY >= 0) {
      for (final platform in game.platforms) {
        if (footRight > platform.position.x &&
            footLeft < platform.position.x + platform.size.x &&
            feet >= platform.surfaceY &&
            feet <= platform.surfaceY + groundBand &&
            (best == null || platform.surfaceY < best)) {
          best = platform.surfaceY;
        }
      }
    }
    if (best == null) return false;
    position.y = best - size.y;
    velocityY = 0;
    return true;
  }

  /// Raised ground is solid at its sides: a block that rises more than
  /// [wallBand] above the feet is a wall, and the player is pushed back out of
  /// it to the side they came from. Run right after every horizontal move.
  ///
  /// [previousCentreX] is where the middle of the sprite was before this frame's
  /// move, which says which side of the wall the player is on.
  ///
  void resolveWalls(double previousCentreX) {
    final feet = position.y + size.y;
    final footHalfWidth = size.x * footSpanFraction / 2;
    final centre = position.x + size.x / 2;
    final left = centre - footHalfWidth;
    final right = centre + footHalfWidth;
    for (final section in game.groundSections) {
      final start = section.position.x;
      final end = start + section.size.x;
      if (!(right > start && left < end)) continue;
      // On the ground any rise over [wallBand] is a wall; in the air a landing that
      // is a little low (up to [groundBand]) still snaps up onto the ledge.
      if (!(feet > section.position.y + (isOnGround ? wallBand : groundBand))) {
        continue;
      }
      final cameFromLeft = previousCentreX + footHalfWidth <= start;
      final cameFromRight = previousCentreX - footHalfWidth >= end;
      final toLeft = cameFromLeft
          ? true
          : cameFromRight
              ? false
              : centre < (start + end) / 2;
      position.x = toLeft
          ? start - footHalfWidth - size.x / 2
          : end + footHalfWidth - size.x / 2;
    }
  }
}
