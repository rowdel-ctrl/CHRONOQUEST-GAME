import 'package:flutter/material.dart';

import '../core/constants.dart';

/// A small gatehouse with a padlock on it: the icon for "the end gate".
///
/// [unlocked] shows it ready (green padlock, shackle open); otherwise the
/// padlock is gold and shut. Drawn in code from the same pieces as the gate in
/// the level (stone towers, barred arched door, padlock), so what the student
/// sees in the corner is the thing they are walking towards.
class GateIcon extends StatelessWidget {
  final double size;
  final bool unlocked;

  const GateIcon({super.key, this.size = 20, this.unlocked = true});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _GatePainter(unlocked: unlocked)),
      ),
    );
  }
}

class _GatePainter extends CustomPainter {
  final bool unlocked;
  const _GatePainter({required this.unlocked});

  static const Color _stone = Color(0xFFB9B5C7);
  static const Color _stoneShade = Color(0xFF8E8AA0);
  static const Color _wood = Color(0xFF4A2E18);
  static const Color _iron = Color(0xFF9096A3);
  static const Color _gold = Color(0xFFFFC531);
  static const Color _steel = Color(0xFFE6E6EE);

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 24 x 24 grid and scaled, so every size looks the same.
    canvas.scale(size.width / 24, size.height / 24);

    Paint fill(Color c) => Paint()..color = c;
    Paint line(Color c, double width) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final edge = line(AppColors.primaryDark, 1.3);

    // Towers and wall as one shape (battlements fused to the block), so the
    // outline runs round the whole silhouette with no seam between them.
    var gate = Path()
      ..addRRect(RRect.fromLTRBR(1.5, 6, 18.5, 22.5, const Radius.circular(1.2)));
    for (final x in const [1.5, 7.75, 14.0]) {
      gate = Path.combine(
        PathOperation.union,
        gate,
        Path()..addRect(Rect.fromLTRB(x, 2.5, x + 4.5, 7)),
      );
    }
    canvas.drawPath(gate, fill(_stone));
    // A darker plinth along the foot of the wall.
    canvas.drawRect(const Rect.fromLTRB(2.1, 20.2, 17.9, 21.9), fill(_stoneShade));
    canvas.drawPath(gate, edge);

    // The arched door with its bars.
    final door = Path()
      ..moveTo(5.5, 22.5)
      ..lineTo(5.5, 14)
      ..quadraticBezierTo(10, 6.5, 14.5, 14)
      ..lineTo(14.5, 22.5)
      ..close();
    canvas.drawPath(door, fill(_wood));
    final bar = line(_iron, 1);
    for (final x in const [8.0, 10.0, 12.0]) {
      canvas.drawLine(Offset(x, 11.4), Offset(x, 22), bar);
    }
    canvas.drawPath(door, edge);

    // The padlock, bottom right, over the corner of the gate.
    const lock = Rect.fromLTRB(13.4, 14.2, 23.2, 23);
    final lockBody = RRect.fromRectAndRadius(lock, const Radius.circular(2.2));
    final shackle = Path()
      ..moveTo(15.8, 14.2)
      ..lineTo(15.8, 11.4)
      ..arcToPoint(
        const Offset(20.8, 11.4),
        radius: const Radius.circular(2.5),
        clockwise: true,
      );
    if (!unlocked) shackle.lineTo(20.8, 14.2);
    // A dark edge first so the shackle reads against the stone and the chip.
    canvas.drawPath(shackle, line(AppColors.primaryDark, 3.3));
    canvas.drawPath(shackle, line(_steel, 1.7));
    canvas.drawRRect(lockBody, fill(unlocked ? AppColors.success : _gold));
    canvas.drawRRect(lockBody, line(AppColors.primaryDark, 1.4));
    final keyhole = fill(AppColors.primaryDark);
    canvas.drawCircle(const Offset(18.3, 18.0), 1.3, keyhole);
    canvas.drawRect(const Rect.fromLTWH(17.7, 18.4, 1.2, 2.5), keyhole);
  }

  @override
  bool shouldRepaint(_GatePainter old) => old.unlocked != unlocked;
}
