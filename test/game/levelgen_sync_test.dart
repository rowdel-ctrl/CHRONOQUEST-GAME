// The level generator (tools/levelgen, Node) cannot import the game's Dart
// constants, so it keeps its own copy in data/physics.json and data/eras.json.
// This test pins the copy to the game: change a jump value or an era and this
// fails, instead of the generator quietly producing levels for the old numbers.
import 'dart:convert';
import 'dart:io';

import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/enemy_behavior.dart';
import 'package:chronoquest/game/components/tile_platform_component.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  test('physics.json matches the game', () {
    final p = _json('tools/levelgen/data/physics.json');

    expect(p['forwardSpeed'], PlayerComponent.forwardSpeed);
    expect(p['gravity'], PlayerComponent.gravity);
    expect(p['jumpForce'], PlayerComponent.jumpForce);
    expect(p['lengthUnits'], CombatConstants.lengthUnitsDefault);
    expect(p['artifactsPerLevel'], CombatConstants.artifactsPerLevel);
    expect(p['artifactSize'], CombatConstants.artifactSize);
    expect(p['enemyHeight'], EnemyComponent.spriteHeight,
        reason: 'platform heights are set against how high an enemy reaches');
    expect(p['gateWidth'], CombatConstants.gateWidth);
    expect(p['platformTile'], TilePlatformComponent.tileSize);
    expect(p['playerX'], GameConstants.playerX);
  });

  test('the protected jump numbers have not moved', () {
    // GAMEPLAY-V2.md: gravity 900 and jumpForce -480 are verified and must
    // not change without re-tuning every gap and platform in every level.
    expect(PlayerComponent.gravity, 900);
    expect(PlayerComponent.jumpForce, -480);
    const airtime = 2 * 480 / 900;
    // 250 u/s since 2026-10-06 (it was 210, reach 224); the jump is unchanged.
    expect(PlayerComponent.forwardSpeed * airtime, closeTo(266.7, 0.5));
  });

  test('eras.json matches the era registry', () {
    final eras = (jsonDecode(File('tools/levelgen/data/eras.json').readAsStringSync())
            as List)
        .cast<Map<String, dynamic>>();

    expect(eras.length, allEras.length);
    for (var i = 0; i < allEras.length; i++) {
      final want = allEras[i];
      final got = eras[i];
      expect(got['id'], want.id, reason: 'era ${i + 1}');
      expect(got['grade'], want.grade, reason: want.id);
      expect(got['term'], want.term, reason: want.id);
      expect(got['enemyTypes'], want.enemyTypes, reason: want.id);
      expect(
        got['heavy'],
        want.enemyTypes
            .where((k) => enemyTypeTable[k]?.behavior == EnemyBehavior.heavy)
            .toList(),
        reason: '${want.id} heavy kinds',
      );
      expect(
        (got['levelWeeks'] as List).map((w) => (w as List).cast<int>()).toList(),
        want.levelWeeks,
        reason: '${want.id} levelWeeks',
      );
    }
  });
}
