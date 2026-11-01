// The motion on the character screen: another hero slides in, a bought hero lights up,
// a chosen hero jumps and runs off before the next screen, and none of it happens when
// the phone removes animations. The idle hop and glints run on timers, so every test
// settles by time.
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/screens/home/character_selection_screen.dart';
import 'package:chronoquest/widgets/particles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

final _paid = allCharacters.firstWhere((c) => c.unlockCost > 0);

class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame({int coins = 0, String selected = 'rizal'})
      : super(GameState(
          coins: coins,
          selectedCharacterId: selected,
          hearts: const HeartsState(count: 3, regenStartMs: null),
        ));

  final unlocked = <String>{};
  final chosen = <String>[];

  @override
  Duration? get heartCountdown => null;

  @override
  void refreshHearts() {}

  @override
  bool isCharacterUnlocked(String id) =>
      allCharacters.firstWhere((c) => c.id == id).unlockCost == 0 ||
      unlocked.contains(id);

  @override
  void selectCharacter(String id) => chosen.add(id);

  @override
  bool unlockCharacter(String id) {
    final c = allCharacters.firstWhere((c) => c.id == id);
    if (state.coins < c.unlockCost) return false;
    unlocked.add(id);
    state = state.copyWith(
        coins: state.coins - c.unlockCost, unlockedCharacters: {...unlocked});
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

late _FakeGame _game;
final _landed = <String>[];

Future<void> _pump(WidgetTester tester,
    {bool animations = true, int coins = 0, bool opened = true}) async {
  _game = _FakeGame(coins: coins);
  _landed.clear();
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: !animations);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.binding.setSurfaceSize(const Size(800, 360));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.view.devicePixelRatio = 1.0;
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const CharacterSelectionScreen()),
    GoRoute(
      path: '/era-selection',
      builder: (_, __) {
        _landed.add('/era-selection');
        return const Scaffold(body: Text('eras stand-in'));
      },
    ),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [gameProvider.overrideWith((ref) => _game)],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pump();
  if (opened) {
    await tester.pump(const Duration(milliseconds: 2400)); // the opening
  }
}

String _name(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(CharacterSelectionScreen.nameKey)).data!;

double _heroX(WidgetTester tester, String id) =>
    tester.getCenter(find.byKey(ValueKey('hero_$id'))).dx;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('another hero slides out and the next slides in', (tester) async {
    await _pump(tester);
    final rest = _heroX(tester, 'rizal');

    await tester.tap(find.byKey(CharacterSelectionScreen.nextKey));
    await tester.pump(); // the animation starts on this frame
    await tester.pump(const Duration(milliseconds: 150));
    // Rizal is leaving to the left.
    expect(find.byKey(const ValueKey('hero_rizal')), findsOneWidget);
    expect(_heroX(tester, 'rizal'), lessThan(rest - 5));

    await tester.pump(const Duration(milliseconds: 250));
    // Luna is arriving from the right.
    expect(find.byKey(const ValueKey('hero_luna')), findsOneWidget);
    expect(find.byKey(const ValueKey('hero_rizal')), findsNothing);

    await tester.pump(const Duration(milliseconds: 600));
    expect(_name(tester), 'Luna');
    expect((_heroX(tester, 'luna') - rest).abs(), lessThan(1),
        reason: 'and it comes to rest in the same place');
  });

  testWidgets('a hero that comes in from the left when going back',
      (tester) async {
    await _pump(tester);
    final rest = _heroX(tester, 'rizal');
    await tester.tap(find.byKey(CharacterSelectionScreen.prevKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 330));
    expect(find.byKey(const ValueKey('hero_lapu')), findsOneWidget);
    expect(_heroX(tester, 'lapu'), lessThan(rest),
        reason: 'Lapu-Lapu comes from the left');
    await tester.pump(const Duration(milliseconds: 700));
    expect(_name(tester), 'Lapu-Lapu');
  });

  testWidgets('a bought hero lights up with sparks, confetti and NAKUHA NA!',
      (tester) async {
    await _pump(tester, coins: _paid.unlockCost + 10);
    await tester.tap(find.byKey(CharacterSelectionScreen.rosterKey(_paid.id)));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byKey(CharacterSelectionScreen.unlockKey), findsOneWidget);

    await tester.tap(find.byKey(CharacterSelectionScreen.unlockKey));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('confirm_unlock')));
    await tester.pump(); // the dialog goes, the purchase is made
    await tester.pump(
        const Duration(milliseconds: 100)); // the burst starts on this frame
    expect(_game.unlocked, {_paid.id});

    // The burst: confetti and sparks are alive, and the words are up.
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.state<ParticleLayerState>(find.byType(ParticleLayer)).alive,
        greaterThan(5));
    expect(find.text('NAKUHA NA!'), findsOneWidget);

    // Let it play out, a frame at a time as on a phone.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('NAKUHA NA!'), findsNothing, reason: 'it drifts off');
    expect(find.byKey(CharacterSelectionScreen.chooseKey), findsOneWidget);
    expect(tester.state<ParticleLayerState>(find.byType(ParticleLayer)).alive,
        lessThan(4),
        reason: 'and the confetti has fallen away');
  });

  testWidgets('choosing jumps and runs off, then goes to the eras',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(CharacterSelectionScreen.chooseKey));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_game.chosen, ['rizal'], reason: 'the hero is chosen at once');
    expect(_landed, isEmpty);

    await tester.pump(const Duration(milliseconds: 500));
    expect(_landed, isEmpty, reason: 'still jumping and running');
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_landed, ['/era-selection']);
  });

  testWidgets('a tap while it runs off skips ahead', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(CharacterSelectionScreen.chooseKey));
    await tester.pump(); // the run starts on this frame
    await tester.pump(const Duration(milliseconds: 200));
    expect(_landed, isEmpty);
    await tester.tapAt(const Offset(400, 180));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_landed, ['/era-selection']);
  });

  testWidgets(
      'with animations removed there is no motion at all, and choosing is at once',
      (tester) async {
    await _pump(tester, animations: false);
    final rest = _heroX(tester, 'rizal');

    await tester.tap(find.byKey(CharacterSelectionScreen.nextKey));
    await tester.pump();
    expect(_name(tester), 'Luna');
    expect(find.byKey(const ValueKey('hero_rizal')), findsNothing);
    expect((_heroX(tester, 'luna') - rest).abs(), lessThan(1));
    expect(
        tester.state<ParticleLayerState>(find.byType(ParticleLayer)).alive, 0);

    await tester.tap(find.byKey(CharacterSelectionScreen.prevKey));
    await tester.pump();
    await tester.tap(find.byKey(CharacterSelectionScreen.chooseKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_landed, ['/era-selection']);
  });

  testWidgets('the screen fits a short landscape phone while moving',
      (tester) async {
    await _pump(tester, opened: false);
    await tester.binding.setSurfaceSize(const Size(732, 320));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull,
          reason: 'after ${(i + 1) * 250} ms');
    }
  });
}
