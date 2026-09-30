// Artifacts and gates (GAMEPLAY-V2.md Section 6) — the answer points that
// replace enemies as the game's question triggers.
//
// Components are mounted through a real GameWidget rather than the bare-game
// pattern: their sprite, size and hitbox are all set in onLoad(), and the
// claim/crumble effects only tick once genuinely mounted (see
// enemy_death_test.dart's header for why a bare ChronoGame cannot).
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/artifact_component.dart';
import 'package:chronoquest/game/components/gate_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_spawning.dart';

class _PointGame extends ChronoGame {
  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    camera.viewfinder.anchor = Anchor.topLeft;
    player = PlayerComponent(characterId: 'rizal')
      ..size = Vector2(96, 120)
      ..position = Vector2(0, groundY - 120);
    setupSpawning();
  }
}

Future<_PointGame> _mount(WidgetTester tester, Component component) async {
  final game = _PointGame();
  await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  game.world.add(component);
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
  return game;
}

void main() {
  group('ArtifactComponent', () {
    testWidgets('starts interactable and rewards the full amount',
        (tester) async {
      final a = ArtifactComponent(worldX: 900, spriteIndex: 1);
      await _mount(tester, a);

      expect(a.isInteractable, true);
      expect(a.reward, CombatConstants.artifactReward);
    });

    testWidgets('a wrong answer makes it inert and halves the reward',
        (tester) async {
      final a = ArtifactComponent(worldX: 900, spriteIndex: 1);
      await _mount(tester, a);

      a.goInert();

      expect(a.isInert, true);
      expect(a.isInteractable, false,
          reason: 'an inert artifact must not re-open a question');
      expect(a.reward, CombatConstants.artifactRetryReward);
    });

    testWidgets('re-lights after the inert window and is interactable again',
        (tester) async {
      final a = ArtifactComponent(worldX: 900, spriteIndex: 1);
      final game = await _mount(tester, a);

      a.goInert();
      expect(a.isInteractable, false);

      // Drive past the 5s window.
      for (var i = 0; i < 40; i++) {
        game.updateTree(CombatConstants.artifactInertSeconds / 20);
      }

      expect(a.isInert, false);
      expect(a.isInteractable, true,
          reason: 'Section 6: it goes inert, then re-lights');
      expect(a.reward, CombatConstants.artifactRetryReward,
          reason: 'the reduced reward is permanent for this artifact');
    });

    testWidgets('claiming stops it being interactable', (tester) async {
      final a = ArtifactComponent(worldX: 900, spriteIndex: 1);
      await _mount(tester, a);

      a.claim();

      expect(a.claimed, true);
      expect(a.isInteractable, false);
    });

    testWidgets('floats above the ground rather than sitting on it',
        (tester) async {
      final a = ArtifactComponent(worldX: 900, spriteIndex: 1);
      final game = await _mount(tester, a);

      expect(a.position.y, lessThan(game.groundY - a.size.y),
          reason: 'Section 6 describes a floating object');
    });
  });

  group('GateComponent', () {
    testWidgets('blocks until opened', (tester) async {
      final g = GateComponent(worldX: 1200);
      await _mount(tester, g);

      expect(g.isBlocking, true);

      g.open();

      expect(g.opened, true);
      expect(g.isBlocking, false);
    });

    testWidgets('is tall enough that it cannot be jumped', (tester) async {
      final g = GateComponent(worldX: 1200);
      await _mount(tester, g);

      // The jump peaks at jumpForce^2 / (2*gravity) ~= 128 units.
      const jumpPeak = 480.0 * 480.0 / (2 * 900.0);
      expect(g.size.y, greaterThan(jumpPeak),
          reason: 'Section 6: "A gate blocks the full height of the '
              'corridor — you cannot jump it."');
    });

    testWidgets('holds the player in front of it, not inside it',
        (tester) async {
      final g = GateComponent(worldX: 1200);
      await _mount(tester, g);

      expect(g.blockX, lessThan(g.position.x));
    });
  });

  group('level layout', () {
    testWidgets('places exactly the specified gates and artifacts',
        (tester) async {
      final game = _PointGame();
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }

      final gates = game.world.children.whereType<GateComponent>().length;
      final artifacts =
          game.world.children.whereType<ArtifactComponent>().length;

      expect(gates, CombatConstants.gatesPerLevel,
          reason: 'Section 6: "Put 3 gates in every level" — this is the '
              'educational floor');
      expect(artifacts, CombatConstants.artifactsPerLevel);
    });

    testWidgets('the first answer point is an artifact, not a gate',
        (tester) async {
      // Charges come only from artifacts. Meeting a gate first would be a
      // dead start: nothing to have earned, and an attack button that has
      // never worked.
      final game = _PointGame();
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }

      final firstGate = game.world.children
          .whereType<GateComponent>()
          .map((g) => g.worldX)
          .reduce((a, b) => a < b ? a : b);
      final firstArtifact = game.world.children
          .whereType<ArtifactComponent>()
          .map((a) => a.worldX)
          .reduce((a, b) => a < b ? a : b);

      expect(firstArtifact, lessThan(firstGate));
    });
  });
}
