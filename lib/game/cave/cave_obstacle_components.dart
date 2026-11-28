import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/cave_constants.dart';
import '../../core/surprise_constants.dart';
import '../chrono_game.dart';
import '../game_collision.dart' show footSpanFraction;
import '../surprise_art.dart';
import '../surprise_rules.dart';
import 'cave_art.dart';
import 'cave_obstacles.dart';
import 'cave_scenery.dart';

// The four obstacles of the underground cave, as components. Every timer counts
// frames in update(dt) (never a wall clock), so tests drive them with
// game.updateTree. Everything is drawn in code in the era's [CaveLook] colours;
// nothing here loads a picture. The numbers are in CaveConstants.
//
// A hit is always [PlayerComponent.takeHazardHit]: one heart, the shove, the
// 1.5 s safe moment and the Shield all work exactly as for an enemy.

const Color _white = Color(0xFFFFFFFF);

Color _a(Color c, double a) => c.withValues(alpha: a);

// ─── 1. Stalagmite spikes ────────────────────────────────────────────────

/// A cluster of 1 to 3 spikes on the floor. Touching one costs a heart; one jump
/// clears the widest cluster.
class CaveSpikesComponent extends PositionComponent
    with HasGameReference<ChronoGame> {
  CaveSpikesComponent({required this.spot, required this.look})
      : super(priority: -1) {
    size = Vector2(spot.width, CaveConstants.spikeHeight);
    position.x = spot.x;
  }

  final CaveSpikeSpot spot;
  final CaveLook look;
  final CaveInk _ink = CaveInk();

  /// Times it has hurt the hero (for tests).
  int hits = 0;

  @override
  Future<void> onLoad() async {
    position.y = game.groundY - CaveConstants.spikeHeight;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final hero = game.studentOrNull;
    if (hero == null) return;
    final top = position.y;
    if (!hero.bodyOverlaps(spot.x, top, spot.endX, top + size.y)) return;
    if (hero.invincible) return;
    hits++;
    final centre = hero.position.x + hero.size.x / 2;
    hero.takeHazardHit(knockbackDirection: centre >= spot.centerX ? 1 : -1);
  }

  @override
  void render(Canvas canvas) {
    final k = _ink
      ..c = canvas
      ..vw = size.x;
    const w = CaveConstants.spikeWidth;
    const h = CaveConstants.spikeHeight;
    for (var i = 0; i < spot.count; i++) {
      final x = i * w;
      // A little taller or shorter each, so a cluster looks grown, not stamped.
      final tall = h - (i.isOdd ? 8 : 0) - (i == 2 ? 4 : 0);
      k.tri(x - 1, h, x + w / 2, h - tall, x + w + 1, h, look.rock1);
      k.tri(x + w / 2, h - tall, x + w + 1, h, x + w / 2, h, look.rock0);
      k.tri(x - 1, h, x + w / 2, h - tall, x + 3, h, _a(look.lip, .85));
      k.tri(x + w / 2 - 1.5, h - tall + 6, x + w / 2, h - tall, x + w / 2 + 1.5,
          h - tall + 6, _a(look.glow, .8));
    }
    k.rect(-2, h - 2, size.x + 4, 3, look.rock0);
  }
}

// ─── 2. Stalactite ────────────────────────────────────────────────────────

enum StalactitePhase { dormant, warn, drop, landed }

/// A stalactite hanging from the ceiling over [spotX]. When the hero walks up to
/// it (between [CaveConstants.stalactiteTriggerNear] and
/// [CaveConstants.stalactiteTriggerFar] to its left) a shadow grows on the floor
/// under it with a "!" for [SurpriseConstants.rockWarn] seconds while it shakes,
/// then it drops for [SurpriseConstants.rockDrop] seconds, lands in a puff of dust
/// and breaks into harmless pieces. It hurts only a hero standing inside the
/// shadow whose feet are less than [SurpriseConstants.rockClearHeight] above the
/// floor when it lands (a jump clears it). It happens once.
class CaveStalactiteComponent extends PositionComponent
    with HasGameReference<ChronoGame> {
  CaveStalactiteComponent({
    required this.spotX,
    required this.surfaceY,
    required this.look,
  }) : super(position: Vector2(spotX, surfaceY), priority: 6);

  final double spotX;
  final double surfaceY;
  final CaveLook look;
  final CaveInk _ink = CaveInk();

  StalactitePhase phase = StalactitePhase.dormant;
  double _t = 0;

  /// Whether the landing hurt the hero (for tests).
  bool hurt = false;

  /// Seconds into the current phase (for tests).
  double get phaseTime => _t;

  /// How far the shadow has grown, 0 to 1 (for tests).
  double get shadowProgress {
    switch (phase) {
      case StalactitePhase.dormant:
        return 0;
      case StalactitePhase.warn:
        return SurpriseArt.clamp01(_t / SurpriseConstants.rockWarn);
      case StalactitePhase.drop:
      case StalactitePhase.landed:
        return 1;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    switch (phase) {
      case StalactitePhase.dormant:
        if (_heroApproaching()) {
          phase = StalactitePhase.warn;
          _t = 0;
          game.audioService.playRockWarn();
        }
      case StalactitePhase.warn:
        _t += dt;
        if (_t >= SurpriseConstants.rockWarn) {
          _t -= SurpriseConstants.rockWarn;
          phase = StalactitePhase.drop;
        }
      case StalactitePhase.drop:
        _t += dt;
        if (_t >= SurpriseConstants.rockDrop) {
          _t -= SurpriseConstants.rockDrop;
          _land();
        }
      case StalactitePhase.landed:
        _t += dt;
        if (_t >= SurpriseConstants.rockDebris) removeFromParent();
    }
  }

  bool _heroApproaching() {
    final s = game.studentOrNull;
    if (s == null) return false;
    final ahead = spotX - (s.position.x + s.size.x / 2);
    final dy = (s.position.y + s.size.y - surfaceY).abs();
    return ahead >= CaveConstants.stalactiteTriggerNear &&
        ahead <= CaveConstants.stalactiteTriggerFar &&
        dy <= 150;
  }

  void _land() {
    phase = StalactitePhase.landed;
    final s = game.studentOrNull;
    if (s != null) {
      final centre = s.position.x + s.size.x / 2;
      if (SurpriseRules.insideZone(
        centreX: centre,
        feetY: s.position.y + s.size.y,
        spotX: spotX,
        groundY: surfaceY,
        radius: SurpriseConstants.rockRadius,
        clearHeight: SurpriseConstants.rockClearHeight,
      )) {
        hurt = true;
        s.takeHazardHit(knockbackDirection: centre >= spotX ? 1 : -1);
      }
    }
    game.audioService.playRockCrash();
  }

  /// The stalactite itself, its base on the ceiling at y = [baseY] (local), its tip
  /// at y = [tipY].
  void _drawBody(CaveInk k, double baseY, double tipY) {
    const half = CaveConstants.stalactiteBaseWidth / 2;
    final mid = (baseY + tipY) / 2;
    k.fill(look.rock1, (p) {
      p
        ..moveTo(-half, baseY)
        ..lineTo(half, baseY)
        ..lineTo(half * .55, mid - 20)
        ..lineTo(half * .3, mid + 30)
        ..lineTo(0, tipY)
        ..lineTo(-half * .35, mid + 36)
        ..lineTo(-half * .6, mid - 12)
        ..close();
    });
    k.fill(look.rock0, (p) {
      p
        ..moveTo(0, baseY)
        ..lineTo(half, baseY)
        ..lineTo(half * .55, mid - 20)
        ..lineTo(half * .3, mid + 30)
        ..lineTo(0, tipY)
        ..close();
    });
    k.tri(-half, baseY, -half * .6, mid - 12, -half + 12, baseY,
        _a(look.lip, .8));
    k.oval(0, baseY, half + 14, 14, look.rock0);
    k.tri(-3, tipY + 14, 0, tipY, 3, tipY + 14, _a(look.glow, .75));
  }

  @override
  void render(Canvas canvas) {
    final k = _ink
      ..c = canvas
      ..vw = 200;
    final baseY = -(surfaceY - 14);
    const tipY = -CaveConstants.stalactiteTipHeight;
    switch (phase) {
      case StalactitePhase.dormant:
        _drawBody(k, baseY, tipY);
      case StalactitePhase.warn:
        final p = shadowProgress;
        SurpriseArt.rockShadow(canvas, 0, SurpriseConstants.rockRadius, p, 1);
        SurpriseArt.bang(canvas, 0, -60, _t);
        // It shakes harder as the warning runs out.
        canvas.save();
        canvas.translate(math.sin(_t * 60) * (1 + 2.5 * p), 0);
        _drawBody(k, baseY, tipY);
        canvas.restore();
      case StalactitePhase.drop:
        SurpriseArt.rockShadow(canvas, 0, SurpriseConstants.rockRadius, 1, 1);
        final u = SurpriseArt.clamp01(_t / SurpriseConstants.rockDrop);
        // The whole stalactite falls, tip first, to the floor.
        final dy = CaveConstants.stalactiteTipHeight * u * u;
        _drawBody(k, baseY + dy, tipY + dy);
      case StalactitePhase.landed:
        final a = SurpriseArt.clamp01(1 - _t / 0.25);
        if (a > 0) {
          SurpriseArt.rockShadow(canvas, 0, SurpriseConstants.rockRadius, 1, a);
        }
        SurpriseArt.rockPieces(
            canvas, 0, -26, _t, SurpriseConstants.rockDebris);
        SurpriseArt.dust(canvas, 0, _t);
        SurpriseArt.shockRing(canvas, 0, _t);
    }
  }
}

// ─── 3. Crumbling slab ────────────────────────────────────────────────────

enum SlabPhase { solid, shaking, falling, gone, returning }

/// One of the cave's floating slabs that does not last. After the hero LANDS on
/// it, it shakes for [CaveConstants.crumbleShake] seconds (still solid), then falls
/// for [CaveConstants.crumbleFall] seconds fading out (no longer solid from the
/// first moment of the fall, so the hero drops), stays away for
/// [CaveConstants.crumbleGone] seconds, then comes back (solid at once, fading in
/// over [CaveConstants.crumbleReturn] seconds).
///
/// It is registered for the hero's footing in `game.platforms` like any slab and
/// taken out of it and put back in; it is an optional extra, never needed to cross
/// the cave.
class CrumblingSlabComponent extends CavePlatformComponent {
  CrumblingSlabComponent({
    required super.widthInTiles,
    required super.surfaceY,
    required super.spawnPosition,
    required super.look,
  });

  SlabPhase phase = SlabPhase.solid;
  double _t = 0;
  final CaveInk _crackInk = CaveInk();
  final Paint _layer = Paint();

  /// Seconds into the current phase (for tests).
  double get phaseTime => _t;

  /// Whether the hero can stand on it right now.
  bool get isSolid => game.platforms.contains(this);

  bool _heroOnTop() {
    final hero = game.studentOrNull;
    if (hero == null || !hero.isOnGround) return false;
    if ((hero.position.y + hero.size.y - surfaceY).abs() > 2) return false;
    final half = hero.size.x * footSpanFraction / 2;
    final centre = hero.position.x + hero.size.x / 2;
    return centre + half > position.x && centre - half < position.x + size.x;
  }

  @override
  void update(double dt) {
    super.update(dt);
    switch (phase) {
      case SlabPhase.solid:
        if (_heroOnTop()) {
          phase = SlabPhase.shaking;
          _t = 0;
        }
      case SlabPhase.shaking:
        _t += dt;
        if (_t >= CaveConstants.crumbleShake) {
          _t -= CaveConstants.crumbleShake;
          phase = SlabPhase.falling;
          // Nothing to stand on from this moment.
          game.platforms.remove(this);
        }
      case SlabPhase.falling:
        _t += dt;
        if (_t >= CaveConstants.crumbleFall) {
          _t -= CaveConstants.crumbleFall;
          phase = SlabPhase.gone;
        }
      case SlabPhase.gone:
        _t += dt;
        if (_t >= CaveConstants.crumbleGone) {
          _t -= CaveConstants.crumbleGone;
          phase = SlabPhase.returning;
          if (!game.platforms.contains(this)) game.platforms.add(this);
        }
      case SlabPhase.returning:
        _t += dt;
        if (_t >= CaveConstants.crumbleReturn) {
          _t = 0;
          phase = SlabPhase.solid;
        }
    }
  }

  @override
  void render(Canvas canvas) {
    var alpha = 1.0;
    var dx = 0.0, dy = 0.0;
    var crack = 0.0;
    switch (phase) {
      case SlabPhase.solid:
        break;
      case SlabPhase.shaking:
        crack = SurpriseArt.clamp01(_t / CaveConstants.crumbleShake);
        dx = math.sin(_t * 80) * (1 + 2 * crack);
      case SlabPhase.falling:
        final u = SurpriseArt.clamp01(_t / CaveConstants.crumbleFall);
        crack = 1;
        dy = 140 * u * u;
        alpha = 1 - u;
      case SlabPhase.gone:
        return;
      case SlabPhase.returning:
        alpha = SurpriseArt.clamp01(_t / CaveConstants.crumbleReturn);
    }
    canvas.save();
    canvas.translate(dx, dy);
    final faded = alpha < 1;
    if (faded) {
      _layer.color = _white.withValues(alpha: alpha);
      canvas.saveLayer(Rect.fromLTWH(-8, -16, size.x + 16, 100), _layer);
    }
    super.render(canvas);
    if (crack > 0) _drawCracks(canvas, crack);
    if (faded) canvas.restore();
    canvas.restore();
  }

  void _drawCracks(Canvas canvas, double amount) {
    final k = _crackInk
      ..c = canvas
      ..vw = size.x;
    final n = amount > .5 ? 4 : 2;
    for (var i = 0; i < n; i++) {
      final x = size.x * (.18 + .64 * i / (n - 1 == 0 ? 1 : n - 1));
      k.stroke(const Color(0xCC000000), 2, (p) {
        p
          ..moveTo(x, 1)
          ..lineTo(x - 4, 9)
          ..lineTo(x + 3, 16)
          ..lineTo(x - 2, 24);
      });
    }
  }
}

// ─── 4. Stone crusher ─────────────────────────────────────────────────────

/// A stone block (100 wide, 70 tall) on a chain over flat floor. See
/// [CrusherCycle] for the cycle: up 1.5 s, shaking with a "!" and a ring on the
/// floor 0.6 s, slam 0.3 s, hold 0.3 s, rise 0.6 s. It hurts only while the
/// hero's body overlaps the block and the block is moving down or resting on the
/// floor, so a hero can always wait for it to be up and walk under it.
///
/// It runs only while the hero is within [CaveConstants.crusherActiveRange].
class CaveCrusherComponent extends PositionComponent
    with HasGameReference<ChronoGame> {
  CaveCrusherComponent({
    required this.spot,
    required this.surfaceY,
    required this.look,
  }) : super(position: Vector2(spot.centerX, surfaceY), priority: 6);

  final CaveCrusherSpot spot;
  final double surfaceY;
  final CaveLook look;
  final CaveInk _ink = CaveInk();

  /// Running time in seconds (wraps round the cycle). Settable for tests.
  double time = 0;

  CrusherPhase _lastPhase = CrusherPhase.up;

  /// Times it has hurt the hero (for tests).
  int hits = 0;

  CrusherPhase get phase => CrusherCycle.phaseAt(time);

  /// Height of the bottom of the block above the floor right now.
  double get bottomHeight => CrusherCycle.bottomHeightAt(time);

  @override
  void update(double dt) {
    super.update(dt);
    final hero = game.studentOrNull;
    if (hero == null) return;
    final centre = hero.position.x + hero.size.x / 2;
    if ((centre - spot.centerX).abs() > CaveConstants.crusherActiveRange) {
      return;
    }
    time = CrusherCycle.wrap(time + dt);
    final now = phase;
    if (now != _lastPhase) {
      final near = (centre - spot.centerX).abs() < 700;
      if (near && now == CrusherPhase.warn) game.audioService.playRockWarn();
      if (near && now == CrusherPhase.hold) game.audioService.playRockCrash();
      _lastPhase = now;
    }
    if (!CrusherCycle.hurts(now)) return;
    final bottom = surfaceY - bottomHeight;
    final top = bottom - CaveConstants.crusherHeight;
    if (!hero.bodyOverlaps(spot.left, top, spot.right, bottom)) return;
    if (hero.invincible) return;
    hits++;
    hero.takeHazardHit(knockbackDirection: centre >= spot.centerX ? 1 : -1);
  }

  @override
  void render(Canvas canvas) {
    final k = _ink
      ..c = canvas
      ..vw = 200;
    const w = CaveConstants.crusherWidth;
    const h = CaveConstants.crusherHeight;
    final now = phase;
    final p = CrusherCycle.timeInPhase(time);
    final lift = bottomHeight;
    final bottom = -lift; // local y of the block's bottom
    final top = bottom - h;

    // The ring on the floor shows where it will land, from the warning on.
    if (now == CrusherPhase.warn) {
      final u = SurpriseArt.clamp01(p / CaveConstants.crusherWarn);
      SurpriseArt.ring(canvas, 0, w * .62, .4 + .5 * u, .1 + .25 * u);
    } else if (now == CrusherPhase.slam || now == CrusherPhase.hold) {
      SurpriseArt.ring(canvas, 0, w * .62, .9, .35);
    } else if (now == CrusherPhase.rise) {
      final u = SurpriseArt.clamp01(p / CaveConstants.crusherRise);
      SurpriseArt.ring(canvas, 0, w * .62, .9 * (1 - u), .35 * (1 - u));
    }

    var shake = 0.0;
    if (now == CrusherPhase.warn) {
      shake = math.sin(time * 90) * 3;
    }
    canvas.save();
    canvas.translate(shake, 0);

    // The chain from the ceiling down to the block.
    final ceilingY = -(surfaceY - 14);
    k.rect(-4, ceilingY, 8, top - ceilingY, look.rock0);
    for (var y = top - 10; y > ceilingY; y -= 16) {
      k.rrect(-4.5, y - 11, 9, 14, 3, look.lip);
      k.rrect(-2, y - 9, 4, 10, 2, look.rock0);
    }
    k.oval(0, ceilingY, 30, 12, look.rock0);

    // The block.
    k.rrect(-w / 2, top, w, h, 8, look.rock0);
    k.rrect(-w / 2 + 4, top + 4, w - 8, h - 8, 5, look.rock1);
    k.rect(-w / 2 + 6, top + 6, w - 12, 4, _a(_white, .12));
    k.rect(-w / 2 + 4, top + 4, 4, h - 8, _a(look.lip, .6));
    // Teeth along the bottom.
    for (var i = 0; i < 5; i++) {
      final x = -w / 2 + 6 + i * (w - 12) / 5;
      k.tri(x, bottom - 4, x + (w - 12) / 10, bottom + 4, x + (w - 12) / 5,
          bottom - 4, look.rock0);
    }
    for (final sx in [-1.0, 1.0]) {
      k.circle(sx * (w / 2 - 12), top + 12, 3, look.lip);
      k.circle(sx * (w / 2 - 12), bottom - 14, 3, look.lip);
    }
    // A crack that glows when it is about to fall.
    final warnGlow = now == CrusherPhase.warn
        ? SurpriseArt.clamp01(p / CaveConstants.crusherWarn)
        : 0.0;
    k.stroke(_a(look.glow, .35 + .5 * warnGlow), 2, (path) {
      path
        ..moveTo(-8, top + 10)
        ..lineTo(-2, top + 30)
        ..lineTo(-10, top + 44)
        ..lineTo(0, top + 58);
    });
    canvas.restore();

    if (now == CrusherPhase.warn) {
      SurpriseArt.bang(canvas, 0, top - 6, p);
    }
    // Dust and a ring of force where it lands.
    if (now == CrusherPhase.hold || now == CrusherPhase.rise) {
      final d = now == CrusherPhase.hold ? p : CaveConstants.crusherHold + p;
      SurpriseArt.dust(canvas, -w / 2, d);
      SurpriseArt.dust(canvas, w / 2, d);
      SurpriseArt.shockRing(canvas, 0, d);
    }
  }
}
