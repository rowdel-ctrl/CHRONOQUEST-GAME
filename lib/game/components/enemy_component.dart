import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../../core/combat_constants.dart';
import '../chrono_game.dart';
import '../enemy_behavior.dart';
import '../game_collision.dart';
import 'coin_component.dart';
import 'player_component.dart';

enum _HeavyState { idle, windup, lunge, recover }

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

  /// Drawn size. Public so level data can be checked against the real
  /// footprint (see `LoadedLevel.enemyStaysOnGround`).
  static const double spriteWidth = 90;
  static const double spriteHeight = 108;

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

  /// Where this enemy stands, in world x. Null means "spawn just off the
  /// right edge of the camera", which is what the runtime EnemySpawner wants
  /// and what every enemy did before Phase 4. Tiled-authored enemies pass a
  /// real position instead (GAMEPLAY-V2.md Section 11) — they are placed by
  /// a person at a specific spot, not fed in from off-screen.
  final double? worldX;

  /// How far this enemy patrols from where it was placed, overriding
  /// [CombatConstants.patrolRange]. Tiled's `patrol` property maps here so a
  /// level author can make one enemy pace a wide corridor and another guard
  /// a narrow ledge.
  final double? patrolRangeOverride;

  /// World y of the surface this enemy's feet stand on, when that is a platform
  /// rather than the ground. Null means the ground. A platform enemy patrols
  /// between the platform's edges and turns round there (see [_isSupportedAt]).
  final double? surfaceY;

  /// Called once when this enemy is beaten. The boss fight uses it to pay out
  /// a Kaalaman charge for each minion.
  final VoidCallback? onDefeated;

  EnemyComponent({
    required this.eraId,
    this.enemyTypeOverride,
    this.worldX,
    this.patrolRangeOverride,
    this.surfaceY,
    this.onDefeated,
  });

  /// Effective patrol range: the authored override when there is one, else
  /// the global default.
  double get _patrolRange =>
      patrolRangeOverride ?? CombatConstants.patrolRange;

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
    size = Vector2(spriteWidth, spriteHeight);
    position = Vector2(
      worldX ?? game.cameraRightEdgeX + 60,
      (surfaceY ?? game.groundY) - size.y,
    );
    _spawnX = position.x;
    // Sized to the drawn figure, not the whole sprite box. The art has
    // transparent margins, so a full-size hitbox made the enemy hurt the
    // player from a visible gap away — the "phantom hit" the project's own
    // Flame conventions warn about, and what a playtester read as the enemy
    // damaging them without being touched.
    add(
      RectangleHitbox.relative(
        Vector2(CombatConstants.enemyHitWidthFraction, CombatConstants.enemyHitHeightFraction),
        parentSize: size,
        anchor: Anchor.center,
      ),
    );
  }

  /// Heavy only: where it is in its lunge. Idle until a student comes close,
  /// then [_HeavyState.windup] (it flashes), [_HeavyState.lunge], [_HeavyState.recover].
  _HeavyState _heavyState = _HeavyState.idle;
  double _heavyTime = 0;
  double _heavyCooldown = 0;
  int _lungeDirection = 1;

  /// True after a lunge has carried it off its spot: it shuffles back, once nobody
  /// is near. A Heavy that has not lunged never moves.
  bool _lunged = false;

  /// A chaser growls once each time a student comes into its range.
  bool _growled = false;

  /// Whether this Heavy is in its wind-up flash right now.
  @visibleForTesting
  bool get isWindingUp => _heavyState == _HeavyState.windup;

  /// Whether this Heavy is mid-lunge right now.
  @visibleForTesting
  bool get isLunging => _heavyState == _HeavyState.lunge;

  /// Walker only: set once it has turned to face a student who came close, and
  /// cleared when they leave, so it turns once per approach and not every frame.
  bool _noticed = false;

  PlayerComponent? get _playerOrNull {
    try {
      return game.player;
    } catch (_) {
      return null; // a bare game with no player
    }
  }

  /// The student, when they are close enough to matter ([range] along the ground)
  /// and on this enemy's own level (not far above or below).
  PlayerComponent? _playerWithin(double range) {
    final p = _playerOrNull;
    if (p == null) return null;
    final dx = (p.position.x + p.size.x / 2) - (position.x + size.x / 2);
    final dy = (p.position.y + p.size.y) - (position.y + size.y);
    if (dx.abs() > range || dy.abs() > CombatConstants.sameLevelTolerance) {
      return null;
    }
    return p;
  }

  /// 1 when [p] is to the right of this enemy, -1 to the left.
  int _towards(PlayerComponent p) =>
      (p.position.x + p.size.x / 2) >= (position.x + size.x / 2) ? 1 : -1;

  @override
  void update(double dt) {
    super.update(dt);
    if (defeated) return;

    switch (_behavior) {
      case EnemyBehavior.walker:
        _updateWalker(dt);
      case EnemyBehavior.chaser:
        _updateChaser(dt);
      case EnemyBehavior.heavy:
        _updateHeavy(dt);
    }

    // Never culled behind the camera (see level_culling.dart). A living
    // enemy the player ran past is still there if they come back — which
    // also means running past one is a real decision rather than a way to
    // make it cease to exist. Defeated enemies are removed by the death
    // sequence in _die(), not by position.
  }

  /// Paces back and forth within its patrol range, turning at ledges. A student
  /// who comes close is faced once, so a walker no longer ignores them.
  void _updateWalker(double dt) {
    final near = _playerWithin(CombatConstants.walkerNoticeRange);
    if (near == null) {
      _noticed = false;
    } else if (!_noticed) {
      _noticed = true;
      _direction = _towards(near);
    }
    _patrol(dt);
  }

  void _patrol(double dt) {
    final nextX = position.x + CombatConstants.patrolSpeed * _direction * dt;

    // Turn around at a ledge rather than walk out over a gap. Only applies
    // while currently standing on ground: an enemy placed over a hole by
    // mistake would otherwise flip direction every frame.
    if (_isSupportedAt(position.x) && !_isSupportedAt(nextX)) {
      _direction = -_direction;
      return;
    }

    position.x = nextX;
    final offsetFromSpawn = position.x - _spawnX;
    if (offsetFromSpawn.abs() >= _patrolRange) {
      // Clamp back onto the range's edge rather than let one frame's
      // movement overshoot it, then turn around.
      position.x = _spawnX + _patrolRange * _direction;
      _direction = -_direction;
    }
  }

  /// Walks towards a student who comes close, slower than they walk, never past
  /// its leash and never off a ledge. Out of range it walks home and paces.
  void _updateChaser(double dt) {
    final target = _playerWithin(CombatConstants.chaserNoticeRange);
    if (target == null) {
      _growled = false;
    } else if (!_growled) {
      _growled = true;
      game.audioService.playChaserNotice();
    }
    if (target != null) {
      final dir = _towards(target);
      _direction = dir;
      final dx = (target.position.x + target.size.x / 2) -
          (position.x + size.x / 2);
      if (dx.abs() < 8) return; // right on top: no jitter
      final nextX = position.x + CombatConstants.chaserSpeed * dir * dt;
      final withinLeash =
          (nextX - _spawnX).abs() <= CombatConstants.chaserLeash;
      final ledgeOk = !_isSupportedAt(position.x) || _isSupportedAt(nextX);
      if (withinLeash && ledgeOk) position.x = nextX;
      return;
    }
    if ((position.x - _spawnX).abs() > _patrolRange) {
      // Too far from home to pace: walk back first.
      _direction = position.x > _spawnX ? -1 : 1;
      position.x += CombatConstants.patrolSpeed * _direction * dt;
      return;
    }
    _patrol(dt);
  }

  /// Stands still until a student comes close; then flashes for a moment (the
  /// warning), lunges a short way, and gets its breath back. A hit during the
  /// wind-up interrupts it.
  void _updateHeavy(double dt) {
    switch (_heavyState) {
      case _HeavyState.idle:
        _heavyCooldown -= dt;
        final target = _playerWithin(CombatConstants.lungeTriggerRange);
        if (target != null && _heavyCooldown <= 0) {
          _lungeDirection = _towards(target);
          _direction = _lungeDirection;
          _heavyState = _HeavyState.windup;
          _heavyTime = 0;
          game.audioService.playHeavyWindup();
          add(ColorEffect(
            Colors.white,
            EffectController(
                duration: CombatConstants.lungeWindup / 6,
                reverseDuration: CombatConstants.lungeWindup / 6,
                repeatCount: 3),
            opacityFrom: 0,
            opacityTo: 0.8,
          ));
        } else if (target == null && _lunged) {
          // Nobody near: shuffle back to the place it was put.
          final back = position.x > _spawnX ? -1 : 1;
          final step = CombatConstants.patrolSpeed * dt;
          if ((position.x - _spawnX).abs() <= step) {
            position.x = _spawnX;
            _lunged = false;
          } else {
            position.x += back * step;
          }
        }
      case _HeavyState.windup:
        _heavyTime += dt;
        if (_heavyTime >= CombatConstants.lungeWindup) {
          _heavyState = _HeavyState.lunge;
          _heavyTime = 0;
          game.audioService.playLunge();
        }
      case _HeavyState.lunge:
        _heavyTime += dt;
        final nextX = position.x +
            CombatConstants.lungeSpeed * _lungeDirection * dt;
        final withinLeash =
            (nextX - _spawnX).abs() <= CombatConstants.lungeLeash;
        final ledgeOk = !_isSupportedAt(position.x) || _isSupportedAt(nextX);
        if (withinLeash && ledgeOk) {
          position.x = nextX;
          _lunged = true;
        } else {
          _heavyTime = CombatConstants.lungeDuration; // stopped short: spent
        }
        if (_heavyTime >= CombatConstants.lungeDuration) {
          _heavyState = _HeavyState.recover;
          _heavyTime = 0;
        }
      case _HeavyState.recover:
        _heavyTime += dt;
        if (_heavyTime >= CombatConstants.lungeRecover) {
          _heavyState = _HeavyState.idle;
          _heavyCooldown = CombatConstants.lungeCooldown;
        }
    }
  }

  /// Whether the centre of the sprite, at world x [x], is over solid ground —
  /// the same foot span the player is held to (`footSpanFraction`).
  bool _isSupportedAt(double x) {
    final footHalfWidth = size.x * footSpanFraction / 2;
    final centre = x + size.x / 2;
    final surface = surfaceY;
    if (surface != null) {
      return game.isSurfaceUnder(
          centre - footHalfWidth, centre + footHalfWidth, surface);
    }
    return game.isGroundUnder(centre - footHalfWidth, centre + footHalfWidth);
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
    if (_hp <= 0) {
      _die();
    } else {
      // A hit knocks the wind-up out of a Heavy: it has to start over.
      _heavyState = _HeavyState.idle;
      _heavyCooldown = CombatConstants.lungeCooldown;
      _flinch();
    }
  }

  /// Which way a hit throws this enemy: 1 to the right, -1 to the left, away
  /// from the player. With no player to measure from, the way it is walking.
  int _awayFromPlayer() {
    try {
      final player = game.player;
      final mine = position.x + size.x / 2;
      final theirs = player.position.x + player.size.x / 2;
      return mine >= theirs ? 1 : -1;
    } catch (_) {
      return _direction;
    }
  }

  /// A hit that does not kill (a Heavy's first): it flashes white and is
  /// shoved back a few units and settles, so the swing visibly landed.
  void _flinch() {
    final away = _awayFromPlayer();
    add(ColorEffect(
      Colors.white,
      EffectController(duration: 0.07, reverseDuration: 0.07),
      opacityFrom: 0,
      opacityTo: 0.9,
    ));
    add(MoveByEffect(
      Vector2(away * 14.0, 0),
      EffectController(duration: 0.07, reverseDuration: 0.07),
    ));
  }

  void _die() {
    // Set before the effect even starts playing, not after it completes —
    // a still-visible, fading enemy must not be re-hittable or still deal
    // contact damage while it fades out.
    defeated = true;
    game.audioService.playEnemyDefeat();
    onDefeated?.call();

    final away = _awayFromPlayer();
    _deathSpot = position.clone();

    // Spin about the middle, not the top-left corner: re-anchor without
    // moving the picture.
    anchor = Anchor.center;
    position += size / 2;
    _burst();

    const flash = CombatConstants.deathFlashDuration;
    const flight = CombatConstants.deathFlightDuration;
    EffectController thrown() => EffectController(
        duration: flight, startDelay: flash, curve: Curves.easeOut);

    // White, then thrown away from the player, spinning and shrinking.
    add(ColorEffect(
      Colors.white,
      EffectController(duration: flash),
      opacityFrom: 0,
      opacityTo: 1,
    ));
    add(MoveByEffect(
      Vector2(away * CombatConstants.deathFlightPush,
          -CombatConstants.deathFlightRise),
      thrown(),
    ));
    add(RotateEffect.by(away * CombatConstants.deathSpin, thrown()));
    add(ScaleEffect.to(Vector2.all(0.55), thrown()));
    // Gone at the end of the flight, which is also when the coins drop.
    add(OpacityEffect.fadeOut(
      EffectController(duration: 0.22, startDelay: flash + flight - 0.22),
      onComplete: () {
        _dropCoins();
        removeFromParent();
      },
    ));
  }

  /// Sparks and a shock ring where the enemy was hit. They live in the world,
  /// not on the enemy, so they stay put as it flies off.
  void _burst() {
    const colors = [Colors.white, Color(0xFFFFEE58), Color(0xFFFF9800)];
    final centre = position.clone();
    game.world.add(
      ParticleSystemComponent(
        position: centre,
        priority: 15,
        particle: Particle.generate(
          count: 12,
          lifespan: 0.5,
          generator: (i) {
            final angle = i / 12 * 2 * pi + _random.nextDouble() * 0.5;
            final speed = 120 + _random.nextDouble() * 140;
            final colour = colors[i % colors.length];
            final paint = Paint();
            return AcceleratedParticle(
              speed: Vector2(cos(angle), sin(angle)) * speed,
              acceleration: Vector2(0, 420),
              child: ComputedParticle(renderer: (canvas, particle) {
                final p = particle.progress;
                paint.color = colour.withValues(alpha: 1 - p);
                canvas.drawCircle(Offset.zero, (1 - p) * 5 + 1.5, paint);
              }),
            );
          },
        ),
      ),
    );

    final ring = CircleComponent(
      radius: 14,
      anchor: Anchor.center,
      position: centre,
      priority: 14,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
    ring.add(ScaleEffect.to(
      Vector2.all(4),
      EffectController(duration: 0.28, curve: Curves.easeOut),
    ));
    ring.add(OpacityEffect.fadeOut(
      EffectController(duration: 0.28),
      onComplete: ring.removeFromParent,
    ));
    game.world.add(ring);
  }

  /// Where the enemy stood when it was struck, which is where its coins fall
  /// (it has moved by the time the flight is over).
  Vector2 _deathSpot = Vector2.zero();

  void _dropCoins() {
    final count = CombatConstants.coinDropMin +
        _random.nextInt(
          CombatConstants.coinDropMax - CombatConstants.coinDropMin + 1,
        );
    for (var i = 0; i < count; i++) {
      game.world.add(
        CoinComponent(spawnPosition: _deathSpot + Vector2(i * 10.0, 0)),
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
