// Walkers patrol, but they must never walk out over a gap: a walker that
// reaches the edge of its ground turns around, the way it would at a wall.
// Found on device — an enemy hovered over the first gap in era1_1.
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/components/tile_platform_component.dart';
import 'package:chronoquest/game/game_collision.dart';

/// Two ground spans, 0..1000 and 1200..2200, with a 200px gap between them.
ChronoGame _gameWithGap() {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.images.prefix = 'assets/';
  game.player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(96, 120)
    ..position = Vector2(0, game.groundY - 120);

  for (final (start, width) in [(0.0, 1000.0), (1200.0, 1000.0)]) {
    game.groundSections.add(
      GroundSection(
        sectionWidth: width,
        sectionPosition: Vector2(start, game.groundY),
      )..size = Vector2(width, 60),
    );
  }
  return game;
}

Future<EnemyComponent> _mountWalker(
  ChronoGame game, {
  required double x,
  required double patrol,
  double? surfaceY,
}) async {
  final enemy = EnemyComponent(
    eraId: 'spanish',
    enemyTypeOverride: 'spanish_soldier',
    worldX: x,
    patrolRangeOverride: patrol,
    surfaceY: surfaceY,
  );
  game.world.add(enemy);
  await game.ready();
  // ready() can return before the enemy's sprites finish loading under load,
  // leaving it at x=0 with no size; wait for its own onLoad.
  await enemy.loaded;
  return enemy;
}

bool _footOverGround(ChronoGame game, EnemyComponent enemy) {
  final centre = enemy.position.x + enemy.size.x / 2;
  final half = enemy.size.x * footSpanFraction / 2;
  return game.isGroundUnder(centre - half, centre + half);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ledge awareness', () {
    test('a walker whose patrol would cross the gap turns around instead',
        () async {
      final game = _gameWithGap();
      // Patrol of 300 from x=900 would carry it to 1200, well into the gap.
      final enemy = await _mountWalker(game, x: 900, patrol: 300);

      var turned = false;
      for (var i = 0; i < 60 * 30; i++) {
        enemy.update(1 / 60);
        expect(_footOverGround(game, enemy), isTrue,
            reason: 'frame $i: foot span left the ground at x='
                '${enemy.position.x}');
        if (enemy.patrolDirection < 0) turned = true;
      }
      expect(turned, isTrue, reason: 'it never reached the ledge and turned');
    });

    test('it keeps patrolling back and forth rather than getting stuck',
        () async {
      final game = _gameWithGap();
      final enemy = await _mountWalker(game, x: 900, patrol: 300);

      var minX = enemy.position.x;
      var maxX = enemy.position.x;
      for (var i = 0; i < 60 * 60; i++) {
        enemy.update(1 / 60);
        if (enemy.position.x < minX) minX = enemy.position.x;
        if (enemy.position.x > maxX) maxX = enemy.position.x;
      }

      expect(maxX - minX, greaterThan(100),
          reason: 'it should still pace between the ledge and its far limit');
    });

    test('a walker well inside its ground keeps its full patrol range',
        () async {
      final game = _gameWithGap();
      final enemy = await _mountWalker(game, x: 300, patrol: 150);

      var maxOffset = 0.0;
      for (var i = 0; i < 60 * 20; i++) {
        enemy.update(1 / 60);
        maxOffset = maxOffset < (enemy.position.x - 300).abs()
            ? (enemy.position.x - 300).abs()
            : maxOffset;
      }

      expect(maxOffset, closeTo(150, 1));
    });

    test('with no ground registered at all, patrol is unconstrained',
        () async {
      final game = ChronoGame();
      game.onGameResize(Vector2(800, 450));
      game.images.prefix = 'assets/';
      game.player = PlayerComponent(characterId: 'rizal')
        ..size = Vector2(96, 120);
      final enemy = await _mountWalker(game, x: 500, patrol: 150);

      var maxOffset = 0.0;
      for (var i = 0; i < 60 * 10; i++) {
        enemy.update(1 / 60);
        maxOffset = maxOffset < (enemy.position.x - 500).abs()
            ? (enemy.position.x - 500).abs()
            : maxOffset;
      }

      expect(maxOffset, closeTo(150, 1));
    });

    test('an enemy already over a gap does not flip direction every frame',
        () async {
      final game = _gameWithGap();
      // Centre at 1095, inside the 1000..1200 gap: bad data, not a patrol.
      final enemy = await _mountWalker(game, x: 1050, patrol: 100);

      final directionBefore = enemy.patrolDirection;
      for (var i = 0; i < 10; i++) {
        enemy.update(1 / 60);
      }

      expect(enemy.patrolDirection, directionBefore);
    });
  });

  group('platform enemies', () {
    // A 192-wide platform over the gap (1000..1200), top 108 above the ground.
    ChronoGame gameWithPlatform() {
      final game = _gameWithGap();
      final surface = game.groundY - 108;
      game.platforms.add(
        TilePlatformComponent(
          widthInTiles: 8,
          surfaceY: surface,
          spawnPosition: Vector2(1004, surface),
        ),
      );
      return game;
    }

    test('stands on the platform, not on the ground', () async {
      final game = gameWithPlatform();
      final surface = game.groundY - 108;
      final enemy = await _mountWalker(game, x: 1055, patrol: 36, surfaceY: surface);

      expect(enemy.position.y + enemy.size.y, closeTo(surface, 0.01));
    });

    test('a patrol wider than the platform turns round at its edge', () async {
      final game = gameWithPlatform();
      final surface = game.groundY - 108;
      // Patrol of 300 would carry it off both ends of the 192-wide platform.
      final enemy = await _mountWalker(game, x: 1055, patrol: 300, surfaceY: surface);

      var turns = 0;
      var last = enemy.patrolDirection;
      for (var i = 0; i < 60 * 30; i++) {
        enemy.update(1 / 60);
        final centre = enemy.position.x + enemy.size.x / 2;
        const half = EnemyComponent.spriteWidth * footSpanFraction / 2;
        expect(game.isPlatformUnder(centre - half, centre + half, surface), isTrue,
            reason: 'frame $i: foot span left the platform at x=${enemy.position.x}');
        if (enemy.patrolDirection != last) turns++;
        last = enemy.patrolDirection;
      }
      expect(turns, greaterThanOrEqualTo(2),
          reason: 'it should pace between both edges, not stick at one');
    });

    test('a platform enemy ignores the ground below', () async {
      // The ground spans end at 1000 and restart at 1200, so a ground check would
      // call this enemy unsupported everywhere over the gap.
      final game = gameWithPlatform();
      final surface = game.groundY - 108;
      final enemy = await _mountWalker(game, x: 1055, patrol: 36, surfaceY: surface);
      final start = enemy.position.x;

      for (var i = 0; i < 60 * 5; i++) {
        enemy.update(1 / 60);
      }
      expect(enemy.position.x, isNot(start), reason: 'it patrols');
      expect(enemy.position.x, inInclusiveRange(1055 - 36 - 1, 1055 + 36 + 1));
    });
  });
}
