import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../chrono_game.dart';

/// A power-up lying on the floor (dropped by a minion of the boss's waves). Walk into it and it is
/// gone and the student has one more of that power-up: it goes into the wallet at once, like one
/// bought in the shop. [kind] is the name of a `PowerUpKind` ('fiftyFifty', 'shield' or
/// 'timeFreeze').
class PowerUpPickupComponent extends SpriteComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  final String kind;
  bool collected = false;

  double _bobTime = 0;
  late final double _baseY;

  PowerUpPickupComponent({required this.kind, required Vector2 spawnPosition}) {
    position = spawnPosition;
  }

  /// The picture of each kind (the same ones the shop and the question card use).
  static String assetFor(String kind) => switch (kind) {
        'fiftyFifty' => 'powerups/fifty_fifty.png',
        'shield' => 'powerups/shield.png',
        _ => 'powerups/time_freeze.png',
      };

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(assetFor(kind));
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

  /// Picks it up: one more power-up of its kind, and the heart's sound.
  void collect() {
    if (collected) return;
    collected = true;
    game.gainPowerUp(kind);
    game.audioService.playHeart();
    removeFromParent();
  }
}
