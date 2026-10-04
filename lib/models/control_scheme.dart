/// How a student moves in a level. A per-device preference: the joystick is
/// the default, and left/right arrows are the alternative for students who
/// find a dragged circle awkward. Jump and attack are the same in both.
enum ControlScheme {
  joystick,
  arrows;

  /// Reads a stored name, falling back to the joystick for anything missing
  /// or unrecognised so a bad value can never leave a student without controls.
  static ControlScheme fromName(String? name) => ControlScheme.values
      .firstWhere((s) => s.name == name, orElse: () => ControlScheme.joystick);
}
