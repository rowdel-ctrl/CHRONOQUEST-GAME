import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'chrono_game.dart';

/// Builds the on-screen joystick and jump/attack buttons — Flame's built-in
/// input components (GAMEPLAY-V2.md Section 3: "Don't build the controls —
/// Flame ships them"). Split out of chrono_game.dart as part of the Phase 1
/// refactor (Section 15).
///
/// Added to `camera.viewport`, not `world` or the game directly: both
/// `JoystickComponent` and `HudButtonComponent` mix in
/// `ComponentViewportMargin`, whose margin positioning asserts its parent
/// provides a size and resolves against that parent's `virtualSize`.
/// `camera.viewport` is the `StretchToFillViewport` this game's
/// `CameraComponent` uses, so margins land against its virtual size (fixed
/// height, device-matched width — see that class) rather than the raw,
/// per-device canvas size. That viewport's scale is always uniform, so
/// these round controls render as true circles on every device with no
/// extra counter-scaling needed.
///
/// The knob/background/button shapes here are plain Flame primitives, not
/// the Kenney CC0 on-screen-control art Section 3 calls for — swapping in
/// real control art is a follow-up, the same "plumbing now, real asset
/// later" split Phase 0 used for audio.
class GameInput {
  final ChronoGame game;
  late final JoystickComponent joystick;

  GameInput({required this.game});

  void setup() {
    // Sized for a comfortable thumb drag (radius 60, margin 45/45) rather
    // than shrunk to fit some gap next to the player — those two goals
    // couldn't both be satisfied by sizing the joystick alone, since any
    // comfortable radius/margin combination reached past where the player
    // used to render. Fixed instead by moving the player further from the
    // left edge (GameConstants.playerX, see its own doc comment), which is
    // what actually clears this joystick's footprint (x in [45,165]) now.
    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 28,
        paint: Paint()..color = Colors.white.withValues(alpha: 0.75),
      ),
      background: CircleComponent(
        radius: 60,
        paint: Paint()..color = Colors.white.withValues(alpha: 0.3),
      ),
      margin: const EdgeInsets.only(left: 45, bottom: 45),
    );

    final jumpButton = HudButtonComponent(
      button: _buttonShape(label: 'JUMP', alpha: 0.35),
      buttonDown: _buttonShape(label: 'JUMP', alpha: 0.65),
      margin: const EdgeInsets.only(right: 145, bottom: 35),
      onPressed: game.onPlayerJump,
    );

    final attackButton = HudButtonComponent(
      button: _buttonShape(
        label: 'ATK',
        alpha: 0.35,
        color: Colors.redAccent,
      ),
      buttonDown: _buttonShape(
        label: 'ATK',
        alpha: 0.65,
        color: Colors.redAccent,
      ),
      margin: const EdgeInsets.only(right: 15, bottom: 35),
      onPressed: game.onPlayerAttack,
    );

    game.camera.viewport.addAll([joystick, jumpButton, attackButton]);
  }

  PositionComponent _buttonShape({
    required String label,
    required double alpha,
    Color color = Colors.white,
  }) {
    // 20% bigger than the original 90 — playtesting found Jump/Attack too
    // small and too close to the joystick to reach comfortably by thumb.
    const diameter = 108.0;
    return CircleComponent(
      radius: diameter / 2,
      paint: Paint()..color = color.withValues(alpha: alpha),
      children: [
        TextComponent(
          text: label,
          anchor: Anchor.center,
          position: Vector2.all(diameter / 2),
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
