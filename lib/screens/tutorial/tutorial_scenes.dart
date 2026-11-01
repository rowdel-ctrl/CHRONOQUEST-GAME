import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../models/control_scheme.dart';
import '../../widgets/action_disc.dart';
import '../../widgets/gate_icon.dart';
import '../../widgets/pixel_icon.dart';

/// The little pictures on the how-to-play pages. Each is a small copy of the play
/// screen made from the game's own pieces (the forest, the hero and soldier, the
/// red and blue bars, the Jump and Attack buttons, the gate) and loops by itself.
/// They are drawn on a 298 x 190 board and sit in a [SceneWindow]; every number
/// below is a position or a time on that board.

const double sceneW = 298;
const double sceneH = 190;

/// 0 before [start], 1 after [start] + [dur], a straight line between.
double _p(num ms, num start, num dur) =>
    ((ms - start) / dur).clamp(0.0, 1.0).toDouble();

double _lerp(double a, double b, double t) => a + (b - a) * t;

// ── The window ─────────────────────────────────────────────────────────────────

/// The frame the picture sits in: a dark pixel border, a hard shadow and a glow in
/// the page's colour.
class SceneWindow extends StatelessWidget {
  final Color glow;
  final List<Color> sky;
  final List<Widget> children;

  const SceneWindow({
    super.key,
    required this.glow,
    required this.children,
    this.sky = const [Color(0xFF2A2150), Color(0xFF46387A), Color(0xFF7662A8)],
  });

  static const double outerW = sceneW + 6;
  static const double outerH = sceneH + 6;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: outerW,
      height: outerH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.primaryDark, width: 3),
        boxShadow: [
          const BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 4)),
          BoxShadow(color: glow.withValues(alpha: 0.4), blurRadius: 26),
        ],
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: sky),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
            width: sceneW,
            height: sceneH,
            child: Stack(clipBehavior: Clip.hardEdge, children: children)),
      ),
    );
  }
}

// ── Pieces ─────────────────────────────────────────────────────────────────────

Widget _img(String path,
    {double? w,
    double? h,
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.center}) {
  return Image.asset(
    path,
    width: w,
    height: h,
    fit: fit,
    alignment: alignment,
    filterQuality: FilterQuality.none,
    gaplessPlayback: true,
    errorBuilder: (_, __, ___) => SizedBox(width: w, height: h),
  );
}

String _walk(String id, int ms, {int every = 140}) =>
    'assets/characters/${id}_walk_${(ms ~/ every) % 4 + 1}.png';

Widget _hero(String id, {String? path, double w = 43}) {
  return SizedBox(
      width: w,
      child: _img(path ?? 'assets/characters/${id}_walk_1.png',
          w: w, fit: BoxFit.fitWidth, alignment: Alignment.bottomCenter));
}

Widget _soldier(int ms) =>
    _img('assets/enemies/spanish_soldier_${(ms ~/ 250) % 2 + 1}.png',
        w: 41, h: 50, alignment: Alignment.bottomCenter);

/// The forest of the level: four layers, with the era's green wash over them.
class SceneForest extends StatelessWidget {
  final double seconds;
  final Color tint;

  const SceneForest(
      {super.key, this.seconds = 0, this.tint = const Color(0x665E8C3A)});

  static const _layers = [
    ('assets/backgrounds/parallax-forest-back-trees.png', 13.0),
    ('assets/backgrounds/parallax-forest-lights.png', 20.0),
    ('assets/backgrounds/parallax-forest-middle-trees.png', 32.0),
    ('assets/backgrounds/parallax-forest-front-trees.png', 54.0),
  ];
  static const double tileW = sceneH * 272 / 160;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final l in _layers)
            ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: double.infinity,
                child: Transform.translate(
                  offset: Offset(-((l.$2 * seconds) % tileW), 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++)
                        _img(l.$1, w: tileW, h: sceneH, fit: BoxFit.fill)
                    ],
                  ),
                ),
              ),
            ),
          ColoredBox(color: tint),
        ],
      ),
    );
  }
}

/// The ground strip: grass on top, earth in two tones that slide when the hero runs.
class SceneGround extends StatelessWidget {
  final double scroll;
  final bool boss;

  const SceneGround({super.key, this.scroll = 0, this.boss = false});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 44,
      child: CustomPaint(painter: _GroundPainter(scroll, boss)),
    );
  }
}

class _GroundPainter extends CustomPainter {
  final double scroll;
  final bool boss;
  const _GroundPainter(this.scroll, this.boss);

  @override
  void paint(Canvas canvas, Size size) {
    final a = Paint()
      ..color = boss ? const Color(0xFF4A2A2E) : const Color(0xFF5D4E37);
    final b = Paint()
      ..color = boss ? const Color(0xFF42262A) : const Color(0xFF54452F);
    canvas.drawRect(Offset.zero & size, a);
    final shift = scroll % 36;
    for (var x = -36 - shift; x < size.width; x += 36) {
      canvas.drawRect(Rect.fromLTWH(x + 18, 0, 18, size.height), b);
    }
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, 5),
        Paint()
          ..color = boss ? const Color(0xFF8A4A3A) : const Color(0xFF5AA845));
  }

  @override
  bool shouldRepaint(_GroundPainter old) =>
      old.scroll != scroll || old.boss != boss;
}

/// A row of equal segments, the first [filled] lit: the level's red and blue bars.
class SegBar extends StatelessWidget {
  final int segments;
  final int filled;
  final Color color;
  final double width;
  final double height;
  final double gap;
  final double border;
  final bool ring;
  final String? label;

  const SegBar({
    super.key,
    required this.segments,
    required this.filled,
    required this.color,
    required this.width,
    required this.height,
    this.gap = 1.2,
    this.border = 2,
    this.ring = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height > 10 ? 4 : 3),
        border: Border.all(color: AppColors.primaryDark, width: border),
        boxShadow: ring
            ? [
                const BoxShadow(color: Color(0xE6FFFFFF), spreadRadius: 2),
                BoxShadow(
                    color: color.withValues(alpha: 0.8),
                    blurRadius: 10,
                    spreadRadius: 1),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Row(
              children: [
                for (var i = 0; i < segments; i++)
                  Expanded(
                    child: Container(
                      margin:
                          EdgeInsets.only(right: i == segments - 1 ? 0 : gap),
                      color: i < filled ? color : Colors.black38,
                    ),
                  ),
              ],
            ),
            if (label != null)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(label!,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        shadows: const [
                          Shadow(blurRadius: 2, color: Colors.black)
                        ],
                      )),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The health bar with the Kaalaman bar hanging under it, as in the level; scaled
/// up on the pages that are about one of them.
class SceneHud extends StatelessWidget {
  final int hearts;
  final int kaalaman;
  final double scale;
  final String? ring; // 'hp' | 'kb'
  final int kaalamanSegments;

  const SceneHud(
      {super.key,
      required this.hearts,
      required this.kaalaman,
      this.scale = 1,
      this.ring,
      this.kaalamanSegments = 10});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 8,
      top: 8,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SegBar(
                segments: 5,
                filled: hearts,
                color: AppColors.danger,
                width: 78,
                height: 13,
                ring: ring == 'hp',
                label: '$hearts/5'),
            const SizedBox(height: 2.5),
            SegBar(
                segments: kaalamanSegments,
                filled: kaalaman,
                color: AppColors.info,
                width: 56,
                height: 7.5,
                border: 1.5,
                ring: ring == 'kb'),
          ],
        ),
      ),
    );
  }
}

/// The artifact counter at the top middle.
class ScenePill extends StatelessWidget {
  final String done;
  final bool ok;
  final double scale;

  const ScenePill(
      {super.key, required this.done, this.ok = false, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: ok ? Border.all(color: AppColors.success, width: 1.5) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _img('assets/collectibles/artifact_1.png', w: 12, h: 12),
            const SizedBox(width: 4),
            Text(done,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1.2)),
            Text('/10',
                style: GoogleFonts.poppins(
                    color: Colors.white70, fontSize: 7, height: 1.2)),
          ],
        ),
      ),
    );
  }
}

/// A small round chip that floats up and fades: "−1", "+2", "+1".
class FloatChip extends StatelessWidget {
  final String text;
  final Color color;
  final double progress;
  final String? icon;

  const FloatChip(
      {super.key,
      required this.text,
      required this.color,
      required this.progress,
      this.icon});

  @override
  Widget build(BuildContext context) {
    final p = progress;
    if (p <= 0 || p >= 1) return const SizedBox.shrink();
    final opacity = p < 0.2 ? p / 0.2 : (p < 0.7 ? 1.0 : 1 - (p - 0.7) / 0.3);
    final dy = p < 0.2 ? _lerp(6, 0, p / 0.2) : -14 * (p - 0.2) / 0.8;
    final scale = p < 0.2 ? _lerp(0.7, 1.1, p / 0.2) : 1.0;
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.primaryDark, width: 2),
              boxShadow: const [
                BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  _img(icon!, w: 11, h: 11),
                  const SizedBox(width: 3)
                ],
                Text(text,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlashPainter extends CustomPainter {
  const _SlashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primaryDark;
    canvas.drawArc(r, -math.pi * 0.95, math.pi * 0.95, false, edge);
    canvas.drawArc(
        r,
        -math.pi * 0.95,
        math.pi * 0.5,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = Colors.white);
    canvas.drawArc(
        r,
        -math.pi * 0.45,
        math.pi * 0.45,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFFFE9A0));
  }

  @override
  bool shouldRepaint(_SlashPainter old) => false;
}

/// The sword swing in front of the hero. [p] is 0..1 through one swing.
Widget _slash(double p, {double left = 128}) {
  final opacity = p < 0.1 ? p / 0.1 : (p < 0.48 ? 1.0 : 0.0);
  final angle =
      _lerp(-1.57, 0.44, _p(p, 0, 0.34)) + _lerp(0, 0.35, _p(p, 0.34, 0.14));
  final scale = _lerp(0.7, 1.1, _p(p, 0, 0.34));
  return Positioned(
    left: left,
    bottom: 62,
    child: Opacity(
      opacity: opacity,
      child: Transform.rotate(
          angle: angle,
          child: Transform.scale(
              scale: scale,
              child: const SizedBox(
                  width: 34,
                  height: 34,
                  child: CustomPaint(painter: _SlashPainter())))),
    ),
  );
}

/// A soldier that is hit: flashes white, swells and fades, then is gone. [p] 0..1.
Widget _hitSoldier(double left, int ms, double p) {
  double opacity = 1, scale = 1, dx = 0;
  var flash = false;
  if (p >= 0.18 && p < 0.34) {
    flash = true;
    scale = 1.08;
  } else if (p >= 0.34 && p < 0.88) {
    final k = _p(p, 0.34, 0.14);
    opacity = 1 - k;
    scale = _lerp(1.08, 1.22, k);
    dx = 8 * k;
    flash = true;
  } else if (p >= 0.88) {
    opacity = 0;
  }
  Widget s = _soldier(ms);
  if (flash) {
    s = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcATop),
        child: s);
  }
  return Positioned(
      left: left,
      bottom: 39,
      child: Opacity(
          opacity: opacity,
          child: Transform.translate(
              offset: Offset(dx, 0),
              child: Transform.scale(scale: scale, child: s))));
}

// ── Page 1: the buttons ───────────────────────────────────────────────────────

/// Which of the three things the picture is showing.
enum ControlAct { move, jump, attack }

class ControlsScene extends StatelessWidget {
  final String charId;
  final ControlScheme scheme;
  final ControlAct act;

  /// Milliseconds since this act began.
  final int local;

  /// Milliseconds on the whole clock, for the walking frames.
  final int ms;

  final ValueChanged<ControlAct> onTapControl;

  const ControlsScene({
    super.key,
    required this.charId,
    required this.scheme,
    required this.act,
    required this.local,
    required this.ms,
    required this.onTapControl,
  });

  @override
  Widget build(BuildContext context) {
    final moving = act == ControlAct.move;
    final jumping = act == ControlAct.jump;
    final attacking = act == ControlAct.attack;
    final hop = jumping ? _hump((local % 900) / 900) : 0.0;
    final heroPath = moving
        ? _walk(charId, ms)
        : jumping
            ? 'assets/characters/${charId}_jump.png'
            : 'assets/characters/${charId}_walk_1.png';
    final soldierLeft = 160 + (moving ? _lerp(40, 0, _p(local, 0, 2500)) : 0.0);
    return SceneWindow(
      glow: AppColors.accent,
      children: [
        SceneForest(seconds: moving ? local / 1000 : 0),
        SceneGround(scroll: moving ? local / 1000 * 40 : 0),
        const SceneHud(hearts: 4, kaalaman: 6),
        const Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(child: ScenePill(done: '0'))),
        Positioned(
            left: 92,
            bottom: 39 + 44 * hop,
            child: _hero(charId, path: heroPath)),
        if (attacking) _slash((local % 1250) / 1250),
        if (attacking)
          _hitSoldier(soldierLeft, ms, _p(local, 0, 2500))
        else
          Positioned(left: soldierLeft, bottom: 39, child: _soldier(ms)),
        // The controls, where they sit in a level.
        if (scheme == ControlScheme.arrows)
          Positioned(
            left: 10,
            bottom: 10,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTapControl(ControlAct.move),
              child: _Badged(number: 1, child: _arrowPair(rightOn: moving)),
            ),
          )
        else
          Positioned(
            left: 12,
            bottom: 8,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTapControl(ControlAct.move),
              child: _Badged(
                  number: 1,
                  child: _Stick(
                      nudge: moving
                          ? 10 * math.sin((local % 1200) / 1200 * math.pi)
                          : 0)),
            ),
          ),
        Positioned(
          right: 60,
          bottom: 8,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTapControl(ControlAct.jump),
            child: _Badged(
                number: 2,
                child: _PressedDisc(
                    kind: ActionDiscKind.jump, on: jumping, local: local)),
          ),
        ),
        Positioned(
          right: 14,
          bottom: 8,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTapControl(ControlAct.attack),
            child: _Badged(
                number: 3,
                child: _PressedDisc(
                    kind: ActionDiscKind.attack, on: attacking, local: local)),
          ),
        ),
      ],
    );
  }

  /// 0 on the ground, 1 at the top of the jump: up for a third, hold, back down.
  static double _hump(double p) => p < 0.35
      ? Curves.easeOut.transform(p / 0.35)
      : (p < 0.62 ? 1.0 : Curves.easeIn.transform(1 - (p - 0.62) / 0.38));
}

class _Badged extends StatelessWidget {
  final int number;
  final Widget child;
  const _Badged({required this.number, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      child,
      Positioned(top: -9, right: -5, child: NumberBadge(number))
    ]);
  }
}

/// The small gold number that ties a button to its line of text.
class NumberBadge extends StatelessWidget {
  final int number;
  const NumberBadge(this.number, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryDark, width: 2),
      ),
      child: Text('$number',
          style: GoogleFonts.poppins(
              color: AppColors.primaryDark,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              height: 1)),
    );
  }
}

class _Stick extends StatelessWidget {
  final double nudge;
  const _Stick({required this.nudge});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.3))),
          Transform.translate(
            offset: Offset(nudge, 0),
            child: Container(
                width: 23,
                height: 23,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.82))),
          ),
        ],
      ),
    );
  }
}

/// The two arrow buttons of the "arrows" setting.
class ArrowPair extends StatelessWidget {
  final double size;
  final bool rightOn;
  const ArrowPair({super.key, this.size = 36, this.rightOn = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: size * 2.15,
        height: size,
        child: CustomPaint(painter: _ArrowPainter(rightOn)));
  }
}

Widget _arrowPair({required bool rightOn}) =>
    ArrowPair(size: 36, rightOn: rightOn);

class _ArrowPainter extends CustomPainter {
  final bool rightOn;
  const _ArrowPainter(this.rightOn);

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.height;
    for (var k = 0; k < 2; k++) {
      final cx = d / 2 + k * (d + d * 0.15);
      final on = k == 1 ? rightOn : false;
      canvas.drawCircle(Offset(cx, d / 2), d / 2,
          Paint()..color = Colors.white.withValues(alpha: on ? 0.65 : 0.35));
      final dir = k == 1 ? 1.0 : -1.0;
      final path = Path()
        ..moveTo(cx - 0.28 * dir * d / 2, d / 2 - 0.45 * d / 2)
        ..lineTo(cx + 0.5 * dir * d / 2, d / 2)
        ..lineTo(cx - 0.28 * dir * d / 2, d / 2 + 0.45 * d / 2)
        ..close();
      canvas.drawPath(path, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.rightOn != rightOn;
}

class _PressedDisc extends StatelessWidget {
  final ActionDiscKind kind;
  final bool on;
  final int local;
  const _PressedDisc(
      {required this.kind, required this.on, required this.local});

  @override
  Widget build(BuildContext context) {
    final ripple = on ? (local % 900) / 900 : 0.0;
    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (on)
            Opacity(
              opacity: 0.9 * (1 - ripple),
              child: Transform.scale(
                  scale: 1 + 0.7 * ripple,
                  child: Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)))),
            ),
          Transform.scale(
              scale: on ? 0.93 : 1,
              child: ActionDisc(kind: kind, size: 38, alpha: on ? 1 : 0.86)),
        ],
      ),
    );
  }
}

// ── Page 2: artifact, question, counter, gate ───────────────────────────────

class FlowScene extends StatelessWidget {
  final String charId;
  final int ms;
  const FlowScene({super.key, required this.charId, required this.ms});

  static const _labels = [
    'LAPITAN ANG ARTIFACT',
    'SUMAGOT NG TANONG',
    'NASAGOT ANG LAHAT',
    'BUKAS ANG GATE!'
  ];

  @override
  Widget build(BuildContext context) {
    final step = (ms % 8000) ~/ 2000;
    final tiles = <Widget>[];
    for (var i = 0; i < 4; i++) {
      final on = i == step;
      final done = i < step;
      if (i > 0) {
        tiles.add(SizedBox(
          width: 13,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 26),
            child: Center(
                child: PixelIcon(PixelGlyph.chevron,
                    size: 11,
                    color: i <= step
                        ? AppColors.accent
                        : const Color(0x59F5E3BE))),
          ),
        ));
      }
      tiles.add(Expanded(
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: on ? const Offset(0, -0.02) : Offset.zero,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: on ? 1 : (done ? 0.92 : 0.5),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color:
                              on ? AppColors.accent : const Color(0x47F5E3BE),
                          width: 2),
                      gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF2E2350), Color(0xFF3B2D66)]),
                      boxShadow: on
                          ? [
                              BoxShadow(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.5),
                                  blurRadius: 12)
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(fit: StackFit.expand, children: [
                        _tile(i, on || done, ms),
                        Positioned(left: 4, top: 4, child: _smallNumber(i + 1))
                      ]),
                    ),
                  ),
                ),
                SizedBox(
                  height: 21,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(_labels[i],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 8,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: on
                                ? AppColors.accent
                                : const Color(0xFFCDBA94))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
    }
    return SceneWindow(
      glow: const Color(0xFFA77BFF),
      sky: const [Color(0xFF1B1430), Color(0xFF2B2048)],
      children: [
        Positioned(
            left: 6,
            right: 6,
            top: 10,
            bottom: 8,
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: tiles))
      ],
    );
  }

  static Widget _smallNumber(int n) => Container(
        width: 13,
        height: 13,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryDark, width: 2)),
        child: Text('$n',
            style: GoogleFonts.poppins(
                fontSize: 7.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
                height: 1)),
      );

  Widget _tile(int i, bool lit, int ms) {
    switch (i) {
      case 0:
        return Stack(children: [
          Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 26,
              child: Container(
                  decoration: const BoxDecoration(
                      color: Color(0xFF5D4E37),
                      border: Border(
                          top: BorderSide(
                              color: Color(0xFF5AA845), width: 4))))),
          Positioned(
              right: -6,
              top: 22,
              child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppColors.accent.withValues(alpha: 0.7),
                        AppColors.accent.withValues(alpha: 0)
                      ])))),
          Positioned(
              left: 3,
              bottom: 20,
              child: SizedBox(
                  width: 32,
                  child: _img(_walk(charId, ms),
                      w: 32,
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.bottomCenter))),
          Positioned(
              right: 4,
              top: 34 + 3 * math.sin(ms / 1600 * 2 * math.pi),
              child: _img('assets/collectibles/artifact_1.png', w: 30, h: 30)),
        ]);
      case 1:
        return Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: 4,
            right: 4,
            top: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.primaryDark, width: 2),
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.primaryDark, offset: Offset(2, 2))
                  ]),
              child: Column(children: [
                _bar(1),
                const SizedBox(height: 3.5),
                _bar(0.66),
                const SizedBox(height: 7),
                for (var k = 0; k < 4; k++) ...[
                  Expanded(child: _answer(k == 1)),
                  if (k < 3) const SizedBox(height: 3.5)
                ],
              ]),
            ),
          ),
          Positioned(
              right: 2,
              top: 2,
              child: FloatChip(
                  text: '+2',
                  color: AppColors.info,
                  progress: lit ? _p(ms % 8000, 2300, 1400) : 0)),
        ]);
      case 2:
        final all = lit;
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ScenePill(done: all ? '10' : '9', ok: all, scale: 1.15),
            const SizedBox(height: 14),
            GateIcon(size: 42, unlocked: all),
          ]),
        );
      default:
        return Stack(children: [
          Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 26,
              child: Container(
                  decoration: const BoxDecoration(
                      color: Color(0xFF5D4E37),
                      border: Border(
                          top: BorderSide(
                              color: Color(0xFF5AA845), width: 4))))),
          if (lit)
            Positioned(
                left: 0,
                right: 0,
                bottom: 14,
                child: Center(
                    child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              const Color(0xFFFFD666).withValues(alpha: 0.5),
                              const Color(0x00FFD666)
                            ]))))),
          Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: Center(child: GateIcon(size: 56, unlocked: lit))),
        ]);
    }
  }

  static Widget _bar(double f) => Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
          widthFactor: f,
          child: Container(
              height: 3.5,
              decoration: BoxDecoration(
                  color: const Color(0xFFB58F5C),
                  borderRadius: BorderRadius.circular(2)))));

  static Widget _answer(bool right) => Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: right ? AppColors.success : const Color(0xFFE8CE9C),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
                color: right ? AppColors.primaryDark : const Color(0xFFA9855C),
                width: 1.2)),
        child: right
            ? const Icon(Icons.check_rounded, size: 10, color: Colors.white)
            : null,
      );
}

// ── Page 3: Kaalaman ──────────────────────────────────────────────────────────

class KaalamanScene extends StatelessWidget {
  final String charId;
  final int ms;
  const KaalamanScene({super.key, required this.charId, required this.ms});

  @override
  Widget build(BuildContext context) {
    final u = ms % 7600;
    final kaalaman = u < 1500 ? 6 : (u < 4000 ? 5 : (u < 4400 ? 6 : 7));
    final fade = math.min(_p(u, 0, 300), 1 - _p(u, 7100, 350));
    final foeAlive = u < 1100;
    final hitting = u >= 1100 && u < 2900;
    final artifact = u >= 2900 && u < 4000
        ? Curves.easeOut.transform(_p(u, 2900, 500))
        : (u >= 4000 && u < 4800
            ? 1 - Curves.easeIn.transform(_p(u, 4000, 800))
            : 0.0);
    return SceneWindow(
      glow: AppColors.info,
      children: [
        const SceneForest(),
        const SceneGround(),
        Positioned.fill(
          child: Opacity(
            opacity: fade,
            child: Stack(children: [
              SceneHud(hearts: 5, kaalaman: kaalaman, scale: 1.5, ring: 'kb'),
              Positioned(
                left: 100,
                top: 32,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.primaryDark.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(99)),
                  child: Text('KAALAMAN',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          height: 1.2)),
                ),
              ),
              Positioned(left: 62, bottom: 39, child: _hero(charId)),
              if (hitting) _slash(((u - 1100) % 1250) / 1250, left: 100),
              if (foeAlive)
                Positioned(left: 118, bottom: 39, child: _soldier(ms))
              else if (hitting)
                _hitSoldier(118, ms, _p(u, 1100, 1900)),
              if (artifact > 0)
                Positioned(
                  left: 214,
                  bottom: 60 + (u >= 4000 ? 40 * (1 - artifact) : 0),
                  child: Opacity(
                    opacity: artifact.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: u < 3400 ? artifact : (u >= 4000 ? artifact : 1),
                      child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(colors: [
                                      AppColors.accent.withValues(alpha: 0.75),
                                      AppColors.accent.withValues(alpha: 0)
                                    ]))),
                            _img('assets/collectibles/artifact_1.png',
                                w: 30, h: 30),
                          ]),
                    ),
                  ),
                ),
              Positioned(
                  left: 122,
                  top: 80,
                  child: FloatChip(
                      text: '−1',
                      color: AppColors.info,
                      progress: _p(u, 1600, 1400))),
              Positioned(
                  left: 212,
                  top: 66,
                  child: FloatChip(
                      text: '+2',
                      color: AppColors.info,
                      progress: _p(u, 4250, 1400))),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Page 4: hearts ────────────────────────────────────────────────────────────

class HeartScene extends StatelessWidget {
  final String charId;
  final int ms;
  const HeartScene({super.key, required this.charId, required this.ms});

  @override
  Widget build(BuildContext context) {
    final u = ms % 9200;
    final hearts = (u >= 1700 && u < 6600) ? 4 : 5;
    final fade = math.min(_p(u, 0, 300), 1 - _p(u, 8700, 350));
    var foeDx = 0.0;
    var foeOpacity = 1.0;
    if (u < 1500) {
      foeDx = _lerp(90, 0, Curves.easeOut.transform(_p(u, 0, 1500)));
    } else if (u < 2000) {
      foeDx = 0;
    } else if (u < 3300) {
      final k = Curves.easeIn.transform(_p(u, 2000, 1300));
      foeDx = 110 * k;
      foeOpacity = 1 - k;
    } else {
      foeOpacity = 0;
    }
    final hurt = u >= 1500 && u < 2200;
    final knock = hurt ? _lerp(-12, -6, _p(u, 1500, 700)) : 0.0;
    final clockOn = u >= 2600 && u < 8300;
    var clock = '1:00';
    if (u >= 2600 && u < 6600) {
      final r = 60 - (60 * (u - 2600) / 4000).floor();
      clock = '${r ~/ 60}:${(r % 60).toString().padLeft(2, '0')}';
    } else if (u >= 6600) {
      clock = '0:00';
    }
    final vignette = u >= 1500 && u < 2200
        ? math.sin(_p(u, 1500, 700) * math.pi).clamp(0.0, 1.0)
        : 0.0;
    return SceneWindow(
      glow: AppColors.danger,
      children: [
        const SceneForest(),
        const SceneGround(),
        Positioned.fill(
          child: Opacity(
            opacity: fade,
            child: Stack(children: [
              SceneHud(hearts: hearts, kaalaman: 6, scale: 1.5, ring: 'hp'),
              Positioned(
                left: 8,
                top: 50,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: clockOn ? 1 : 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                          color: u >= 6600
                              ? const Color(0xFF8FE08A)
                              : AppColors.accent.withValues(alpha: 0.7),
                          width: 1.5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      PixelIcon(PixelGlyph.clock,
                          size: 10,
                          color: u >= 6600
                              ? const Color(0xFF8FE08A)
                              : AppColors.accent),
                      const SizedBox(width: 4),
                      Text(clock,
                          style: GoogleFonts.poppins(
                              color: u >= 6600
                                  ? const Color(0xFF8FE08A)
                                  : Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              height: 1.2)),
                    ]),
                  ),
                ),
              ),
              Positioned(
                  left: 70 + knock,
                  bottom: 39,
                  child: _hero(charId,
                      path: hurt
                          ? 'assets/characters/${charId}_hurt.png'
                          : null)),
              if (foeOpacity > 0)
                Positioned(
                    left: 114 + foeDx,
                    bottom: 39,
                    child: Opacity(opacity: foeOpacity, child: _soldier(ms))),
              IgnorePointer(
                child: Opacity(
                  opacity: vignette,
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: RadialGradient(radius: 0.9, colors: [
                    Colors.transparent,
                    AppColors.danger.withValues(alpha: 0.75)
                  ], stops: const [
                    0.55,
                    1
                  ]))),
                ),
              ),
              Positioned(
                  left: 72,
                  top: 70,
                  child: FloatChip(
                      text: '−1',
                      color: AppColors.danger,
                      icon: 'assets/ui/heart_full.png',
                      progress: _p(u, 1700, 1400))),
              Positioned(
                  left: 140,
                  top: 12,
                  child: FloatChip(
                      text: '+1',
                      color: AppColors.success,
                      icon: 'assets/ui/heart_full.png',
                      progress: _p(u, 6700, 1400))),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Page 5: coins and the shop ────────────────────────────────────────────────

class ShopScene extends StatelessWidget {
  final int ms;
  const ShopScene({super.key, required this.ms});

  static const _cards = [
    (
      '50/50',
      'Tanggal 2 mali',
      15,
      Color(0xFF7E5CE6),
      'assets/powerups/fifty_fifty.png'
    ),
    (
      'SHIELD',
      'Salo ng 1 mali',
      25,
      Color(0xFF4F8FE6),
      'assets/powerups/shield.png'
    ),
    (
      'TIME FREEZE',
      'Hinto ang oras',
      30,
      Color(0xFF55C8E8),
      'assets/powerups/time_freeze.png'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const loop = 3600;
    final m = ms % loop;
    final coins = 62 +
        (ms ~/ loop) * 3 +
        (m >= 1100 ? math.min(3, (m - 1100) ~/ 280 + 1) : 0);
    return SceneWindow(
      glow: AppColors.success,
      sky: const [Color(0xFF1B1430), Color(0xFF2B2048)],
      children: [
        Positioned(
          left: 8,
          right: 8,
          top: 6,
          height: 20,
          child: Stack(alignment: Alignment.center, children: [
            Text('TINDAHAN',
                style: GoogleFonts.poppins(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4)),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent, width: 2)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _img('assets/collectibles/coin.png', w: 12, h: 12),
                  const SizedBox(width: 5),
                  Text('$coins',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.2)),
                ]),
              ),
            ),
          ]),
        ),
        Positioned(
          left: 8,
          right: 8,
          top: 34,
          bottom: 9,
          child: Row(children: [
            for (var i = 0; i < _cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 7),
              Expanded(child: _card(_cards[i])),
            ],
          ]),
        ),
        for (var i = 0; i < 3; i++) _flyingCoin(m, i),
      ],
    );
  }

  Widget _card((String, String, int, Color, String) c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(3, 7, 3, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primaryDark, width: 2.5),
        boxShadow: const [
          BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 3))
        ],
        gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2B1F42), Color(0xFF1B1230)]),
      ),
      child: Column(children: [
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          c.$4.withValues(alpha: 0.5),
                          c.$4.withValues(alpha: 0)
                        ]))),
                _img(c.$5, w: 36, h: 36),
              ]),
        ),
        const SizedBox(height: 4),
        FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(c.$1,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4))),
        const SizedBox(height: 2),
        SizedBox(
            height: 24,
            child: Text(c.$2,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color: const Color(0xFFCDBA94),
                    fontSize: 8.6,
                    height: 1.2,
                    fontWeight: FontWeight.w500))),
        const Spacer(),
        Container(
          height: 19,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.primaryDark, width: 2.5),
              boxShadow: const [
                BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 3))
              ]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _img('assets/collectibles/coin.png', w: 10, h: 10),
            const SizedBox(width: 4),
            Text('${c.$3}',
                style: GoogleFonts.poppins(
                    color: AppColors.primaryDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.1)),
          ]),
        ),
      ]),
    );
  }

  /// A coin flies from the lower left, over the cards, to the coin count.
  Widget _flyingCoin(int m, int i) {
    final p = _p(m, i * 280.0, 1100);
    if (p <= 0 || p >= 1) return const SizedBox.shrink();
    final x = _lerp(-14, 272, Curves.easeInOut.transform(p));
    final y = _lerp(160, 14, Curves.easeInOut.transform(p)) -
        70 * math.sin(p * math.pi);
    return Positioned(
        left: x,
        top: y,
        child: _img('assets/collectibles/coin.png', w: 12, h: 12));
  }
}

// ── Page 6: the boss ──────────────────────────────────────────────────────────

class BossScene extends StatelessWidget {
  final String charId;
  final int ms;
  const BossScene({super.key, required this.charId, required this.ms});

  @override
  Widget build(BuildContext context) {
    final u = ms % 7600;
    double w;
    var frozen = false;
    if (u < 2400) {
      w = _lerp(1, 0.62, u / 2400);
    } else if (u < 4800) {
      w = 0.62;
      frozen = true;
    } else {
      w = _lerp(0.62, 0.24, (u - 4800) / 2800);
    }
    final low = !frozen && w < 0.4;
    final barColor = frozen
        ? const Color(0xFF8FDFFF)
        : (low ? AppColors.warning : AppColors.success);
    return SceneWindow(
      glow: const Color(0xFFFF7A2A),
      sky: const [Color(0xFF2A0F1A), Color(0xFF4A1B2A), Color(0xFF7A3038)],
      children: [
        const SceneForest(tint: Color(0x946E1222)),
        const SceneGround(boss: true),
        Positioned(
          top: 7,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: 190,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SegBar(
                    segments: 22,
                    filled: 15,
                    color: AppColors.danger,
                    width: 190,
                    height: 12,
                    gap: 0.8),
                const SizedBox(height: 2),
                Text('Tamang sagot: 7/22',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        shadows: const [
                          Shadow(blurRadius: 3, color: Colors.black)
                        ])),
              ]),
            ),
          ),
        ),
        Positioned(
            right: 10,
            bottom: 38 + 3 * math.sin(ms / 2400 * 2 * math.pi),
            child: _img('assets/bosses/bakunawa_idle.png',
                w: 86, h: 96, alignment: Alignment.bottomCenter)),
        Positioned(left: 156, bottom: 39, child: _hero(charId)),
        Positioned(
          left: 9,
          top: 40,
          width: 132,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: AppColors.primaryDark, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.primaryDark, offset: Offset(3, 3))
                  ]),
              child: Column(children: [
                _line(1),
                const SizedBox(height: 3),
                _line(0.62),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(child: _ans()),
                  const SizedBox(width: 3),
                  Expanded(child: _ans())
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  Expanded(child: _ans()),
                  const SizedBox(width: 3),
                  Expanded(child: _ans())
                ]),
              ]),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: Container(
                  height: 9,
                  decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: AppColors.primaryDark, width: 2),
                      boxShadow: frozen
                          ? const [
                              BoxShadow(color: Color(0xFF8FDFFF), blurRadius: 8)
                            ]
                          : null),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                              widthFactor: w,
                              child: ColoredBox(color: barColor)))),
                ),
              ),
              const SizedBox(width: 6),
              AnimatedScale(
                duration: const Duration(milliseconds: 150),
                scale: frozen ? 1.12 : 1,
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF55C8E8), width: 2),
                      boxShadow: frozen
                          ? const [
                              BoxShadow(
                                  color: Color(0xFF8FDFFF), blurRadius: 12)
                            ]
                          : null),
                  child: _img('assets/powerups/time_freeze.png', w: 16, h: 16),
                ),
              ),
            ]),
            SizedBox(
              height: 14,
              child: frozen
                  ? Center(
                      child: Text('HINTO ANG ORAS!',
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF8FDFFF),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              height: 1.4,
                              shadows: const [
                                Shadow(
                                    color: AppColors.primaryDark,
                                    offset: Offset(0, 1.5))
                              ])))
                  : null,
            ),
          ]),
        ),
      ],
    );
  }

  static Widget _line(double f) => Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
          widthFactor: f,
          child: Container(
              height: 3.5,
              decoration: BoxDecoration(
                  color: const Color(0xFFB58F5C),
                  borderRadius: BorderRadius.circular(2)))));

  static Widget _ans() => Container(
      height: 11,
      decoration: BoxDecoration(
          color: const Color(0xFFE8CE9C),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0xFFA9855C), width: 1.2)));
}
