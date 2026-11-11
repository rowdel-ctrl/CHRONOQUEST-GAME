import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Canvas;

import '../../core/combat_constants.dart';
import '../../core/hero_move_constants.dart';
import '../chrono_game.dart';
import '../hero_move_art.dart';
import '../kaalaman_handler.dart';
import 'enemy_component.dart';

/// One attack costs one Kaalaman charge, and only if it hits something. Every
/// flying thing (and the dash) of one attack shares one of these, so a net that
/// catches three enemies, or three pages that each hit, still cost a single charge.
class MoveCharge {
  bool _spent = false;

  /// Whether the charge has been taken yet.
  bool get spent => _spent;

  void spend(ChronoGame game) {
    if (_spent) return;
    _spent = true;
    game.trySpendCharge();
  }
}

/// Calls [callback] at most once, however many times it is asked.
class CallOnce {
  CallOnce(this._callback);
  VoidCallback? _callback;

  bool get called => _callback == null;

  void call() {
    final f = _callback;
    _callback = null;
    f?.call();
  }
}

/// A flying thing a hero throws (the 2026-11 hero moves): Juan's coin, Maria's net,
/// Del Pilar's shot, Luna's saber wave, Maria Clara's petals, a page of Rizal's.
/// It flies level at the hero's chest, over gaps, and hits enemies through
/// `EnemyComponent.takeHit`.
///
/// Hits are found two ways that agree: Flame's collision callbacks, and a sweep of
/// the ground covered each frame (a 700 units/s shot covers 12 units a frame and a
/// slow frame covers far more, so contact alone could skip an enemy). One flying
/// thing hits one enemy at most once.
///
/// With [counterTargetX] set it is a counter instead: for a right answer in the
/// boss fight it flies to that x, calls [counter] on arrival and hits nothing.
class HeroProjectileComponent extends PositionComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  final HeroMove move;

  /// Which way it is thrown: 1 right, -1 left.
  final double direction;
  final MoveCharge? charge;
  final double? counterTargetX;
  final CallOnce? counter;

  final double _startX;
  late final double _speed;

  /// Which way it is flying right now (the boomerang turns round).
  late double _flyDir = direction;
  bool _returning = false;
  bool _done = false;
  double _age = 0;
  double _spin = 0;
  final Set<EnemyComponent> _hit = {};

  HeroProjectileComponent({
    required this.move,
    required this.direction,
    required Vector2 centre,
    this.charge,
    this.counterTargetX,
    this.counter,
  })  : _startX = centre.x,
        super(
          position: centre,
          size: Vector2(move.hitWidth, move.hitHeight),
          anchor: Anchor.center,
          priority: 12,
        ) {
    final target = counterTargetX;
    _speed = target == null
        ? move.speed
        : max(
            move.speed,
            (target - centre.x).abs() /
                HeroMoveConstants.counterMaxFlightSeconds);
  }

  bool get isCounter => counterTargetX != null;

  /// Whether the boomerang is on its way home.
  @visibleForTesting
  bool get returning => _returning;

  /// Whether it has ended (it is being removed).
  @visibleForTesting
  bool get finished => _done;

  /// How many different enemies it has hit.
  @visibleForTesting
  int get hitCount => _hit.length;

  /// How far it has flown out from where it started, in the way it was thrown.
  @visibleForTesting
  double get distanceOut => (position.x - _startX) * direction;

  @override
  Future<void> onLoad() async {
    if (!isCounter) add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_done) return;
    _age += dt;
    _spin += dt * 12;
    final limit = isCounter
        ? HeroMoveConstants.counterFailsafeSeconds
        : HeroMoveConstants.failsafeSeconds;
    if (_age >= limit) {
      _finish();
      return;
    }
    if (_returning) {
      _flyHome(dt);
    } else if (isCounter) {
      _flyToTarget(dt);
    } else {
      _flyOut(dt);
    }
  }

  void _flyOut(double dt) {
    final from = position.x;
    final step = min(_speed * dt, max(0.0, move.range - distanceOut));
    position.x += direction * step;
    _sweep(from, position.x);
    if (_done || _returning) return;
    if (move.range - distanceOut <= 0.001) {
      // The end of its range: the boomerang turns back, anything else is spent.
      if (move.kind == HeroMoveKind.boomerang) {
        _returning = true;
      } else {
        _finish();
      }
    }
  }

  void _flyToTarget(double dt) {
    final target = counterTargetX!;
    final left = (target - position.x) * direction;
    position.x += direction * min(_speed * dt, max(0.0, left));
    if ((target - position.x) * direction <= 0.001) {
      position.x = target;
      counter?.call();
      // The boomerang goes home after meeting it; the others are spent.
      if (move.kind == HeroMoveKind.boomerang) {
        _returning = true;
      } else {
        _finish();
      }
    }
  }

  void _flyHome(double dt) {
    final goal = _heroCentreX();
    if (goal == null) {
      _finish();
      return;
    }
    final gap = goal - position.x;
    if (gap.abs() <= HeroMoveConstants.boomerangCatchDistance) {
      _finish();
      return;
    }
    final from = position.x;
    _flyDir = gap >= 0 ? 1 : -1;
    position.x += _flyDir * min(_speed * dt, gap.abs());
    _sweep(from, position.x);
  }

  double? _heroCentreX() {
    try {
      final p = game.player;
      return p.position.x + p.size.x / 2;
    } catch (_) {
      return null; // a bare game with no player
    }
  }

  /// Hits every enemy the thing passed through between [from] and [to] this frame,
  /// the one it met first first, stopping as soon as a hit ends or turns it.
  void _sweep(double from, double to) {
    if (isCounter) return;
    final left = min(from, to) - move.hitWidth / 2;
    final right = max(from, to) + move.hitWidth / 2;
    final top = position.y - move.hitHeight / 2;
    final bottom = position.y + move.hitHeight / 2;
    final met = <EnemyComponent>[];
    for (final e in game.world.children.whereType<EnemyComponent>()) {
      if (e.defeated || _hit.contains(e)) continue;
      final r = e.hitRect;
      if (r.right > left &&
          r.left < right &&
          r.bottom > top &&
          r.top < bottom) {
        met.add(e);
      }
    }
    if (met.isEmpty) return;
    final way = _flyDir;
    met.sort((a, b) => ((a.hitRect.center.dx - from) * way)
        .compareTo((b.hitRect.center.dx - from) * way));
    for (final e in met) {
      if (_strike(e)) break;
    }
  }

  /// Hits [e]. Returns true when that ended the flight or turned it round, so no
  /// further enemy is hit this frame.
  bool _strike(EnemyComponent e) {
    if (_done || e.defeated || _hit.contains(e)) return false;
    // Measured before the hit: a beaten enemy is thrown away at once.
    final spotX = e.hitRect.center.dx;
    final feet = e.position.y + e.size.y;
    _hit.add(e);
    charge?.spend(game);
    e.takeHit();
    if (move.groupRadius > 0) _catchNeighbours(e, spotX, feet);

    switch (move.kind) {
      case HeroMoveKind.wave:
      case HeroMoveKind.dash:
        return false; // goes on through everything
      case HeroMoveKind.boomerang:
        if (_returning) return false; // on the way home it goes through
        _returning = true; // turns back at once
        return true;
      case HeroMoveKind.shot:
      case HeroMoveKind.burst:
        _finish();
        return true;
    }
  }

  /// The net also catches enemies close to the one it hit, on the same level.
  void _catchNeighbours(EnemyComponent first, double spotX, double feet) {
    for (final o in game.world.children.whereType<EnemyComponent>().toList()) {
      if (o == first || o.defeated || _hit.contains(o)) continue;
      if ((o.hitRect.center.dx - spotX).abs() > move.groupRadius) continue;
      final oFeet = o.position.y + o.size.y;
      if ((oFeet - feet).abs() > CombatConstants.sameLevelTolerance) continue;
      _hit.add(o);
      o.takeHit();
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    // A counter never ends without telling whoever asked for it.
    counter?.call();
    removeFromParent();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (isCounter || other is! EnemyComponent) return;
    _strike(other);
  }

  @override
  void onRemove() {
    super.onRemove();
    // Taken out of the world before it arrived (the level ended, say): still tell.
    try {
      counter?.call();
    } catch (e) {
      debugPrint('counter callback failed on removal: $e');
    }
  }

  @override
  void render(Canvas canvas) {
    final shape = move.shape;
    if (shape == null) return;
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    if (_flyDir < 0) canvas.scale(-1, 1);
    paintHeroShape(canvas, shape, spin: _spin);
    canvas.restore();
  }
}
