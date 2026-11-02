import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// A colour from its parts, as the 0xAARRGGBB number the rest of the backdrop uses.
int rgba(int r, int g, int b, [int a = 255]) =>
    (a << 24) | (r << 16) | (g << 8) | b;

/// [a] mixed towards [b] by [t] (0 = all a, 1 = all b). Always fully opaque.
int mixColor(int a, int b, double t) {
  int ch(int shift) {
    final x = (a >> shift) & 255, y = (b >> shift) & 255;
    return (x + (y - x) * t).round().clamp(0, 255);
  }

  return rgba(ch(16), ch(8), ch(0));
}

/// A small random-number generator that gives the same numbers for the same seed, so
/// the scenery looks the same every time a level opens.
class Rand {
  Rand(int seed) : _s = (seed * 2654435761) & 0xFFFFFFFF {
    if (_s == 0) _s = 0x9E3779B9;
  }
  int _s;

  /// 0 up to (not including) 1.
  double next() {
    _s ^= (_s << 13) & 0xFFFFFFFF;
    _s ^= _s >> 17;
    _s ^= (_s << 5) & 0xFFFFFFFF;
    return _s / 4294967296.0;
  }

  /// [lo] up to [hi].
  double range(double lo, double hi) => lo + next() * (hi - lo);
}

/// A picture drawn one chunky pixel at a time: rectangles, discs, lines. It is turned
/// into an image once, and the game then draws that image scaled up without smoothing,
/// which is what gives the backdrop the same pixel-art look as the sprites.
class PixelBuf {
  PixelBuf(this.w, this.h) : _px = Uint8List(w * h * 4);

  final int w;
  final int h;
  final Uint8List _px;

  bool _inside(int x, int y) => x >= 0 && y >= 0 && x < w && y < h;

  void put(int x, int y, int color) {
    if (!_inside(x, y)) return;
    final i = (y * w + x) * 4;
    _px[i] = (color >> 16) & 255;
    _px[i + 1] = (color >> 8) & 255;
    _px[i + 2] = color & 255;
    _px[i + 3] = (color >> 24) & 255;
  }

  /// Makes a pixel see-through again (a window cut out of a building).
  void clear(int x, int y) {
    if (!_inside(x, y)) return;
    _px[(y * w + x) * 4 + 3] = 0;
  }

  bool filled(int x, int y) => _inside(x, y) && _px[(y * w + x) * 4 + 3] != 0;

  void rect(int x, int y, int rw, int rh, int color) {
    for (var j = 0; j < rh; j++) {
      for (var i = 0; i < rw; i++) {
        put(x + i, y + j, color);
      }
    }
  }

  void clearRect(int x, int y, int rw, int rh) {
    for (var j = 0; j < rh; j++) {
      for (var i = 0; i < rw; i++) {
        clear(x + i, y + j);
      }
    }
  }

  /// A filled ellipse. With [maxY] set, only the rows up to it are drawn (a cap).
  void ell(double cx, double cy, double rx, double ry, int color,
      {int? maxY}) {
    final top = (cy - ry).floor();
    final bottom = math.min((cy + ry).ceil(), maxY ?? 1 << 30);
    for (var y = top; y <= bottom; y++) {
      for (var x = (cx - rx).floor(); x <= (cx + rx).ceil(); x++) {
        final dx = (x + .5 - cx) / rx, dy = (y + .5 - cy) / ry;
        if (dx * dx + dy * dy <= 1) put(x, y, color);
      }
    }
  }

  /// Cuts a see-through ellipse out of what is drawn (an arch in a wall).
  void clearEll(double cx, double cy, double rx, double ry) {
    for (var y = (cy - ry).floor(); y <= (cy + ry).ceil(); y++) {
      for (var x = (cx - rx).floor(); x <= (cx + rx).ceil(); x++) {
        final dx = (x + .5 - cx) / rx, dy = (y + .5 - cy) / ry;
        if (dx * dx + dy * dy <= 1) clear(x, y);
      }
    }
  }

  void disc(double cx, double cy, double r, int color) =>
      ell(cx, cy, r, r, color);

  /// A line made of square stamps [width] pixels wide.
  void line(double x0, double y0, double x1, double y1, int width, int color) {
    final d = math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0));
    final n = math.max(1, (d * 2).ceil());
    for (var i = 0; i <= n; i++) {
      final t = i / n;
      final x = x0 + (x1 - x0) * t, y = y0 + (y1 - y0) * t;
      rect((x - width / 2 + .01).round(), (y - width / 2 + .01).round(), width,
          width, color);
    }
  }

  /// A filled triangle pointing up: apex at ([cx], [apexY]), widest at [baseY].
  void tri(int cx, int apexY, int baseY, int halfWidth, int color) {
    for (var y = apexY; y <= baseY; y++) {
      final hw = ((y - apexY) / math.max(1, baseY - apexY) * halfWidth).round();
      rect(cx - hw, y, hw * 2 + 1, 1, color);
    }
  }

  /// Washes everything drawn so far towards [color] (distance haze): [amount] 0..1.
  void haze(int color, double amount) {
    for (var i = 0; i < _px.length; i += 4) {
      if (_px[i + 3] == 0) continue;
      final c = mixColor(rgba(_px[i], _px[i + 1], _px[i + 2]), color, amount);
      _px[i] = (c >> 16) & 255;
      _px[i + 1] = (c >> 8) & 255;
      _px[i + 2] = c & 255;
    }
  }

  /// The pixels as an image. Needs a real engine (not available in plain unit tests
  /// without `runAsync`).
  Future<ui.Image> toImage() {
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(_px, w, h, ui.PixelFormat.rgba8888, done.complete);
    return done.future;
  }

  /// The raw RGBA bytes, for tests.
  Uint8List get bytes => _px;
}
