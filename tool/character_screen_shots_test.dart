// A development tool, not a test of behaviour: draws the hero selection screen (7 heroes) at
// a few phone sizes and writes a PNG for each, so the new art in it can be reviewed without
// a device.
//
//   flutter test tool/character_screen_shots_test.dart --dart-define=SHOT_OUT=C:/temp/hero
//
// Without SHOT_OUT the test does nothing, so it is safe in a full `flutter test tool` run.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/screens/home/character_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _out = String.fromEnvironment('SHOT_OUT');

class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame(String selected)
      : super(GameState(
          selectedCharacterId: selected,
          coins: 300,
          hearts: const HeartsState(count: 3, regenStartMs: null),
        ));

  @override
  Duration? get heartCountdown => null;

  @override
  void refreshHearts() {}

  @override
  bool isCharacterUnlocked(String id) =>
      allCharacters.firstWhere((c) => c.id == id).unlockCost == 0;

  @override
  void selectCharacter(String id) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('hero screen shots', (tester) async {
    if (_out.isEmpty) return;
    for (final (size, hero) in [
      (const Size(732, 320), 'boy'),
      (const Size(732, 320), 'rizal'),
      (const Size(640, 360), 'lapu'),
      (const Size(400, 700), 'girl'),
      (const Size(320, 640), 'delpilar'),
    ]) {
      final game = _FakeGame(hero);
      final key = GlobalKey();
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = size;
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const CharacterSelectionScreen()),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [gameProvider.overrideWith((ref) => game)],
        child: RepaintBoundary(key: key, child: MaterialApp.router(routerConfig: router)),
      ));
      for (var i = 0; i < 12; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 60));
      }
      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.5);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      File('${_out}_${hero}_${size.width.toInt()}x${size.height.toInt()}.png').writeAsBytesSync(bytes!);
    }
    addTearDown(tester.view.reset);
  });
}
