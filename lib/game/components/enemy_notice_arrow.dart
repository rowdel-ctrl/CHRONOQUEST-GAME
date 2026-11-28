import 'dart:math' as math;
import 'dart:ui' show Canvas;

import 'package:flame/components.dart';

import '../chrono_game.dart';
import 'boss_wave_warning.dart';
import 'enemy_component.dart';

/// The red arrow a chaser gives when it notices the student from past the edge of the screen:
/// a "!" badge on that screen edge with a little arrow toward it, for as long as the chaser is
/// off screen (and for no longer than [maxSeconds]). When the chaser is on the screen it shows
/// nothing (the enemy's own small "!" does that). Drawn in code, in world coordinates.
class EnemyNoticeArrow extends PositionComponent with HasGameReference<ChronoGame> {
  final EnemyComponent enemy;

  EnemyNoticeArrow({required this.enemy}) {
    priority = 18;
    position = Vector2.zero();
    size = Vector2.zero();
  }

  /// The longest it stays, so a chaser that stands off screen does not nag for ever.
  static const double maxSeconds = 1.6;

  double _t = 0;

  /// Which screen edge the chaser is past: -1 left, 1 right, 0 when it is on the screen.
  int get edge {
    final cx = enemy.position.x + enemy.size.x / 2;
    if (cx < game.cameraLeftEdgeX + 8) return -1;
    if (cx > game.cameraRightEdgeX - 8) return 1;
    return 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > maxSeconds || enemy.defeated || !enemy.isMounted) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final e = edge;
    if (e == 0) return;
    final pulse = 0.5 + 0.5 * math.sin(_t * 13);
    final cx = e < 0
        ? game.cameraLeftEdgeX + BossWaveWarning.edgeInset
        : game.cameraRightEdgeX - BossWaveWarning.edgeInset;
    final cy = enemy.position.y + enemy.size.y - 150;
    BossWaveWarning.paintEdgeBadge(canvas, cx: cx, cy: cy, edge: e, pulse: pulse);
  }
}
