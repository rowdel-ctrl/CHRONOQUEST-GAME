import 'dart:async' show unawaited;
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/cave_constants.dart';
import '../cave_handler.dart';
import '../chrono_game.dart';
import 'gap_component.dart';

/// A pipe the student can stand on and go down (or, in the cave, up).
///
/// In a level that has a cave it stands in the road where one of the level's ten
/// artifacts would have been. It is solid like raised ground: a wall that has to
/// be jumped (72 high, the jump peaks at 128) with a top to land on. Standing on
/// its top for a moment takes the student down. In the cave the same pipe stands
/// at the end and takes them back up, once the cave's artifact is answered.
///
/// Drawn in code, one skin per era (bamboo, stone, iron, olive metal, rust,
/// concrete), the same as the approved mockup.
class PipeComponent extends PositionComponent
    with HasGameReference<ChronoGame> {
  PipeComponent({
    required this.centerX,
    required this.eraId,
    this.surfaceY,
    this.isExit = false,
    this.onEnter,
  }) : super(priority: -1);

  /// World x of the pipe's middle.
  final double centerX;
  final String eraId;

  /// World y of the ground it stands on; the base ground when null. A pipe may
  /// stand on the flat top of a mesa.
  final double? surfaceY;

  /// The pipe at the end of the cave, which goes up. The entrance goes down.
  final bool isExit;

  /// Called once when the student has stood on the top long enough.
  void Function(PipeComponent pipe)? onEnter;

  /// Whether standing on it does anything now. The exit pipe waits for the cave's
  /// artifact; the entrance stops once the cave is done.
  bool enabled = true;

  /// True once the cave has been done: the entrance shows a quiet glow, no sign
  /// and no arrow.
  bool done = false;

  /// Seconds the student has stood on the top. Negative is a rest after a trip:
  /// the student coming back up is not taken straight down again.
  double standTime = 0;

  double _t = 0;
  bool _fired = false;

  /// World y of the top of the pipe, where the student's feet stand.
  double get topY => (surfaceY ?? game.groundY) - CaveConstants.pipeHeight;

  /// The era's skin: body, light side, shaded side, outline.
  static const Map<String, List<Color>> _skins = {
    'pre-colonial': [
      Color(0xFF7FB04A), Color(0xFFA9D35E), Color(0xFF4D7A2A), Color(0xFF365A1C)
    ],
    'spanish': [
      Color(0xFF8A8378), Color(0xFFB3AB9D), Color(0xFF5E584F), Color(0xFF3F3B35)
    ],
    'nationalism': [
      Color(0xFF5F6B7A), Color(0xFF8795A8), Color(0xFF3D4654), Color(0xFF2A303A)
    ],
    'american': [
      Color(0xFF6B7A3A), Color(0xFF92A352), Color(0xFF454F22), Color(0xFF2F3716)
    ],
    'ww2': [
      Color(0xFF9A5A34), Color(0xFFC47D4C), Color(0xFF683A1E), Color(0xFF46260F)
    ],
    'modern': [
      Color(0xFF7F8696), Color(0xFFA7AEBF), Color(0xFF565C6B), Color(0xFF3A3F4B)
    ],
  };

  List<Color> get _skin => _skins[eraId] ?? _skins['spanish']!;

  @override
  Future<void> onLoad() async {
    // The pipe in the level takes the student down, and the level knows about it.
    if (!isExit) {
      game.cave.pipe = this;
      onEnter ??= (p) => unawaited(game.enterCavePipe(p));
    }
    const rim = CaveConstants.pipeRimWidth;
    size = Vector2(rim, CaveConstants.pipeHeight);
    position = Vector2(centerX - rim / 2, topY);
    // The solid part: raised ground the width of the body, so the sides are a wall
    // and the top is somewhere to land.
    game.world.add(
      GroundSection(
        sectionWidth: CaveConstants.pipeBodyWidth,
        sectionPosition:
            Vector2(centerX - CaveConstants.pipeBodyWidth / 2, topY),
        sectionHeight: CaveConstants.pipeHeight + GroundSection.bandHeight,
        drawn: false,
      ),
    );
  }

  /// Whether the student is standing on the top right now.
  bool get studentOnTop {
    final p = game.player;
    if (!p.isMounted || !p.isOnGround) return false;
    final middle = p.position.x + p.size.x / 2;
    final feet = p.position.y + p.size.y;
    return (middle - centerX).abs() <= CaveConstants.pipeEnterHalfWidth &&
        (feet - topY).abs() < 6;
  }

  /// Puts the student back beside the pipe, on the ground, after a trip, and rests
  /// the pipe for a moment so they are not taken straight down again.
  void settleStudent() {
    final p = game.player;
    p.position = Vector2(
        centerX + CaveConstants.pipeRimWidth / 2 + 24,
        (surfaceY ?? game.groundY) - p.size.y);
    p.velocityY = 0;
    standTime = -1.5;
    _fired = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (!enabled || done || onEnter == null) {
      standTime = min(standTime + dt, 0);
      return;
    }
    if (standTime < 0) {
      standTime = min(standTime + dt, 0);
      return;
    }
    if (studentOnTop) {
      standTime += dt;
      if (standTime >= CaveConstants.pipeStandSeconds && !_fired) {
        _fired = true;
        onEnter!(this);
      }
    } else {
      standTime = 0;
      _fired = false;
    }
  }

  // ─── drawing ───────────────────────────────────────────────────────────────

  static final TextPainter _signText = TextPainter(
    text: const TextSpan(
      text: 'SA ILALIM',
      style: TextStyle(
        color: Color(0xFFFFE08A),
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  static final TextPainter _upText = TextPainter(
    text: const TextSpan(
      text: 'SA ITAAS',
      style: TextStyle(
        color: Color(0xFFFFE08A),
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final Paint _p = Paint();

  @override
  void render(Canvas canvas) {
    if (position.x + size.x < game.cameraLeftEdgeX - 80 ||
        position.x > game.cameraRightEdgeX + 80) {
      return;
    }
    final c = _skin;
    const bw = CaveConstants.pipeBodyWidth, rw = CaveConstants.pipeRimWidth;
    const h = CaveConstants.pipeHeight;
    const bx = (rw - bw) / 2;
    final bamboo = eraId == 'pre-colonial';

    // The body down to the ground, lit from the left.
    _p.color = c[0];
    canvas.drawRect(const Rect.fromLTWH(bx, 18, bw, h - 18 + 6), _p);
    _p.color = c[1];
    canvas.drawRect(const Rect.fromLTWH(bx + 8, 18, 14, h - 18 + 6), _p);
    _p.color = c[2];
    canvas.drawRect(const Rect.fromLTWH(bx + bw - 16, 18, 16, h - 18 + 6), _p);
    _p
      ..color = c[3]
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final step = bamboo ? 26.0 : 20.0;
    for (var y = 18 + step; y < h; y += step) {
      canvas.drawLine(Offset(bx, y), Offset(bx + bw, y), _p);
    }
    if (!bamboo && (eraId == 'nationalism' || eraId == 'ww2')) {
      _p.style = PaintingStyle.fill;
      _p.color = c[3];
      for (var y = 18 + step / 2; y < h; y += step) {
        canvas.drawCircle(Offset(bx + 10, y), 2, _p);
        canvas.drawCircle(Offset(bx + bw - 10, y), 2, _p);
      }
    }
    // The rim.
    _p.style = PaintingStyle.fill;
    _p.color = c[0];
    canvas.drawRect(const Rect.fromLTWH(0, 0, rw, 20), _p);
    _p.color = c[1];
    canvas.drawRect(const Rect.fromLTWH(0, 0, rw, 6), _p);
    _p.color = c[2];
    canvas.drawRect(const Rect.fromLTWH(0, 16, rw, 4), _p);
    _p
      ..color = c[3]
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(const Rect.fromLTWH(1, 1, rw - 2, 18), _p);
    _p.style = PaintingStyle.fill;

    // The opening on top, dark; gold light when it is the way through.
    const open = Rect.fromLTWH(10, 0, rw - 20, 12);
    _p.color = const Color(0xFF0A0612);
    canvas.drawOval(open, _p);
    final lit = (isExit && enabled) || done;
    if (lit) {
      final pulse = 0.5 + 0.5 * sin(_t * 4);
      _p.color = Color.fromRGBO(255, 224, 138, 0.55 + 0.35 * pulse);
      canvas.drawOval(open, _p);
    }

    // The sign and the arrow that say where to go, only while the pipe is wanted.
    final wanted = enabled && !done;
    if (!wanted) return;
    final near = isExit ||
        (game.player.isMounted &&
            (game.player.position.x - centerX).abs() <
                CaveConstants.pipeSignRange);
    if (!near) return;
    final bob = sin(_t * 6) * 5;
    final arrow = Path()
      ..moveTo(rw / 2 - 16, -46 + bob)
      ..lineTo(rw / 2 + 16, -46 + bob)
      ..lineTo(rw / 2, -22 + bob)
      ..close();
    _p.color = const Color(0xFFFFE08A);
    canvas.drawPath(arrow, _p);
    _p
      ..color = const Color(0xFF6B4F16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(arrow, _p);
    _p.style = PaintingStyle.fill;
    final tp = isExit ? _upText : _signText;
    final sw = tp.width + 22;
    final sx = rw / 2 - sw / 2;
    const sy = -86.0;
    _p.color = const Color(0xE00E111E);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(sx, sy, sw, 28), const Radius.circular(8)),
        _p);
    _p
      ..color = const Color(0xFFFFE08A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(sx, sy, sw, 28), const Radius.circular(8)),
        _p);
    _p.style = PaintingStyle.fill;
    tp.paint(canvas, Offset(sx + 11, sy + (28 - tp.height) / 2));
  }
}
