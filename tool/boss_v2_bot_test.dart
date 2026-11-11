// ignore_for_file: invalid_use_of_visible_for_testing_member, unused_local_variable
// A development tool, not a test of behaviour: a bot plays the boss fight v2 through the real game
// (real arena, physics, controls, question card) and prints what happened, so problems can be
// found without a device.
//
//   flutter test tool/boss_v2_bot_test.dart --dart-define=BOT_ERA=2 [--dart-define=BOT_OUT=C:/temp/bot]
//
// BOT_ERA is 1 to 6. Without it the test does nothing. The bot walks to each rune with the arrow
// controls (jumping when it is stuck), fights the minions of a wave, and answers every question
// right except every fourth, which it answers wrong. It reports: how long each rune took to
// reach, whether it got stuck, heart losses and why, the sides of the boss it fought from, and
// writes a few pictures.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chronoquest/core/theme.dart';
import 'package:chronoquest/data/question_bank.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/boss_component.dart';
import 'package:chronoquest/game/overlays/hud_overlay.dart';
import 'package:chronoquest/game/overlays/question_overlay.dart';
import 'package:chronoquest/game/quiz_handler.dart';
import 'package:chronoquest/models/control_scheme.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_test/flutter_test.dart';

const _era = int.fromEnvironment('BOT_ERA');
const _out = String.fromEnvironment('BOT_OUT', defaultValue: 'bot');
const _eraIds = ['pre-colonial', 'spanish', 'nationalism', 'american', 'ww2', 'modern'];
const _bossLevels = [10, 5, 7, 8, 8, 5];

void main() {
  testWidgets('boss v2 bot', timeout: const Timeout(Duration(minutes: 20)), (tester) async {
    if (_era == 0) return;
    tester.view.physicalSize = const Size(873 * 2.0, 393 * 2.0);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.runAsync(QuestionBank.loadAll);
    final game = ChronoGame()
      ..currentEra = _eraIds[_era - 1]
      ..currentLevel = _bossLevels[_era - 1]
      ..selectedCharacterId = 'boy'
      ..hearts = 5;
    final reportError = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception is MissingPluginException) return;
      reportError?.call(d);
    };
    addTearDown(() => FlutterError.onError = reportError);
    if (game.audioService.soundEnabled) game.audioService.toggleSound();
    final key = GlobalKey();
    final log = <String>[];
    void say(String s) {
      log.add(s);
      // ignore: avoid_print
      print(s);
    }

    var shots = 0;
    Future<void> shot(String name) async {
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 16));
      }
      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      final file = File('${_out}_e${_era}_${(++shots).toString().padLeft(2, '0')}_$name.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes!);
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
                return QuestionOverlayWidget(game: cg, onAnswer: cg.handleAnswer);
              },
              'BossHealthOverlay': (c, g) => BossHealthOverlayWidget(game: g as ChronoGame),
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
    game.gameInput.setScheme(ControlScheme.arrows);
    game.playerPowerUps.shield = 2;
    game.playerPowerUps.timeFreeze = 2;
    game.playerPowerUps.fiftyFifty = 2;

    BossComponent? boss() => game.boss;
    double heroX() => game.player.position.x + game.player.size.x / 2;
    final bossX = game.tiledLevel?.boss?.x ?? 912;
    say('era $_era: boss x=$bossX, spawn x=${game.tiledLevel?.spawnX}, hero starts x=${heroX().round()}');

    // --- the bot ---
    var time = 0.0;
    var jumpCool = 0.0;
    var lastX = heroX();
    var stuckFor = 0.0;
    var runeStart = 0.0;
    BossRoundState? lastState;
    var lastHearts = game.hearts;
    var rounds = 0;
    var answeredWrong = 0;
    var crossings = 0;
    var lastSide = heroX() > bossX ? 1 : -1;
    var maxStuck = 0.0;
    var attackCool = 0.0;
    var usedFreeze = false, usedFifty = false, usedShield = false;

    void hold(double dir) {
      game.gameInput.setLeftHeld(dir < 0);
      game.gameInput.setRightHeld(dir > 0);
    }

    // The loop: 1/60 s frames; a picture every so often is taken outside it.
    for (var frame = 0; frame < 60 * 600; frame++) {
      final b = boss();
      if (b == null || b.isDefeated || game.levelEnded) break;
      const dt = 1 / 60;
      time += dt;
      jumpCool -= dt;
      attackCool -= dt;
      final hx = heroX();
      if (b.state != lastState) {
        if (b.state == BossRoundState.rune) {
          runeStart = time;
          stuckFor = 0;
        }
        say('${time.toStringAsFixed(1)}s ${b.state.name} hero x=${hx.round()} hearts=${game.hearts} boss ${b.maxHealth - b.health}/${b.maxHealth}'
            '${b.state == BossRoundState.rune && b.rune != null ? ' rune x=${b.rune!.centreX.round()} (${(b.rune!.centreX - hx).abs().round()} away)' : ''}'
            '${b.state == BossRoundState.wave ? ' minions=${b.minionsAlive}' : ''}');
        if (lastState == BossRoundState.rune && b.state == BossRoundState.windup) {
          say('   rune reached in ${(time - runeStart).toStringAsFixed(1)} s${b.stalled ? ' (STALL: gave up)' : ''}');
        }
        lastState = b.state;
      }
      if (game.hearts < lastHearts) {
        say('   -1 heart at ${time.toStringAsFixed(1)}s in ${b.state.name} (hearts now ${game.hearts})');
      }
      lastHearts = game.hearts;
      final side = hx > bossX ? 1 : -1;
      if (side != lastSide) {
        crossings++;
        say('   hero crossed the boss to the ${side > 0 ? 'right' : 'left'} at ${time.toStringAsFixed(1)}s, boss faces right=${b.facesRight}');
        lastSide = side;
      }

      double dir = 0;
      var jump = false;
      switch (b.state) {
        case BossRoundState.rune:
          final r = b.rune;
          if (r != null) {
            final d = r.centreX - hx;
            dir = d.abs() < 10 ? 0 : d.sign;
            // stuck in front of something: jump
            if ((hx - lastX).abs() < 0.2 && d.abs() > 30) {
              stuckFor += dt;
            } else {
              stuckFor = 0;
            }
            if (stuckFor > 0.15 && jumpCool <= 0) jump = true;
            // a step or a gap ahead: jump early
            if (game.player.isOnGround && jumpCool <= 0 && d.abs() > 80) {
              final ahead = hx + dir * 46;
              if (!(game.tiledLevel?.isOverGround(ahead) ?? true)) jump = true;
            }
            if (stuckFor > maxStuck) maxStuck = stuckFor;
            if (stuckFor > 3) {
              say('   STUCK for ${stuckFor.toStringAsFixed(1)} s at x=${hx.round()} going to ${r.centreX.round()}');
              stuckFor = -1000; // say it once
            }
          }
        case BossRoundState.wave:
          if (frame % 20 == 0) say('      wave t=${time.toStringAsFixed(1)} hero=${hx.round()} face=${game.player.facingRight} kaal=${game.kaalaman} hearts=${game.hearts} minions=${b.minions.map((m) => '${m.kind}@${(m.position.x + m.size.x / 2).round()}${m.defeated ? "x" : ""}/${m.isMounted ? "m" : "u"}').join(" ")}');
          final live = b.minions.where((m) => !m.defeated && m.isMounted).toList();
          if (live.isNotEmpty) {
            live.sort((p, q) => (p.position.x - hx).abs().compareTo((q.position.x - hx).abs()));
            final m = live.first;
            final mx = m.position.x + m.size.x / 2;
            final d = mx - hx;
            if (d.abs() > 80) {
              dir = d.sign;
            } else if (attackCool <= 0) {
              game.player.facingRight = d > 0;
              game.onPlayerAttack();
              attackCool = 0.5;
            }
            if ((hx - lastX).abs() < 0.2 && d.abs() > 100) {
              stuckFor += dt;
              if (stuckFor > 0.2 && jumpCool <= 0) jump = true;
            } else {
              stuckFor = 0;
            }
          }
          if (!usedShield && live.length >= 2 && time > 30) {
            usedShield = game.activateShield();
            say('   Shield switched on during a wave: $usedShield');
          }
        case BossRoundState.asking:
          if (b.asking) {
            // use the power-ups once each
            if (!usedFifty && b.round >= 2) {
              usedFifty = true;
              // the overlay buttons are widgets: tap through the game's own state instead
              say('   (50/50 and Time Freeze are widget buttons: covered by the tests)');
            }
            // answer after 3 s, wrong every fourth round
            if (b.secondsLeft < b.answerSeconds - 3) {
              final q = game.currentQuestion!;
              final wrongRound = (b.round + answeredWrong) % 4 == 0 && rounds % 4 == 3;
              final wrong = q.options.map((o) => o.label).firstWhere((l) => l != q.correctAnswer);
              game.handleAnswer(wrongRound ? wrong : q.correctAnswer);
              if (wrongRound) answeredWrong++;
              rounds++;
            }
          }
        default:
          break;
      }
      hold(dir);
      if (jump) {
        game.onPlayerJump();
        jumpCool = 0.45;
      }
      lastX = hx;
      game.update(dt);
      if (frame % 6 == 0) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(microseconds: 300)));
        await tester.pump(const Duration(milliseconds: 1));
      }
      // pictures at a few moments
      if (frame % 1200 == 600 && shots < 12) await shot('${b.state.name}');
    }
    hold(0);
    final b = boss();
    say('END at ${time.toStringAsFixed(0)}s: boss ${b == null ? 'gone' : (b.isDefeated ? 'DEFEATED' : '${b.maxHealth - b.health}/${b.maxHealth} right')}, hearts ${game.hearts}, levelEnded=${game.levelEnded}, crossings=$crossings, longest stuck=${maxStuck.toStringAsFixed(1)} s');
    await shot('end');
    File('${_out}_e$_era.log').writeAsStringSync(log.join('\n'));
  });
}
