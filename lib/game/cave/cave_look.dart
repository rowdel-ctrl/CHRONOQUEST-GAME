import 'dart:math';
import 'dart:ui';

/// The colours of one era's cave: the wall (top, middle, bottom), the rock (dark,
/// light) with its lit top edge, and the glow of the era's lights. The modern cave
/// has a second neon colour.
class CaveLook {
  final String id;
  final Color wallTop, wallMid, wallBottom, rock0, rock1, lip, glow, glow2;

  const CaveLook(
    this.id,
    this.wallTop,
    this.wallMid,
    this.wallBottom,
    this.rock0,
    this.rock1,
    this.lip,
    this.glow, [
    Color? glow2,
  ]) : glow2 = glow2 ?? glow;

  /// The names the first version of the cave used.
  Color get earthEdge => lip;
  Color get earth => rock1;

  static const Map<String, CaveLook> byEra = {
    'pre-colonial': CaveLook(
        'pre',
        Color(0xFF06100C),
        Color(0xFF0F2A1F),
        Color(0xFF1A4A37),
        Color(0xFF34271A),
        Color(0xFF5B4729),
        Color(0xFF76603A),
        Color(0xFF6CF0B8),
        Color(0xFFC8FF9A)),
    'spanish': CaveLook(
        'spa',
        Color(0xFF0D1016),
        Color(0xFF1B212D),
        Color(0xFF2C3445),
        Color(0xFF3A3D47),
        Color(0xFF5A5E6B),
        Color(0xFF7A7F8E),
        Color(0xFFFFA24A),
        Color(0xFFFFE28A)),
    'nationalism': CaveLook(
        'nat',
        Color(0xFF160A0A),
        Color(0xFF2E1514),
        Color(0xFF4A2420),
        Color(0xFF4A2E18),
        Color(0xFF6D4525),
        Color(0xFF8A5A30),
        Color(0xFFFFD27A),
        Color(0xFFFFF3C0)),
    'american': CaveLook(
        'ame',
        Color(0xFF150F08),
        Color(0xFF2E2012),
        Color(0xFF4A3520),
        Color(0xFF4B3720),
        Color(0xFF7A5A33),
        Color(0xFFA07F48),
        Color(0xFFFFF0B0),
        Color(0xFFFFD24A)),
    'ww2': CaveLook(
        'ww2',
        Color(0xFF090E10),
        Color(0xFF16222A),
        Color(0xFF22343C),
        Color(0xFF2C3430),
        Color(0xFF4B5A52),
        Color(0xFF6A7A68),
        Color(0xFF9BD0FF),
        Color(0xFFD6ECFF)),
    'modern': CaveLook(
        'mod',
        Color(0xFF060816),
        Color(0xFF10163A),
        Color(0xFF1C2658),
        Color(0xFF262B45),
        Color(0xFF3E4670),
        Color(0xFF4C5584),
        Color(0xFF46E0FF),
        Color(0xFFFF4FD8)),
  };

  static CaveLook of(String eraId) => byEra[eraId] ?? byEra['spanish']!;
}

/// A small steady "random" number for a whole or fractional [i]: the same input
/// always gives the same answer, from 0 up to (not including) 1.
double caveRnd(num i) {
  final s = sin(i * 127.1 + 3.7) * 43758.5453;
  return s - s.floorToDouble();
}
