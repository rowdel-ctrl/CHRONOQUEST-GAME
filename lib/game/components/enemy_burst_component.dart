import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import '../../core/combat_constants.dart';
import '../enemy_behavior.dart';

/// The picture of a blast chaser bursting: smoke for the dark spirit, flying paper for
/// propaganda, storm puffs and lightning for the misinfo cloud. Ported from the
/// approved mockup's burstFx. It lives in the world (not on the enemy), is drawn from
/// a seed so every frame is the same picture, and removes itself after
/// [CombatConstants.burstDuration]. The harmless pop uses it at half size.
class EnemyBurstComponent extends PositionComponent {
  final BurstStyle style;
  final double burstScale;
  final int seed;

  double _age = 0;

  EnemyBurstComponent({
    required this.style,
    required Vector2 centre,
    this.burstScale = 1,
    this.seed = 0,
  }) : super(position: centre, anchor: Anchor.center, priority: 15);

  /// Seconds since it started. Public so tests can check it ages and goes away.
  double get age => _age;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= CombatConstants.burstDuration) removeFromParent();
  }

  // Ring colours per style: the stroke and the soft fill inside it.
  static const _flash = {
    BurstStyle.smoke: Color(0xFFC9A6FF),
    BurstStyle.paper: Color(0xFFFF8E7A),
    BurstStyle.storm: Color(0xFFFFE680),
  };
  static const _glow = {
    BurstStyle.smoke: Color(0xFFEBDDFF),
    BurstStyle.paper: Color(0xFFFFE1DA),
    BurstStyle.storm: Color(0xFFFFFBE0),
  };

  final Paint _paint = Paint();

  @override
  void render(Canvas canvas) {
    final sc = burstScale;
    final age = _age;
    final random = Random(11 + seed * 31 + style.index);

    if (age < 0.4) {
      final a = 1 - age / 0.4;
      _paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * sc * a + 1
        ..color = _flash[style]!.withValues(alpha: a);
      canvas.drawCircle(Offset.zero, (20 + age * 300) * sc, _paint);
      _paint
        ..style = PaintingStyle.fill
        ..color = _glow[style]!.withValues(alpha: a * 0.55);
      canvas.drawCircle(Offset.zero, (14 + age * 90) * sc, _paint);
    }
    _paint.style = PaintingStyle.fill;

    switch (style) {
      case BurstStyle.smoke:
        _smoke(canvas, random, age, sc);
      case BurstStyle.paper:
        _paper(canvas, random, age, sc);
      case BurstStyle.storm:
        _storm(canvas, random, age, sc);
    }
  }

  /// Dark violet squares drifting up and out, and cyan sparks.
  void _smoke(Canvas canvas, Random random, double age, double sc) {
    const palette = [
      Color(0xFF2A1646),
      Color(0xFF4B2A7A),
      Color(0xFF1B0E30),
      Color(0xFF63409B),
    ];
    for (var i = 0; i < 18; i++) {
      final a = random.nextDouble() * 2 * pi;
      final speed = (80 + random.nextDouble() * 220) * sc;
      final size = (12 + random.nextDouble() * 22) * sc;
      final life = 0.45 + random.nextDouble() * 0.3;
      if (age > life) continue;
      final d = speed * age * (1 - 0.5 * age);
      final px = cos(a) * d;
      final py = sin(a) * d * 0.8 - 24 * age;
      final s = size * (1 + age);
      _paint.color = palette[i % 4].withValues(alpha: 1 - age / life);
      canvas.drawRect(Rect.fromLTWH(px - s / 2, py - s / 2, s, s), _paint);
    }
    for (var i = 0; i < 10; i++) {
      final a = random.nextDouble() * 2 * pi;
      final speed = (140 + random.nextDouble() * 200) * sc;
      const life = 0.4;
      if (age > life) continue;
      _paint.color = const Color(0xFF8FFFEF).withValues(alpha: 1 - age / life);
      canvas.drawRect(
          Rect.fromLTWH(cos(a) * speed * age, sin(a) * speed * age, 4, 4),
          _paint);
    }
  }

  /// Cream flyers with red lines, fluttering (their width squeezes as they turn).
  void _paper(Canvas canvas, Random random, double age, double sc) {
    for (var i = 0; i < 16; i++) {
      final a = random.nextDouble() * 2 * pi;
      final speed = (60 + random.nextDouble() * 200) * sc;
      final r0 = random.nextDouble() * 2 * pi;
      final rs = (random.nextDouble() - 0.5) * 14;
      final life = 0.55 + random.nextDouble() * 0.25;
      if (age > life) continue;
      final px = cos(a) * speed * age * (1 - 0.4 * age);
      final py = sin(a) * speed * age * 0.7 + 140 * age * age - 40 * age;
      final f = cos(rs * age * 1.3).abs() * 0.8 + 0.2;
      final alpha = age > life - 0.2 ? (life - age) / 0.2 : 1.0;
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(r0 + rs * age * 0.3);
      _paint.color = const Color(0xFFF3EAD2).withValues(alpha: alpha);
      canvas.drawRect(Rect.fromLTWH(-8 * f, -10, 16 * f, 20), _paint);
      _paint.color = const Color(0xFFC0392B).withValues(alpha: alpha);
      for (var j = 0; j < 3; j++) {
        canvas.drawRect(Rect.fromLTWH(-6 * f, -7 + j * 6, 12 * f, 2), _paint);
      }
      canvas.restore();
    }
  }

  /// Grey puffs, and for the first 0.3 s five zig-zag lightning bolts that re-roll
  /// about 30 times a second so they crackle.
  void _storm(Canvas canvas, Random random, double age, double sc) {
    for (var i = 0; i < 9; i++) {
      final a = random.nextDouble() * 2 * pi;
      final d = (40 + random.nextDouble() * 80) * sc * age * 1.5;
      final r = (16 + random.nextDouble() * 16) * sc * (0.6 + age * 2);
      final alpha = max(0.0, 1 - age / CombatConstants.burstDuration);
      _paint.color =
          (i.isOdd ? const Color(0xFF9AA3B5) : const Color(0xFFD7DCEA))
              .withValues(alpha: alpha);
      canvas.drawCircle(Offset(cos(a) * d, sin(a) * d * 0.8), r, _paint);
    }
    if (age >= 0.3) return;
    final step = (age * 30).floor();
    final fade = 1 - age / 0.3;
    for (var i = 0; i < 5; i++) {
      final bolt = Random(100 + step * 7 + i);
      final base = i * 1.2566 + bolt.nextDouble() * 0.5;
      final path = Path()..moveTo(0, 0);
      var x = 0.0, y = 0.0;
      for (var s = 0; s < 6; s++) {
        final ang = base + (bolt.nextDouble() - 0.5) * 1.1;
        x += cos(ang) * 26 * sc;
        y += sin(ang) * 26 * sc;
        path.lineTo(x, y);
      }
      _paint
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.miter
        ..strokeWidth = 6
        ..color = const Color(0xFFFFD23A).withValues(alpha: fade);
      canvas.drawPath(path, _paint);
      _paint
        ..strokeWidth = 2
        ..color = const Color(0xFFFFFBE0).withValues(alpha: fade);
      canvas.drawPath(path, _paint);
    }
    _paint.style = PaintingStyle.fill;
  }
}
