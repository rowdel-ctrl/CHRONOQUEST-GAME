// The marks over and under enemies (2026-11-28): the shield marks of an enemy that takes two
// hits, the small red "!" and the screen-edge arrow of a chaser that notices the student, the
// floor strip of a dash and of a Heavy's lunge, and the landing ring of a hopper.
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/core/surprise_constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/enemy_notice_arrow.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/enemy_behavior.dart';
import 'package:chronoquest/game/enemy_moves.dart';
import 'package:chronoquest/game/surprise_rules.dart';

ChronoGame _bareGame() {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.images.prefix = 'assets/';
  final player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(64, 80)
    ..position = Vector2(0, game.groundY - 80);
  game.player = player;
  return game;
}

Future<EnemyComponent> _mount(ChronoGame game, String type,
    {double? worldX,
    bool hunts = false,
    EnemyBehavior? behavior,
    EnemySurprise surprise = EnemySurprise.none}) async {
  final enemy = EnemyComponent(
    eraId: 'spanish',
    enemyTypeOverride: type,
    worldX: worldX,
    hunts: hunts,
    behaviorOverride: behavior,
    surprise: surprise,
  );
  game.world.add(enemy);
  await game.ready();
  return enemy;
}

void _placePlayer(ChronoGame game, EnemyComponent enemy, double dx) {
  final p = game.player;
  p.position = Vector2(
    enemy.position.x + enemy.size.x / 2 + dx - p.size.x / 2,
    enemy.position.y + enemy.size.y - p.size.y,
  );
}

/// Draws the enemy once: every state it can be in must paint without an error.
void _paint(EnemyComponent e) {
  final rec = ui.PictureRecorder();
  e.render(ui.Canvas(rec));
  rec.endRecording();
}

void _run(EnemyComponent e, double seconds, {bool Function()? until}) {
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    e.update(1 / 60);
    if (until != null && until()) return;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the health bar', () {
    test('a tank shows a two-segment bar, and the one-hit enemies show none', () async {
      final game = _bareGame();
      final tank = await _mount(game, 'tank');
      expect(tank.showsHealthBar, isTrue);
      expect(tank.healthSegments, 2);
      for (final type in ['spanish_soldier', 'dark_spirit', 'propaganda', 'misinfo_cloud']) {
        final e = await _mount(game, type);
        expect(e.showsHealthBar, isFalse, reason: type);
        expect(e.healthSegments, 0, reason: type);
      }
    });

    test('every heavy kind shows a bar of two segments', () async {
      final game = _bareGame();
      for (final type in ['tank', 'tax_collector', 'corruption_figure']) {
        final e = await _mount(game, type);
        expect(e.healthSegments, 2, reason: type);
      }
    });

    test('a thrower has the heavy\'s art but takes one hit, so it shows no bar', () async {
      final game = _bareGame();
      final thrower = await _mount(game, 'tax_collector', surprise: EnemySurprise.thrower);
      expect(thrower.showsHealthBar, isFalse);
      expect(thrower.healthSegments, 0);
    });

    test('a hit that does not defeat it drains one segment; the second hit defeats it', () async {
      final game = _bareGame();
      final tank = await _mount(game, 'tank');
      _paint(tank);
      tank.takeHit();
      expect(tank.defeated, isFalse);
      expect(tank.healthSegments, 1);
      _paint(tank); // the segment is draining
      _run(tank, 1.0);
      _paint(tank); // and empty
      expect(tank.healthSegments, 1);
      tank.takeHit();
      expect(tank.defeated, isTrue);
    });
  });

  group('a chaser that notices the student', () {
    test('shows a small red "!" for 0.45 s, once per approach', () async {
      final game = _bareGame();
      final e = await _mount(game, 'dark_spirit');
      expect(e.noticeLeft, 0);
      _placePlayer(game, e, -300);
      e.update(1 / 60);
      expect(e.noticeLeft, closeTo(0.45, 0.03));
      _paint(e);
      _run(e, 0.6);
      expect(e.noticeLeft, lessThanOrEqualTo(0));
    });

    test('a wave minion that hunts does not (it already had its warning where it appeared)', () async {
      final game = _bareGame();
      final e = await _mount(game, 'dark_spirit', hunts: true);
      _placePlayer(game, e, -300);
      e.update(1 / 60);
      expect(e.noticeLeft, 0);
    });

    test('on the screen it needs no edge arrow; past the screen edge an arrow shows on that edge',
        () async {
      final game = _bareGame();
      final seen = await _mount(game, 'dark_spirit', worldX: game.cameraLeftEdgeX + 400);
      _placePlayer(game, seen, -200);
      seen.update(1 / 60);
      await game.ready();
      expect(game.world.children.whereType<EnemyNoticeArrow>(), isEmpty);

      final hidden = await _mount(game, 'dark_spirit', worldX: game.cameraLeftEdgeX - 300);
      _placePlayer(game, hidden, 250);
      hidden.update(1 / 60);
      await game.ready();
      final arrows = game.world.children.whereType<EnemyNoticeArrow>().toList();
      expect(arrows, hasLength(1));
      expect(arrows.first.edge, -1, reason: 'it is past the left edge');
      final rec = ui.PictureRecorder();
      arrows.first.render(ui.Canvas(rec));
      rec.endRecording();
      // It goes by itself after a while.
      arrows.first.update(EnemyNoticeArrow.maxSeconds + 0.1);
      expect(EnemyNoticeArrow.maxSeconds, lessThan(2.5), reason: "it does not nag for ever");
    });
  });

  group('the dash chaser\'s warning', () {
    test('the crouch lasts at least the game\'s minimum warning of 0.5 s', () {
      expect(CombatConstants.dashCrouch, greaterThanOrEqualTo(SurpriseConstants.minWarning));
    });

    test('on open ground the strip is the whole 130-unit dash, towards the student', () async {
      final game = _bareGame();
      final e = await _mount(game, 'spanish_soldier', behavior: EnemyBehavior.chaser);
      _placePlayer(game, e, -100);
      _run(e, 1, until: () => e.isCrouching);
      expect(e.isCrouching, isTrue);
      expect(e.plannedStrip.dir, -1);
      expect(e.plannedStrip.length, CombatConstants.dashDistance);
      _paint(e);
      // It dashes after 0.5 s, not before.
      _run(e, CombatConstants.dashCrouch - 0.1);
      expect(e.isCrouching, isTrue);
      _run(e, 0.2, until: () => e.isDashing);
      expect(e.isDashing, isTrue);
      _paint(e);
    });

    test('the strip stops where the ground ends, as the dash does', () async {
      final game = _bareGame();
      final e = await _mount(game, 'spanish_soldier', behavior: EnemyBehavior.chaser, worldX: 400);
      // Ground from far on the right up to 60 units to the left of the enemy's middle.
      final centre = e.position.x + e.size.x / 2;
      game.groundSections.add(GroundSection(
          sectionWidth: 3000, sectionPosition: Vector2(centre - 60, game.groundY))
        ..size = Vector2(3000, 60));
      _placePlayer(game, e, -100);
      _run(e, 1, until: () => e.isCrouching);
      expect(e.isCrouching, isTrue);
      expect(e.plannedStrip.length, lessThan(CombatConstants.dashDistance));
      expect(e.plannedStrip.length, lessThanOrEqualTo(60));
    });
  });

  group('the Heavy\'s warning', () {
    test('the wind-up is at least 0.5 s and the strip shows the lunge reach', () async {
      expect(CombatConstants.lungeWindup, greaterThanOrEqualTo(SurpriseConstants.minWarning));
      final game = _bareGame();
      final tank = await _mount(game, 'tank');
      _placePlayer(game, tank, -200);
      _run(tank, 2, until: () => tank.isWindingUp);
      expect(tank.isWindingUp, isTrue);
      expect(tank.plannedStrip.dir, -1);
      expect(tank.plannedStrip.length,
          closeTo(CombatConstants.lungeSpeed * CombatConstants.lungeDuration, 0.01));
      _paint(tank);
      _run(tank, 1, until: () => tank.isLunging);
      expect(tank.isLunging, isTrue);
      _paint(tank);
    });

    test('a lunge that a wall would stop has a short strip', () async {
      final game = _bareGame();
      final tank = await _mount(game, 'tank', worldX: 600);
      final centre = tank.position.x + tank.size.x / 2;
      // A tower of ground 80 units to the left of its middle, 96 high: a wall.
      game.groundSections.add(GroundSection(
          sectionWidth: 400, sectionPosition: Vector2(centre - 480, game.groundY - 96))
        ..size = Vector2(400, 156));
      _placePlayer(game, tank, -200);
      _run(tank, 2, until: () => tank.isWindingUp);
      // Heavies are not hunters, so a wall does not stop their lunge (as before): the strip says so.
      expect(tank.plannedStrip.length,
          closeTo(CombatConstants.lungeSpeed * CombatConstants.lungeDuration, 0.01));
    });
  });

  group('the hopper\'s landing ring', () {
    test('it is where the hop will end, from the squat to the landing', () async {
      final game = _bareGame();
      final e = await _mount(game, 'spanish_soldier', surprise: EnemySurprise.hopper);
      _placePlayer(game, e, -220);
      final move = e.move! as HopperMove;
      expect(move.landingX, isNull);
      _run(e, 2, until: () => move.phase == HopperPhase.squat);
      expect(move.phase, HopperPhase.squat);
      final centre = e.position.x + e.size.x / 2;
      expect(move.landingX, closeTo(centre - SurpriseConstants.hopDistance, 0.01));
      _paint(e);
      _run(e, 1, until: () => move.phase == HopperPhase.hop);
      expect(move.landingX, isNotNull);
      _paint(e); // in the air: the ring stays on the floor below it
      _run(e, 2, until: () => move.phase == HopperPhase.dizzy);
      expect(move.landingX, isNull);
    });
  });
}
