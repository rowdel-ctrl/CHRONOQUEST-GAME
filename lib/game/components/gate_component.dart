import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../../core/combat_constants.dart';
import '../../models/question.dart';
import '../chrono_game.dart';
import '../era_asset_keys.dart';

/// An era wall turned into a knowledge-gate (GAMEPLAY-V2.md Section 6).
///
/// "Gates are what guarantee the educational floor." A gate blocks the full
/// height of the corridor — it cannot be jumped — and only opens when its
/// question is answered correctly. A wrong answer shows the explanation and
/// then retries with a different question; there is no way past it except
/// through, which is why three per level means every student answers at
/// least three questions correctly.
///
/// Replaces the old `WallComponent`, which used the same art but simply
/// dealt contact damage and could be walked through. A hazard that hurts
/// you and a gate that stops you are different objects; keeping both would
/// have meant two things made of the same sprite with opposite rules.
class GateComponent extends SpriteComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  /// World x this gate was placed at by the spawner.
  final double worldX;

  /// True once answered correctly — the gate is crumbling and no longer
  /// blocks or re-opens a question.
  bool opened = false;

  /// True while its question overlay is open, so a second collision frame
  /// doesn't stack another question on top.
  bool questionPending = false;

  /// The question this gate last served, so a retry asks a different one.
  Question? lastQuestion;

  GateComponent({required this.worldX});

  /// The x the player is held at while this gate stands.
  double get blockX => position.x - CombatConstants.gateStandoff;

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(
      'obstacles/${eraAssetKey(game.currentEra)}_wall.png',
    );
    size = Vector2(CombatConstants.gateWidth, CombatConstants.gateHeight);
    position = Vector2(worldX, game.groundY - CombatConstants.gateHeight);
    add(RectangleHitbox());
  }

  /// Whether this gate should stop the player and open a question.
  ///
  /// Note there is deliberately no despawn check in [update] — unlike
  /// enemies and coins, a gate is never culled for being behind the camera.
  /// The player can walk back to one, and a gate that respawned closed
  /// would re-block a corridor they had already earned passage through.
  bool get isBlocking => !opened;

  /// Called after a correct answer — crumble and stop blocking.
  void open() {
    if (opened) return;
    opened = true;
    questionPending = false;
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
