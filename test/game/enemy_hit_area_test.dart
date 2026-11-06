// New art (2026-11): enemy pictures have their own sizes, so the hit area follows the
// body (a low tank is only about 60 units high and stands on the ground) and a hit
// shows the hurt picture. Mounts a real GameWidget like sprite_scale_test.dart, because
// sizes, pictures and hitboxes are set in onLoad().
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/enemy_behavior.dart';
import 'package:chronoquest/game/game_spawning.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Game extends ChronoGame {
  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    camera.viewfinder.anchor = Anchor.topLeft;
    player = PlayerComponent(characterId: 'rizal')
      ..size = Vector2(96, 120)
      ..position = Vector2(0, groundY - 120);
    setupSpawning();
  }
}

Future<(_Game, EnemyComponent)> _mount(WidgetTester tester, String type) async {
  final game = _Game();
  await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  final enemy = EnemyComponent(eraId: 'ww2', enemyTypeOverride: type);
  game.world.add(enemy);
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 16));
  }
  return (game, enemy);
}

void main() {
  testWidgets('a tank hit area is about 60 high and its bottom sits on the feet line',
      (tester) async {
    final (_, tank) = await _mount(tester, 'tank');
    final r = tank.hitRect;
    expect(r.height, closeTo(60, 1));
    expect(r.bottom, closeTo(tank.position.y + tank.size.y, 0.01));
    expect(r.top, greaterThan(tank.position.y + tank.size.y - 61),
        reason: 'nothing above the tank can hurt');
    final box = tank.children.whereType<ShapeHitbox>().first;
    expect(box.size.y, closeTo(r.height, 0.01));
    expect(box.position.y + box.size.y, closeTo(tank.size.y, 0.01),
        reason: 'the collision box and hitRect are the same rectangle');
    expect(box.size.x, closeTo(r.width, 0.01));
  });

  testWidgets('every low or wide type has a body-sized hit area on the ground', (tester) async {
    for (final type in ['misinfo_cloud', 'japanese_soldier']) {
      final (_, e) = await _mount(tester, type);
      final data = enemyTypeDataFor(type);
      expect(e.hitRect.height, data.hitHeight, reason: type);
      expect(e.hitRect.bottom, closeTo(e.position.y + e.size.y, 0.01), reason: type);
    }
    final (_, cloud) = await _mount(tester, 'misinfo_cloud');
    expect(cloud.hitRect.height, lessThan(70));
  });

  testWidgets('a human keeps the old hit width and the old centred place', (tester) async {
    final (_, soldier) = await _mount(tester, 'spanish_soldier');
    final r = soldier.hitRect;
    expect(r.width, closeTo(90 * CombatConstants.enemyHitWidthFraction, 0.01));
    expect(r.height, closeTo(108 * CombatConstants.enemyHitHeightFraction, 0.01));
    expect(r.center.dx, closeTo(soldier.position.x + 45, 0.01));
    expect(r.center.dy, closeTo(soldier.position.y + 54, 0.01));
    final box = soldier.children.whereType<ShapeHitbox>().first;
    expect(box.size.x, closeTo(r.width, 0.01));
    expect(box.size.y, closeTo(r.height, 0.01));
  });

  testWidgets('hitRect moves with the enemy', (tester) async {
    final (_, tank) = await _mount(tester, 'tank');
    final before = tank.hitRect;
    tank.position.x += 100;
    expect(tank.hitRect.left, closeTo(before.left + 100, 0.01));
  });

  testWidgets('the walking cycle uses the three pictures of the new art', (tester) async {
    final (_, enemy) = await _mount(tester, 'spanish_soldier');
    expect(enemy.animation!.frames.length, 3);
  });

  testWidgets('the hurt picture shows during a Heavy\'s first-hit flinch, then goes',
      (tester) async {
    final (_, tank) = await _mount(tester, 'tank');
    expect(tank.shownPicture, 'walk');
    tank.takeHit(); // 2 HP: the first hit leaves it alive
    expect(tank.defeated, false);
    expect(tank.shownPicture, 'hurt');
    tank.update(0.2);
    expect(tank.shownPicture, 'walk');
  });

  testWidgets('the hurt picture also shows while a defeated enemy is thrown away',
      (tester) async {
    final (_, soldier) = await _mount(tester, 'spanish_soldier');
    soldier.takeHit(); // 1 HP
    expect(soldier.defeated, true);
    expect(soldier.shownPicture, 'hurt');
  });

  testWidgets('the attack picture shows during a Heavy\'s wind-up', (tester) async {
    final (game, tank) = await _mount(tester, 'tank');
    game.player.position.x = tank.position.x - 60;
    tank.update(1 / 60);
    expect(tank.isWindingUp, true);
    expect(tank.shownPicture, 'attack');
  });
}
