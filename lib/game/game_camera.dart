import 'package:flame/components.dart';
import 'chrono_game.dart';

/// Camera-follow for [ChronoGame]. Split out of chrono_game.dart's update()
/// loop as part of the Phase 1 refactor (GAMEPLAY-V2.md Section 15) —
/// behavior is unchanged: the viewfinder tracks the player's worldX every
/// frame, offset so the player renders at the fixed screen position
/// GameConstants.playerX (see ChronoGame.cameraLeftEdgeX).
extension GameCamera on ChronoGame {
  void updateCamera() {
    camera.viewfinder.position = Vector2(cameraLeftEdgeX, 0);
  }
}
