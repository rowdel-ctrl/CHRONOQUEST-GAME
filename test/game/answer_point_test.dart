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
import 'package:chronoquest/data/question_pool.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/models/question.dart';
import 'package:chronoquest/game/answer_point_handler.dart';
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
    // Awaited: setupSpawning() became async in Phase 4 (it checks for an
    // authored .tmx first), so firing and forgetting it raced the test's
    // own pump loop and left the level empty.
    //
    // The default era here is 'spanish', which has no Tiled level yet, so
    // this still exercises the procedural placement these tests cover.
    await setupSpawning();
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

      expect(gates, 1,
          reason: 'one gate per level, standing at the exit');
      expect(gates, CombatConstants.gatesPerLevel);
      expect(artifacts, 10);
      expect(artifacts, CombatConstants.artifactsPerLevel);
      expect(game.artifactsTotal, artifacts,
          reason: 'the gate counts against what was actually placed');
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

    testWidgets('every artifact is reachable before the only gate',
        (tester) async {
      // The softlock that shipped on 2026-10-03: gates started requiring
      // every artifact to be answered, but procedural levels still put the
      // first of three gates a quarter of the way in with one artifact behind
      // it. The student was stopped and told to find artifacts they could not
      // reach. With one gate after every artifact that cannot happen, and
      // this pins it so a future layout change cannot bring it back.
      final game = _PointGame();
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }

      final gates = game.world.children.whereType<GateComponent>().toList();
      expect(gates, hasLength(1));
      expect(gates.single.isLevelExit, isTrue);

      for (final a in game.world.children.whereType<ArtifactComponent>()) {
        expect(a.worldX, lessThan(gates.single.worldX),
            reason: 'artifact at x=${a.worldX} sits past the gate that '
                'requires it');
      }
    });

    testWidgets('an artifact answered twice is counted once', (tester) async {
      // A Shield absorbs a wrong answer without marking the artifact
      // attempted, so counting off that flag would have counted it twice.
      final game = _PointGame();
      await tester.pumpWidget(MaterialApp(
        home: GameWidget(
          game: game,
          // A bare GameWidget has no overlay builders, and overlays.add
          // asserts on an unknown name.
          overlayBuilderMap: {
            'QuestionOverlay': (_, __) => const SizedBox.shrink(),
          },
        ),
      ));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Two questions so a retry can draw a different one; the bundled bank is
      // not loaded in this harness.
      game.questionPool = QuestionPool(questions: [
        for (final id in ['q1', 'q2'])
          Question(
            id: id,
            era: 'spanish',
            questionText: 'Sample $id?',
            options: [
              const QuestionOption(label: 'A', text: 'right'),
              const QuestionOption(label: 'B', text: 'wrong'),
            ],
            correctAnswer: 'A',
          ),
      ]);

      final artifact =
          game.world.children.whereType<ArtifactComponent>().first;
      game.showArtifactQuestion(artifact);
      game.shieldActive = true;
      game.handleAnswerPointAnswer('definitely-wrong');
      expect(game.artifactsAnswered, 1);

      game.showArtifactQuestion(artifact);
      game.handleAnswerPointAnswer('definitely-wrong');
      expect(game.artifactsAnswered, 1,
          reason: 'same artifact, second answer: still one');
    });
  });
}
