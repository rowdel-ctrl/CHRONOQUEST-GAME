// The era selection screen with the testing switch on shows all six eras. On a
// landscape phone there are only ~230px between the title and the student bar,
// and the cards used to wrap into two rows of 200px each, so the second row
// (American, WW2, Modern) was pushed down behind the bottom bar. Children
// painted outside their parent's bounds are not hit-testable, so those three
// eras could not be tapped at all.
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/era_progress.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/models/student.dart';
import 'package:chronoquest/providers/auth_provider.dart';
import 'package:chronoquest/providers/badge_provider.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/providers/progress_provider.dart';
import 'package:chronoquest/providers/unlock_all_provider.dart';
import 'package:chronoquest/screens/home/era_selection_screen.dart';
import 'package:chronoquest/widgets/hearts_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame()
      : super(
            GameState(hearts: const HeartsState(count: 3, regenStartMs: null)));
  @override
  Duration? get heartCountdown => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuth()
      : super(AuthState(
          student: Student.fromJson(
              {'id': 's', 'name': 'Rodel', 'gradeLevel': 'grade5'}),
          isLoggedIn: true,
        ));
  static int refreshes = 0;
  @override
  Future<void> refreshProfile() async => refreshes++;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProgress extends StateNotifier<ProgressState>
    implements ProgressNotifier {
  _FakeProgress() : super(const ProgressState());
  @override
  Future<void> loadProgress() async {}
  @override
  EraProgress getEraProgress(String eraId) {
    // One completed era and one in progress, so the star and the "n/total
    // levels" line are laid out too, not just the plain cards.
    if (eraId == 'pre-colonial') {
      return EraProgress(eraId: eraId, bossDefeated: true, levelsCompleted: 10);
    }
    if (eraId == 'spanish') {
      return EraProgress(eraId: eraId, levelsCompleted: 3);
    }
    return EraProgress(eraId: eraId);
  }

  @override
  bool isEraUnlocked(String eraId, List<String> visibleEraIds) =>
      visibleEraIds.indexOf(eraId) <= 0;
  @override
  void markLevelCompleted(String eraId, int level, int stars) {}
}

class _FakeUnlock extends StateNotifier<bool> implements UnlockAllNotifier {
  _FakeUnlock(super.value);
  @override
  Future<void> set(bool value) async => state = value;
}

Future<void> _pump(WidgetTester tester, Size size,
    {required bool unlockAll}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameProvider.overrideWith((ref) => _FakeGame()),
        authProvider.overrideWith((ref) => _FakeAuth()),
        progressProvider.overrideWith((ref) => _FakeProgress()),
        unlockAllProvider.overrideWith((ref) => _FakeUnlock(unlockAll)),
        badgeProvider.overrideWith((ref) => BadgeNotifier(payCoins: (_) {})),
      ],
      child: const MaterialApp(home: EraSelectionScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const sizes = {
    '640x360': Size(640, 360),
    '732x320': Size(732, 320),
  };

  testWidgets('era select no longer shows hearts, and has a Settings gear',
      (tester) async {
    await _pump(tester, const Size(800, 360), unlockAll: false);

    expect(find.byType(HeartsPill), findsNothing,
        reason: 'hearts show on character select and level select only');
    final gear = find.byTooltip('Settings');
    expect(gear, findsOneWidget);
    expect(gear.hitTestable(), findsOneWidget);
  });

  testWidgets('asks the server for the score again when it opens',
      (tester) async {
    _FakeAuth.refreshes = 0;
    await _pump(tester, const Size(800, 360), unlockAll: false);
    expect(_FakeAuth.refreshes, 1);
  });

  testWidgets('Profile sits just left of Settings, which is right-most',
      (tester) async {
    await _pump(tester, const Size(800, 360), unlockAll: false);

    final profile = tester.getCenter(find.byTooltip('Profile'));
    final settings = tester.getCenter(find.byTooltip('Settings'));
    expect(profile.dx, lessThan(settings.dx));
    expect(settings.dx - profile.dx, 48, reason: 'chips sit side by side');
    expect(find.byTooltip('Profile').hitTestable(), findsOneWidget);
  });

  for (final entry in sizes.entries) {
    testWidgets(
        'all six eras can be reached and tapped one by one at ${entry.key}',
        (tester) async {
      await _pump(tester, entry.value, unlockAll: true);

      final screen = Offset.zero & entry.value;
      // It opens on the era in progress; go back to the first.
      while (tester.any(find.byKey(EraSelectionScreen.prevKey))) {
        await tester.tap(find.byKey(EraSelectionScreen.prevKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }
      for (var i = 0; i < allEras.length; i++) {
        final era = allEras[i];
        expect(tester.takeException(), isNull,
            reason: 'a layout overflow was reported at ${entry.key}');
        final card = find.byKey(EraSelectionScreen.cardKey(era.id));
        expect(card, findsOneWidget, reason: '${era.name} is missing');
        expect(find.text(era.name), findsWidgets,
            reason: '${era.name} shows its full name');
        expect(screen.contains(tester.getRect(card).center), isTrue,
            reason: '${era.name} is drawn off screen');
        expect(card.hitTestable(), findsOneWidget,
            reason: '${era.name} is not tappable');
        if (i < allEras.length - 1) {
          await tester.tap(find.byKey(EraSelectionScreen.nextKey));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
        }
      }
      expect(find.byKey(EraSelectionScreen.nextKey), findsNothing,
          reason: 'the sixth is the last');
    });

    testWidgets('the normal three-era view still fits at ${entry.key}',
        (tester) async {
      await _pump(tester, entry.value, unlockAll: false);

      expect(tester.takeException(), isNull,
          reason: 'a layout overflow was reported at ${entry.key}');
      final screen = Offset.zero & entry.value;
      final grade5 = allEras.where((e) => e.grade == 5);
      expect(grade5.length, 3);
      // The first is finished and the second is not open in this fake, so it stands
      // on the first, with the second peeking in.
      for (final era in grade5) {
        final card = find.byKey(EraSelectionScreen.cardKey(era.id));
        // The first is in front; the one after it peeks in; the third is out of sight.
        if (era == grade5.last) {
          expect(card, findsNothing);
          continue;
        }
        expect(card, findsOneWidget);
        expect(screen.contains(tester.getRect(card).center), isTrue);
        expect(card.hitTestable(), findsOneWidget);
      }
      // Grade 6 eras stay hidden when the switch is off.
      for (final era in allEras.where((e) => e.grade == 6)) {
        expect(find.byKey(EraSelectionScreen.cardKey(era.id)), findsNothing);
        expect(find.text(era.name), findsNothing);
      }
    });
  }
}
