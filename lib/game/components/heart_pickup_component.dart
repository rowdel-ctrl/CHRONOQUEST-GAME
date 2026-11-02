import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../core/constants.dart';
import '../chrono_game.dart';

/// A heart lying on a high platform (or dropped by the boss when its second phase
/// starts). Walk into it and the student gets one heart back, up to the five.
/// It is there whether or not the hearts are full; at full it is simply not
/// worth the climb, and it stays for later.
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

  /// Whether picking it up would do anything right now.
  bool get wanted => game.hearts < GameConstants.maxHearts;

  /// Picks it up. A student with full hearts walks through it and leaves it be.
  void collect() {
    if (collected || !wanted) return;
    collected = true;
    game.gainHeart();
    game.audioService.playHeart();
    removeFromParent();
  }
}
