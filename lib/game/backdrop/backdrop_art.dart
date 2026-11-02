import 'dart:math' as math;
import 'dart:ui' as ui;

import 'era_look.dart';
import 'pixel_art.dart';

/// One tile of scenery, in art pixels. The game draws it scaled up to the screen
/// height (720 / 180 = 4 screen units per art pixel), and it repeats sideways with
/// no seam, so a level of any length has scenery.
const int kTileW = 320;
const int kTileH = 180;

/// Art pixel row of the ground line (the game's ground sits 60 screen units from the
/// bottom: 660 / 4).
const int kGroundRow = 165;

/// The five pictures that make up one era's backdrop, far to near.
class EraArt {
  EraArt({
    required this.hills,
    required this.farTrees,
    required this.scenery,
    required this.midTrees,
    required this.nearTrees,
  });

  final ui.Image hills;
  final ui.Image farTrees;
  final ui.Image scenery;
  final ui.Image midTrees;
  final ui.Image nearTrees;

  /// In drawing order, far to near.
  List<ui.Image> get layers => [hills, farTrees, scenery, midTrees, nearTrees];

  void dispose() {
    for (final i in layers) {
      i.dispose();
    }
  }
}

/// Draws all five layers for [look]. The same look always gives the same pictures.
Future<EraArt> buildEraArt(EraLook look) async {
  final hills = await hillsPixels(look).toImage();
  final far = await treePixels(look, look.far, 11, 5, 60, 90, 4, 6, 12, 17)
      .toImage();
  final scenery = await sceneryPixels(look).toImage();
  final mid = await treePixels(look, look.mid, 31, 3, 120, 160, 8, 11, 17, 23)
      .toImage();
  final near = await treePixels(look, look.near, 51, 2, 185, 215, 17, 24, 28, 34)
      .toImage();
  return EraArt(
      hills: hills,
      farTrees: far,
      scenery: scenery,
      midTrees: mid,
      nearTrees: near);
}

const List<int> _wraps = [-kTileW, 0, kTileW];

/// Two overlapping ridges of hills, hazed by distance.
PixelBuf hillsPixels(EraLook look) {
  final b = PixelBuf(kTileW, kTileH);
  void ridge(double base, double a1, int k1, double a2, int k2, double ph,
      int color) {
    for (var x = 0; x < kTileW; x++) {
      final t = x / kTileW * math.pi * 2;
      final y = (base + math.sin(t * k1 + ph) * a1 + math.sin(t * k2 + ph * 2) * a2)
          .round();
      b.rect(x, y, 1, kTileH - y, color);
    }
  }

  ridge(96, 14, 2, 6, 5, .4, mixColor(look.hillFar, look.fog, .35));
  ridge(116, 11, 3, 5, 7, 1.7, mixColor(look.hillNear, look.fog, .2));
  return b;
}

/// One row of trees: trunks standing on the bottom of the tile, a leafy crown
/// (dark underside, middle, light top) and a few hanging vines; bare branches
/// instead for a burnt era. Hazed by distance.
PixelBuf treePixels(EraLook look, TreeStyle s, int seed, int count, double hMin,
    double hMax, double wMin, double wMax, double rMin, double rMax) {
  final b = PixelBuf(kTileW, kTileH);
  final r = Rand(seed);
  final light = mixColor(s.trunk, 0xFFFFFFFF, .12);
  for (var i = 0; i < count; i++) {
    final x = (i + r.range(0, .8)) / count * kTileW;
    final h = r.range(hMin, hMax);
    final w = r.range(wMin, wMax).round();
    final rad = r.range(rMin, rMax);
    final lean = r.range(-5, 5);
    final blobs = [
      for (var k = 0; k < 7; k++)
        [r.range(-1.1, 1.1) * rad, r.range(-.6, .35) * rad, rad * r.range(.5, .95)]
    ];
    final vines = [
      for (var v = 0; v < 4; v++) [r.range(-1, 1) * rad, 6 + r.range(0, 18)]
    ];
    final lens = [for (var k = 0; k < 3; k++) 14 + r.range(0, 14)];
    for (final o in _wraps) {
      final bx = x + o, topY = kTileH - h, tx = bx + lean;
      for (var y = 0; y < h; y++) {
        final xx = bx + lean * (y / h);
        final row = kTileH - 1 - y;
        b.rect((xx - w / 2).round(), row, w, 1, s.trunk);
        b.put((xx - w / 2).round(), row, light);
      }
      if (s.dead) {
        for (var k = 0; k < 3; k++) {
          final dir = k.isOdd ? 1 : -1, by = topY + 6 + k * 9;
          for (var u = 0; u < lens[k]; u++) {
            b.rect((tx + dir * u).round(), (by - u * .55).round(), 2, 2, s.trunk);
          }
        }
      } else {
        const shift = [
          [2.0, 3.0, 0.0],
          [0.0, 0.0, 0.0],
          [-2.0, -3.0, -2.0]
        ];
        for (var pass = 0; pass < 3; pass++) {
          for (final bl in blobs) {
            b.disc(tx + bl[0] + shift[pass][0], topY + bl[1] + shift[pass][1],
                math.max(2.0, (bl[2] + shift[pass][2]).roundToDouble()),
                s.leaf[pass]);
          }
        }
        for (final v in vines) {
          final vx = (tx + v[0]).round(), vl = v[1].round();
          b.rect(vx, (topY + 4).round(), 1, vl, s.leaf[0]);
          b.rect(vx, (topY + 4 + vl).round(), 2, 2, s.leaf[1]);
        }
      }
    }
  }
  b.haze(look.fog, s.haze);
  return b;
}

const int _lit = 0xFFFFC86A;

/// The buildings, huts or ruins that stand behind the trees of this era.
PixelBuf sceneryPixels(EraLook look) {
  final b = PixelBuf(kTileW, kTileH);
  final col = look.silhouette;
  const by = 152;
  final r = Rand(21 + look.scenery.index);

  void palm(double x, int h) {
    for (var y = 0; y < h; y++) {
      b.rect((x + math.sin(y / h * 1.3) * 8).round(), by - y, 3, 1, col);
    }
    final tx = x + math.sin(1.3) * 8, ty = (by - h).toDouble();
    for (var a = 0; a < 7; a++) {
      final ang = -0.2 + a * 0.55 + math.pi * 1.05;
      for (var u = 0.0; u <= 1; u += .06) {
        b.rect((tx + math.cos(ang) * u * 24).round(),
            (ty + math.sin(ang) * u * 14 + u * u * 18 + 2).round(), 2, 2, col);
      }
    }
  }

  void hut(int x) {
    for (final dx in [-16, 14, -1]) {
      b.rect(x + dx, by - 22, 2, 22, col);
    }
    b.rect(x - 22, by - 25, 46, 3, col);
    b.rect(x - 16, by - 44, 34, 19, col);
    b.tri(x + 1, by - 78, by - 44, 30, col);
    b.rect(x - 2, by - 38, 7, 12, _lit);
  }

  void church(int x) {
    b.rect(x - 38, by - 54, 76, 54, col);
    b.tri(x, by - 80, by - 54, 38, col);
    b.rect(x + 44, by - 108, 24, 108, col);
    b.disc(x + 56, (by - 108).toDouble(), 12, col);
    b.rect(x + 55, by - 134, 2, 16, col);
    b.rect(x + 50, by - 129, 12, 2, col);
    b.rect(x - 7, by - 32, 14, 32, _lit);
    b.rect(x - 26, by - 42, 7, 12, _lit);
    b.rect(x + 19, by - 42, 7, 12, _lit);
    b.rect(x + 53, by - 94, 7, 14, _lit);
  }

  void arcade(int x, int len) {
    b.rect(x, by - 40, len, 40, col);
    for (var cx = x + 16; cx < x + len - 10; cx += 34) {
      b.clearEll(cx.toDouble(), by - 24, 11, 11);
      b.clearRect(cx - 11, by - 24, 22, 24);
    }
  }

  void bahay(int x) {
    b.rect(x - 28, by - 20, 56, 20, col);
    b.rect(x - 31, by - 44, 62, 24, col);
    b.tri(x, by - 66, by - 44, 38, col);
    for (final wx in [-23, -7, 9]) {
      b.rect(x + wx, by - 40, 9, 14, _lit);
    }
    b.rect(x - 33, by - 21, 66, 2, col);
  }

  void bellTower(int x) {
    b.rect(x - 8, by - 76, 16, 76, col);
    b.tri(x, by - 96, by - 76, 12, col);
    b.rect(x - 3, by - 66, 6, 12, _lit);
  }

  void school(int x) {
    b.rect(x - 48, by - 36, 96, 36, col);
    b.tri(x, by - 64, by - 36, 54, col);
    for (var wx = -38; wx <= 26; wx += 16) {
      b.rect(x + wx, by - 30, 9, 14, _lit);
    }
    b.rect(x + 62, by - 100, 2, 100, col);
    b.rect(x + 64, by - 100, 18, 11, 0xFFC8322E);
    b.rect(x + 64, by - 94, 18, 3, 0xFFF4F0E4);
  }

  void ruin(int x, int w, int h) {
    for (var xx = 0; xx < w; xx += 4) {
      final edge = xx < 8 || xx > w - 8;
      final top = by - h + (r.next() * 18).floor() * (edge ? 2 : 1);
      b.rect(x + xx, top, 4, by - top, col);
    }
    for (var wy = by - h + 16; wy < by - 14; wy += 22) {
      for (var wx = x + 8; wx < x + w - 10; wx += 18) {
        if (r.next() > .35) {
          b.clearRect(wx, wy, 7, 10);
          if (r.next() > .88) b.rect(wx + 1, wy + 5, 5, 5, 0xFFFF9A3C);
        }
      }
    }
  }

  void tower(int x, int w, int h) {
    b.rect(x, by - h, w, h, col);
    b.rect(x + w ~/ 2, by - h - 14, 1, 14, col);
    for (var wy = by - h + 6; wy < by - 8; wy += 9) {
      for (var wx = x + 4; wx < x + w - 5; wx += 7) {
        if (r.next() > .45) b.rect(wx, wy, 3, 4, 0xFFFFF0B0);
      }
    }
  }

  switch (look.scenery) {
    case SceneryKind.huts:
      palm(40, 82);
      hut(112);
      palm(172, 98);
      palm(210, 72);
      hut(262);
      palm(302, 88);
    case SceneryKind.church:
      church(80);
      arcade(150, 112);
      church(300);
    case SceneryKind.houses:
      bahay(52);
      bellTower(112);
      bahay(168);
      bahay(250);
      bellTower(300);
    case SceneryKind.school:
      school(70);
      hut(170);
      school(250);
    case SceneryKind.ruins:
      ruin(8, 60, 80);
      ruin(76, 46, 108);
      ruin(132, 64, 66);
      ruin(206, 50, 96);
      ruin(262, 54, 76);
      b.rect(120, by - 150, 4, 150, col);
    case SceneryKind.skyline:
      tower(6, 30, 70);
      tower(40, 24, 104);
      tower(70, 34, 84);
      tower(110, 22, 128);
      b.disc(121, by - 134.0, 6, col);
      tower(138, 36, 76);
      tower(180, 28, 112);
      tower(214, 40, 90);
      tower(260, 26, 120);
      tower(292, 24, 74);
  }
  b.rect(0, by - 1, kTileW, kTileH - by + 1, col);
  b.haze(look.fog, .16);
  return b;
}

/// The dark leaves and hanging vines that frame the top of the screen, in front of
/// everything. 320 x 40 art pixels, no seam; drawn scaled 4x like the other tiles.
PixelBuf foregroundTopPixels(EraLook look) {
  const h = 40;
  final b = PixelBuf(kTileW, h);
  final col = look.foreground;
  for (final o in _wraps) {
    var seed = Rand(55 + look.scenery.index);
    for (var i = 0; i < 6; i++) {
      final x = i * 54 + seed.range(0, 20) + o, len = 8 + seed.range(0, 22);
      b.rect(x.round(), 0, 1, len.round(), col);
      b.disc(x, len, 2, col);
    }
    for (var j = 0; j < 7; j++) {
      final lx = j * 46 + seed.range(0, 20) + o;
      b.disc(lx, 1, 6 + seed.range(0, 6).floorToDouble(), col);
      b.disc(lx + 10, 4, 5, col);
    }
  }
  b.rect(0, 0, kTileW, 3, col);
  return b;
}
