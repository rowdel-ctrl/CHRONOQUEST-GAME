import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/bonus_constants.dart';
import '../bonus_handler.dart';
import '../chrono_game.dart';

/// Where the portal is in its short life.
enum PortalPhase {
  /// Growing out of the spot the golden artifact was. Cannot be entered yet.
  opening,

  /// Open for [BonusConstants.portalSeconds]: walk into it.
  open,

  /// The hero has walked in and the bonus round is on screen. Held still.
  entering,

  /// Shrinking away, because the time ran out or the hero is back.
  closing,

  /// The hero is back from the round: the portal glows a moment, then closes.
  returning,

  /// Finished; about to be removed.
  gone,
}

/// The golden bonus portal, drawn as a glowing time vortex, that opens where a
/// golden artifact was, after its question is answered right on the first try
/// (the 2026-11 update).
///
/// It stands on the ground under the artifact for 5 seconds with a countdown ring
/// above it ("Pasok na! 5"). Walking into it (no button) starts the bonus round;
/// the time running out just closes it and the level goes on as normal. Every
/// timer is a per-frame one, so a question, the pause menu or the bonus round
/// itself (which holds the level still) freezes it with everything else.
class GoldenPortalComponent extends PositionComponent
    with HasGameReference<ChronoGame> {
  GoldenPortalComponent({required double centerX, required double surfaceY})
      : super(
          size:
              Vector2(BonusConstants.portalWidth, BonusConstants.portalHeight),
          position: Vector2(
            centerX - BonusConstants.portalWidth / 2,
            surfaceY - BonusConstants.portalHeight,
          ),
          priority: 3,
        );

  PortalPhase phase = PortalPhase.opening;

  /// Seconds left to walk in; counts down only while [phase] is open.
  double remaining = BonusConstants.portalSeconds;

  double _phaseTime = 0;
  double _clock = 0;

  /// How far the swirl has turned: time, but running faster while the hero is
  /// away in the round, so a change of speed never makes it jump.
  double _swirl = 0;

  /// The middle of the portal in world coordinates.
  Vector2 get worldCenter => position + size / 2;

  /// True when walking into it would start the round right now.
  bool get canEnter => phase == PortalPhase.open;

  /// Gone for good: either finished closing or removed.
  bool get isGone => phase == PortalPhase.gone;

  void _go(PortalPhase next) {
    phase = next;
    _phaseTime = 0;
  }

  /// The hero walked in: held in its bright state while the round is on screen.
  void beginEnter() => _go(PortalPhase.entering);

  /// The hero is back from the round.
  void beginReturn() => _go(PortalPhase.returning);

  /// Closes it early (nothing could show the round).
  void close() {
    if (phase == PortalPhase.closing || phase == PortalPhase.gone) return;
    _go(PortalPhase.closing);
  }

  /// Whether the middle of the hero's body is inside the doorway: near the
  /// portal's middle sideways, and the feet within its height.
  bool heroInside() {
    final p = game.player;
    final middle = p.position.x + p.size.x / 2;
    final feet = p.position.y + p.size.y;
    final top = position.y;
    final bottom = position.y + size.y + 30;
    return (middle - (position.x + size.x / 2)).abs() <=
            BonusConstants.portalEnterHalfWidth &&
        feet > top + 30 &&
        feet <= bottom;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _clock += dt;
    _phaseTime += dt;
    _swirl += dt * _swirlSpeed;
    switch (phase) {
      case PortalPhase.opening:
        if (_phaseTime >= BonusConstants.portalOpenSeconds) {
          _go(PortalPhase.open);
        }
      case PortalPhase.open:
        remaining -= dt;
        if (remaining <= 0) {
          remaining = 0;
          _go(PortalPhase.closing);
        } else if (heroInside()) {
          game.enterBonusPortal(this);
        }
      case PortalPhase.entering:
        break; // held still: nothing runs while away
      case PortalPhase.returning:
        if (_phaseTime >= BonusConstants.portalReturnGlowSeconds) {
          _go(PortalPhase.closing);
        }
      case PortalPhase.closing:
        if (_phaseTime >= BonusConstants.portalCloseSeconds) {
          _go(PortalPhase.gone);
          removeFromParent();
        }
      case PortalPhase.gone:
        break;
    }
  }

  @override
  void onRemove() {
    if (identical(game.bonus.portal, this)) game.bonus.portal = null;
    super.onRemove();
  }

  // ─── look ──────────────────────────────────────────────────────────────

  /// 0 closed, 1 fully open: grows with a little overshoot, shrinks smoothly.
  double get openness {
    switch (phase) {
      case PortalPhase.opening:
        final p =
            (_phaseTime / BonusConstants.portalOpenSeconds).clamp(0.0, 1.0);
        const c1 = 1.70158, c3 = c1 + 1;
        return 1 + c3 * pow(p - 1, 3) + c1 * pow(p - 1, 2);
      case PortalPhase.closing:
        final p =
            (_phaseTime / BonusConstants.portalCloseSeconds).clamp(0.0, 1.0);
        final e = p < .5 ? 2 * p * p : 1 - pow(-2 * p + 2, 2) / 2;
        return 1 - e;
      case PortalPhase.gone:
        return 0;
      case PortalPhase.open:
      case PortalPhase.entering:
      case PortalPhase.returning:
        return 1;
    }
  }

  /// 1 normally, 3 while the round is on screen, easing back to 1 on return.
  double get _swirlSpeed {
    switch (phase) {
      case PortalPhase.entering:
        return 3;
      case PortalPhase.returning:
        final p = (_phaseTime / BonusConstants.portalReturnGlowSeconds)
            .clamp(0.0, 1.0);
        return 3 - 2 * p;
      default:
        return 1;
    }
  }

  /// Extra glow: the flare while the hero is in the round and a fading one on return.
  double get bright {
    if (phase == PortalPhase.entering) return .6;
    if (phase == PortalPhase.returning) {
      return .5 *
          (1 -
              (_phaseTime / BonusConstants.portalReturnGlowSeconds)
                  .clamp(0.0, 1.0));
    }
    return 0;
  }

  static final Paint _fill = Paint();
  static final Paint _line = Paint()..style = PaintingStyle.stroke;
  final PortalVortexPainter _vortex = PortalVortexPainter();

  @override
  void render(Canvas canvas) {
    final sc = openness;
    if (sc <= .01) return;
    _vortex.paint(
      canvas,
      width: size.x,
      height: size.y,
      openness: sc,
      clock: _clock,
      swirl: _swirl,
      flash: bright,
      sinceOpen: _clock,
    );
    if (phase == PortalPhase.open || phase == PortalPhase.opening) {
      // Above the sparkles that orbit the vortex.
      _renderCountdown(canvas, Offset(size.x / 2, -88));
    }
  }

  // The countdown ring above the portal: a track, the gold arc that empties, the
  // seconds in the middle and "Pasok na!" over it.
  void _renderCountdown(Canvas canvas, Offset c) {
    final fade = phase == PortalPhase.opening
        ? (_phaseTime / BonusConstants.portalOpenSeconds).clamp(0.0, 1.0)
        : 1.0;
    final frac = (remaining / BonusConstants.portalSeconds).clamp(0.0, 1.0);
    const r = 30.0;
    canvas.saveLayer(Rect.fromCircle(center: c, radius: 120),
        Paint()..color = Colors.white.withValues(alpha: fade));
    _fill.color = const Color(0xD11E1606);
    canvas.drawCircle(c, r + 6, _fill);
    _line
      ..strokeWidth = 8
      ..color = const Color(0xFF4A3B12);
    canvas.drawCircle(c, r, _line);
    _line
      ..strokeCap = StrokeCap.round
      ..color = frac < .35 ? const Color(0xFFFF9A3C) : const Color(0xFFFFD34D);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -pi / 2,
        2 * pi * frac, false, _line);
    _line.strokeCap = StrokeCap.butt;
    final secs = max(1, remaining.ceil());
    final number = _label('$secs', 30, const Color(0xFFFFF3B0), null);
    number.paint(canvas, c + Offset(-number.width / 2, -19));
    final words = _label(
        'Pasok na!', 26, const Color(0xFFFFF3B0), const Color(0xFF3A2A00));
    words.paint(canvas, c + Offset(-words.width / 2, -r - 12 - 32));
    canvas.restore();
  }

  static final Map<String, _Label> _labels = {};

  /// A cached bold label; [outline] draws a dark edge behind it.
  static _Label _label(String text, double size, Color color, Color? outline) {
    final key = '$text|$size|${color.toARGB32()}|${outline?.toARGB32()}';
    return _labels.putIfAbsent(key, () => _Label(text, size, color, outline));
  }
}

/// One line of bold text, laid out once: an optional dark outline under the fill.
class _Label {
  late final TextPainter _fill;
  TextPainter? _edge;

  _Label(String text, double size, Color color, Color? outline) {
    TextPainter make(TextStyle style) => TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
        )..layout();
    _fill = make(
        TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: color));
    if (outline != null) {
      _edge = make(TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeJoin = StrokeJoin.round
          ..color = outline,
      ));
    }
  }

  double get width => _fill.width;

  void paint(Canvas canvas, Offset at) {
    _edge?.paint(canvas, at);
    _fill.paint(canvas, at);
  }
}

/// Draws the portal as a time vortex: a dark centre fading to violet and cyan, light
/// arms swirling in, sparks streaming to the middle, two clock hands, a ring of 60
/// ticks turning slowly, sparkles orbiting outside, a soft glow, a ring on the
/// floor and a shockwave when it opens. The same in every era.
///
/// Kept cheap for a phone: one instance reuses its paints, paths and gradient
/// shaders (a gradient is only rebuilt when its radius changes, so while the portal
/// stands open nothing is rebuilt), the ten swirl arms are the same unit spiral
/// path turned, and there is no layer. The light is added (BlendMode.plus) only
/// inside the body of the vortex.
class PortalVortexPainter {
  /// How far the vortex centre sits below the middle of the component, so its
  /// bottom edge dips just under the floor like the approved mockup.
  static const double centreDrop = 10;

  /// How far the soft glow reaches from the centre when fully open.
  static const double glowRadius = 190;

  static const int _arms = 5;
  static const int _sparks = 26;
  static const int _sparkles = 7;
  static const int _ticks = 60;

  final Paint _fill = Paint();
  final Paint _line = Paint()..style = PaintingStyle.stroke;
  final Path _bigTicks = Path();
  final Path _smallTicks = Path();

  /// One swirl arm for a vortex of radius 1: it is turned and scaled to draw all of them.
  static final Path _spiral = () {
    final p = Path();
    const n = 44;
    for (var k = 0; k <= n; k++) {
      final u = k / n;
      final a = u * 6.4;
      final r = .04 + u * .98;
      if (k == 0) {
        p.moveTo(cos(a) * r, sin(a) * r);
      } else {
        p.lineTo(cos(a) * r, sin(a) * r);
      }
    }
    return p;
  }();

  static const _violetGlow = [Color(0x8C8C6EFF), Color(0x003C28A0)];
  static const _goldGlow = [Color(0x59FFE18C), Color(0x00FFC850)];
  static const _body = [
    Color(0xFF05020F),
    Color(0xFF1B0E4D),
    Color(0xFF4A2BB3),
    Color(0xFF4FD0FF),
  ];
  static const _bodyStops = [0.0, .35, .75, 1.0];

  // One remembered gradient per use, rebuilt only when its radius changes.
  final List<double> _shaderRadius = [-1, -1, -1];
  final List<Shader?> _shader = [null, null, null];

  Shader _radial(int slot, double r, List<Color> colors,
      [List<double>? stops]) {
    if (_shader[slot] == null || _shaderRadius[slot] != r) {
      _shaderRadius[slot] = r;
      _shader[slot] = RadialGradient(colors: colors, stops: stops)
          .createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    }
    return _shader[slot]!;
  }

  /// Paints the vortex into a component [width] by [height] (feet at its bottom).
  ///
  /// [openness] 0..1 (a little over 1 while it pops open) scales everything about
  /// the centre; [clock] is plain seconds; [swirl] is the swirl's own clock (it runs
  /// faster while the round is on); [flash] is extra glow; [sinceOpen] drives the
  /// shockwave ring for its first 1.1 seconds. [glow] false leaves the two big soft
  /// discs out (used by the bounds test).
  void paint(
    Canvas canvas, {
    required double width,
    required double height,
    required double openness,
    required double clock,
    required double swirl,
    double flash = 0,
    double sinceOpen = 99,
    bool glow = true,
  }) {
    final sc = openness;
    if (sc <= .01) return;
    final rx = width / 2 * sc, ry = height / 2 * sc;
    final cx = width / 2, cy = height / 2 + centreDrop;
    final footRel = height + 2 - cy; // the floor line, from the centre

    canvas.save();
    canvas.translate(cx, cy);

    // Big soft glow and the ring on the floor.
    if (glow) {
      final violetR = glowRadius * sc * (1 + flash * .5);
      _fill.shader = _radial(0, violetR, _violetGlow);
      canvas.drawCircle(Offset.zero, violetR, _fill);
      final goldR = 120 * sc * (1 + flash);
      _fill.shader = _radial(1, goldR, _goldGlow);
      canvas.drawCircle(Offset.zero, goldR, _fill);
      _fill.shader = null;
    }
    _fill.color = const Color(0x59A08CFF);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, footRel + 3), width: rx * 2.2, height: 18 * sc),
        _fill);

    // The body: dark centre, violet to cyan edge, with the light inside it.
    canvas.save();
    canvas.clipPath(Path()
      ..addOval(
          Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2)));
    _fill.shader = _radial(2, ry, _body, _bodyStops);
    canvas.drawRect(Rect.fromLTRB(-rx, -ry, rx, ry), _fill);
    _fill.shader = null;

    _line
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.butt;
    _fill.blendMode = BlendMode.plus;
    // The swirl is drawn squeezed to the oval, as the mockup does.
    canvas.save();
    canvas.scale(rx / ry, 1);
    for (var arm = 0; arm < _arms; arm++) {
      for (var pass = 0; pass < 2; pass++) {
        final bright = pass == 1;
        canvas.save();
        canvas.rotate(arm * 1.2566 + swirl * 2.2 * (bright ? 1 : .9));
        canvas.scale(ry);
        _line
          ..strokeWidth = (bright ? 2 : 7) / ry
          ..color = bright
              ? const Color(0xD9FFFFFF)
              : (arm.isOdd ? const Color(0x595AE6FF) : const Color(0x59FFCD5A));
        canvas.drawPath(_spiral, _line);
        canvas.restore();
      }
    }
    // Sparks streaming to the middle.
    for (var i = 0; i < _sparks; i++) {
      final u = (i * .137 + swirl * .5) % 1;
      final a = i * 2.4 + u * 6.4;
      final r = (1 - u) * ry;
      _fill.color = Color.fromRGBO(255, 255, 255, .8 * (1 - u));
      canvas.drawRect(
          Rect.fromLTWH(cos(a) * r - 1.5, sin(a) * r - 1.5, 3, 3), _fill);
    }
    _line.blendMode = BlendMode.srcOver;
    _fill.blendMode = BlendMode.srcOver;
    // Two clock hands in the middle.
    _line
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xE6FFF5C8);
    canvas.drawLine(
        Offset.zero, Offset(cos(swirl * 3) * 22, sin(swirl * 3) * 22), _line);
    canvas.drawLine(
        Offset.zero, Offset(cos(swirl * .8) * 14, sin(swirl * .8) * 14), _line);
    canvas.restore(); // the squeeze
    canvas.restore(); // the clip

    // The ring of 60 clock ticks turning slowly, then the cyan edge.
    _bigTicks.reset();
    _smallTicks.reset();
    for (var i = 0; i < _ticks; i++) {
      final a = i / _ticks * 2 * pi + clock * .35;
      final big = i % 5 == 0;
      final r0 = 1.07 + (big ? 0 : .03), r1 = 1.14 + (big ? .04 : 0);
      final path = big ? _bigTicks : _smallTicks;
      path.moveTo(cos(a) * rx * r0, sin(a) * ry * r0);
      path.lineTo(cos(a) * rx * r1, sin(a) * ry * r1);
    }
    _line
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = 1.5
      ..color = const Color(0x99FFE6A0);
    canvas.drawPath(_smallTicks, _line);
    _line
      ..strokeWidth = 3
      ..color = const Color(0xFFFFF1A8);
    canvas.drawPath(_bigTicks, _line);
    _line.color = const Color(0xE682E6FF);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: rx * 2.08, height: ry * 2.08),
        _line);

    // Sparkles orbiting outside.
    for (var i = 0; i < _sparkles; i++) {
      final a = clock * .9 + i * .9;
      final d = 1.28 + .05 * sin(clock * 2 + i);
      _fill.color = Color.fromRGBO(255, 240, 170, .5 + .4 * sin(clock * 3 + i));
      canvas.drawCircle(Offset(cos(a) * rx * d, sin(a) * ry * d), 3, _fill);
    }

    // The shockwave ring on the floor while it opens.
    if (sinceOpen < 1.1) {
      final u = sinceOpen / 1.1;
      _line
        ..strokeWidth = 5 * (1 - u) + 1
        ..color = Color.fromRGBO(190, 170, 255, 1 - u);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(0, footRel - 2),
              width: (30 + u * 140) * 2,
              height: (6 + u * 22) * 2),
          _line);
    }
    canvas.restore();
  }
}
