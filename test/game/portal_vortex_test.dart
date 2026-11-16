// The look of the golden bonus portal (a glowing time vortex): drawn at several
// moments of its short life into a picture without throwing, and it stays inside the
// space it is meant to use.
//
// To look at it: flutter test test/game/portal_vortex_test.dart --dart-define=SHOT_OUT=C:/temp/vortex
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chronoquest/core/bonus_constants.dart';
import 'package:chronoquest/game/components/golden_portal_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _out = String.fromEnvironment('SHOT_OUT');

const _w = 600, _h = 700;

/// Where the portal component's top-left corner sits on the test picture.
const _origin = Offset(225, 300);

class _Moment {
  const _Moment(this.name, this.openness,
      {this.clock = 3, this.swirl = 3, this.flash = 0, this.sinceOpen = 99});
  final String name;
  final double openness, clock, swirl, flash, sinceOpen;
}

// Opening (with the pop over 1), open, the round on screen, coming back, closing.
const _moments = [
  _Moment('opening_start', .06, clock: .03, swirl: .03, sinceOpen: .03),
  _Moment('opening_half', .55, clock: .35, swirl: .35, sinceOpen: .35),
  _Moment('opening_pop', 1.1, clock: .6, swirl: .6, sinceOpen: .6),
  _Moment('open', 1.0, clock: 2.4, swirl: 2.4),
  _Moment('open_later', 1.0, clock: 7.9, swirl: 7.9),
  _Moment('entering', 1.0, clock: 5.0, swirl: 9.0, flash: .6),
  _Moment('returning', 1.0, clock: 6.0, swirl: 11.0, flash: .25),
  _Moment('closing_half', .5, clock: 6.2, swirl: 11.4),
  _Moment('closing_end', .03, clock: 6.5, swirl: 11.8),
];

Future<ui.Image> _draw(_Moment m, {required bool glow}) {
  final recorder = ui.PictureRecorder();
  final canvas =
      Canvas(recorder, Rect.fromLTWH(0, 0, _w.toDouble(), _h.toDouble()));
  canvas.translate(_origin.dx, _origin.dy);
  PortalVortexPainter().paint(
    canvas,
    width: BonusConstants.portalWidth,
    height: BonusConstants.portalHeight,
    openness: m.openness,
    clock: m.clock,
    swirl: m.swirl,
    flash: m.flash,
    sinceOpen: m.sinceOpen,
    glow: glow,
  );
  return recorder.endRecording().toImage(_w, _h);
}

/// The box around every pixel that is not (almost) transparent, relative to the
/// component's top-left corner; null when nothing was drawn.
Future<Rect?> _bounds(ui.Image image) async {
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  var minX = _w, minY = _h, maxX = -1, maxY = -1;
  for (var y = 0; y < _h; y++) {
    for (var x = 0; x < _w; x++) {
      if (data.getUint8((y * _w + x) * 4 + 3) > 12) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (maxX < 0) return null;
  return Rect.fromLTRB(minX - _origin.dx, minY - _origin.dy,
      maxX + 1 - _origin.dx, maxY + 1 - _origin.dy);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const width = BonusConstants.portalWidth,
      height = BonusConstants.portalHeight;

  test('the portal is the bigger vortex: about 150 wide, 230 tall', () {
    expect(width, 150);
    expect(height, 230);
    // Walking in works within two thirds of the drawn half width.
    expect(BonusConstants.portalEnterHalfWidth, 50);
    expect(BonusConstants.portalEnterHalfWidth, lessThan(width / 2));
  });

  testWidgets(
      'draws at every moment of its life without throwing, even all at once',
      (tester) async {
    await tester.runAsync(() async {
      for (final m in _moments) {
        for (final glow in [true, false]) {
          final image = await _draw(m, glow: glow);
          expect(await _bounds(image), isNotNull,
              reason: '${m.name} draws something');
          image.dispose();
        }
      }
    });
  });

  testWidgets('one painter can be reused frame after frame', (tester) async {
    await tester.runAsync(() async {
      final painter = PortalVortexPainter();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (var i = 0; i < 120; i++) {
        final t = i / 60;
        painter.paint(canvas,
            width: width,
            height: height,
            openness: i < 48 ? i / 48 : 1,
            clock: t,
            swirl: t,
            sinceOpen: t);
      }
      recorder.endRecording().dispose();
    });
  });

  testWidgets('the drawing stays inside the space it is meant for',
      (tester) async {
    await tester.runAsync(() async {
      for (final m in _moments) {
        final image = await _draw(m, glow: false);
        final b = (await _bounds(image))!;
        image.dispose();
        // Solid parts (without the soft glow): the ticks and sparkles reach about
        // 1.3 times the half size, the shockwave ring on the floor up to 170 wide;
        // the sparkles that orbit below dip up to about 65 under the floor line.
        expect(b.left, greaterThanOrEqualTo(width / 2 - 175), reason: m.name);
        expect(b.right, lessThanOrEqualTo(width / 2 + 175), reason: m.name);
        expect(b.top, greaterThanOrEqualTo(-60), reason: m.name);
        expect(b.bottom, lessThanOrEqualTo(height + 70), reason: m.name);
      }
      // Fully open: the vortex really fills its 150 x 230, and the top stays below
      // where the countdown ring sits (its bottom is 54 above the component top).
      final open = (await _bounds(await _draw(_moments[3], glow: false)))!;
      expect(open.width, greaterThanOrEqualTo(width));
      expect(open.height, greaterThanOrEqualTo(height - 10));
      expect(open.top, greaterThan(-54));
    });
  });

  testWidgets('the soft glow reaches about 190 from the middle and no further',
      (tester) async {
    await tester.runAsync(() async {
      final b =
          (await _bounds(await _draw(_moments[5], glow: true)))!; // flash .6
      const reach = PortalVortexPainter.glowRadius * (1 + .6 * .5) + 2;
      const cx = width / 2, cy = height / 2 + PortalVortexPainter.centreDrop;
      expect(b.left, greaterThanOrEqualTo(cx - reach));
      expect(b.right, lessThanOrEqualTo(cx + reach));
      expect(b.top, greaterThanOrEqualTo(cy - reach));
      expect(b.bottom, lessThanOrEqualTo(cy + reach));
    });
  });

  testWidgets('writes pictures when SHOT_OUT is given', (tester) async {
    if (_out.isEmpty) return;
    Directory(_out).createSync(recursive: true);
    await tester.runAsync(() async {
      for (final m in _moments) {
        // Over the dark green of the mockup's forest, so the glow shows.
        final recorder = ui.PictureRecorder();
        final canvas =
            Canvas(recorder, Rect.fromLTWH(0, 0, _w.toDouble(), _h.toDouble()));
        canvas.drawRect(Rect.fromLTWH(0, 0, _w.toDouble(), _h.toDouble()),
            Paint()..color = const Color(0xFF244A38));
        canvas.drawRect(
            Rect.fromLTWH(0, _origin.dy + height, _w.toDouble(), 200),
            Paint()..color = const Color(0xFF5B3F26));
        canvas.drawRect(Rect.fromLTWH(0, _origin.dy + height, _w.toDouble(), 7),
            Paint()..color = const Color(0xFF5AA646));
        canvas.translate(_origin.dx, _origin.dy);
        PortalVortexPainter().paint(canvas,
            width: width,
            height: height,
            openness: m.openness,
            clock: m.clock,
            swirl: m.swirl,
            flash: m.flash,
            sinceOpen: m.sinceOpen);
        final image = await recorder.endRecording().toImage(_w, _h);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        File('$_out/vortex_${m.name}.png')
            .writeAsBytesSync(bytes.buffer.asUint8List());
      }
    });
  });
}
