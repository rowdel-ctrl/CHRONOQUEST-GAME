import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../boss_attack_profile.dart';
import 'boss_attack_paint.dart';

/// What the attack is doing right now.
enum BossAttackMode {
  /// Flying from the boss to the hero; [BossAttackComponent.progress] says how far.
  incoming,

  /// Held where it is (Time Freeze, or while the hero's counter is on its way to it).
  frozen,

  /// Sent back at the boss by the hero's counter.
  reflect,

  /// Fading away (the ghost knights vanish).
  fading,
}

/// One boss attack in flight, drawn in code (see boss_attack_paint*.dart).
///
/// It has no clock of its own: the boss sets [progress] (and [reflectProgress]) every frame
/// from the question's timer, so the attack reaches the hero at exactly 1, when the time is up.
/// The component sits at the world's origin and paints in world units.
class BossAttackComponent extends PositionComponent {
  BossAttackComponent({
    required this.kind,
    required Vector2 start,
    required Vector2 end,
    this.mirrored = false,
  })  : start = start.clone(),
        end = end.clone(),
        super(priority: 9);

  final BossAttackKind kind;

  /// True when the hero is on the boss's right: every attack is drawn flying left (the way the
  /// pictures face), so it is drawn mirrored. Positions stay real world positions; only the
  /// painting is flipped (about [start]'s x).
  final bool mirrored;

  /// Where it leaves the boss, and where it meets the hero (world units). The boss keeps
  /// them right if either moves.
  final Vector2 start;
  final Vector2 end;

  BossAttackMode mode = BossAttackMode.incoming;

  /// 0 at the boss, 1 at the hero.
  double progress = 0;

  /// While sent back: 0 where it was hit, 1 at the boss.
  double reflectProgress = 0;

  Vector2 _from = Vector2.zero();
  Vector2 _to = Vector2.zero();

  /// 1 until it fades.
  double fade = 1;
  double _anim = 0;

  /// Seconds it has been alive (for spinning and wobbling).
  double get anim => _anim;

  Vector2 _at(double p) => start + (end - start) * p.clamp(0.0, 1.0);

  /// Where its head is now.
  Vector2 get head => mode == BossAttackMode.reflect
      ? _from + (_to - _from) * reflectProgress.clamp(0.0, 1.0)
      : _at(progress);

  /// Where the hero's counter should aim: the middle of what is drawn.
  Vector2 get centre {
    final h = head;
    return switch (kind) {
      BossAttackKind.whirl ||
      BossAttackKind.knights ||
      BossAttackKind.ghost =>
        Vector2(h.x, h.y - 40),
      _ => h,
    };
  }

  /// The hero's counter met it: from here it flies back to [boss].
  void sendBack(Vector2 boss) {
    _from = head.clone();
    _to = boss.clone();
    reflectProgress = 0;
    mode = BossAttackMode.reflect;
  }

  /// Holds it where it is.
  void freeze() {
    if (mode == BossAttackMode.incoming) mode = BossAttackMode.frozen;
  }

  void fadeOut() => mode = BossAttackMode.fading;

  @override
  void update(double dt) {
    super.update(dt);
    _anim += dt;
    if (mode == BossAttackMode.fading) {
      fade -= dt / 0.25;
      if (fade <= 0) removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final rev = mode == BossAttackMode.reflect;
    final h = head;
    final pivot = start.x;
    // Mirrored: paint at the mirror image of each point, inside a mirrored canvas.
    double vx(double x) => mirrored ? 2 * pivot - x : x;
    final step = rev ? .04 : kind.trail.step;
    final count = kind.trail.count;
    final base = rev ? reflectProgress : progress;
    Offset trail(int k) {
      final i = math.min(k, count - 1);
      final t = math.max(0.0, base - i * step);
      final v = rev ? _from + (_to - _from) * t : _at(t);
      return Offset(vx(v.x), v.y);
    }

    if (mirrored) {
      canvas.save();
      canvas.translate(2 * pivot, 0);
      canvas.scale(-1, 1);
    }
    paintBossAttack(
      canvas,
      BossAttackFrame(
        kind: kind,
        x: vx(h.x),
        y: h.y,
        p: rev ? 1 : progress.clamp(0.0, 1.0),
        q: rev ? reflectProgress : 0,
        rev: rev,
        anim: _anim,
        trail: trail,
      ),
      alpha: fade.clamp(0.0, 1.0),
    );
    if (mirrored) canvas.restore();
  }
}
