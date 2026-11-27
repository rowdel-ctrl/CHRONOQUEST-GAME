// The last hit on a boss: it cracks while the camera moves in, explodes, coins fall, a medal
// rises, a banner pops up and the screen fills with gold. These tests drive the sequence on its
// own (no game): when each part happens, how time slows down, the camera, the sounds, the skip,
// and that every frame can be drawn.
import 'dart:ui' as ui;

import 'package:chronoquest/game/boss_defeat.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<Sprite> _sprite(int w, int h, {bool halfSolid = false}) async {
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), halfSolid ? h / 2 : h.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFCC3322),
  );
  final image = await rec.endRecording().toImage(w, h);
  return Sprite(image);
}

class _Count {
  int rumble = 0,
      crack = 0,
      boom = 0,
      clatter = 0,
      coin = 0,
      medal = 0,
      win = 0;
  BossDefeatSounds get sounds => BossDefeatSounds(
        rumble: () => rumble++,
        crack: () => crack++,
        boom: () => boom++,
        clatter: () => clatter++,
        coin: () => coin++,
        medal: () => medal++,
        win: () => win++,
      );
}

Future<BossDefeatStage> _stage({bool flipped = false, Sprite? hero}) async {
  final boss = await _sprite(80, 60);
  final stage = BossDefeatStage(
    viewSize: Vector2(1280, 720),
    normalTopLeft: Vector2(100, 0),
    bossFoot: Vector2(900, 660),
    heroFoot: Vector2(330, 660),
    bossArtSize: Vector2(160, 120),
    bossFlipped: flipped,
    bossSprite: boss,
    heroWinSprite: hero,
    groundY: 660,
    medalColor: const ui.Color(0xFF8B4513),
    bossName: 'Governor',
    pieces: <DefeatPiece>[],
  );
  stage.pieces.addAll(await sampleDefeatPieces(boss, stage.bossArtSize));
  return stage;
}

/// Runs the sequence at 60 frames a second until it is done (or [limit] seconds), calling
/// [each] after every frame.
double _run(BossDefeatSequence seq,
    {double limit = 30, void Function()? each, bool reduced = false}) {
  var t = 0.0;
  while (!seq.done && t < limit) {
    seq.step(1 / 60, reducedMotion: reduced);
    t += 1 / 60;
    each?.call();
  }
  return t;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test(
      'the picture is cut into small squares, and the see-through ones are left out',
      () async {
    final sprite =
        await _sprite(32, 32, halfSolid: true); // the top half is solid
    final pieces = await sampleDefeatPieces(sprite, Vector2(64, 64));
    expect(pieces, isNotEmpty);
    // A 32 px picture cut every 8 px: 4 columns; the solid half is 2 rows.
    expect(pieces, hasLength(8));
    for (final p in pieces) {
      expect(p.y, lessThan(32),
          reason:
              'only the top half (of the 64 units it is drawn at) has colour');
      expect(p.color, const ui.Color(0xFFCC3322));
    }
    expect(pieces.map((p) => p.x).toSet(), {0.0, 16.0, 32.0, 48.0},
        reason: 'positions are in the units it is drawn at');
  });

  group('the clock', () {
    test(
        'the last hit is first, then the pressure builds, then the explosion, the medal, the banner and the gold',
        () async {
      final seq = BossDefeatSequence(
          stage: await _stage(), sounds: BossDefeatSounds.silent);
      expect(seq.phase, 0);
      expect(seq.hit, isFalse);
      final phases = <int>[];
      _run(seq, each: () {
        if (phases.isEmpty || phases.last != seq.phase) phases.add(seq.phase);
      });
      expect(phases, [0, 1, 2, 3, 4, 5]);
      expect(seq.done, isTrue);
      expect(seq.hit && seq.boomed && seq.medalShown, isTrue);
    });

    test(
        'it freezes for a moment at the last hit and at the explosion, and slows down in between',
        () async {
      final seq = BossDefeatSequence(
          stage: await _stage(), sounds: BossDefeatSounds.silent);
      // Just before the hit: story time runs at full speed.
      _run(seq, limit: 0.3);
      final before = seq.story;
      expect(before, closeTo(0.3, 0.02));
      // Run until the hit lands, then count the frames in which story time does not move.
      var frozen = 0;
      var lastStory = seq.story;
      while (!seq.hit) {
        seq.step(1 / 60);
        lastStory = seq.story;
      }
      for (var i = 0; i < 40; i++) {
        seq.step(1 / 60);
        if (seq.story == lastStory) frozen++;
        lastStory = seq.story;
      }
      expect(frozen * (1 / 60), closeTo(BossDefeatTimes.hitStop, 0.05),
          reason: 'a short freeze at the last hit');

      // Pressure: story time moves at the pressure speed.
      final a = seq.story;
      for (var i = 0; i < 30; i++) {
        seq.step(1 / 60);
      }
      expect(
          (seq.story - a) / 0.5, closeTo(BossDefeatTimes.pressureSpeed, 0.05));
    });

    test(
        'the whole defeat lasts about eight real seconds, and about six and a half if it begins at the hit',
        () async {
      final full = BossDefeatSequence(
          stage: await _stage(), sounds: BossDefeatSounds.silent);
      final seconds = _run(full);
      expect(seconds, inInclusiveRange(7, 11));

      final fromHit = BossDefeatSequence(
          stage: await _stage(), sounds: BossDefeatSounds.silent)
        ..story = BossDefeatTimes.hit;
      final shorter = _run(fromHit);
      expect(shorter, inInclusiveRange(6, 9));
      expect(shorter, lessThan(seconds));
    });

    test(
        'a phone set to remove animations plays it at full speed with no freeze',
        () async {
      final seq = BossDefeatSequence(
          stage: await _stage(), sounds: BossDefeatSounds.silent);
      final seconds = _run(seq, reduced: true);
      expect(seconds, closeTo(BossDefeatTimes.end, 0.1));
    });
  });

  group('the camera', () {
    test(
        'it moves in on the boss while the pressure builds, punches out at the explosion and ends back at normal',
        () async {
      final stage = await _stage();
      final seq =
          BossDefeatSequence(stage: stage, sounds: BossDefeatSounds.silent);
      expect(seq.zoom, 1);
      expect(seq.topLeft, stage.normalTopLeft,
          reason: 'before anything: the camera is where the game put it');

      var maxZoom = 1.0;
      var punched = false;
      var leftWhenClosest = seq.topLeft;
      while (!seq.boomed) {
        seq.step(1 / 60);
        if (seq.zoom > maxZoom) {
          maxZoom = seq.zoom;
          leftWhenClosest = seq.topLeft.clone();
        }
      }
      expect(maxZoom, greaterThan(1.25));
      expect(maxZoom, lessThanOrEqualTo(1.34 + 0.001));
      // Moving in, the view's top left moves toward the boss (to the right of where it started).
      expect(leftWhenClosest.x, greaterThan(stage.normalTopLeft.x));

      seq.step(1 / 60);
      if (seq.zoom < 1) punched = true;
      _run(seq);
      expect(punched, isTrue,
          reason: 'the explosion pulls the camera back a little');
      expect(seq.zoom, 1);
      expect(seq.topLeft, stage.normalTopLeft);
    });
  });

  group('the sounds', () {
    test(
        'rumble once at the hit, a boom once, a coin for each of the 24 coins, the medal and the banner once each',
        () async {
      final count = _Count();
      final seq =
          BossDefeatSequence(stage: await _stage(), sounds: count.sounds);
      _run(seq);
      expect(count.rumble, 1);
      expect(count.boom, 1);
      expect(count.coin, 24);
      expect(count.medal, 1);
      expect(count.win, 1);
      expect(count.crack, greaterThan(5),
          reason: 'the cracks tick faster and faster');
      expect(count.clatter, greaterThan(0));
    });
  });

  group('the skip', () {
    test(
        'a tap counts only after the first second, then jumps to the end with the camera back',
        () async {
      final seq = BossDefeatSequence(
          stage: await _stage(), sounds: BossDefeatSounds.silent);
      _run(seq, limit: 0.5);
      expect(seq.canSkip, isFalse);
      _run(seq, limit: 1.0);
      expect(seq.canSkip, isTrue);
      seq.skip();
      expect(seq.done, isTrue);
      expect(seq.zoom, 1);
      expect(seq.topLeft, seq.stage.normalTopLeft);
      expect(seq.hit && seq.boomed && seq.medalShown, isTrue);
      seq.step(1 / 60); // does nothing more
      expect(seq.done, isTrue);
    });
  });

  group('drawing', () {
    for (final flipped in [false, true]) {
      test(
          'every part can be drawn (${flipped ? 'boss turned right' : 'boss turned left'}) with and without the cheering hero',
          () async {
        final hero = await _sprite(60, 70);
        for (final withHero in [false, true]) {
          final seq = BossDefeatSequence(
              stage:
                  await _stage(flipped: flipped, hero: withHero ? hero : null),
              sounds: BossDefeatSounds.silent);
          var frames = 0;
          while (!seq.done && frames < 700) {
            seq.step(1 / 60);
            frames++;
            if (frames % 9 == 0) {
              final rec = ui.PictureRecorder();
              seq.render(ui.Canvas(rec));
              rec.endRecording();
            }
          }
          expect(seq.done, isTrue);
        }
      });
    }

    test(
        'the cheering hero is drawn by the sequence only when it has his picture',
        () async {
      final hero = await _sprite(60, 70);
      final seq = BossDefeatSequence(
          stage: await _stage(hero: hero), sounds: BossDefeatSounds.silent);
      expect(seq.drawsHero, isFalse);
      while (!seq.medalShown) {
        seq.step(1 / 60);
      }
      expect(seq.drawsHero, isTrue);
      final without = BossDefeatSequence(
          stage: await _stage(), sounds: BossDefeatSounds.silent);
      while (!without.medalShown) {
        without.step(1 / 60);
      }
      expect(without.drawsHero, isFalse,
          reason: 'no picture of him cheering: his usual one stays');
    });
  });
}
