// The six era gates draw without throwing, shut, unlocked, lifting and open. Set GATE_SHOTS to a folder to also save a PNG
// sheet of all 18 (six eras by shut, unlocked, open) to look at.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/gate_component.dart';
import 'package:chronoquest/game/components/player_component.dart';

const _eras = [
  'pre-colonial',
  'spanish',
  'nationalism',
  'american',
  'ww2',
  'modern',
];

Future<(ChronoGame, GateComponent)> _gateIn(String era) async {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.currentEra = era;
  game.player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(96, 120)
    ..position = Vector2(4400, game.groundY - 120);
  final gate = GateComponent(worldX: 5000, isLevelExit: true)..game = game;
  await gate.onLoad();
  return (game, gate);
}

/// 0 = shut with artifacts left, 1 = unlocked, 2 = open.
void _setState(ChronoGame game, GateComponent gate, int state) {
  game.artifactsTotal = 10;
  game.artifactsAnswered = state == 0 ? 3 : 10;
  gate.doorOpen = state == 2 ? 1 : 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final era in _eras) {
    test('$era: shut, unlocked, lifting and open all draw', () async {
      final (game, gate) = await _gateIn(era);
      for (var state = 0; state < 3; state++) {
        _setState(game, gate, state);
        for (var t = 0; t < 40; t++) {
          gate.update(0.1); // the flames and chimes move
          final recorder = ui.PictureRecorder();
          gate.render(Canvas(recorder));
          recorder.endRecording().dispose();
        }
      }
      // Half way up, with dust, and fading out.
      gate.doorOpen = 0.5;
      gate.paint.color = Colors.white.withValues(alpha: 0.4);
      final recorder = ui.PictureRecorder();
      gate.render(Canvas(recorder));
      recorder.endRecording().dispose();
    });
  }

  testWidgets('a sheet of all 18 (only when GATE_SHOTS is set)',
      (tester) async {
    final dir = Platform.environment['GATE_SHOTS'];
    if (dir == null || dir.isEmpty) return;
    const cellW = 300.0, cellH = 300.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, cellW * 3, cellH * 6),
        Paint()..color = const Color(0xFF3D4262));
    for (var e = 0; e < _eras.length; e++) {
      final (game, gate) = await _gateIn(_eras[e]);
      for (var s = 0; s < 3; s++) {
        _setState(game, gate, s);
        gate.update(0.7);
        canvas.save();
        canvas.translate(s * cellW + 50, e * cellH + 50);
        canvas.drawRect(const Rect.fromLTWH(-50, 236, cellW, 64),
            Paint()..color = const Color(0xFF5A4030));
        gate.render(canvas);
        canvas.restore();
      }
    }
    final pic = recorder.endRecording();
    await tester.runAsync(() async {
      final image = await pic.toImage((cellW * 3).toInt(), (cellH * 6).toInt());
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/gates.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  });
}
