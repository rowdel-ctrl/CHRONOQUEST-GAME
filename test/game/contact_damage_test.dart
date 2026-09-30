// Contact damage (GAMEPLAY-V2.md Section 5): "-1 HP, knockback away from
// the enemy, and ~1s of invincibility frames (flashing sprite) so you don't
// get chain-hit."
//
// Bare-game pattern (this codebase's default for pure update()/state-machine
// logic) with onCollisionStart called directly rather than going through
// Flame's broad phase — the same approach player_movement_test.dart uses for
// ground contact.
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/components/gate_component.dart';
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
void _advancePastInvincibility(ChronoGame game) {
  final groundedY = game.groundY - game.player.size.y;
  final frames = (CombatConstants.invincibilityDuration * 60).ceil() + 10;
  for (var i = 0; i < frames; i++) {
    game.player.update(1 / 60);
    game.player.position.y = groundedY;
    game.player.velocityY = 0;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('enemy contact', () {
    test('costs exactly one heart', () async {
      final game = await _bareGameWithPlayer();
      final startingHearts = game.hearts;
      final enemy = _enemyAt(game, 500);

      game.player.onCollisionStart({}, enemy);

      expect(game.hearts, startingHearts - 1);
    });

    test('starts the invincibility window', () async {
      final game = await _bareGameWithPlayer();
      final enemy = _enemyAt(game, 500);

      expect(game.player.invincible, false);
      game.player.onCollisionStart({}, enemy);

      expect(game.player.invincible, true);
    });

    test('knocks the player away from an enemy on their right', () async {
      final game = await _bareGameWithPlayer(playerWorldX: 400);
      final enemy = _enemyAt(game, 500); // to the player's right
      final startX = game.player.position.x;

      game.player.onCollisionStart({}, enemy);
      game.player.update(1 / 60);

      expect(game.player.position.x, lessThan(startX),
          reason: 'knockback should push away from the enemy, i.e. left');
    });

    test('knocks the player away from an enemy on their left', () async {
      final game = await _bareGameWithPlayer(playerWorldX: 400);
      final enemy = _enemyAt(game, 300); // to the player's left
      final startX = game.player.position.x;

      game.player.onCollisionStart({}, enemy);
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

      game.player.onCollisionStart({}, enemy);

      expect(game.hearts, startingHearts,
          reason: 'a fading, already-defeated enemy must not still hurt');
    });
  });

  group('invincibility window', () {
    test('a second enemy hit inside the window costs nothing', () async {
      final game = await _bareGameWithPlayer();
      final enemy = _enemyAt(game, 500);

      game.player.onCollisionStart({}, enemy);
      final heartsAfterFirst = game.hearts;

      // Well inside CombatConstants.invincibilityDuration.
      game.player.update(0.1);
      game.player.onCollisionStart({}, _enemyAt(game, 500));

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
      game.player.onCollisionStart({}, _enemyAt(game, 500));
      final heartsAfterFirst = game.hearts;

      _advancePastInvincibility(game);
      expect(game.player.invincible, false);

      game.player.onCollisionStart({}, _enemyAt(game, 500));

      expect(game.hearts, heartsAfterFirst - 1,
          reason: 'damage must work again once the window has expired');
    });

    test('leaves the sprite visible once the window ends', () async {
      final game = await _bareGameWithPlayer();
      game.player.onCollisionStart({}, _enemyAt(game, 500));

      _advancePastInvincibility(game);

      expect(game.player.invincible, false);
      // The flash toggles during the window; whatever phase it ended on, it
      // must never leave the player permanently invisible.
      expect(game.player.isFlashVisible, true);
    });
  });
}
