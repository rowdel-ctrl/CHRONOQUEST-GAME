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

/// The golden portal that opens where a golden artifact was, after its question
/// is answered right on the first try (the 2026-11 update).
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
          size: Vector2(
              BonusConstants.portalWidth, BonusConstants.portalHeight),
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
    switch (phase) {
      case PortalPhase.opening:
        if (_phaseTime >= BonusConstants.portalOpenSeconds) _go(PortalPhase.open);
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
        final p = (_phaseTime / BonusConstants.portalOpenSeconds).clamp(0.0, 1.0);
        const c1 = 1.70158, c3 = c1 + 1;
        return 1 + c3 * pow(p - 1, 3) + c1 * pow(p - 1, 2);
      case PortalPhase.closing:
        final p = (_phaseTime / BonusConstants.portalCloseSeconds).clamp(0.0, 1.0);
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

  /// Extra glow: the flare while the hero is in the round and a fading one on return.
  double get bright {
    if (phase == PortalPhase.entering) return .6;
    if (phase == PortalPhase.returning) {
      return .5 * (1 - (_phaseTime / BonusConstants.portalReturnGlowSeconds).clamp(0.0, 1.0));
    }
    return 0;
  }

  static final Paint _fill = Paint();
  static final Paint _line = Paint()..style = PaintingStyle.stroke;
  static final Paint _star = Paint();

  @override
  void render(Canvas canvas) {
    final sc = openness;
    if (sc <= .01) return;
    final cx = size.x / 2, cy = size.y / 2;
    final rx = size.x / 2 * sc, ry = size.y / 2 * sc;
    final t = _clock;

    // Glow behind everything.
    final glowR = 150 * sc * (1 + bright);
    _fill.shader = const RadialGradient(
      colors: [Color(0xBFFFE278), Color(0x00FFC83C)],
    ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: glowR));
    canvas.drawCircle(Offset(cx, cy), glowR, _fill);
    _fill.shader = null;

    // The golden disc with its swirl, clipped to the ellipse.
    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2)));
    _fill.shader = const RadialGradient(
      colors: [Color(0xFFFFFBE0), Color(0xFFFFD24A), Color(0xFFD9791C)],
      stops: [0, .45, 1],
    ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: max(ry, 1)));
    canvas.drawRect(Rect.fromLTWH(cx - rx, cy - ry, rx * 2, ry * 2), _fill);
    _fill.shader = null;
    canvas.translate(cx, cy);
    canvas.scale(rx / max(ry, 1), 1);
    _line
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.butt;
    for (var arm = 0; arm < 4; arm++) {
      final path = Path();
      for (var k = 0; k <= 36; k++) {
        final u = k / 36;
        final a = arm * pi / 2 + t * 3.2 + u * 5.2;
        final r = u * ry * 1.05;
        final x = cos(a) * r, y = sin(a) * r;
        if (k == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      _line.color = arm.isOdd ? const Color(0xD9FFFFFF) : const Color(0x8CFFF8C8);
      canvas.drawPath(path, _line);
    }
    canvas.restore();

    // Three dashed rings turning against each other.
    _line.strokeWidth = 4;
    const rings = [
      (1.0, Color(0xFFFFF1A8), 1.0),
      (1.2, Color(0xFFFFC83D), -1.3),
      (1.42, Color(0xFFFF9A3C), 1.7),
    ];
    for (var i = 0; i < rings.length; i++) {
      final (m, color, speed) = rings[i];
      _line.color = color.withValues(alpha: .95 - i * .2);
      final rect = Rect.fromCenter(
          center: Offset(cx, cy), width: rx * 2 * m, height: ry * 2 * m);
      const dash = .2, gap = .15;
      final offset = t * speed * .55;
      for (var a = offset; a < offset + 2 * pi - 1e-6; a += dash + gap) {
        canvas.drawArc(rect, a, dash, false, _line);
      }
    }

    // Sparkles orbiting outside.
    for (var i = 0; i < 12; i++) {
      final a = t * (1 + (i % 3) * .3) + i * 2.4;
      final m = 1.5 + (i % 4) * .08;
      final alpha = (.5 + .5 * sin(t * 6 + i)).clamp(0.0, 1.0) * sc.clamp(0.0, 1.0);
      _drawStar(canvas, cx + cos(a) * rx * m, cy + sin(a) * ry * m,
          5.0 + (i % 3) * 2, alpha, const Color(0xFFFFF3B0));
    }

    if (phase == PortalPhase.open || phase == PortalPhase.opening) {
      _renderCountdown(canvas, Offset(cx, -58));
    }
  }

  /// An eight-pointed twinkle, like the artifact's.
  void _drawStar(Canvas canvas, double x, double y, double r, double alpha, Color color) {
    if (alpha <= 0) return;
    _star.color = color.withValues(alpha: alpha);
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final rr = i.isOdd ? r * .25 : r;
      final an = i * pi / 4;
      final px = x + cos(an) * rr, py = y + sin(an) * rr;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, _star);
  }

  // The countdown ring above the portal: a track, the gold arc that empties, the
  // seconds in the middle and "Pasok na!" over it.
  void _renderCountdown(Canvas canvas, Offset c) {
    final fade = phase == PortalPhase.opening
        ? (_phaseTime / BonusConstants.portalOpenSeconds).clamp(0.0, 1.0)
        : 1.0;
    final frac = (remaining / BonusConstants.portalSeconds).clamp(0.0, 1.0);
    const r = 30.0;
    canvas.saveLayer(
        Rect.fromCircle(center: c, radius: 120),
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
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -pi / 2, 2 * pi * frac,
        false, _line);
    _line.strokeCap = StrokeCap.butt;
    final secs = max(1, remaining.ceil());
    final number = _label('$secs', 30, const Color(0xFFFFF3B0), null);
    number.paint(canvas, c + Offset(-number.width / 2, -19));
    final words = _label('Pasok na!', 26, const Color(0xFFFFF3B0), const Color(0xFF3A2A00));
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
