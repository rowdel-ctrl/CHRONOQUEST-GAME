import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/combat_constants.dart';
import '../core/surprise_constants.dart';
import 'components/enemy_component.dart';
import 'components/praise_component.dart';
import 'components/thrown_item_component.dart';
import 'surprise_art.dart';
import 'surprise_rules.dart';

/// How a move changes the way its enemy is drawn this frame.
class EnemyLook {
  const EnemyLook({
    this.lift = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.flash = 0,
    this.gold = false,
    this.picture = 'walk',
    this.clipAtGround = false,
  });

  /// Units the picture is lifted above where the enemy stands (negative: sunk into
  /// the ground, as while it rises).
  final double lift;
  final double scaleX;
  final double scaleY;

  /// White flash, 0 for none.
  final double flash;

  /// The golden tint.
  final bool gold;

  /// 'walk' (the walking cycle), 'hop' (its third walking picture), 'idle' (standing
  /// still, which is what a dizzy or resting enemy shows) or 'attack'.
  final String picture;

  /// Cut the picture off at the ground line (an enemy rising out of the ground).
  final bool clipAtGround;
}

/// An extra thing an [EnemyComponent] does on top of its kind's behaviour: the
/// hopper's hop, the thrower's throw, the golden runner's run, the rising of an
/// enemy that a ground pop raised. The enemy owns one and asks it every frame.
///
/// The coordinates [paintBehind] and [paintOver] draw in have the enemy's feet (the
/// middle of the bottom edge of its box) at (0, 0) and things above them at
/// negative y.
abstract class EnemyMove {
  double _age = 0;

  /// Seconds since the move was made, for animations.
  double get age => _age;

  /// A short name of where the move is now, for tests.
  String get phaseName;

  /// Runs one frame. Returns true when the move has done everything this frame and
  /// the enemy's normal behaviour (pacing, lunging) must not run.
  bool update(EnemyComponent e, double dt);

  /// Whether touching this enemy costs the student a heart right now. A hit always
  /// lands whatever this says.
  bool get hurtsOnTouch => true;

  EnemyLook look(EnemyComponent e) => const EnemyLook();

  void paintBehind(Canvas canvas, EnemyComponent e) {}
  void paintOver(Canvas canvas, EnemyComponent e) {}

  /// The student's hit landed (before the enemy reacts to it).
  void onHit(EnemyComponent e) {}

  /// The enemy was taken out of the game: give back whatever it was holding.
  void onRemoved(EnemyComponent e) {}
}

double _centreX(PositionComponent c) => c.position.x + c.size.x / 2;

// ─── 1. Hopper ───────────────────────────────────────────────────────────
enum HopperPhase { walk, squat, hop, dizzy }

/// A walker that squats (flash and "!"), hops about 140 units at the student, lands
/// dizzy for 1.4 s (it cannot hurt then and a hit gets it) and walks on.
class HopperMove extends EnemyMove {
  HopperPhase phase = HopperPhase.walk;
  double _t = 0;
  double _cooldown = SurpriseConstants.hopFirstDelay;
  int _dir = 1;
  double _distance = 0;
  double _travelled = 0;
  double _baseY = 0;
  SurpriseRegistry? _counted;

  @override
  String get phaseName => phase.name;

  @override
  bool get hurtsOnTouch => phase != HopperPhase.dizzy;

  /// Seconds into the squat, for tests.
  double get phaseTime => _t;

  void _release(EnemyComponent e) {
    _counted?.finish(this);
    _counted = null;
  }

  @override
  bool update(EnemyComponent e, double dt) {
    _age += dt;
    switch (phase) {
      case HopperPhase.walk:
        _cooldown -= dt;
        if (_cooldown <= 0 && _tryStartSquat(e)) return true;
        return _walkHome(e, dt);
      case HopperPhase.squat:
        _t += dt;
        if (_t >= SurpriseConstants.hopSquat) {
          phase = HopperPhase.hop;
          _t = 0;
          _travelled = 0;
          _baseY = e.position.y;
        }
        return true;
      case HopperPhase.hop:
        _t += dt;
        _hopStep(e, dt);
        return true;
      case HopperPhase.dizzy:
        _t += dt;
        if (_t >= SurpriseConstants.hopDizzy) {
          phase = HopperPhase.walk;
          _cooldown = SurpriseConstants.hopCooldown;
        }
        return true;
    }
  }

  bool _tryStartSquat(EnemyComponent e) {
    final s = e.studentWithin(SurpriseConstants.hopTriggerRange);
    if (s == null) return false;
    final dx = _centreX(s) - _centreX(e);
    if (dx.abs() < SurpriseConstants.hopMinRange) return false;
    final registry = e.game.surprises;
    if (!registry.tryStart(this)) return false;
    _counted = registry;
    _dir = dx >= 0 ? 1 : -1;
    e.facing = _dir;
    _distance = min(SurpriseConstants.hopDistance, dx.abs());
    phase = HopperPhase.squat;
    _t = 0;
    e.game.audioService.playHeavyWindup();
    return true;
  }

  void _hopStep(EnemyComponent e, double dt) {
    final p = (_t / SurpriseConstants.hopDuration).clamp(0.0, 1.0);
    final step = min(SurpriseConstants.hopSpeed * dt, _distance - _travelled);
    final nextX = e.position.x + step * _dir;
    final leash = e.patrolLimit + SurpriseConstants.hopDistance;
    final canGo = e.canStandAt(nextX) && (nextX - e.homeX).abs() <= leash;
    var landed = false;
    if (canGo) {
      e.position.x = nextX;
      _travelled += step;
    } else {
      landed = true; // stopped short at a ledge: it comes down there
    }
    e.position.y = _baseY - SurpriseConstants.hopPeak * 4 * p * (1 - p);
    if (landed || _t >= SurpriseConstants.hopDuration) _land(e);
  }

  void _land(EnemyComponent e) {
    e.position.y = _baseY;
    phase = HopperPhase.dizzy;
    _t = 0;
    _release(e);
  }

  /// A hopper that landed beyond its patrol range walks back to it instead of
  /// being snapped back. True while it does.
  bool _walkHome(EnemyComponent e, double dt) {
    final off = e.position.x - e.homeX;
    if (off.abs() <= e.patrolLimit) return false;
    final dir = off > 0 ? -1 : 1;
    e.facing = dir;
    e.position.x += CombatConstants.patrolSpeed * dir * dt;
    return true;
  }

  @override
  EnemyLook look(EnemyComponent e) {
    switch (phase) {
      case HopperPhase.squat:
        final p = (_t / SurpriseConstants.hopSquat).clamp(0.0, 1.0);
        final flashOn =
            (_t * SurpriseConstants.hopFlashHz).floor().isEven ? 0.78 : 0.0;
        return EnemyLook(
            scaleY: 1 - SurpriseConstants.hopSquashDepth * sin(p * pi * 0.8),
            flash: flashOn);
      case HopperPhase.hop:
        return const EnemyLook(scaleY: 1.08, picture: 'hop');
      case HopperPhase.dizzy:
        final land = _t < 0.25
            ? 1 - 0.14 * sin(_t / 0.25 * pi)
            : 1 + 0.02 * sin(_age * 9);
        return EnemyLook(scaleY: land, picture: 'idle');
      case HopperPhase.walk:
        return const EnemyLook();
    }
  }

  @override
  void paintOver(Canvas canvas, EnemyComponent e) {
    final h = e.drawnHeight;
    if (phase == HopperPhase.squat) {
      final p = (_t / SurpriseConstants.hopSquat).clamp(0.0, 1.0);
      final sy = 1 - SurpriseConstants.hopSquashDepth * sin(p * pi * 0.8);
      SurpriseArt.bang(canvas, 0, -h * sy, _t);
    } else if (phase == HopperPhase.dizzy && _t > 0.3) {
      SurpriseArt.dizzyStars(canvas, 0, -h, _age);
    }
  }

  @override
  void onHit(EnemyComponent e) {
    if (phase == HopperPhase.hop) e.position.y = _baseY;
    phase = HopperPhase.walk;
    _release(e);
  }

  @override
  void onRemoved(EnemyComponent e) => _release(e);
}

// ─── 2. The enemy a ground pop raises ────────────────────────────────────
/// An enemy coming up out of the ground. For [SurpriseConstants.popRise] seconds it
/// stands still, sunk into the ground and cut off at it; it can be hit at once and
/// cannot hurt until it is fully up. Then it is an ordinary walker.
class RiseMove extends EnemyMove {
  double _t = 0;

  bool get rising => _t < SurpriseConstants.popRise;

  @override
  String get phaseName => rising ? 'rising' : 'up';

  @override
  bool get hurtsOnTouch => !rising;

  @override
  bool update(EnemyComponent e, double dt) {
    _age += dt;
    _t += dt;
    return rising;
  }

  @override
  EnemyLook look(EnemyComponent e) {
    if (!rising) return const EnemyLook();
    final p = (_t / SurpriseConstants.popRise).clamp(0.0, 1.0);
    return EnemyLook(
        lift: -e.drawnHeight * (1 - SurpriseArt.ease(p)) - 4,
        clipAtGround: true);
  }

  @override
  void paintOver(Canvas canvas, EnemyComponent e) {
    if (rising) SurpriseArt.riseDebris(canvas, 0, _t);
  }
}

// ─── 4. Thrower ──────────────────────────────────────────────────────────
enum ThrowerPhase { idle, windup, flight }

/// The era's heavy enemy as a thrower. It never moves and never lunges. When a student
/// is in range it flashes with a "!" for 0.6 s while a ring on the ground shows where
/// its item will land, then throws it: the item flies slowly, and about 1.4 s later
/// it lands in the ring. Only the ring hurts (see [ThrownItemComponent]).
class ThrowerMove extends EnemyMove {
  ThrowerPhase phase = ThrowerPhase.idle;
  double _t = 0;
  double _cooldown = SurpriseConstants.throwFirstDelay;
  ThrownItemComponent? _item;
  SurpriseRegistry? _counted;

  @override
  String get phaseName => phase.name;

  /// The item in the air, for tests.
  ThrownItemComponent? get item => _item;

  /// Gives the slot back. The item calls it when it lands or is called off, so a thrower
  /// beaten while its item is still in the air keeps its slot until the item has landed.
  void _release() {
    _counted?.finish(this);
    _counted = null;
  }

  @override
  bool update(EnemyComponent e, double dt) {
    _age += dt;
    switch (phase) {
      case ThrowerPhase.idle:
        _cooldown -= dt;
        if (_cooldown <= 0) _tryWindup(e);
      case ThrowerPhase.windup:
        _t += dt;
        if (_t >= SurpriseConstants.throwWindup) {
          phase = ThrowerPhase.flight;
          _t = 0;
        }
      case ThrowerPhase.flight:
        _t += dt;
        final item = _item;
        if (item == null || item.finished) {
          _item = null;
          phase = ThrowerPhase.idle;
          _cooldown = SurpriseConstants.throwCooldown;
          _release();
        }
    }
    return true;
  }

  void _tryWindup(EnemyComponent e) {
    final s = e.student;
    if (s == null || !s.isOnGround) return;
    final dx = _centreX(s) - _centreX(e);
    if (dx.abs() < SurpriseConstants.throwMinRange ||
        dx.abs() > SurpriseConstants.throwRange) {
      return;
    }
    final feetE = e.position.y + e.size.y;
    final feetS = s.position.y + s.size.y;
    if ((feetS - feetE).abs() > 60) return;
    final registry = e.game.surprises;
    if (!registry.tryStart(this)) return;
    _counted = registry;
    final dir = dx >= 0 ? 1 : -1;
    e.facing = dir;
    final hand = Vector2(_centreX(e) + dir * 34, feetE - 72);
    final item = ThrownItemComponent(
      kind: thrownKindFor(e.kind),
      from: hand,
      targetX: _centreX(s),
      groundY: feetS,
      onFinished: _release,
    );
    e.game.world.add(item);
    _item = item;
    phase = ThrowerPhase.windup;
    _t = 0;
    e.game.audioService.playHeavyWindup();
  }

  @override
  EnemyLook look(EnemyComponent e) {
    if (phase == ThrowerPhase.windup) {
      final on = (_t * 12).floor().isEven ? 0.78 : 0.0;
      return EnemyLook(scaleY: 0.94, flash: on);
    }
    if (phase == ThrowerPhase.flight && _t < SurpriseConstants.throwShow) {
      return const EnemyLook(picture: 'attack');
    }
    return const EnemyLook();
  }

  @override
  void paintOver(Canvas canvas, EnemyComponent e) {
    if (phase == ThrowerPhase.windup) {
      SurpriseArt.bang(canvas, 0, -e.drawnHeight, _t);
    }
  }

  /// A hit before the item has left cancels the throw (the ring goes); one already
  /// in the air still lands.
  @override
  void onHit(EnemyComponent e) {
    if (phase == ThrowerPhase.windup) {
      _item?.cancel();
      _item = null;
      phase = ThrowerPhase.idle;
      _cooldown = SurpriseConstants.throwCooldown;
      _release();
    }
  }

  @override
  void onRemoved(EnemyComponent e) {
    if (phase == ThrowerPhase.windup) _item?.cancel();
    if (_item?.finished ?? true) _release();
  }
}

// ─── 5. Golden runner ────────────────────────────────────────────────────
enum GoldenPhase { watch, alert, run, rest }

/// A gold soldier that never hurts. It runs about 200 units away from a student who
/// comes close (after a "!"), stops to catch its breath, and drops 8 to 10 bonus coins
/// when hit.
class GoldenMove extends EnemyMove {
  GoldenPhase phase = GoldenPhase.watch;
  double _t = 0;
  int _runDir = 1;
  double _travelled = 0;
  bool _announced = false;

  @override
  String get phaseName => phase.name;

  @override
  bool get hurtsOnTouch => false;

  @override
  bool update(EnemyComponent e, double dt) {
    _age += dt;
    if (!_announced &&
        e.studentWithin(SurpriseConstants.goldenAnnounce) != null) {
      _announced = true;
      e.game.world.add(PraiseComponent(word: 'Golden!')
        ..position = Vector2(_centreX(e), e.position.y - 4));
    }
    switch (phase) {
      case GoldenPhase.watch:
        final s = e.studentWithin(SurpriseConstants.goldenSight);
        if (s == null) return false;
        final toward = _centreX(s) >= _centreX(e) ? 1 : -1;
        _runDir = -toward;
        e.facing = toward;
        phase = GoldenPhase.alert;
        _t = 0;
        e.game.audioService.playChaserNotice();
        return true;
      case GoldenPhase.alert:
        _t += dt;
        if (_t >= SurpriseConstants.goldenAlert) {
          phase = GoldenPhase.run;
          _t = 0;
          _travelled = 0;
          e.facing = _runDir;
        }
        return true;
      case GoldenPhase.run:
        _t += dt;
        final step = min(SurpriseConstants.goldenSpeed * dt,
            SurpriseConstants.goldenDistance - _travelled);
        final nextX = e.position.x + step * _runDir;
        var blocked = false;
        if (e.canStandAt(nextX)) {
          e.position.x = nextX;
          _travelled += step;
        } else {
          blocked = true; // never off a ledge: it stops where the ground ends
        }
        if (blocked ||
            _t >= SurpriseConstants.goldenRunTime ||
            _travelled >= SurpriseConstants.goldenDistance - 0.001) {
          phase = GoldenPhase.rest;
          _t = 0;
          e.rehome(); // paces round where it stopped, not back at its old spot
        }
        return true;
      case GoldenPhase.rest:
        _t += dt;
        if (_t >= SurpriseConstants.goldenRest) {
          phase = GoldenPhase.watch;
          _t = 0;
        }
        return true;
    }
  }

  @override
  EnemyLook look(EnemyComponent e) {
    switch (phase) {
      case GoldenPhase.run:
        return EnemyLook(gold: true, scaleY: 1 + 0.04 * sin(_age * 20));
      case GoldenPhase.rest:
        return EnemyLook(
            gold: true, scaleY: 1 + 0.025 * sin(_age * 7), picture: 'idle');
      default:
        return const EnemyLook(gold: true);
    }
  }

  @override
  void paintBehind(Canvas canvas, EnemyComponent e) {
    SurpriseArt.glow(canvas, 0, -e.drawnHeight / 2);
  }

  @override
  void paintOver(Canvas canvas, EnemyComponent e) {
    final h = e.drawnHeight;
    SurpriseArt.sparkles(canvas, 0, -h * 0.9, _age);
    if (phase == GoldenPhase.alert) SurpriseArt.bang(canvas, 0, -h, _t);
    if (phase == GoldenPhase.rest) SurpriseArt.sweat(canvas, 0, -h, _age);
  }
}
