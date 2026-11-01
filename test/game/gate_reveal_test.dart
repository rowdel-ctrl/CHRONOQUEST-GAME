// When the last artifact is answered the camera goes to the end gate, the door
// lifts, and the camera comes back to the student. The world stands still for
// those few seconds, and Jump or Attack skips it.
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/data/question_pool.dart';
import 'package:chronoquest/game/answer_point_handler.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/artifact_component.dart';
import 'package:chronoquest/game/components/gate_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_input.dart';
import 'package:chronoquest/game/gate_reveal.dart';
import 'package:chronoquest/models/question.dart';

class _RevealGame extends ChronoGame {
  _RevealGame() {
    currentEra = 'pre-colonial';
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
    artifactsTotal = 2;
  }
}

class _Rig {
  final _RevealGame game;
  final GateComponent gate;
  final List<ArtifactComponent> artifacts;
  _Rig(this.game, this.gate, this.artifacts);
}

Future<_Rig> _mount(WidgetTester tester) async {
  final game = _RevealGame();
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
  final artifacts = [
    ArtifactComponent(worldX: 400, spriteIndex: 1),
    ArtifactComponent(worldX: 800, spriteIndex: 2),
  ];
  game.world.add(gate);
  game.world.addAll(artifacts);
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 16));
  }
  game.questionPool = QuestionPool(questions: [
    Question(
      id: 'q1',
      era: 'pre-colonial',
      questionText: 'Sample?',
      options: [
        const QuestionOption(label: 'A', text: 'right'),
        const QuestionOption(label: 'B', text: 'wrong'),
      ],
      correctAnswer: 'A',
    ),
  ]);
  return _Rig(game, gate, artifacts);
}

void _answer(_Rig rig, int i) {
  rig.game.showArtifactQuestion(rig.artifacts[i]);
  rig.game.handleAnswerPointAnswer('definitely-wrong'); // a wrong answer counts too, and needs no saved Kodeks
}

/// Runs the world for [seconds] in 1/60 s frames; returns the camera's left
/// edge after each frame.
List<double> _run(ChronoGame game, double seconds) {
  final xs = <double>[];
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    game.updateTree(1 / 60);
    xs.add(game.cameraLeftEdgeX);
  }
  return xs;
}

void main() {
  _test('answering the last artifact starts the trip to the gate', (tester) async {
    final rig = await _mount(tester);

    _answer(rig, 0);
    expect(rig.game.gateReveal, isNull, reason: 'one artifact is still left');

    _answer(rig, 1);
    expect(rig.game.gateReveal, isNotNull);
    expect(rig.gate.doorOpen, 0, reason: 'the door has not moved yet');
  });

  _test('the camera goes to the gate, the door opens, and the camera comes back',
      (tester) async {
    final rig = await _mount(tester);
    final game = rig.game;
    final home = game.cameraLeftEdgeX;
    _answer(rig, 0);
    _answer(rig, 1);
    final reveal = game.gateReveal!;

    final xs = _run(game, reveal.totalSeconds + 0.2);

    final farthest = xs.reduce((a, b) => a > b ? a : b);
    expect(farthest, greaterThan(home + 500),
        reason: 'the camera left the student and travelled towards the gate');
    expect(farthest + game.size.x, greaterThan(rig.gate.position.x + rig.gate.size.x / 2),
        reason: 'the gate was in view at the far end');
    expect(rig.gate.doorOpen, 1);
    expect(rig.gate.opened, isTrue);
    expect(rig.gate.isBlocking, isFalse, reason: 'open for walking through');
    expect(rig.gate.entered, isFalse, reason: 'nobody has gone in yet');
    expect(rig.gate.isMounted, isTrue, reason: 'the gate stays; it does not crumble');
    expect(game.gateReveal, isNull);
    expect(game.gateRevealCameraX, isNull);
    expect(game.cameraLeftEdgeX, home, reason: 'back on the student');
  });

  _test('the door only starts to lift once the camera has arrived', (tester) async {
    final rig = await _mount(tester);
    _answer(rig, 0);
    _answer(rig, 1);
    final reveal = rig.game.gateReveal!;

    expect(reveal.doorAt(reveal.panSeconds * 0.5), 0);
    expect(reveal.doorAt(reveal.totalSeconds), 1);
    // Smoothly: it never jumps backwards or past fully open.
    var last = 0.0;
    for (var t = 0.0; t <= reveal.totalSeconds; t += 0.05) {
      final d = reveal.doorAt(t);
      expect(d, greaterThanOrEqualTo(last));
      expect(d, lessThanOrEqualTo(1));
      last = d;
    }
  });

  _test('nothing in the world moves while it plays', (tester) async {
    final rig = await _mount(tester);
    final game = rig.game;
    _answer(rig, 0);
    _answer(rig, 1);
    final playerX = game.player.position.x;
    final time = game.currentTime();

    _run(game, 1.0);

    expect(game.player.position.x, playerX);
    expect(game.gateReveal, isNotNull, reason: 'still playing after one second');
    expect(game.currentTime(), time);
  });

  _test('Jump skips it: the door is open and the camera is back at once', (tester) async {
    final rig = await _mount(tester);
    final game = rig.game;
    final home = game.cameraLeftEdgeX;
    _answer(rig, 0);
    _answer(rig, 1);
    _run(game, 0.8);
    expect(game.cameraLeftEdgeX, isNot(home));

    final vy = game.player.velocityY;
    game.onPlayerJump();

    expect(game.gateReveal, isNull);
    expect(rig.gate.doorOpen, 1);
    expect(game.cameraLeftEdgeX, home);
    expect(game.player.velocityY, vy, reason: 'the press skipped; it did not also jump');
  });

  _test('the picture shakes while the grille goes up, and is still before and after',
      (tester) async {
    final rig = await _mount(tester);
    final game = rig.game;
    _answer(rig, 0);
    _answer(rig, 1);
    final reveal = game.gateReveal!;
    final doorStarts = reveal.panSeconds + GateReveal.holdBefore;

    var shakenBefore = 0.0, mostDuring = 0.0;
    while (game.gateReveal != null) {
      game.updateTree(1 / 60);
      final t = reveal.elapsed;
      final shake = game.cameraShake.length;
      if (t < doorStarts) shakenBefore = shakenBefore < shake ? shake : shakenBefore;
      if (t > doorStarts && shake > mostDuring) mostDuring = shake;
    }

    expect(shakenBefore, 0, reason: 'the camera glides to the gate without shaking');
    expect(mostDuring, greaterThan(3), reason: 'the grille shakes the picture');
    expect(mostDuring, lessThanOrEqualTo(GateReveal.shakeAmount * 1.3));
    expect(game.cameraShake.length, 0, reason: 'still again at the end');
    expect(game.camera.viewfinder.position.y, 0);
  });

  _test('Jump in the middle of the shaking stops it at once', (tester) async {
    final rig = await _mount(tester);
    final game = rig.game;
    _answer(rig, 0);
    _answer(rig, 1);
    final reveal = game.gateReveal!;
    while (reveal.elapsed < reveal.panSeconds + GateReveal.holdBefore + 0.5) {
      game.updateTree(1 / 60);
    }
    expect(game.cameraShake.length, greaterThan(0));

    game.onPlayerJump();

    expect(game.cameraShake.length, 0);
    expect(game.camera.viewfinder.position.y, 0);
  });

  _test('walking into the open gate is what ends the level, not touching it', (tester) async {
    final rig = await _mount(tester);
    final game = rig.game;
    game.levelEnded = false;
    _answer(rig, 0);
    _answer(rig, 1);
    _run(game, game.gateReveal!.totalSeconds + 0.2);
    final middle = rig.gate.position.x + rig.gate.size.x / 2;

    // At the front of the open gate: the grille is up, but this is not going in.
    game.player.position.x = rig.gate.position.x - game.player.size.x / 2;
    await tester.pump(const Duration(milliseconds: 16));
    expect(rig.gate.entered, isFalse);
    expect(game.player.position.x, rig.gate.position.x - game.player.size.x / 2,
        reason: 'an open gate does not hold the student back');

    // Middle of the doorway: in.
    game.player.position.x = middle - game.player.size.x / 2 + 2;
    await tester.pump(const Duration(milliseconds: 16));
    expect(rig.gate.entered, isTrue);

    game.levelEnded = true; // the real completion talks to the server; not this test
  });

  _test('a shut gate cannot be walked into', (tester) async {
    final rig = await _mount(tester);
    final game = rig.game;
    game.player.position.x = rig.gate.position.x + rig.gate.size.x / 2;
    await tester.pump(const Duration(milliseconds: 16));

    expect(rig.gate.entered, isFalse);
    expect(rig.gate.isBlocking, isTrue);
  });

  _test('the distance to the gate keeps counting once it is open, until the student is in',
      (tester) async {
    final rig = await _mount(tester);
    final game = rig.game;
    _answer(rig, 0);
    _answer(rig, 1);
    _run(game, game.gateReveal!.totalSeconds + 0.2);

    final far = game.gateDistanceUnits();
    expect(far, isNotNull, reason: 'the gate is open, but the student has not gone in');

    game.player.position.x = rig.gate.position.x - 200;
    final near = game.gateDistanceUnits()!;
    expect(near, lessThan(far!));
    expect(near, greaterThan(0));

    game.player.position.x = rig.gate.position.x + rig.gate.size.x / 2 - game.player.size.x / 2 + 2;
    await tester.pump(const Duration(milliseconds: 16));
    expect(rig.gate.entered, isTrue);
    expect(game.gateDistanceUnits(), isNull, reason: 'in: nothing left to walk');
    game.levelEnded = true;
  });

  _test('no gate in the level, no trip', (tester) async {
    final rig = await _mount(tester);
    rig.gate.removeFromParent();
    await tester.pump();
    await tester.pump();

    _answer(rig, 0);
    _answer(rig, 1);

    expect(rig.game.gateReveal, isNull);
  });
}

/// A cheer starts a 0.4 s timer; let it run out so the test ends clean.
void _test(String name, Future<void> Function(WidgetTester) body) =>
    testWidgets(name, (tester) async {
      await body(tester);
      await tester.pump(const Duration(seconds: 1));
    });
