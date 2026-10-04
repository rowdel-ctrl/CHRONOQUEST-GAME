// Contact damage (GAMEPLAY-V2.md Section 5): "-1 HP, knockback away from
// the enemy, and ~1s of invincibility frames (flashing sprite) so you don't
// get chain-hit."
//
// Bare-game pattern (this codebase's default for pure update()/state-machine
// logic) with the collision callbacks called directly rather than going
// through Flame's broad phase — the same approach player_movement_test.dart
// uses for ground contact.
//
// Enemy contact is driven through `onCollision` (every frame of an overlap),
// not `onCollisionStart` (once per new overlap). The 2026-10-03 playtest
// found that start-only damage made standing inside an enemy free and made
// whether a touch hurt depend on whether the player had separated first.
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/gate_component.dart';
import 'package:chronoquest/game/components/tile_platform_component.dart';
import 'package:chronoquest/game/game_input.dart';

/// A blank single-frame animation — contact damage routes through
/// `loseLife()` -> `triggerHurt()`, which swaps `animation` to `hurtAnim`,
/// and those fields are only assigned by the real onLoad(). Same stub
/// approach player_reactions_test.dart uses for the same reason.
Future<SpriteAnimation> _blankAnim() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 1, 1));
  final image = await recorder.endRecording().toImage(1, 1);
  return SpriteAnimation.spriteList([Sprite(image)], stepTime: 1.0);
}

Future<ChronoGame> _bareGameWithPlayer({double playerWorldX = 400}) async {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.images.prefix = 'assets/';
  final player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(96, 120)
    ..position = Vector2(playerWorldX, game.groundY - 120)
    ..walkAnimation = await _blankAnim()
    ..jumpAnim = await _blankAnim()
    ..hurtAnim = await _blankAnim();
  player.animation = player.walkAnimation;
  player.game = game;
  game.player = player;

  final input = GameInput(game: game);
  input.joystick = JoystickComponent(background: CircleComponent(radius: 10));
  game.gameInput = input;

  return game;
}

/// An enemy positioned at [x] without running onLoad() — these tests only
/// need it as a collision partner with a known position, and the contact
/// damage decision lives entirely on the player's side (EnemyComponent
/// never reacts to touching the player).
EnemyComponent _enemyAt(ChronoGame game, double x) {
  final enemy = EnemyComponent(eraId: 'spanish', enemyTypeOverride: 'spanish_soldier')
    ..size = Vector2(90, 108)
    ..position = Vector2(x, game.groundY - 108);
  enemy.game = game;
  return enemy;
}

/// Drives the player past `CombatConstants.invincibilityDuration`, keeping
/// them pinned on the ground each frame.
///
/// There is no GroundSection in this bare game, so gravity would otherwise
/// pull the player below the viewport within about a second and trip
/// `update()`'s fall-in-gap check — which costs a heart of its own and
/// silently corrupts the heart arithmetic these tests assert on.
/// Must wait real time, not just pump frames: invincibility is a wall-clock
/// deadline now, precisely so a paused question cannot bank it.
Future<void> _advancePastInvincibility(ChronoGame game) async {
  final groundedY = game.groundY - game.player.size.y;
  final deadline = DateTime.now().add(
    Duration(
      milliseconds:
          (CombatConstants.invincibilityDuration * 1000).round() + 120,
    ),
  );
  while (DateTime.now().isBefore(deadline)) {
    game.player.update(1 / 60);
    game.player.position.y = groundedY;
    game.player.velocityY = 0;
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('enemy contact', () {
    test('costs exactly one heart', () async {
      final game = await _bareGameWithPlayer();
      final startingHearts = game.hearts;
      final enemy = _enemyAt(game, 500);

      game.player.onCollision({}, enemy);

      expect(game.hearts, startingHearts - 1);
    });

    test('starts the invincibility window', () async {
      final game = await _bareGameWithPlayer();
      final enemy = _enemyAt(game, 500);

      expect(game.player.invincible, false);
      game.player.onCollision({}, enemy);

      expect(game.player.invincible, true);
    });

    test('knocks the player away from an enemy on their right', () async {
      final game = await _bareGameWithPlayer(playerWorldX: 400);
      final enemy = _enemyAt(game, 500); // to the player's right
      final startX = game.player.position.x;

      game.player.onCollision({}, enemy);
      game.player.update(1 / 60);

      expect(game.player.position.x, lessThan(startX),
          reason: 'knockback should push away from the enemy, i.e. left');
    });

    test('knocks the player away from an enemy on their left', () async {
      final game = await _bareGameWithPlayer(playerWorldX: 400);
      final enemy = _enemyAt(game, 300); // to the player's left
      final startX = game.player.position.x;

      game.player.onCollision({}, enemy);
      game.player.update(1 / 60);

      expect(game.player.position.x, greaterThan(startX),
          reason: 'knockback should push away from the enemy, i.e. right');
    });

    test('a defeated enemy deals no contact damage', () async {
      final game = await _bareGameWithPlayer();
      final startingHearts = game.hearts;
      final enemy = _enemyAt(game, 500);
      // Set directly rather than via takeHit(): HP is resolved in onLoad(),
      // which _enemyAt deliberately skips, and what's under test here is the
      // player's guard against an already-defeated enemy, not how it got
      // that way (that's enemy_behavior_test.dart's job).
      enemy.defeated = true;

      game.player.onCollision({}, enemy);

      expect(game.hearts, startingHearts,
          reason: 'a fading, already-defeated enemy must not still hurt');
    });
  });

  group('invincibility window', () {
    test('a second enemy hit inside the window costs nothing', () async {
      final game = await _bareGameWithPlayer();
      final enemy = _enemyAt(game, 500);

      game.player.onCollision({}, enemy);
      final heartsAfterFirst = game.hearts;

      // Well inside CombatConstants.invincibilityDuration.
      game.player.update(0.1);
      game.player.onCollision({}, _enemyAt(game, 500));

      expect(game.hearts, heartsAfterFirst,
          reason: 'chain-hits inside the i-frame window must be ignored');
    });

    test('touching a gate costs no HP at all', () async {
      // Phase 3 replaced WallComponent (which dealt contact damage) with
      // GateComponent, which blocks instead. A gate that also hurt would
      // punish the student for reaching the thing they're meant to answer.
      final game = await _bareGameWithPlayer();
      final startingHearts = game.hearts;

      final gate = GateComponent(worldX: 500)
        ..size = Vector2(48, 260)
        ..position = Vector2(500, game.groundY - 260);
      gate.game = game;

      game.player.onCollisionStart({}, gate);

      expect(game.hearts, startingHearts,
          reason: 'gates block passage; they are not a hazard');
    });

    test('expires after invincibilityDuration, allowing damage again', () async {
      final game = await _bareGameWithPlayer();
      game.player.onCollision({}, _enemyAt(game, 500));
      final heartsAfterFirst = game.hearts;

      await _advancePastInvincibility(game);
      expect(game.player.invincible, false);

      game.player.onCollision({}, _enemyAt(game, 500));

      expect(game.hearts, heartsAfterFirst - 1,
          reason: 'damage must work again once the window has expired');
    });

    test('standing inside an enemy damages again once the window expires',
        () async {
      // The playtest bug: damage fired only on `onCollisionStart`, so a
      // student who stayed inside an enemy was never hit again — the overlap
      // never "began" a second time. Holding still must not be safer than
      // moving.
      final game = await _bareGameWithPlayer();
      final enemy = _enemyAt(game, 500);

      game.player.onCollision({}, enemy);
      final afterFirst = game.hearts;

      // Never leaves the overlap; just waits inside it.
      final groundedY = game.groundY - game.player.size.y;
      final deadline = DateTime.now().add(Duration(
          milliseconds:
              (CombatConstants.invincibilityDuration * 1000).round() + 120));
      while (DateTime.now().isBefore(deadline)) {
        game.player.update(1 / 60);
        game.player.position.y = groundedY;
        game.player.velocityY = 0;
        game.player.onCollision({}, enemy);
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }

      expect(game.hearts, lessThan(afterFirst),
          reason: 'standing inside an enemy must eventually hurt again');
    });

    test('a paused question cannot bank invincibility', () async {
      // The other half of the playtest report. The i-frame timer used to
      // count down in update(), which pauseEngine() stops for the whole time
      // a question is open — so a student who answered for 20s came back
      // still invincible. Wall-clock time cannot be banked, so simulating a
      // pause (no update() calls at all) must still let it expire.
      final game = await _bareGameWithPlayer();
      game.player.onCollision({}, _enemyAt(game, 500));
      expect(game.player.invincible, true);

      // Not a single update() call — exactly what a paused engine does.
      await Future<void>.delayed(
        Duration(
          milliseconds:
              (CombatConstants.invincibilityDuration * 1000).round() + 120,
        ),
      );

      expect(game.player.invincible, false,
          reason: 'invincibility must expire on real time, not frame time');
    });

    test('leaves the sprite visible once the window ends', () async {
      final game = await _bareGameWithPlayer();
      game.player.onCollision({}, _enemyAt(game, 500));

      await _advancePastInvincibility(game);

      expect(game.player.invincible, false);
      // The flash toggles during the window; whatever phase it ended on, it
      // must never leave the player permanently invisible.
      expect(game.player.isFlashVisible, true);
    });
  });

  group('knockback', () {
    /// Runs the player's own update() for [seconds] at 60 fps.
    void run(ChronoGame game, double seconds) {
      for (var i = 0; i < (seconds * 60).round(); i++) {
        game.player.update(1 / 60);
      }
    }

    test('the numbers rule out walking back through the enemy', () {
      // After the stun, the invincibility that is left covers this much walking.
      const walkable = (CombatConstants.invincibilityDuration -
              CombatConstants.knockbackDuration) *
          PlayerComponent.forwardSpeed;
      // Getting back through the enemy: the shove, plus its hit area (0.55 of
      // 90 wide) and the player's own width.
      const crossing = CombatConstants.knockbackDistance + 0.55 * 90 + 96;
      expect(walkable, lessThan(crossing),
          reason: 'the student could pass through the enemy before the '
              'invincibility ends');
    });

    test('a hit shoves the player back by the knockback distance', () async {
      final game = await _bareGameWithPlayer(playerWorldX: 400);
      final enemy = _enemyAt(game, 500);
      final start = game.player.position.x;

      game.player.onCollision({}, enemy);
      run(game, CombatConstants.knockbackDuration + 0.05);

      expect(start - game.player.position.x,
          closeTo(CombatConstants.knockbackDistance, 12),
          reason: 'pushed left, away from the enemy on the right');
    });

    test('the player cannot steer back into the enemy during the shove',
        () async {
      final game = await _bareGameWithPlayer(playerWorldX: 400);
      final enemy = _enemyAt(game, 500);
      final start = game.player.position.x;

      game.player.onCollision({}, enemy);
      game.gameInput.joystick.delta.setValues(10, 0); // full right, at the enemy
      run(game, CombatConstants.knockbackDuration);

      expect(game.player.position.x, lessThan(start - 100),
          reason: 'holding toward the enemy must not cancel the shove');
    });

    test('steering works again once the shove is over', () async {
      final game = await _bareGameWithPlayer(playerWorldX: 400);
      final enemy = _enemyAt(game, 500);

      game.player.onCollision({}, enemy);
      run(game, CombatConstants.knockbackDuration + 0.1);
      final afterShove = game.player.position.x;
      game.gameInput.joystick.delta.setValues(10, 0);
      run(game, 0.2);

      expect(game.player.position.x, greaterThan(afterShove));
    });

    test('a shove stops at the edge of the ground instead of into a gap',
        () async {
      final game = await _bareGameWithPlayer(playerWorldX: 400);
      // Ground starts at 300, so a 160 shove left from 400 would cross the edge.
      final ground = GroundSection(
        sectionWidth: 1700,
        sectionPosition: Vector2(300, game.groundY),
      )..size = Vector2(1700, 60);
      game.groundSections.add(ground);
      game.player.isOnGround = true;
      final enemy = _enemyAt(game, 500);

      game.player.onCollision({}, enemy);
      run(game, CombatConstants.knockbackDuration + 0.05);

      // Foot span is the middle 48 of 96, so the sprite's left edge can go to
      // the ground's edge minus 24.
      expect(game.player.position.x, closeTo(300 + 24 - 48, 1));
      expect(game.hearts, lessThan(5), reason: 'it still cost a heart');
    });

    test('a shove stops at the edge of a platform instead of into the gap',
        () async {
      final game = await _bareGameWithPlayer(playerWorldX: 400);
      // A 192-wide platform at 300..492, 108 above the ground, over a gap: there
      // is no ground section at all, so only the platform can hold them up.
      final surface = game.groundY - 108;
      game.platforms.add(
        TilePlatformComponent(
          widthInTiles: 8,
          surfaceY: surface,
          spawnPosition: Vector2(300, surface),
        ),
      );
      game.player.position.y = surface - game.player.size.y;
      game.player.isOnGround = true;
      final enemy = _enemyAt(game, 500);

      game.player.onCollision({}, enemy);
      run(game, CombatConstants.knockbackDuration + 0.05);

      expect(game.player.position.x, closeTo(300 + 24 - 48, 1),
          reason: 'stopped with the foot span on the platform edge');
      expect(game.player.position.y + game.player.size.y, closeTo(surface, 0.01),
          reason: 'still standing on the platform, not dropped into the gap');
    });
  });
}
