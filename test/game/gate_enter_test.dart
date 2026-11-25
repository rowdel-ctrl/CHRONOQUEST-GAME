// Walking into the end gate: the level ends as soon as the middle of the hero steps into the
// doorway (checkGateEntered, GateComponent.enterX), not at the middle or the far pillar.
//
// A student reported having to walk to "the last pillar". This walks the real
// hero, at normal speed, from where a shut gate holds him, through the real
// GateComponent once it is open, and checks where it ends. It also checks, on
// the 37 real maps, that the exit marker is not what ends the level first.
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/gate_art.dart';
import 'package:chronoquest/game/components/gate_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_input.dart';
import 'package:chronoquest/models/control_scheme.dart';

class _WalkGame extends ChronoGame {
  _WalkGame(String era) {
    currentEra = era;
    currentLevel = 1;
  }

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    camera.viewfinder.anchor = Anchor.topLeft;
    player = PlayerComponent(characterId: 'rizal')
      ..size = Vector2(96, 120)
      ..position = Vector2(0, groundY - 120);
    world.add(player);
    gameInput = GameInput(game: this);
    gameInput.setup();
    // Nothing to answer: the gate is only waiting to be opened.
    artifactsTotal = 0;
    artifactsAnswered = 0;
  }
}

Future<(_WalkGame, GateComponent)> _mount(
    WidgetTester tester, String era) async {
  final game = _WalkGame(era);
  await tester.pumpWidget(
    MaterialApp(
      home: GameWidget(
        game: game,
        overlayBuilderMap: {
          'GateLockedOverlay': (_, __) => const SizedBox.shrink(),
          'QuestionOverlay': (_, __) => const SizedBox.shrink(),
        },
      ),
    ),
  );
  await tester.pump();
  final gate = GateComponent(worldX: 2400, isLevelExit: true);
  game.world.add(gate);
  for (var i = 0; i < 12; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 16));
  }
  return (game, gate);
}

void main() {
  for (final era in const [
    'pre-colonial',
    'spanish',
    'nationalism',
    'american',
    'ww2',
    'modern',
  ]) {
    testWidgets(
        '$era: the hero going in at normal speed ends it as he steps into the doorway',
        (tester) async {
      final (game, gate) = await _mount(tester, era);
      final hero = game.player;
      // Where a shut gate holds him: 8 in front of it.
      hero.position.x = gate.blockX - hero.size.x;
      game.update(1 / 60);
      expect(gate.entered, isFalse);
      expect(hero.position.x, gate.blockX - hero.size.x);

      gate.open();
      expect(gate.isBlocking, isFalse);

      // Walk right at full speed, one frame at a time.
      game.gameInput.setScheme(ControlScheme.arrows);
      game.gameInput.setRightHeld(true);
      final enterX = gate.enterX;
      final doorMiddle = gate.position.x + gate.size.x / 2;
      final farPillarLeft = gate.position.x + gate.size.x - 48;
      const step = PlayerComponent.forwardSpeed / 60; // a frame's walk, ~4.2

      for (var frame = 0; frame < 600 && !gate.entered; frame++) {
        // The game's own frame: it moves the world, then checks the gate.
        game.update(1 / 60);
        // There is no ground in this bare game: keep him standing on it.
        hero.position.y = game.groundY - hero.size.y;
        hero.velocityY = 0;
        expect(hero.position.x, lessThan(farPillarLeft),
            reason: 'he got to the far pillar without the level ending');
      }
      // The level's real completion talks to the server; not this test.
      game.levelEnded = true;
      final middleWhenIn = hero.position.x + hero.size.x / 2;
      game.gameInput.setRightHeld(false);

      expect(gate.entered, isTrue);
      expect(middleWhenIn, greaterThanOrEqualTo(enterX));
      expect(middleWhenIn - enterX, lessThanOrEqualTo(step + 0.5),
          reason: 'it ends on the frame his middle steps into the doorway');
      expect(middleWhenIn, lessThan(doorMiddle),
          reason: 'he does not have to walk on to the middle of the doorway');
      expect(hero.position.x, lessThan(gate.position.x + 60),
          reason: 'his left edge is nowhere near the far pillar');

      await tester
          .pump(const Duration(seconds: 1)); // the 0.25 s completion timer
    });
  }

  test('the exit marker of every real map is past the middle of the doorway',
      () {
    // levelComplete also fires when the hero's left edge reaches the exit marker
    // (ChronoGame.checkLevelEnd). That must not come before the gate's own rule.
    // With his left edge at the doorway middle minus half his width, the
    // marker has to be at least there; the generator puts it 120 past the gate.
    final dir = Directory('assets/tiles/levels');
    var checked = 0;
    for (final f in dir.listSync().whereType<File>()) {
      if (!f.path.endsWith('.tmx')) continue;
      final xml = f.readAsStringSync();
      final gate = RegExp(r'type="gate" x="([0-9.]+)"').firstMatch(xml);
      if (gate == null) continue; // a boss arena has no gate
      final exit = RegExp(r'type="exit" x="([0-9.]+)"').firstMatch(xml)!;
      final width = int.parse(
              RegExp(r'<map [^>]*?width="(\d+)"').firstMatch(xml)!.group(1)!) *
          24;
      final gx = double.parse(gate.group(1)!);
      final ex = double.parse(exit.group(1)!);
      const heroHalf = 48.0;
      expect(ex,
          greaterThanOrEqualTo(gx + CombatConstants.gateWidth / 2 - heroHalf),
          reason:
              '${f.path}: the exit marker would end the level before the doorway');
      expect(gx + CombatConstants.gateWidth, lessThanOrEqualTo(width),
          reason: '${f.path}: the gate runs off the end of the map');
      checked++;
    }
    expect(checked, 37);
  });

  test('the doorway is centred in the drawing', () {
    expect(
        GateArt.doorX + GateArt.doorWidth / 2, CombatConstants.gateWidth / 2);
  });
}
