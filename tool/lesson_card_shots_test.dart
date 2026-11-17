// A development tool, not a test of behaviour: draws the real lesson card (LessonCardScreen)
// in its states and writes a PNG for each, so it can be looked at without a device.
//
//   flutter test tool/lesson_card_shots_test.dart --dart-define=SHOT_OUT=C:/temp/shots-lesson
//
// Without SHOT_OUT the test does nothing, so it is safe in a full `flutter test tool` run.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chronoquest/data/history_full.dart';
import 'package:chronoquest/screens/game/lesson_card_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _out = String.fromEnvironment('SHOT_OUT');

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('lesson card shots', (tester) async {
    if (_out.isEmpty) return;
    Directory(_out).createSync(recursive: true);
    await tester.runAsync(() => HistoryFull.chapters('pre-colonial'));

    Future<void> shot(
      String name,
      Size size, {
      required int seconds, // time that has run
      required bool toEnd,
      bool done = false,
      int level = 1,
    }) async {
      final key = GlobalKey();
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = size;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: GoRouter(initialLocation: '/l', routes: [
          GoRoute(
            path: '/l',
            builder: (_, __) => RepaintBoundary(
              key: key,
              child: LessonCardScreen(
                eraId: 'pre-colonial',
                level: level,
                wasDone: (_, __) => done,
                onDone: (_, __) {},
              ),
            ),
          ),
          GoRoute(path: '/game/:eraId/:level', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/level-select/:eraId', builder: (_, __) => const SizedBox()),
        ]),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 80));
      }
      if (seconds > 0) await tester.pump(Duration(seconds: seconds));
      if (toEnd) {
        final s = tester.firstState<ScrollableState>(
            find.descendant(
                of: find.byKey(LessonCardScreen.scrollKey),
                matching: find.byType(Scrollable)));
        s.position.jumpTo(s.position.maxScrollExtent);
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
      }
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.5);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      File('$_out/$name.png').writeAsBytesSync(bytes!);
    }

    const land = Size(873, 393);
    await shot('l1_start', land, seconds: 0, toEnd: false);
    await shot('l2_end_early', land, seconds: 20, toEnd: true);
    await shot('l3_ready', land, seconds: 60, toEnd: true);
    await shot('l4_phone', const Size(400, 700), seconds: 10, toEnd: false);
    await shot('l5_replay', land, seconds: 0, toEnd: false, done: true, level: 2);
  });
}
