// A development tool, not a test of behaviour: draws part of a level through the
// real game (terrain, water, platforms, enemies, the parallax backdrop) and writes
// it to a PNG, so a level can be reviewed without running the app on a device.
//
//   flutter test tool/level_screenshots_test.dart \
//       --dart-define=SHOT_LEVEL=era1_7 --dart-define=SHOT_X=17100 \
//       --dart-define=SHOT_OUT=C:/temp/shot.png
//
// SHOT_X is the world x at the left edge of the picture. Without SHOT_LEVEL the
// test does nothing, so it is safe in a full `flutter test tool` run.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/parallax_background.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_input.dart';
import 'package:chronoquest/game/game_spawning.dart';

const _level = String.fromEnvironment('SHOT_LEVEL');
const _x = int.fromEnvironment('SHOT_X', defaultValue: 0);
const _out = String.fromEnvironment('SHOT_OUT', defaultValue: 'shot.png');

final _eraIds = ['pre-colonial', 'spanish', 'nationalism', 'american', 'ww2', 'modern'];

class _ShotGame extends ChronoGame {
  _ShotGame(String era, int level) {
    currentEra = era;
    currentLevel = level;
  }

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.backdrop = ParallaxBackground();
    player = PlayerComponent(characterId: 'rizal');
    world.add(player);
    // A joystick that is never mounted: the player reads it, nothing draws it.
    gameInput = GameInput(game: this);
    gameInput.joystick = JoystickComponent(background: CircleComponent(radius: 10));
    await setupSpawning();
  }
}

void main() {
  testWidgets('screenshot', (tester) async {
    final m = RegExp(r'era(\d+)_(\d+)').firstMatch(_level);
    if (m == null) return;
    final era = _eraIds[int.parse(m.group(1)!) - 1];
    final index = int.parse(m.group(2)!);

    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final game = _ShotGame(era, index);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: RepaintBoundary(key: key, child: GameWidget(game: game)),
    ));
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Put the camera where asked: the camera's left edge is the player's world x
    // less the fixed screen offset.
    final level = game.tiledLevel!;
    final block = level.blockAt((_x + 220 + 48).toDouble());
    game.player.position
      ..x = (_x + 220).toDouble()
      ..y = (block?.topY ?? game.groundY) - game.player.size.y;
    game.player.isOnGround = true;
    game.questionShowing = true; // freeze the spawner / level end
    game.update(0.001);
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 16));
    }

    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    File(_out).writeAsBytesSync(bytes!);
    // ignore: avoid_print
    print('wrote $_out');
  });
}
