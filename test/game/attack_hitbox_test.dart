// Attack hitbox (GAMEPLAY-V2.md Section 3: "a short forward hitbox in the
// facing direction, ~0.25s, with a cooldown so it can't be spammed").
// Covers the charge-cost/cooldown gating on PlayerComponent.attack() and
// AttackHitboxComponent's own lifetime and enemy-hit wiring.
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/attack_hitbox_component.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_input.dart';

ChronoGame _bareGameWithPlayer({bool facingRight = true}) {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.images.prefix = 'assets/';
  final player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(96, 120)
    ..position = Vector2(400, game.groundY - 120)
    ..facingRight = facingRight;
  player.game = game;
  game.player = player;
  game.world.add(player);

  // A bare, never-mounted joystick — PlayerComponent.update() reads
  // game.gameInput.joystick.relativeDelta.x every frame, and this test
  // drives update() directly (to advance the attack cooldown) without
  // running the real onLoad() pipeline that would otherwise set this up.
  final input = GameInput(game: game);
  input.joystick = JoystickComponent(background: CircleComponent(radius: 10));
  game.gameInput = input;

  return game;
}

int _hitboxCount(ChronoGame game) =>
    game.world.children.whereType<AttackHitboxComponent>().length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerComponent.attack()', () {
    test('spends one charge and spawns a hitbox when charges are available',
        () async {
      final game = _bareGameWithPlayer();
      game.kaalaman = 3;
      await game.ready();

      game.player.attack();
      await game.ready();

      expect(game.kaalaman, 3 - CombatConstants.attackChargeCost);
      expect(_hitboxCount(game), 1);
    });

    test('spends nothing and spawns nothing with zero charges', () async {
      final game = _bareGameWithPlayer();
      game.kaalaman = 0;
      await game.ready();

      game.player.attack();
      await game.ready();

      expect(game.kaalaman, 0);
      expect(_hitboxCount(game), 0);
    });

    test('a second swing inside the cooldown spends nothing and spawns nothing',
        () async {
      final game = _bareGameWithPlayer();
      game.kaalaman = CombatConstants.kaalamanCap;
      await game.ready();

      game.player.attack();
      await game.ready();
      expect(_hitboxCount(game), 1);
      final chargesAfterFirst = game.kaalaman;

      game.player.attack();
      await game.ready();

      expect(_hitboxCount(game), 1,
          reason: 'a swing inside the cooldown must not spawn a second hitbox');
      expect(game.kaalaman, chargesAfterFirst,
          reason: 'a swing inside the cooldown must not spend a charge');
    });

    test('a swing after the cooldown elapses spawns a second hitbox',
        () async {
      final game = _bareGameWithPlayer();
      game.kaalaman = CombatConstants.kaalamanCap;
      await game.ready();

      game.player.attack();
      await game.ready();

      game.player.update(CombatConstants.attackCooldown + 0.01);
      game.player.attack();
      await game.ready();

      expect(_hitboxCount(game), 2);
    });

    test('spawns in front of the player when facing right', () async {
      final game = _bareGameWithPlayer(facingRight: true);
      game.kaalaman = 1;
      await game.ready();

      game.player.attack();
      await game.ready();

      final hitbox = game.world.children.whereType<AttackHitboxComponent>().first;
      expect(hitbox.position.x, game.player.position.x + game.player.size.x);
    });

    test('spawns behind (to the left of) the player when facing left',
        () async {
      final game = _bareGameWithPlayer(facingRight: false);
      game.kaalaman = 1;
      await game.ready();

      game.player.attack();
      await game.ready();

      final hitbox = game.world.children.whereType<AttackHitboxComponent>().first;
      expect(
        hitbox.position.x,
        game.player.position.x - CombatConstants.attackHitboxWidth,
      );
    });
  });

  group('AttackHitboxComponent', () {
    test('removes itself after attackHitboxDuration elapses', () async {
      final game = _bareGameWithPlayer();
      final hitbox = AttackHitboxComponent(
        position: Vector2(100, 100),
        size: Vector2(
          CombatConstants.attackHitboxWidth,
          CombatConstants.attackHitboxHeight,
        ),
      );
      game.world.add(hitbox);
      await game.ready();

      hitbox.update(CombatConstants.attackHitboxDuration + 0.01);
      await game.ready();

      expect(hitbox.parent, isNull);
    });

    test('calls takeHit on an enemy it collides with', () async {
      final game = _bareGameWithPlayer();
      final enemy = EnemyComponent(eraId: 'spanish', enemyTypeOverride: 'spanish_soldier');
      game.world.add(enemy);
      await game.ready();

      final hitbox = AttackHitboxComponent(
        position: enemy.position.clone(),
        size: enemy.size.clone(),
      );
      game.world.add(hitbox);
      await game.ready();

      hitbox.onCollisionStart({}, enemy);

      expect(enemy.defeated, true);
    });

    test('does not double-hit the same enemy across multiple collision frames',
        () async {
      final game = _bareGameWithPlayer();
      final enemy =
          EnemyComponent(eraId: 'ww2', enemyTypeOverride: 'tank'); // 2 HP
      game.world.add(enemy);
      await game.ready();

      final hitbox = AttackHitboxComponent(
        position: enemy.position.clone(),
        size: enemy.size.clone(),
      );
      game.world.add(hitbox);
      await game.ready();

      hitbox.onCollisionStart({}, enemy);
      hitbox.onCollisionStart({}, enemy);
      hitbox.onCollisionStart({}, enemy);

      expect(enemy.defeated, false,
          reason: 'one swing must count as at most one hit per enemy, '
              'even across several collision-detection frames');
    });
  });
}
