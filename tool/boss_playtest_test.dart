// A development tool, not a test of behaviour: plays a boss fight through the real
// game (real arena, sprites, HUD, controls, question card, boss bar) at a phone-sized
// window and writes a PNG at each moment, so the fight can be reviewed without a device.
//
//   flutter test tool/boss_playtest_test.dart \
//       --dart-define=BOSS_ERA=2 --dart-define=BOSS_SIZE=873x393 \
//       --dart-define=BOSS_OUT=C:/temp/boss
//
// BOSS_ERA is 1 to 6. Without it the test does nothing, so it is safe in a full
// `flutter test tool` run.
//
// It plays the whole fight (2026-11 flow: wind-up, an attack that flies at the hero while the
// question card is open, the hero's counter or the hit): every round answered right except the
// third, whose question comes back at the end. Pictures: the arena, the wind-up, the first
// question of each phase (at the throw and half way), the result of the first right and the first
// wrong answer, and the end.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chronoquest/core/theme.dart';
import 'package:chronoquest/data/question_bank.dart';
import 'package:chronoquest/game/answer_point_handler.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/boss_component.dart';
import 'package:chronoquest/game/overlays/gate_locked_overlay.dart';
import 'package:chronoquest/game/overlays/hud_overlay.dart';
import 'package:chronoquest/game/overlays/question_overlay.dart';
import 'package:chronoquest/game/quiz_handler.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_test/flutter_test.dart';

const _era = int.fromEnvironment('BOSS_ERA');
const _size = String.fromEnvironment('BOSS_SIZE', defaultValue: '873x393');
const _out = String.fromEnvironment('BOSS_OUT', defaultValue: 'boss');

const _eraIds = ['pre-colonial', 'spanish', 'nationalism', 'american', 'ww2', 'modern'];
const _bossLevels = [10, 5, 7, 8, 8, 5];

void main() {
  testWidgets('boss playtest', timeout: const Timeout(Duration(minutes: 8)), (tester) async {
    if (_era == 0) return;
    final parts = _size.split('x').map(int.parse).toList();
    tester.view.physicalSize = Size(parts[0] * 2.0, parts[1] * 2.0);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.runAsync(QuestionBank.loadAll);
    final game = ChronoGame()
      ..currentEra = _eraIds[_era - 1]
      ..currentLevel = _bossLevels[_era - 1]
      ..selectedCharacterId = 'boy'
      ..hearts = 5;
    // No audio plugin in a test: its late channel errors are not the fight's.
    final reportError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is MissingPluginException) return;
      reportError?.call(details);
    };
    addTearDown(() => FlutterError.onError = reportError);
    if (game.audioService.soundEnabled) game.audioService.toggleSound();
    final key = GlobalKey();
    var n = 0;

    Future<void> shot(String name) async {
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 16));
      }
      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.5);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      final file = File('${_out}_e${_era}_${(++n).toString().padLeft(2, '0')}_$name.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes!);
      // ignore: avoid_print
      print('wrote ${file.path}');
    }

    Future<void> run(double seconds, {bool Function()? until}) async {
      for (var t = 0.0; t < seconds; t += 0.1) {
        if (until != null && until()) break;
        game.update(0.1);
        if ((t * 10).round() % 3 == 0) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: RepaintBoundary(
          key: key,
          child: GameWidget(
            game: game,
            overlayBuilderMap: {
              'HudOverlay': (c, g) => HudOverlayWidget(game: g as ChronoGame),
              'QuestionOverlay': (c, g) {
                final cg = g as ChronoGame;
                return QuestionOverlayWidget(
                  game: cg,
                  onAnswer: cg.activeArtifact != null ? cg.handleAnswerPointAnswer : cg.handleAnswer,
                );
              },
              'BossHealthOverlay': (c, g) => BossHealthOverlayWidget(game: g as ChronoGame),
              'GateLockedOverlay': (c, g) => GateLockedOverlayWidget(game: g as ChronoGame),
            },
            initialActiveOverlays: const ['HudOverlay'],
          ),
        ),
      ),
    ));
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 16));
    }

    await shot('arena_start');
    // (the arena starts the fight by itself as soon as the level is up)
    await run(8, until: () => game.boss?.state == BossRoundState.windup);
    await run(0.5);
    await shot('windup');

    var lastSeconds = -1;
    for (var round = 1; round <= 25; round++) {
      final boss = game.boss;
      if (boss == null || boss.isDefeated) {
        // ignore: avoid_print
        print('stopped at round $round: boss ${boss == null ? 'gone' : 'defeated'}');
        break;
      }
      await run(8, until: () => boss.asking);
      if (!boss.asking) {
        // ignore: avoid_print
        print('stopped at round $round: no question (${boss.state})');
        break;
      }
      final seconds = boss.answerSeconds.round();
      final first = seconds != lastSeconds;
      if (first) {
        lastSeconds = seconds;
        await run(0.4);
        await shot('throw_${seconds}s_${boss.maxHealth - boss.health}_of_${boss.maxHealth}');
        await run(boss.answerSeconds * 0.45);
        await shot('flight_${seconds}s');
      }
      // ignore: avoid_print
      print('round ${boss.round}: ${boss.maxHealth - boss.health}/${boss.maxHealth} right, ${boss.answerSeconds}s, ${boss.attackKind?.name}');
      final q = game.currentQuestion!;
      final wrongOne = q.options.map((o) => o.label).firstWhere((l) => l != q.correctAnswer);
      final right = round != 3;
      game.handleAnswer(right ? q.correctAnswer : wrongOne);
      await run(right ? 0.9 : 1.2);
      if (round <= 3) await shot('result_round${round}_${right ? 'right' : 'wrong'}');
    }
    await run(4);
    await shot('end');
  });
}
