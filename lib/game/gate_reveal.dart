import 'dart:math' as math;

import 'package:flutter/animation.dart' show Curves;

import 'chrono_game.dart';
import 'game_camera.dart';
import 'components/gate_component.dart';

/// The moment after the last artifact is answered: the camera leaves the player,
/// slides to the end gate, the door lifts, and the camera slides back.
///
/// While it runs the world stands still (nothing in it is updated: no enemy
/// can reach the player), so the only things moving are the camera, the
/// background that follows it, and the gate. It is driven from
/// `ChronoGame.updateTree`, which calls [step] instead of updating the world.
///
/// It ends by itself after about three seconds, or at once when the student
/// presses Jump or Attack ([skip]); either way the door is left open, so the
/// student walks into a doorway that is already open.
class GateReveal {
  final ChronoGame game;
  final GateComponent gate;

  /// Seconds the camera takes to get to the gate, and to come back. Longer when
  /// the gate is further away, but never slow enough to feel like waiting.
  late final double panSeconds;

  /// Where the camera starts (following the player) and where it looks at the
  /// gate from, as world x of the left edge of the view.
  late final double fromX;
  late final double toX;

  static const double holdBefore = 0.25;
  static const double openSeconds = 1.1;

  /// The most the picture is shaken, in world units, at the strongest moment.
  static const double shakeAmount = 7;
  static const double holdAfter = 0.7;

  double _elapsed = 0;
  bool _soundPlayed = false;

  GateReveal({required this.game, required this.gate}) {
    fromX = game.cameraLeftEdgeX;
    // Centre the gate in the view, but never pan backwards.
    final centred = gate.position.x + gate.size.x / 2 - game.size.x / 2;
    toX = centred > fromX ? centred : fromX;
    panSeconds = (0.6 + (toX - fromX) / 3000).clamp(0.6, 1.1);
  }

  double get _openStart => panSeconds + holdBefore;
  double get _backStart => _openStart + openSeconds + holdAfter;

  /// How long the whole thing takes.
  double get totalSeconds => _backStart + panSeconds;

  /// How far through it is, in seconds.
  double get elapsed => _elapsed;

  /// The camera's left edge at [t] seconds in.
  double cameraXAt(double t) {
    if (t < panSeconds) {
      return fromX + (toX - fromX) * Curves.easeInOut.transform(t / panSeconds);
    }
    if (t < _backStart) return toX;
    final back = ((t - _backStart) / panSeconds).clamp(0.0, 1.0);
    return toX + (fromX - toX) * Curves.easeInOut.transform(back);
  }

  /// How far the door is up at [t] seconds in, 0 to 1.
  double doorAt(double t) =>
      Curves.easeIn.transform(((t - _openStart) / openSeconds).clamp(0.0, 1.0));

  /// How strongly the gate is shaking at [t] seconds in, 0 to 1: it starts with
  /// the grille, is strongest in the middle of the lift, and dies away as the
  /// grille stops.
  double shakeStrength(double t) {
    final u = (t - _openStart) / (openSeconds + 0.15);
    if (u <= 0 || u >= 1) return 0;
    return math.sin(math.pi * u);
  }

  /// The picture's offset at [t] seconds in. Two out-of-step wobbles, so it
  /// shudders instead of swinging side to side.
  (double, double) shakeAt(double t) {
    final a = shakeAmount * shakeStrength(t);
    return (
      a * (math.sin(t * 47) * 0.7 + math.sin(t * 29) * 0.3),
      a * 0.7 * math.cos(t * 53),
    );
  }

  /// Advances by [dt] seconds. Called every frame instead of the world update.
  void step(double dt) {
    _elapsed += dt;
    if (_elapsed >= totalSeconds) {
      _finish();
      return;
    }
    if (!_soundPlayed && _elapsed >= _openStart) {
      _soundPlayed = true;
      game.audioService.playPowerup();
    }
    gate.doorOpen = doorAt(_elapsed);
    final shake = shakeAt(_elapsed);
    game.cameraShake.setValues(shake.$1, shake.$2);
    game.gateRevealCameraX = cameraXAt(_elapsed);
    game.updateCamera();
    // The background scrolls from how far the camera moved, so it has to see
    // this frame's camera, even though nothing else in the world is updating.
    game.camera.updateTree(dt);
    gate.update(dt);
  }

  /// Ends it now, with the door open and the camera back on the player.
  void skip() => _finish();

  void _finish() {
    gate.doorOpen = 1;
    game.cameraShake.setZero();
    game.gateRevealCameraX = null;
    game.gateReveal = null;
    game.updateCamera();
  }
}
