// Platforms, enemies and coins used to render at their native art size
// while only the player (96x120) and boss (120x140) were deliberately
// upscaled, so the world read as miniature next to the character standing
// in it. These lock in the corrected scale and — since scaling a sprite
// also moves the collision geometry derived from it — check each
// component's hitbox still matches the sprite it is drawn as.
//
// These mount a real GameWidget rather than using a bare ChronoGame: sizes
// and hitboxes are set in onLoad(), which only runs once the component is
// actually attached to a running game.
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/game_spawning.dart';
import 'package:chronoquest/game/components/coin_component.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/enemy_spawner.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/components/tile_platform_component.dart';

const double _playerHeight = 120;
const double _playerWidth = 96;

/// ChronoGame minus the parts these tests have no use for: audio, and
/// mounting the player (whose own art would have to load first). The
/// spawners are still set up because update() drives them every frame.
/// The player is assigned but never added — nothing here renders it, and
/// the camera only reads its position.
class _ScaleGame extends ChronoGame {
  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    camera.viewfinder.anchor = Anchor.topLeft;
    player = PlayerComponent(characterId: 'rizal')
      ..size = Vector2(_playerWidth, _playerHeight)
      ..position = Vector2(0, groundY - _playerHeight);
    setupSpawning();
  }
}

Vector2 _hitboxSize(PositionComponent component) =>
    component.children.whereType<ShapeHitbox>().first.size;

/// Mounts [component] in a running game and waits for its async onLoad
/// (sprite decoding) and its hitbox child to finish mounting.
Future<_ScaleGame> _mount(WidgetTester tester, Component component) async {
  final game = _ScaleGame();
  await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));

  game.world.add(component);
  // Sprite loading is real file I/O, which does not progress inside the
  // test binding's fake async zone — so real time (runAsync) has to be
  // alternated with pumps, which are what actually tick the game loop and
  // mount the component and its hitbox.
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
  return game;
}

void main() {
  testWidgets('enemies read at the same scale as the player, hitbox included',
      (tester) async {
    final enemy = EnemyComponent(eraId: 'spanish');
    await _mount(tester, enemy);

    expect(enemy.size.y, greaterThan(_playerHeight * 0.7),
        reason: 'an enemy dwarfed by the player does not read as a threat');
    expect(enemy.size.y, lessThan(_playerHeight),
        reason: 'the player should still read as the hero');
    // Deliberately smaller than the sprite box since 2026-10-03: the art has
    // transparent margins, and a full-size hitbox hurt the player from a
    // visible gap away. It still has to track the sprite's scale, just inset
    // to the drawn figure.
    final hitbox = _hitboxSize(enemy);
    expect(hitbox.x, lessThan(enemy.size.x),
        reason: 'a full-width hit area causes phantom hits');
    expect(hitbox.x, greaterThan(enemy.size.x * 0.4),
        reason: 'too narrow and the student cannot land a hit either');
    expect(hitbox.y, greaterThan(enemy.size.y * 0.7),
        reason: 'the enemy must still be hittable at most heights');
  });

  testWidgets('coins scale with the world and sit above the ground line',
      (tester) async {
    final coin = CoinComponent();
    final game = await _mount(tester, coin);

    expect(coin.size.y, greaterThan(_playerHeight * 0.25));
    expect(_hitboxSize(coin).y, coin.size.y);
    expect(coin.position.y + coin.size.y, lessThanOrEqualTo(game.groundY),
        reason: 'a coin hanging through the ground cannot be collected '
            'cleanly — height has to be measured from its own bottom edge');
  });

  testWidgets('platform size and hitbox both follow the drawn tile size',
      (tester) async {
    const widthInTiles = 3;
    final platform = TilePlatformComponent(
      widthInTiles: widthInTiles,
      surfaceY: 200,
      spawnPosition: Vector2(200, 200),
    );
    await _mount(tester, platform);

    expect(
      platform.size,
      Vector2(widthInTiles * TilePlatformComponent.tileSize,
          TilePlatformComponent.thickness),
    );
    expect(_hitboxSize(platform), platform.size);
  });

  test('the lowest platform still has visible air underneath it', () {
    // A platform hangs entirely below its surface, so thickness eats the
    // gap to the ground. Drawing the underside as a full second tile made
    // the lowest platforms 48 thick, leaving 12 units of clearance — they
    // read as blocks resting on the floor that you walk into sideways
    // instead of ledges you jump onto.
    const lowestSurfaceAboveGround = EnemySpawner.platformMinHeight;
    const clearance =
        lowestSurfaceAboveGround - TilePlatformComponent.thickness;

    expect(clearance, greaterThanOrEqualTo(_playerHeight / 5),
        reason: 'the gap under the lowest platform has to stay readable');
  });

  testWidgets('a platform surface stays exactly where it was spawned',
      (tester) async {
    // Thickness grows downward from surfaceY, so scaling tiles up must not
    // move the plane the player actually lands on — jump height is tuned
    // against it, and PlayerGroundCollision snaps to surfaceY, not to the
    // component's bottom edge.
    const surfaceY = 200.0;
    final platform = TilePlatformComponent(
      widthInTiles: 4,
      surfaceY: surfaceY,
      spawnPosition: Vector2(200, surfaceY),
    );
    await _mount(tester, platform);

    expect(platform.surfaceY, surfaceY);
    expect(platform.position.y, surfaceY);
  });

  test('platform tiles are drawn larger than the sheet they are cut from', () {
    expect(TilePlatformComponent.tileSize,
        greaterThan(TilePlatformComponent.sourceTileSize));
  });
}
