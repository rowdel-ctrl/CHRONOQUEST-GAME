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
  static const Color _iron = Color(0xFF9096A3);
  static const Color _gold = Color(0xFFFFC531);
  static const Color _light = Color(0xFFFFE9A0);
  static const Color _wax = Color(0xFFD8584F);
  static const Color _flame = Color(0xFFFF8A2A);

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

    // The stepped stone front.
    final front = Path()
      ..moveTo(2, 22.5)
      ..lineTo(2, 12)
      ..lineTo(5, 12)
      ..lineTo(5, 8.5)
      ..lineTo(8, 8.5)
      ..lineTo(8, 4)
      ..lineTo(16, 4)
      ..lineTo(16, 8.5)
      ..lineTo(19, 8.5)
      ..lineTo(19, 12)
      ..lineTo(22, 12)
      ..lineTo(22, 22.5)
      ..close();
    canvas.drawPath(front, fill(_stone));
    // A darker plinth along the foot.
    canvas.drawRect(
        const Rect.fromLTRB(2.6, 20.6, 21.4, 22), fill(_stoneShade));
    canvas.drawPath(front, edge);

    // The arched doorway: dark with a grille, or full of light once open.
    final door = Path()
      ..moveTo(8.2, 22.5)
      ..lineTo(8.2, 14.5)
      ..arcToPoint(const Offset(15.8, 14.5), radius: const Radius.circular(3.8))
      ..lineTo(15.8, 22.5)
      ..close();
    canvas.drawPath(door, fill(unlocked ? _light : const Color(0xFF14100C)));
    if (unlocked) {
      // The grille is up: only its tips hang from the arch.
      for (final x in const [9.6, 12.0, 14.4]) {
        canvas.drawLine(Offset(x, 11.4), Offset(x, 13.6), line(_iron, 0.9));
      }
    } else {
      for (final x in const [9.6, 12.0, 14.4]) {
        canvas.drawLine(Offset(x, 11.4), Offset(x, 22), line(_iron, 0.9));
      }
      canvas.drawLine(
          const Offset(8.4, 17.2), const Offset(15.6, 17.2), line(_iron, 0.9));
    }
    canvas.drawPath(door, edge);

    // The wax seal on the keystone.
    canvas.drawCircle(
        const Offset(12, 7.3), 2.3, fill(unlocked ? _gold : _wax));
    canvas.drawCircle(
        const Offset(12, 7.3), 2.3, line(AppColors.primaryDark, 1));

    // A torch on each pillar.
    for (final x in const [4.6, 19.4]) {
      canvas.drawCircle(Offset(x, 15.8), 1.25, fill(_flame));
      canvas.drawLine(
          Offset(x, 17), Offset(x, 19.4), line(AppColors.primaryDark, 1.1));
    }
  }

  @override
  bool shouldRepaint(_GatePainter old) => old.unlocked != unlocked;
}
