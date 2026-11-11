import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../core/hero_move_constants.dart';
import 'components/enemy_component.dart';
import 'components/hero_projectile_component.dart';
import 'components/player_component.dart';

/// Plays the hero's own move for [PlayerComponent] (the 2026-11 hero moves): the
/// flying things of the ranged heroes (the burst's later pages wait on a per-frame
/// timer) and the dash of the dash heroes, plus the same moves aimed at a boss
/// attack ([counter]).
///
/// The player calls [updatePages] every frame, [stepDash] where it moves the hero
/// sideways, and [afterMove] once walls and gates have had their say. Nothing here
/// uses wall-clock time or `Future.delayed`.
class HeroMoveRunner {
  final PlayerComponent player;

  HeroMoveRunner(this.player);

  HeroMove get move => heroMoveFor(player.characterId);

  /// Pages of a burst not thrown yet.
  final List<_Throw> _waiting = [];
  _Dash? _dash;

  /// Whether a dash (or a counter dash with its glide home) is going on. The hero
  /// cannot be hurt and cannot steer for as long as it is.
  bool get dashing => _dash != null;

  /// Whether the hero is busy with a counter dash, so no new attack may start.
  bool get busyWithCounter => _dash?.counter != null;

  /// What the player draws for a dash: how far through it is, how far it goes, and
  /// whether it is only gliding home after a counter. Null when there is no dash.
  ({double progress, double distance, bool gliding})? get dashLook {
    final d = _dash;
    if (d == null) return null;
    return (
      progress: d.gliding ? 1.0 : (d.elapsed / d.seconds).clamp(0.0, 1.0),
      distance: d.dist,
      gliding: d.gliding,
    );
  }

  /// Pages of a burst still waiting to be thrown.
  @visibleForTesting
  int get pagesWaiting => _waiting.length;

  // ─── Ranged moves ─────────────────────────────────────────────────────────

  /// Throws the hero's flying thing in the facing direction: one, or the first of a
  /// burst (the rest follow [HeroMove.gap] seconds apart).
  void fire() {
    final m = move;
    final dir = player.facingRight ? 1.0 : -1.0;
    final charge = MoveCharge();
    _throw(_Throw(0, dir, charge: charge));
    for (var i = 1; i < m.count; i++) {
      _waiting.add(_Throw(i * m.gap, dir, charge: charge));
    }
  }

  /// Counts the waiting pages down and throws those that are due.
  void updatePages(double dt) {
    if (_waiting.isEmpty) return;
    for (final t in List<_Throw>.of(_waiting)) {
      t.delay -= dt;
      if (t.delay <= 0) {
        _waiting.remove(t);
        _throw(t);
      }
    }
  }

  void _throw(_Throw t) {
    final centreX = player.position.x + player.size.x / 2;
    final feetY = player.position.y + player.size.y;
    player.game.world.add(HeroProjectileComponent(
      move: move,
      direction: t.direction,
      centre: Vector2(
        centreX + t.direction * HeroMoveConstants.startAhead,
        feetY - HeroMoveConstants.shotHeight,
      ),
      charge: t.charge,
      counterTargetX: t.targetX,
      counter: t.once,
    ));
  }

  // ─── Dash ─────────────────────────────────────────────────────────────────

  /// The dash heroes' move: forward [HeroMove.dashDistance] in [HeroMove.dashSeconds],
  /// safe all the while, slicing every enemy in the path once. Needs the ground
  /// under the hero (the player decides that).
  void startDash() {
    final m = move;
    _dash = _Dash(
      dir: player.facingRight ? 1.0 : -1.0,
      fromX: player.position.x,
      dist: m.dashDistance,
      seconds: m.dashSeconds,
      charge: MoveCharge(),
    );
    player.showAttackPicture(
      seconds: m.dashSeconds + HeroMoveConstants.dashAfterSeconds,
      secondAt: m.dashSeconds,
    );
    player.game.audioService.playLunge();
  }

  /// Moves the hero along the dash for this frame. Called where the player moves
  /// sideways, before walls are resolved. A ledge or the edge of a pit stops the
  /// dash (the same foot-span rule the enemies keep to).
  void stepDash(double dt) {
    final d = _dash;
    if (d == null) return;
    if (d.gliding) return _stepGlide(dt, d);
    // Left the ground (a jump): a dash that was never a counter is over.
    if (!d.isCounter && !player.isOnGround) {
      _dash = null;
      return;
    }
    d.elapsed += dt;
    final p = (d.elapsed / d.seconds).clamp(0.0, 1.0);
    final eased = 1 - (1 - p) * (1 - p);
    final want = d.fromX + d.dir * d.dist * eased;
    final previousCentre = player.position.x + player.size.x / 2;
    final x = _reach(want);
    final stoppedAtEdge = (x - want).abs() > 0.01;
    player.position.x = x;
    d.expectedX = x;
    if (!d.isCounter) _slice(d, previousCentre);
    if (p >= 1 || stoppedAtEdge) _endDash(d);
  }

  /// How far along the ground the hero's box may be moved towards [want] (its left
  /// edge, world x): the same foot-span rule the knockback keeps to. A hero who
  /// stands with the toes over an edge is held by it only as far as the middle of
  /// the body, which is what stops a dash from carrying it out over the pit.
  double _reach(double want) {
    final x = player.keepOnGround(want);
    if ((x - want).abs() > 0.01) return x;
    if (!player.isOnGround) return want;
    final game = player.game;
    if (game.groundSections.isEmpty && game.platforms.isEmpty) return want;
    final middle = want + player.size.x / 2;
    for (final s in game.groundSections) {
      if (middle >= s.position.x && middle <= s.position.x + s.size.x) {
        return want;
      }
    }
    for (final p in game.platforms) {
      if (middle >= p.position.x && middle <= p.position.x + p.size.x) {
        return want;
      }
    }
    return player.position.x; // would leave the ground: stay
  }

  /// A wall or a gate may have pushed the hero back after [stepDash]: that ends the
  /// dash. Called after both have been resolved.
  void afterMove() {
    final d = _dash;
    if (d == null || d.gliding) return;
    if ((player.position.x - d.expectedX).abs() > 0.5) _endDash(d);
  }

  void _endDash(_Dash d) {
    if (!d.isCounter) {
      _dash = null;
      return;
    }
    // A counter dash has met the attack: tell the boss fight, then glide home.
    d.gliding = true;
    d.glideFrom = player.position.x;
    d.counter!.call();
  }

  void _stepGlide(double dt, _Dash d) {
    d.glideElapsed += dt;
    final p = (d.glideElapsed / HeroMoveConstants.counterGlideSeconds)
        .clamp(0.0, 1.0);
    final eased = p * p * (3 - 2 * p);
    player.position.x =
        player.keepOnGround(d.glideFrom + (d.fromX - d.glideFrom) * eased);
    d.expectedX = player.position.x;
    if (p >= 1) _dash = null;
  }

  /// Cuts every enemy the hero's front reached while moving from [previousCentre]
  /// to where it is now, once each. The first cut spends the attack's charge.
  void _slice(_Dash d, double previousCentre) {
    final centre = player.position.x + player.size.x / 2;
    final lo = min(previousCentre, centre);
    final hi = max(previousCentre, centre);
    final left = lo -
        (d.dir > 0
            ? HeroMoveConstants.dashReachBack
            : HeroMoveConstants.dashReachFront);
    final right = hi +
        (d.dir > 0
            ? HeroMoveConstants.dashReachFront
            : HeroMoveConstants.dashReachBack);
    final feet = player.position.y + player.size.y;
    final top = feet - HeroMoveConstants.dashBandTop;
    final bottom = feet - HeroMoveConstants.dashBandBottom;
    final enemies =
        player.game.world.children.whereType<EnemyComponent>().toList();
    for (final e in enemies) {
      if (e.defeated || d.sliced.contains(e)) continue;
      final r = e.hitRect;
      if (r.right > left &&
          r.left < right &&
          r.bottom > top &&
          r.top < bottom) {
        d.sliced.add(e);
        d.charge?.spend(player.game);
        e.takeHit();
      }
    }
  }

  // ─── Counter ──────────────────────────────────────────────────────────────

  /// This hero's own move aimed at a boss attack at world position [target]:
  /// a flying thing travels from the hero to `target.x` and calls [onImpact] on
  /// arrival (a burst, on its first page's arrival); a dash hero dashes towards it,
  /// at most the move's distance, and calls [onImpact] at the end of the dash,
  /// then glides back to where it stood. Spends no Kaalaman charge and hits no
  /// enemy. [onImpact] is called exactly once, whatever happens.
  void counter({required Vector2 target, required VoidCallback onImpact}) {
    final once = CallOnce(onImpact);
    try {
      if (busyWithCounter) {
        once.call(); // one counter at a time: this one is met at once
        return;
      }
      _dash = null; // an ordinary dash gives way
      final m = move;
      final centre = player.position.x + player.size.x / 2;
      final dx = target.x - centre;
      final dir =
          dx == 0 ? (player.facingRight ? 1.0 : -1.0) : (dx > 0 ? 1.0 : -1.0);
      player.facingRight = dir > 0;
      if (m.isDash) {
        final dist = min(m.dashDistance,
            max(0.0, dx.abs() - HeroMoveConstants.counterMeetGap));
        _dash = _Dash(
          dir: dir,
          fromX: player.position.x,
          dist: dist,
          seconds: m.dashSeconds,
          counter: once,
        );
        player.showAttackPicture(
          seconds: m.dashSeconds + HeroMoveConstants.dashAfterSeconds,
          secondAt: m.dashSeconds,
        );
        player.game.audioService.playLunge();
        return;
      }
      player.showAttackPicture();
      _throw(_Throw(0, dir, targetX: target.x, once: once));
      for (var i = 1; i < m.count; i++) {
        // The later pages of a burst fly to the same place; only the first reports.
        _waiting.add(_Throw(i * m.gap, dir, targetX: target.x));
      }
    } catch (e) {
      debugPrint('hero counter could not play, meeting the attack at once: $e');
      _dash = null;
      _waiting.clear();
      once.call();
    }
  }

  /// Ends whatever is going on (a respawn): a counter in progress still reports.
  void cancel() {
    _waiting.clear();
    final d = _dash;
    _dash = null;
    d?.counter?.call();
  }
}

/// One thing to throw: a page of a burst waits [delay] seconds first.
class _Throw {
  double delay;
  final double direction;
  final MoveCharge? charge;
  final double? targetX;
  final CallOnce? once;

  _Throw(this.delay, this.direction, {this.charge, this.targetX, this.once});
}

class _Dash {
  final double dir;
  final double fromX;
  final double dist;
  final double seconds;

  /// The attack's charge (an ordinary dash only).
  final MoveCharge? charge;

  /// Set for a counter dash: called when the dash ends.
  final CallOnce? counter;
  final Set<EnemyComponent> sliced = {};

  double elapsed = 0;
  double expectedX = 0;
  bool gliding = false;
  double glideElapsed = 0;
  double glideFrom = 0;

  _Dash({
    required this.dir,
    required this.fromX,
    required this.dist,
    required this.seconds,
    this.charge,
    this.counter,
  });

  bool get isCounter => counter != null;
}
