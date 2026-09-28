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
/// `camera.viewport` is the `FixedResolutionViewport` this game's
/// `CameraComponent` uses, so margins land against the fixed 1280x720
/// virtual resolution (GameConstants.virtualWidth/Height) rather than the
/// raw, per-device canvas size.
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
    // Player renders at a fixed virtual x=GameConstants.playerX (80) —
    // very close to the left edge, by design (see chrono_game.dart's
    // cameraLeftEdgeX doc comment). At the original 55-radius background and
    // 50-unit left margin, the joystick's footprint (x in [50,160]) reached
    // well past the player's own left edge, sitting directly under them.
    // Shrunk and tucked closer to the true corner (left/bottom 15, radius
    // 40) so its footprint is [15,95] — clear of the player's [80,176] span
    // apart from a small sliver at their trailing foot during the walk
    // animation, instead of overlapping their whole lower body.
    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 20,
        paint: Paint()..color = Colors.white.withValues(alpha: 0.75),
      ),
      background: CircleComponent(
        radius: 40,
        paint: Paint()..color = Colors.white.withValues(alpha: 0.3),
      ),
      margin: const EdgeInsets.only(left: 15, bottom: 15),
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
      // Phase 2 wires this to the attack hitbox — GAMEPLAY-V2.md Section 15,
      // Phase 1 prompt: "the attack button should do nothing yet".
      onPressed: () {},
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
