// Settings is a few big icon tiles with one word each, not a list of rows with
// sentences: Tunog, Kontrol and I-LOGOUT (in red).
import 'package:chronoquest/models/control_scheme.dart';
import 'package:chronoquest/providers/control_scheme_provider.dart';
import 'package:chronoquest/providers/unlock_all_provider.dart';
import 'package:chronoquest/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeScheme extends StateNotifier<ControlScheme> implements ControlSchemeNotifier {
  _FakeScheme(super.state);
  @override
  Future<void> set(ControlScheme scheme) async => state = scheme;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUnlock extends StateNotifier<bool> implements UnlockAllNotifier {
  _FakeUnlock() : super(false);
  @override
  Future<void> set(bool value) async => state = value;
}

Future<void> _open(
  WidgetTester tester, {
  Size size = const Size(732, 320),
  ControlScheme scheme = ControlScheme.joystick,
  bool testBuild = false,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  await tester.pumpWidget(ProviderScope(
    overrides: [
      controlSchemeProvider.overrideWith((ref) => _FakeScheme(scheme)),
      unlockAllProvider.overrideWith((ref) => _FakeUnlock()),
      testBuildProvider.overrideWithValue(testBuild),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  ));
  await tester.pump();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('three tiles, one word each: Tunog, Kontrol and I-LOGOUT', (tester) async {
    await _open(tester);

    expect(find.byKey(SettingsScreen.soundKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.controlsKey), findsOneWidget);
    expect(find.byKey(const Key('logout_button')), findsOneWidget);
    expect(find.text('Tunog'), findsOneWidget);
    expect(find.text('Kontrol'), findsOneWidget);
    expect(find.text('I-LOGOUT'), findsOneWidget);
  });

  testWidgets('no sentences: the sound summary and the old row text are gone', (tester) async {
    await _open(tester);

    expect(find.textContaining('Musika'), findsNothing);
    expect(find.textContaining('Effects'), findsNothing);
    expect(find.textContaining('·'), findsNothing);
  });

  testWidgets('Kontrol shows Joystick small underneath when that is chosen', (tester) async {
    await _open(tester, scheme: ControlScheme.joystick);
    expect(find.text('Joystick'), findsOneWidget);
  });

  testWidgets('Kontrol shows Mga Arrow small underneath when that is chosen', (tester) async {
    await _open(tester, scheme: ControlScheme.arrows);
    expect(find.text('Mga Arrow'), findsOneWidget);
  });

  testWidgets('the sound tile says what a screen reader needs: music and effects, on or off',
      (tester) async {
    await _open(tester);
    final semantics = tester.getSemantics(find.byKey(SettingsScreen.soundKey));
    expect(semantics.label, startsWith('Tunog: Musika'));
    expect(semantics.label, contains('Effects'));
  });

  testWidgets('each tile is big: at least 96 square, and tappable', (tester) async {
    await _open(tester);
    for (final key in [SettingsScreen.soundKey, SettingsScreen.controlsKey, const Key('logout_button')]) {
      final size = tester.getSize(find.byKey(key));
      expect(size.width, greaterThanOrEqualTo(96), reason: '$key');
      expect(size.height, greaterThanOrEqualTo(96), reason: '$key');
      expect(find.byKey(key).hitTestable(), findsOneWidget, reason: '$key');
    }
  });

  testWidgets('the tester build keeps its Test Mode switch under the tiles', (tester) async {
    await _open(tester, testBuild: true);
    expect(find.byKey(const Key('unlock_all_switch')), findsOneWidget);
  });

  testWidgets('the student build has no Test Mode switch', (tester) async {
    await _open(tester, testBuild: false);
    expect(find.byKey(const Key('unlock_all_switch')), findsNothing);
  });

  for (final size in const [Size(732, 320), Size(640, 360), Size(400, 700)]) {
    testWidgets('fits ${size.width.toInt()}x${size.height.toInt()}, every tile reachable', (tester) async {
      await _open(tester, size: size, testBuild: true);

      expect(tester.takeException(), isNull);
      for (final key in [SettingsScreen.soundKey, SettingsScreen.controlsKey, const Key('logout_button')]) {
        await tester.ensureVisible(find.byKey(key));
        expect(find.byKey(key).hitTestable(), findsOneWidget, reason: '$key at $size');
      }
    });
  }
}
