// The golden artifact and its portal (the 2026-11 update): one golden artifact in
// each level from level 2 on, never in a boss level; a right answer on the FIRST try
// opens a golden portal where it stood for 5 seconds; walking into it holds the level
// still and shows the bonus round; the level carries on exactly as it was after.
import 'dart:async';
import 'dart:io';

import 'package:chronoquest/core/bonus_constants.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/data/question_pool.dart';
import 'package:chronoquest/game/answer_point_handler.dart';
import 'package:chronoquest/game/bonus/bonus_session.dart';
import 'package:chronoquest/game/bonus_handler.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/artifact_component.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/golden_portal_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_input.dart';
import 'package:chronoquest/game/level_loader.dart';
import 'package:chronoquest/models/question.dart';
import 'package:chronoquest/services/audio_service.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// A level with a floor and a hero standing on it, and nothing else.
class _GoldGame extends ChronoGame {
  _GoldGame({int level = 3, String era = 'spanish'}) {
    currentEra = era;
    currentLevel = level;
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

Future<_GoldGame> _mount(WidgetTester tester,
    {int level = 3, String era = 'spanish'}) async {
  final game = _GoldGame(level: level, era: era);
  await tester.pumpWidget(MaterialApp(
    home: GameWidget(
      game: game,
      overlayBuilderMap: {
        'QuestionOverlay': (_, __) => const SizedBox.shrink(),
      },
    ),
  ));
  await tester.pump();
  await _settle(tester);
  game.questionPool = QuestionPool(questions: [
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
  return game;
}

/// Adds an artifact standing 400 units into the level and waits for it to load.
Future<ArtifactComponent> _addArtifact(WidgetTester tester, _GoldGame game,
    {bool golden = true, double x = 900}) async {
  final a = ArtifactComponent(worldX: x, spriteIndex: 1, golden: golden);
  game.world.add(a);
  await _settle(tester, frames: 6);
  return a;
}

/// Opens the artifact's question and answers it. 'A' is the right answer (whatever
/// the question's own label for it is: the pool shuffles), 'B' a wrong one, and ''
/// is the question timer running out.
void _answer(_GoldGame game, ArtifactComponent a, String answer) {
  game.showArtifactQuestion(a);
  final text = switch (answer) {
    'A' => game.currentQuestion!.correctAnswer,
    'B' => 'definitely-wrong',
    _ => answer,
  };
  game.handleAnswerPointAnswer(text);
}

/// A widget test that, once it has said what it has to, lets the hero's short
/// reactions (a cheer, a hurt pose) finish, so no timer is left pending.
void _test(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    await body(tester);
    await tester.pump(const Duration(seconds: 1));
  });
}

/// Steps the portal by hand, a frame at a time.
void _run(GoldenPortalComponent p, double seconds) {
  var left = seconds;
  while (left > 1e-9) {
    final dt = left < 1 / 60 ? left : 1 / 60;
    p.update(dt);
    left -= dt;
  }
}

/// Puts the middle of the hero in the middle of the portal, feet on the floor.
void _walkInto(_GoldGame game, GoldenPortalComponent p) {
  game.player.position = Vector2(
    p.position.x + p.size.x / 2 - game.player.size.x / 2,
    game.groundY - game.player.size.y,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageDir =
      Directory.systemTemp.createTempSync('chronoquest_golden_test_').path;

  setUpAll(() async {
    // No sound plugin in a test: the sound switch is off, as for a student who muted it.
    AudioService().setSoundEnabled(false);
    Hive.init(storageDir);
    await Hive.openBox('chronoquest');
  });


  // ─── the mark in the maps ──────────────────────────────────────────────────
  group('the golden mark in the maps', () {
    String mapText(int era, int level) =>
        File('assets/tiles/levels/era${era}_$level.tmx').readAsStringSync();

    test('only from level 2 on, one a level, never in a boss level', () {
      var golden = 0;
      for (var e = 0; e < allEras.length; e++) {
        final count = allEras[e].levels.length;
        for (var n = 1; n <= count; n++) {
          final artifacts = LevelLoader.parse(mapText(e + 1, n))
              .entities
              .where((x) => x.type == 'artifact')
              .toList();
          final marked = artifacts.where((a) => a.golden).length;
          final boss = n == count;
          if (boss || n < BonusConstants.firstGoldenLevel) {
            expect(marked, 0, reason: '${allEras[e].id} level $n has none');
          } else {
            expect(marked, 1, reason: '${allEras[e].id} level $n has exactly one');
            // The middle one, counted from the left.
            final sorted = [...artifacts]..sort((a, b) => a.x.compareTo(b.x));
            expect(sorted[sorted.length ~/ 2].golden, isTrue);
            golden++;
          }
        }
      }
      expect(golden, 31, reason: '37 non-boss levels minus the 6 first levels');
    });

    test('the builder makes the marked artifact golden from level 2 on only', () {
      final level = LevelLoader.parse(mapText(2, 3));
      final world = Component();
      LevelBuilder.build(level: level, world: world, groundY: 660, eraId: 'spanish', levelNo: 3);
      final made = world.children.whereType<ArtifactComponent>().toList();
      expect(made.where((a) => a.golden).length, 1);

      // Even a mark on a first-level map would not count.
      final first = Component();
      LevelBuilder.build(level: level, world: first, groundY: 660, eraId: 'spanish', levelNo: 1);
      expect(first.children.whereType<ArtifactComponent>().where((a) => a.golden), isEmpty);

      // Built exactly as the map says when no level number is given.
      final bare = Component();
      LevelBuilder.build(level: level, world: bare, groundY: 660, eraId: 'spanish');
      expect(bare.children.whereType<ArtifactComponent>().where((a) => a.golden).length, 1);
    });
  });

  // ─── how it looks ──────────────────────────────────────────────────────────
  group('the golden artifact', () {
    _test('is drawn gold; an ordinary one is not', (tester) async {
      final game = await _mount(tester);
      final gold = await _addArtifact(tester, game, golden: true, x: 900);
      final plain = await _addArtifact(tester, game, golden: false, x: 1400);
      expect(gold.golden, isTrue);
      expect(gold.paint.colorFilter, isNotNull, reason: 'a gold wash over the picture');
      expect(plain.golden, isFalse);
      expect(plain.paint.colorFilter, isNull);
      // Both still behave as artifacts.
      expect(gold.isInteractable, isTrue);
      expect(gold.reward, 2);
    });
  });

  // ─── when the portal opens ─────────────────────────────────────────────────
  group('the portal opens only for a right answer on the first try', () {
    _test('a first-try right answer opens it where the artifact stood',
        (tester) async {
      final game = await _mount(tester);
      final a = await _addArtifact(tester, game);

      _answer(game, a, 'A');
      await _settle(tester, frames: 3);

      final portal = game.bonus.portal;
      expect(portal, isNotNull);
      expect(game.bonus.offered, isTrue);
      expect(portal!.phase, PortalPhase.opening);
      expect(portal.worldCenter.x, a.worldX + 36, reason: 'in the middle of the artifact');
      expect(portal.position.y + portal.size.y, game.groundY, reason: 'standing on the floor');
      expect(game.world.children.contains(portal), isTrue);
    });

    _test('a wrong first try opens nothing, and neither does a right second try',
        (tester) async {
      final game = await _mount(tester);
      final a = await _addArtifact(tester, game);

      _answer(game, a, 'B');
      expect(game.bonus.portal, isNull);
      _answer(game, a, 'A');
      await _settle(tester, frames: 3);

      expect(game.bonus.portal, isNull, reason: 'the second answer is not the first try');
      expect(game.bonus.offered, isFalse);
      expect(a.claimed, isTrue, reason: 'the artifact is still claimed as usual');
    });

    _test('a wrong first try that a Shield absorbed is still a first try used',
        (tester) async {
      final game = await _mount(tester);
      final a = await _addArtifact(tester, game);

      game.shieldActive = true;
      _answer(game, a, 'B');
      _answer(game, a, 'A');

      expect(game.bonus.portal, isNull);
    });

    _test('a question that ran out of time is a wrong first try', (tester) async {
      final game = await _mount(tester);
      final a = await _addArtifact(tester, game);

      game.shieldActive = true; // so the heart it costs does not end this test's level
      _answer(game, a, '');
      _answer(game, a, 'A');

      expect(game.bonus.portal, isNull);
    });

    _test('an ordinary artifact never opens one', (tester) async {
      final game = await _mount(tester);
      final a = await _addArtifact(tester, game, golden: false);

      _answer(game, a, 'A');

      expect(game.bonus.portal, isNull);
      expect(game.bonus.offered, isFalse);
    });

    _test('not in level 1, and not in a boss level', (tester) async {
      for (final level in [1, 5]) {
        // Spanish has five levels: 1 is the first, 5 is the boss.
        final game = await _mount(tester, level: level);
        final a = await _addArtifact(tester, game);

        _answer(game, a, 'A');

        expect(game.bonus.portal, isNull, reason: 'level $level');
        expect(game.canOfferBonus, isFalse, reason: 'level $level');
        await tester.pumpWidget(const SizedBox());
      }
    });

    _test('only one portal a level, whatever else is answered', (tester) async {
      final game = await _mount(tester);
      final a = await _addArtifact(tester, game, x: 900);
      final b = await _addArtifact(tester, game, x: 1700);

      _answer(game, a, 'A');
      final first = game.bonus.portal;
      expect(first, isNotNull);
      _answer(game, b, 'A');
      await _settle(tester, frames: 3);

      expect(game.bonus.portal, same(first), reason: 'no second portal');
      expect(game.world.children.whereType<GoldenPortalComponent>().length, 1);
    });
  });

  // ─── the 5 seconds ─────────────────────────────────────────────────────────
  group('the portal window', () {
    Future<(_GoldGame, GoldenPortalComponent)> open(WidgetTester tester) async {
      final game = await _mount(tester);
      final a = await _addArtifact(tester, game);
      _answer(game, a, 'A');
      await _settle(tester, frames: 3);
      return (game, game.bonus.portal!);
    }

    _test('takes under a second to open, and cannot be entered while it does',
        (tester) async {
      final (game, portal) = await open(tester);
      _walkInto(game, portal);
      var shown = 0;
      game.bonus.onEnter = (r) async {
        shown++;
        return null;
      };

      _run(portal, BonusConstants.portalOpenSeconds - .1);
      expect(portal.phase, PortalPhase.opening);
      expect(portal.canEnter, isFalse);
      expect(shown, 0, reason: 'standing in it while it opens does nothing');

      _run(portal, .1 + 1 / 30);
      // The hero stood in the doorway the whole time: now it is open, it takes them.
      expect(shown, 1);
    });

    _test('stays open for 5 seconds, then closes and goes; the level goes on',
        (tester) async {
      final (game, portal) = await open(tester);
      var shown = 0;
      game.bonus.onEnter = (r) async {
        shown++;
        return null;
      };
      expect(BonusConstants.portalSeconds, 5.0);

      _run(portal, BonusConstants.portalOpenSeconds + .01);
      expect(portal.phase, PortalPhase.open);
      expect(portal.remaining, closeTo(5.0, .05));

      _run(portal, 4.5);
      expect(portal.phase, PortalPhase.open, reason: '4.5 s of the 5 have passed');
      expect(portal.remaining, closeTo(.5, .06));

      _run(portal, .6);
      expect(portal.phase, PortalPhase.closing, reason: 'the 5 seconds are over');
      expect(portal.canEnter, isFalse);

      _run(portal, BonusConstants.portalCloseSeconds + .05);
      expect(portal.isGone, isTrue);
      expect(portal.isRemoving, isTrue);
      await _settle(tester, frames: 3);
      expect(game.world.children.contains(portal), isFalse);
      expect(shown, 0, reason: 'nobody walked in: no round');
      expect(game.bonus.away, isFalse);
      expect(game.bonus.played, isFalse);
      expect(game.paused, isFalse, reason: 'the level never stopped');
    });

    _test('a hero that walks in after it has closed gets nothing', (tester) async {
      final (game, portal) = await open(tester);
      var shown = 0;
      game.bonus.onEnter = (r) async {
        shown++;
        return null;
      };
      _run(portal, BonusConstants.portalOpenSeconds + BonusConstants.portalSeconds + .1);
      _walkInto(game, portal);
      _run(portal, .2);
      expect(shown, 0);
    });

    _test('the countdown only runs while the game does (a question or the pause menu freeze it)',
        (tester) async {
      final (game, portal) = await open(tester);
      _run(portal, BonusConstants.portalOpenSeconds + 1);
      final left = portal.remaining;

      // The engine is the one thing that updates it: paused, nothing moves.
      game.pauseEngine();
      await tester.pump(const Duration(seconds: 3));
      expect(portal.remaining, left);
      game.resumeEngine();
    });
  });

  // ─── walking in, the round, and coming back ────────────────────────────────
  group('walking into the portal', () {
    _test('holds the level still, shows the round, and puts the level back as it was',
        (tester) async {
      final game = await _mount(tester);
      final a = await _addArtifact(tester, game);
      _answer(game, a, 'A');
      await _settle(tester, frames: 3);
      final portal = game.bonus.portal!;
      _run(portal, BonusConstants.portalOpenSeconds + .1);

      // What the level looks like before.
      game.hearts = 3;
      game.kaalaman = 7;
      final coinsBefore = game.playerCoins;
      final answeredBefore = game.artifactsAnswered;
      final done = Completer<BonusResult?>();
      BonusRequest? asked;
      game.bonus.onEnter = (request) {
        asked = request;
        return done.future;
      };

      _walkInto(game, portal);
      portal.update(1 / 60);

      expect(asked, isNotNull, reason: 'the round was asked for, with no button');
      expect(asked!.eraId, 'spanish');
      expect(asked!.levelNo, 3);
      expect(asked!.portalOnScreen.dx, inInclusiveRange(0, 1));
      expect(game.bonus.away, isTrue);
      expect(game.bonus.played, isTrue);
      expect(game.paused, isTrue, reason: 'nothing runs while away');
      expect(portal.phase, PortalPhase.entering);

      // Away: the portal does not count down, a second walk-in does nothing, and
      // the level's engine is stopped.
      final heldAt = portal.remaining;
      portal.update(2);
      expect(portal.remaining, heldAt, reason: 'the countdown is held too');
      var asks = 0;
      game.bonus.onEnter = (r) {
        asks++;
        return done.future;
      };
      portal.update(1 / 60);
      await game.enterBonusPortal(portal);
      expect(asks, 0);

      // The student comes back with 12 coins already in the wallet.
      done.complete(const BonusResult(coins: 12, grabbed: 17, knockedLoose: 5));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(game.bonus.away, isFalse);
      expect(game.paused, isFalse, reason: 'the level carries on');
      expect(game.hearts, 3, reason: 'the same hearts');
      expect(game.kaalaman, 7, reason: 'the same Kaalaman charges');
      expect(game.artifactsAnswered, answeredBefore);
      expect(game.playerCoins, coinsBefore + 12, reason: "the level's own count shows the bonus");
      expect(game.bonus.coinsWon, 12);
      expect(portal.phase, PortalPhase.returning, reason: 'the portal glows where the artifact was');

      // And it is not offered again.
      expect(game.bonus.offered, isTrue);
      expect(game.canOfferBonus, isFalse);
    });

    _test('a round that could not be shown lets the level go on', (tester) async {
      final game = await _mount(tester);
      final a = await _addArtifact(tester, game);
      _answer(game, a, 'A');
      await _settle(tester, frames: 3);
      final portal = game.bonus.portal!;
      _run(portal, BonusConstants.portalOpenSeconds + .1);
      game.bonus.onEnter = (r) async => throw StateError('no screen');

      _walkInto(game, portal);
      portal.update(1 / 60);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(game.bonus.away, isFalse);
      expect(game.paused, isFalse);
    });

    _test('with no screen to show it a bare game just closes the portal', (tester) async {
      final game = await _mount(tester);
      final a = await _addArtifact(tester, game);
      _answer(game, a, 'A');
      await _settle(tester, frames: 3);
      final portal = game.bonus.portal!;
      _run(portal, BonusConstants.portalOpenSeconds + .1);

      _walkInto(game, portal);
      portal.update(1 / 60);

      expect(game.bonus.away, isFalse);
      expect(game.paused, isFalse);
      expect(portal.phase, PortalPhase.closing);
    });

    _test('a hero that is above the portal, or beside it, is not inside', (tester) async {
      final game = await _mount(tester);
      final a = await _addArtifact(tester, game);
      _answer(game, a, 'A');
      await _settle(tester, frames: 3);
      final portal = game.bonus.portal!;
      _run(portal, BonusConstants.portalOpenSeconds + .1);
      game.bonus.onEnter = (r) async => null;

      // Beside it, touching the artifact's old spot but not the doorway.
      game.player.position.x = portal.position.x - 70;
      expect(portal.heroInside(), isFalse);
      // High above (a jump over it, or on a platform over it).
      game.player.position
        ..x = portal.position.x + portal.size.x / 2 - 48
        ..y = portal.position.y - 200;
      expect(portal.heroInside(), isFalse);
      // In the doorway.
      _walkInto(game, portal);
      expect(portal.heroInside(), isTrue);
    });
  });
}
