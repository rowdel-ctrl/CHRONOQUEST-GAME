import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../../core/combat_constants.dart';
import '../../core/surprise_constants.dart';
import '../art_scale.dart';
import '../chrono_game.dart';
import '../enemy_behavior.dart';
import '../enemy_moves.dart';
import '../game_collision.dart';
import '../surprise_rules.dart';
import 'coin_component.dart';
import 'enemy_burst_component.dart';
import 'player_component.dart';
import 'praise_component.dart';

enum _HeavyState { idle, windup, lunge, recover }

enum _ChaserState { chase, fuse, crouch, dash, tired }

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

  /// Makes this enemy act as another kind than its table entry says. The map's
  /// `behavior="chaser"` on a soldier uses it: that soldier then chases and dashes.
  final EnemyBehavior? behaviorOverride;

  /// False keeps a chaser plain: it chases but never fuses, bursts or dashes. The
  /// first two levels of each era and the boss rooms turn it off.
  final bool blasts;

  /// A surprise move this enemy has on top of its kind's behaviour (the map's
  /// `behavior="hopper"`, `"thrower"` or `"golden"`, or [EnemySurprise.popper] for an
  /// enemy a ground pop raised). See enemy_moves.dart.
  final EnemySurprise surprise;

  EnemyComponent({
    required this.eraId,
    this.enemyTypeOverride,
    this.worldX,
    this.patrolRangeOverride,
    this.surfaceY,
    this.onDefeated,
    this.behaviorOverride,
    this.blasts = true,
    this.surprise = EnemySurprise.none,
  });

  EnemyMove? _move;

  /// The surprise move, for tests.
  @visibleForTesting
  EnemyMove? get move => _move;

  /// What the surprise moves (enemy_moves.dart) need from this enemy.
  String get kind => _enemyType;
  PlayerComponent? get student => _playerOrNull;
  PlayerComponent? studentWithin(double range) => _playerWithin(range);
  int get facing => _direction;
  set facing(int direction) => _direction = direction >= 0 ? 1 : -1;
  double get homeX => _spawnX;

  /// Makes where it stands now the place it paces round (the golden runner, after a run).
  void rehome() => _spawnX = position.x;
  double get patrolLimit => _patrolRange;
  bool canStandAt(double x) => _isSupportedAt(x);

  /// How tall the picture is drawn, in game units (what a "!" or the dizzy stars
  /// sit above).
  double get drawnHeight {
    final sprite = _frames.isEmpty ? null : _frames.first;
    return sprite == null ? spriteHeight : artSizeOf(sprite).y;
  }

  /// Whether touching this enemy costs the student a heart right now. False while a
  /// surprise move says so (a dizzy hopper, a rising enemy, a golden runner).
  bool get hurtsOnTouch => _move?.hurtsOnTouch ?? true;

  /// Effective patrol range: the authored override when there is one, else
  /// the global default.
  double get _patrolRange =>
      patrolRangeOverride ?? CombatConstants.patrolRange;

  @override
  Future<void> onLoad() async {
    _enemyType = enemyTypeOverride ?? _getEnemyTypeForEra(eraId);
    final typeData = enemyTypeDataFor(_enemyType);
    // A walker-made surprise (hopper, popper, golden) walks whatever its kind is.
    final walks = surprise == EnemySurprise.hopper ||
        surprise == EnemySurprise.popper ||
        surprise == EnemySurprise.golden;
    _behavior = behaviorOverride ??
        (walks ? EnemyBehavior.walker : typeData.behavior);
    _hp = surprise == EnemySurprise.thrower
        ? SurpriseConstants.throwerHits
        : typeData.maxHp;
    _move = switch (surprise) {
      EnemySurprise.hopper => HopperMove(),
      EnemySurprise.popper => RiseMove(),
      EnemySurprise.thrower => ThrowerMove(),
      EnemySurprise.golden => GoldenMove(),
      EnemySurprise.none => null,
    };

    _typeData = typeData;

    // The walking cycle: _1 is required, _2 and _3 are used when the art has
    // them (the old art only had two pictures).
    final frames = [await game.loadSprite('enemies/${_enemyType}_1.png')];
    for (var i = 2; i <= 3; i++) {
      final frame = await _tryLoad('${_enemyType}_$i');
      if (frame != null) frames.add(frame);
    }
    _frames = frames;
    animation = SpriteAnimation.spriteList(frames, stepTime: 0.2);
    _hurtSprite = await _tryLoad('${_enemyType}_hurt');
    _attackSprite = await _tryLoad('${_enemyType}_attack');
    if (_move != null) _idleSprite = await _tryLoad('${_enemyType}_idle');

    // The box stays 90x108 for physics and level layout; only the drawing
    // follows the picture's own size (see [render] and art_scale.dart).
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
    // damaging them without being touched. A low or wide body (tank, cloud)
    // has its own size and stands on the ground; see [_hitLocal].
    final local = _hitLocal;
    add(RectangleHitbox(
      position: Vector2(local.left, local.top),
      size: Vector2(local.width, local.height),
    ));
  }

  EnemyTypeData? _typeData;
  Sprite? _hurtSprite;
  Sprite? _attackSprite;

  /// The standing picture a surprise move shows (dizzy, out of breath), and the
  /// walking pictures it picks from.
  Sprite? _idleSprite;
  List<Sprite> _frames = const [];

  /// Seconds the hurt picture still shows after a hit that did not defeat it.
  double _hurtLeft = 0;

  Future<Sprite?> _tryLoad(String name) async {
    try {
      return await game.loadSprite('enemies/$name.png');
    } catch (_) {
      return null; // optional picture: the walking pictures stand in
    }
  }

  /// The hit area in this component's own coordinates (0,0 = top-left of the box).
  /// Tall humans: the old centred fractions of the box. Low or wide bodies: their own
  /// size, centred sideways, with the bottom on the feet line.
  Rect get _hitLocal {
    final data = _typeData ??
        (enemyTypeOverride == null ? null : enemyTypeDataFor(enemyTypeOverride!));
    if (data != null && data.hasBodyHit) {
      final w = data.hitWidth!;
      final h = data.hitHeight!;
      return Rect.fromLTWH((size.x - w) / 2, size.y - h, w, h);
    }
    final w = size.x * CombatConstants.enemyHitWidthFraction;
    final h = size.y * CombatConstants.enemyHitHeightFraction;
    return Rect.fromLTWH((size.x - w) / 2, (size.y - h) / 2, w, h);
  }

  /// The part of this enemy that hurts, in world coordinates. The player's contact
  /// check should use this so it and the collision hitbox can never disagree.
  Rect get hitRect =>
      _hitLocal.shift(Offset(topLeftPosition.x, topLeftPosition.y));

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

  /// Chaser only: where it is in its warning-then-attack move. [_ChaserState.chase] is
  /// the plain chase. A blast kind (a [BurstStyle]) goes chase, fuse, then bursts (and is
  /// gone); a soldier made a chaser goes chase, crouch, dash, tired, chase.
  _ChaserState _chaserState = _ChaserState.chase;
  double _chaserTime = 0;
  int _dashDirection = 1;
  double _dashTravelled = 0;

  /// Whether this chaser is in its fuse (stopped, flashing) right now.
  @visibleForTesting
  bool get isFusing => _chaserState == _ChaserState.fuse;

  /// Whether this chaser is crouching before its dash right now.
  @visibleForTesting
  bool get isCrouching => _chaserState == _ChaserState.crouch;

  /// Whether this chaser is mid-dash right now.
  @visibleForTesting
  bool get isDashing => _chaserState == _ChaserState.dash;

  /// Whether this chaser is standing tired after a dash right now.
  @visibleForTesting
  bool get isTired => _chaserState == _ChaserState.tired;

  BurstStyle? get _burstStyle => _typeData?.burst;

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
    if (_hurtLeft > 0) _hurtLeft -= dt;
    if (defeated) return;

    // A surprise move may take over the whole frame (a squat, a hop, a throw, a run).
    if (_move?.update(this, dt) ?? false) return;

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
    switch (_chaserState) {
      case _ChaserState.fuse:
        return _updateFuse(dt);
      case _ChaserState.crouch:
        return _updateCrouch(dt);
      case _ChaserState.dash:
        return _updateDash(dt);
      case _ChaserState.tired:
        return _updateTired(dt);
      case _ChaserState.chase:
        break;
    }
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
      if (blasts && _armIfClose()) return;
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

  /// Starts the warning move when a student is close enough: a blast kind fuses, any
  /// other chaser crouches. Returns true when it did, so the chase step is skipped.
  bool _armIfClose() {
    final style = _burstStyle;
    if (style != null) {
      final near = _playerWithin(CombatConstants.blastArmRange);
      if (near == null) return false;
      _direction = _towards(near);
      _chaserState = _ChaserState.fuse;
      _chaserTime = 0;
      game.audioService.playHeavyWindup();
      return true;
    }
    final near = _playerWithin(CombatConstants.dashArmRange);
    if (near == null) return false;
    _direction = _towards(near);
    _chaserState = _ChaserState.crouch;
    _chaserTime = 0;
    return true;
  }

  /// Stopped and flashing. When the fuse runs out it bursts by itself.
  void _updateFuse(double dt) {
    _chaserTime += dt;
    if (_chaserTime >= CombatConstants.blastFuse) _selfBurst();
  }

  /// How far through its fuse, 0 to 1.
  double get _fuseProgress =>
      (_chaserTime / CombatConstants.blastFuse).clamp(0.0, 1.0);

  /// The fuse ran out: one heart off a student inside the ring and not jumping clear of
  /// it (the same hit a touch does, so the safe moment and the Shield count), then
  /// gone. A blast pays nothing: no coins, and it does not count as beaten.
  void _selfBurst() {
    _chaserState = _ChaserState.chase;
    final p = _playerOrNull;
    if (p != null) {
      final dx =
          (p.position.x + p.size.x / 2) - (position.x + size.x / 2);
      final feetAbove = (position.y + size.y) - (p.position.y + p.size.y);
      if (dx.abs() <= CombatConstants.blastRadius &&
          feetAbove < CombatConstants.blastHeight) {
        p.takeHazardHit(knockbackDirection: dx >= 0 ? 1 : -1);
      }
    }
    _spawnBurst(1);
    game.audioService.playShockwave();
    defeated = true;
    removeFromParent();
  }

  void _spawnBurst(double scale) {
    final style = _burstStyle;
    if (style == null) return;
    game.world.add(EnemyBurstComponent(
      style: style,
      centre: Vector2(position.x + size.x / 2, position.y + size.y - 46),
      burstScale: scale,
      seed: _random.nextInt(1000),
    ));
  }

  /// Squatting, the warning. Stopped; then it dashes.
  void _updateCrouch(double dt) {
    _chaserTime += dt;
    if (_chaserTime >= CombatConstants.dashCrouch) {
      _chaserState = _ChaserState.dash;
      _chaserTime = 0;
      _dashTravelled = 0;
      _dashDirection = _direction;
    }
  }

  /// A short fast run the way it faces, never past its leash and never off a ledge.
  void _updateDash(double dt) {
    _chaserTime += dt;
    const speed = CombatConstants.dashDistance / CombatConstants.dashDuration;
    final step =
        min(speed * dt, CombatConstants.dashDistance - _dashTravelled);
    final nextX = position.x + step * _dashDirection;
    final withinLeash = (nextX - _spawnX).abs() <= CombatConstants.chaserLeash;
    final ledgeOk = !_isSupportedAt(position.x) || _isSupportedAt(nextX);
    if (withinLeash && ledgeOk) {
      position.x = nextX;
      _dashTravelled += step;
    } else {
      _dashTravelled = CombatConstants.dashDistance; // stopped short: spent
    }
    if (_chaserTime >= CombatConstants.dashDuration ||
        _dashTravelled >= CombatConstants.dashDistance - 0.001) {
      _chaserState = _ChaserState.tired;
      _chaserTime = 0;
    }
  }

  /// Out of breath after a dash: stands still, then chases again.
  void _updateTired(double dt) {
    _chaserTime += dt;
    if (_chaserTime >= CombatConstants.dashTired) {
      _chaserState = _ChaserState.chase;
      _chaserTime = 0;
    }
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

  /// Which picture is drawn now: 'hurt' during a flinch and while thrown away when
  /// defeated, 'attack' during a Heavy's wind-up and lunge, else 'walk'. A picture the
  /// art does not have is never named: the walking pictures stand in.
  @visibleForTesting
  String get shownPicture {
    if (_hurtSprite != null && (defeated || _hurtLeft > 0)) return 'hurt';
    final moved = defeated ? null : _move?.look(this).picture;
    if (moved == 'idle' && _idleSprite != null) return 'idle';
    if (moved == 'hop' && _frames.length >= 3) return 'hop';
    if (moved == 'attack' && _attackSprite != null) return 'attack';
    if (_attackSprite != null &&
        (_heavyState == _HeavyState.windup ||
            _heavyState == _HeavyState.lunge ||
            _chaserState == _ChaserState.dash ||
            // The flyer keeps its walking picture while the fuse burns.
            (_chaserState == _ChaserState.fuse &&
                _burstStyle != BurstStyle.paper))) {
      return 'attack';
    }
    return 'walk';
  }

  /// Fuse flicker: white, rising from [CombatConstants.blastFlashFrom] to
  /// [CombatConstants.blastFlashTo] flashes a second over the fuse.
  @visibleForTesting
  double get fuseFlashAlpha => _fuseFlash;

  double get _fuseFlash {
    final u = _fuseProgress;
    const from = CombatConstants.blastFlashFrom;
    const to = CombatConstants.blastFlashTo;
    final phase = 2 * pi * CombatConstants.blastFuse *
        (from * u + (to - from) / 2 * u * u);
    return 0.3 + 0.55 * (0.5 + 0.5 * sin(phase));
  }

  final Paint _tintPaint = Paint();

  /// A dashed red ellipse on the ground (the blast's reach) with a faint red fill that
  /// grows over the fuse. The feet are at the bottom middle of the box.
  void _drawBlastRing(Canvas canvas) {
    const rx = CombatConstants.blastRadius;
    const ry = rx * 0.2;
    final oval = Rect.fromCenter(
        center: Offset(size.x / 2, size.y + 4), width: rx * 2, height: ry * 2);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFF4A3D)
          .withValues(alpha: 0.08 + 0.22 * _fuseProgress);
    canvas.drawOval(oval, fill);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFFF6A5A).withValues(alpha: 0.9);
    final path = Path()..addOval(oval);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, min(d + 8, metric.length)), line);
        d += 14;
      }
    }
  }

  Sprite? get _shownSprite {
    switch (shownPicture) {
      case 'hurt':
        return _hurtSprite;
      case 'attack':
        return _attackSprite;
      case 'idle':
        return _idleSprite;
      case 'hop':
        return _frames[2];
      default:
        return animationTicker?.getSprite();
    }
  }

  // The picture is drawn here by paintArt, so super.render (which would stretch
  // the animation into the 90x108 box) is deliberately not called.
  @override
  // ignore: must_call_super
  void render(Canvas canvas) {
    final sprite = _shownSprite;
    if (sprite == null) return;
    // The enemy art faces left natively (enemies originally only ever
    // advanced toward the player), so walking left needs no flip and
    // walking right does — the opposite of PlayerComponent, whose art
    // faces right.
    //
    // paintArt mirrors around the feet with a render-local canvas transform
    // rather than `flipHorizontally()`, for the same reason PlayerComponent
    // avoids it: that method compensates a non-center anchor by nudging
    // `position.x`, which here is world-authoritative state read by the
    // despawn check and by the patrol anchor (`_spawnX`) every frame.
    // The warning moves squash or swell the picture about its feet and tint it.
    var sx = 1.0, sy = 1.0;
    Color? tint;
    var tintAlpha = 0.0;
    if (_chaserState == _ChaserState.fuse) {
      final s = 1 + (CombatConstants.blastSwell - 1) * _fuseProgress;
      sx = s;
      sy = s;
      tint = Colors.white;
      tintAlpha = _fuseFlash;
      _drawBlastRing(canvas);
    } else if (_chaserState == _ChaserState.crouch) {
      final u = (_chaserTime / CombatConstants.dashCrouch).clamp(0.0, 1.0);
      final pulse = sin(u * pi);
      sy = 1 - (1 - CombatConstants.dashSquashY) * pulse;
      sx = 1 + (CombatConstants.dashSquashX - 1) * pulse;
      tint = const Color(0xFFFFB84A);
      tintAlpha = 0.25 + 0.4 * (0.5 + 0.5 * sin(u * 22));
    }
    // A surprise move squashes, flashes, tints, lifts or cuts the picture too.
    final look = _move?.look(this);
    var lift = 0.0;
    var clip = false;
    if (look != null) {
      if (!defeated) {
        sx *= look.scaleX;
        sy *= look.scaleY;
        lift = look.lift;
        clip = look.clipAtGround;
        if (look.flash > 0) {
          tint = Colors.white;
          tintAlpha = look.flash;
        }
      }
      if (look.gold && tint == null) {
        tint = const Color(0xFFFFCC33);
        tintAlpha = 0.5;
      }
    }
    var drawPaint = paint;
    if (tint != null) {
      _tintPaint
        ..color = paint.color
        ..colorFilter =
            ColorFilter.mode(tint.withValues(alpha: tintAlpha), BlendMode.srcATop);
      drawPaint = _tintPaint;
    }
    final move = defeated ? null : _move;
    if (move != null) {
      canvas.save();
      canvas.translate(size.x / 2, size.y);
      move.paintBehind(canvas, this);
      canvas.restore();
    }
    canvas.save();
    // Cut at the ground line first (an enemy rising out of the ground), then lift.
    if (clip) {
      canvas.clipRect(Rect.fromLTRB(-300, -600, size.x + 300, size.y + 2));
    }
    canvas.translate(0, -lift);
    canvas.translate(size.x / 2, size.y);
    canvas.scale(sx, sy);
    canvas.translate(-size.x / 2, -size.y);
    paintArt(
      canvas,
      sprite,
      footX: size.x / 2,
      footY: size.y,
      flip: _direction >= 0,
      overridePaint: drawPaint,
    );
    canvas.restore();
    if (move != null) {
      canvas.save();
      canvas.translate(size.x / 2, size.y);
      move.paintOver(canvas, this);
      canvas.restore();
    }
  }

  /// Called when the player's attack hitbox connects. Decrements HP and
  /// triggers the death sequence once it reaches 0 — a Heavy's first hit
  /// registers but leaves it alive and still a threat.
  void takeHit() {
    if (defeated) return;
    // A hit during the fuse pops it harmlessly: a small burst, no blast, and then the
    // normal defeat (coins, onDefeated). Whatever warning it was in ends here.
    if (_chaserState == _ChaserState.fuse) _spawnBurst(CombatConstants.popBurstScale);
    _chaserState = _ChaserState.chase;
    _move?.onHit(this);
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
    _hurtLeft = 0.14; // the flash is 0.07 s in and 0.07 s out
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
    if (surprise == EnemySurprise.golden) return _dropGoldenCoins();
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

  /// How many bonus coins the golden runner drops, and where: 8 to 10 in two rows over
  /// about 130 units, with a word of praise over them.
  @visibleForTesting
  int goldenCoinCount() =>
      SurpriseConstants.goldenCoinsMin +
      _random.nextInt(SurpriseConstants.goldenCoinsMax -
          SurpriseConstants.goldenCoinsMin +
          1);

  void _dropGoldenCoins() {
    final count = goldenCoinCount();
    final perRow = (count + 1) ~/ 2;
    for (var i = 0; i < count; i++) {
      final row = i < perRow ? 0 : 1;
      final inRow = row == 0 ? i : i - perRow;
      final n = row == 0 ? perRow : count - perRow;
      final x = (inRow - (n - 1) / 2) * 30.0;
      game.world.add(
        CoinComponent(
            spawnPosition: _deathSpot + Vector2(x + 24, row == 0 ? 40 : -10)),
      );
    }
    game.world.add(PraiseComponent(word: 'Bonus coins!')
      ..position = _deathSpot + Vector2(size.x / 2, -20));
  }

  @override
  void onRemove() {
    _move?.onRemoved(this);
    super.onRemove();
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
