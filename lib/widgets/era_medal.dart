import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The medal for beating an era's boss: a pixel-art gold disc with the era's number
/// on it and a red ribbon beneath. Drawn in code (20 x 22 squares), so it is sharp at
/// any size and needs no picture.
class EraMedal extends StatelessWidget {
  /// 1 to 6: which era.
  final int number;
  final double width;

  /// The red ribbon under the disc. Without it the medal is square.
  final bool ribbon;

  const EraMedal(
      {super.key, required this.number, this.width = 120, this.ribbon = true});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Medalya ng Panahon $number',
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: width * (ribbon ? 22 : 20) / 20,
          child: CustomPaint(painter: _MedalPainter(number, ribbon)),
        ),
      ),
    );
  }
}

const Map<int, List<String>> _digits = {
  1: ['.#.', '##.', '.#.', '.#.', '###'],
  2: ['###', '..#', '###', '#..', '###'],
  3: ['###', '..#', '###', '..#', '###'],
  4: ['#.#', '#.#', '###', '..#', '..#'],
  5: ['###', '#..', '###', '..#', '###'],
  6: ['###', '#..', '###', '#.#', '###'],
};

class _MedalPainter extends CustomPainter {
  final int number;
  final bool ribbon;
  _MedalPainter(this.number, this.ribbon);

  static const _outline = Color(0xFF2E1608);
  static const _rim = Color(0xFFFFE98A);
  static const _edge = Color(0xFFE0A412);
  static const _face = Color(0xFFFFC531);
  static const _light = Color(0xFFFFF8D6);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 20;
    final paint = Paint()..isAntiAlias = false;
    void px(int x, int y, Color c) {
      // A hair over a square, so neighbours leave no seam.
      canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5),
          paint..color = c);
    }

    if (ribbon) {
      for (var y = 14; y < 22; y++) {
        for (final x0 in const [4, 11]) {
          for (var x = x0; x < x0 + 5; x++) {
            // The two ends are cut in a V.
            if (y >= 20 && x == x0 + 2) continue;
            px(x, y,
                x == x0 ? const Color(0xFFB52E27) : const Color(0xFFE8433A));
          }
        }
      }
    }

    for (var y = 0; y < 20; y++) {
      for (var x = 0; x < 20; x++) {
        final dx = x - 9.5, dy = y - 9.5;
        final d = (dx * dx + dy * dy);
        if (d > 9.7 * 9.7) continue;
        final r = math.sqrt(d);
        var c = r > 8.3
            ? _outline
            : r > 6.9
                ? _rim
                : r > 5.9
                    ? _edge
                    : _face;
        if (r > 6.9 && r <= 8.3 && x + y < 11) c = _light;
        px(x, y, c);
      }
    }

    final digit = _digits[number.clamp(1, 6)]!;
    for (var j = 0; j < digit.length; j++) {
      for (var i = 0; i < digit[j].length; i++) {
        if (digit[j][i] != '#') continue;
        for (var a = 0; a < 2; a++) {
          for (var b = 0; b < 2; b++) {
            px(7 + i * 2 + a, 5 + j * 2 + b, _outline);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_MedalPainter old) =>
      old.number != number || old.ribbon != ribbon;
}
