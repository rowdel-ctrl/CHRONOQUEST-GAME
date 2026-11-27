import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

/// When things happen in the boss defeat, in seconds of "story time" (the clock that slows down
/// in slow motion). The whole defeat lasts about eight real seconds.
///
///  0.00 the hero's last hit lands
///  0.50 hit-stop and a flash; the boss falls apart in cracks (pressure builds)
///  1.90 the boss explodes
///  3.00 time speeds up again; coins fall
///  3.20 a medal rises where the boss stood and the hero cheers
///  4.10 the banner pops up
///  5.20 the medal flies to the middle and the screen fills with gold
///  6.20 done: the level is complete (the Era Complete screen follows)
class BossDefeatTimes {
  BossDefeatTimes._();

  static const double hit = 0.5;
  static const double boom = 1.9;
  static const double after = 3.0;
  static const double medal = 3.2;
  static const double banner = 4.1;
  static const double fade = 5.2;
  static const double end = 6.2;

  /// Real seconds the picture is frozen at the last hit and at the explosion.
  static const double hitStop = 0.18;
  static const double boomStop = 0.12;

  /// How fast story time runs between the last hit and the explosion, and during the
  /// explosion.
  static const double pressureSpeed = 0.75;
  static const double slowMotionSpeed = 0.45;

  /// A tap skips what is left, but only after this long (so it is not skipped by accident).
  static const double skipAfter = 1.0;
}

/// One small square of the boss picture, flying off when it explodes.
class DefeatPiece {
  /// Where it sits on the picture, in game units from the picture's top left.
  final double x;
  final double y;
  final ui.Color color;
  double delay = 0;
  double vx = 0;
  double vy = 0;
  double gravity = 520;
  double life = 1;
  DefeatPiece(this.x, this.y, this.color);
}

/// Cuts a picture into small squares of [step] source pixels (the colour of each one's middle),
/// skipping the see-through ones. [drawSize] is how big the picture is drawn, in game units.
Future<List<DefeatPiece>> sampleDefeatPieces(Sprite sprite, Vector2 drawSize,
    {int step = 8}) async {
  final image = sprite.image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return const [];
  final src = sprite.src;
  final pieces = <DefeatPiece>[];
  final sx = drawSize.x / src.width;
  final sy = drawSize.y / src.height;
  for (var py = 0; py < src.height; py += step) {
    for (var px = 0; px < src.width; px += step) {
      final ix = (src.left + px + step ~/ 2).clamp(0, image.width - 1).toInt();
      final iy = (src.top + py + step ~/ 2).clamp(0, image.height - 1).toInt();
      final o = (iy * image.width + ix) * 4;
      final a = data.getUint8(o + 3);
      if (a < 110) continue;
      pieces.add(DefeatPiece(
        px * sx,
        py * sy,
        ui.Color.fromARGB(
            255, data.getUint8(o), data.getUint8(o + 1), data.getUint8(o + 2)),
      ));
    }
  }
  return pieces;
}

/// What the sequence needs to know about the scene, gathered when the boss falls.
class BossDefeatStage {
  /// The size of the view in game units (the virtual screen).
  final Vector2 viewSize;

  /// The world position of the view's top left before any zoom.
  final Vector2 normalTopLeft;

  /// Where the boss and the hero stand: the middle of the bottom of each picture, in world units.
  final Vector2 bossFoot;
  final Vector2 heroFoot;

  /// How big the boss picture is drawn, and whether it is turned to face right.
  final Vector2 bossArtSize;
  final bool bossFlipped;
  final Sprite bossSprite;

  /// The hero's cheering picture (null: the hero just stays as he is), drawn facing right. It is
  /// loaded while the defeat starts, so it may arrive a moment late.
  Sprite? heroWinSprite;
  final double groundY;

  /// What shows on the medal and in the banner.
  final ui.Color medalColor;
  final String bossName;

  /// The boss picture cut into squares.
  final List<DefeatPiece> pieces;

  BossDefeatStage({
    required this.viewSize,
    required this.normalTopLeft,
    required this.bossFoot,
    required this.heroFoot,
    required this.bossArtSize,
    required this.bossFlipped,
    required this.bossSprite,
    required this.heroWinSprite,
    required this.groundY,
    required this.medalColor,
    required this.bossName,
    required this.pieces,
  });
}

/// The sounds of the defeat, so the game can play them and a test can count them.
class BossDefeatSounds {
  final void Function() rumble;
  final void Function() crack;
  final void Function() boom;
  final void Function() clatter;
  final void Function() coin;
  final void Function() medal;
  final void Function() win;
  const BossDefeatSounds({
    required this.rumble,
    required this.crack,
    required this.boom,
    required this.clatter,
    required this.coin,
    required this.medal,
    required this.win,
  });

  static final silent = BossDefeatSounds(
      rumble: () {},
      crack: () {},
      boom: () {},
      clatter: () {},
      coin: () {},
      medal: () {},
      win: () {});
}

class _Spark {
  double x, y, vx, vy, age = 0;
  final double life;
  final double size;
  final ui.Color color;
  _Spark(this.x, this.y, this.vx, this.vy, this.life, this.size, this.color);
}

class _Puff {
  double x, y, vx, vy, r, age = 0;
  final double life;
  final bool dark;
  _Puff(this.x, this.y, this.vx, this.vy, this.r, this.life, this.dark);
}

class _Chip {
  double x, y;
  final double vx, vy, life;
  final ui.Color color;
  double age = 0;
  _Chip(this.x, this.y, this.vx, this.vy, this.life, this.color);
}

class _Ember {
  double x, y, age = 0;
  final double vx, vy, life, size, phase;
  _Ember(this.x, this.y, this.vx, this.vy, this.life, this.size, this.phase);
}

class _Ring {
  final double x, y, max, life, width;
  final ui.Color color;
  double age = 0;
  _Ring(this.x, this.y, this.max, this.life, this.width, this.color);
}

class _Coin {
  double x, y, vx, vy, spin, rest = 0;
  int bounced = 0;
  int state = 0; // 0 flying, 1 resting, 2 flying to the hero, 3 gone
  _Coin(this.x, this.y, this.vx, this.vy, this.spin);
}

class _Star {
  final double x, y, size;
  double age;
  _Star(this.x, this.y, this.size, this.age);
}

/// The last hit on a boss: it cracks and shakes while the camera moves in, then explodes, coins
/// fall, a medal rises, a banner pops up and the screen fills with gold. It owns the camera
/// (zoom and where it looks) and draws everything of its own over the picture; the world stands
/// still meanwhile. The game calls [step] each frame and [render] to draw.
class BossDefeatSequence {
  final BossDefeatStage stage;
  final BossDefeatSounds sounds;
  final math.Random _rnd;

  BossDefeatSequence(
      {required this.stage, required this.sounds, math.Random? random})
      : _rnd = random ?? math.Random(11);

  /// Seconds of story time, and how long the picture is still frozen (real seconds).
  double story = 0;
  double _freeze = 0;

  /// Real seconds since it began (the skip button waits for this).
  double real = 0;

  bool _hit = false;
  bool _boomed = false;
  bool _medal = false;
  bool _banner = false;
  bool _faded = false;
  bool done = false;

  bool get hit => _hit;
  bool get boomed => _boomed;
  bool get medalShown => _medal;

  // Looks.
  double _flash = 0;
  double _shake = 0;
  double _vignette = 0;
  double _zoom = 1;
  double _boomAt = 0;
  double _crackT = 0;
  double _smokeT = 0;
  double _chipT = 0;
  double _clatterT = 0;
  int _coinQueue = 0;
  double _coinT = 0;
  double _fire = -1;

  final List<_Spark> _sparks = [];
  final List<_Puff> _puffs = [];
  final List<_Chip> _chips = [];
  final List<_Ember> _embers = [];
  final List<_Ring> _rings = [];
  final List<_Coin> _coins = [];
  final List<_Star> _stars = [];
  List<List<ui.Offset>>? _cracks;

  // ─── READ BY THE GAME ───────────────────────────────────────────────────

  double get zoom => _zoom;

  /// Whether the boss picture itself is drawn by the game (before the last hit). From the last
  /// hit on, this sequence draws the boss.
  bool get drawsBoss => _hit;

  /// Whether the hero is drawn by this sequence (cheering), so the game hides his own picture.
  bool get drawsHero => _medal && stage.heroWinSprite != null;

  /// Where the camera looks from (the world position of the top left of the view), shake included.
  /// Worked out once a step, so the game's camera and this sequence's drawing agree.
  late Vector2 topLeft = stage.normalTopLeft.clone();

  Vector2 _computeTopLeft() {
    final kz = ((_zoom - 1) / 0.3).clamp(0.0, 1.0);
    final normalCentre = stage.normalTopLeft + stage.viewSize / 2;
    final bossCentre =
        Vector2(_bossFoot.x, _bossFoot.y - stage.bossArtSize.y * 0.5);
    final centre = Vector2(
      normalCentre.x + (bossCentre.x - normalCentre.x) * kz,
      normalCentre.y + (bossCentre.y - normalCentre.y) * kz * 0.8,
    );
    final shake = _shake > 0.05
        ? Vector2(_r(-_shake, _shake), _r(-_shake, _shake) * 0.6)
        : Vector2.zero();
    return centre - stage.viewSize / (2 * _zoom) + shake;
  }

  static double _ease(double t) => t * t * (3 - 2 * t);

  double _r(double a, double b) => a + _rnd.nextDouble() * (b - a);

  /// The boss's foot, pushed back a little by the last hit.
  Vector2 get _bossFoot {
    final k = _hit
        ? _ease(((story - BossDefeatTimes.hit) / 0.18).clamp(0.0, 1.0))
        : 0.0;
    return Vector2(stage.bossFoot.x + 14 * k, stage.bossFoot.y);
  }

  /// Whether a tap may skip the rest yet.
  bool get canSkip => real >= BossDefeatTimes.skipAfter;

  /// Jumps to the end: everything stops and the sequence is done.
  void skip() {
    if (done) return;
    story = BossDefeatTimes.end;
    _hit = _boomed = _medal = _banner = _faded = true;
    _freeze = 0;
    _zoom = 1;
    _vignette = 0;
    _flash = 0;
    _shake = 0;
    _sparks.clear();
    _puffs.clear();
    _chips.clear();
    _embers.clear();
    _rings.clear();
    _coins.clear();
    _fire = -1;
    done = true;
    topLeft = stage.normalTopLeft.clone();
  }

  /// Which part of the defeat is on, for the tests: 0 last hit, 1 pressure, 2 explosion, 3 coins
  /// and medal, 4 banner, 5 gold fade.
  int get phase => story < BossDefeatTimes.hit
      ? 0
      : story < BossDefeatTimes.boom
          ? 1
          : story < BossDefeatTimes.after
              ? 2
              : story < BossDefeatTimes.banner
                  ? 3
                  : story < BossDefeatTimes.fade
                      ? 4
                      : 5;

  // ─── THE CLOCK ───────────────────────────────────────────────────────────

  /// Moves on by [rawDt] real seconds. [reducedMotion] keeps time at full speed and skips the
  /// freeze (for a phone that is set to remove animations).
  void step(double rawDt, {bool reducedMotion = false}) {
    if (done) return;
    real += rawDt;
    var scale = 1.0;
    if (_freeze > 0) {
      _freeze -= rawDt;
      scale = 0;
    } else if (story >= BossDefeatTimes.hit && story < BossDefeatTimes.boom) {
      scale = BossDefeatTimes.pressureSpeed;
    } else if (story >= BossDefeatTimes.boom && story < BossDefeatTimes.after) {
      scale = BossDefeatTimes.slowMotionSpeed;
    }
    if (reducedMotion) scale = 1;
    final dt = rawDt * scale;
    story += dt;
    _flash = math.max(0, _flash - rawDt * 2.4);
    _shake = math.max(0, _shake - rawDt * (_boomed ? 9 : 14));
    _vignette = math.max(0, _vignette - rawDt * (_boomed ? 1.1 : 0));

    final foot = _bossFoot;
    final bx = foot.x;
    final by = foot.y - stage.bossArtSize.y * 0.5;

    // The last hit.
    if (!_hit && story >= BossDefeatTimes.hit) {
      _hit = true;
      _freeze = reducedMotion ? 0 : BossDefeatTimes.hitStop;
      _flash = 0.85;
      _shake = 8;
      sounds.rumble();
      _makeCracks();
      _spark(bx - 20, by, 28, 1.2);
      _rings.add(_Ring(bx - 20, by, 80, 0.5, 5, const ui.Color(0xFFFFFFFF)));
    }

    // Pressure builds: the camera moves in, the edges go dark, the cracks spread.
    if (_hit && !_boomed) {
      final p = ((story - BossDefeatTimes.hit) /
              (BossDefeatTimes.boom - BossDefeatTimes.hit))
          .clamp(0.0, 1.0);
      _zoom = 1 + 0.34 * _ease(p);
      _vignette = math.max(_vignette, 0.6 * math.min(1.0, p * 2.5));
      _shake = math.max(_shake, 1 + 5 * p * p);
      _crackT -= dt;
      if (_crackT <= 0) {
        _crackT = 0.13 - 0.09 * p;
        sounds.crack();
        _spark(bx + _r(-45, 45), by + _r(-60, 60), 2 + (p * 4).floor(), 0.7);
      }
      _smokeT -= dt;
      if (_smokeT <= 0) {
        _smokeT = 0.08;
        _puffs.add(_Puff(bx + _r(-50, 50), foot.y - _r(10, 80), _r(-10, 10),
            -_r(20, 55), _r(8, 16), _r(0.8, 1.3), false));
      }
      _chipT -= dt;
      if (_chipT <= 0 && stage.pieces.isNotEmpty) {
        _chipT = 1 / (10 + 70 * p);
        final piece = stage.pieces[_rnd.nextInt(stage.pieces.length)];
        final left = bx - stage.bossArtSize.x / 2;
        final px = stage.bossFlipped ? stage.bossArtSize.x - piece.x : piece.x;
        _chips.add(_Chip(left + px, foot.y - stage.bossArtSize.y + piece.y,
            _r(-14, 14), -_r(30, 100), _r(0.6, 1.1), piece.color));
      }
    }

    // The explosion.
    if (!_boomed && story >= BossDefeatTimes.boom) {
      _boomed = true;
      _freeze = reducedMotion ? 0 : BossDefeatTimes.boomStop;
      _flash = 1;
      _shake = 17;
      _zoom = 0.9;
      _vignette = math.max(_vignette, 0.55);
      _boomAt = story;
      sounds.boom();
      _rings
        ..add(_Ring(bx, by, 260, 0.8, 10, const ui.Color(0xFFFFFFFF)))
        ..add(_Ring(bx, by, 190, 1.0, 6, const ui.Color(0xFFFFB23E)))
        ..add(_Ring(bx, by, 130, 1.2, 4, const ui.Color(0xFFFF6A3A)));
      _fire = 0;
      _spark(bx, by, 80, 1.8);
      for (var i = 0; i < 22; i++) {
        _puffs.add(_Puff(bx + _r(-45, 45), by + _r(-55, 55), _r(-110, 110),
            _r(-110, 10), _r(14, 28), _r(1.0, 1.7), true));
      }
      for (var i = 0; i < 46; i++) {
        _embers.add(_Ember(bx + _r(-50, 50), by + _r(-50, 60), _r(-30, 30),
            -_r(14, 60), _r(1.4, 2.8), _r(1.5, 2.8), _r(0, 6)));
      }
      for (final p in stage.pieces) {
        final cx = p.x + 2 - stage.bossArtSize.x / 2;
        final cy = p.y + 2 - stage.bossArtSize.y / 2;
        final dist = math.sqrt(cx * cx + cy * cy);
        final ang = math.atan2(cy, cx) + _r(-0.35, 0.35);
        final sp = _r(90, 350) * (0.55 + math.min(1.0, dist / 110) * 0.6);
        p
          ..delay = _r(0, 0.05)
          ..vx = math.cos(ang) * sp
          ..vy = math.sin(ang) * sp - 110
          ..gravity = 520
          ..life = _r(0.9, 1.5);
      }
      _coinQueue = 24;
      _coinT = 0.25;
    }
    if (_boomed && story < BossDefeatTimes.after + 0.4) {
      _clatterT -= dt;
      if (_clatterT <= 0) {
        _clatterT = 0.28;
        sounds.clatter();
      }
    }
    if (_coinQueue > 0 && story >= BossDefeatTimes.boom) {
      _coinT -= dt;
      if (_coinT <= 0) {
        _coinT = 0.05;
        _coinQueue--;
        _coins.add(_Coin(bx + _r(-20, 20), by + _r(-10, 20), -_r(60, 240),
            -_r(260, 430), _r(0, 6)));
        sounds.coin();
      }
    }
    if (_boomed) _zoom += (1 - _zoom) * math.min(1.0, rawDt * 4.5);

    // The medal and the cheer.
    if (!_medal && story >= BossDefeatTimes.medal) {
      _medal = true;
      sounds.medal();
      final hx = stage.heroFoot.x;
      for (var i = 0; i < 10; i++) {
        _stars.add(_Star(hx + _r(-60, 60), stage.groundY - _r(40, 170),
            _r(6, 12), -i * 0.07));
      }
      for (var i = 0; i < 12; i++) {
        _stars.add(_Star(bx + _r(-80, 80), stage.groundY - _r(30, 170),
            _r(6, 12), -(0.2 + i * 0.07)));
      }
    }
    if (!_banner && story >= BossDefeatTimes.banner) {
      _banner = true;
      sounds.win();
    }
    if (!_faded && story >= BossDefeatTimes.fade) _faded = true;
    if (story >= BossDefeatTimes.end) {
      done = true;
      _zoom = 1;
      _flash = 0;
    }

    // Particles.
    for (final p in _sparks) {
      p.age += dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 420 * dt;
    }
    _sparks.removeWhere((p) => p.age >= p.life);
    for (final p in _puffs) {
      p.age += dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.r += 14 * dt;
      p.vx *= 1 - 1.2 * dt;
    }
    _puffs.removeWhere((p) => p.age >= p.life);
    for (final p in _chips) {
      p.age += dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
    }
    _chips.removeWhere((p) => p.age >= p.life);
    for (final p in _embers) {
      p.age += dt;
      p.x += (p.vx + math.sin(p.age * 3 + p.phase) * 14) * dt;
      p.y += p.vy * dt;
    }
    _embers.removeWhere((p) => p.age >= p.life);
    for (final p in _rings) {
      p.age += dt;
    }
    _rings.removeWhere((p) => p.age >= p.life);
    for (final p in _stars) {
      p.age += dt;
    }
    _stars.removeWhere((p) => p.age >= 0.9);
    if (_fire >= 0) {
      _fire += dt;
      if (_fire > 0.75) _fire = -1;
    }
    final hcx = stage.heroFoot.x;
    final hcy = stage.heroFoot.y - 64;
    for (final c in _coins) {
      c.spin += dt * 14;
      if (c.state == 0) {
        c.x += c.vx * dt;
        c.y += c.vy * dt;
        c.vy += 900 * dt;
        if (c.y > stage.groundY + 2) {
          c.y = stage.groundY + 2;
          c.vy *= -0.38;
          c.vx *= 0.5;
          c.bounced++;
          if (c.bounced >= 2) {
            c.state = 1;
            c.rest = 0;
          }
        }
      } else if (c.state == 1) {
        c.rest += dt;
        if (c.rest > 0.5) c.state = 2;
      } else if (c.state == 2) {
        final dx = hcx - c.x;
        final dy = hcy - c.y;
        final d = math.sqrt(dx * dx + dy * dy);
        final move = 430 * dt;
        if (d < 18) {
          c.state = 3;
          _spark(c.x, c.y, 3, 0.4);
        } else {
          c.x += dx / d * move;
          c.y += dy / d * move;
        }
      }
    }
    _coins.removeWhere((c) => c.state == 3);
    topLeft = _computeTopLeft();
  }

  void _spark(double x, double y, int n, double power) {
    const colors = [
      ui.Color(0xFFFFE27A),
      ui.Color(0xFFFFFFFF),
      ui.Color(0xFFFFB23E),
      ui.Color(0xFFFFF3B0)
    ];
    for (var i = 0; i < n; i++) {
      final a = _r(0, math.pi * 2);
      final sp = _r(40, 230) * power;
      _sparks.add(_Spark(x, y, math.cos(a) * sp, math.sin(a) * sp - 80,
          _r(0.4, 1.0), _r(2, 4.5), colors[i % 4]));
    }
  }

  void _makeCracks() {
    final w = stage.bossArtSize.x;
    final h = stage.bossArtSize.y;
    final cx = w * 0.5;
    final cy = h * 0.55;
    final lines = <List<ui.Offset>>[];
    for (var k = 0; k < 9; k++) {
      var a = k / 9 * math.pi * 2 + _r(-0.3, 0.3);
      var x = cx;
      var y = cy;
      final line = <ui.Offset>[ui.Offset(x, y)];
      final n = 6 + _rnd.nextInt(5);
      for (var i = 0; i < n; i++) {
        a += _r(-0.55, 0.55);
        x += math.cos(a) * _r(11, 20);
        y += math.sin(a) * _r(11, 20);
        line.add(ui.Offset(x, y));
        if (i == 2 && _rnd.nextDouble() < 0.7) {
          var b = a + _r(0.6, 1.1) * (_rnd.nextBool() ? 1 : -1);
          var bx = x;
          var by = y;
          final branch = <ui.Offset>[ui.Offset(bx, by)];
          for (var j = 0; j < 4; j++) {
            b += _r(-0.4, 0.4);
            bx += math.cos(b) * _r(9, 15);
            by += math.sin(b) * _r(9, 15);
            branch.add(ui.Offset(bx, by));
          }
          lines.add(branch);
        }
      }
      lines.add(line);
    }
    _cracks = lines;
  }

  // ─── DRAWING ─────────────────────────────────────────────────────────────

  ui.Offset _screen(double wx, double wy, Vector2 tl) =>
      ui.Offset((wx - tl.x) * _zoom, (wy - tl.y) * _zoom);

  /// Draws everything of the defeat over the world picture, in the virtual screen's units.
  void render(ui.Canvas canvas) {
    if (!_hit) return;
    final tl = topLeft;
    final z = _zoom;
    final foot = _bossFoot;

    // The boss, until it explodes.
    if (!_boomed) _renderBoss(canvas, tl, foot);
    // Pieces.
    if (_boomed) _renderPieces(canvas, tl, foot);

    final paint = ui.Paint();
    // Chips flaking off the cracked boss.
    for (final c in _chips) {
      final k = c.age / c.life;
      paint.color = c.color.withValues(alpha: 1 - k);
      final o = _screen(c.x, c.y, tl);
      canvas.drawRect(ui.Rect.fromLTWH(o.dx, o.dy, 3 * z, 3 * z), paint);
    }
    // Smoke.
    for (final p in _puffs) {
      final k = p.age / p.life;
      paint.color =
          (p.dark ? const ui.Color(0xFF3B3640) : const ui.Color(0xFF9FB0A8))
              .withValues(alpha: (p.dark ? 0.5 : 0.34) * (1 - k));
      canvas.drawCircle(_screen(p.x, p.y, tl), p.r * z, paint);
    }
    // The fireball.
    if (_fire >= 0) {
      final k = (_fire / 0.75).clamp(0.0, 1.0);
      final c = _screen(foot.x, foot.y - stage.bossArtSize.y * 0.5, tl);
      final r = (30 + k * 190) * z;
      paint.shader = ui.Gradient.radial(c, r, [
        const ui.Color(0xFFFFFFFF).withValues(alpha: 1 - k),
        const ui.Color(0xFFFFE27A).withValues(alpha: 0.95 * (1 - k)),
        const ui.Color(0xFFFF7828).withValues(alpha: 0.6 * (1 - k)),
        const ui.Color(0x00FF501E),
      ], const [
        0,
        0.25,
        0.6,
        1
      ]);
      paint.blendMode = ui.BlendMode.plus;
      canvas.drawCircle(c, r, paint);
      paint.shader = null;
      paint.blendMode = ui.BlendMode.srcOver;
    }
    // Light beams and rays once the medal is up.
    if (_medal) _renderLight(canvas, tl, foot);
    // The hero cheering.
    if (drawsHero) _renderHero(canvas, tl);
    // Coins.
    for (final c in _coins) {
      final o = _screen(c.x, c.y, tl);
      final w = math.max(0.15, math.cos(c.spin).abs()) * 7 * z;
      paint.color = const ui.Color(0xFFFFD24A);
      canvas.drawOval(
          ui.Rect.fromCenter(center: o, width: w * 2, height: 14 * z), paint);
      paint
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.5 * z
        ..color = const ui.Color(0xFFA8741A);
      canvas.drawOval(
          ui.Rect.fromCenter(center: o, width: w * 2, height: 14 * z), paint);
      paint.style = ui.PaintingStyle.fill;
    }
    // Embers and sparks add light.
    paint.blendMode = ui.BlendMode.plus;
    for (final p in _embers) {
      final k = p.age / p.life;
      paint.color = const ui.Color(0xFFFF9A3A).withValues(alpha: (1 - k) * 0.9);
      final o = _screen(p.x, p.y, tl);
      canvas.drawRect(
          ui.Rect.fromLTWH(o.dx, o.dy, p.size * z, p.size * z), paint);
    }
    for (final p in _sparks) {
      final k = p.age / p.life;
      paint.color = p.color.withValues(alpha: 1 - k);
      final o = _screen(p.x, p.y, tl);
      canvas.drawRect(
          ui.Rect.fromLTWH(o.dx, o.dy, p.size * z, p.size * z), paint);
    }
    paint.blendMode = ui.BlendMode.srcOver;
    // Rings.
    for (final r in _rings) {
      final k = r.age / r.life;
      paint
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = r.width * (1 - k * 0.7) * z
        ..color = r.color.withValues(alpha: 1 - k);
      canvas.drawCircle(_screen(r.x, r.y, tl), r.max * math.sqrt(k) * z, paint);
    }
    paint.style = ui.PaintingStyle.fill;
    // Sparkles round the hero and where the boss stood.
    for (final s in _stars) {
      if (s.age < 0) continue;
      final k = s.age / 0.9;
      final sz = s.size * math.sin(math.min(1.0, k) * math.pi) * z;
      final o = _screen(s.x, s.y, tl);
      final path = ui.Path();
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        final rr = i.isOdd ? sz * 0.28 : sz;
        final px = o.dx + math.cos(a) * rr;
        final py = o.dy + math.sin(a) * rr;
        i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
      }
      path.close();
      paint.color = const ui.Color(0xFFFFE98A);
      canvas.drawPath(path, paint);
    }

    _renderScreen(canvas, tl);
  }

  void _renderBoss(ui.Canvas canvas, Vector2 tl, Vector2 foot) {
    final sprite = stage.bossSprite;
    final art = stage.bossArtSize;
    final p = ((story - BossDefeatTimes.hit) /
            (BossDefeatTimes.boom - BossDefeatTimes.hit))
        .clamp(0.0, 1.0);
    final amp = 1.2 + 5.5 * p;
    final jx = _r(-1, 1) * amp;
    final jy = _r(-1, 1) * amp * 0.5;
    final topLeftWorld = Vector2(foot.x - art.x / 2 + jx, foot.y - art.y + jy);
    final o = _screen(topLeftWorld.x, topLeftWorld.y, tl);
    final size = ui.Size(art.x * _zoom, art.y * _zoom);

    void drawSprite(ui.Paint? paint) {
      canvas.save();
      if (stage.bossFlipped) {
        canvas.translate(o.dx + size.width / 2, 0);
        canvas.scale(-1, 1);
        canvas.translate(-(o.dx + size.width / 2), 0);
      }
      sprite.render(canvas,
          position: Vector2(o.dx, o.dy),
          size: Vector2(size.width, size.height),
          overridePaint: paint);
      canvas.restore();
    }

    drawSprite(null);
    // A red and white glow that pulses faster as the pressure builds.
    final pulse =
        0.5 + 0.5 * math.sin((story - BossDefeatTimes.hit) * (14 + 20 * p));
    drawSprite(ui.Paint()
      ..colorFilter = ui.ColorFilter.mode(
          const ui.Color(0xFFFF3B2A).withValues(
              alpha: math.min(0.7, (0.15 + 0.25 * pulse) * (0.4 + p))),
          ui.BlendMode.srcIn)
      ..blendMode = ui.BlendMode.plus);
    drawSprite(ui.Paint()
      ..colorFilter = ui.ColorFilter.mode(
          const ui.Color(0xFFFFFFFF)
              .withValues(alpha: math.min(0.7, 0.5 * p * pulse)),
          ui.BlendMode.srcIn)
      ..blendMode = ui.BlendMode.plus);
    // Glowing cracks, cut to the boss's shape.
    final cracks = _cracks;
    if (cracks != null) {
      final grow = math.min(1.0, p * 1.6);
      canvas.saveLayer(
          ui.Rect.fromLTWH(o.dx - 4, o.dy - 4, size.width + 8, size.height + 8),
          ui.Paint());
      final line = ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round;
      for (final pass in const [
        (4.0, ui.Color(0xFFFF9A2E)),
        (1.6, ui.Color(0xFFFFF7D0))
      ]) {
        line
          ..strokeWidth = pass.$1 * _zoom
          ..color = pass.$2;
        for (final l in cracks) {
          final n = math.max(1, ((l.length - 1) * grow).floor());
          final path = ui.Path()
            ..moveTo(o.dx + l[0].dx * _zoom, o.dy + l[0].dy * _zoom);
          for (var i = 1; i <= n && i < l.length; i++) {
            path.lineTo(o.dx + l[i].dx * _zoom, o.dy + l[i].dy * _zoom);
          }
          canvas.drawPath(path, line);
        }
      }
      // Keep only what is on the boss.
      canvas.saveLayer(null, ui.Paint()..blendMode = ui.BlendMode.dstIn);
      drawSprite(null);
      canvas.restore();
      canvas.restore();
    }
  }

  void _renderPieces(ui.Canvas canvas, Vector2 tl, Vector2 foot) {
    final left = foot.x - stage.bossArtSize.x / 2;
    final top = foot.y - stage.bossArtSize.y;
    final paint = ui.Paint();
    final z = _zoom;
    for (final b in stage.pieces) {
      final t = story - _boomAt - b.delay;
      final px = stage.bossFlipped ? stage.bossArtSize.x - b.x - 3.2 : b.x;
      var a = 1.0;
      var size = 3.2;
      var ox = 0.0;
      var oy = 0.0;
      if (t > 0) {
        final p = math.min(1.0, t / b.life);
        if (p >= 1) continue;
        ox = b.vx * t;
        oy = b.vy * t + 0.5 * b.gravity * t * t;
        a = 1 - p * p;
        size = 3.2 * (1 - p * 0.3);
        // A fiery trail behind the piece.
        paint.color = const ui.Color(0xFFFFB23E).withValues(alpha: a * 0.35);
        final trail = _screen(left + px + ox - b.vx * 0.035,
            top + b.y + oy - (b.vy + b.gravity * t) * 0.035, tl);
        canvas.drawRect(
            ui.Rect.fromLTWH(trail.dx, trail.dy, size * z, size * z), paint);
      }
      paint.color = b.color.withValues(alpha: a);
      final o = _screen(left + px + ox, top + b.y + oy, tl);
      canvas.drawRect(ui.Rect.fromLTWH(o.dx, o.dy, size * z, size * z), paint);
    }
  }

  void _renderLight(ui.Canvas canvas, Vector2 tl, Vector2 foot) {
    final t = story - BossDefeatTimes.medal;
    final p = math.min(1.0, t / 0.6);
    final fade = story > BossDefeatTimes.fade
        ? math.max(0.0, 1 - (story - BossDefeatTimes.fade) / 0.5)
        : 1.0;
    final c = _screen(foot.x, foot.y - stage.bossArtSize.y * 0.5, tl);
    final top = _screen(0, tl.y - 40, tl).dy;
    final ground = _screen(0, stage.groundY, tl).dy;
    final z = _zoom;
    final paint = ui.Paint();
    // Three beams from above.
    for (final b in const [(-26.0, 0.9), (0.0, 1.3), (30.0, 0.8)]) {
      final x = c.dx + b.$1 * z;
      paint.shader =
          ui.Gradient.linear(ui.Offset(x, top), ui.Offset(x, ground), [
        const ui.Color(0xFFFFECA0).withValues(alpha: 0),
        const ui.Color(0xFFFFE278).withValues(alpha: 0.55 * 0.5 * p * fade),
        const ui.Color(0xFFFFE278).withValues(alpha: 0.12 * 0.5 * p * fade),
      ], const [
        0,
        0.4,
        1
      ]);
      final path = ui.Path()
        ..moveTo(x - 6 * b.$2 * z, top)
        ..lineTo(x + 6 * b.$2 * z, top)
        ..lineTo(x + 22 * b.$2 * z, ground)
        ..lineTo(x - 22 * b.$2 * z, ground)
        ..close();
      canvas.drawPath(path, paint);
    }
    // Rays turning slowly.
    final r = 300 * z;
    final rot = t * 0.45;
    paint.shader = ui.Gradient.radial(c, r, [
      const ui.Color(0xFFFFE278).withValues(alpha: 0.42 * p * fade),
      const ui.Color(0x00FFE278),
    ]);
    for (var i = 0; i < 14; i++) {
      final a0 = rot + i * math.pi * 2 / 14;
      final a1 = a0 + 0.13;
      final path = ui.Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a0) * r, c.dy + math.sin(a0) * r)
        ..lineTo(c.dx + math.cos(a1) * r, c.dy + math.sin(a1) * r)
        ..close();
      canvas.drawPath(path, paint);
    }
    paint.shader = null;
  }

  void _renderHero(ui.Canvas canvas, Vector2 tl) {
    final sprite = stage.heroWinSprite;
    if (sprite == null) return;
    final t = story - BossDefeatTimes.medal;
    final hop = (math.sin(t * 7)).abs() * math.max(0.0, 1 - t / 1.3) * 26;
    final size =
        sprite.srcSize / 2.5; // art_scale.dart: 2.5 source pixels to a unit
    final foot = stage.heroFoot;
    final o = _screen(foot.x - size.x / 2, foot.y - size.y - hop, tl);
    sprite.render(canvas, position: Vector2(o.dx, o.dy), size: size * _zoom);
  }

  /// What is on the screen itself: dark edges, the banner, the flash, the gold, the medal.
  void _renderScreen(ui.Canvas canvas, Vector2 tl) {
    final w = stage.viewSize.x;
    final h = stage.viewSize.y;
    final paint = ui.Paint();
    final rect = ui.Rect.fromLTWH(0, 0, w, h);
    // Dark edges.
    if (_vignette > 0.01) {
      paint.shader =
          ui.Gradient.radial(ui.Offset(w / 2, h / 2), math.max(w, h) * 0.62, [
        const ui.Color(0x00000000),
        ui.Color.fromRGBO(0, 0, 0, _vignette.clamp(0.0, 1.0)),
      ], const [
        0.5,
        1
      ]);
      canvas.drawRect(rect, paint);
      paint.shader = null;
    }
    // The banner.
    if (_banner && story < BossDefeatTimes.fade + 0.35) {
      final t = story - BossDefeatTimes.banner;
      final scale = t < 0.12
          ? 0.3 + t / 0.12 * 0.9
          : (t < 0.2 ? 1.2 - (t - 0.12) * 2.5 : 1.0);
      final alpha = story > BossDefeatTimes.fade
          ? 1 - (story - BossDefeatTimes.fade) / 0.35
          : math.min(1.0, t / 0.1);
      _paintBanner(canvas, w, h, scale, alpha.clamp(0.0, 1.0));
    }
    // The flash.
    if (_flash > 0) {
      paint.color =
          const ui.Color(0xFFFFFFFF).withValues(alpha: math.min(1.0, _flash));
      canvas.drawRect(rect, paint);
    }
    // Gold over everything, and the medal on top of it.
    if (story > BossDefeatTimes.fade) {
      final p = math.min(
          1.0,
          (story - BossDefeatTimes.fade) /
              (BossDefeatTimes.end - BossDefeatTimes.fade));
      paint.color = const ui.Color(0xFFFFE9A6).withValues(alpha: p);
      canvas.drawRect(rect, paint);
    }
    if (_medal) _paintMedal(canvas, tl, w, h);
  }

  void _paintBanner(
      ui.Canvas canvas, double w, double h, double scale, double alpha) {
    final text = 'TALO NA ANG ${stage.bossName.toUpperCase()}!';
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.poppins(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: const ui.Color(0xFF2A1D05).withValues(alpha: alpha)),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final bw = tp.width + 56;
    final bh = tp.height + 18;
    canvas.save();
    canvas.translate(w / 2, h * 0.2);
    canvas.scale(scale);
    final r = ui.Rect.fromCenter(center: ui.Offset.zero, width: bw, height: bh);
    final fill = ui.Paint()
      ..color = const ui.Color(0xFFF2B632).withValues(alpha: alpha);
    final edge = ui.Paint()
      ..color = const ui.Color(0xFFB9821A).withValues(alpha: alpha);
    canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
            r.shift(const ui.Offset(0, 6)), const ui.Radius.circular(10)),
        edge);
    canvas.drawRRect(
        ui.RRect.fromRectAndRadius(r, const ui.Radius.circular(10)), fill);
    tp.paint(canvas, ui.Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  void _paintMedal(ui.Canvas canvas, Vector2 tl, double w, double h) {
    final t = story - BossDefeatTimes.medal;
    final foot = _bossFoot;
    final c0 = _screen(foot.x, foot.y - stage.bossArtSize.y * 0.5 - 34, tl);
    final start = _screen(foot.x, stage.groundY - 10, tl);
    final rise = _ease((t / 0.9).clamp(0.0, 1.0));
    var pos = ui.Offset(c0.dx, start.dy + (c0.dy - start.dy) * rise);
    var sc = (0.25 + 0.75 * _ease((t / 0.7).clamp(0.0, 1.0))) * _zoom;
    var spin = t * 5;
    if (story > BossDefeatTimes.fade) {
      final f = _ease(((story - BossDefeatTimes.fade) /
              (BossDefeatTimes.end - BossDefeatTimes.fade))
          .clamp(0.0, 1.0));
      const a0 = (BossDefeatTimes.fade - BossDefeatTimes.medal) * 5;
      final target = (a0 / (math.pi * 2)).ceil() * math.pi * 2 + math.pi * 2;
      spin = a0 + (target - a0) * f;
      pos = ui.Offset(
          pos.dx + (w / 2 - pos.dx) * f, pos.dy + (h / 2 - pos.dy) * f);
      sc = sc + (2.4 - sc) * f;
    } else {
      pos = pos.translate(0, math.sin(t * 3) * 3);
    }
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    final glow = ui.Paint()
      ..shader = ui.Gradient.radial(ui.Offset.zero, 60 * sc,
          [const ui.Color(0xCCFFE278), const ui.Color(0x00FFE278)]);
    canvas.drawCircle(ui.Offset.zero, 60 * sc, glow);
    canvas.scale(sc * math.max(0.12, math.cos(spin).abs()), sc);
    final gold = ui.Paint()
      ..shader = ui.Gradient.linear(
          const ui.Offset(-26, -26), const ui.Offset(26, 26), const [
        ui.Color(0xFFFFF0A8),
        ui.Color(0xFFF2B632),
        ui.Color(0xFFA8741A),
      ], const [
        0,
        0.5,
        1
      ]);
    canvas.drawCircle(ui.Offset.zero, 27, gold);
    canvas.drawCircle(
        ui.Offset.zero, 19.5, ui.Paint()..color = stage.medalColor);
    canvas.drawCircle(
        ui.Offset.zero,
        19.5,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const ui.Color(0x80FFFFFF));
    final star = ui.Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final r = i.isOdd ? 5.0 : 12.0;
      i == 0
          ? star.moveTo(math.cos(a) * r, math.sin(a) * r)
          : star.lineTo(math.cos(a) * r, math.sin(a) * r);
    }
    star.close();
    canvas.drawPath(star, ui.Paint()..color = const ui.Color(0xFFFFE98A));
    canvas.restore();
  }
}
