import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/badge_defs.dart';

/// The pictures on the medals: 12 x 12 squares each, `#` filled. The same ones as the
/// menu icons where there is one (trophy, coin, shield).
const Map<String, List<String>> badgeGlyphs = {
  'trophy': [
    '..########..',
    '.##########.',
    '###.####.###',
    '#..######..#',
    '###.####.###',
    '...######...',
    '....####....',
    '.....##.....',
    '.....##.....',
    '....####....',
    '...######...',
    '............'
  ],
  'coin': [
    '....####....',
    '..########..',
    '.##########.',
    '.####..####.',
    '####.##.####',
    '####.##.####',
    '####.##.####',
    '####.##.####',
    '.####..####.',
    '.##########.',
    '..########..',
    '....####....'
  ],
  'shield': [
    '............',
    '############',
    '############',
    '#####..#####',
    '#####..#####',
    '#####..#####',
    '#####..#####',
    '.##########.',
    '..########..',
    '...######...',
    '....####....',
    '.....##.....'
  ],
  'star': [
    '.....##.....',
    '.....##.....',
    '....####....',
    '############',
    '.##########.',
    '..########..',
    '..########..',
    '.#####.####.',
    '.####...###.',
    '.###.....##.',
    '.##.......#.',
    '............'
  ],
  'check': [
    '............',
    '..........##',
    '.........###',
    '........###.',
    '#......###..',
    '##....###...',
    '###..###....',
    '.######.....',
    '..####......',
    '...##.......',
    '............',
    '............'
  ],
  'up': [
    '.....##.....',
    '....####....',
    '...######...',
    '..########..',
    '.....##.....',
    '.....##.....',
    '.....##.....',
    '.....##.....',
    '.....##.....',
    '............',
    '############',
    '............'
  ],
  'cal': [
    '.#........#.',
    '############',
    '#..........#',
    '############',
    '#.##.##.##.#',
    '#.##.##.##.#',
    '#..........#',
    '#.##.##.##.#',
    '#.##.##.##.#',
    '#..........#',
    '############',
    '............'
  ],
  'heart': [
    '............',
    '.###....###.',
    '#####..#####',
    '############',
    '############',
    '############',
    '.##########.',
    '..########..',
    '...######...',
    '....####....',
    '.....##.....',
    '............'
  ],
  'urn': [
    '...######...',
    '....####....',
    '...######...',
    '..########..',
    '.##########.',
    '.##########.',
    '.##########.',
    '.##########.',
    '..########..',
    '...######...',
    '...######...',
    '..########..'
  ],
};

/// The era number, three squares wide and five tall.
const Map<int, List<String>> _digits = {
  1: ['.#.', '##.', '.#.', '.#.', '###'],
  2: ['###', '..#', '###', '#..', '###'],
  3: ['###', '..#', '###', '..#', '###'],
  4: ['#.#', '#.#', '###', '..#', '..#'],
  5: ['###', '#..', '###', '..#', '###'],
  6: ['###', '#..', '###', '#.#', '###'],
};

class _Palette {
  final Color outline, rim, edge, face, light, ink;
  const _Palette(
      this.outline, this.rim, this.edge, this.face, this.light, this.ink);
}

const _tanso = _Palette(Color(0xFF2E1608), Color(0xFFE3A56F), Color(0xFF8F5628),
    Color(0xFFB8763E), Color(0xFFF6D0A8), Color(0xFF2E1608));
const _pilak = _Palette(Color(0xFF2E1608), Color(0xFFF2F5F8), Color(0xFF8E9AA8),
    Color(0xFFB7C2CE), Color(0xFFFFFFFF), Color(0xFF2E1608));
const _ginto = _Palette(Color(0xFF2E1608), Color(0xFFFFE98A), Color(0xFFE0A412),
    Color(0xFFFFC531), Color(0xFFFFF8D6), Color(0xFF2E1608));
const _locked = _Palette(Color(0xFF1A1226), Color(0xFF3A2E52),
    Color(0xFF2A2040), Color(0xFF2B2140), Color(0xFF3A2E52), Color(0xFF54456F));

/// A badge's medal: a pixel-art disc in tin, silver or gold with a picture on it, and
/// a red ribbon under it for an [honor] badge. [metal] null draws it dark, as a
/// badge not earned yet. Drawn in code (20 x 22 squares), so it is sharp at any size.
class BadgeMedal extends StatelessWidget {
  /// A key of [badgeGlyphs], or `n1` to `n6` for an era number.
  final String glyph;
  final BadgeMetal? metal;
  final bool honor;
  final double width;

  const BadgeMedal({
    super.key,
    required this.glyph,
    required this.metal,
    this.honor = false,
    this.width = 44,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: width * 22 / 20,
        child: CustomPaint(
            painter: _MedalPainter(glyph, metal, honor && metal != null)),
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  final String glyph;
  final BadgeMetal? metal;
  final bool ribbon;
  _MedalPainter(this.glyph, this.metal, this.ribbon);

  _Palette get _palette => switch (metal) {
        BadgeMetal.tanso => _tanso,
        BadgeMetal.pilak => _pilak,
        BadgeMetal.ginto || BadgeMetal.era => _ginto,
        null => _locked,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 20;
    final paint = Paint()..isAntiAlias = false;
    void px(num x, num y, Color c, {double w = 1}) {
      // A hair over a square, so neighbours leave no seam.
      canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell * w + 0.5, cell * w + 0.5),
          paint..color = c);
    }

    final p = _palette;
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
        final d = math.sqrt(dx * dx + dy * dy);
        if (d > 9.7) continue;
        var c = d > 8.3
            ? p.outline
            : d > 6.9
                ? p.rim
                : d > 5.9
                    ? p.edge
                    : p.face;
        if (d > 6.9 && d <= 8.3 && x + y < 11) c = p.light;
        if (d <= 5.9 &&
            ((x == 6 && y == 4) || (x == 5 && y == 5) || (x == 4 && y == 6))) {
          c = p.light;
        }
        px(x, y, c);
      }
    }

    final number = RegExp(r'^n(\d)$').firstMatch(glyph);
    if (number != null) {
      final rows = _digits[int.parse(number.group(1)!)]!;
      for (var j = 0; j < rows.length; j++) {
        for (var i = 0; i < rows[j].length; i++) {
          if (rows[j][i] == '#') px(7 + i * 2, 5 + j * 2, p.ink, w: 2);
        }
      }
    } else {
      final rows = badgeGlyphs[glyph];
      if (rows == null) return;
      for (var j = 0; j < rows.length; j++) {
        for (var i = 0; i < rows[j].length; i++) {
          if (rows[j][i] == '#') px(4 + i, 4 + j, p.ink);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_MedalPainter old) =>
      old.glyph != glyph || old.metal != metal || old.ribbon != ribbon;
}
