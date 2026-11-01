import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Whether things may move: not when the phone is set to remove animations.
bool motionAllowed(BuildContext context) =>
    !MediaQuery.disableAnimationsOf(context);

/// A backdrop that is quietly alive: slow golden rays turning behind [center], a
/// soft glow, and a few fireflies drifting up. It paints behind the content and
/// takes no taps.
///
/// With [animate] false (or the phone's "remove animations" on) it is one still
/// picture and schedules no frames.
class LivingBackdrop extends StatefulWidget {
  /// Where the light comes from, as a fraction of the box (0..1 each way).
  final Offset center;
  final Color color;
  final int fireflies;

  /// False: only the soft glow, no rays.
  final bool rays;

  /// null: follow the phone's setting.
  final bool? animate;

  const LivingBackdrop({
    super.key,
    this.center = const Offset(0.5, 0.5),
    this.color = AppColors.accent,
    this.fireflies = 14,
    this.rays = true,
    this.animate,
  });

  @override
  State<LivingBackdrop> createState() => _LivingBackdropState();
}

class _LivingBackdropState extends State<LivingBackdrop>
    with SingleTickerProviderStateMixin {
  /// The longest wait before the picture repeats: the fireflies' periods (4, 5, 8
  /// and 10 seconds) all divide it, so the loop has no jump.
  static const Duration loop = Duration(seconds: 40);

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: loop);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = widget.animate ?? motionAllowed(context);
    if (on && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!on && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _LivingPainter(
                seconds: _controller.value * loop.inSeconds,
                center: widget.center,
                color: widget.color,
                fireflies: widget.fireflies,
                rays: widget.rays,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LivingPainter extends CustomPainter {
  final double seconds;
  final Offset center;
  final Color color;
  final int fireflies;
  final bool rays;

  _LivingPainter({
    required this.seconds,
    required this.center,
    required this.color,
    required this.fireflies,
    required this.rays,
  });

  /// One turn in 70 seconds: slow enough to be felt rather than watched.
  static const double secondsPerTurn = 70;
  static const int rayCount = 24;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final c = Offset(size.width * center.dx, size.height * center.dy);
    final reach = size.shortestSide * 1.05;

    // The glow under the rays.
    final glowRect =
        Rect.fromCenter(center: c, width: reach * 0.95, height: reach * 0.7);
    canvas.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0)],
        ).createShader(glowRect),
    );

    // The rays: 24 narrow wedges that fade out with distance.
    if (rays) _paintRays(canvas, c, reach);

    _paintFireflies(canvas, size);
  }

  void _paintRays(Canvas canvas, Offset c, double reach) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(seconds / secondsPerTurn * 2 * math.pi);
    final disc = Rect.fromCircle(center: Offset.zero, radius: reach);
    final path = Path();
    const step = 2 * math.pi / rayCount;
    const width = step * 0.4;
    for (var i = 0; i < rayCount; i++) {
      path
        ..moveTo(0, 0)
        ..arcTo(disc, i * step, width, false)
        ..close();
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.26), color.withValues(alpha: 0)],
        ).createShader(disc),
    );
    canvas.restore();
  }

  /// Fireflies, each on its own loop, rising and fading in and out.
  void _paintFireflies(Canvas canvas, Size size) {
    final random = math.Random(7);
    final glow = Paint()
      ..color = const Color(0xFFFFE98A).withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final core = Paint()..color = const Color(0xFFFFE98A);
    for (var i = 0; i < fireflies; i++) {
      final x = 0.06 + random.nextDouble() * 0.88;
      final y = 0.14 + random.nextDouble() * 0.66;
      final period = const [4.0, 5.0, 8.0, 10.0][random.nextInt(4)];
      final phase = random.nextDouble();
      final dx = (random.nextDouble() - 0.5) * 60;
      final dy = -(10 + random.nextDouble() * 40);
      final p = (seconds / period + phase) % 1;
      final alpha = math.sin(p * math.pi);
      final at = Offset(size.width * x + dx * p, size.height * y + dy * p);
      glow.color = const Color(0xFFFFE98A).withValues(alpha: 0.7 * alpha);
      canvas.drawCircle(at, 3.5, glow);
      canvas.drawCircle(at, 1.6,
          core..color = const Color(0xFFFFE98A).withValues(alpha: alpha));
    }
  }

  @override
  bool shouldRepaint(_LivingPainter old) =>
      old.seconds != seconds ||
      old.center != center ||
      old.color != color ||
      old.rays != rays ||
      old.fireflies != fireflies;
}

/// Moves its child up and down a few pixels, forever: a hero that breathes.
/// Still when animations are off.
class Bob extends StatefulWidget {
  final Widget child;
  final double height;
  final bool? animate;

  const Bob({super.key, required this.child, this.height = 5, this.animate});

  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends State<Bob> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = widget.animate ?? motionAllowed(context);
    if (on && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!on && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(
            0, -widget.height * Curves.easeInOut.transform(_controller.value)),
        child: child,
      ),
    );
  }
}
