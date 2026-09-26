import 'dart:ui' as ui;

import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/enemy_spawner.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/components/tile_platform_component.dart';
import 'package:chronoquest/game/game_input.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

/// A single-frame animation, same trick as player_reactions_test.dart's
/// _blankAnim(): PlayerComponent.jump() assigns `animation = jumpAnim`,
/// which is a `late` field never populated outside the real onLoad()
/// pipeline — these tests bypass onLoad() entirely for speed, so it needs a
/// stand-in value, not a real sprite.
Future<SpriteAnimation> _blankAnim() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 1, 1));
  final image = await recorder.endRecording().toImage(1, 1);
  return SpriteAnimation.spriteList([Sprite(image)], stepTime: 1.0);
}

/// A bare, unloaded ChronoGame + PlayerComponent + one platform, same
/// pattern as player_movement_test.dart — the real onLoad() pipeline pulls
/// audio/sprite loading these physics-only assertions don't need.
///
/// The player starts standing on the ground, directly under the platform,
/// so `player.jump()` sends it straight up through the platform's
/// x-span — the actual way a player reaches a platform in-game (an
/// auto-runner's joystick controls only horizontal movement; height only
/// ever comes from a jump arc, never a drop from above).
Future<ChronoGame> _groundedPlayerUnderPlatform(
    {required double platformHeightAboveGround}) async {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));

  final player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(96, 120)
    ..position = Vector2(400, game.groundY - 120)
    ..isOnGround = true
    ..walkAnimation = await _blankAnim()
    ..jumpAnim = await _blankAnim();
  player.game = game;
  game.player = player;

  final input = GameInput(game: game);
  input.joystick = JoystickComponent(background: CircleComponent(radius: 10));
  game.gameInput = input;

  final surfaceY = game.groundY - platformHeightAboveGround;
  final platform = TilePlatformComponent(
    widthInTiles: 6,
    surfaceY: surfaceY,
    // Wide enough, and centered under the player, that horizontal position
    // is never in question — this test is purely about the vertical AABB
    // catching the player's feet before they tunnel through.
    spawnPosition: Vector2(400 - 3 * TilePlatformComponent.tileSize, surfaceY),
  );
  game.platforms.add(platform);

  return game;
}

/// Runs the jump arc to completion and returns the first `position.y` at
/// which the player is caught resting on something (`isOnGround` flips
/// true), or null if it never lands within [maxFrames].
double? _runJumpAndCaptureLandingY(ChronoGame game, double dt, int maxFrames) {
  game.player.jump();
  for (var i = 0; i < maxFrames; i++) {
    game.player.update(dt);
    if (game.player.isOnGround) return game.player.position.y;
  }
  return null;
}

void main() {
  // player.jump() plays a sound through flame_audio, which needs a
  // resolvable platform-channel binding even though it's wrapped in
  // AudioService's own try/catch (the throw happens deep inside audioplayers
  // before that catch, on binding lookup) — same requirement as
  // player_reactions_test.dart.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tile platforms', () {
    test('render behind the player, so the player is never painted over', () {
      final platform = TilePlatformComponent(widthInTiles: 3, surfaceY: 0);
      final player = PlayerComponent(characterId: 'rizal');
      expect(platform.priority, lessThan(player.priority));
    });

    test('spawn no higher than the jump can reach, with room to spare', () {
      // Peak height of a jump: v² / (2g).
      const jumpPeak = PlayerComponent.jumpForce *
          PlayerComponent.jumpForce /
          (2 * PlayerComponent.gravity);
      expect(
        EnemySpawner.platformMaxHeight,
        lessThanOrEqualTo(jumpPeak - 15),
      );
    });

    test('spawn height range is valid', () {
      expect(EnemySpawner.platformMinHeight,
          lessThan(EnemySpawner.platformMaxHeight));
    });
  });

  group('Landing on a platform (not pass-through)', () {
    test('a jump lands the player on the platform surface, not the ground '
        'below, at a normal 60fps frame time', () async {
      final game = await _groundedPlayerUnderPlatform(
        platformHeightAboveGround: EnemySpawner.platformMinHeight,
      );
      final expectedSurfaceY =
          game.groundY - EnemySpawner.platformMinHeight;

      final landedY =
          _runJumpAndCaptureLandingY(game, 1 / 60, 120); // up to 2s

      expect(landedY, isNotNull, reason: 'never registered ground contact');
      // Caught on the platform (a much smaller y, i.e. higher up) rather
      // than having fallen straight through to the real ground.
      expect(landedY, closeTo(expectedSurfaceY - game.player.size.y, 0.5));
    });

    test('still lands on the platform at the tallest documented spawn '
        'height, not just the shortest', () async {
      final game = await _groundedPlayerUnderPlatform(
        platformHeightAboveGround: EnemySpawner.platformMaxHeight,
      );
      final expectedSurfaceY =
          game.groundY - EnemySpawner.platformMaxHeight;

      final landedY = _runJumpAndCaptureLandingY(game, 1 / 60, 120);

      expect(landedY, isNotNull);
      expect(landedY, closeTo(expectedSurfaceY - game.player.size.y, 0.5));
    });

    test('still lands on the platform at a stuttery 30fps frame time — '
        'bigger per-frame fall distance is the actual tunneling risk',
        () async {
      final game = await _groundedPlayerUnderPlatform(
        platformHeightAboveGround: EnemySpawner.platformMinHeight,
      );
      final expectedSurfaceY =
          game.groundY - EnemySpawner.platformMinHeight;

      final landedY = _runJumpAndCaptureLandingY(game, 1 / 30, 60);

      expect(landedY, isNotNull,
          reason: 'tunneled through the platform at a lower frame rate');
      expect(landedY, closeTo(expectedSurfaceY - game.player.size.y, 0.5));
    });

    test('a huge single dt right at jump-off does not break landing — '
        'velocity is still small then, so it does not actually overshoot',
        () async {
      final game = await _groundedPlayerUnderPlatform(
        platformHeightAboveGround: EnemySpawner.platformMinHeight,
      );
      final expectedSurfaceY =
          game.groundY - EnemySpawner.platformMinHeight;
      game.player.jump();
      // A pathological single frame (18x a normal 60fps frame) right as the
      // jump starts. Confirmed by running this: it does NOT overshoot the
      // platform, because velocity is still small this early in the arc —
      // see the next test for the actual worst case.
      game.player.update(0.3);
      var landed = false;
      double? landedY;
      for (var i = 0; i < 120 && !landed; i++) {
        game.player.update(1 / 60);
        landed = game.player.isOnGround;
        if (landed) landedY = game.player.position.y;
      }
      expect(landed, isTrue, reason: 'player never recovered ground contact');
      expect(landedY, closeTo(expectedSurfaceY - game.player.size.y, 0.5));
    });

    test('a hitch at the worst possible instant — already falling fast, '
        'one frame from the platform surface — is a genuine tunneling risk',
        () async {
      final game = await _groundedPlayerUnderPlatform(
        platformHeightAboveGround: EnemySpawner.platformMinHeight,
      );
      final windowTop = game.groundY - EnemySpawner.platformMinHeight;
      game.player.jump();
      // Run normal frames through the whole ascent and most of the descent,
      // stopping just above the platform's 20-unit landing window — the
      // worst moment a hitch could land on, since fall speed (and therefore
      // per-frame distance) is at its highest here in the whole arc.
      //
      // The band has to be a bit wider than one frame of falling (~5 units
      // here) rather than hugging the window: land inside the window and
      // update() snaps the player onto the platform, and the loop would
      // then stop having already landed instead of mid-fall.
      const stopBand = 12.0;
      var guard = 0;
      while (guard++ < 600) {
        final feet = game.player.position.y + game.player.size.y;
        final descending = game.player.velocityY >= 0;
        if (descending && feet >= windowTop - stopBand) break;
        game.player.update(1 / 60);
      }
      // Sanity check on the setup itself, not the finding: confirms the loop
      // above actually stopped mid-descent (falling, not still ascending)
      // right at the edge of the window, as intended.
      expect(game.player.velocityY, greaterThan(0));

      // A single 200ms hitch (a severe but real-world-plausible stall — GC
      // pause, texture upload, thermal throttle — not the cartoonish 300ms
      // above) substituted for the next normal frame, right at this exact
      // worst-case instant.
      game.player.update(0.2);

      // CONFIRMED FINDING (see HANDOFF.md): a hitch this size, landing at
      // this exact moment, genuinely tunnels the player through the
      // platform's 20-unit landing window and down toward the real ground —
      // this is not a false alarm. A normal 60fps frame here (~5.5 units of
      // fall) fits inside the window comfortably; a 200ms frame (~66 units)
      // does not. This is a pre-existing property of the hand-rolled AABB
      // check, unrelated to Phase 1, and is asserted here as a known,
      // understood limitation rather than left as an unverified suspicion.
      expect(
        game.player.position.y + game.player.size.y,
        greaterThan(windowTop + 20),
        reason: 'if this ever fails, the tunneling risk was fixed — update '
            'this test to assert landing instead of deleting it',
      );
    });
  });
}
