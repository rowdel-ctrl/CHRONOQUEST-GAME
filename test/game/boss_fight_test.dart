// The boss fight, end to end in a mounted game: every question of the level once, a wave of
// minions after every second one; a wrong answer or a timeout costs the boss nothing and the
// question comes back at the end; the boss falls when all of them have been answered right;
// three phases (shorter time, more minions); minions pay out Kaalaman.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chronoquest/data/question_pool.dart';
import 'package:chronoquest/game/boss_plan.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/boss_component.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/level_loader.dart';
import 'package:chronoquest/game/quiz_handler.dart';
import 'package:chronoquest/models/question.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Question _q(int i) => Question(
      id: 'q$i',
      era: 'spanish',
      questionText: 'Tanong $i',
      options: const [
        QuestionOption(label: 'A', text: 'Una'),
        QuestionOption(label: 'B', text: 'Pangalawa'),
        QuestionOption(label: 'C', text: 'Pangatlo'),
        QuestionOption(label: 'D', text: 'Pang-apat'),
      ],
      correctAnswer: 'A',
      explanation: '',
    );

/// The player's animations are only assigned by its real onLoad(); a stub is
/// enough here (same approach as contact_damage_test.dart).
Future<SpriteAnimation> _blankAnim() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 1, 1));
  final image = await recorder.endRecording().toImage(1, 1);
  return SpriteAnimation.spriteList([Sprite(image)], stepTime: 1.0);
}

class _BossGame extends ChronoGame {
  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    if (audioService.soundEnabled) audioService.toggleSound(); // no audio plugin in tests
    camera.viewfinder.anchor = Anchor.topLeft;
    player = PlayerComponent(characterId: 'rizal')
      ..size = Vector2(96, 120)
      ..position = Vector2(0, groundY - 120)
      ..walkAnimation = await _blankAnim()
      ..jumpAnim = await _blankAnim()
      ..hurtAnim = await _blankAnim();
    player.game = this;
    currentEra = 'spanish';
    currentLevel = 5; // the Pananakop ng Espanya boss level
    questionPool = QuestionPool(questions: [for (var i = 0; i < 22; i++) _q(i)]);
    bossPhase = true;
  }
}

Future<(_BossGame, BossComponent)> _start(WidgetTester tester, {LoadedLevel? arena}) async {
  final game = _BossGame();
  game.tiledLevel = arena;
  await tester.pumpWidget(MaterialApp(
    home: GameWidget(
      game: game,
      overlayBuilderMap: {
        'QuestionOverlay': (_, __) => const SizedBox.shrink(),
        'BossHealthOverlay': (_, __) => const SizedBox.shrink(),
      },
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  final boss = BossComponent(eraId: 'spanish', arena: arena);
  game.boss = boss;
  game.world.add(boss);
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 16));
  }
  return (game, boss);
}

// The pool reshuffles the options on every serve, so read the key off the
// question that is up.
String _right(_BossGame game) => game.currentQuestion!.correctAnswer;
String _wrong(_BossGame game) => game.currentQuestion!.options.map((o) => o.label).firstWhere((l) => l != _right(game));

/// Lets the component's own short delays (sprite flashes, the defeat pause)
/// run out, so no timer is left pending when the test ends.
Future<void> _flush(WidgetTester tester) => tester.pump(const Duration(seconds: 3));

/// Lets sprite loading (real file I/O) finish so new components mount.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Runs the world forward [seconds] in small steps (not while a question is up).
void _run(_BossGame game, double seconds) {
  for (var t = 0.0; t < seconds; t += 0.05) {
    if (game.questionShowing) return;
    game.updateTree(0.05);
  }
}

List<EnemyComponent> _minions(_BossGame game) => game.world.children.whereType<EnemyComponent>().toList();

/// Beats every minion of the wave that is up (each pays one Kaalaman charge).
void _beatWave(_BossGame game) {
  for (final m in _minions(game)) {
    m.takeHit();
    m.takeHit(); // a Heavy needs two
  }
}

/// Answers the question that is up, right or wrong, beats the wave that follows (if there is
/// one), and runs on until the next question is up.
Future<void> _round(WidgetTester tester, _BossGame game, {bool right = true}) async {
  expect(game.questionShowing, isTrue);
  game.handleAnswer(right ? _right(game) : _wrong(game));
  _run(game, 1.2);
  await _settle(tester);
  _beatWave(game);
  _run(game, 4);
}

/// Answers two questions right, so the first wave has come ([_run] stops short of the next
/// question: it is not asked until the wave is beaten).
Future<void> _firstWave(WidgetTester tester, _BossGame game) async {
  game.handleAnswer(_right(game));
  _run(game, 1.2);
  await _settle(tester);
  game.handleAnswer(_right(game));
  _run(game, 1.2);
  await _settle(tester);
}

void main() {
  arenaTests();

  testWidgets('the boss walks in and asks the first question', (tester) async {
    final (game, boss) = await _start(tester);
    _run(game, 20);
    expect(boss.reachedCenter, isTrue);
    expect(game.questionShowing, isTrue);
    expect(game.currentQuestion, isNotNull);
    expect(boss.health, 22, reason: 'one point of health for every question of the level');
    expect(boss.maxHealth, 22);
    expect(boss.answerSeconds, 15);
    await _flush(tester);
  });

  testWidgets('a right answer hurts the boss; a wave comes after every second question, not every one', (tester) async {
    final (game, boss) = await _start(tester);
    _run(game, 20);
    final first = game.currentQuestion!;

    game.handleAnswer(_right(game));
    expect(boss.health, 21);
    expect(game.questionShowing, isFalse);
    _run(game, 1.2);
    expect(_minions(game), isEmpty, reason: 'no wave after the first question');
    expect(game.questionShowing, isTrue);
    final second = game.currentQuestion!;
    expect(second.id, isNot(first.id));

    game.handleAnswer(_right(game));
    expect(boss.health, 20);
    _run(game, 1.2);
    await _settle(tester);
    expect(_minions(game), hasLength(BossPlan.minionsPerWave[0]));
    expect(game.questionShowing, isFalse, reason: 'the minions come before the next question');

    // Beat them: each pays one Kaalaman charge (from a bar that is not full, as the
    // full bar caps what they can add).
    game.kaalaman = 4;
    final before = game.kaalaman;
    _beatWave(game);
    expect(game.kaalaman, before + BossPlan.minionsPerWave[0]);

    _run(game, 2);
    expect(game.questionShowing, isTrue);
    expect({first.id, second.id}, isNot(contains(game.currentQuestion!.id)));
    await _flush(tester);
  });

  testWidgets('a wrong answer costs the boss nothing, and the question comes back at the end', (tester) async {
    final (game, boss) = await _start(tester);
    _run(game, 20);
    final missed = game.currentQuestion!.id;

    game.handleAnswer(_wrong(game));
    expect(boss.health, 22);
    _run(game, 3);
    expect(game.questionShowing, isTrue, reason: 'the fight goes straight on');

    // The other 21 questions, each once; the missed one is the last.
    final asked = <String>[];
    for (var n = 0; n < 21; n++) {
      asked.add(game.currentQuestion!.id);
      await _round(tester, game);
    }
    expect(asked.toSet(), hasLength(21));
    expect(asked, isNot(contains(missed)));
    expect(game.currentQuestion!.id, missed, reason: 'asked again, last');
    expect(boss.health, 1);
    expect(boss.answerSeconds, 10, reason: 'a question asked again gets the last phase\'s clock');

    game.handleAnswer(_right(game));
    expect(boss.isDefeated, isTrue);
    await _flush(tester);
  });

  testWidgets('a timeout is a wrong answer', (tester) async {
    final (game, boss) = await _start(tester);
    _run(game, 20);

    game.handleAnswer(''); // what the overlay sends when the clock runs out
    expect(boss.health, 22);
    expect(game.answers.last.isCorrect, isFalse);
    await _flush(tester);
  });

  testWidgets('a wave nobody clears does not trap the student', (tester) async {
    final (game, boss) = await _start(tester);
    _run(game, 20);
    await _firstWave(tester, game);
    expect(_minions(game), isNotEmpty);

    _run(game, 45); // longer than the wave timeout, minions left alone
    expect(game.questionShowing, isTrue);
    expect(boss.isDefeated, isFalse);
    await _flush(tester);
  });

  testWidgets('all 22 questions answered right defeat the boss', (tester) async {
    final (game, boss) = await _start(tester);
    _run(game, 20);

    for (var n = 1; n <= 22; n++) {
      expect(game.questionShowing, isTrue, reason: 'question $n');
      if (n < 22) {
        await _round(tester, game);
      } else {
        game.handleAnswer(_right(game));
      }
    }
    expect(boss.health, 0);
    expect(boss.isDefeated, isTrue);
    expect(game.answers, hasLength(22));
    expect(game.answers.map((a) => a.questionId).toSet(), hasLength(22), reason: 'every question exactly once');
    await _flush(tester);
  });

  testWidgets('three phases: less time and more minions, announced, ending on the final question', (tester) async {
    final (game, boss) = await _start(tester);
    _run(game, 20);

    // Phase 1: the first 10 questions, 15 seconds, waves of two.
    for (var n = 1; n <= 9; n++) {
      expect(boss.answerSeconds, 15, reason: 'question $n');
      await _round(tester, game);
    }
    expect(boss.answerSeconds, 15);
    game.handleAnswer(_right(game)); // the 10th
    _run(game, 1.2);
    await _settle(tester);
    expect(_minions(game), hasLength(2));
    _beatWave(game);
    _run(game, 1.0);
    expect(boss.banner, 'PHASE 2');
    expect(game.questionShowing, isFalse, reason: 'announced before it is asked');
    _run(game, 2);
    expect(boss.banner, isNull);
    expect(game.questionShowing, isTrue);

    // Phase 2: questions 11 to 16, 12 seconds, waves of three.
    expect(boss.answerSeconds, 12);
    await _round(tester, game); // the 11th: no wave
    expect(boss.answerSeconds, 12);
    game.handleAnswer(_right(game)); // the 12th: a wave
    _run(game, 1.2);
    await _settle(tester);
    expect(_minions(game), hasLength(3));
    _beatWave(game);
    _run(game, 4);
    for (var n = 13; n <= 15; n++) {
      await _round(tester, game);
    }
    game.handleAnswer(_right(game)); // the 16th
    _run(game, 1.2);
    await _settle(tester);
    _beatWave(game);
    _run(game, 1.0);
    expect(boss.banner, 'PHASE 3');
    _run(game, 2);

    // Phase 3: questions 17 to 22, 10 seconds, waves of four.
    expect(boss.answerSeconds, 10);
    await _round(tester, game); // the 17th
    game.handleAnswer(_right(game)); // the 18th
    _run(game, 1.2);
    await _settle(tester);
    expect(_minions(game), hasLength(4));
    _beatWave(game);
    _run(game, 4);
    for (var n = 19; n <= 20; n++) {
      await _round(tester, game);
    }
    game.handleAnswer(_right(game)); // the 21st
    _run(game, 1.2);
    await _settle(tester);
    _beatWave(game);
    _run(game, 1.0);
    // The 22nd is the last one left.
    expect(boss.banner, 'FINAL QUESTION');
    _run(game, 2);
    expect(game.questionShowing, isTrue);
    game.handleAnswer(_right(game));
    expect(boss.isDefeated, isTrue);
    await _flush(tester);
  });

  testWidgets('a shield turns a wrong answer away, and the fight goes on', (tester) async {
    final (game, boss) = await _start(tester);
    _run(game, 20);
    game.shieldActive = true;

    game.handleAnswer(_wrong(game));
    expect(game.shieldActive, isFalse);
    expect(boss.health, 22);
    _run(game, 3);
    expect(game.questionShowing, isTrue);
    await _flush(tester);
  });
}

LoadedLevel _arena(String file) =>
    LevelLoader.parse(File('assets/tiles/levels/$file.tmx').readAsStringSync());

void arenaTests() {
  group('in a boss arena', () {
    testWidgets('the boss is already standing where the map put it, and stays', (tester) async {
      final level = _arena('era2_5');
      final (game, boss) = await _start(tester, arena: level);
      final spot = level.boss!;
      expect(boss.position.x, spot.x - 60);
      expect(boss.position.y, spot.y - 140);
      expect(boss.reachedCenter, isTrue);

      game.player.position.x = 1500; // the student walks across the room
      _run(game, 3);
      expect(boss.position.x, spot.x - 60, reason: 'an arena boss does not follow the camera');
      await _flush(tester);
    });

    testWidgets('the first question comes after a moment to look around', (tester) async {
      final (game, _) = await _start(tester, arena: _arena('era2_5'));
      _run(game, 1);
      expect(game.questionShowing, isFalse);
      _run(game, 2);
      expect(game.questionShowing, isTrue);
      await _flush(tester);
    });

    testWidgets('a wave stands on the map spots, far from the student', (tester) async {
      final level = _arena('era2_5');
      final (game, _) = await _start(tester, arena: level);
      game.player.position.x = level.spawnX; // at the left end
      _run(game, 3);
      await _firstWave(tester, game);

      final minions = _minions(game);
      expect(minions, hasLength(BossPlan.minionsPerWave[0]));
      final spots = level.minionSpawns.map((s) => s.x - 45).toSet();
      for (final m in minions) {
        // (a minion has already taken a step or two by now)
        expect(spots.any((x) => (x - m.position.x).abs() < 40), isTrue,
            reason: 'a minion stands on a spot the map gave');
        expect(m.position.x - game.player.position.x, greaterThan(400), reason: 'not on top of the student');
      }
      expect(minions.map((m) => (m.position.x / 100).round()).toSet(), hasLength(minions.length), reason: 'no two share a spot');
      await _flush(tester);
    });

    testWidgets('on a raised floor the minions stand on it', (tester) async {
      final level = _arena('era6_5'); // the palace steps: the dais is 72 up
      final (game, _) = await _start(tester, arena: level);
      _run(game, 3);
      await _firstWave(tester, game);
      expect(_minions(game), isNotEmpty);
      for (final m in _minions(game)) {
        expect(m.position.y + m.size.y, 660 - 72);
      }
      await _flush(tester);
    });

    testWidgets('the camera follows the student inside the room and stops at the walls', (tester) async {
      final level = _arena('era2_5');
      final (game, _) = await _start(tester, arena: level);
      final room = level.mapWidth - game.size.x;
      expect(room, greaterThan(0), reason: 'the arena is wider than the screen');

      game.player.position.x = 0;
      expect(game.cameraLeftEdgeX, 0);
      game.player.position.x = level.mapWidth;
      expect(game.cameraLeftEdgeX, room);
      game.player.position.x = level.mapWidth / 2;
      expect(game.cameraLeftEdgeX, closeTo(level.mapWidth / 2 - 220, 0.01));
      await _flush(tester);
    });
  });
}
