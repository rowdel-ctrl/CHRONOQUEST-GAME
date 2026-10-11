// The boss fight, end to end in a mounted game: a question, then a wave of
// minions, then the next question; six right answers beat the boss; a wrong
// answer or a timeout costs the boss nothing; minions pay out Kaalaman.
import 'dart:ui' as ui;

import 'package:chronoquest/data/question_pool.dart';
import 'package:chronoquest/game/boss_countdown.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/boss_component.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
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
    questionPool = QuestionPool(questions: [for (var i = 0; i < 12; i++) _q(i)]);
    bossPhase = true;
  }
}

Future<(_BossGame, BossComponent)> _start(WidgetTester tester) async {
  final game = _BossGame();
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
  final boss = BossComponent(eraId: 'spanish');
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

void main() {
  testWidgets('the boss walks in and asks the first question', (tester) async {
    final (game, boss) = await _start(tester);
    _run(game, 20);
    expect(boss.reachedCenter, isTrue);
    expect(game.questionShowing, isTrue);
    expect(game.currentQuestion, isNotNull);
    expect(boss.health, 6);
    await _flush(tester);
  });

  testWidgets('a right answer hurts the boss, then minions come, then a new question', (tester) async {
    final (game, boss) = await _start(tester);
    _run(game, 20);
    final first = game.currentQuestion!;

    game.handleAnswer(_right(game));
    expect(boss.health, 5);
    expect(game.questionShowing, isFalse);

    _run(game, 1.2);
    await _settle(tester);
    expect(_minions(game), hasLength(minionsInWave(0)));
    expect(game.questionShowing, isFalse, reason: 'the minions come before the next question');

    // Beat them: each pays one Kaalaman charge.
    final before = game.kaalaman;
    for (final m in _minions(game)) {
      m.takeHit();
      m.takeHit(); // a Heavy needs two
    }
    expect(game.kaalaman, before + minionsInWave(0));

    _run(game, 2);
    expect(game.questionShowing, isTrue);
    expect(game.currentQuestion!.id, isNot(first.id));
    await _flush(tester);
  });

  testWidgets('a wrong answer costs the boss nothing but the minions still come', (tester) async {
    final (game, boss) = await _start(tester);
    _run(game, 20);

    game.handleAnswer(_wrong(game));
    expect(boss.health, 6);
    _run(game, 1.2);
    await _settle(tester);
    expect(_minions(game), isNotEmpty);
    await _flush(tester);
  });

  testWidgets('a timeout is a wrong answer', (tester) async {
    final (game, boss) = await _start(tester);
    _run(game, 20);

    game.handleAnswer(''); // what the overlay sends when the clock runs out
    expect(boss.health, 6);
    expect(game.answers.last.isCorrect, isFalse);
    await _flush(tester);
  });

  testWidgets('a wave nobody clears does not trap the student', (tester) async {
    final (game, boss) = await _start(tester);
    _run(game, 20);
    game.handleAnswer(_right(game));
    _run(game, 1.2);
    await _settle(tester);
    expect(_minions(game), isNotEmpty);

    _run(game, 45); // longer than the wave timeout, minions left alone
    expect(game.questionShowing, isTrue);
    expect(boss.isDefeated, isFalse);
    await _flush(tester);
  });

  testWidgets('six right answers defeat the boss', (tester) async {
    final (game, boss) = await _start(tester);
    _run(game, 20);

    for (var n = 1; n <= 6; n++) {
      expect(game.questionShowing, isTrue, reason: 'question $n');
      game.handleAnswer(_right(game));
      if (n < 6) {
        _run(game, 1.2);
    await _settle(tester);
        for (final m in _minions(game)) {
          m.takeHit();
          m.takeHit();
        }
        _run(game, 2);
      }
    }
    expect(boss.health, 0);
    expect(boss.isDefeated, isTrue);
    await _flush(tester);
  });

  testWidgets('a shield turns a wrong answer away, and the fight goes on', (tester) async {
    final (game, boss) = await _start(tester);
    _run(game, 20);
    game.shieldActive = true;

    game.handleAnswer(_wrong(game));
    expect(game.shieldActive, isFalse);
    expect(boss.health, 6);
    _run(game, 1.2);
    await _settle(tester);
    expect(_minions(game), isNotEmpty);
    await _flush(tester);
  });
}
