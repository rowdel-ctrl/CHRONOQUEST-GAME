// Settings > Kontrol: the two screens a student walks through to choose how to
// move. Opened from the main menu's gear and from the pause menu, so the walk
// is the same either way: open Settings, open Kontrol, pick a card, go back.
import 'package:chronoquest/models/control_scheme.dart';
import 'package:chronoquest/providers/control_scheme_provider.dart';
import 'package:chronoquest/providers/unlock_all_provider.dart';
import 'package:chronoquest/screens/settings/controls_screen.dart';
import 'package:chronoquest/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Stands in for the real notifier, which writes to Hive (a write that never
/// completes inside a widget test; see tutorial_screen_test.dart).
class _FakeScheme extends StateNotifier<ControlScheme>
    implements ControlSchemeNotifier {
  final List<ControlScheme> saved = [];
  _FakeScheme(super.state);

  @override
  Future<void> set(ControlScheme scheme) async {
    state = scheme;
    saved.add(scheme);
  }

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

Future<_FakeScheme> _pumpApp(
  WidgetTester tester, {
  ControlScheme initial = ControlScheme.joystick,
  _FakeUnlockAll? unlockAll,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 360));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final fake = _FakeScheme(initial);
  final unlock = unlockAll ?? _FakeUnlockAll();

  final router = GoRouter(
    initialLocation: '/menu',
    routes: [
      GoRoute(
        path: '/menu',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push('/settings'),
              child: const Text('OPEN_SETTINGS'),
            ),
          ),
        ),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
        path: '/settings/controls',
        builder: (_, __) => const ControlsScreen(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        controlSchemeProvider.overrideWith((ref) => fake),
        unlockAllProvider.overrideWith((ref) => unlock),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}

Future<void> _openControls(WidgetTester tester) async {
  await tester.tap(find.text('OPEN_SETTINGS'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Kontrol'));
  await tester.pumpAndSettle();
}

void main() {
  group('the testing switch and logout live in Settings', () {
    testWidgets('both are there, and the switch turns on and off', (tester) async {
      final unlock = _FakeUnlockAll();
      await _pumpApp(tester, unlockAll: unlock);
      await tester.tap(find.text('OPEN_SETTINGS'));
      await tester.pumpAndSettle();

      expect(find.text('I-LOGOUT'), findsOneWidget);
      final toggle = find.byKey(const Key('unlock_all_switch'));
      await tester.ensureVisible(toggle);
      expect(toggle, findsOneWidget);
      expect(unlock.state, isFalse);

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(unlock.state, isTrue);
    });

    testWidgets('the switch says hearts are not lost while it is on', (tester) async {
      await _pumpApp(tester);
      await tester.tap(find.text('OPEN_SETTINGS'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Hindi mawawala ang puso'), findsOneWidget);
    });
  });

  testWidgets('Settings lists Kontrol with the current choice', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text('OPEN_SETTINGS'));
    await tester.pumpAndSettle();

    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('Kontrol'), findsOneWidget);
    expect(find.text('Joystick'), findsOneWidget);
  });

  testWidgets('Settings shows Mga Arrow when that is chosen', (tester) async {
    await _pumpApp(tester, initial: ControlScheme.arrows);
    await tester.tap(find.text('OPEN_SETTINGS'));
    await tester.pumpAndSettle();

    expect(find.text('Mga Arrow'), findsOneWidget);
  });

  testWidgets('Kontrol shows both layouts with the current one marked',
      (tester) async {
    await _pumpApp(tester);
    await _openControls(tester);

    expect(find.text('KONTROL'), findsOneWidget);
    expect(find.text('JOYSTICK'), findsOneWidget);
    expect(find.text('MGA ARROW'), findsOneWidget);
    expect(find.text('NAKAPILI'), findsOneWidget);
  });

  testWidgets('picking Mga Arrow saves it and moves the mark', (tester) async {
    final fake = await _pumpApp(tester);
    await _openControls(tester);

    await tester.tap(find.text('MGA ARROW'));
    await tester.pumpAndSettle();

    expect(fake.saved, [ControlScheme.arrows]);
    expect(find.text('NAKAPILI'), findsOneWidget, reason: 'only one card is marked');
    final badge = tester.getCenter(find.text('NAKAPILI')).dx;
    final arrows = tester.getCenter(find.text('MGA ARROW')).dx;
    final joystick = tester.getCenter(find.text('JOYSTICK')).dx;
    expect((badge - arrows).abs(), lessThan((badge - joystick).abs()),
        reason: 'the mark moved to the Mga Arrow card');
  });

  testWidgets('back from Kontrol returns to Settings, which shows the change',
      (tester) async {
    await _pumpApp(tester);
    await _openControls(tester);
    await tester.tap(find.text('MGA ARROW'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bumalik'));
    await tester.pumpAndSettle();

    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('Mga Arrow'), findsOneWidget);
  });

  testWidgets('back from Settings returns to whatever opened it',
      (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text('OPEN_SETTINGS'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bumalik'));
    await tester.pumpAndSettle();

    expect(find.text('OPEN_SETTINGS'), findsOneWidget);
  });

  testWidgets('both screens fit a short sideways phone', (tester) async {
    await _pumpApp(tester);
    await tester.binding.setSurfaceSize(const Size(640, 320));
    await _openControls(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('NAKAPILI'), findsOneWidget);
  });
}
