// Settings > Tunog: music and effects each get an on/off switch and a volume
// slider, and Settings lists the row.
import 'package:chronoquest/models/control_scheme.dart';
import 'package:chronoquest/providers/control_scheme_provider.dart';
import 'package:chronoquest/providers/unlock_all_provider.dart';
import 'package:chronoquest/screens/settings/settings_screen.dart';
import 'package:chronoquest/screens/settings/sound_screen.dart';
import 'package:chronoquest/services/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeAudio implements AudioService {
  @override
  bool musicEnabled = true;
  @override
  bool soundEnabled = true;
  @override
  double musicVolume = 1.0;
  @override
  double sfxVolume = 1.0;
  int coins = 0;

  @override
  void setMusicEnabled(bool on) => musicEnabled = on;
  @override
  void setSoundEnabled(bool on) => soundEnabled = on;
  @override
  void setMusicVolume(double v) => musicVolume = v;
  @override
  void setSfxVolume(double v) => sfxVolume = v;
  @override
  Future<void> playCoin() async => coins++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The real notifier reads Hive, which a widget test does not have.
class _FakeUnlockAll extends StateNotifier<bool> implements UnlockAllNotifier {
  _FakeUnlockAll([super.state = false]);

  @override
  Future<void> set(bool value) async => state = value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The real notifier reads Hive, which a widget test does not have.
class _FakeScheme extends StateNotifier<ControlScheme>
    implements ControlSchemeNotifier {
  _FakeScheme() : super(ControlScheme.joystick);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _size(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('the switches turn music and effects on and off', (tester) async {
    await _size(tester, const Size(800, 360));
    final audio = _FakeAudio();
    await tester.pumpWidget(MaterialApp(
      home: SoundScreen(audio: audio),
    ));

    await tester.tap(find.byKey(SoundScreen.musicSwitchKey));
    await tester.pump();
    expect(audio.musicEnabled, isFalse);
    expect(audio.soundEnabled, isTrue, reason: 'the other one is untouched');

    await tester.tap(find.byKey(SoundScreen.sfxSwitchKey));
    await tester.pump();
    expect(audio.soundEnabled, isFalse);
  });

  testWidgets('the sliders set the volumes', (tester) async {
    await _size(tester, const Size(800, 360));
    final audio = _FakeAudio();
    await tester.pumpWidget(MaterialApp(home: SoundScreen(audio: audio)));

    // The far left of a slider is 0, the middle about half.
    final music = find.byKey(SoundScreen.musicSliderKey);
    await tester.tapAt(tester.getCenter(music));
    await tester.pump();
    expect(audio.musicVolume, closeTo(0.5, 0.11));

    final sfx = find.byKey(SoundScreen.sfxSliderKey);
    await tester.tapAt(tester.getTopLeft(sfx) + const Offset(30, 24));
    await tester.pump();
    expect(audio.sfxVolume, lessThan(0.3));
    expect(audio.coins, 1, reason: 'a sample plays when the effects slider is set');
  });

  testWidgets('a slider cannot be moved while its switch is off', (tester) async {
    await _size(tester, const Size(800, 360));
    final audio = _FakeAudio()..musicEnabled = false;
    await tester.pumpWidget(MaterialApp(home: SoundScreen(audio: audio)));

    final slider = tester.widget<Slider>(find.byKey(SoundScreen.musicSliderKey));
    expect(slider.onChanged, isNull);
  });

  for (final size in const [Size(640, 360), Size(800, 360), Size(732, 320)]) {
    testWidgets('fits a ${size.width.toInt()}x${size.height.toInt()} screen',
        (tester) async {
      await _size(tester, size);
      await tester.pumpWidget(MaterialApp(home: SoundScreen(audio: _FakeAudio())));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Settings lists Tunog and opens it', (tester) async {
    await _size(tester, const Size(800, 360));
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(path: '/settings/sound', builder: (_, __) => SoundScreen(audio: _FakeAudio())),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        controlSchemeProvider.overrideWith((ref) => _FakeScheme()),
        unlockAllProvider.overrideWith((ref) => _FakeUnlockAll()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();

    expect(find.text('Tunog'), findsOneWidget);
    await tester.tap(find.text('Tunog'));
    await tester.pumpAndSettle();

    expect(find.text('TUNOG'), findsOneWidget);
    expect(find.text('Musika'), findsOneWidget);
    expect(find.text('Sound Effects'), findsOneWidget);
  });
}
