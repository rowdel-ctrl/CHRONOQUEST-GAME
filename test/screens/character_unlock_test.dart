// A locked character shows its price and is bought with coins; an unlocked one
// is chosen as before.
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/screens/home/character_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

final _paid = allCharacters.firstWhere((c) => c.unlockCost > 0);
final _paidIndex = allCharacters.indexOf(_paid);

class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame(int coins)
      : super(GameState(
          coins: coins,
          hearts: const HeartsState(count: 3, regenStartMs: null),
        ));

  final unlocked = <String>{};
  final selected = <String>[];

  @override
  Duration? get heartCountdown => null;

  @override
  void refreshHearts() {}

  @override
  bool isCharacterUnlocked(String id) =>
      allCharacters.firstWhere((c) => c.id == id).unlockCost == 0 || unlocked.contains(id);

  @override
  void selectCharacter(String id) => selected.add(id);

  @override
  bool unlockCharacter(String id) {
    final c = allCharacters.firstWhere((c) => c.id == id);
    if (state.coins < c.unlockCost) return false;
    unlocked.add(id);
    state = state.copyWith(coins: state.coins - c.unlockCost, unlockedCharacters: {...unlocked});
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

late _FakeGame _game;

Future<void> _pump(WidgetTester tester, {required int coins}) async {
  _game = _FakeGame(coins);
  await tester.binding.setSurfaceSize(const Size(800, 360));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(ProviderScope(
    overrides: [gameProvider.overrideWith((ref) => _game)],
    child: const MaterialApp(home: CharacterSelectionScreen()),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// The carousel and the idle avatars animate forever, so settle by time.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}

/// Swipes to the paid character, as a student would.
Future<void> _goToPaid(WidgetTester tester) async {
  for (var i = 0; i < _paidIndex; i++) {
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await _settle(tester);
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a free character is chosen with the usual button', (tester) async {
    await _pump(tester, coins: 0);
    expect(find.byKey(const ValueKey('unlock_character')), findsNothing);
    expect(find.textContaining('PILIIN SI'), findsOneWidget);
  });

  testWidgets('a locked one shows its price and an unlock button, not Piliin', (tester) async {
    await _pump(tester, coins: 0);
    await _goToPaid(tester);

    // (the next card, also locked, shows its price beside it)
    expect(find.text('${_paid.unlockCost}'), findsOneWidget);
    expect(find.byKey(const ValueKey('unlock_character')), findsOneWidget);
    expect(find.textContaining('PILIIN SI'), findsNothing);
    expect(_game.selected, isEmpty);
  });

  testWidgets('with too few coins the dialog will not let it be bought', (tester) async {
    await _pump(tester, coins: _paid.unlockCost - 1);
    await _goToPaid(tester);
    await tester.tap(find.byKey(const ValueKey('unlock_character')));
    await _settle(tester);

    expect(find.textContaining('Kulang ang coins'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm_unlock')), warnIfMissed: false);
    await _settle(tester);
    expect(_game.unlocked, isEmpty);
  });

  testWidgets('with enough coins it is bought, and then it can be chosen', (tester) async {
    await _pump(tester, coins: _paid.unlockCost + 10);
    await _goToPaid(tester);
    await tester.tap(find.byKey(const ValueKey('unlock_character')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('confirm_unlock')));
    await _settle(tester);
    await _settle(tester); // the dialog has closed
    expect(find.byType(Dialog), findsNothing);

    expect(_game.unlocked, {_paid.id});
    expect(_game.state.coins, 10);
    // The lock and price are gone, and the usual button is back.
    expect(find.text('${_paid.unlockCost}'), findsNothing);
    expect(find.byKey(const ValueKey('unlock_character')), findsNothing);
    expect(find.textContaining('PILIIN SI'), findsOneWidget);
  });
}
