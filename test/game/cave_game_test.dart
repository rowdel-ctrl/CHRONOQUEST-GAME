// The underground cave (the 2026-11 update): a pipe in the road of some levels takes
// the student down to a cave of their own, where the level's last artifact is. The
// level still counts ten artifacts, the gate opens only once the cave's artifact
// is answered, and the way back is the pipe at the end of the cave.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chronoquest/core/cave_constants.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/data/question_pool.dart';
import 'package:chronoquest/game/answer_point_handler.dart';
import 'package:chronoquest/game/cave/cave_game.dart';
import 'package:chronoquest/game/cave/cave_obstacle_components.dart';
import 'package:chronoquest/game/cave/cave_scenery.dart';
import 'package:chronoquest/game/cave/cave_session.dart';
import 'package:chronoquest/game/cave_handler.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/artifact_component.dart';
import 'package:chronoquest/game/components/coin_component.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/pipe_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_input.dart';
import 'package:chronoquest/game/level_loader.dart';
import 'package:chronoquest/models/question.dart';
import 'package:chronoquest/models/quiz_result.dart';
import 'package:chronoquest/services/audio_service.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart' show AudioPool;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// A level with a long floor, a pipe standing on it and a hero beside it.
class _PipeLevel extends ChronoGame {
  _PipeLevel() {
    currentEra = 'spanish';
    currentLevel = 2;
  }

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(GroundSection(
      sectionWidth: 6000,
      sectionPosition: Vector2(0, groundY),
      drawn: false,
    ));
    player = PlayerComponent(characterId: 'rizal')
      ..size = Vector2(96, 120)
      ..position = Vector2(300, groundY - 120);
    world.add(player);
    gameInput = GameInput(game: this);
    gameInput.setup();
  }
}

Future<void> _settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
}

QuestionPool _pool(String era) => QuestionPool(questions: [
      for (final id in ['q1', 'q2', 'q3'])
        Question(
          id: id,
          era: era,
          questionText: 'Sample $id?',
          options: const [
            QuestionOption(label: 'A', text: 'right'),
            QuestionOption(label: 'B', text: 'wrong'),
          ],
          correctAnswer: 'A',
        ),
    ]);

Future<_PipeLevel> _mountLevel(WidgetTester tester) async {
  final game = _PipeLevel();
  await tester.pumpWidget(MaterialApp(
    home: GameWidget(
      game: game,
      overlayBuilderMap: {'QuestionOverlay': (_, __) => const SizedBox.shrink()},
    ),
  ));
  await tester.pump();
  await _settle(tester);
  game.questionPool = _pool('spanish');
  game.artifactsTotal = 10;
  game.artifactsAnswered = 9; // the road is done: the cave's is the last one
  return game;
}

Future<PipeComponent> _addPipe(WidgetTester tester, _PipeLevel game,
    {double x = 1200}) async {
  final pipe = PipeComponent(centerX: x, eraId: 'spanish');
  game.world.add(pipe);
  await _settle(tester, frames: 6);
  return pipe;
}

/// Puts the hero on top of the pipe, feet on its top.
void _standOn(_PipeLevel game, PipeComponent pipe) {
  game.player.position =
      Vector2(pipe.centerX - game.player.size.x / 2, pipe.topY - game.player.size.y);
}

void _run(ChronoGame game, double seconds) {
  var left = seconds;
  while (left > 1e-9) {
    final dt = left < 1 / 60 ? left : 1 / 60;
    game.player.update(dt);
    for (final p in game.world.children.whereType<PipeComponent>()) {
      p.update(dt);
    }
    left -= dt;
  }
}

/// A widget test that, once it has said what it has to, lets the hero's short
/// reactions finish, so no timer is left pending.
void _test(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    await body(tester);
    await tester.pump(const Duration(seconds: 1));
  });
}

Future<CaveGame> _mountCave(WidgetTester tester, ChronoGame level) async {
  final game = CaveGame(level: level);
  await tester.pumpWidget(MaterialApp(
    home: GameWidget(
      game: game,
      overlayBuilderMap: {'QuestionOverlay': (_, __) => const SizedBox.shrink()},
    ),
  ));
  await tester.pump();
  bool built() =>
      game.isLoaded &&
      game.player.isLoaded &&
      game.world.children.whereType<CoinComponent>().length ==
          game.layout.coins.length &&
      game.world.children.whereType<EnemyComponent>().length ==
          game.layout.enemies.length &&
      game.world.children.whereType<ArtifactComponent>().isNotEmpty &&
      game.exitPipe != null &&
      game.exitPipe!.isLoaded;
  for (var i = 0; i < 300 && !built(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.pump(const Duration(milliseconds: 16));
  expect(built(), isTrue);
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageDir =
      Directory.systemTemp.createTempSync('chronoquest_cave_test_').path;

  setUpAll(() async {
    AudioService().setSoundEnabled(false);
    // The cave loads like a real level, which asks for its sound pools: give it none
    // (there is no sound plugin in a test).
    AudioService().poolFactory =
        (file) => Future<AudioPool>.error(StateError('no sound in a test'));
    Hive.init(storageDir);
    await Hive.openBox('chronoquest');
  });


  // Not a check: with CAVE_SHOTS set to a folder, saves pictures of the cave and of the
  // pipe in a level, for looking at.
  testWidgets('saves pictures when CAVE_SHOTS is set', (tester) async {
    final dir = Platform.environment['CAVE_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(1560, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    Future<void> save(String name) async {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await boundary.toImage();
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$dir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    for (final era in ['pre-colonial', 'spanish', 'modern']) {
      final level = _PipeLevel()..currentEra = era;
      await tester.pumpWidget(MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: GameWidget(
            game: level,
            overlayBuilderMap: {'QuestionOverlay': (_, __) => const SizedBox.shrink()},
          ),
        ),
      ));
      await tester.pump();
      await _settle(tester);
      final pipe = PipeComponent(centerX: 1200, eraId: era);
      level.world.add(pipe);
      await _settle(tester, frames: 8);
      level.artifactsTotal = 10;
      level.artifactsAnswered = 9;
      level.player.position = Vector2(700, level.groundY - 120);
      for (var i = 0; i < 30; i++) {
        level.update(1 / 60);
      }
      await save('level_pipe_$era');

      final cave = CaveGame(level: level..currentEra = era);
      await tester.pumpWidget(MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: GameWidget(
            game: cave,
            overlayBuilderMap: {'QuestionOverlay': (_, __) => const SizedBox.shrink()},
          ),
        ),
      ));
      await tester.pump();
      for (var i = 0; i < 300 && !(cave.isLoaded && cave.exitPipe != null && cave.exitPipe!.isLoaded); i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await _settle(tester, frames: 10);
      await save('cave_start_$era');
      // The middle of the cave.
      final mid = cave.layout.pits.first;
      cave.player.position = Vector2(mid.x0 - 200, cave.groundY - 120);
      for (var i = 0; i < 40; i++) {
        cave.update(1 / 60);
      }
      await save('cave_pit_$era');
      // The artifact room with the exit pipe open.
      cave.artifactsAnswered = 1;
      cave.player.position = Vector2(CaveConstants.exitPipeX - 520, cave.groundY - 120);
      for (var i = 0; i < 40; i++) {
        cave.update(1 / 60);
      }
      await save('cave_exit_$era');
    }
    await tester.pump(const Duration(seconds: 1));
  });

  // ─── the pipe in the level ─────────────────────────────────────────────────
  group('the pipe in the level', () {
    _test('standing on it for a moment takes the student down', (tester) async {
      final game = await _mountLevel(tester);
      final pipe = await _addPipe(tester, game);
      CaveRequest? seen;
      game.cave.onEnter = (r) async {
        seen = r;
        return null;
      };
      expect(game.cave.pipe, same(pipe), reason: 'the level knows its pipe');

      _standOn(game, pipe);
      _run(game, .1);
      expect(seen, isNull, reason: 'not yet: 0.25 s on top');
      _run(game, .5);
      expect(seen, isNotNull);
      expect(seen!.level, same(game));
    });

    _test('walking past it, or jumping over it, does nothing', (tester) async {
      final game = await _mountLevel(tester);
      final pipe = await _addPipe(tester, game);
      var shown = 0;
      game.cave.onEnter = (r) async {
        shown++;
        return null;
      };
      // Beside it, on the floor.
      game.player.position = Vector2(pipe.centerX - 250, game.groundY - 120);
      _run(game, 1);
      // High above it, in the air.
      game.player.position = Vector2(pipe.centerX - 48, pipe.topY - 300);
      _run(game, .1);
      expect(shown, 0);
    });

    _test('the pipe is a wall: it has to be jumped, with a top to land on',
        (tester) async {
      final game = await _mountLevel(tester);
      final pipe = await _addPipe(tester, game);
      final raised = game.groundSections.where((s) =>
          (s.position.y - pipe.topY).abs() < 1 &&
          s.position.x < pipe.centerX &&
          s.position.x + s.size.x > pipe.centerX);
      expect(raised, isNotEmpty);
      expect(CaveConstants.pipeHeight, greaterThan(24),
          reason: 'more than a step: it must be jumped');
      expect(CaveConstants.pipeHeight, lessThan(128),
          reason: 'under the peak of a jump');
    });

    _test('a level with no pipe, or a bare game, is not touched', (tester) async {
      final game = await _mountLevel(tester);
      final pipe = await _addPipe(tester, game);
      _standOn(game, pipe);
      _run(game, 1); // no screen to show the cave with: nothing happens
      expect(game.cave.away, isFalse);
      expect(game.levelEnded, isFalse);
    });

    _test('the pipe is the way on once the road is done, and not before',
        (tester) async {
      final game = await _mountLevel(tester);
      await _addPipe(tester, game);
      expect(game.pipeIsTheWay, isTrue, reason: '9 of 10 answered');
      game.artifactsAnswered = 6;
      expect(game.pipeIsTheWay, isFalse, reason: 'four artifacts are still on the road');
      game.artifactsAnswered = 9;
      game.cave.done = true;
      expect(game.pipeIsTheWay, isFalse);
    });

    _test('how far the pipe is counts down as the student walks', (tester) async {
      final game = await _mountLevel(tester);
      final pipe = await _addPipe(tester, game);
      game.player.position = Vector2(pipe.centerX - 600, game.groundY - 120);
      final far = game.pipeDistanceUnits()!;
      game.player.position = Vector2(pipe.centerX - 300, game.groundY - 120);
      final near = game.pipeDistanceUnits()!;
      expect(near, lessThan(far));
      expect(game.gateDistanceUnits(), isNull, reason: 'the gate is not the way yet');
    });
  });

  // ─── coming back up ────────────────────────────────────────────────────────
  group('back from the cave', () {
    Future<(_PipeLevel, PipeComponent)> ready(WidgetTester tester) async {
      final game = await _mountLevel(tester);
      final pipe = await _addPipe(tester, game);
      return (game, pipe);
    }

    CaveResult answeredRight({int hearts = 5}) => CaveResult(
          answered: true,
          claimed: true,
          answers: const [
            QuestionSnapshot(
              questionId: 'q9',
              questionText: 'Sample?',
              studentAnswer: 'right',
              correctAnswer: 'right',
              isCorrect: true,
              timeTaken: 4,
            ),
          ],
          coins: 7,
          score: 15,
          kaalaman: 3,
          hearts: hearts,
        );

    _test('the cave artifact counts as the level\'s tenth, once', (tester) async {
      final (game, pipe) = await ready(tester);
      game.cave.onEnter = (r) async => answeredRight(hearts: 4);
      game.hearts = 5;
      await game.enterCavePipe(pipe);

      expect(game.artifactsAnswered, 10);
      expect(game.artifactsClaimed, 1);
      expect(game.canPassEndGate, isTrue, reason: 'the gate may open now');
      expect(game.cave.done, isTrue);
      expect(pipe.done, isTrue);
      expect(game.answers.length, 1, reason: 'the answer reaches the level\'s list');
      expect(game.playerCoins, 7);
      expect(game.score, 15);
      expect(game.hearts, 4, reason: 'what the cave took is gone from the level too');
      expect(game.kaalaman, 3);
      expect(game.cave.away, isFalse);

      // A second trip is not offered.
      var shown = 0;
      game.cave.onEnter = (r) async {
        shown++;
        return null;
      };
      await game.enterCavePipe(pipe);
      expect(shown, 0);
    });

    _test('the student is put back beside the pipe, not on top of it',
        (tester) async {
      final (game, pipe) = await ready(tester);
      game.cave.onEnter = (r) async => answeredRight();
      _standOn(game, pipe);
      await game.enterCavePipe(pipe);
      expect(game.player.position.x, greaterThan(pipe.centerX + 60));
      expect(pipe.studentOnTop, isFalse);
    });

    _test('leaving without answering changes nothing, and the pipe still works',
        (tester) async {
      final (game, pipe) = await ready(tester);
      game.hearts = 5;
      game.cave.onEnter = (r) async => const CaveResult(hearts: 5, kaalaman: 5);
      await game.enterCavePipe(pipe);
      expect(game.artifactsAnswered, 9);
      expect(game.cave.done, isFalse);
      expect(pipe.done, isFalse);
      expect(game.cave.away, isFalse);

      // After the rest, standing on it takes the student down again.
      var shown = 0;
      game.cave.onEnter = (r) async {
        shown++;
        return null;
      };
      _standOn(game, pipe);
      _run(game, 2.5);
      expect(shown, 1);
    });

    _test('a cave that could not be shown carries on as normal', (tester) async {
      final (game, pipe) = await ready(tester);
      game.cave.onEnter = (r) async => throw StateError('no screen');
      await game.enterCavePipe(pipe);
      expect(game.cave.away, isFalse);
      expect(game.artifactsAnswered, 9);
      expect(game.levelEnded, isFalse);
    });

    _test('the last heart lost in the cave fails the level', (tester) async {
      final (game, pipe) = await ready(tester);
      var failed = 0;
      game.onLevelFailed = () => failed++;
      game.cave.onEnter =
          (r) async => const CaveResult(failed: true, hearts: 0, answered: false);
      await game.enterCavePipe(pipe);
      expect(failed, 1);
      expect(game.levelEnded, isTrue);
    });
  });

  // ─── the cave itself ───────────────────────────────────────────────────────
  group('the cave', () {
    _test('builds its whole map, with the artifact and an exit pipe that waits',
        (tester) async {
      final level = await _mountLevel(tester);
      level.hearts = 3;
      final cave = await _mountCave(tester, level);

      expect(cave.artifactsTotal, 1);
      expect(cave.hearts, 3, reason: 'the cave plays with the level\'s hearts');
      expect(cave.world.children.whereType<ArtifactComponent>().length, 1);
      expect(cave.world.children.whereType<ArtifactComponent>().first.golden, isFalse,
          reason: 'never a golden artifact down here');
      expect(cave.exitPipe!.isExit, isTrue);
      expect(cave.exitPipe!.enabled, isFalse, reason: 'the way out opens after the question');
      expect(cave.player.position.x, closeTo(CaveConstants.spawnX, 1));
    });

    _test('builds the obstacles its level has: all four from level 8',
        (tester) async {
      final level = await _mountLevel(tester);
      level.currentEra = 'pre-colonial';
      level.currentLevel = 8;
      final cave = await _mountCave(tester, level);
      await _settle(tester, frames: 6);
      final kids = cave.world.children;
      expect(kids.whereType<CaveSpikesComponent>().length,
          cave.layout.spikes.length);
      expect(kids.whereType<CaveSpikesComponent>().length, 2);
      expect(kids.whereType<CaveStalactiteComponent>().length,
          cave.layout.stalactites.length);
      expect(kids.whereType<CaveStalactiteComponent>().length, 2);
      expect(kids.whereType<CaveCrusherComponent>().length, 1);
      final crumbling = cave.layout.platforms.where((p) => p.crumbling).length;
      expect(crumbling, inInclusiveRange(1, 2));
      expect(kids.whereType<CrumblingSlabComponent>().length, crumbling);
      expect(kids.whereType<CavePlatformComponent>().length,
          cave.layout.platforms.length,
          reason: 'a crumbling slab is a slab too: none is left out');
    });

    _test('an early cave has only spikes', (tester) async {
      final level = await _mountLevel(tester); // level 2
      final cave = await _mountCave(tester, level);
      await _settle(tester, frames: 6);
      final kids = cave.world.children;
      expect(kids.whereType<CaveSpikesComponent>().length, 2);
      expect(kids.whereType<CaveStalactiteComponent>(), isEmpty);
      expect(kids.whereType<CaveCrusherComponent>(), isEmpty);
      expect(kids.whereType<CrumblingSlabComponent>(), isEmpty);
    });

    _test('the exit pipe opens once the artifact is answered, right or wrong',
        (tester) async {
      final level = await _mountLevel(tester);
      final cave = await _mountCave(tester, level);
      final artifact = cave.world.children.whereType<ArtifactComponent>().first;

      cave.showArtifactQuestion(artifact);
      cave.handleAnswerPointAnswer('definitely-wrong'); // a wrong answer counts too
      cave.update(1 / 60);
      expect(cave.artifactsAnswered, 1);
      expect(cave.exitPipe!.enabled, isTrue);
      expect(cave.result().answered, isTrue);
      expect(cave.result().claimed, isFalse);
      expect(cave.result().answers.length, 1);
    });

    _test('standing on the open exit pipe takes the student back up',
        (tester) async {
      final level = await _mountLevel(tester);
      final cave = await _mountCave(tester, level);
      var finished = 0;
      cave.onFinish = () => finished++;
      final pipe = cave.exitPipe!;

      // Shut: standing on it does nothing.
      cave.player.position =
          Vector2(pipe.centerX - 48, pipe.topY - cave.player.size.y);
      for (var i = 0; i < 60; i++) {
        cave.player.update(1 / 60);
        pipe.update(1 / 60);
      }
      expect(finished, 0);

      // Answer, then stand on it.
      final artifact = cave.world.children.whereType<ArtifactComponent>().first;
      cave.showArtifactQuestion(artifact);
      cave.handleAnswerPointAnswer(cave.currentQuestion!.correctAnswer);
      cave.update(1 / 60);
      cave.player.position =
          Vector2(pipe.centerX - 48, pipe.topY - cave.player.size.y);
      for (var i = 0; i < 60; i++) {
        cave.player.update(1 / 60);
        pipe.update(1 / 60);
      }
      expect(finished, 1);
      final r = cave.result();
      expect(r.answered, isTrue);
      expect(r.claimed, isTrue);
      expect(r.failed, isFalse);
    });

    _test('the last heart lost in the cave ends it as failed', (tester) async {
      final level = await _mountLevel(tester);
      level.hearts = 1;
      final cave = await _mountCave(tester, level);
      var finished = 0;
      cave.onFinish = () => finished++;
      cave.loseLife();
      expect(cave.failed, isTrue);
      expect(finished, 1);
      expect(cave.result().failed, isTrue);
      expect(cave.result().hearts, 0);
    });

    _test('the hearts, coins and power-ups are the level\'s own', (tester) async {
      final level = await _mountLevel(tester);
      var lost = 0, coins = 0;
      level.onHeartLost = () => lost++;
      level.onCoinCollected = () => coins++;
      final cave = await _mountCave(tester, level);
      cave.loseLife();
      cave.collectCoin();
      expect(lost, 1, reason: 'a heart lost down there leaves the wallet at once');
      expect(coins, 1);
      expect(identical(cave.playerPowerUps, level.playerPowerUps), isTrue);
    });
  });

  // ─── the maps carry the pipe ───────────────────────────────────────────────
  group('a pipe level is built with its pipe', () {
    _test('nine artifacts on the road, one pipe, and still ten counted',
        (tester) async {
      final text =
          File('assets/tiles/levels/era2_2.tmx').readAsStringSync();
      final map = LevelLoader.parse(text);
      final world = Component();
      LevelBuilder.build(
        level: map,
        world: world,
        groundY: 660,
        eraId: 'spanish',
        levelNo: 2,
      );
      await tester.pump();
      expect(world.children.whereType<PipeComponent>().length, 1);
      expect(world.children.whereType<ArtifactComponent>().length, 9);
      expect(map.entities.where((e) => e.type == 'artifact').length, 10);
    });

    _test('a level with no pipe keeps all ten artifacts', (tester) async {
      final map = LevelLoader.parse(
          File('assets/tiles/levels/era2_3.tmx').readAsStringSync());
      final world = Component();
      LevelBuilder.build(
        level: map,
        world: world,
        groundY: 660,
        eraId: 'spanish',
        levelNo: 3,
      );
      await tester.pump();
      expect(world.children.whereType<PipeComponent>(), isEmpty);
      expect(world.children.whereType<ArtifactComponent>().length, 10);
    });

    _test('level 1 and the boss room never have one', (tester) async {
      expect(CaveConstants.hasPipe('spanish', 1), isFalse);
      expect(CaveConstants.hasPipe('spanish', 5), isFalse);
      expect(CaveConstants.hasPipe('spanish', 2), isTrue);
      expect(allEras.every((e) => !CaveConstants.hasPipe(e.id, e.levels.length)), isTrue);
    });
  });
}
