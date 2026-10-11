// The six boss arenas: what is in each map, and one mounted in a real game.
// That every platform and minion spot can be reached, and that nothing is a trap,
// is checked by the generator (tools/levelgen/arenas.js, with a node test).
import 'dart:io';

import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/boss_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_input.dart';
import 'package:chronoquest/game/game_spawning.dart';
import 'package:chronoquest/game/level_loader.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

LoadedLevel _load(int era, int level) => LevelLoader.parse(
      File('assets/tiles/levels/era${era}_$level.tmx').readAsStringSync(),
    );

class _ArenaGame extends ChronoGame {
  _ArenaGame(String era, int level) {
    currentEra = era;
    currentLevel = level;
  }

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    if (audioService.soundEnabled) audioService.toggleSound(); // no audio plugin in tests
    camera.viewfinder.anchor = Anchor.topLeft;
    player = PlayerComponent(characterId: 'rizal')
      ..size = Vector2(96, 120)
      ..position = Vector2(0, groundY - 120);
    world.add(player);
    gameInput = GameInput(game: this);
    gameInput.setup();
    await setupSpawning();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('every boss level has an arena map', () {
    for (var e = 1; e <= allEras.length; e++) {
      final era = allEras[e - 1];
      final bossLevel = era.levels.length;

      test('${era.name}: level $bossLevel', () {
        final level = _load(e, bossLevel);
        expect(level.isArena, isTrue);
        expect(level.mapWidth, 1824, reason: 'wider than the widest screen the game allows (1800)');

        // Two walls close the room, and it is the same on both sides.
        final blocks = level.blocks;
        expect(blocks.first.heightInTiles(24), 7);
        expect(blocks.last.heightInTiles(24), 7);
        expect(level.boss!.x, level.mapWidth / 2);

        // The student starts on ground, the boss and every minion stand on it.
        expect(level.blockAt(level.spawnX + 48), isNotNull);
        expect(level.blockAt(level.boss!.x), isNotNull);
        expect(level.blockAt(level.boss!.x)!.topY, level.boss!.y);
        expect(level.minionSpawns.length, greaterThanOrEqualTo(4));
        for (final m in level.minionSpawns) {
          expect(level.blockAt(m.x)?.topY, m.y, reason: 'a minion at ${m.x} is not on ground');
        }
        // The two halves mirror each other.
        for (final m in level.minionSpawns) {
          expect(level.minionSpawns.any((o) => (o.x - (level.mapWidth - m.x)).abs() < 0.5), isTrue);
        }

        // No gate, no exit to run to, no artifacts: the fight is the level.
        expect(level.entities.where((x) => x.type == 'gate' || x.type == 'artifact'), isEmpty);
        // At least two ledges high enough to be out of a minion's reach (100).
        final safe = level.entities.where((x) => x.type == 'platform' && x.y <= 660 - 100);
        expect(safe.length, greaterThanOrEqualTo(2));
      });
    }
  });

  testWidgets('a boss arena runs in the real game: the fight starts by itself', (tester) async {
    // Pag-usbong ng Nasyonalismo: the student starts on the high terrace.
    final game = _ArenaGame('nationalism', 7);
    await tester.pumpWidget(MaterialApp(
      home: GameWidget(
        game: game,
        overlayBuilderMap: {
          'HudOverlay': (_, __) => const SizedBox.shrink(),
          'QuestionOverlay': (_, __) => const SizedBox.shrink(),
          'BossHealthOverlay': (_, __) => const SizedBox.shrink(),
        },
      ),
    ));
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 16));
    }

    final level = game.tiledLevel;
    expect(level, isNotNull, reason: 'the arena map loaded');
    expect(level!.isArena, isTrue);

    // On the terrace, 48 up, not sunk into it.
    expect(game.player.position.y + game.player.size.y, 660 - 48);

    // The fight began without the student reaching an exit.
    expect(game.bossPhase, isTrue);
    expect(game.boss, isNotNull);
    expect(game.world.children.whereType<BossComponent>(), hasLength(1));
    expect(game.boss!.position.x + 60, level.boss!.x);
    // And with charges to fight the first wave, since there were no artifacts on the way.
    expect(game.kaalaman, CombatConstants.bossStartCharges);

    // There is a floor to stand on all round the room (a sample of columns).
    for (final x in [100.0, 600.0, 912.0, 1300.0, 1700.0]) {
      expect(level.blockAt(x), isNotNull, reason: 'no ground at $x');
    }
    await tester.pump(const Duration(seconds: 3));
  });
}
