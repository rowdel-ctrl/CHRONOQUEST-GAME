import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../../core/combat_constants.dart';
import '../chrono_game.dart';
import '../enemy_behavior.dart';
import 'coin_component.dart';

/// Enemy encountered as the player advances through the world. Spawns at a
/// fixed world position ahead of the camera; the camera moving past it (as
/// the player's worldX increases) is what creates the on-screen leftward
/// motion for a stationary Heavy, on top of whatever patrol movement a
/// Walker adds itself. Renders a 2-frame walk cycle from image files.
///
/// No longer carries a `Question` (GAMEPLAY-V2.md Section 15, Phase 2:
/// enemies no longer open the quiz on contact — that whole loop, and the
/// `?` indicator that signalled it, is gone). Contact/attack damage now
/// drive this component instead; see [takeHit] and `PlayerComponent`'s
/// contact-damage handling.
class EnemyComponent extends SpriteAnimationComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  final String eraId;

  /// True once HP has reached 0 and the death sequence has started —
  /// checked before any further hit or contact-damage processing so a
  /// still-visible, fading enemy can't be re-hit or deal a second contact
  /// hit while its death effect plays out.
  bool defeated = false;

  late final String _enemyType;
  late final EnemyBehavior _behavior;
  late int _hp;

  /// Walker only: the world-x this enemy spawned at, and which direction
  /// it's currently walking — patrol range is measured from this anchor,
  /// not from wherever the enemy has wandered to. [_direction] also decides
  /// which way the sprite is drawn (see [render]).
  double _spawnX = 0;
  int _direction = 1;

  /// Which way this enemy is currently walking: -1 left, 1 right. Drives
  /// both patrol movement and which way the sprite is drawn ([render]).
  @visibleForTesting
  int get patrolDirection => _direction;

  final Random _random = Random();

  /// Forces a specific sprite type instead of picking randomly from
  /// [eraId]'s pair — every era mixes exactly one Walker and one Heavy
  /// sprite (enemy_behavior.dart's table), so era alone can't deterministically
  /// select a behaviour for a test.
  @visibleForTesting
  final String? enemyTypeOverride;

  EnemyComponent({required this.eraId, this.enemyTypeOverride});

  @override
  Future<void> onLoad() async {
    _enemyType = enemyTypeOverride ?? _getEnemyTypeForEra(eraId);
    final typeData = enemyTypeDataFor(_enemyType);
    _behavior = typeData.behavior;
    _hp = typeData.maxHp;

    // Load the 2-frame walking cycle
    final frame1 = await game.loadSprite('enemies/${_enemyType}_1.png');
    final frame2 = await game.loadSprite('enemies/${_enemyType}_2.png');

    animation = SpriteAnimation.spriteList(
      [frame1, frame2],
      stepTime: 0.3,
    );

    // 1.5x the native 60x72 art. Everything in the world except the player
    // (96x120) and boss (120x140) used to render at native size, so the
    // player towered over enemies that were supposed to threaten them. The
    // hitbox below is added after this and derives from `size`, so the hit
    // area grows with the sprite — deliberate, since the sprite is what the
    // student aims at.
    size = Vector2(90, 108);
    position = Vector2(
      game.cameraRightEdgeX + 60,
      game.groundY - size.y,
    );
    _spawnX = position.x;
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (defeated) return;

    if (_behavior == EnemyBehavior.walker) {
      position.x += CombatConstants.patrolSpeed * _direction * dt;
      final offsetFromSpawn = position.x - _spawnX;
      if (offsetFromSpawn.abs() >= CombatConstants.patrolRange) {
        // Clamp back onto the range's edge rather than let one frame's
        // movement overshoot it, then turn around.
        position.x = _spawnX + CombatConstants.patrolRange * _direction;
        _direction = -_direction;
      }
    }
    // Heavy: deliberately no movement of its own ("barely moves" — Section
    // 5). The camera panning past it is the only motion it shows.

    if (position.x < game.cameraLeftEdgeX - size.x) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // The enemy art faces left natively (enemies originally only ever
    // advanced toward the player), so walking left needs no flip and
    // walking right does — the opposite of PlayerComponent, whose art
    // faces right.
    if (_direction < 0) {
      super.render(canvas);
      return;
    }
    // Mirrored via a render-local canvas transform rather than
    // `flipHorizontally()`, for the same reason PlayerComponent avoids it:
    // that method compensates a non-center anchor by nudging `position.x`,
    // which here is world-authoritative state read by the despawn check and
    // by the patrol anchor (`_spawnX`) every frame. A transform-based flip
    // would silently displace both by ±size.x on every turn.
    canvas.save();
    canvas.translate(size.x, 0);
    canvas.scale(-1, 1);
    super.render(canvas);
    canvas.restore();
  }

  /// Called when the player's attack hitbox connects. Decrements HP and
  /// triggers the death sequence once it reaches 0 — a Heavy's first hit
  /// registers but leaves it alive and still a threat.
  void takeHit() {
    if (defeated) return;
    _hp--;
    if (_hp <= 0) _die();
  }

  void _die() {
    // Set before the effect even starts playing, not after it completes —
    // a still-visible, fading enemy must not be re-hittable or still deal
    // contact damage while it fades out.
    defeated = true;
    game.audioService.playEnemyDefeat();
    add(
      SequenceEffect(
        [
          ColorEffect(
            Colors.white,
            EffectController(duration: CombatConstants.deathColorEffectDuration),
            opacityFrom: 0,
            opacityTo: 1,
          ),
          ScaleEffect.by(
            Vector2.all(CombatConstants.deathScaleFactor),
            EffectController(duration: CombatConstants.deathScaleEffectDuration),
          ),
          OpacityEffect.fadeOut(
            EffectController(duration: CombatConstants.deathOpacityEffectDuration),
          ),
        ],
        onComplete: () {
          _dropCoins();
          removeFromParent();
        },
      ),
    );
  }

  void _dropCoins() {
    final count = CombatConstants.coinDropMin +
        _random.nextInt(
          CombatConstants.coinDropMax - CombatConstants.coinDropMin + 1,
        );
    for (var i = 0; i < count; i++) {
      game.world.add(
        CoinComponent(spawnPosition: position.clone() + Vector2(i * 10.0, 0)),
      );
    }
  }

  String _getEnemyTypeForEra(String era) {
    final enemies = {
      'pre-colonial': ['tribal_warrior', 'dark_spirit'],
      'spanish': ['spanish_soldier', 'tax_collector'],
      'american': ['american_soldier', 'propaganda'],
      'ww2': ['japanese_soldier', 'tank'],
      'modern': ['corruption_figure', 'misinfo_cloud'],
    };
    final list = enemies[era] ?? ['spanish_soldier'];
    return list[_random.nextInt(list.length)];
  }
}
