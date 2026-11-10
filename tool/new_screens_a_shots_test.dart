// A development tool, not a test of behaviour: draws the new first screen, hero
// choice, Sound and Controls screens at a few phone sizes and writes a PNG for each,
// so they can be looked at without a device.
//
//   flutter test tool/new_screens_a_shots_test.dart --dart-define=SHOT_OUT=C:/temp/shots-a
//
// Without SHOT_OUT the test does nothing, so it is safe in a full `flutter test tool` run.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/control_scheme.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/providers/auth_provider.dart';
import 'package:chronoquest/providers/control_scheme_provider.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/screens/auth/login_screen.dart';
import 'package:chronoquest/screens/home/character_selection_screen.dart';
import 'package:chronoquest/screens/settings/controls_screen.dart';
import 'package:chronoquest/screens/settings/sound_screen.dart';
import 'package:chronoquest/services/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _out = String.fromEnvironment('SHOT_OUT');

class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuth() : super(const AuthState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame(String selected)
      : super(GameState(
          selectedCharacterId: selected,
          coins: 340,
          hearts: const HeartsState(count: 5, regenStartMs: null),
        ));

  @override
  Duration? get heartCountdown => null;

  @override
  void refreshHearts() {}

  @override
  bool isCharacterUnlocked(String id) =>
      allCharacters.firstWhere((c) => c.id == id).unlockCost == 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeScheme extends StateNotifier<ControlScheme>
    implements ControlSchemeNotifier {
  _FakeScheme(super.state);
  @override
  Future<void> set(ControlScheme s) async => state = s;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAudio implements AudioService {
  @override
  bool musicEnabled = true;
  @override
  bool soundEnabled = true;
  @override
  double musicVolume = 0.7;
  @override
  double sfxVolume = 0.5;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('new screens A shots', (tester) async {
    if (_out.isEmpty) return;

    Future<void> shot(String name, Size size, Widget home,
        {List<Override> overrides = const []}) async {
      final key = GlobalKey();
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = size;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(ProviderScope(
        key: UniqueKey(),
        overrides: overrides,
        child: RepaintBoundary(key: key, child: home),
      ));
      await tester.pump(const Duration(milliseconds: 2500));
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 60));
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

    Directory(_out).createSync(recursive: true);

    for (final size in const [
      Size(732, 320),
      Size(640, 360),
      Size(400, 700),
    ]) {
      await shot(
        'first',
        size,
        MaterialApp(
          home: LoginScreen(
            scannerBuilder: (c, a, b) => const SizedBox(),
            connection: ValueNotifier<bool?>(true),
            checkConnection: () {},
            lastSignIn: () => null,
          ),
        ),
        overrides: [authProvider.overrideWith((ref) => _FakeAuth())],
      );
    }

    for (final size in const [Size(732, 320), Size(400, 700)]) {
      for (final hero in ['boy', 'rizal']) {
        final router = GoRouter(routes: [
          GoRoute(
              path: '/', builder: (_, __) => const CharacterSelectionScreen()),
        ]);
        await shot(
          'hero_$hero',
          size,
          MaterialApp.router(routerConfig: router),
          overrides: [gameProvider.overrideWith((ref) => _FakeGame(hero))],
        );
      }
      await shot(
        'sound',
        size,
        MaterialApp(home: SoundScreen(audio: _FakeAudio())),
      );
      for (final scheme in ControlScheme.values) {
        await shot(
          'controls_${scheme.name}',
          size,
          const MaterialApp(home: ControlsScreen()),
          overrides: [
            controlSchemeProvider.overrideWith((ref) => _FakeScheme(scheme)),
            gameProvider.overrideWith((ref) => _FakeGame('girl')),
          ],
        );
      }
    }
    addTearDown(tester.view.reset);
  });
}
