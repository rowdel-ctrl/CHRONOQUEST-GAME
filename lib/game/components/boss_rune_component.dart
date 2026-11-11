import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/boss_attack_constants.dart';
import '../chrono_game.dart';
import 'boss_attack_paint.dart' show star;

/// The purple rune of a boss fight: it appears on the floor away from the student, and walking
/// up to it makes the boss throw (see BossComponent). Drawn in code: a glowing diamond with a
/// question mark, a light column up to the top of the view so it can be found from across the
/// room, a ring on the floor and a few sparks. Not the golden artifact: that one is a reward.
///
/// Counted in [update] with the frame's `dt`, and gone by itself once [collect]ed.
class BossRuneComponent extends PositionComponent with HasGameReference<ChronoGame> {
  /// [x] is the rune's middle, [surfaceY] the floor it stands on (both in world units).
  BossRuneComponent({required double x, required this.surfaceY})
      : super(position: Vector2(x, surfaceY), priority: 8);

  /// The floor under the rune.
  final double surfaceY;

  double _age = 0;
  double _taken = -1;

  /// World x of the rune's middle.
  double get centreX => position.x;

  /// 0 as it appears, 1 once it has fully grown. Drops back to 0 while it vanishes.
  double get scale01 {
    final born = (_age / BossAttackConstants.runeBornSeconds).clamp(0.0, 1.0);
    final gone = _taken < 0
        ? 1.0
        : (1 - _taken / BossAttackConstants.runeTakenSeconds).clamp(0.0, 1.0);
    return born * gone;
  }

  /// Whether it has been touched (it is vanishing).
  bool get collected => _taken >= 0;

  /// The student touched it: it vanishes.
  void collect() {
    if (_taken < 0) _taken = 0;
  }

  /// It vanishes without being touched (the boss lost patience).
  void fade() => collect();

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_taken >= 0) {
      _taken += dt;
      if (_taken >= BossAttackConstants.runeTakenSeconds) removeFromParent();
    }
  }

  static const _glow = Color(0xFFC9A6FF);
  static const _dark = Color(0xFF2A1646);
  static const _body = Color(0xFF7B4DD6);
  static const _light = Color(0xFFB58BFF);
  static const _pale = Color(0xFFE4D3FF);

  /// When the rune is off screen, a round arrow on the edge of the view points to it, with the
  /// distance (the room is wider than the screen, so the student would not know which way to go).
  void _paintGuide(Canvas canvas) {
    if (collected) return;
    final left = game.cameraLeftEdgeX, right = game.cameraRightEdgeX;
    final dir = position.x < left ? -1 : (position.x > right ? 1 : 0);
    if (dir == 0) return;
    final p = game.player;
    final dist = ((p.position.x + p.size.x / 2) - position.x).abs().round();
    final cx = (dir < 0 ? left + 60 : right - 60) - position.x; // local x
    const cy = -190.0;
    final pulse = 0.75 + 0.25 * math.sin(_age * 5);
    canvas.drawCircle(Offset(cx, cy), 26, Paint()..color = const Color.fromRGBO(20, 14, 31, .75));
    canvas.drawCircle(
      Offset(cx, cy),
      26,
      Paint()
        ..color = _light.withValues(alpha: pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final tip = dir * 14.0;
    canvas.drawPath(
      Path()
        ..moveTo(cx + tip, cy)
        ..lineTo(cx - tip * .5, cy - 12)
        ..lineTo(cx - tip * .5, cy + 12)
        ..close(),
      Paint()..color = _pale.withValues(alpha: pulse),
    );
    final label = ParagraphBuilder(ParagraphStyle(textAlign: TextAlign.center))
      ..pushStyle(TextStyle(color: _pale, fontSize: 15, fontWeight: FontWeight.w700))
      ..addText('$dist');
    final para = label.build()..layout(const ParagraphConstraints(width: 70));
    canvas.drawParagraph(para, Offset(cx - 35, cy + 30));
  }

  @override
  void render(Canvas canvas) {
    _paintGuide(canvas);
    final sc = scale01;
    if (sc <= 0) return;
    // Local (0, 0) is where the rune touches the floor.
    final bob = math.sin(_age * 3) * 5;
    const cyBase = -66.0;

    // The light column: from high above down to the floor.
    final beam = Paint()
      ..shader = Gradient.linear(const Offset(0, -900), Offset.zero, [
        const Color(0x00B58BFF),
        Color.fromRGBO(181, 139, 255, .38 * sc),
      ]);
    canvas.drawRect(const Rect.fromLTRB(-20, -900, 20, 0), beam);

    // The ring on the floor.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 3), width: 100 * sc, height: 16 * sc),
      Paint()..color = Color.fromRGBO(181, 139, 255, .35 * sc),
    );

    // The diamond.
    canvas.save();
    canvas.translate(0, cyBase + bob);
    canvas.scale(sc * 1.3);
    final shape = Path()
      ..moveTo(0, -36)
      ..lineTo(25, 0)
      ..lineTo(0, 36)
      ..lineTo(-25, 0)
      ..close();
    canvas.drawPath(
      shape,
      Paint()
        ..color = _glow.withValues(alpha: .5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(shape, Paint()..color = _body);
    canvas.drawPath(
      shape,
      Paint()
        ..color = _dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, -36)
        ..lineTo(25, 0)
        ..lineTo(0, 0)
        ..close(),
      Paint()..color = _light,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, -28)
        ..lineTo(9, -7)
        ..lineTo(0, -7)
        ..close(),
      Paint()..color = _pale,
    );
    final mark = ParagraphBuilder(ParagraphStyle(textAlign: TextAlign.center))
      ..pushStyle(TextStyle(
        color: const Color(0xFFFFFFFF),
        fontSize: 26,
        fontWeight: FontWeight.w700,
      ))
      ..addText('?');
    final p = mark.build()..layout(const ParagraphConstraints(width: 40));
    canvas.drawParagraph(p, const Offset(-20, -17));
    canvas.restore();

    // A few sparks circling it.
    for (var i = 0; i < 5; i++) {
      final an = _age * 1.6 + i * 1.26;
      star(canvas, math.cos(an) * 38, cyBase + bob + math.sin(an) * 27, 4 * sc,
          _pale.withValues(alpha: .8 * sc));
    }
  }
}
