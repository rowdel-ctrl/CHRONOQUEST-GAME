import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

import '../core/constants.dart';

/// Whether things may move: not when the phone is set to remove animations.
bool motionAllowed(BuildContext context) =>
    !MediaQuery.disableAnimationsOf(context);

/// The menu backdrop: a night of star lanterns (parols) swaying on strings over
/// kubo roofs, with a wooden deck along the bottom. The sky and one lantern take
/// [color]. It paints behind the content and takes no taps.
///
/// It is drawn on a small grid (about 144 units high) and scaled up, so its edges
/// stay chunky like the game's pixel art. With [animate] false (or the phone's
/// "remove animations" on) it is one still picture and schedules no frames.
class LivingBackdrop extends StatefulWidget {
  final Color color;

  /// null: follow the phone's setting.
  final bool? animate;

  const LivingBackdrop({
    super.key,
    this.color = AppColors.accent,
    this.animate,
  });

  @override
  State<LivingBackdrop> createState() => _LivingBackdropState();
}

class _LivingBackdropState extends State<LivingBackdrop>
    with SingleTickerProviderStateMixin {
  /// The moment shown when nothing moves: lanterns hanging a little off true.
  static const double stillAt = 3;

  /// 30 frames a second is plenty for a slow sway, and easier on the battery.
  static const Duration _frame = Duration(milliseconds: 33);

  final ValueNotifier<double> _seconds = ValueNotifier<double>(stillAt);
  Ticker? _ticker;
  Duration _lastDraw = Duration.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = widget.animate ?? motionAllowed(context);
    if (on && _ticker == null) {
      _ticker = createTicker(_tick)..start();
    } else if (!on && _ticker != null) {
      _ticker!.dispose();
      _ticker = null;
      _seconds.value = stillAt;
    }
  }

  void _tick(Duration elapsed) {
    if (elapsed - _lastDraw < _frame) return;
    _lastDraw = elapsed;
    _seconds.value = stillAt + elapsed.inMicroseconds / 1e6;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _ParolPainter(seconds: _seconds, tint: widget.color),
          ),
        ),
      ),
    );
  }
}

class _ParolPainter extends CustomPainter {
  final ValueListenable<double> seconds;
  final Color tint;

  _ParolPainter({required this.seconds, required this.tint})
      : super(repaint: seconds);

  /// Height of the wooden deck, in drawing units.
  static const double _deck = 29;

  static const Color _gold = Color(0xFFFFC531);
  static const Color _red = Color(0xFFE8433A);
  static const Color _blue = Color(0xFF3D8FD1);
  static const Color _green = Color(0xFF43A83E);

  /// A repeatable number in 0..1 for index [i], so the scene never changes shape.
  static double _rnd(num i) {
    final x = math.sin(i * 127.1 + 311.7) * 43758.5453;
    return x - x.floorToDouble();
  }

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // Drawing units: 144 high on a landscape phone, never narrower than 200.
    final s = math.min(size.height / 144, size.width / 200);
    final w = size.width / s;
    final h = size.height / s;
    final t = seconds.value;
    final gy = h - _deck;

    canvas.save();
    canvas.scale(s, s);
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));

    final crisp = Paint()..isAntiAlias = false;

    // Sky, in bands.
    const top = Color(0xFF0B0824);
    final low = _mix(const Color(0xFF1D1552), tint, 0.3);
    for (double y = 0; y < gy; y += 2) {
      canvas.drawRect(
          Rect.fromLTWH(0, y, w, 2.6), crisp..color = _mix(top, low, y / gy));
    }

    // Stars.
    final stars = (50 * w / 256).round();
    for (var i = 0; i < stars; i++) {
      final tw = 0.5 + 0.5 * math.sin(t * 1.4 + i * 2.3);
      canvas.drawRect(
        Rect.fromLTWH((_rnd(i + 3) * w).floorToDouble(),
            (_rnd(i + 55) * gy * 0.6).floorToDouble(), 1, 1),
        crisp
          ..color = const Color(0xFFFFF4D2).withValues(alpha: 0.15 + 0.5 * tw),
      );
    }

    _houses(canvas, w, gy, t, crisp);
    _strings(canvas, w);
    _deckAndLanterns(canvas, w, h, gy, t, crisp);
    canvas.restore();
  }

  void _houses(Canvas canvas, double w, double gy, double t, Paint crisp) {
    final n = math.max(3, (w / 34).round());
    final slot = w / n;
    final roof = Paint()..color = const Color(0xFF0A0720);
    for (var i = 0; i < n; i++) {
      final hw = 22 + _rnd(i) * 10;
      final bh = 12 + _rnd(i + 2) * 8;
      final x = i * slot + _rnd(i + 20) * (slot - hw).clamp(0, 12);
      final base = gy - 6;
      canvas.drawRect(Rect.fromLTWH(x, base - bh, hw, bh + 6), roof);
      canvas.drawPath(
        Path()
          ..moveTo(x - 4, base - bh)
          ..lineTo(x + hw / 2, base - bh - 14)
          ..lineTo(x + hw + 4, base - bh)
          ..close(),
        roof,
      );
      if (_rnd(i + 8) > 0.35) {
        final flicker = 0.7 + 0.3 * math.sin(t * 3 + i * 5);
        canvas.drawRect(Rect.fromLTWH(x + 5, base - bh + 4, 4, 5),
            crisp..color = _gold.withValues(alpha: 0.8 * flicker));
      }
    }
  }

  /// Where a string sags to at [x] (drawing units), for a string hung at [y0].
  static double _sag(double x, double w, double y0) =>
      y0 + math.sin(x / w * math.pi) * 14;

  void _strings(Canvas canvas, double w) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.28);
    for (final y0 in const [6.0, 22.0]) {
      final path = Path()..moveTo(0, _sag(0, w, y0));
      for (double x = 4; x <= w; x += 4) {
        path.lineTo(x, _sag(x, w, y0));
      }
      canvas.drawPath(path, line);
    }
  }

  void _deckAndLanterns(
      Canvas canvas, double w, double h, double gy, double t, Paint crisp) {
    // The wooden deck.
    final wood = _mix(const Color(0xFF2A1A30), tint, 0.1);
    canvas.drawRect(Rect.fromLTWH(0, gy, w, h - gy), crisp..color = wood);
    final seam = _mix(wood, Colors.black, 0.3);
    for (double y = gy + 6; y < h; y += 6) {
      canvas.drawRect(Rect.fromLTWH(0, y, w, 1), crisp..color = seam);
    }
    var row = 0;
    for (double y = gy; y < h; y += 6, row++) {
      for (double x = (row % 2) * 20 + 8; x < w; x += 40) {
        canvas.drawRect(Rect.fromLTWH(x, y, 1, 6), crisp..color = seam);
      }
    }
    canvas.drawRect(Rect.fromLTWH(0, gy, w, 1),
        crisp..color = _mix(tint, const Color(0xFFFFD99A), 0.5));

    // The lanterns: evenly spread, each its own size and sway.
    final colors = [_gold, tint, _red, _blue, _green, Colors.white];
    final n = (w / 36).round().clamp(3, 10);
    for (var i = 0; i < n; i++) {
      final x = (i + 0.5) * w / n;
      final y0 = i.isEven ? 6.0 : 22.0;
      final size = 7 + _rnd(i + 11) * 4;
      final col = colors[i % colors.length];
      // A soft pool of the lantern's light on the deck.
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, gy, w, h - gy));
      final pool = Rect.fromCircle(center: Offset(x, gy + 8), radius: 26);
      canvas.drawRect(
        pool,
        Paint()
          ..shader = RadialGradient(colors: [
            col.withValues(alpha: 0.22),
            col.withValues(alpha: 0),
          ]).createShader(pool),
      );
      canvas.restore();
      _lantern(canvas, x, _sag(x, w, y0), size, col, t, i);
    }
  }

  void _lantern(Canvas canvas, double x, double y, double size, Color col,
      double t, int i) {
    final angle = math.sin(t * 1.1 + i * 1.7) * 0.07;
    final pulse = 0.75 + 0.25 * math.sin(t * 2.4 + i);
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);
    canvas.drawLine(
      Offset.zero,
      const Offset(0, 8),
      Paint()
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.35),
    );
    final cy = 8 + size;

    // Glow, added to what is behind it.
    final glow = Rect.fromCircle(center: Offset(0, cy), radius: size * 3.2);
    canvas.drawRect(
      glow,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(colors: [
          col.withValues(alpha: 0.42 * pulse),
          col.withValues(alpha: 0),
        ]).createShader(glow),
    );

    Path star(double scale) {
      final p = Path();
      for (var k = 0; k < 16; k++) {
        final a = k * math.pi / 8 - math.pi / 2;
        final r = (k.isOdd ? size * 0.44 : size) * scale;
        final o = Offset(math.cos(a) * r, cy + math.sin(a) * r);
        k == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      }
      return p..close();
    }

    canvas.drawPath(star(1), Paint()..color = _mix(col, Colors.black, 0.15));
    canvas.drawPath(
        star(0.55),
        Paint()
          ..color = _mix(col, Colors.white, 0.55).withValues(alpha: pulse));

    // Two streamers under the star.
    final tail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = col.withValues(alpha: 0.9);
    for (final dx in const [-3.0, 3.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(dx * 0.4, cy + size * 0.8)
          ..quadraticBezierTo(dx + math.sin(t * 2 + i) * 2, cy + size * 1.5,
              dx * 1.6, cy + size * 2.1),
        tail,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ParolPainter old) =>
      old.tint != tint || old.seconds != seconds;
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
