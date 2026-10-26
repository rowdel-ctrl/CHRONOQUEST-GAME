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
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chronoquest/core/theme.dart';
import 'package:chronoquest/data/question_bank.dart';
import 'package:chronoquest/game/answer_point_handler.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/overlays/gate_locked_overlay.dart';
import 'package:chronoquest/game/overlays/hud_overlay.dart';
import 'package:chronoquest/game/overlays/question_overlay.dart';
import 'package:chronoquest/game/quiz_handler.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _era = int.fromEnvironment('BOSS_ERA');
const _size = String.fromEnvironment('BOSS_SIZE', defaultValue: '873x393');
const _out = String.fromEnvironment('BOSS_OUT', defaultValue: 'boss');

const _eraIds = ['pre-colonial', 'spanish', 'nationalism', 'american', 'ww2', 'modern'];
const _bossLevels = [10, 5, 7, 8, 8, 5];

void main() {
  testWidgets('boss playtest', timeout: const Timeout(Duration(minutes: 4)), (tester) async {
    if (_era == 0) return;
    final parts = _size.split('x').map(int.parse).toList();
    tester.view.physicalSize = Size(parts[0] * 2.0, parts[1] * 2.0);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.runAsync(QuestionBank.loadAll);
    final game = ChronoGame()
      ..currentEra = _eraIds[_era - 1]
      ..currentLevel = _bossLevels[_era - 1]
      ..selectedCharacterId = 'rizal'
      ..hearts = 5;
    final key = GlobalKey();
    var n = 0;

    Future<void> run(double seconds, {bool stopOnQuestion = true}) async {
      for (var t = 0.0; t < seconds; t += 0.1) {
        if (stopOnQuestion && game.questionShowing) break;
        game.update(0.1);
        if ((t * 10).round() % 3 == 0) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

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

    // The student walks into the arena: put them at the map's start and begin the fight.
    await shot('arena_start');
    game.startBossFight();
    await run(1.0);
    await shot('boss_walking_in');
    await run(20);
    await shot('first_question');

    // Six rounds: a right answer, the minion wave, the next question. Round 3 is
    // answered wrong, to see that card too.
    for (var round = 1; round <= 7; round++) {
      if (game.boss == null || !game.questionShowing) break;
      final q = game.currentQuestion!;
      final wrongOne = q.options.map((o) => o.label).firstWhere((l) => l != q.correctAnswer);
      final right = round != 3;
      game.handleAnswer(right ? q.correctAnswer : wrongOne);
      await tester.pump(const Duration(milliseconds: 300));
      await shot('round${round}_${right ? 'right' : 'wrong'}_after');
      await run(4, stopOnQuestion: true);
      await shot('round${round}_wave');
      // let the wave stand a while, then clear it so the next question comes
      await run(30, stopOnQuestion: true);
      if (!game.questionShowing) {
        for (final e in game.world.children.toList()) {
          if (e.runtimeType.toString() == 'EnemyComponent') e.removeFromParent();
        }
        await run(10, stopOnQuestion: true);
      }
      if (game.questionShowing) await shot('round${round + 1}_question');
    }
    await tester.pump(const Duration(seconds: 4));
    await shot('end');
  });
}
