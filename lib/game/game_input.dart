import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'chrono_game.dart';
import '../models/control_scheme.dart';

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
///
/// Movement comes in two schemes (see [ControlScheme]): the joystick, or a
/// pair of left/right arrow buttons for students who prefer them. Everything
/// else reads [horizontal] and does not care which is on screen. Jump and
/// attack are identical in both.
class GameInput {
  final ChronoGame game;

  /// The joystick. Only mounted while [scheme] is [ControlScheme.joystick];
  /// tests also assign a bare one directly, so this is not `final`.
  late JoystickComponent joystick;

  ControlScheme scheme;

  bool _leftHeld = false;
  bool _rightHeld = false;

  /// The movement controls currently on screen, so a scheme change can take
  /// exactly these away and leave jump and attack alone.
  final List<Component> _movementControls = [];

  GameInput({required this.game, this.scheme = ControlScheme.joystick});

  /// Horizontal input in -1..1, whichever scheme is active. The joystick gives
  /// a graded value (a half pull walks slower); an arrow button is either held
  /// or not, and holding both cancels out.
  double get horizontal => scheme == ControlScheme.arrows
      ? (_rightHeld ? 1.0 : 0.0) - (_leftHeld ? 1.0 : 0.0)
      : joystick.relativeDelta.x;

  /// Called by the arrow buttons. Public so tests can press them without
  /// simulating a touch.
  void setLeftHeld(bool held) => _leftHeld = held;
  void setRightHeld(bool held) => _rightHeld = held;

  void setup() {
    _mountMovement();

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

    game.camera.viewport.addAll([jumpButton, attackButton]);
  }

  /// Swaps the movement controls for [next]. Jump and attack stay mounted, and
  /// any held direction is dropped so nothing keeps walking after the switch.
  void setScheme(ControlScheme next) {
    if (next == scheme) return;
    for (final c in _movementControls) {
      c.removeFromParent();
    }
    _movementControls.clear();
    _leftHeld = false;
    _rightHeld = false;
    scheme = next;
    _mountMovement();
  }

  void _mountMovement() {
    final List<Component> controls;
    if (scheme == ControlScheme.arrows) {
      controls = _buildArrows();
    } else {
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
      controls = [joystick];
    }
    _movementControls.addAll(controls);
    game.camera.viewport.addAll(controls);
  }

  /// Two round buttons in the joystick's corner, the same size as Jump and
  /// Attack so a thumb finds them the same way.
  List<Component> _buildArrows() {
    HudButtonComponent arrow({
      required bool right,
      required double left,
    }) {
      return HudButtonComponent(
        button: _arrowShape(right: right, alpha: 0.35),
        buttonDown: _arrowShape(right: right, alpha: 0.65),
        margin: EdgeInsets.only(left: left, bottom: 35),
        onPressed: () => right ? setRightHeld(true) : setLeftHeld(true),
        onReleased: () => right ? setRightHeld(false) : setLeftHeld(false),
        onCancelled: () => right ? setRightHeld(false) : setLeftHeld(false),
      );
    }

    const gap = 16.0;
    return [
      arrow(right: false, left: 45),
      arrow(right: true, left: 45 + _buttonDiameter + gap),
    ];
  }

  static const double _buttonDiameter = 108;

  PositionComponent _arrowShape({required bool right, required double alpha}) {
    // Points are relative to the circle, in -1..1, so the triangle scales with
    // the button. It sits a touch toward its point so it looks centred.
    final dir = right ? 1.0 : -1.0;
    return CircleComponent(
      radius: _buttonDiameter / 2,
      paint: Paint()..color = Colors.white.withValues(alpha: alpha),
      children: [
        PolygonComponent.relative(
          [
            Vector2(-0.28 * dir, -0.45),
            Vector2(0.5 * dir, 0),
            Vector2(-0.28 * dir, 0.45),
          ],
          parentSize: Vector2.all(_buttonDiameter),
          position: Vector2.all(_buttonDiameter / 2),
          anchor: Anchor.center,
          paint: Paint()..color = Colors.white,
        ),
      ],
    );
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
