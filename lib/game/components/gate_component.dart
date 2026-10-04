import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../../core/combat_constants.dart';
import '../chrono_game.dart';

/// An era wall turned into a knowledge-gate (GAMEPLAY-V2.md Section 6).
///
/// A gate blocks the full height of the corridor and cannot be jumped. Since
/// 2026-10-04 it asks **no question of its own**: each level has one, at the
/// exit, and it opens by itself the moment the student reaches it with every
/// artifact in the level answered (right or wrong). Until then it only tells
/// them how many artifacts are left. The questions all live on the artifacts.
///
/// Replaces the old `WallComponent`, which used the same art but simply
/// dealt contact damage and could be walked through. A hazard that hurts
/// you and a gate that stops you are different objects; keeping both would
/// have meant two things made of the same sprite with opposite rules.
/// Extends `PositionComponent with HasPaint` rather than `SpriteComponent`:
/// the gate is drawn from tiles in [render], so it has no single sprite, and
/// inheriting an unused `sprite` field would invite exactly the stretched
/// draw this component was changed to stop doing. `HasPaint` is kept because
/// [open]'s `OpacityEffect` fades that paint.
class GateComponent extends PositionComponent
    with HasGameReference<ChronoGame>, HasPaint, CollisionCallbacks {
  /// World x this gate was placed at by the spawner.
  final double worldX;

  /// True once open — the gate is crumbling and no longer blocks.
  bool opened = false;

  GateComponent({required this.worldX, this.isLevelExit = false});

  /// The x the player is held at while this gate stands.
  double get blockX => position.x - CombatConstants.gateStandoff;

  /// On-screen size of one tile, matching TilePlatformComponent exactly so
  /// a gate reads at the same scale as the platforms and ground beside it.
  static const double tileSize = 24;

  /// Size of one tile in the source sheet (unchanged — the sheet is a grid
  /// of 16px tiles, they are just drawn larger).
  static const double sourceTileSize = 16;

  // Grid coordinates (row, column) into ground_tileset.png, 0-indexed from
  // the top-left. These are the same pixel-verified constants
  // TilePlatformComponent uses for its fill row: (1,3) and (1,5) are the
  // plain wall tiles carrying the left and right side borders, (1,4) is the
  // plain fill between them. Stacked vertically they build a solid column
  // whose sides stay bordered all the way up.
  static const int _leftRow = 1, _leftCol = 3;
  static const int _midRow = 1, _midCol = 4;
  static const int _rightRow = 1, _rightCol = 5;

  /// Grass-capped tile for the very top course, so the gate reads as built
  /// rather than cut off: (1,1)/(0,1)/(1,2) are the same caps a platform
  /// uses for its top-left / middle / top-right.
  static const int _capLeftRow = 1, _capLeftCol = 1;
  static const int _capMidRow = 0, _capMidCol = 1;
  static const int _capRightRow = 1, _capRightCol = 2;

  late final SpriteSheet _sheet;

  /// How many tiles wide and tall this gate is.
  late final int _cols;
  late final int _rows;

  /// Paint for one drawn tile.
  ///
  /// Built per render from the component's own [paint] rather than cached,
  /// because `open()` fades the gate out with an `OpacityEffect`, which
  /// works by mutating that paint's alpha. A cached Paint would ignore the
  /// fade and the gate would vanish instantly instead of crumbling.
  ///
  /// Filtering is disabled for the same reason as TilePlatformComponent and
  /// GroundSection: tiles are drawn at fractional world positions, and with
  /// filtering on each tile's edge blends with what is behind it, leaving
  /// faint seams between them.
  Paint get _tilePaint => Paint()
    ..color = paint.color
    ..colorFilter = paint.colorFilter
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;

  @override
  Future<void> onLoad() async {
    // Built from the ground tileset, not the era wall art.
    //
    // The wall sprites are 40x50 standalone objects, and SpriteComponent
    // scaled one to fill the gate's 48x260 — **5.2x taller than it was
    // drawn**. That non-uniform smear is what made the gate read as a
    // strange ladder; the subject was fine, the stretch was not. Swapping in
    // different wall art would have smeared identically.
    //
    // The ground tileset is the game's existing visual vocabulary (the
    // ground and every platform are already built from it) and is actually
    // designed to repeat, so a gate made from it looks like part of the
    // world instead of a sprite pasted onto it — and it solves all six eras
    // at once rather than only the two whose wall art happens to tile.
    final tileset = await game.loadSprite('tiles/ground_tileset.png');
    _sheet = SpriteSheet(
      image: tileset.image,
      srcSize: Vector2.all(sourceTileSize),
    );

    _cols = (CombatConstants.gateWidth / tileSize).ceil();
    _rows = (CombatConstants.gateHeight / tileSize).ceil();

    // Snap to whole tiles so nothing is ever part-drawn.
    size = Vector2(_cols * tileSize, _rows * tileSize);
    position = Vector2(worldX, game.groundY - size.y);

    add(RectangleHitbox());
  }

  /// Draws the gate as a tiled column: a grass-capped top course over
  /// repeated wall tiles, with the side borders running the full height.
  @override
  void render(Canvas canvas) {
    final tilePaint = _tilePaint;

    for (var row = 0; row < _rows; row++) {
      final isCap = row == 0;
      for (var col = 0; col < _cols; col++) {
        final isLeft = col == 0;
        final isRight = col == _cols - 1;

        final int r, c;
        if (isCap) {
          r = isLeft
              ? _capLeftRow
              : isRight
                  ? _capRightRow
                  : _capMidRow;
          c = isLeft
              ? _capLeftCol
              : isRight
                  ? _capRightCol
                  : _capMidCol;
        } else {
          r = isLeft
              ? _leftRow
              : isRight
                  ? _rightRow
                  : _midRow;
          c = isLeft
              ? _leftCol
              : isRight
                  ? _rightCol
                  : _midCol;
        }

        _sheet.getSprite(r, c).render(
              canvas,
              position: Vector2(col * tileSize, row * tileSize),
              size: Vector2.all(tileSize),
              overridePaint: tilePaint,
            );
      }
    }
  }

  /// Whether this gate should stop the player.
  ///
  /// Note there is deliberately no despawn check in [update] — unlike
  /// enemies and coins, a gate is never culled for being behind the camera.
  /// The player can walk back to one, and a gate that respawned closed
  /// would re-block a corridor they had already earned passage through.
  bool get isBlocking => !opened;

  /// Whether every artifact in the level has been answered.
  ///
  /// The end gate is the level's exit (playtest decision, 2026-10-03), and it
  /// stays shut until every artifact has been answered — right or wrong.
  /// Until then, walking into it shows a count of what is left, so the
  /// student is told why they are blocked instead of just being stopped.
  bool get requirementMet => game.canPassEndGate;

  /// Whether passing this gate completes the level. Every level's single
  /// gate is its exit, so this is true for all of them; it is kept as a flag
  /// so a gate could be placed elsewhere without ending the level.
  final bool isLevelExit;

  /// Crumble and stop blocking.
  void open() {
    if (opened) return;
    opened = true;
    game.audioService.playEnemyDefeat();
    add(
      SequenceEffect(
        [
          MoveEffect.by(Vector2(0, 12), EffectController(duration: 0.12)),
          OpacityEffect.fadeOut(EffectController(duration: 0.25)),
        ],
        onComplete: removeFromParent,
      ),
    );
  }
}
