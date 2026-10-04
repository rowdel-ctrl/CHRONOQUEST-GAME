// Gates (GAMEPLAY-V2.md Section 6): one per level, at the exit, asking no
// question. It opens by itself when every artifact has been answered, and
// until then it holds the player and says how many are left.
//
// Also guards the 2026-10-01 softlock: a gate blocks the full corridor and
// cannot be jumped, and the clamp in `PlayerComponent.update()` parks the
// player 8px short of it, so their hitboxes never overlap. Anything keyed to
// onCollisionStart therefore never fires; the decision lives in update().
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/gate_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_input.dart';

class _GateGame extends ChronoGame {
  _GateGame({this.artifacts = 0, this.answered = 0}) {
    currentEra = 'pre-colonial';
    currentLevel = 1;
  }

  final int artifacts;
  final int answered;

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
    // No setupSpawning(): these tests place one gate by hand so nothing else
    // can be what stops the player.
    artifactsTotal = artifacts;
    artifactsAnswered = answered;
  }
}

Future<_GateGame> _mount(
  WidgetTester tester,
  GateComponent gate, {
  int artifacts = 0,
  int answered = 0,
}) async {
  final game = _GateGame(artifacts: artifacts, answered: answered);
  await tester.pumpWidget(
    MaterialApp(
      home: GameWidget(
        game: game,
        // A bare GameWidget has no overlay builders registered, and
        // `overlays.add` asserts on an unknown name.
        overlayBuilderMap: {
          'GateLockedOverlay': (_, __) => const SizedBox.shrink(),
        },
      ),
    ),
  );
  await tester.pump();
  game.world.add(gate);
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
  return game;
}

void main() {
  testWidgets('a gate with every artifact answered opens by itself, no question',
      (tester) async {
    final gate = GateComponent(worldX: 600);
    final game = await _mount(tester, gate, artifacts: 3, answered: 3);

    game.player.position.x = gate.blockX - game.player.size.x + 4;
    await tester.pump(const Duration(milliseconds: 16));

    expect(gate.opened, isTrue,
        reason: 'the requirement is met, so reaching the gate opens it');
    expect(game.questionShowing, isFalse,
        reason: 'the gate asks nothing; every question is on an artifact');
    expect(game.currentQuestion, isNull);
  });

  testWidgets('a gate with artifacts left stays shut and explains why',
      (tester) async {
    final gate = GateComponent(worldX: 600);
    final game = await _mount(tester, gate, artifacts: 10, answered: 4);

    final limit = gate.blockX - game.player.size.x;
    game.player.position.x = limit + 40;
    await tester.pump(const Duration(milliseconds: 16));

    expect(gate.opened, isFalse);
    expect(game.player.position.x, limit,
        reason: 'a locked gate must still be a hard stop');
    expect(game.gateLockedNoticeShowing, isTrue,
        reason: 'the student must be told why they are stopped — a silent '
            'wall reads as a broken game');
    expect(game.questionShowing, isFalse);
    expect(game.artifactsRemaining, 6);
  });

  testWidgets('the standoff is what made a collision-based check never fire',
      (tester) async {
    // Regression for the 2026-10-01 softlock: the clamp parks the player 8px
    // short of the gate, so their hitboxes never overlap and anything keyed
    // to onCollisionStart never runs. The decision lives in update() instead.
    final gate = GateComponent(worldX: 600);
    await _mount(tester, gate);

    expect(
      gate.blockX,
      gate.position.x - CombatConstants.gateStandoff,
    );
  });

  testWidgets('an opened gate stops blocking', (tester) async {
    final gate = GateComponent(worldX: 600);
    final game = await _mount(tester, gate);

    gate.open();
    expect(gate.isBlocking, isFalse);

    // Walk straight through where it stood.
    final past = gate.position.x + gate.size.x + 50;
    game.player.position.x = past;
    await tester.pump(const Duration(milliseconds: 16));

    expect(game.player.position.x, past,
        reason: 'an opened gate must not keep clamping the player');
  });
}
