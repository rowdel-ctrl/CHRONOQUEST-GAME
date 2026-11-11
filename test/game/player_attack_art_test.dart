// The 2026-11 hero art: pictures of different sizes drawn at pixels / 2.5 with
// the middle of the bottom edge on the feet (lib/game/art_scale.dart), and a
// 0.25 s attack picture sequence that is only a picture: the move itself (hero_moves_test.dart)
// does not depend on it. The old short swing (the 80x90 box) still exists: it is what a
// dash hero does in the air, so the tests of the box use Bonifacio in the air.
//
// Loads a real hero from assets/characters/ (plain test(), so real file I/O
// works), without mounting a GameWidget.
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/game/art_scale.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/attack_hitbox_component.dart';
import 'package:chronoquest/game/components/hero_projectile_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_input.dart';

Future<(ChronoGame, PlayerComponent)> _loadedPlayer(String id,
    {bool onGround = true}) async {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.images.prefix = 'assets/';
  final player = PlayerComponent(characterId: id);
  player.game = game;
  await player.onLoad();
  player
    ..position = Vector2(400, game.groundY - player.size.y)
    ..isOnGround = onGround;
  game.player = player;
  game.world.add(player);

  final input = GameInput(game: game);
  input.joystick = JoystickComponent(background: CircleComponent(radius: 10));
  game.gameInput = input;
  game.kaalaman = 5;
  await game.ready();
  return (game, player);
}

AttackHitboxComponent _hitbox(ChronoGame game) =>
    game.world.children.whereType<AttackHitboxComponent>().single;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('art_scale paintArt', () {
    test('a 304x300 picture is drawn 121.6x120 with its feet at the bottom middle',
        () async {
      ui.Image solid(int w, int h) {
        final r = ui.PictureRecorder();
        ui.Canvas(r).drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
            ui.Paint()..color = const ui.Color(0xFFFF0000));
        return r.endRecording().toImageSync(w, h);
      }

      final sprite = Sprite(solid(304, 300));
      final size = artSizeOf(sprite);
      expect(size.x, closeTo(121.6, 1e-3));
      expect(size.y, closeTo(120, 1e-3));

      final r = ui.PictureRecorder();
      paintArt(ui.Canvas(r), sprite, footX: 100, footY: 150);
      final out = r.endRecording().toImageSync(200, 200);
      final bytes = (await out.toByteData())!;
      bool filled(int x, int y) => bytes.getUint8((y * 200 + x) * 4 + 3) > 0;

      // Feet (bottom middle) at (100, 150): the picture spans x 39.2..160.8, y 30..150.
      expect(filled(100, 149), isTrue);
      expect(filled(100, 151), isFalse);
      expect(filled(100, 31), isTrue);
      expect(filled(100, 28), isFalse);
      expect(filled(40, 100), isTrue);
      expect(filled(37, 100), isFalse);
      expect(filled(160, 100), isTrue);
      expect(filled(163, 100), isFalse);
    });
  });

  group('PlayerComponent pictures', () {
    test('keeps the 96x120 box and loads every walk frame the hero has',
        () async {
      final (_, rizal) = await _loadedPlayer('rizal');
      expect(rizal.size, Vector2(96, 120));
      expect(rizal.walkAnimation.frames.length, 4);

      final (_, lapu) = await _loadedPlayer('lapu');
      expect(lapu.walkAnimation.frames.length, 5);
    });

    test('the combat numbers did not change', () {
      expect(CombatConstants.attackHitboxWidth, 80);
      expect(CombatConstants.attackHitboxHeight, 90);
      expect(CombatConstants.attackHitboxDuration, 0.25);
      expect(CombatConstants.attackCooldown, 0.4);
    });
  });

  group('attack pictures', () {
    test('on the ground: attack_1, then attack_4, then back to walking',
        () async {
      final (game, player) = await _loadedPlayer('rizal');
      expect(player.hasAttackArt, isTrue);
      expect(player.attackPictureNumber, isNull);

      player.attack();
      expect(player.attackPictureNumber, 1);

      player.update(0.10);
      expect(player.attackPictureNumber, 1);
      player.update(0.08); // 0.18 s
      expect(player.attackPictureNumber, 4);
      player.update(0.06); // 0.24 s
      expect(player.attackPictureNumber, 4);
      player.update(0.02); // 0.26 s
      expect(player.attackPictureNumber, isNull);
      expect(player.animation, same(player.walkAnimation));
      // Rizal throws pages now, not a box.
      await game.ready();
      expect(game.world.children.whereType<HeroProjectileComponent>(), isNotEmpty);
      expect(game.world.children.whereType<AttackHitboxComponent>(), isEmpty);
    });

    test('in the air: attack_2, then attack_3, then back to the jump pose',
        () async {
      final (_, player) = await _loadedPlayer('rizal', onGround: false);
      player.animation = player.jumpAnim;

      player.attack();
      expect(player.attackPictureNumber, 2);
      player.update(0.05);
      expect(player.attackPictureNumber, 2);
      player.update(0.07); // 0.12 s
      expect(player.attackPictureNumber, 3);
      player.update(0.14); // 0.26 s
      expect(player.attackPictureNumber, isNull);
      expect(player.animation, same(player.jumpAnim));
    });

    test('a hero with 3 attack pictures (Lapu) shows attack_1 for the whole dash',
        () async {
      final (_, player) = await _loadedPlayer('lapu');
      expect(player.hasAttackArt, isTrue);

      // Lapu's dash lasts 0.22 s and the picture stays 0.14 s after it.
      player.attack();
      expect(player.attackPictureNumber, 1);
      player.update(0.20);
      expect(player.attackPictureNumber, 1);
      player.update(0.10);
      expect(player.attackPictureNumber, 1);
      player.update(0.07); // 0.37 s
      expect(player.attackPictureNumber, isNull);
    });

    test('a dash with 4 pictures (Bonifacio): attack_1 during it, attack_4 after',
        () async {
      final (_, player) = await _loadedPlayer('bonifacio');
      player.attack();
      expect(player.attackPictureNumber, 1);
      player.update(0.10);
      expect(player.attackPictureNumber, 1);
      player.update(0.07); // 0.17 s: the 0.16 s dash is over
      expect(player.attackPictureNumber, 4);
      player.update(0.14); // 0.31 s: past 0.16 + 0.14
      expect(player.attackPictureNumber, isNull);
    });

    test('Lapu in the air still gets attack_2 then attack_3 (the old short swing)',
        () async {
      final (game, player) = await _loadedPlayer('lapu', onGround: false);
      player.attack();
      expect(player.attackPictureNumber, 2);
      player.update(0.12);
      expect(player.attackPictureNumber, 3);
      await game.ready();
      expect(_hitbox(game).size, Vector2(80, 90));
    });

    test('hurt wins over the attack picture', () async {
      final (_, player) = await _loadedPlayer('rizal');
      player.attack();
      expect(player.attackPictureNumber, 1);
      player.isHurt = true;
      expect(player.attackPictureNumber, isNull);
    });

    test('the short swing (a dash hero in the air): box, lifetime and the hero\'s cooldown',
        () async {
      final (game, player) = await _loadedPlayer('bonifacio', onGround: false);
      player.attack();
      await game.ready();

      final box = _hitbox(game);
      expect(box.size, Vector2(80, 90));
      expect(box.drawSlash, isFalse,
          reason: 'the art draws its own slash, so no white crescent on top');

      // Inside Bonifacio's own 0.55 s cooldown a second swing does nothing.
      player.update(0.30);
      player.attack();
      await game.ready();
      expect(game.world.children.whereType<AttackHitboxComponent>().length, 1);

      // The picture is over at 0.25 s, the next swing is allowed after 0.55 s.
      expect(player.attackPictureNumber, isNull);
      player.update(0.26);
      player.isOnGround = false;
      player.attack();
      expect(player.attackPictureNumber, 2);
    });

    test('a hero without attack art keeps the old white slash', () async {
      final game = ChronoGame();
      game.onGameResize(Vector2(800, 450));
      final player = PlayerComponent(characterId: 'bonifacio')
        ..size = Vector2(96, 120)
        ..position = Vector2(400, game.groundY - 120);
      player.game = game;
      game.player = player;
      // never mounted, so no pictures are loaded
      game.kaalaman = 3;
      await game.ready();

      expect(player.hasAttackArt, isFalse);
      player.attack();
      await game.ready();
      expect(_hitbox(game).drawSlash, isTrue);
      expect(player.attackPictureNumber, isNull);
    });
  });
}
