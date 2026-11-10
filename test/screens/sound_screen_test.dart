// Settings > Tunog: music and effects side by side, each with a big ON/OFF button,
// a meter of ten blocks with minus and plus, a big percentage, and (effects only)
// PAKINGGAN. Settings lists the row.
import 'package:chronoquest/models/control_scheme.dart';
import 'package:chronoquest/providers/control_scheme_provider.dart';
import 'package:chronoquest/providers/unlock_all_provider.dart';
import 'package:chronoquest/screens/settings/settings_screen.dart';
import 'package:chronoquest/screens/settings/sound_screen.dart';
import 'package:chronoquest/services/audio_service.dart';
import 'package:chronoquest/widgets/game_ui.dart';
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

String _percent(WidgetTester tester, Key k) =>
    tester.widget<Text>(find.byKey(k)).textSpan!.toPlainText();

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

  testWidgets('the switches are big ON and OFF buttons that follow the state',
      (tester) async {
    await _size(tester, const Size(800, 360));
    final audio = _FakeAudio();
    await tester.pumpWidget(MaterialApp(home: SoundScreen(audio: audio)));

    expect(find.text('ON'), findsNWidgets(2));
    expect(find.byType(Switch), findsNothing);
    await tester.tap(find.byKey(SoundScreen.musicSwitchKey));
    await tester.pump();
    expect(find.text('ON'), findsOneWidget);
    expect(find.text('OFF'), findsOneWidget);
    expect(tester.getSize(find.byKey(SoundScreen.musicSwitchKey)).height,
        greaterThanOrEqualTo(40));
    // Turning it back on works too.
    await tester.tap(find.byKey(SoundScreen.musicSwitchKey));
    await tester.pump();
    expect(audio.musicEnabled, isTrue);
  });

  testWidgets('the two panels have their names and notes', (tester) async {
    await _size(tester, const Size(800, 360));
    await tester
        .pumpWidget(MaterialApp(home: SoundScreen(audio: _FakeAudio())));
    expect(find.text('MUSIKA'), findsOneWidget);
    expect(find.text('Tugtog habang naglalaro'), findsOneWidget);
    expect(find.text('SOUND EFFECTS'), findsOneWidget);
    expect(find.text('Talon, barya at atake'), findsOneWidget);
    expect(find.text('Saved na sa device na ito.'), findsOneWidget);
  });

  /// The middle of block [n] (1 to 10) of a meter.
  Offset block(WidgetTester tester, Key meter, int n) {
    final r = tester.getRect(find.byKey(meter));
    return Offset(r.left + r.width * (n - 0.5) / 10, r.center.dy);
  }

  testWidgets('a tap on a block sets the volume to that block out of ten',
      (tester) async {
    await _size(tester, const Size(800, 360));
    final audio = _FakeAudio();
    await tester.pumpWidget(MaterialApp(home: SoundScreen(audio: audio)));

    await tester.tapAt(block(tester, SoundScreen.musicSliderKey, 3));
    await tester.pump();
    expect(audio.musicVolume, closeTo(0.3, 1e-9));
    expect(audio.sfxVolume, 1.0, reason: 'the other one is untouched');
    expect(_percent(tester, SoundScreen.musicPercentKey), '30%');

    await tester.tapAt(block(tester, SoundScreen.sfxSliderKey, 7));
    await tester.pump();
    expect(audio.sfxVolume, closeTo(0.7, 1e-9));
    expect(audio.coins, 1, reason: 'a sample plays when the effects are set');
    expect(_percent(tester, SoundScreen.sfxPercentKey), '70%');
  });

  testWidgets('dragging along the blocks follows the finger', (tester) async {
    await _size(tester, const Size(800, 360));
    final audio = _FakeAudio()..musicVolume = 0.1;
    await tester.pumpWidget(MaterialApp(home: SoundScreen(audio: audio)));

    final gesture =
        await tester.startGesture(block(tester, SoundScreen.musicSliderKey, 2));
    await gesture.moveTo(block(tester, SoundScreen.musicSliderKey, 6));
    await tester.pump();
    expect(audio.musicVolume, closeTo(0.6, 1e-9));
    await gesture.moveTo(block(tester, SoundScreen.musicSliderKey, 9));
    await gesture.up();
    await tester.pump();
    expect(audio.musicVolume, closeTo(0.9, 1e-9));
    expect(audio.coins, 0, reason: 'the music meter plays no effect');
  });

  testWidgets('minus and plus move one block at a time and stop at the ends',
      (tester) async {
    await _size(tester, const Size(800, 360));
    final audio = _FakeAudio()
      ..musicVolume = 0.5
      ..sfxVolume = 0.9;
    await tester.pumpWidget(MaterialApp(home: SoundScreen(audio: audio)));

    await tester.tap(find.byKey(SoundScreen.musicMinusKey));
    await tester.pump();
    expect(audio.musicVolume, closeTo(0.4, 1e-9));
    await tester.tap(find.byKey(SoundScreen.musicPlusKey));
    await tester.pump();
    await tester.tap(find.byKey(SoundScreen.musicPlusKey));
    await tester.pump();
    expect(audio.musicVolume, closeTo(0.6, 1e-9));

    await tester.tap(find.byKey(SoundScreen.sfxPlusKey));
    await tester.pump();
    await tester.tap(find.byKey(SoundScreen.sfxPlusKey));
    await tester.pump();
    expect(audio.sfxVolume, closeTo(1.0, 1e-9), reason: 'it stops at full');
    for (var i = 0; i < 11; i++) {
      await tester.tap(find.byKey(SoundScreen.sfxMinusKey));
      await tester.pump();
    }
    await tester.pump();
    expect(audio.sfxVolume, 0.0, reason: 'and at nothing');
  });

  testWidgets('PAKINGGAN plays the effect sample, music has no such button',
      (tester) async {
    await _size(tester, const Size(800, 360));
    final audio = _FakeAudio();
    await tester.pumpWidget(MaterialApp(home: SoundScreen(audio: audio)));

    expect(find.text('PAKINGGAN'), findsOneWidget);
    await tester.tap(find.byKey(SoundScreen.sfxPreviewKey));
    await tester.pump();
    expect(audio.coins, 1);
    expect(audio.sfxVolume, 1.0, reason: 'hearing it changes nothing');
  });

  testWidgets('with a switch off its meter is dim and dead, and PAKINGGAN too',
      (tester) async {
    await _size(tester, const Size(800, 360));
    final audio = _FakeAudio()
      ..musicEnabled = false
      ..soundEnabled = false
      ..musicVolume = 0.5;
    await tester.pumpWidget(MaterialApp(home: SoundScreen(audio: audio)));

    await tester.tap(find.byKey(SoundScreen.musicSliderKey),
        warnIfMissed: false);
    await tester.tap(find.byKey(SoundScreen.musicPlusKey), warnIfMissed: false);
    await tester.tap(find.byKey(SoundScreen.sfxPreviewKey),
        warnIfMissed: false);
    await tester.pump();
    expect(audio.musicVolume, 0.5);
    expect(audio.coins, 0);
    final opacity = tester.widget<Opacity>(find
        .ancestor(
            of: find.byKey(SoundScreen.musicSliderKey),
            matching: find.byType(Opacity))
        .first);
    expect(opacity.opacity, lessThan(0.6));
    expect(_percent(tester, SoundScreen.musicPercentKey), '0%',
        reason: 'it shows 0% while off');
  });

  for (final size in const [Size(640, 360), Size(732, 320), Size(400, 700)]) {
    testWidgets('fits a ${size.width.toInt()}x${size.height.toInt()} screen',
        (tester) async {
      await _size(tester, size);
      await tester
          .pumpWidget(MaterialApp(home: SoundScreen(audio: _FakeAudio())));
      expect(tester.takeException(), isNull);
      // Every button is a thumb-sized target.
      for (final k in [
        SoundScreen.musicSwitchKey,
        SoundScreen.musicMinusKey,
        SoundScreen.sfxPlusKey,
        SoundScreen.sfxPreviewKey,
      ]) {
        expect(tester.getSize(find.byKey(k)).height, greaterThanOrEqualTo(40));
      }
    });
  }

  testWidgets(
      'side by side on a wide screen, one above the other on a narrow one',
      (tester) async {
    await _size(tester, const Size(732, 320));
    await tester
        .pumpWidget(MaterialApp(home: SoundScreen(audio: _FakeAudio())));
    var a = tester.getRect(find.byType(GamePanel).first);
    var b = tester.getRect(find.byType(GamePanel).last);
    expect(a.right, lessThan(b.left));
    expect((a.top - b.top).abs(), lessThan(1));

    await _size(tester, const Size(400, 700));
    await tester
        .pumpWidget(MaterialApp(home: SoundScreen(audio: _FakeAudio())));
    await tester.pump();
    a = tester.getRect(find.byType(GamePanel).first);
    b = tester.getRect(find.byType(GamePanel).last);
    expect(a.bottom, lessThan(b.top));
  });

  testWidgets('Settings lists Tunog and opens it', (tester) async {
    await _size(tester, const Size(800, 360));
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(
            path: '/settings/sound',
            builder: (_, __) => SoundScreen(audio: _FakeAudio())),
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
    expect(find.text('MUSIKA'), findsOneWidget);
    expect(find.text('SOUND EFFECTS'), findsOneWidget);
  });
}
