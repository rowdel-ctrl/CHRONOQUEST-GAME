// The end gate: 200 x 220 (six era gates), drawn in code, and not drawn at all while it
// is off screen. It is added for the whole level, so without that check the far
// end of a level would cost every frame from the first screen onwards.
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/gate_art.dart';
import 'package:chronoquest/game/components/gate_component.dart';
import 'package:chronoquest/game/components/player_component.dart';

/// Counts what is drawn to it and ignores the rest.
class _CountingCanvas implements ui.Canvas {
  int calls = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    return null;
  }
}

Future<(ChronoGame, GateComponent)> _gateAt(double gateX) async {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.currentEra = 'pre-colonial';
  game.player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(96, 120)
    ..position = Vector2(gateX - 600, game.groundY - 120);
  final gate = GateComponent(worldX: gateX, isLevelExit: true)..game = game;
  await gate.onLoad();
  return (game, gate);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the gate is exactly as big as the constants say: 200 x 220', () async {
    final (_, gate) = await _gateAt(5000);
    expect(CombatConstants.gateWidth, 200);
    expect(CombatConstants.gateHeight, 220);
    expect(gate.size.x, 200);
    expect(gate.size.y, 220);
  });

  test('it stands on the ground and is a good deal above the highest a jump reaches',
      () async {
    final (game, gate) = await _gateAt(5000);
    const jumpPeak = 480.0 * 480.0 / (2 * 900.0); // about 128
    expect(gate.position.y + gate.size.y, game.groundY);
    expect(gate.size.y, greaterThan(jumpPeak + 40));
  });

  test('the doorway is in the middle: size.x / 2 is the middle of the door', () {
    // The end rule (checkGateEntered) uses gate.position.x + size.x / 2.
    expect(GateArt.doorX + GateArt.doorWidth / 2, CombatConstants.gateWidth / 2);
    expect(GateArt.centreX, CombatConstants.gateWidth / 2);
    expect(GateArt.width, CombatConstants.gateWidth);
    expect(GateArt.height, CombatConstants.gateHeight);
  });

  test('the student is drawn in front of it, not behind', () async {
    final (game, gate) = await _gateAt(5000);
    expect(gate.priority, lessThan(game.player.priority));
  });

  test('it still stops the player 8 units in front of its left edge', () async {
    final (_, gate) = await _gateAt(5000);
    expect(gate.blockX, 5000 - CombatConstants.gateStandoff);
  });

  test('it draws when it is on screen, shut and unlocked', () async {
    final (game, gate) = await _gateAt(5000);
    expect(game.cameraRightEdgeX, greaterThan(5000),
        reason: 'the player is 600 units before it, so it is in view');

    game.artifactsTotal = 10; // none answered yet, so the gate is shut
    game.artifactsAnswered = 0;
    final shut = _CountingCanvas();
    gate.render(shut);
    expect(shut.calls, greaterThan(0));

    game.artifactsAnswered = 10;
    final open = _CountingCanvas();
    gate.render(open);
    expect(open.calls, greaterThan(shut.calls),
        reason: 'unlocked adds the door glow and the open padlock');
  });

  test('it draws nothing while it is far off screen', () async {
    final (game, gate) = await _gateAt(20000);
    game.player.position.x = 100; // the camera is at the start of the level
    expect(game.cameraRightEdgeX, lessThan(gate.position.x));

    final canvas = _CountingCanvas();
    gate.render(canvas);
    expect(canvas.calls, 0);
  });

  test('it draws again once the camera reaches it', () async {
    final (game, gate) = await _gateAt(20000);
    game.player.position.x = 100;
    final far = _CountingCanvas();
    gate.render(far);
    expect(far.calls, 0);

    game.player.position.x = 20000 - GameConstants.playerX;
    final near = _CountingCanvas();
    gate.render(near);
    expect(near.calls, greaterThan(0));
  });

  test('it is drawn for every era, and the era picks the gate', () async {
    const eras = {
      'pre-colonial': GateKind.bamboo,
      'spanish': GateKind.stone,
      'nationalism': GateKind.wood,
      'american': GateKind.brick,
      'ww2': GateKind.sandbag,
      'modern': GateKind.concrete,
      'something-new': GateKind.stone,
    };
    for (final e in eras.entries) {
      expect(GateArt.kindForEra(e.key), e.value, reason: e.key);
    }
  });
}
