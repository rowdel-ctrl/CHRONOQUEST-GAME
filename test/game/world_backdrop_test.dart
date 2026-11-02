// The scenery behind the player (WorldBackdrop and the pictures it is built from).
//
// Real image decoding needs the engine, so the pictures are made inside
// `tester.runAsync`. A test can also write what the backdrop looks like to a PNG: set
// the BACKDROP_SHOTS environment variable to a folder and every era is saved there.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chronoquest/game/backdrop/backdrop_art.dart';
import 'package:chronoquest/game/backdrop/era_look.dart';
import 'package:chronoquest/game/backdrop/pixel_art.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/world_backdrop.dart';
import 'package:chronoquest/game/components/world_foreground.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

ChronoGame _game(String era, {double playerWorldX = 0}) {
  final game = ChronoGame()..currentEra = era;
  game.onGameResize(Vector2(1560, 720));
  game.player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(96, 120)
    ..position = Vector2(playerWorldX, game.groundY - 120);
  return game;
}

Future<WorldBackdrop> _loaded(ChronoGame game, String era,
    {bool animate = true}) async {
  final backdrop = WorldBackdrop(eraId: era, animate: animate)..game = game;
  await backdrop.onLoad();
  return backdrop;
}

void main() {
  group('PixelBuf', () {
    test('draws where it is told and ignores what is off the edge', () {
      final b = PixelBuf(8, 8);
      b.rect(2, 2, 3, 2, 0xFF112233);
      b.put(-1, 0, 0xFFFFFFFF);
      b.put(99, 99, 0xFFFFFFFF);
      expect(b.filled(2, 2), isTrue);
      expect(b.filled(4, 3), isTrue);
      expect(b.filled(5, 3), isFalse);
      expect(b.filled(0, 0), isFalse);
    });

    test('clear makes a pixel see-through again', () {
      final b = PixelBuf(4, 4)..rect(0, 0, 4, 4, 0xFF000000);
      b.clearRect(1, 1, 2, 2);
      expect(b.filled(0, 0), isTrue);
      expect(b.filled(1, 1), isFalse);
    });

    test('haze moves colours towards the fog and leaves empty pixels empty', () {
      final b = PixelBuf(2, 1)..put(0, 0, 0xFF000000);
      b.haze(0xFFFFFFFF, 1);
      expect(b.bytes.sublist(0, 4), [255, 255, 255, 255]);
      expect(b.filled(1, 0), isFalse);
    });

    test('mixColor is the first colour at 0 and the second at 1', () {
      expect(mixColor(0xFF102030, 0xFFA0B0C0, 0), 0xFF102030);
      expect(mixColor(0xFF102030, 0xFFA0B0C0, 1), 0xFFA0B0C0);
    });

    test('the random numbers repeat for the same seed', () {
      final a = Rand(7), b = Rand(7), c = Rand(8);
      final xs = [for (var i = 0; i < 5; i++) a.next()];
      expect([for (var i = 0; i < 5; i++) b.next()], xs);
      expect(c.next(), isNot(xs.first));
    });
  });

  group('EraLook', () {
    test('every era has its own look', () {
      final skies = {for (final id in EraLook.eraIds) EraLook.of(id).skyTop};
      expect(skies.length, EraLook.eraIds.length);
    });

    test('an unknown era gets the first look instead of failing', () {
      expect(EraLook.of('nope').skyTop, EraLook.of('pre-colonial').skyTop);
    });
  });

  group('Scenery pictures', () {
    test('tile with no seam: the left and right edges join up', () {
      // A tree row is drawn three times (one tile left, here, one tile right), so
      // whatever leaves the right edge enters the left edge.
      final look = EraLook.of('pre-colonial');
      final b = treePixels(look, look.mid, 31, 4, 120, 165, 8, 11, 20, 27);
      var leftFilled = 0, rightFilled = 0;
      for (var y = 0; y < kTileH; y++) {
        if (b.filled(0, y)) leftFilled++;
        if (b.filled(kTileW - 1, y)) rightFilled++;
      }
      // Both edges are cut through the same tall trunks and crowns, so neither is empty
      // while the other is full.
      expect((leftFilled - rightFilled).abs(), lessThan(kTileH ~/ 2));
    });

    test('every era draws something in each row of scenery', () {
      for (final id in EraLook.eraIds) {
        final look = EraLook.of(id);
        final scenery = sceneryPixels(look);
        var filled = 0;
        for (var y = 0; y < kTileH; y++) {
          for (var x = 0; x < kTileW; x++) {
            if (scenery.filled(x, y)) filled++;
          }
        }
        expect(filled, greaterThan(kTileW * 20), reason: id);
      }
    });

    test('the same era always gives the same picture', () {
      final look = EraLook.of('ww2');
      expect(sceneryPixels(look).bytes, sceneryPixels(look).bytes);
    });
  });

  group('WorldForeground', () {
    test('the grass stays inside the ground band, so it never covers the feet', () {
      expect(WorldForeground.tuftMax, lessThanOrEqualTo(GroundSection.bandHeight));
    });

    testWidgets('loads and draws every era without error', (tester) async {
      await tester.runAsync(() async {
        for (final id in EraLook.eraIds) {
          final game = _game(id);
          final fg = WorldForeground(eraId: id)..game = game;
          await fg.onLoad();
          fg.update(0.016);
          final rec = ui.PictureRecorder();
          fg.render(ui.Canvas(rec));
          rec.endRecording().dispose();
          fg.onRemove();
        }
      });
    });

    test('the hanging leaves tile with no seam and draw something', () {
      final look = EraLook.of('spanish');
      final b = foregroundTopPixels(look);
      var filled = 0;
      for (var y = 0; y < b.h; y++) {
        for (var x = 0; x < b.w; x++) {
          if (b.filled(x, y)) filled++;
        }
      }
      expect(filled, greaterThan(b.w * 3));
    });
  });

  group('WorldBackdrop', () {
    testWidgets('loads and draws every era without error', (tester) async {
      await tester.runAsync(() async {
        for (final id in EraLook.eraIds) {
          final game = _game(id);
          final backdrop = await _loaded(game, id);
          backdrop.update(0.016);
          final rec = ui.PictureRecorder();
          backdrop.render(ui.Canvas(rec));
          rec.endRecording().dispose();
          backdrop.onRemove();
        }
      });
    });

    testWidgets('scrolls with the camera, nearer rows faster', (tester) async {
      await tester.runAsync(() async {
        final game = _game('pre-colonial');
        final backdrop = await _loaded(game, 'pre-colonial');
        backdrop.update(0.016);
        final before = await _shot(backdrop);
        game.player.position.x = 600;
        backdrop.update(0.016);
        final after = await _shot(backdrop);
        expect(before, isNot(after));
        backdrop.onRemove();
      });
    });

    testWidgets('with animations removed it is still between frames', (tester) async {
      await tester.runAsync(() async {
        final game = _game('spanish');
        final backdrop = await _loaded(game, 'spanish', animate: false);
        backdrop.update(0.016);
        final a = await _shot(backdrop);
        backdrop.update(1.0);
        final b = await _shot(backdrop);
        expect(a, b, reason: 'nothing moves by itself when animations are off');
        backdrop.onRemove();
      });
    });

    testWidgets('saves a picture of each era when BACKDROP_SHOTS is set',
        (tester) async {
      final dir = Platform.environment['BACKDROP_SHOTS'];
      if (dir == null) return;
      await tester.runAsync(() async {
        for (final id in EraLook.eraIds) {
          final game = _game(id, playerWorldX: 900);
          final backdrop = await _loaded(game, id);
          for (var i = 0; i < 120; i++) {
            backdrop.update(1 / 60);
          }
          final rec = ui.PictureRecorder();
          final canvas = ui.Canvas(rec);
          backdrop.render(canvas);
          final fg = WorldForeground(eraId: id)..game = game;
          await fg.onLoad();
          for (var i = 0; i < 120; i++) {
            fg.update(1 / 60);
          }
          fg.render(canvas);
          final img = await rec.endRecording().toImage(1560, 720);
          final data = await img.toByteData(format: ui.ImageByteFormat.png);
          File('$dir/backdrop_$id.png')
              .writeAsBytesSync(data!.buffer.asUint8List());
          backdrop.onRemove();
        }
      });
    });
  });
}

Future<List<int>> _shot(WorldBackdrop backdrop) async {
  final rec = ui.PictureRecorder();
  backdrop.render(ui.Canvas(rec));
  final img = await rec.endRecording().toImage(1560, 720);
  final data = await img.toByteData();
  return data!.buffer.asUint8List().toList();
}
