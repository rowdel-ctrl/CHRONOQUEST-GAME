// The era carousel: one big card at a time (number, boss, full name, a progress
// bar, a line and a gold button) with the neighbours peeking in on each side.
// Arrows, a tap on a neighbour and a swipe move it; the dots show every era. A
// finished era has a star; a locked one a lock and a line saying what to finish.
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
          student: Student.fromJson({
            'id': 's',
            'name': 'Rodel',
            'gradeLevel': 'grade5',
            'score': 1240
          }),
          isLoggedIn: true,
        ));
  @override
  Future<void> refreshProfile() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// [done] is how many levels of each era are finished; [bossDown] the finished eras.
class _FakeProgress extends StateNotifier<ProgressState>
    implements ProgressNotifier {
  _FakeProgress(this.done, this.bossDown) : super(const ProgressState());
  final Map<String, int> done;
  final Set<String> bossDown;
  @override
  Future<void> loadProgress() async {}
  @override
  EraProgress getEraProgress(String eraId) => EraProgress(
      eraId: eraId,
      levelsCompleted: done[eraId] ?? 0,
      bossDefeated: bossDown.contains(eraId));
  @override
  bool isEraUnlocked(String eraId, List<String> visibleEraIds) {
    final i = visibleEraIds.indexOf(eraId);
    return i <= 0 || getEraProgress(visibleEraIds[i - 1]).isCompleted;
  }

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
  Map<String, int> done = const {},
  Set<String> bossDown = const {},
  Size size = const Size(732, 320),
  bool animations = false,
  List<String>? landedOn,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: !animations);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const EraSelectionScreen()),
    GoRoute(
      path: '/background/:eraId',
      builder: (_, s) {
        landedOn?.add('/background/${s.pathParameters['eraId']}');
        return const Scaffold(body: Text('history stand-in'));
      },
    ),
    GoRoute(
      path: '/level-select/:eraId',
      builder: (_, s) {
        landedOn?.add('/level-select/${s.pathParameters['eraId']}');
        return const Scaffold(body: Text('levels stand-in'));
      },
    ),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      gameProvider.overrideWith((ref) => _FakeGame()),
      authProvider.overrideWith((ref) => _FakeAuth()),
      progressProvider.overrideWith((ref) => _FakeProgress(done, bossDown)),
      unlockAllProvider.overrideWith((ref) => _FakeUnlock()),
      badgeProvider.overrideWith((ref) => BadgeNotifier(payCoins: (_) {})),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

final _grade5 = allEras.where((e) => e.grade == 5).toList();

String _assetOf(Image i) => (i.image as AssetImage).assetName;

Iterable<String> _assetsIn(WidgetTester tester, Finder within) => tester
    .widgetList<Image>(
        find.descendant(of: within, matching: find.byType(Image)))
    .map(_assetOf);

Finder _card(int i) => find.byKey(EraSelectionScreen.cardKey(_grade5[i].id));

/// The width of a card: the big one is wider than a neighbour.
double _width(WidgetTester tester, int i) => tester.getSize(_card(i)).width;

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byKey(EraSelectionScreen.nextKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _prev(WidgetTester tester) async {
  await tester.tap(find.byKey(EraSelectionScreen.prevKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('the big card', () {
    testWidgets(
        'starts on the era that is next to play, with its number, boss, full name and a gold MAGLARO',
        (tester) async {
      await _open(tester);
      final first = _grade5[0];

      expect(_width(tester, 0), greaterThan(_width(tester, 1)),
          reason: 'the first era is in front');
      expect(find.byKey(EraSelectionScreen.prevKey), findsNothing,
          reason: 'nothing before the first');
      final card = _card(0);
      expect(
          find.descendant(
              of: card, matching: find.text('${eraNumberFor(first.id)}')),
          findsOneWidget);
      expect(find.descendant(of: card, matching: find.text(first.name)),
          findsOneWidget,
          reason: 'the full name');
      expect(_assetsIn(tester, card),
          contains('assets/bosses/${first.bossName}_idle.png'));
      expect(find.text('MAGLARO'), findsOneWidget);
      expect(find.text('BALIKAN'), findsNothing);
    });

    testWidgets(
        'a started era says which level is next and how many are done, with a bar',
        (tester) async {
      await _open(tester, done: {'pre-colonial': 4});
      final levels = _grade5[0].levels.length;

      expect(
          find.text('Level 5 na ang susunod · 4 ng $levels'), findsOneWidget);
      final bar = find.byKey(EraSelectionScreen.progressKey(_grade5[0].id));
      expect(bar, findsOneWidget);
      final fill = tester.widget<FractionallySizedBox>(find.descendant(
          of: bar, matching: find.byType(FractionallySizedBox)));
      expect(fill.widthFactor, closeTo(4 / levels, 0.001));
    });

    testWidgets('a finished era has a star, says Tapos na and offers BALIKAN',
        (tester) async {
      await _open(tester,
          done: {'pre-colonial': 10}, bossDown: {'pre-colonial'});
      // The next era is the one in front; go back to the finished one.
      await _prev(tester);
      final levels = _grade5[0].levels.length;

      expect(_assetsIn(tester, _card(0)), contains('assets/ui/star_full.png'));
      expect(find.text('Tapos na · $levels ng $levels level'), findsOneWidget);
      expect(find.text('BALIKAN'), findsOneWidget);
      expect(find.text('MAGLARO'), findsNothing);
    });

    testWidgets(
        'a locked era shows a lock, a dark boss and what to finish first',
        (tester) async {
      await _open(tester);
      await _next(tester);

      expect(_assetsIn(tester, _card(1)), contains('assets/ui/lock_icon.png'));
      expect(_assetsIn(tester, _card(1)),
          contains('assets/bosses/${_grade5[1].bossName}_idle.png'));
      expect(
          find.descendant(of: _card(1), matching: find.byType(ColorFiltered)),
          findsWidgets,
          reason: 'the boss is a dark shape');
      final note =
          tester.widget<Text>(find.byKey(EraSelectionScreen.lockedNoteKey));
      expect(note.textSpan!.toPlainText(),
          'Tapusin muna ang ${_grade5[0].name} para mabuksan ito.');
      expect(find.text('MAGLARO'), findsNothing);
      expect(find.byKey(EraSelectionScreen.progressKey(_grade5[1].id)),
          findsNothing);
    });
  });

  group('moving between the cards', () {
    testWidgets('the arrows step one card at a time and stop at the ends',
        (tester) async {
      await _open(tester);
      expect(find.byKey(EraSelectionScreen.prevKey), findsNothing);

      await _next(tester);
      expect(_width(tester, 1), greaterThan(_width(tester, 0)));
      expect(find.byKey(EraSelectionScreen.prevKey), findsOneWidget);

      await _next(tester);
      expect(_width(tester, 2), greaterThan(_width(tester, 1)));
      expect(find.byKey(EraSelectionScreen.nextKey), findsNothing,
          reason: 'nothing after the last');

      await _prev(tester);
      expect(_width(tester, 1), greaterThan(_width(tester, 2)));
    });

    testWidgets('a tap on a neighbour brings it to the front', (tester) async {
      await _open(tester);
      await tester.tap(_card(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_width(tester, 1), greaterThan(_width(tester, 0)));
    });

    testWidgets('a swipe to the left goes on, a swipe to the right goes back',
        (tester) async {
      await _open(tester);
      await tester.fling(_card(0), const Offset(-300, 0), 1200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_width(tester, 1), greaterThan(_width(tester, 0)));

      await tester.fling(_card(1), const Offset(300, 0), 1200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_width(tester, 0), greaterThan(_width(tester, 1)));
    });

    testWidgets(
        'the dots show every era and the one in front is a long gold pill',
        (tester) async {
      await _open(tester);
      double dotWidth(int i) =>
          tester.getSize(find.byKey(EraSelectionScreen.dotKey(i))).width;

      expect(find.byKey(EraSelectionScreen.dotKey(_grade5.length - 1)),
          findsOneWidget);
      expect(
          find.byKey(EraSelectionScreen.dotKey(_grade5.length)), findsNothing);
      expect(dotWidth(0), greaterThan(dotWidth(1)));
      await _next(tester);
      expect(dotWidth(1), greaterThan(dotWidth(0)));
      final pill = tester
          .widget<AnimatedContainer>(find.byKey(EraSelectionScreen.dotKey(1)));
      expect((pill.decoration as BoxDecoration).color, AppColors.accent);
    });

    testWidgets('it starts on the era in progress, not the first',
        (tester) async {
      await _open(tester,
          done: {'pre-colonial': 10, 'spanish': 3}, bossDown: {'pre-colonial'});
      expect(_width(tester, 1), greaterThan(_width(tester, 0)));
      expect(_width(tester, 1), greaterThan(_width(tester, 2)));
      expect(
          find.text(
              'Level 4 na ang susunod · 3 ng ${_grade5[1].levels.length}'),
          findsOneWidget);
    });
  });

  testWidgets('the screen has few words: the era names, one title, a score',
      (tester) async {
    await _open(tester);

    expect(find.text('PANAHON'), findsOneWidget);
    expect(find.text('PILIIN ANG PANAHON'), findsNothing);
    expect(find.text(_grade5[0].subtitle), findsNothing,
        reason: 'no English subtitle');
    expect(find.text('Rodel'), findsNothing,
        reason: 'a face and a score, not a name line');
    expect(find.text('1240'), findsOneWidget);
    expect(find.textContaining('pts'), findsNothing);
    expect(find.text('TINDAHAN'), findsNothing,
        reason: 'the shop is only the small cart chip here');
    expect(find.byTooltip('Tindahan'), findsOneWidget);
  });

  group('tapping the big card', () {
    testWidgets('an era not started goes to its history', (tester) async {
      final landed = <String>[];
      await _open(tester, landedOn: landed);

      await tester.tap(_card(0));
      await tester.pumpAndSettle();
      expect(landed, ['/background/${_grade5[0].id}']);
    });

    testWidgets('an era in progress goes to its levels', (tester) async {
      final landed = <String>[];
      await _open(tester, done: {'pre-colonial': 4}, landedOn: landed);

      await tester.tap(_card(0));
      await tester.pumpAndSettle();
      expect(landed, ['/level-select/${_grade5[0].id}']);
    });

    testWidgets('a finished era goes to its levels (BALIKAN)', (tester) async {
      final landed = <String>[];
      await _open(tester,
          done: {'pre-colonial': 10},
          bossDown: {'pre-colonial'},
          landedOn: landed);
      await _prev(tester);

      await tester.tap(find.byKey(EraSelectionScreen.playKey));
      await tester.pumpAndSettle();
      expect(landed, ['/level-select/${_grade5[0].id}']);
    });

    testWidgets('a locked era does nothing', (tester) async {
      final landed = <String>[];
      await _open(tester, landedOn: landed);
      await _next(tester);

      await tester.tap(_card(1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(landed, isEmpty);
      expect(find.byType(EraSelectionScreen), findsOneWidget);
    });
  });

  testWidgets(
      'the card next to play breathes, and nothing moves when the phone removes animations',
      (tester) async {
    await _open(tester, animations: true);
    expect(tester.hasRunningAnimations, isTrue);

    await _open(tester, animations: false);
    expect(tester.hasRunningAnimations, isFalse);
  });

  for (final size in const [Size(732, 320), Size(640, 360), Size(400, 700)]) {
    testWidgets(
        'fits ${size.width.toInt()}x${size.height.toInt()} on every card',
        (tester) async {
      await _open(tester,
          size: size, animations: true, done: {'pre-colonial': 5});
      await tester.pump(const Duration(seconds: 1));

      for (var i = 0; i < _grade5.length; i++) {
        expect(tester.takeException(), isNull, reason: 'card $i');
        final finder = _card(i);
        final r = tester.getRect(finder);
        expect(r.top, greaterThanOrEqualTo(0));
        expect(r.bottom, lessThanOrEqualTo(size.height), reason: 'card $i');
        expect(r.left, greaterThanOrEqualTo(0),
            reason: 'the big card is all on screen');
        expect(r.right, lessThanOrEqualTo(size.width));
        expect(finder.hitTestable(), findsOneWidget);
        if (i < _grade5.length - 1) {
          await tester.tap(find.byKey(EraSelectionScreen.nextKey));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
        }
      }
    });
  }
}
