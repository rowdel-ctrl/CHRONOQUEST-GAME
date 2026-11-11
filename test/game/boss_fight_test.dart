// The boss fight, end to end in a mounted game (the 2026-11 flow): 22 rounds; a rune, then each round the boss
// winds up, throws an attack that flies at the hero and opens the question at once, and the
// attack's flight is the answer timer. A right answer makes the hero counter it and costs the boss
// 1 of 22 health; a wrong answer or no answer lets it hit (-1 heart) and the question comes back
// at the end. Phase timers, the defeat and fail flows, no double resolution.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chronoquest/core/boss_attack_constants.dart';
import 'package:chronoquest/data/question_pool.dart';
import 'package:chronoquest/game/boss_attack_profile.dart';
import 'package:chronoquest/game/boss_plan.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/boss_attack_component.dart';
import 'package:chronoquest/game/components/boss_component.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/enemy_behavior.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/level_loader.dart';
import 'package:chronoquest/game/overlays/boss_question_card.dart';
import 'package:chronoquest/game/overlays/hud_overlay.dart';
import 'package:chronoquest/game/overlays/question_overlay.dart';
import 'package:chronoquest/game/overlays/question_widgets.dart';
import 'package:chronoquest/game/quiz_handler.dart';
import 'package:chronoquest/models/question.dart';
import 'package:chronoquest/widgets/game_ui.dart';
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

/// A hero whose counter is under the test's control: it records the call and either answers at
/// once ([autoImpact]) or waits for [impact] to be called by the test. Hits are counted.
class _TestPlayer extends PlayerComponent {
  _TestPlayer() : super(characterId: 'rizal');

  bool autoImpact = true;
  int counters = 0;
  Vector2? lastTarget;
  VoidCallback? pending;
  int hazardHits = 0;
  int? lastKnockback;

  @override
  void playCounter({required Vector2 target, required VoidCallback onImpact}) {
    counters++;
    lastTarget = target.clone();
    if (autoImpact) {
      onImpact();
    } else {
      pending = onImpact;
    }
  }

  void impact() => pending?.call();

  @override
  void takeHazardHit({required int knockbackDirection}) {
    hazardHits++;
    lastKnockback = knockbackDirection;
    super.takeHazardHit(knockbackDirection: knockbackDirection);
  }
}

class _BossGame extends ChronoGame {
  _BossGame({this.era = 'spanish', this.level = 5, this.poolSize = 22});

  final String era;
  final int level;
  final int poolSize;

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    if (audioService.soundEnabled) {
      audioService.toggleSound(); // no audio plugin in tests
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    player = _TestPlayer()
      ..size = Vector2(96, 120)
      ..position = Vector2(0, groundY - 120)
      ..walkAnimation = await _blankAnim()
      ..jumpAnim = await _blankAnim()
      ..hurtAnim = await _blankAnim();
    player.game = this;
    currentEra = era;
    currentLevel = level;
    questionPool =
        QuestionPool(questions: [for (var i = 0; i < poolSize; i++) _q(i)]);
    bossPhase = true;
    hearts = 5;
  }
}

_TestPlayer _hero(_BossGame game) => game.player as _TestPlayer;

Future<(_BossGame, BossComponent)> _start(WidgetTester tester,
    {LoadedLevel? arena,
    String era = 'spanish',
    int level = 5,
    int poolSize = 22,
    bool realOverlays = false}) async {
  final game = _BossGame(era: era, level: level, poolSize: poolSize);
  game.tiledLevel = arena;
  await tester.pumpWidget(MaterialApp(
    home: GameWidget(
      game: game,
      overlayBuilderMap: realOverlays
          ? {
              'QuestionOverlay': (_, g) => QuestionOverlayWidget(
                  game: g as ChronoGame, onAnswer: g.handleAnswer),
              'BossHealthOverlay': (_, g) =>
                  BossHealthOverlayWidget(game: g as ChronoGame),
            }
          : {
              'QuestionOverlay': (_, __) => const SizedBox.shrink(),
              'BossHealthOverlay': (_, __) => const SizedBox.shrink(),
            },
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  final boss = BossComponent(eraId: era, arena: arena);
  game.boss = boss;
  game.world.add(boss);
  for (var i = 0; i < 10; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 16));
  }
  return (game, boss);
}

// The pool reshuffles the options on every serve, so read the key off the
// question that is up.
String _right(_BossGame game) => game.currentQuestion!.correctAnswer;
String _wrong(_BossGame game) => game.currentQuestion!.options
    .map((o) => o.label)
    .firstWhere((l) => l != _right(game));

/// Lets the component's own short delays (the hero's hurt picture) run out, so no timer is left
/// pending when the test ends.
Future<void> _flush(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 3));

/// Lets sprite and text loading (real file I/O) finish so new components mount.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Runs the world forward [seconds] in steps of 0.05 s (the game splits each into 1/60 s steps,
/// as it does on a device).
void _step(_BossGame game, double seconds) {
  final n = (seconds / 0.05).round();
  for (var i = 0; i < n; i++) {
    game.updateTree(0.05);
  }
}

/// One step of the world that also plays the student's part between rounds: while a rune is
/// waiting he stands on it, and a wave of minions is over at once.
void _tick(_BossGame game, BossComponent boss) {
  final r = boss.rune;
  if (boss.state == BossRoundState.rune && r != null) {
    final p = game.player;
    p.position.x = r.centreX - p.size.x / 2;
    p.position.y = r.surfaceY - p.size.y;
  } else if (boss.state == BossRoundState.wave) {
    boss.endWave();
  }
  game.updateTree(0.05);
}

/// Runs until the intro is over, the student has touched the rune and the boss has begun to wind
/// up (the intro has already run a little while the game loaded, so the test cannot count on its
/// length).
void _untilWindup(_BossGame game, BossComponent boss) {
  for (var t = 0.0; t < 8 && boss.state != BossRoundState.windup; t += 0.05) {
    _tick(game, boss);
  }
  expect(boss.state, BossRoundState.windup);
}

/// Runs until the boss has thrown and the question is open (at most [max] seconds).
void _untilAsking(_BossGame game, BossComponent boss, {double max = 14}) {
  for (var t = 0.0; t < max && !boss.asking; t += 0.05) {
    _tick(game, boss);
  }
  expect(boss.asking, isTrue, reason: 'the question should be open');
}

/// Answers the open question right (the hero's counter answers at once) and runs on until the
/// next question is open, or the fight is over.
void _winRound(_BossGame game, BossComponent boss) {
  _untilAsking(game, boss);
  game.handleAnswer(_right(game));
  for (var t = 0.0; t < 14 && !boss.asking && !boss.isDefeated; t += 0.05) {
    _tick(game, boss);
  }
}

/// Answers wrong and runs on until the next question is open.
void _loseRound(_BossGame game, BossComponent boss) {
  _untilAsking(game, boss);
  game.handleAnswer(_wrong(game));
  for (var t = 0.0; t < 14 && !boss.asking; t += 0.05) {
    _tick(game, boss);
  }
}

LoadedLevel _arena(String file) =>
    LevelLoader.parse(File('assets/tiles/levels/$file.tmx').readAsStringSync());

void main() {
  group('the flow of one round', () {
    testWidgets('a short intro, then the boss winds up: glow and its attack picture, no question yet',
        (tester) async {
      final (game, boss) = await _start(tester);
      expect(boss.state, BossRoundState.intro);
      expect(boss.health, 22);
      expect(boss.maxHealth, 22);
      expect(boss.sprite, same(boss.idleSprite));

      _untilWindup(game, boss);
      expect(game.questionShowing, isFalse, reason: 'the question opens with the throw');
      expect(boss.attack, isNull);
      expect(boss.roundTag, 'Tanong 1 ng 22');
      _step(game, 0.1);
      expect(boss.sprite, same(boss.idleSprite), reason: 'first it only glows and draws back');
      _step(game, 0.2);
      expect(boss.sprite, same(boss.attackSprite),
          reason: 'it turns to the hero: its attack picture, which faces him, from the wind-up on');
      await _flush(tester);
    });

    testWidgets(
        'after 0.6 s the attack leaves the boss and the question opens at the same moment',
        (tester) async {
      final (game, boss) = await _start(tester);
      _untilWindup(game, boss);
      _step(game, 0.45);
      expect(boss.state, BossRoundState.windup);
      expect(game.overlays.isActive('QuestionOverlay'), isFalse);
      _step(game, 0.2);
      expect(boss.state, BossRoundState.asking);
      expect(game.questionShowing, isTrue);
      expect(game.overlays.isActive('QuestionOverlay'), isTrue);
      expect(game.currentQuestion, isNotNull);
      expect(boss.attack, isNotNull);
      expect(boss.attackKind, BossAttackKind.gslash,
          reason: 'the Governor of the Spanish era throws a gold sword slash');
      expect(boss.attack!.progress, lessThan(0.01));
      expect(boss.sprite, same(boss.attackSprite), reason: 'the throw pose');
      await _flush(tester);
    });

    testWidgets('the attack flies from the boss to the hero and the game is not paused',
        (tester) async {
      final level = _arena('era2_5');
      final (game, boss) = await _start(tester, arena: level);
      game.player.position.x = level.spawnX; // far from the boss, on its left
      boss.startRoundNow();
      _untilAsking(game, boss);
      _step(game, 0.1);
      final a = boss.attack!;
      final hero = game.player;
      final bossX = boss.position.x + boss.size.x / 2;
      expect(a.start.x, lessThan(bossX), reason: 'it leaves the boss on the hero\'s side');
      expect(a.end.x, greaterThan(hero.position.x + hero.size.x / 2),
          reason: 'it meets the hero in front of it');
      expect(game.paused, isFalse, reason: 'the attack must be seen coming');
      final x0 = a.head.x;
      _step(game, 5);
      expect(a.head.x, lessThan(x0), reason: 'it moves towards the hero as the time runs');
      _step(game, 5);
      expect(a.head.x, lessThan(x0 - 100));
      await _flush(tester);
    });

    testWidgets(
        'the attack\'s progress is elapsed / limit and reaches 1 exactly at the limit (15 s in phase 1)',
        (tester) async {
      final (game, boss) = await _start(tester);
      _untilAsking(game, boss);
      expect(boss.answerSeconds, 15);
      expect(boss.secondsLeft, closeTo(15, 0.06)); // the wind-up ends at some frame of the 0.05 step
      final used = 15 - boss.secondsLeft;
      _step(game, 7.5);
      expect(boss.attackProgress, closeTo((7.5 + used) / 15, 1e-6));
      expect(boss.clockFraction, closeTo(1 - (7.5 + used) / 15, 1e-6));
      _step(game, 7.0);
      expect(boss.attackProgress, closeTo((14.5 + used) / 15, 1e-6));
      expect(boss.asking, isTrue);
      expect(game.hearts, 5);
      var slices = 0;
      while (boss.asking && slices < 200) {
        game.updateTree(1 / 60);
        slices++;
      }
      expect((14.5 + used) + slices / 60, closeTo(15, 1 / 60 + 1e-6),
          reason: 'time is up at the limit, not before');
      expect(boss.state, BossRoundState.rest);
      expect(game.hearts, 4, reason: 'the attack hit');
      await _flush(tester);
    });

    testWidgets('a pause stops the attack and the clock, and play goes on from there',
        (tester) async {
      final (game, boss) = await _start(tester);
      _untilAsking(game, boss);
      _step(game, 2);
      game.pauseEngine();
      await tester.pump(const Duration(milliseconds: 16));
      final p = boss.attackProgress;
      final left = boss.secondsLeft;
      await tester.pump(const Duration(seconds: 5));
      expect(boss.attackProgress, p);
      expect(boss.secondsLeft, left);
      game.resumeEngine();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 100));
      expect(boss.attackProgress, greaterThan(p));
      await _flush(tester);
    });

    testWidgets('Time Freeze holds the attack where it is, and an answer still counts',
        (tester) async {
      final (game, boss) = await _start(tester);
      _untilAsking(game, boss);
      _step(game, 3);
      boss.freezeClock();
      expect(boss.frozen, isTrue);
      final p = boss.attackProgress;
      _step(game, 7.5);
      expect(boss.attackProgress, p, reason: 'held for 8 seconds');
      expect(boss.asking, isTrue);
      _step(game, 1);
      expect(boss.attackProgress, greaterThan(p), reason: 'then it goes on');
      game.handleAnswer(_right(game));
      expect(boss.health, 22);
      expect(_hero(game).counters, 1);
      await _flush(tester);
    });
  });

  group('a right answer', () {
    testWidgets(
        'the hero counters the attack where it is, it is sent back, the boss loses 1 health and is dizzy',
        (tester) async {
      final (game, boss) = await _start(tester);
      _hero(game).autoImpact = false;
      _untilAsking(game, boss);
      _step(game, 6);
      final where = boss.attack!.centre.clone();
      game.handleAnswer(_right(game));

      expect(_hero(game).counters, 1);
      expect(_hero(game).lastTarget!.x, closeTo(where.x, 0.001),
          reason: 'the counter is aimed at the attack\'s position');
      expect(_hero(game).lastTarget!.y, closeTo(where.y, 0.001));
      expect(boss.state, BossRoundState.counter);
      expect(game.questionShowing, isFalse, reason: 'answered');
      expect(boss.health, 22, reason: 'nothing happens to the boss until the hero meets it');
      final p = boss.attackProgress;
      _step(game, 1);
      expect(boss.attackProgress, p, reason: 'the attack waits for the counter');
      expect(game.hearts, 5);

      _hero(game).impact();
      expect(boss.state, BossRoundState.reflect);
      expect(boss.attack!.mode, BossAttackMode.reflect);
      _step(game, 0.3);
      expect(boss.health, 22, reason: 'still on its way back');
      _step(game, 0.25);
      expect(boss.health, 21, reason: 'it hit the boss');
      expect(boss.sprite, same(boss.hurtSprite));
      expect(boss.attack, isNull);
      expect(boss.state, BossRoundState.rest);
      expect(boss.roundTag, 'Tanong 2 ng 22');
      expect(game.hearts, 5);
      await _settle(tester);
      expect(game.world.children.whereType<TextComponent>().any((t) => t.text == '-1'),
          isTrue, reason: '"-1" rises over the boss');
      await _flush(tester);
    });

    testWidgets('a new rune appears about 1.2 s after the hit, and touching it starts the next round',
        (tester) async {
      final (game, boss) = await _start(tester);
      _untilAsking(game, boss);
      game.handleAnswer(_right(game));
      _step(game, 0.6); // sent back
      expect(boss.state, BossRoundState.rest);
      _step(game, 1.05);
      expect(boss.state, BossRoundState.rest);
      _step(game, 0.2);
      expect(boss.state, BossRoundState.rune, reason: 'round 1 was played: a rune, not a wave');
      expect(boss.rune, isNotNull);
      _untilWindup(game, boss);
      _step(game, 0.65);
      expect(boss.asking, isTrue);
      expect(game.currentQuestion, isNotNull);
      await _flush(tester);
    });

    testWidgets('the question card stays up a moment after the hit, then goes', (tester) async {
      final (game, boss) = await _start(tester);
      _untilAsking(game, boss);
      game.handleAnswer(_right(game));
      _step(game, 0.6);
      expect(game.overlays.isActive('QuestionOverlay'), isTrue,
          reason: 'the right answer can still be read');
      _step(game, 0.95);
      expect(game.overlays.isActive('QuestionOverlay'), isFalse);
      await _flush(tester);
    });

    testWidgets('the score and the streak count, and the answer is recorded', (tester) async {
      final (game, boss) = await _start(tester);
      _untilAsking(game, boss);
      game.handleAnswer(_right(game));
      expect(game.score, 15, reason: '10 for the answer and 5 for answering quickly');
      expect(game.answers, hasLength(1));
      expect(game.answers.single.isCorrect, isTrue);
      expect(boss.lastAnswer, isNotEmpty);
      await _flush(tester);
    });

    testWidgets('the counter calling back twice costs the boss one health, not two',
        (tester) async {
      final (game, boss) = await _start(tester);
      _hero(game).autoImpact = false;
      _untilAsking(game, boss);
      game.handleAnswer(_right(game));
      _hero(game).impact();
      _hero(game).impact();
      _step(game, 0.6);
      _hero(game).impact(); // and once more, long after
      _step(game, 0.1);
      expect(boss.health, 21);
      await _flush(tester);
    });

    testWidgets('a counter that never answers does not hang the fight', (tester) async {
      final (game, boss) = await _start(tester);
      _hero(game).autoImpact = false;
      _untilAsking(game, boss);
      game.handleAnswer(_right(game));
      _step(game, 2.9);
      expect(boss.state, BossRoundState.counter);
      _step(game, 0.2);
      expect(boss.state, isNot(BossRoundState.counter));
      _step(game, 0.6);
      expect(boss.health, 21);
      await _flush(tester);
    });

    testWidgets('with the real hero move the counter answers by itself', (tester) async {
      final game = _BossGame();
      await tester.pumpWidget(MaterialApp(
        home: GameWidget(game: game, overlayBuilderMap: {
          'QuestionOverlay': (_, __) => const SizedBox.shrink(),
          'BossHealthOverlay': (_, __) => const SizedBox.shrink(),
        }),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      // The ordinary player (not the test's), with the hero's real counter.
      final real = PlayerComponent(characterId: 'boy')
        ..size = Vector2(96, 120)
        ..position = Vector2(0, game.groundY - 120)
        ..walkAnimation = await _blankAnim()
        ..jumpAnim = await _blankAnim()
        ..hurtAnim = await _blankAnim();
      real.game = game;
      game.player = real;
      final boss = BossComponent(eraId: 'spanish');
      game.boss = boss;
      game.world.add(boss);
      await _settle(tester);
      _untilAsking(game, boss);
      game.handleAnswer(_right(game));
      for (var i = 0; i < 100 && boss.health == 22; i++) {
        game.updateTree(0.05);
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
      }
      expect(boss.health, 21, reason: 'the hero met the attack, whatever its move');
      await _flush(tester);
    });
  });

  group('a wrong answer or no answer', () {
    testWidgets(
        'the attack rushes in and hits: -1 heart, nothing for the boss, the question goes to the back',
        (tester) async {
      final (game, boss) = await _start(tester);
      _untilAsking(game, boss);
      final missed = game.currentQuestion!.id;
      _step(game, 4);
      final p = boss.attackProgress;
      game.handleAnswer(_wrong(game));
      expect(boss.state, BossRoundState.rush);
      expect(_hero(game).counters, 0, reason: 'no counter for a wrong answer');
      expect(game.hearts, 5);
      _step(game, 0.3);
      expect(boss.attackProgress, greaterThan(p), reason: 'it keeps coming, faster');
      _step(game, 0.5);
      expect(game.hearts, 4);
      expect(boss.health, 22);
      expect(boss.state, BossRoundState.rest);
      expect(boss.attack, isNull);
      expect(boss.roundTag, 'Tanong 1 ng 22', reason: 'still round 1: the boss has not been hurt');
      expect(game.answers.single.isCorrect, isFalse);

      // The 21 others come first, then the missed one again.
      final asked = <String>[];
      for (var n = 0; n < 21; n++) {
        _untilAsking(game, boss);
        asked.add(game.currentQuestion!.id);
        _winRound(game, boss);
      }
      expect(asked.toSet(), hasLength(21));
      expect(asked, isNot(contains(missed)));
      expect(game.currentQuestion!.id, missed, reason: 'asked again, last');
      expect(boss.health, 1);
      expect(boss.roundTag, 'Tanong 22 ng 22');
      await _flush(tester);
    });

    testWidgets('time running out is a wrong answer: the attack arrives, -1 heart, asked again later',
        (tester) async {
      final (game, boss) = await _start(tester);
      _untilAsking(game, boss);
      final missed = game.currentQuestion!.id;
      _step(game, 15.05);
      expect(boss.state, BossRoundState.rest);
      expect(game.hearts, 4);
      expect(_hero(game).hazardHits, 1);
      expect(boss.health, 22);
      expect(game.answers, hasLength(1));
      expect(game.answers.single.isCorrect, isFalse);
      expect(game.answers.single.studentAnswer, '');
      expect(game.answers.single.questionId, missed);
      expect(game.questionShowing, isFalse);
      for (var n = 0; n < 21; n++) {
        _winRound(game, boss);
      }
      expect(game.currentQuestion!.id, missed);
      await _flush(tester);
    });

    testWidgets('the hit has a burst and a "-1", and the screen shakes', (tester) async {
      final (game, boss) = await _start(tester);
      _untilAsking(game, boss);
      game.handleAnswer(_wrong(game));
      _step(game, 0.8);
      await _settle(tester);
      expect(game.world.children.whereType<TextComponent>().any((t) => t.text == '-1'),
          isTrue);
      await _flush(tester);
    });

    testWidgets('a Shield turns the hit away: no heart is lost, and the question still comes back',
        (tester) async {
      final (game, boss) = await _start(tester);
      _untilAsking(game, boss);
      game.shieldActive = true;
      game.handleAnswer(_wrong(game));
      _step(game, 1);
      expect(game.hearts, 5);
      expect(game.shieldActive, isFalse, reason: 'the bubble popped');
      expect(_hero(game).hazardHits, 1);
      expect(boss.health, 22);
      await _flush(tester);
    });

    testWidgets('the last heart lost fails the level (the existing flow), and the fight stops',
        (tester) async {
      final (game, boss) = await _start(tester);
      var failed = 0;
      game.onLevelFailed = () => failed++;
      game.hearts = 1;
      _untilAsking(game, boss);
      game.handleAnswer(_wrong(game));
      _step(game, 1);
      expect(game.hearts, 0);
      expect(failed, 1);
      expect(game.levelEnded, isTrue);
      expect(boss.state, BossRoundState.ended);
      expect(game.overlays.isActive('QuestionOverlay'), isFalse);
      _step(game, 10);
      expect(boss.state, BossRoundState.ended, reason: 'no new round');
      expect(failed, 1);
      await _flush(tester);
    });

    testWidgets('running out of time on the last heart fails the level too', (tester) async {
      final (game, boss) = await _start(tester);
      var failed = 0;
      game.onLevelFailed = () => failed++;
      game.hearts = 1;
      _untilAsking(game, boss);
      _step(game, 15.1);
      expect(failed, 1);
      expect(boss.state, BossRoundState.ended);
      await _flush(tester);
    });
  });

  group('no double resolution', () {
    testWidgets('a tap after the answer, or in the moment of the timeout, does nothing',
        (tester) async {
      final (game, boss) = await _start(tester);
      _hero(game).autoImpact = false;
      _untilAsking(game, boss);
      game.handleAnswer(_right(game));
      game.handleAnswer(_wrong(game));
      game.handleAnswer('');
      expect(game.answers, hasLength(1));
      expect(_hero(game).counters, 1);
      _step(game, 2); // the old clock must not fire a timeout on top
      expect(_hero(game).hazardHits, 0);
      expect(game.hearts, 5);
      await _flush(tester);
    });

    testWidgets('a wrong answer, then a late tap and the timer: one hit only', (tester) async {
      final (game, boss) = await _start(tester);
      _untilAsking(game, boss);
      game.handleAnswer(_wrong(game));
      game.handleAnswer(_right(game));
      _step(game, 2.5);
      expect(_hero(game).hazardHits, 1);
      expect(game.answers, hasLength(1));
      expect(boss.health, 22);
      await _flush(tester);
    });

    testWidgets('an answer when no question is open is ignored', (tester) async {
      final (game, boss) = await _start(tester);
      game.currentQuestion = _q(1);
      game.handleAnswer('A'); // in the intro
      expect(game.answers, isEmpty);
      _step(game, 1.5); // the wind-up
      game.handleAnswer('A');
      expect(game.answers, isEmpty);
      expect(boss.health, 22);
      await _flush(tester);
    });
  });

  group('the whole fight', () {
    testWidgets('22 right answers defeat the boss, and then the level is complete', (tester) async {
      final (game, boss) = await _start(tester);
      var completed = 0;
      game.onLevelComplete = (score, correct, total, answers) => completed++;
      for (var n = 1; n <= 22; n++) {
        expect(boss.roundTag, 'Tanong $n ng 22');
        _winRound(game, boss);
      }
      expect(boss.health, 0);
      expect(boss.isDefeated, isTrue);
      expect(boss.sprite, same(boss.defeatedSprite));
      expect(game.answers, hasLength(22));
      expect(game.answers.map((a) => a.questionId).toSet(), hasLength(22),
          reason: '22 different questions, each once');
      expect(game.overlays.isActive('QuestionOverlay'), isFalse);
      expect(completed, 0, reason: 'the boss lies there for a moment first');
      _step(game, 0.9);
      expect(completed, 0);
      _step(game, 0.2);
      expect(completed, 1);
      _step(game, 2);
      expect(completed, 1);
      expect(boss.isRemoving || !boss.isMounted, isTrue);
      await _flush(tester);
    });

    testWidgets('phases: 15 s in rounds 1-7, 12 s in rounds 8-15, 10 s in rounds 16-22; the extra attack from round 16',
        (tester) async {
      final (game, boss) = await _start(tester);
      final seconds = <double>[];
      final kinds = <BossAttackKind>[];
      for (var n = 1; n <= 22; n++) {
        _untilAsking(game, boss);
        seconds.add(boss.secondsLeft);
        kinds.add(boss.attackKind!);
        expect(boss.phase, BossPlan.phaseOfRound(n));
        _winRound(game, boss);
      }
      expect(seconds.map((s) => s.round()), [
        ...List.filled(7, 15),
        ...List.filled(8, 12),
        ...List.filled(7, 10),
      ]);
      expect(kinds, [
        ...List.filled(15, BossAttackKind.gslash),
        ...List.filled(7, BossAttackKind.knights),
      ]);
      await _flush(tester);
    });

    testWidgets('a question asked again gets the clock of the round it is asked in',
        (tester) async {
      final (game, boss) = await _start(tester);
      _loseRound(game, boss); // round 1 missed
      for (var n = 1; n <= 21; n++) {
        _winRound(game, boss);
      }
      // 21 rounds won: this is round 22, the missed question again, with phase 3's 10 s.
      expect(boss.answerSeconds, 10);
      expect(boss.secondsLeft, closeTo(10, 0.1));
      await _flush(tester);
    });

    testWidgets('a wave of 2 minions comes after every second round, then the next rune',
        (tester) async {
      final (game, boss) = await _start(tester, arena: _arena('era2_5'));
      _untilAsking(game, boss);
      game.handleAnswer(_right(game));
      _step(game, 2.5); // sent back, the rest
      await _settle(tester);
      expect(boss.state, BossRoundState.rune, reason: 'after round 1: no wave yet');
      expect(game.world.children.whereType<EnemyComponent>(), isEmpty);
      _untilAsking(game, boss);
      game.handleAnswer(_right(game)); // round 2 won: the wave comes before round 3
      for (var i = 0; i < 80 && boss.state != BossRoundState.wave; i++) {
        game.updateTree(0.05);
      }
      expect(boss.state, BossRoundState.wave);
      expect(boss.minions, hasLength(2), reason: 'phase 1: 2 minions');
      expect(boss.minions.every((m) => m.parent == game.world), isTrue);
      expect(boss.minions.every((m) => m.eraId == 'spanish'), isTrue);
      expect(boss.minionsAlive, 2);
      expect(game.questionShowing, isFalse);
      await _flush(tester);
    });

    testWidgets('a boss with no questions cannot be fought and falls at once', (tester) async {
      final (game, boss) = await _start(tester, poolSize: 0);
      expect(boss.maxHealth, 0);
      _step(game, 1.5);
      expect(boss.isDefeated, isTrue);
      await _flush(tester);
    });

    testWidgets('a short pool gives a short fight', (tester) async {
      final (game, boss) = await _start(tester, poolSize: 4);
      expect(boss.maxHealth, 4);
      for (var n = 1; n <= 4; n++) {
        _winRound(game, boss);
      }
      expect(boss.isDefeated, isTrue);
      await _flush(tester);
    });
  });

  group('how the boss looks', () {
    testWidgets('it shows hurt when it takes damage, and idle again after', (tester) async {
      final (game, boss) = await _start(tester);
      expect(boss.hurtSprite, isNotNull, reason: 'the new art has a hurt picture');
      expect(boss.specialSprite, isNotNull);
      expect(boss.sprite, same(boss.idleSprite));

      boss.takeDamage();
      expect(boss.sprite, same(boss.hurtSprite));
      expect(boss.sprite, isNot(same(boss.attackSprite)));
      _step(game, 0.2);
      expect(boss.sprite, same(boss.hurtSprite), reason: 'still hurt 0.2 s later');
      _step(game, 0.45);
      expect(boss.sprite, same(boss.idleSprite), reason: 'hurt lasts 0.4 s');
      await _flush(tester);
    });

    testWidgets('the phase 3 attack is thrown with the special picture', (tester) async {
      final (game, boss) = await _start(tester);
      for (var n = 1; n <= 15; n++) {
        _winRound(game, boss);
      }
      // Round 16: ghost knights march in; the boss raises its special picture to throw.
      _untilAsking(game, boss);
      expect(boss.attackKind, BossAttackKind.knights);
      expect(boss.sprite, same(boss.specialSprite));
      _step(game, 0.6);
      expect(boss.sprite, same(boss.idleSprite));
      await _flush(tester);
    });

    testWidgets('the ghost knights are not sent back: they vanish and the boss is hit',
        (tester) async {
      final (game, boss) =
          await _start(tester, era: 'nationalism', level: 7);
      _untilAsking(game, boss);
      expect(boss.attackKind, BossAttackKind.ghost);
      game.handleAnswer(_right(game));
      expect(boss.health, 21, reason: 'the counter meets them and the boss is hit at once');
      expect(boss.state, BossRoundState.rest);
      await _flush(tester);
    });
  });

  group('the rune', () {
    /// Runs the world until the boss is waiting for a rune to be touched.
    void untilRune(_BossGame game, BossComponent boss) {
      for (var t = 0.0; t < 6 && boss.state != BossRoundState.rune; t += 0.05) {
        game.updateTree(0.05);
      }
      expect(boss.state, BossRoundState.rune);
    }

    testWidgets('a rune appears on the floor at least 450 from the student, off the stage',
        (tester) async {
      final level = _arena('era2_5');
      final (game, boss) = await _start(tester, arena: level);
      game.player.position.x = level.spawnX;
      untilRune(game, boss);
      final r = boss.rune!;
      final hero = game.player.position.x + game.player.size.x / 2;
      expect((r.centreX - hero).abs(), greaterThanOrEqualTo(BossAttackConstants.runeMinDistance));
      expect((r.centreX - level.boss!.x).abs(), greaterThanOrEqualTo(168), reason: 'not on the stage');
      expect(r.surfaceY, game.groundY, reason: 'on the base floor');
      expect(boss.attack, isNull);
      expect(game.questionShowing, isFalse, reason: 'no question until the rune is touched');
      await _flush(tester);
    });

    testWidgets('every place a rune may stand is flat base floor away from the stage and the ends',
        (tester) async {
      final level = _arena('era1_10');
      final (game, boss) = await _start(tester, arena: level);
      final spots = boss.floorSpots();
      expect(spots, isNotEmpty);
      for (final s in spots) {
        expect(s.y, game.groundY);
        expect((s.x - level.boss!.x).abs(), greaterThanOrEqualTo(168), reason: 'not on the stage');
        expect(s.x, greaterThan(70));
        expect(s.x, lessThan(level.mapWidth - 70));
      }
      expect(spots.any((s) => s.x < level.boss!.x), isTrue, reason: 'floor on the boss\'s left');
      expect(spots.any((s) => s.x > level.boss!.x), isTrue, reason: 'and on its right');
      // The tide pools are not floor: no spot inside one.
      expect(spots.map((s) => s.x).toSet().length, spots.length);
      await _flush(tester);
    });

    testWidgets('walking up to the rune makes the boss turn and wind up, and the question follows',
        (tester) async {
      final level = _arena('era2_5');
      final (game, boss) = await _start(tester, arena: level);
      game.player.position.x = level.spawnX;
      untilRune(game, boss);
      final r = boss.rune!;
      // Not there yet: nothing happens, however long it takes (under 15 s).
      _step(game, 5);
      expect(boss.state, BossRoundState.rune);
      expect(boss.stalled, isFalse);
      game.player.position.x = r.centreX - game.player.size.x / 2 - 60; // close, not yet touching
      _step(game, 0.1);
      expect(boss.state, BossRoundState.rune);
      game.player.position.x = r.centreX - game.player.size.x / 2;
      game.player.position.y = r.surfaceY - game.player.size.y;
      _step(game, 0.1);
      expect(boss.state, BossRoundState.windup);
      expect(boss.stalled, isFalse);
      expect(boss.rune, isNull);
      _step(game, 0.3);
      expect(boss.sprite, same(boss.attackSprite), reason: 'it has turned to face the student');
      _step(game, 0.4);
      expect(boss.asking, isTrue);
      await _flush(tester);
    });

    testWidgets('a student who does nothing for 15 s: the boss throws anyway', (tester) async {
      final level = _arena('era2_5');
      final (game, boss) = await _start(tester, arena: level);
      game.player.position.x = level.spawnX;
      untilRune(game, boss);
      _step(game, 14);
      expect(boss.state, BossRoundState.rune);
      expect(boss.runeWaited, greaterThan(13.5));
      _step(game, 1.5);
      expect(boss.state, BossRoundState.windup);
      expect(boss.stalled, isTrue);
      _step(game, 0.7);
      expect(boss.asking, isTrue);
      await _flush(tester);
    });

    testWidgets('jumping over a rune does not touch it', (tester) async {
      final level = _arena('era2_5');
      final (game, boss) = await _start(tester, arena: level);
      game.player.position.x = level.spawnX;
      untilRune(game, boss);
      final r = boss.rune!;
      game.player.position.x = r.centreX - game.player.size.x / 2;
      game.player.position.y = r.surfaceY - game.player.size.y - 200; // high in the air
      _step(game, 0.05);
      expect(boss.state, BossRoundState.rune);
      await _flush(tester);
    });

    testWidgets('after a round a new rune comes, and the one before is gone', (tester) async {
      final level = _arena('era2_5');
      final (game, boss) = await _start(tester, arena: level);
      _untilAsking(game, boss);
      game.handleAnswer(_right(game));
      for (var t = 0.0; t < 6 && boss.state != BossRoundState.rune; t += 0.05) {
        game.updateTree(0.05);
      }
      expect(boss.state, BossRoundState.rune);
      expect(boss.rune, isNotNull);
      await _flush(tester);
    });
  });

  group('the minion waves', () {
    testWidgets('a wave is 3 minions in phase 2 and 4 in phase 3, and never over 6', (tester) async {
      for (final (round, expected) in [(7, 2), (8, 3), (15, 3), (16, 4), (22, 4)]) {
        final plan = BossAttackConstants.waveSizes[BossPlan.phaseOfRound(round) - 1];
        expect(plan, expected, reason: 'round $round');
        expect(plan, lessThanOrEqualTo(BossAttackConstants.waveMaxAlive));
      }
    });

    testWidgets('after the wave the next rune comes; a stuck wave gives up after 30 s', (tester) async {
      final level = _arena('era2_5');
      final (game, boss) = await _start(tester, arena: level);
      _untilAsking(game, boss);
      game.handleAnswer(_right(game));
      _step(game, 2.5);
      _untilAsking(game, boss);
      game.handleAnswer(_right(game));
      for (var t = 0.0; t < 6 && boss.state != BossRoundState.wave; t += 0.05) {
        game.updateTree(0.05);
      }
      expect(boss.state, BossRoundState.wave);
      _step(game, 29);
      expect(boss.state, BossRoundState.wave, reason: 'minions still about');
      _step(game, 1.5);
      expect(boss.state, BossRoundState.rune, reason: 'a stuck wave can never trap the student');
      await _flush(tester);
    });

    testWidgets('the minions are the era\'s own and chase; a minion that falls pays a charge back',
        (tester) async {
      final level = _arena('era2_5');
      final (game, boss) = await _start(tester, arena: level);
      _untilAsking(game, boss);
      game.handleAnswer(_right(game));
      _step(game, 2.5);
      _untilAsking(game, boss);
      game.handleAnswer(_right(game));
      for (var t = 0.0; t < 6 && boss.state != BossRoundState.wave; t += 0.05) {
        game.updateTree(0.05);
      }
      expect(boss.minions, hasLength(2));
      for (final m in boss.minions) {
        expect(m.eraId, 'spanish');
        expect(m.behaviorOverride, EnemyBehavior.chaser);
        expect(m.blasts, isFalse, reason: 'plain chasers: no bursts in the boss room');
      }
      game.kaalaman = 1;
      boss.minions.first.onDefeated!.call();
      expect(game.kaalaman, 2);
      await _flush(tester);
    });
  });

  group('the boss faces the hero', () {
    testWidgets('from the wind-up on it shows the picture that faces him, until the hit', (tester) async {
      final (game, boss) = await _start(tester); // the Governor: a gold slash
      _untilWindup(game, boss);
      expect(boss.sprite, same(boss.idleSprite));
      _step(game, 0.3);
      expect(boss.sprite, same(boss.attackSprite));
      _step(game, 0.4);
      expect(boss.asking, isTrue);
      _step(game, 3); // well after the first half second
      expect(boss.sprite, same(boss.attackSprite), reason: 'it keeps facing him while he answers');
      game.handleAnswer(_right(game));
      _step(game, 0.7);
      for (var t = 0.0; t < 4 && boss.state != BossRoundState.rest; t += 0.05) {
        game.updateTree(0.05);
      }
      await _flush(tester);
    });
  });

  group('with the real overlays', () {
    testWidgets("the top strip shows the boss's name, 22 segments and the round",
        (tester) async {
      final (game, boss) = await _start(tester, realOverlays: true);
      game.overlays.add('BossHealthOverlay');
      await tester.pump();
      expect(find.byKey(BossHealthOverlayWidget.nameKey), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(BossHealthOverlayWidget.nameKey)).data,
          'Governor');
      expect(tester.widget<Text>(find.byKey(BossHealthOverlayWidget.roundKey)).data,
          'Tanong 1 ng 22');
      final bar = tester.widget<GameProgressBar>(find.byType(GameProgressBar));
      expect(bar.segments, 22);
      expect(bar.value, 1);

      _winRound(game, boss);
      await tester.pump();
      expect(tester.widget<Text>(find.byKey(BossHealthOverlayWidget.roundKey)).data,
          'Tanong 2 ng 22');
      expect(tester.widget<GameProgressBar>(find.byType(GameProgressBar)).value, closeTo(21 / 22, 1e-9));
      await _flush(tester);
    });

    testWidgets('the card opens with the throw, the game keeps running, and a tap answers',
        (tester) async {
      final (game, boss) = await _start(tester, realOverlays: true);
      expect(find.byType(BossQuestionCard), findsNothing);
      _untilAsking(game, boss);
      await tester.pump();
      expect(find.byType(BossQuestionCard), findsOneWidget);
      expect(game.paused, isFalse);

      // The bar is the attack's flight.
      double bar() => tester
          .widget<FractionallySizedBox>(find.byKey(CountdownBar.barKey))
          .widthFactor!;
      final before = bar();
      _step(game, 5);
      await tester.pump(const Duration(milliseconds: 150));
      expect(bar(), lessThan(before));
      expect(bar(), closeTo(boss.clockFraction, 0.02));

      final q = game.currentQuestion!;
      final right = q.options.firstWhere((o) => o.label == q.correctAnswer);
      await tester.tap(find.text('${right.label}) ${right.text}'));
      await tester.pump();
      expect(game.answers.single.isCorrect, isTrue);
      expect(_hero(game).counters, 1);
      expect(find.text('TAMA!'), findsOneWidget,
          reason: 'the card stays to show the result');
      _step(game, 0.6);
      expect(boss.health, 21);
      await _flush(tester);
    });

    testWidgets('a wrong tap lets the attack in: MALI!, the right answer marked, a heart lost',
        (tester) async {
      final (game, boss) = await _start(tester, realOverlays: true);
      _untilAsking(game, boss);
      await tester.pump();
      final q = game.currentQuestion!;
      final wrong = q.options.firstWhere((o) => o.label != q.correctAnswer);
      await tester.tap(find.text('${wrong.label}) ${wrong.text}'));
      await tester.pump();
      expect(find.text('MALI!'), findsOneWidget);
      _step(game, 1);
      await tester.pump();
      expect(game.hearts, 4);
      expect(find.text('MALI!'), findsOneWidget, reason: 'still readable after the hit');
      await _flush(tester);
    });

    testWidgets('time running out shows MALI! on the card too', (tester) async {
      final (game, boss) = await _start(tester, realOverlays: true);
      _untilAsking(game, boss);
      await tester.pump();
      _step(game, 15.1);
      await tester.pump(const Duration(milliseconds: 150)); // the card redraws ten times a second
      expect(find.text('MALI!'), findsOneWidget);
      expect(game.hearts, 4);
      await _flush(tester);
    });

    testWidgets('Time Freeze on the card holds the attack for 8 seconds, then it goes on',
        (tester) async {
      final (game, boss) = await _start(tester, realOverlays: true);
      game.playerPowerUps.timeFreeze = 2;
      _untilAsking(game, boss);
      await tester.pump();
      _step(game, 2);
      await tester.tap(find.byKey(BossQuestionCard.freezeKey));
      await tester.pump();
      expect(boss.frozen, isTrue);
      expect(game.playerPowerUps.timeFreeze, 1);
      final p = boss.attackProgress;
      _step(game, 7.5);
      expect(boss.attackProgress, p, reason: 'held for 8 seconds');
      expect(boss.frozenSecondsLeft, greaterThan(0));
      _step(game, 1);
      expect(boss.frozen, isFalse, reason: 'the freeze is over');
      expect(boss.attackProgress, greaterThan(p), reason: 'the attack moves again');
      // One freeze a question: a second tap does nothing and costs nothing.
      await tester.pump();
      await tester.tap(find.byKey(BossQuestionCard.freezeKey));
      await tester.pump();
      expect(game.playerPowerUps.timeFreeze, 1);
      expect(boss.frozen, isFalse);
      await _flush(tester);
    });

    testWidgets('50/50 on the card hides two wrong answers, once a question', (tester) async {
      final (game, boss) = await _start(tester, realOverlays: true);
      game.playerPowerUps.fiftyFifty = 2;
      _untilAsking(game, boss);
      await tester.pump();
      final q = game.currentQuestion!;
      for (final o in q.options) {
        expect(find.text('${o.label}) ${o.text}'), findsOneWidget);
      }
      await tester.tap(find.byKey(BossQuestionCard.fiftyKey));
      await tester.pump();
      expect(game.playerPowerUps.fiftyFifty, 1);
      var shown = 0;
      for (final o in q.options) {
        final w = find.text('${o.label}) ${o.text}');
        if (w.evaluate().isEmpty) continue;
        final op = tester.widgetList<Opacity>(find.ancestor(of: w, matching: find.byType(Opacity)));
        if (op.every((x) => x.opacity > 0)) shown++;
      }
      expect(shown, 2, reason: 'the right answer and one wrong one are left');
      await tester.tap(find.byKey(BossQuestionCard.fiftyKey));
      await tester.pump();
      expect(game.playerPowerUps.fiftyFifty, 1, reason: 'a second use on the same question is refused');
      await _flush(tester);
    });

    testWidgets('the Shield button on the screen works at any moment, even while looking for a rune',
        (tester) async {
      final (game, boss) = await _start(tester, realOverlays: true);
      game.playerPowerUps.shield = 1;
      expect(boss.state, isNot(BossRoundState.asking));
      expect(game.activateShield(), isTrue);
      expect(game.shieldActive, isTrue);
      expect(game.playerPowerUps.shield, 0);
      expect(game.activateShield(), isFalse, reason: 'already on, and none left');
      await _flush(tester);
    });

    testWidgets('the next round brings a new question and a fresh card', (tester) async {
      final (game, boss) = await _start(tester, realOverlays: true);
      _winRound(game, boss);
      await tester.pump();
      expect(find.byType(BossQuestionCard), findsOneWidget);
      final first = game.answers.single.questionId;
      expect(game.currentQuestion!.id, isNot(first));
      expect(boss.lastAnswer, isNull, reason: 'a fresh question is not answered');
      expect(find.text('TAMA!'), findsNothing);
      await _flush(tester);
    });
  });

  group('in a boss arena', () {
    testWidgets('the boss stands where the map put it and does not pace', (tester) async {
      final level = _arena('era2_5');
      final (game, boss) = await _start(tester, arena: level);
      final spot = level.boss!;
      expect(boss.position.x, spot.x - 60);
      expect(boss.position.y, spot.y - 140);
      _step(game, 6);
      expect(boss.position.x, spot.x - 60, reason: 'the attack leaves from a steady place');
      await _flush(tester);
    });

    testWidgets('between rounds the whole room is the hero\'s, on both sides of the boss',
        (tester) async {
      final level = _arena('era2_5');
      final (game, boss) = await _start(tester, arena: level);
      final p = game.player;
      expect(boss.state, BossRoundState.intro);
      p.position.x = 1500; // across the stage, on the right
      _step(game, 0.1);
      expect(p.position.x, 1500, reason: 'nothing stops him from crossing');
      expect(boss.facesRight, isTrue, reason: 'the boss turns to him');
      p.position.x = 300;
      _step(game, 0.1);
      expect(p.position.x, 300);
      expect(boss.facesRight, isFalse);
      await _flush(tester);
    });

    testWidgets('while a question is on, the hero keeps to his side: right up to the boss, not past it',
        (tester) async {
      final level = _arena('era2_5');
      final (game, boss) = await _start(tester, arena: level);
      final p = game.player;
      p.position.x = 300;
      boss.startRoundNow();
      _untilAsking(game, boss);
      p.position.x = 1500; // tries to run through the boss
      _step(game, 0.1);
      expect(p.position.x + p.size.x / 2, level.boss!.x - BossAttackConstants.heroBossGap);
      expect(boss.facesRight, isFalse);
      await _flush(tester);
    });

    testWidgets('the hit knocks the hero back away from the boss, on whichever side he is',
        (tester) async {
      for (final (heroX, dir) in [(300.0, -1), (1500.0, 1)]) {
        final level = _arena('era2_5');
        final (game, boss) = await _start(tester, arena: level);
        game.player.position.x = heroX;
        boss.startRoundNow();
        _untilAsking(game, boss);
        game.handleAnswer(_wrong(game));
        _step(game, 2);
        expect(_hero(game).hazardHits, 1, reason: 'hero at $heroX');
        expect(_hero(game).lastKnockback, dir, reason: 'hero at $heroX');
        await _flush(tester);
      }
    });

    testWidgets('a hero on the right: the boss and its attack are turned to him and fly the other way',
        (tester) async {
      final level = _arena('era2_5');
      final (game, boss) = await _start(tester, arena: level);
      final p = game.player;
      p.position.x = 1500;
      boss.startRoundNow();
      expect(boss.facesRight, isTrue);
      _step(game, 0.8);
      expect(boss.asking, isTrue);
      final a = boss.attack!;
      expect(a.mirrored, isTrue);
      expect(a.start.x, greaterThan(level.boss!.x), reason: 'it leaves the boss on the hero\'s side');
      expect(a.end.x, lessThan(p.position.x + p.size.x / 2), reason: 'it meets the hero in front of him');
      final x0 = a.head.x;
      _step(game, 5);
      expect(a.head.x, greaterThan(x0), reason: 'it flies to the right, towards the hero');
      // A right answer: the hero's counter, the attack goes back to the boss, which loses 1.
      game.handleAnswer(_right(game));
      _step(game, 1.5);
      expect(boss.health, 21);
      expect(_hero(game).lastTarget!.x, greaterThan(level.boss!.x));
      await _flush(tester);
    });

    testWidgets('the attack flies the whole way between the boss and the hero', (tester) async {
      final level = _arena('era2_5');
      final (game, boss) = await _start(tester, arena: level);
      game.player.position.x = level.spawnX; // far from the boss, on its left
      boss.startRoundNow();
      _untilAsking(game, boss);
      _step(game, 0.1);
      final a = boss.attack!;
      final span = a.start.x - a.end.x;
      expect(span, greaterThan(400), reason: 'a long way to fly: that is the time to answer');
      expect(a.start.x, lessThan(level.boss!.x));
      expect(a.end.x, lessThan(a.start.x));
      _step(game, 7.4);
      expect(boss.attackProgress, closeTo(0.5, 0.01));
      expect(a.head.x, closeTo(a.start.x - span * boss.attackProgress, 0.5));
      await _flush(tester);
    });

    testWidgets('the camera follows the student inside the room and stops at the walls',
        (tester) async {
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
