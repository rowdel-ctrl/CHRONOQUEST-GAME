import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/cave_constants.dart';
import '../chrono_game.dart';
import '../components/coin_component.dart';
import '../components/tile_platform_component.dart';
import 'cave_art.dart';
import 'cave_layout.dart';
import 'cave_look.dart';

export 'cave_look.dart';

// What the cave looks like. Each era has its own underground place (see
// cave_art.dart); this file holds the components that draw it:
//
//  * [CaveBackdrop]: behind everything, stays on the screen: the wall, the far
//    rock, the era's wall decor and lights, the ceiling and what hangs from it;
//  * [CaveGround]: the floor, its texture, the pits and the props standing on it;
//  * [CavePlatformComponent]: a floating slab in the era's material;
//  * [CaveLights]: the hero's own light and a glow behind every coin;
//  * [CaveFront]: in front of everything: dust, dark rock hanging close, the
//    darkened edges of the screen.
//
// None of it is solid or moves anything: the floor and slabs keep their own hit
// boxes, so how the cave plays is exactly what it was.

/// The cave behind the world, drawn in the viewport so it stays put while the
/// camera moves and slides its layers at different speeds.
class CaveBackdrop extends PositionComponent with HasGameReference<ChronoGame> {
  CaveBackdrop(this.look) : super(priority: -10);

  final CaveLook look;
  late final CaveEraArt _art = CaveEraArt.of(look);
  final CaveInk _ink = CaveInk();
  double _t = 0;
  Size _shaderFor = Size.zero;
  Paint? _wall;

  @override
  Future<void> onLoad() async {
    size = game.size.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final w = game.size.x, h = game.size.y, ground = game.groundY;
    final s = Size(w, h);
    if (_shaderFor != s || _wall == null) {
      _shaderFor = s;
      _wall = Paint()
        ..shader =
            caveWallGradient(look).createShader(Rect.fromLTWH(0, 0, w, h));
    }
    final camX = game.cameraLeftEdgeX;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _wall!);

    final k = _ink
      ..c = canvas
      ..vw = w;
    // A soft glow in the middle of the cave, where the action is.
    k.halo(w * .55, ground - 40, 440, look.glow, .10);

    // The wall: drawn in the units the painters were designed in, with their floor
    // line on the real floor.
    canvas.save();
    canvas.translate(0, ground - kMockGround);
    // Far rock, sliding slowly.
    k.fill(const Color(0x09FFFFFF), (p) {
      p.moveTo(0, kMockGround);
      for (var x = 0.0; x <= w + 40; x += 40) {
        final wx = ((x + camX * .15) / 40).floor();
        p.lineTo(x, kMockGround - (70 + caveRnd(wx) * 90) * 2.2);
      }
      p.lineTo(w + 40, kMockGround);
      p.close();
    });
    _art.wall(k, camX, _t, look);
    canvas.restore();

    // The ceiling: anchored to the top of the screen.
    canvas.save();
    canvas.translate(0, 20);
    _art.ceil(k, camX, _t, look);
    canvas.restore();
  }
}

/// A thing standing on the cave floor, placed by [CaveGround.planProps].
class PlacedProp {
  final CaveProp prop;
  final double x;
  final int n;
  const PlacedProp(this.prop, this.x, this.n);
}

/// The cave floor: earth with a lit top edge and the era's texture, a black drop
/// where there are pits, and the era's props standing on the floor. Draws only
/// what is on screen.
class CaveGround extends PositionComponent with HasGameReference<ChronoGame> {
  CaveGround({required this.layout, required this.look}) : super(priority: -2);

  final CaveLayout layout;
  final CaveLook look;
  late final CaveEraArt _art = CaveEraArt.of(look);
  final CaveInk _ink = CaveInk();
  final Paint _p = Paint();
  Paint? _body, _pitFade;
  double _bodyH = 0;
  double _t = 0;
  late final List<PlacedProp> _placed = planProps(layout, look);

  @override
  Future<void> onLoad() async {
    position = Vector2(0, game.groundY);
    size = Vector2(layout.mapWidth, game.size.y - game.groundY);
  }

  /// Walks along the floor and sets a prop down wherever there is solid floor
  /// under all of it, leaving the pits, the start and the artifact room alone.
  /// Pure data (no game needed), so it can be checked on its own.
  static List<PlacedProp> planProps(CaveLayout layout, CaveLook look) {
    final props = CaveEraArt.of(look).props;
    final out = <PlacedProp>[];
    var x = 640.0, n = 0;
    while (x < layout.artifactX - 420) {
      final prop = props[n % props.length];
      final half = prop.width / 2 + 30;
      if (layout.floorHolds(x - half, x + half)) {
        out.add(PlacedProp(prop, x, n));
        n++;
        x += 560 + caveRnd(n + layout.levelNo) * 200;
      } else {
        x += 40;
      }
    }
    return out;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final camL = game.cameraLeftEdgeX - 40, camR = game.cameraRightEdgeX + 40;
    final bandH = size.y;
    if (_body == null || _bodyH != bandH) {
      _bodyH = bandH;
      _body = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [look.rock1, look.rock0],
        ).createShader(Rect.fromLTWH(0, 0, 1, bandH));
      _pitFade = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0x00000000),
            look.glow.withValues(alpha: .3),
          ],
        ).createShader(Rect.fromLTWH(0, 20, 1, bandH - 20));
    }
    final k = _ink
      ..c = canvas
      ..vw = game.size.x;
    for (final f in layout.floor) {
      final l = max(f.x0, camL), r = min(f.x1, camR);
      if (r <= l) continue;
      canvas.drawRect(Rect.fromLTRB(l, 0, r, bandH), _body!);
      k.rect(l, 0, r - l, 8, look.lip);
      k.rect(l, 0, r - l, 2, look.glow.withValues(alpha: .55));
      k.rect(l, 2, r - l, 2, const Color(0x1FFFFFFF));
      _art.floorTex(k, l, r, _t, look);
    }
    // The pits: black, with a faint shimmer at the very bottom.
    for (final p in layout.pits) {
      final l = max(p.x0, camL), r = min(p.x1, camR);
      if (r <= l) continue;
      _p
        ..color = const Color(0xFF05040A)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTRB(p.x0, 0, p.x1, bandH), _p);
      canvas.drawRect(Rect.fromLTRB(p.x0, 20, p.x1, bandH), _pitFade!);
      for (var x = p.x0 + 4; x < p.x1; x += 14) {
        k.rect(x, bandH - 14 + sin(_t * 3 + x * .2) * 2, 8, 2,
            look.glow.withValues(alpha: .5));
      }
      k.rect(p.x0 - 4, 0, 4, bandH, look.rock0);
      k.rect(p.x1, 0, 4, bandH, look.rock0);
    }
    // The props.
    for (final it in _placed) {
      if (it.x + 120 < camL || it.x - 120 > camR) continue;
      canvas.save();
      canvas.translate(it.x, 0);
      it.prop.draw(k, look, _t, it.n);
      canvas.restore();
    }
  }
}

/// A floating slab of the cave in the era's material. It is a
/// `TilePlatformComponent` for everything that matters (where the hero lands, the
/// hit box) and draws itself differently.
class CavePlatformComponent extends TilePlatformComponent {
  CavePlatformComponent({
    required super.widthInTiles,
    required super.surfaceY,
    required Vector2 super.spawnPosition,
    required this.look,
  });

  final CaveLook look;
  late final CaveEraArt _art = CaveEraArt.of(look);
  final CaveInk _ink = CaveInk();

  @override
  void render(Canvas canvas) {
    _ink
      ..c = canvas
      ..vw = size.x;
    _art.plat(_ink, size.x, look);
  }
}

/// The hero's own light, and a soft glow behind every coin still to be taken.
class CaveLights extends PositionComponent with HasGameReference<ChronoGame> {
  CaveLights(this.look) : super(priority: -1);

  final CaveLook look;
  final CaveInk _ink = CaveInk();

  @override
  void render(Canvas canvas) {
    final k = _ink
      ..c = canvas
      ..vw = game.size.x;
    final camL = game.cameraLeftEdgeX - 40, camR = game.cameraRightEdgeX + 40;
    for (final child in game.world.children) {
      if (child is! CoinComponent) continue;
      final x = child.position.x + child.size.x / 2;
      if (x < camL || x > camR) continue;
      k.halo(x, child.position.y + child.size.y / 2, 24,
          const Color(0xFFFFD24A), .3);
    }
    final p = game.player;
    k.halo(p.position.x + p.size.x / 2, p.position.y + p.size.y * .4, 130,
        look.glow, .13);
  }
}

/// In front of everything: dust or sparks drifting, dark rock hanging close to the
/// camera, and the darkened edges of the screen.
class CaveFront extends PositionComponent with HasGameReference<ChronoGame> {
  CaveFront(this.look) : super(priority: 100);

  final CaveLook look;
  final CaveInk _ink = CaveInk();
  final Paint _v = Paint();
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final w = game.size.x, h = game.size.y;
    final camX = game.cameraLeftEdgeX;
    final k = _ink
      ..c = canvas
      ..vw = w;
    final span = w + 40;
    for (var i = 0; i < 18; i++) {
      final x = ((i * 97 + _t * (6 + i % 3 * 4) - camX * 1.2) % span) - 20;
      final y = 90 + ((i * 53) % 520) + sin(_t + i) * 8;
      k.rect(x, y, 2, 2, look.glow.withValues(alpha: .22));
    }
    k.each(560, camX * 1.3, (x, i) {
      final len = 30 + caveRnd(i + 21) * 40;
      k.tri(x, 0, x + 50, 0, x + 25, 24 + len, const Color(0x80000000));
    });
    // The darkened edges: a gradient that is clear in the middle.
    _v.shader ??= const RadialGradient(
      colors: [Color(0x00000000), Color(0x00000000), Color(0x8C000000)],
      stops: [0, .55, 1],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));
    final sx = w * .62, sy = h * .8;
    canvas.save();
    canvas.translate(w / 2, h * .55);
    canvas.scale(sx, sy);
    canvas.drawRect(
        Rect.fromLTRB(-w / 2 / sx, -h * .55 / sy, w / 2 / sx, h * .45 / sy),
        _v);
    canvas.restore();
  }
}

/// The pipe in the ceiling the student dropped out of, at the start of the cave.
class CaveCeilingPipe extends PositionComponent
    with HasGameReference<ChronoGame> {
  CaveCeilingPipe({required this.centerX, required this.color})
      : super(priority: -3);

  final double centerX;
  final Color color;
  final Paint _p = Paint();

  @override
  Future<void> onLoad() async {
    position = Vector2(centerX - CaveConstants.pipeRimWidth / 2, 0);
    size = Vector2(CaveConstants.pipeRimWidth, 80);
  }

  @override
  void render(Canvas canvas) {
    _p.color = color;
    canvas.drawRect(const Rect.fromLTWH(12, 0, 96, 56), _p);
    _p.color = Color.lerp(color, Colors.white, .25)!;
    canvas.drawRect(const Rect.fromLTWH(0, 46, 120, 20), _p);
    _p.color = Color.lerp(color, Colors.black, .4)!;
    canvas.drawRect(const Rect.fromLTWH(0, 62, 120, 4), _p);
  }
}
