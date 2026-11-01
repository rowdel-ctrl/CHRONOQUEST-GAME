import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'living_backdrop.dart' show motionAllowed;

enum _Kind { puff, spark, confetti, ring }

class _Particle {
  final _Kind kind;
  double x;
  double y;
  double vx;
  double vy;
  final double life;
  final double size;
  final Color color;
  double age = 0;
  double rot;
  final double spin;

  _Particle(this.kind, this.x, this.y, this.vx, this.vy, this.life, this.size,
      this.color,
      {this.rot = 0, this.spin = 0});
}

/// A layer that draws short-lived specks: dust, sparks, confetti and rings of light.
/// Nothing is drawn, and nothing is scheduled, while nothing is alive, and nothing is
/// ever started when the phone has "remove animations" on. Takes no taps.
///
/// Reach it with a [GlobalKey] and call [ParticleLayerState.puff] and friends, with
/// positions in this layer's own coordinates.
class ParticleLayer extends StatefulWidget {
  const ParticleLayer({super.key});

  @override
  ParticleLayerState createState() => ParticleLayerState();
}

class ParticleLayerState extends State<ParticleLayer>
    with SingleTickerProviderStateMixin {
  final List<_Particle> _items = [];
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);
  final math.Random _random = math.Random();
  Ticker? _ticker;
  Duration _last = Duration.zero;

  bool get _allowed => mounted && motionAllowed(context);

  /// How many specks are alive: for tests.
  int get alive => _items.length;

  @override
  void dispose() {
    _ticker?.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _add(_Particle p) {
    _items.add(p);
    final ticker = _ticker ??= createTicker(_tick);
    if (!ticker.isActive) {
      _last = Duration.zero;
      ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt =
        _last == Duration.zero ? 0.016 : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    for (final p in _items) {
      p.age += dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      if (p.kind == _Kind.confetti) p.vy += 420 * dt;
      p.rot += p.spin * dt;
    }
    _items.removeWhere((p) => p.age >= p.life);
    _repaint.value++;
    if (_items.isEmpty) _ticker?.stop();
  }

  /// A small cloud of dust at [at], like feet landing.
  void puff(Offset at, {double size = 9}) {
    if (!_allowed) return;
    _add(_Particle(_Kind.puff, at.dx, at.dy, (_random.nextDouble() - 0.5) * 14,
        -14, 0.48, size, const Color(0xFFF5E3BE)));
  }

  /// A little four-pointed glint.
  void spark(Offset at,
      {double size = 11, Color color = const Color(0xFFFFF3B8)}) {
    if (!_allowed) return;
    _add(_Particle(_Kind.spark, at.dx, at.dy, 0, 0, 0.62, size, color));
  }

  /// A ring of light that grows and fades.
  void ring(Offset at, {Color color = const Color(0xFFFFE08A)}) {
    if (!_allowed) return;
    _add(_Particle(_Kind.ring, at.dx, at.dy, 0, 0, 0.62, 40, color));
  }

  /// [count] coloured pieces thrown up from [at] that tumble down.
  void confetti(Offset at, List<Color> colors, {int count = 30}) {
    if (!_allowed) return;
    for (var i = 0; i < count; i++) {
      final dx = (_random.nextDouble() * 2 - 1) * 150;
      final up = 120 + _random.nextDouble() * 140;
      _add(_Particle(
        _Kind.confetti,
        at.dx,
        at.dy,
        dx,
        -up,
        1.1 + _random.nextDouble() * 0.6,
        4 + _random.nextDouble() * 3,
        colors[i % colors.length],
        rot: _random.nextDouble() * math.pi,
        spin: (_random.nextDouble() * 2 - 1) * 14,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
              size: Size.infinite, painter: _ParticlePainter(_items, _repaint)),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> items;
  _ParticlePainter(this.items, Listenable repaint) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in items) {
      final t = (p.age / p.life).clamp(0.0, 1.0);
      switch (p.kind) {
        case _Kind.puff:
          canvas.drawCircle(
            Offset(p.x, p.y),
            p.size * (0.4 + 1.3 * t),
            Paint()..color = p.color.withValues(alpha: 0.85 * (1 - t)),
          );
        case _Kind.spark:
          final s = p.size * math.sin(t * math.pi) * 1.2;
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(t * math.pi / 2);
          final path = Path()
            ..moveTo(0, -s)
            ..lineTo(s * 0.24, -s * 0.24)
            ..lineTo(s, 0)
            ..lineTo(s * 0.24, s * 0.24)
            ..lineTo(0, s)
            ..lineTo(-s * 0.24, s * 0.24)
            ..lineTo(-s, 0)
            ..lineTo(-s * 0.24, -s * 0.24)
            ..close();
          canvas.drawPath(path, Paint()..color = p.color);
          canvas.restore();
        case _Kind.ring:
          final e = Curves.easeOut.transform(t);
          canvas.drawCircle(
            Offset(p.x, p.y),
            p.size * (0.3 + 4.3 * e) / 2,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4 * (1 - t) + 0.5
              ..color = p.color.withValues(alpha: 1 - t)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
          );
        case _Kind.confetti:
          final fade = t > 0.75 ? 1 - (t - 0.75) / 0.25 : 1.0;
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(p.rot);
          canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero, width: p.size, height: p.size * 1.7),
            Paint()..color = p.color.withValues(alpha: fade),
          );
          canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
