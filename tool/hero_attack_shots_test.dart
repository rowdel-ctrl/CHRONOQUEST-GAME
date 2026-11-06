// A development tool, not a test of behaviour: plays each hero's ground and air attack
// through the real game (real level, real sprites, a real enemy) at a phone-sized window
// and writes a PNG at a few moments of the swing, so the new attack pictures can be
// reviewed without a device.
//
//   flutter test tool/hero_attack_shots_test.dart \
//       --dart-define=HERO_SHOTS=boy,girl,lapu --dart-define=SHOT_OUT=C:/temp/atk
//
// Writes <out>_<hero>_ground_<n>.png and <out>_<hero>_air_<n>.png. Without HERO_SHOTS the
// test does nothing, so it is safe in a full `flutter test tool` run.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/parallax_background.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_input.dart';
import 'package:chronoquest/game/game_spawning.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _heroes = String.fromEnvironment('HERO_SHOTS');
const _out = String.fromEnvironment('SHOT_OUT', defaultValue: 'atk');
const _levelX = int.fromEnvironment('SHOT_X', defaultValue: 900);

class _AttackGame extends ChronoGame {
  _AttackGame(this.hero) {
    currentEra = 'pre-colonial';
    currentLevel = 3;
  }

  final String hero;

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.backdrop = ParallaxBackground();
    player = PlayerComponent(characterId: hero);
    world.add(player);
    gameInput = GameInput(game: this);
    gameInput.joystick = JoystickComponent(background: CircleComponent(radius: 10));
    await setupSpawning();
  }
}

void main() {
  testWidgets('hero attack shots', timeout: const Timeout(Duration(minutes: 15)), (tester) async {
    if (_heroes.isEmpty) return;
    tester.view.physicalSize = const Size(1746, 786);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    for (final hero in _heroes.split(',')) {
      for (final air in [false, true]) {
        final game = _AttackGame(hero);
        final key = GlobalKey();
        await tester.pumpWidget(MaterialApp(
          home: RepaintBoundary(key: key, child: GameWidget(game: game)),
        ));
        await tester.pump();
        for (var i = 0; i < 40; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
          await tester.pump(const Duration(milliseconds: 16));
        }
        final level = game.tiledLevel!;
        final px = (_levelX + 220).toDouble();
        final block = level.blockAt(px + 48);
        final feet = block?.topY ?? game.groundY;
        game.player.position
          ..x = px
          ..y = feet - game.player.size.y;
        game.player.isOnGround = true;
        game.questionShowing = true; // freeze the spawner and the level end
        game.kaalaman = 5;
        // An enemy a little way ahead: the Tribal Warrior of this era.
        game.world.add(EnemyComponent(
          eraId: 'pre-colonial',
          enemyTypeOverride: 'tribal_warrior',
          worldX: px + 150,
          surfaceY: feet,
        ));
        game.update(0.001);
        for (var i = 0; i < 6; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
          await tester.pump(const Duration(milliseconds: 16));
        }

        Future<void> shot(String name) async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
          final bytes = await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            return data!.buffer.asUint8List();
          });
          File('${_out}_${hero}_${air ? 'air' : 'ground'}_$name.png').writeAsBytesSync(bytes!);
        }

        if (air) {
          game.player.jump();
          await tester.pump(const Duration(milliseconds: 120));
        }
        game.player.attack();
        // 0.03 s, 0.12 s, 0.21 s into the swing (the picture changes at 0.17 s on the
        // ground and at 0.10 s in the air).
        await tester.pump(const Duration(milliseconds: 30));
        await shot('1');
        await tester.pump(const Duration(milliseconds: 90));
        await shot('2');
        await tester.pump(const Duration(milliseconds: 90));
        await shot('3');
        // ignore: avoid_print
        print('$hero ${air ? 'air' : 'ground'} done');
      }
    }
  });
}
