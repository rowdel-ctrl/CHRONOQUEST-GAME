import 'package:flutter/material.dart';

/// The menu icons. Every one is a 12 x 12 grid of squares in a single colour,
/// drawn here instead of shipped as images, so it stays sharp at any size and
/// takes its colour from where it is used. They match the game's pixel-art
/// hearts, stars and locks, which the smooth Material icons did not.
enum PixelGlyph {
  back,
  profile,
  gear,
  trophy,
  book,
  move,
  speaker,
  door,
  coin,
  shield,
  chevron,
  note,
  speakerLow,
  speakerOff,
  cart,
}

/// One string per row, `#` for a filled square. Kept as text so a glyph can be
/// read and edited as the picture it is.
const Map<PixelGlyph, List<String>> pixelGlyphRows = {
  PixelGlyph.back: [
    '............',
    '....#.......',
    '...##.......',
    '..###.......',
    '.###########',
    '############',
    '############',
    '.###########',
    '..###.......',
    '...##.......',
    '....#.......',
    '............',
  ],
  PixelGlyph.profile: [
    '............',
    '....####....',
    '...######...',
    '...######...',
    '...######...',
    '....####....',
    '.....##.....',
    '..########..',
    '.##########.',
    '.##########.',
    '.##########.',
    '............',
  ],
  PixelGlyph.gear: [
    '....####....',
    '.##.####.##.',
    '.##########.',
    '..###..###..',
    '####....####',
    '####....####',
    '####....####',
    '####....####',
    '..###..###..',
    '.##########.',
    '.##.####.##.',
    '....####....',
  ],
  PixelGlyph.trophy: [
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
    '............',
  ],
  PixelGlyph.book: [
    '............',
    '............',
    '..###..###..',
    '.####..####.',
    '.#.##..##.#.',
    '.####..####.',
    '.#.##..##.#.',
    '.####..####.',
    '############',
    '.##########.',
    '............',
    '............',
  ],
  PixelGlyph.move: [
    '.....##.....',
    '....####....',
    '.....##.....',
    '.#...##...#.',
    '.##..##..##.',
    '############',
    '############',
    '.##..##..##.',
    '.#...##...#.',
    '.....##.....',
    '....####....',
    '.....##.....',
  ],
  PixelGlyph.speaker: [
    '............',
    '..........#.',
    '....#.....#.',
    '...##..#..#.',
    '#####..#..#.',
    '#####..#..#.',
    '#####..#..#.',
    '#####..#..#.',
    '...##..#..#.',
    '....#.....#.',
    '............',
    '............',
  ],
  PixelGlyph.door: [
    '............',
    '#######.....',
    '#.....#.....',
    '#.....#..#..',
    '#.....#..##.',
    '#.....######',
    '#.....######',
    '#.....#..##.',
    '#.....#..#..',
    '#.....#.....',
    '#######.....',
    '............',
  ],
  PixelGlyph.coin: [
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
    '....####....',
  ],
  PixelGlyph.shield: [
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
    '.....##.....',
  ],
  PixelGlyph.chevron: [
    '............',
    '...##.......',
    '...###......',
    '....###.....',
    '.....###....',
    '......###...',
    '......###...',
    '.....###....',
    '....###.....',
    '...###......',
    '...##.......',
    '............',
  ],
  PixelGlyph.note: [
    '............',
    '...########.',
    '...########.',
    '...##....##.',
    '...##....##.',
    '...##....##.',
    '...##....##.',
    '.####..####.',
    '#####.#####.',
    '#####.#####.',
    '.###...###..',
    '............',
  ],
  PixelGlyph.speakerLow: [
    '............',
    '............',
    '.......#....',
    '......##....',
    '...#####....',
    '...#####....',
    '...#####....',
    '...#####....',
    '......##....',
    '.......#....',
    '............',
    '............',
  ],
  PixelGlyph.speakerOff: [
    '............',
    '............',
    '....#.......',
    '...##..#...#',
    '#####...#.#.',
    '#####....#..',
    '#####...#.#.',
    '#####..#...#',
    '...##.......',
    '....#.......',
    '............',
    '............',
  ],
  PixelGlyph.cart: [
    '............',
    '##..........',
    '.#..........',
    '.#.########.',
    '.#.########.',
    '.#..######..',
    '.#..######..',
    '.#...####...',
    '.##########.',
    '............',
    '..##....##..',
    '..##....##..',
  ],
};

/// A [PixelGlyph] drawn at [size] logical pixels square in [color].
class PixelIcon extends StatelessWidget {
  final PixelGlyph glyph;
  final double size;
  final Color color;

  const PixelIcon(
    this.glyph, {
    super.key,
    this.size = 24,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _PixelPainter(glyph, color)),
      ),
    );
  }
}

class _PixelPainter extends CustomPainter {
  final PixelGlyph glyph;
  final Color color;
  _PixelPainter(this.glyph, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 12;
    // One path for the whole glyph, so squares that touch leave no seam.
    final path = Path();
    final rows = pixelGlyphRows[glyph]!;
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        if (rows[y][x] == '#') {
          path.addRect(Rect.fromLTWH(x * cell, y * cell, cell, cell));
        }
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(_PixelPainter old) =>
      old.glyph != glyph || old.color != color;
}
