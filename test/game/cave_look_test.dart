// The look of the six era caves (the 2026-11 cave upgrade): each era draws its own
// wall, ceiling, floor, props and slabs without error along the whole cave, and
// the cave plays exactly as before (this only checks that drawing never throws and
// that props never stand over a pit).
//
// With CAVE_SHOTS set to a folder it also saves a picture of every era's cave, for
// looking at: node scratchpad comparisons were made with these.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chronoquest/core/cave_constants.dart';
import 'package:chronoquest/game/cave/cave_game.dart';
import 'package:chronoquest/game/cave/cave_layout.dart';
import 'package:chronoquest/game/cave/cave_scenery.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/coin_component.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/pipe_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_input.dart';
import 'package:chronoquest/services/audio_service.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart' show AudioPool;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

const _eras = [
  'pre-colonial',
  'spanish',
  'nationalism',
  'american',
  'ww2',
  'modern'
];

/// A bare level: a long floor and a hero, standing where the pipe would be.
class _Level extends ChronoGame {
  _Level(String era, int level) {
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

Future<CaveGame> _mountCave(WidgetTester tester, String era, int level,
    {GlobalKey? key}) async {
  final lv = _Level(era, level);
  await tester.pumpWidget(MaterialApp(home: GameWidget(game: lv)));
  await tester.pump();
  for (var i = 0; i < 12; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 16));
  }
  final cave = CaveGame(level: lv);
  Widget game() => GameWidget(
        game: cave,
        overlayBuilderMap: {
          'QuestionOverlay': (_, __) => const SizedBox.shrink()
        },
      );
  await tester.pumpWidget(MaterialApp(
    home: key == null ? game() : RepaintBoundary(key: key, child: game()),
  ));
  await tester.pump();
  bool built() =>
      cave.isLoaded &&
      cave.player.isLoaded &&
      cave.world.children.whereType<CoinComponent>().length ==
          cave.layout.coins.length &&
      cave.world.children.whereType<EnemyComponent>().length ==
          cave.layout.enemies.length &&
      cave.exitPipe != null &&
      cave.exitPipe!.isLoaded;
  for (var i = 0; i < 300 && !built(); i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(built(), isTrue);
  return cave;
}

void _moveTo(CaveGame cave, double x) {
  cave.player.position = Vector2(x, cave.groundY - 120);
  for (var i = 0; i < 6; i++) {
    cave.update(1 / 60);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageDir =
      Directory.systemTemp.createTempSync('chronoquest_cave_look_').path;

  setUpAll(() async {
    AudioService().setSoundEnabled(false);
    AudioService().poolFactory =
        (file) => Future<AudioPool>.error(StateError('no sound in a test'));
    Hive.init(storageDir);
    await Hive.openBox('chronoquest');
  });

  group('every era has its own cave look', () {
    test('six different looks, each with its own painters', () {
      final ids = <String>{};
      for (final era in _eras) {
        final look = CaveLook.byEra[era];
        expect(look, isNotNull, reason: era);
        ids.add(look!.id);
      }
      expect(ids.length, 6);
      expect(CaveLook.of('unknown').id, 'spa',
          reason: 'an unknown era falls back');
    });

    test(
        'props only stand on solid floor, never over a pit or in the artifact room',
        () {
      for (final era in _eras) {
        final look = CaveLook.of(era);
        for (var level = 2; level <= 9; level++) {
          final layout = CaveLayout.forLevel(era, level);
          final placed = CaveGround.planProps(layout, look);
          expect(placed.length, greaterThan(3),
              reason: '$era level $level has props');
          for (final p in placed) {
            final half = p.prop.width / 2;
            expect(layout.floorHolds(p.x - half, p.x + half), isTrue,
                reason: '$era level $level: a prop at ${p.x} is over a pit');
            expect(p.x, lessThan(layout.artifactX - 400),
                reason: 'the artifact room stays clear');
            expect(p.x, greaterThan(layout.spawnX + 300),
                reason: 'the start stays clear');
          }
        }
      }
    });
  });

  for (final era in _eras) {
    testWidgets('the $era cave draws along its whole run', (tester) async {
      tester.view.physicalSize = const Size(1560, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final cave = await _mountCave(tester, era, 4);
      expect(cave.camera.backdrop, isA<CaveBackdrop>());
      expect(cave.world.children.whereType<CaveGround>().length, 1);
      expect(cave.world.children.whereType<CaveLights>().length, 1);
      expect(cave.camera.viewport.children.whereType<CaveFront>().length, 1);
      expect(cave.world.children.whereType<CavePlatformComponent>().length,
          cave.layout.platforms.length);

      final xs = <double>[
        CaveConstants.spawnX,
        for (final p in cave.layout.pits) p.x0 - 300,
        for (final p in cave.layout.platforms) p.x - 200,
        CaveConstants.artifactX - 400,
        CaveConstants.exitPipeX - 520,
      ];
      for (final x in xs) {
        _moveTo(cave, x);
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull, reason: '$era at x=$x');
      }
      await tester.pump(const Duration(seconds: 1));
    });
  }

  testWidgets(
      'a cave never changes how it plays: its map is the same as before',
      (tester) async {
    tester.view.physicalSize = const Size(1560, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cave = await _mountCave(tester, 'american', 6);
    final layout = CaveLayout.forLevel('american', 6);
    expect(cave.layout.floor.length, layout.floor.length);
    expect(cave.layout.platforms.length, layout.platforms.length);
    expect(cave.layout.enemies.length, layout.enemies.length);
    expect(cave.layout.coins.length, layout.coins.length);
    expect(cave.world.children.whereType<PipeComponent>().length, 1,
        reason: 'the exit pipe');
    await tester.pump(const Duration(seconds: 1));
  });

  // Not a check: with CAVE_SHOTS set to a folder, saves a picture of each era's cave.
  testWidgets('saves pictures when CAVE_SHOTS is set', (tester) async {
    final dir = Platform.environment['CAVE_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(1560, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    Future<void> save(String name) async {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await boundary.toImage();
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$dir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    for (final era in _eras) {
      final cave = await _mountCave(tester, era, 4, key: key);
      // The run-in: the student has just dropped out of the pipe.
      _moveTo(cave, CaveConstants.spawnX + 200);
      await save('look_${era}_start');
      // Mid cave: standing before the first pit, then before the first slab.
      final pit = cave.layout.pits.first;
      _moveTo(cave, pit.x0 - 260);
      await save('look_${era}_pit');
      if (cave.layout.platforms.isNotEmpty) {
        _moveTo(cave, cave.layout.platforms.first.x - 100);
        await save('look_${era}_slab');
      }
      // The artifact room with the exit pipe.
      _moveTo(cave, CaveConstants.exitPipeX - 560);
      await save('look_${era}_exit');
      await tester.pump(const Duration(seconds: 1));
    }
  });
}
