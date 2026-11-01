import 'package:flutter/material.dart';

enum ActionDiscKind { jump, attack }

/// The picture on a round action button: two chevrons up on gold for Jump, a sword
/// on red for Attack, with a light inner ring and a dark rim, in a square of side
/// [d] at the origin. The level's buttons (`game_input.dart`) and the how-to-play
/// pictures both draw it from here, so they always match.
void paintActionDisc(Canvas canvas, double d, ActionDiscKind kind,
    {double alpha = 1}) {
  const ink = Color(0xFF2E1608);
  const cream = Color(0xFFFFE9D0);
  final r = d / 2, centre = Offset(r, r);
  final jump = kind == ActionDiscKind.jump;
  final fill = jump ? const Color(0xFFFFC531) : const Color(0xFFE8433A);
  final mark = jump ? ink : cream;

  canvas.drawCircle(centre, r, Paint()..color = fill.withValues(alpha: alpha));
  // A lighter top edge and a dark rim, like the other round buttons.
  canvas.drawCircle(
    centre,
    r - 11 * d / 108,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * d / 108
      ..color = Colors.white.withValues(alpha: 0.35 * alpha),
  );
  canvas.drawCircle(
    centre,
    r - 3 * d / 108,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 * d / 108
      ..color = ink.withValues(alpha: alpha),
  );

  // The picture, drawn on a 24 x 24 grid and scaled to about half the button.
  final s = d * 0.5 / 24;
  canvas.save();
  canvas.translate(r - 12 * s, r - 12 * s);
  canvas.scale(s);
  final path = Path();
  if (jump) {
    path
      ..moveTo(6, 13)
      ..lineTo(12, 7)
      ..lineTo(18, 13)
      ..moveTo(6, 19)
      ..lineTo(12, 13)
      ..lineTo(18, 19);
  } else {
    path
      ..moveTo(19, 5)
      ..lineTo(9, 15)
      ..moveTo(19, 5)
      ..lineTo(15, 5)
      ..moveTo(19, 5)
      ..lineTo(19, 9)
      ..moveTo(6.5, 12.5)
      ..lineTo(11.5, 17.5)
      ..moveTo(5, 19)
      ..lineTo(7.5, 16.5);
  }
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = mark,
  );
  canvas.restore();
}

/// The same button as a widget, for screens outside the level.
class ActionDisc extends StatelessWidget {
  final ActionDiscKind kind;
  final double size;
  final double alpha;

  const ActionDisc(
      {super.key, required this.kind, this.size = 40, this.alpha = 0.86});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _DiscPainter(kind, alpha)),
      ),
    );
  }
}

class _DiscPainter extends CustomPainter {
  final ActionDiscKind kind;
  final double alpha;
  const _DiscPainter(this.kind, this.alpha);

  @override
  void paint(Canvas canvas, Size size) =>
      paintActionDisc(canvas, size.width, kind, alpha: alpha);

  @override
  bool shouldRepaint(_DiscPainter old) =>
      old.kind != kind || old.alpha != alpha;
}
