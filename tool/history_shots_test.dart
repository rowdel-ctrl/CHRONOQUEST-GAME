// A development tool, not a test of behaviour: draws the era background (history) screen,
// its "BASAHIN ANG BUONG KWENTO" reader, and writes a PNG for each, so they can be looked at
// without a device.
//
//   flutter test tool/history_shots_test.dart --dart-define=SHOT_OUT=C:/temp/shots-history
//
// Without SHOT_OUT the test does nothing, so it is safe in a full `flutter test tool` run.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chronoquest/data/history_full.dart';
import 'package:chronoquest/screens/game/background_history_screen.dart';
import 'package:chronoquest/screens/game/full_story_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _out = String.fromEnvironment('SHOT_OUT');

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('history screen shots', (tester) async {
    if (_out.isEmpty) return;
    Directory(_out).createSync(recursive: true);
    // Read the full text for real (an asset read needs the real event loop).
    await tester.runAsync(() async {
      for (final e in ['pre-colonial', 'american', 'modern']) {
        await HistoryFull.chapters(e);
      }
    });

    Future<void> shot(String name, Size size, Widget Function() home) async {
      final key = GlobalKey();
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = size;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(RepaintBoundary(key: key, child: home()));
      await tester.pump(const Duration(milliseconds: 1500));
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 80));
      }
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.5);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      File('$_out/${name}_${size.width.toInt()}x${size.height.toInt()}.png')
          .writeAsBytesSync(bytes!);
    }

    Widget card(String era) => MaterialApp.router(
          routerConfig: GoRouter(initialLocation: '/b', routes: [
            GoRoute(
                path: '/b',
                builder: (_, __) =>
                    BackgroundHistoryScreen(eraId: era, alreadyRead: false)),
            GoRoute(
                path: '/era-selection', builder: (_, __) => const SizedBox()),
          ]),
        );
    Widget reader(String era, int chapter) => MaterialApp(
          home: FullStoryScreen(
            eraId: era,
            chapter: chapter,
            wasRead: (_, __) => false,
            onChapterRead: (_, __) {},
          ),
        );

    for (final size in const [Size(873, 393), Size(640, 360), Size(400, 700)]) {
      await shot('card', size, () => card('pre-colonial'));
    }
    for (final size in const [Size(873, 393), Size(400, 700)]) {
      await shot('reader_precolonial', size, () => reader('pre-colonial', 1));
    }
    await shot(
        'reader_american', const Size(873, 393), () => reader('american', 6));
    await shot(
        'reader_modern', const Size(640, 360), () => reader('modern', 1));
    addTearDown(tester.view.reset);
  });
}
