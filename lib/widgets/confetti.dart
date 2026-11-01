import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'living_backdrop.dart';

/// Small coloured pieces falling past, forever: the welcome. Takes no taps. With
/// the phone's "remove animations" on, nothing is drawn at all (falling pieces
/// are the kind of motion that setting is for).
class Confetti extends StatefulWidget {
  final int pieces;

  /// null: follow the phone's setting.
  final bool? animate;

  const Confetti({super.key, this.pieces = 40, this.animate});

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  /// Every piece falls in 2.5, 3.75 or 5 seconds; all three divide 15, so the
  /// loop has no jump.
  static const Duration loop = Duration(seconds: 15);

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: loop);

  bool _on = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _on = widget.animate ?? motionAllowed(context);
    if (_on && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!_on && _controller.isAnimating) {
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
    if (!_on) return const SizedBox.shrink();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(
                  _controller.value * loop.inMilliseconds / 1000,
                  widget.pieces),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double seconds;
  final int pieces;
  _ConfettiPainter(this.seconds, this.pieces);

  static const colors = [
    Color(0xFFFFC531),
    Color(0xFFE8433A),
    Color(0xFF43A83E),
    Color(0xFF3D8FD1),
    Color(0xFFF5E3BE),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final random = math.Random(11);
    final paint = Paint();
    for (var i = 0; i < pieces; i++) {
      final x = random.nextDouble() * size.width;
      final period = const [2.5, 3.75, 5.0][random.nextInt(3)];
      final phase = random.nextDouble();
      final spin = 2 + random.nextDouble() * 3;
      final p = (seconds / period + phase) % 1;
      final y = -14 + p * (size.height + 28);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p * spin * math.pi);
      canvas.drawRect(
        const Rect.fromLTWH(-3, -5.5, 6, 11),
        paint..color = colors[i % colors.length],
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.seconds != seconds || old.pieces != pieces;
}
