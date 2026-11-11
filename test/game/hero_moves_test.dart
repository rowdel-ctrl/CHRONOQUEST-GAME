// The 2026-11 hero moves: one Attack button, and the hero decides what it does.
// Juan's boomerang coin, Maria's net, Del Pilar's long shot, Lapu-Lapu's heavy dash,
// Bonifacio's quick dash, Luna's saber wave, Maria Clara's petal gust, Rizal's
// page burst. Plus PlayerComponent.playCounter, the same moves aimed at a boss
// attack (a right answer in the boss fight).
//
// Bare-game pattern: the hero is mounted on a flat ground section and the test
// drives update() by hand (enemies stand still), 1/60 s at a time.
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/core/hero_move_constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/attack_hitbox_component.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/hero_projectile_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_input.dart';

const double _heroX = 400; // the hero's box (96 wide): its middle is at 448
const double _centre = _heroX + 48;
const double _muzzle = _centre + HeroMoveConstants.startAhead; // 498

/// A mounted hero standing on flat ground (every [ground] span is (start, width);
/// by default one long span), facing [facingRight], with [charges] Kaalaman.
Future<ChronoGame> _arena(
  String heroId, {
  bool onGround = true,
  bool facingRight = true,
  int charges = 5,
  List<(double, double)> ground = const [(-500, 4000)],
}) async {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.images.prefix = 'assets/';
  final player = PlayerComponent(characterId: heroId);
  player.game = game;
  game.player = player;
  game.world.add(player);
  final input = GameInput(game: game);
  input.joystick = JoystickComponent(background: CircleComponent(radius: 10));
  game.gameInput = input;
  await game.ready();

  for (final (start, width) in ground) {
    game.groundSections.add(
      GroundSection(
          sectionWidth: width, sectionPosition: Vector2(start, game.groundY))
        ..size = Vector2(width, 60),
    );
  }
  player.size = Vector2(96, 120);
  player.position = Vector2(_heroX, game.groundY - 120);
  player.facingRight = facingRight;
  player.isOnGround = onGround;
  game.kaalaman = charges;
  return game;
}

/// A soldier whose hit area is centred [distance] from the muzzle (right of it when
/// the hero faces right, left of it when not). It stands still.
Future<EnemyComponent> _enemyAt(
  ChronoGame game,
  double distance, {
  String type = 'spanish_soldier',
  bool toTheRight = true,
}) async {
  final e =
      EnemyComponent(eraId: 'spanish', enemyTypeOverride: type, worldX: 0);
  game.world.add(e);
  await game.ready();
  await e.loaded;
  final muzzle = toTheRight ? _muzzle : _centre - HeroMoveConstants.startAhead;
  final want = toTheRight ? muzzle + distance : muzzle - distance;
  e.position.x += want - e.hitRect.center.dx;
  return e;
}

List<HeroProjectileComponent> _shots(ChronoGame game) =>
    game.world.children.whereType<HeroProjectileComponent>().toList();

/// Advances the hero (unless [moveHero] is false) and every flying thing by
/// [seconds], 1/60 s at a time. [each] sees the time after every step.
Future<void> _run(
  ChronoGame game,
  double seconds, {
  bool moveHero = true,
  void Function(double t)? each,
}) async {
  await game.ready();
  final steps = (seconds * 60).round();
  for (var i = 1; i <= steps; i++) {
    if (moveHero) game.player.update(1 / 60);
    for (final p in _shots(game)) {
      p.update(1 / 60);
    }
    await game.ready();
    each?.call(i / 60);
  }
}

const _rangedHeroes = [
  'boy',
  'girl',
  'delpilar',
  'luna',
  'mariaclara',
  'rizal'
];
const _allHeroes = [
  'boy',
  'girl',
  'delpilar',
  'lapu',
  'bonifacio',
  'luna',
  'mariaclara',
  'rizal'
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the numbers', () {
    test('every hero has a move, keyed by its id', () {
      for (final c in allCharacters) {
        expect(heroMoves.containsKey(c.id), isTrue, reason: c.id);
        expect(heroMoveFor(c.id).heroId, c.id);
      }
      expect(heroMoves.length, allCharacters.length);
      expect(heroMoveFor('nobody').heroId, 'boy',
          reason: 'an unknown id still gets a move');
    });

    test('range, speed and cooldown of each hero', () {
      void ranged(
          String id, HeroMoveKind kind, double range, double speed, double cd) {
        final m = heroMoveFor(id);
        expect(m.kind, kind, reason: id);
        expect(m.range, range, reason: id);
        expect(m.speed, speed, reason: id);
        expect(m.cooldown, cd, reason: id);
        expect(m.isRanged, isTrue);
      }

      ranged('boy', HeroMoveKind.boomerang, 200, 420, 0.90);
      ranged('girl', HeroMoveKind.shot, 220, 400, 0.60);
      ranged('delpilar', HeroMoveKind.shot, 320, 700, 0.80);
      ranged('luna', HeroMoveKind.wave, 180, 380, 0.80);
      ranged('mariaclara', HeroMoveKind.wave, 160, 340, 0.70);
      ranged('rizal', HeroMoveKind.burst, 150, 480, 0.90);
      expect(heroMoveFor('girl').groupRadius, 45);
      expect(heroMoveFor('rizal').count, 3);
      expect(heroMoveFor('rizal').gap, 0.09);

      final lapu = heroMoveFor('lapu');
      expect(lapu.isDash, isTrue);
      expect((lapu.dashDistance, lapu.dashSeconds, lapu.cooldown),
          (140.0, 0.22, 0.90));
      final boni = heroMoveFor('bonifacio');
      expect(boni.isDash, isTrue);
      expect((boni.dashDistance, boni.dashSeconds, boni.cooldown),
          (100.0, 0.16, 0.55));
    });

    test(
        'a hero\'s cooldown is its own: a second attack inside it does nothing',
        () async {
      for (final id in _allHeroes) {
        final game = await _arena(id);
        final p = game.player;
        final cd = p.heroMove.cooldown;
        expect(p.attackCooldownLeft, 0);

        p.attack();
        expect(p.attackCooldownLeft, cd,
            reason: '$id: set to its own cooldown');

        p.update(cd - 0.05);
        final left = p.attackCooldownLeft;
        expect(left, closeTo(0.05, 1e-9), reason: id);
        p.attack(); // inside the cooldown: ignored
        expect(p.attackCooldownLeft, left, reason: '$id: not restarted');

        p.update(0.06);
        expect(p.attackCooldownLeft, lessThanOrEqualTo(0), reason: id);
        p.attack();
        expect(p.attackCooldownLeft, cd,
            reason: '$id: free again after the cooldown');
      }
    });

    test('nothing happens with no charge left', () async {
      for (final id in _allHeroes) {
        final game = await _arena(id, charges: 0);
        game.player.attack();
        await game.ready();
        expect(game.player.attackCooldownLeft, 0, reason: id);
        expect(_shots(game), isEmpty, reason: id);
        expect(game.player.moves.dashing, isFalse, reason: id);
      }
    });
  });

  group('how far each ranged move reaches', () {
    test('a thing hits an enemy inside its range and misses one beyond it',
        () async {
      for (final id in _rangedHeroes) {
        final m = heroMoveFor(id);
        // Its hit box reaches 25 (the soldier's half width) + half its own width.
        final reach = m.range + 25 + m.hitWidth / 2;

        final near = await _arena(id);
        final inside = await _enemyAt(near, m.range - 30);
        near.player.attack();
        await _run(near, 2.5);
        expect(inside.defeated, isTrue,
            reason: '$id: an enemy inside its range is hit');

        final far = await _arena(id);
        final outside = await _enemyAt(far, reach + 15);
        far.player.attack();
        await _run(far, 2.5);
        expect(outside.defeated, isFalse,
            reason: '$id: an enemy beyond its range is safe');
        expect(far.kaalaman, 5, reason: '$id: a miss is free');
      }
    });

    test('Del Pilar reaches 320, further than every other ranged hero', () {
      for (final id in _rangedHeroes) {
        expect(heroMoveFor('delpilar').range,
            greaterThanOrEqualTo(heroMoveFor(id).range));
      }
    });

    test(
        'a flying thing flies level at the hero\'s chest and ends at the end of its range',
        () async {
      final game = await _arena('delpilar');
      game.player.attack();
      await game.ready();
      final shot = _shots(game).single;
      final feet = game.player.position.y + game.player.size.y;
      expect(shot.position.y, feet - HeroMoveConstants.shotHeight);
      expect(shot.position.x, _muzzle);

      await _run(game, 0.2, moveHero: false);
      expect(shot.position.y, feet - HeroMoveConstants.shotHeight);
      expect(shot.distanceOut, closeTo(0.2 * 700, 12.0));

      await _run(game, 1.0, moveHero: false);
      expect(shot.finished, isTrue);
      expect(shot.distanceOut, closeTo(320, 0.01));
    });

    test('thrown to the left when the hero faces left', () async {
      final game = await _arena('delpilar', facingRight: false);
      final left = await _enemyAt(game, 120, toTheRight: false);
      final right = await _enemyAt(game, 120);
      game.player.attack();
      await _run(game, 1.0);
      expect(left.defeated, isTrue);
      expect(right.defeated, isFalse);
    });

    test('works in the air: a ranged hero throws from a jump', () async {
      final game = await _arena('girl', onGround: false);
      final enemy = await _enemyAt(game, 100);
      game.player.attack();
      await _run(game, 1.0, moveHero: false);
      expect(enemy.defeated, isTrue);
    });
  });

  group('stop or go through', () {
    test('Del Pilar\'s shot hits one target, the first it meets', () async {
      final game = await _arena('delpilar');
      final a = await _enemyAt(game, 60);
      final b = await _enemyAt(game, 120);
      final c = await _enemyAt(game, 180);
      game.player.attack();
      await _run(game, 1.0);
      expect(a.defeated, isTrue);
      expect(b.defeated, isFalse);
      expect(c.defeated, isFalse);
      expect(game.kaalaman, 4);
    });

    test(
        'Maria\'s net stops at the first enemy but catches those within 45 of it',
        () async {
      final game = await _arena('girl');
      final a = await _enemyAt(game, 100);
      final close = await _enemyAt(game, 140); // 40 from a: caught
      final far = await _enemyAt(game, 160); // 60 from a: not caught
      game.player.attack();
      await _run(game, 1.0);
      expect(a.defeated, isTrue);
      expect(close.defeated, isTrue);
      expect(far.defeated, isFalse);
      expect(game.kaalaman, 4, reason: 'three caught, one charge');
    });

    test('Luna\'s wave goes through every enemy in its path', () async {
      final game = await _arena('luna');
      final soldiers = [
        for (final d in [40.0, 90.0, 140.0]) await _enemyAt(game, d),
      ];
      game.player.attack();
      await game.ready();
      final wave = _shots(game).single;
      await _run(game, 1.0);
      expect(soldiers.every((e) => e.defeated), isTrue);
      expect(wave.hitCount, 3);
      expect(game.kaalaman, 4, reason: 'one swing, one charge');
    });

    test('Maria Clara\'s petals go through every enemy in their path',
        () async {
      final game = await _arena('mariaclara');
      final soldiers = [
        for (final d in [40.0, 90.0, 130.0]) await _enemyAt(game, d),
      ];
      game.player.attack();
      await _run(game, 1.0);
      expect(soldiers.every((e) => e.defeated), isTrue);
      expect(game.kaalaman, 4);
    });

    test('a wave that goes through hits a Heavy once, not once a frame',
        () async {
      final game = await _arena('luna');
      final tank = await _enemyAt(game, 80, type: 'tank'); // 2 HP
      game.player.attack();
      await _run(game, 1.0);
      expect(tank.defeated, isFalse, reason: 'one pass is one hit');
    });

    test('hits are also found by Flame contact, once per enemy', () async {
      final game = await _arena('luna');
      final tank = await _enemyAt(game, 400, type: 'tank');
      final soldier = await _enemyAt(game, 450);
      game.player.attack();
      await game.ready();
      final wave = _shots(game).single;
      wave.onCollisionStart({}, tank);
      wave.onCollisionStart({}, tank);
      wave.onCollisionStart({}, tank);
      expect(tank.defeated, isFalse,
          reason: 'a Heavy has 2 HP: three callbacks are one hit');
      wave.onCollisionStart({}, soldier);
      expect(soldier.defeated, isTrue, reason: 'a wave goes on to the next');
      expect(wave.finished, isFalse);

      final game2 = await _arena('delpilar');
      final a = await _enemyAt(game2, 400);
      final b = await _enemyAt(game2, 450);
      game2.player.attack();
      await game2.ready();
      final shot = _shots(game2).single;
      shot.onCollisionStart({}, a);
      shot.onCollisionStart({}, b);
      expect(a.defeated, isTrue);
      expect(b.defeated, isFalse,
          reason: 'a shot is spent on its first target');
      expect(shot.finished, isTrue);
    });

    test('a slow frame does not let a fast shot skip an enemy', () async {
      final game = await _arena('delpilar');
      final enemy = await _enemyAt(game, 100);
      game.player.attack();
      await game.ready();
      _shots(game).single.update(0.5); // 350 units in one step
      expect(enemy.defeated, isTrue);
    });
  });

  group('Rizal\'s page burst', () {
    test('three pages, one after another 0.09 s apart', () async {
      final game = await _arena('rizal');
      game.player.attack();
      await game.ready();
      expect(_shots(game).length, 1, reason: 'the first page leaves at once');
      expect(game.player.moves.pagesWaiting, 2);

      await _run(game, 0.10); // 0.09 s has passed: the second page is out
      expect(_shots(game).length, 2);
      await _run(game, 0.10); // 0.18 s has passed: the third
      expect(_shots(game).length, 3);
      expect(game.player.moves.pagesWaiting, 0);
    });

    test('each page hits one enemy and costs the swing a single charge',
        () async {
      final game = await _arena('rizal');
      final soldiers = [
        for (final d in [40.0, 90.0, 140.0]) await _enemyAt(game, d),
      ];
      game.player.attack();
      await _run(game, 1.0);
      expect(soldiers.every((e) => e.defeated), isTrue);
      expect(game.kaalaman, 4);
    });

    test('two enemies take two pages, the third flies on', () async {
      final game = await _arena('rizal');
      final a = await _enemyAt(game, 60);
      final b = await _enemyAt(game, 100);
      game.player.attack();
      await game.ready();
      final firstPage = _shots(game).single;
      await _run(game, 0.8);
      expect(firstPage.hitCount, 1);
      expect(a.defeated && b.defeated, isTrue);
    });
  });

  group('Juan\'s boomerang coin', () {
    test('turns back at once at the first enemy it hits', () async {
      final game = await _arena('boy');
      final enemy = await _enemyAt(game, 100);
      final far = await _enemyAt(game, 170);
      game.player.attack();
      await game.ready();
      final coin = _shots(game).single;
      await _run(game, 0.5, moveHero: false);
      expect(enemy.defeated, isTrue);
      expect(coin.returning, isTrue);
      expect(coin.distanceOut, lessThan(150),
          reason: 'it turned at the first enemy, not at 200');
      expect(far.defeated, isFalse, reason: 'it never reached the second');
      expect(game.kaalaman, 4);
    });

    test(
        'turns at the end of its range (200) when it hits nothing, then comes home',
        () async {
      final game = await _arena('boy');
      game.player.attack();
      await game.ready();
      final coin = _shots(game).single;
      var turnedAt = -1.0;
      await _run(game, 2.0, moveHero: false, each: (_) {
        if (coin.returning && turnedAt < 0) turnedAt = coin.distanceOut;
      });
      expect(turnedAt, closeTo(200, 0.01));
      expect(coin.finished, isTrue,
          reason: 'it came back to the hero and was gone');
      expect(game.kaalaman, 5, reason: 'a miss is free');
    });

    test('on the way back it hits an enemy it meets', () async {
      final game = await _arena('boy');
      game.player.attack();
      await game.ready();
      final coin = _shots(game).single;
      await _run(game, 0.6, moveHero: false); // 0.6 s: out to 200 and turned
      expect(coin.returning, isTrue);
      // An enemy walks into its path after it has gone by.
      final late = await _enemyAt(game, 80);
      await _run(game, 1.0, moveHero: false);
      expect(late.defeated, isTrue, reason: 'hit on the return trip');
      expect(coin.hitCount, 1);
      expect(game.kaalaman, 4);
    });

    test('the same enemy is not hit twice by one coin', () async {
      final game = await _arena('boy');
      final tank = await _enemyAt(game, 100, type: 'tank'); // 2 HP
      game.player.attack();
      await game.ready();
      final coin = _shots(game).single;
      await _run(game, 2.0, moveHero: false);
      expect(coin.hitCount, 1);
      expect(tank.defeated, isFalse,
          reason: 'out and back is still one hit on it');
    });

    test('goes through the enemies on its way home', () async {
      final game = await _arena('boy');
      game.player.attack();
      await game.ready();
      final coin = _shots(game).single;
      await _run(game, 0.6, moveHero: false);
      final one = await _enemyAt(game, 60);
      final two = await _enemyAt(game, 120);
      await _run(game, 1.0, moveHero: false);
      expect(one.defeated && two.defeated, isTrue);
      expect(coin.hitCount, 2);
    });
  });

  group('the dash heroes', () {
    test('Lapu dashes 140 forward in 0.22 s and cannot be hurt while he does',
        () async {
      final game = await _arena('lapu');
      final p = game.player;
      final hearts = game.hearts;
      expect(p.invincible, isFalse);

      p.attack();
      expect(p.moves.dashing, isTrue);
      await _run(game, 0.10);
      expect(p.invincible, isTrue, reason: 'safe mid-dash');
      p.takeHazardHit(knockbackDirection: -1);
      expect(game.hearts, hearts, reason: 'a hit does nothing during the dash');

      await _run(game, 0.20);
      expect(p.moves.dashing, isFalse);
      expect(p.position.x, closeTo(_heroX + 140, 0.5));
      expect(p.invincible, isFalse, reason: 'the safe time ends with the dash');
      p.takeHazardHit(knockbackDirection: -1);
      expect(game.hearts, hearts - 1, reason: 'hurt again after it');
    });

    test('Bonifacio dashes 100 in 0.16 s', () async {
      final game = await _arena('bonifacio');
      final p = game.player;
      p.attack();
      await _run(game, 0.08);
      expect(p.invincible, isTrue);
      expect(p.position.x, greaterThan(_heroX + 40));
      expect(p.position.x, lessThan(_heroX + 100));
      await _run(game, 0.12);
      expect(p.moves.dashing, isFalse);
      expect(p.invincible, isFalse);
      expect(p.position.x, closeTo(_heroX + 100, 0.5));
    });

    test('a dash to the left goes left', () async {
      final game = await _arena('lapu', facingRight: false);
      game.player.attack();
      await _run(game, 0.4);
      expect(game.player.position.x, closeTo(_heroX - 140, 0.5));
    });

    test('slices every enemy in the path once, for a single charge', () async {
      final game = await _arena('lapu');
      // Hit areas centred 72, 132 and 192 past the middle of the hero (448 + 72 = 520...).
      final soldiers = [
        for (final d in [22.0, 82.0, 142.0]) await _enemyAt(game, d),
      ];
      final beyond = await _enemyAt(game, 300);
      game.player.attack();
      await _run(game, 0.4);
      expect(soldiers.every((e) => e.defeated), isTrue);
      expect(beyond.defeated, isFalse, reason: 'past the end of the dash');
      expect(game.kaalaman, 4, reason: 'one dash, one charge');
    });

    test('a Heavy in the path takes one hit, not one per frame', () async {
      final game = await _arena('lapu');
      final tank = await _enemyAt(game, 60, type: 'tank'); // 2 HP
      game.player.attack();
      await _run(game, 0.4);
      expect(tank.defeated, isFalse);
    });

    test('a dash that hits nothing is free', () async {
      final game = await _arena('bonifacio');
      game.player.attack();
      await _run(game, 0.4);
      expect(game.kaalaman, 5);
    });

    test('stops at a ledge', () async {
      // Ground ends at 520: the hero's feet (48 wide) can be at most up to there.
      final game = await _arena('lapu', ground: const [(-500, 1020)]);
      final p = game.player;
      p.attack();
      await _run(game, 0.5);
      expect(p.moves.dashing, isFalse);
      final footRight = p.position.x + p.size.x / 2 + p.size.x * 0.5 / 2;
      expect(footRight, lessThanOrEqualTo(520.01));
      expect(p.position.x, greaterThan(_heroX),
          reason: 'it did dash up to the edge');
      expect(p.isOnGround, isTrue, reason: 'and did not fall');
    });

    test('stops at the edge of a pit', () async {
      final game =
          await _arena('bonifacio', ground: const [(-500, 1000), (700, 3000)]);
      final p = game.player;
      p.position.x = 420; // the pit starts at 500; the feet are 444..492
      p.attack();
      await _run(game, 0.5);
      final footRight = p.position.x + p.size.x / 2 + p.size.x * 0.5 / 2;
      expect(footRight, lessThanOrEqualTo(500.01));
      expect(p.isOnGround, isTrue);
    });

    test(
        'with the toes already over the edge, the dash does not go on into the pit',
        () async {
      final game =
          await _arena('bonifacio', ground: const [(-500, 1000), (700, 3000)]);
      final p = game.player;
      p.position.x =
          440; // feet 464..512: standing, but with the toes over the pit
      p.attack();
      await _run(game, 0.5);
      expect(p.moves.dashing, isFalse);
      expect(p.position.x + p.size.x / 2, lessThanOrEqualTo(500.01),
          reason: 'the middle of the hero never goes out over the pit');
      expect(p.isOnGround, isTrue);
    });

    test('stops at a wall', () async {
      // A block of raised ground from 520: a wall, because it rises more than 12.
      final game = await _arena('lapu');
      game.groundSections.add(
        GroundSection(
            sectionWidth: 200, sectionPosition: Vector2(520, game.groundY - 48))
          ..size = Vector2(200, 60),
      );
      final p = game.player;
      p.attack();
      await _run(game, 0.5);
      expect(p.moves.dashing, isFalse);
      final footRight = p.position.x + p.size.x / 2 + p.size.x * 0.5 / 2;
      expect(footRight, lessThanOrEqualTo(520.01), reason: 'not into the wall');
      expect(p.position.x, greaterThan(_heroX));
    });

    test('in the air a dash hero uses the old short swing', () async {
      for (final id in ['lapu', 'bonifacio']) {
        final game = await _arena(id, onGround: false);
        game.player.attack();
        await game.ready();
        expect(game.player.moves.dashing, isFalse, reason: id);
        expect(game.world.children.whereType<AttackHitboxComponent>().length, 1,
            reason: '$id: the 80x90 swing');
        expect(_shots(game), isEmpty, reason: id);
        expect(game.player.attackCooldownLeft, game.player.heroMove.cooldown);
      }
    });

    test('leaving the ground ends the dash', () async {
      final game = await _arena('lapu');
      final p = game.player;
      p.attack();
      await _run(game, 0.05);
      expect(p.moves.dashing, isTrue);
      p.isOnGround = false; // jumped
      p.update(1 / 60);
      expect(p.moves.dashing, isFalse);
    });

    test('a respawn cancels a dash', () async {
      final game = await _arena('lapu');
      final p = game.player;
      p.attack();
      await _run(game, 0.05);
      p.moves.cancel();
      expect(p.moves.dashing, isFalse);
      expect(p.invincible, isFalse);
    });

    test('draws a dash (ghosts, slash, ring) at every point, facing either way',
        () async {
      for (final right in [true, false]) {
        final game = await _arena('bonifacio', facingRight: right);
        game.player.attack();
        final canvas = ui.Canvas(ui.PictureRecorder());
        for (var i = 0; i < 14; i++) {
          game.player.update(1 / 60);
          game.player.render(canvas);
        }
      }
    });
  });

  group('every flying shape draws', () {
    test(
        'each hero\'s thing renders, facing either way, at any point of its flight',
        () async {
      for (final id in _rangedHeroes) {
        final game = await _arena(id);
        game.player.attack();
        await game.ready();
        final canvas = ui.Canvas(ui.PictureRecorder());
        for (var i = 0; i < 20; i++) {
          for (final s in _shots(game)) {
            s.update(1 / 60);
            s.render(canvas);
          }
        }
      }
    });
  });

  group('Kaalaman charge', () {
    test('a move that hits spends exactly one charge, a miss none', () async {
      for (final id in _rangedHeroes) {
        final hit = await _arena(id, charges: 3);
        await _enemyAt(hit, 60);
        hit.player.attack();
        await _run(hit, 1.5);
        expect(hit.kaalaman, 2, reason: '$id: one hit');

        final miss = await _arena(id, charges: 3);
        miss.player.attack();
        await _run(miss, 2.0);
        expect(miss.kaalaman, 3, reason: '$id: a miss is free');
      }
      final dashHit = await _arena('lapu', charges: 3);
      await _enemyAt(dashHit, 40);
      dashHit.player.attack();
      await _run(dashHit, 0.5);
      expect(dashHit.kaalaman, 2);
    });
  });

  group('playCounter (a right answer in the boss fight)', () {
    // The boss attack is 452 units to the right of the hero's middle.
    final target = Vector2(900, 400);

    test('every hero calls onImpact exactly once and spends no charge',
        () async {
      for (final id in _allHeroes) {
        final game = await _arena(id);
        // An enemy in the way must not be hit by a counter.
        final bystander = await _enemyAt(game, 60);
        var calls = 0;
        game.player.playCounter(target: target, onImpact: () => calls++);
        expect(calls, 0, reason: '$id: it takes time to arrive');
        await _run(game, 4.0);
        expect(calls, 1, reason: '$id: exactly once');
        await _run(game, 2.0);
        expect(calls, 1, reason: '$id: and never again');
        expect(game.kaalaman, 5, reason: '$id: a counter spends no charge');
        expect(bystander.defeated, isFalse, reason: '$id: it hits no enemy');
      }
    });

    test('flying moves arrive at the target at their own speed', () async {
      for (final id in _rangedHeroes) {
        final game = await _arena(id);
        final m = heroMoveFor(id);
        const distance = 900 - _muzzle;
        final speed = [
          m.speed,
          distance / HeroMoveConstants.counterMaxFlightSeconds
        ].reduce((a, b) => a > b ? a : b);
        double? at;
        var calls = 0;
        game.player.playCounter(target: target, onImpact: () => calls++);
        await _run(game, 3.0, each: (t) {
          if (calls == 1 && at == null) at = t;
        });
        expect(at, isNotNull, reason: id);
        expect(at!, closeTo(distance / speed, 0.04), reason: id);
        expect(game.kaalaman, 5);
      }
    });

    test('a burst reports on its first page, and the others fly on', () async {
      final game = await _arena('rizal');
      var calls = 0;
      game.player.playCounter(target: target, onImpact: () => calls++);
      await game.ready();
      expect(_shots(game).length, 1);
      expect(game.player.moves.pagesWaiting, 2);
      await _run(game, 1.2);
      expect(calls, 1);
      expect(game.player.moves.pagesWaiting, 0);
      expect(_shots(game), isEmpty);
    });

    test('the boomerang meets the attack, then goes home', () async {
      final game = await _arena('boy');
      var calls = 0;
      game.player.playCounter(target: target, onImpact: () => calls++);
      await game.ready();
      final coin = _shots(game).single;
      await _run(game, 1.1);
      expect(calls, 1);
      expect(coin.returning, isTrue,
          reason: 'after meeting it, back to the hero');
      await _run(game, 2.0);
      expect(coin.finished, isTrue);
    });

    test(
        'a dash hero dashes at most its distance, reports at the end, then glides back',
        () async {
      for (final id in ['lapu', 'bonifacio']) {
        final game = await _arena(id);
        final p = game.player;
        final m = heroMoveFor(id);
        var calls = 0;
        double? at;
        double? x;
        p.playCounter(
            target: target,
            onImpact: () {
              calls++;
              x = p.position.x;
            });
        expect(p.moves.dashing, isTrue);
        expect(p.invincible, isTrue, reason: '$id: safe while it dashes');
        await _run(game, 0.2 + m.dashSeconds, each: (t) {
          if (calls == 1 && at == null) at = t;
        });
        expect(calls, 1, reason: id);
        expect(at!, closeTo(m.dashSeconds, 0.04),
            reason: '$id: at the end of the dash');
        expect(x! - _heroX, closeTo(m.dashDistance, 0.5), reason: id);

        await _run(game, 1.0);
        expect(calls, 1);
        expect(p.position.x, closeTo(_heroX, 0.5),
            reason: '$id: glided back to where it stood');
        expect(p.moves.dashing, isFalse);
        expect(p.invincible, isFalse);
        expect(game.kaalaman, 5);
      }
    });

    test('a target close by is met with a shorter dash', () async {
      final game = await _arena('lapu');
      var x = 0.0;
      // 130 from the hero's middle: stops 50 short of it = 80, less than 140.
      game.player.playCounter(
          target: Vector2(_centre + 130, 400),
          onImpact: () => x = game.player.position.x);
      await _run(game, 0.5);
      expect(x - _heroX, closeTo(80, 0.5));
    });

    test('a target to the left turns the hero and is met', () async {
      for (final id in ['lapu', 'luna']) {
        final game = await _arena(id);
        var calls = 0;
        game.player
            .playCounter(target: Vector2(0, 400), onImpact: () => calls++);
        expect(game.player.facingRight, isFalse, reason: id);
        await _run(game, 3.0);
        expect(calls, 1, reason: id);
      }
    });

    test('a second counter while one is playing is also answered exactly once',
        () async {
      for (final id in _allHeroes) {
        final game = await _arena(id);
        var a = 0, b = 0;
        game.player.playCounter(target: target, onImpact: () => a++);
        game.player.playCounter(target: target, onImpact: () => b++);
        await _run(game, 4.0);
        expect((a, b), (1, 1), reason: id);
      }
    });

    test('cancelled in the middle (a respawn), a dash still reports once',
        () async {
      final game = await _arena('lapu');
      var calls = 0;
      game.player.playCounter(target: target, onImpact: () => calls++);
      await _run(game, 0.05);
      expect(calls, 0);
      game.player.moves.cancel();
      expect(calls, 1);
      await _run(game, 1.0);
      expect(calls, 1);
    });

    test('a hero that is not in the game still answers, at once, once', () {
      for (final id in _allHeroes) {
        var calls = 0;
        PlayerComponent(characterId: id)
            .playCounter(target: target, onImpact: () => calls++);
        expect(calls, 1, reason: id);
      }
    });

    test('a counter does not block the hero from attacking afterwards',
        () async {
      final game = await _arena('lapu');
      game.player.playCounter(target: target, onImpact: () {});
      game.player.attack();
      expect(game.player.attackCooldownLeft, 0,
          reason: 'busy with the counter: no attack');
      await _run(game, 1.0);
      game.player.attack();
      expect(game.player.attackCooldownLeft, game.player.heroMove.cooldown);
    });
  });
}
