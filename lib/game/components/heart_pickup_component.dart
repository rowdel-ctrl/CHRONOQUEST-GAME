import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../chrono_game.dart';

/// A heart lying on a high platform (or dropped by the boss when its second phase
/// starts). Walk into it and it is gone: the student gets one heart back, up to the
/// five. At full hearts it is still taken (nothing is gained), so it never stays
/// hanging there; a classmate's playtest suggestion.
class HeartPickupComponent extends SpriteComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  bool collected = false;

  double _bobTime = 0;
  late final double _baseY;

  HeartPickupComponent({required Vector2 spawnPosition}) {
    position = spawnPosition;
  }

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('ui/heart_full.png');
    size = Vector2(44, 44);
    _baseY = position.y;
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (collected) return;
    _bobTime += dt * 3;
    position.y = _baseY + sin(_bobTime) * 4;
  }

  /// Picks it up. With full hearts it only disappears (a soft coin sound, no heart).
  void collect() {
    if (collected) return;
    collected = true;
    if (game.gainHeart()) {
      game.audioService.playHeart();
    } else {
      game.audioService.playCoin();
    }
    removeFromParent();
  }
}
