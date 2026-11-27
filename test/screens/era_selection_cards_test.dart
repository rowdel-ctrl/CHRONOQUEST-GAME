// The era shelf: a book for each era. The front book is closed (its cover shows the number,
// the boss, the full name and a pill that says to open it) with the neighbours tilted away
// behind it; a tap opens it to a spread (the left page tells the era, the right shows the
// progress and the gold button). A locked book is chained shut. Arrows, a tap on a neighbour
// and a swipe move along the shelf; the dots show every era. A finished era has a star; a
// locked one a lock and a line saying what to finish. A book whose boss just fell is
// unchained once.
import 'dart:async';

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
import 'package:chronoquest/services/storage_service.dart';
import 'package:chronoquest/utils/book_unlock.dart';
import 'package:chronoquest/widgets/character_portrait.dart';
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
  _FakeUnlock(super.value);
  @override
  Future<void> set(bool value) async => state = value;
}

Future<void> _open(
  WidgetTester tester, {
  Map<String, int> done = const {},
  Set<String> bossDown = const {},
  Size size = const Size(732, 320),
  bool animations = false,
  bool unlockAll = false,
  List<String>? landedOn,
  Duration settle = const Duration(milliseconds: 400),
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
      unlockAllProvider.overrideWith((ref) => _FakeUnlock(unlockAll)),
      badgeProvider.overrideWith((ref) => BadgeNotifier(payCoins: (_) {})),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pump();
  await tester.pump(settle);
}

final _grade5 = allEras.where((e) => e.grade == 5).toList();

String _assetOf(Image i) => (i.image as AssetImage).assetName;

Iterable<String> _assetsIn(WidgetTester tester, Finder within) => tester
    .widgetList<Image>(
        find.descendant(of: within, matching: find.byType(Image)))
    .map(_assetOf);

/// The cover of an era's book (it is only there while the book is closed).
Finder _cover(int i) => find.byKey(EraSelectionScreen.cardKey(_grade5[i].id));

/// How wide a cover is drawn on screen: the front book is wider than a neighbour.
double _width(WidgetTester tester, int i) => tester.getRect(_cover(i)).width;

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byKey(EraSelectionScreen.nextKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _prev(WidgetTester tester) async {
  await tester.tap(find.byKey(EraSelectionScreen.prevKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

/// Lets time pass in steps of a tenth of a second, so the books glide and the timers of the chain
/// break fire the way they do on a phone (one long pump draws only one frame at the end).
Future<void> _advance(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Taps the cover of the front book and lets the book open.
Future<void> _openFront(WidgetTester tester, int i) async {
  await tester.tapAt(tester.getCenter(_cover(i)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1300));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // The mark lives in memory here (there is no storage in a widget test).
  setUp(StorageService.resetPendingBookForTesting);

  group('the front book', () {
    testWidgets(
        'starts on the era that is next to play, with its number, boss, full name and a pill to open it',
        (tester) async {
      await _open(tester);
      final first = _grade5[0];

      expect(_width(tester, 0), greaterThan(_width(tester, 1)),
          reason: 'the first era is in front');
      expect(find.byKey(EraSelectionScreen.prevKey), findsNothing,
          reason: 'nothing before the first');
      final cover = _cover(0);
      expect(
          find.descendant(
              of: cover,
              matching: find.text('KABANATA ${eraNumberFor(first.id)}')),
          findsOneWidget);
      expect(find.descendant(of: cover, matching: find.text(first.name)),
          findsOneWidget,
          reason: 'the full name');
      expect(_assetsIn(tester, cover),
          contains('assets/bosses/${first.bossName}_idle.png'));
      expect(
          find.descendant(
              of: cover, matching: find.text('PINDUTIN PARA BUKSAN')),
          findsOneWidget);
      expect(find.byKey(EraSelectionScreen.playKey), findsNothing,
          reason: 'the gold button is on the open book');
    });

    testWidgets(
        'a tap opens the book: the left page tells the era, the right shows the progress and MAGLARO',
        (tester) async {
      await _open(tester, done: {'pre-colonial': 4}, animations: true);
      final levels = _grade5[0].levels.length;
      await _openFront(tester, 0);

      expect(_cover(0), findsNothing, reason: 'the cover has turned away');
      expect(find.text('PROGRESO'), findsWidgets);
      expect(find.byKey(EraSelectionScreen.playKey), findsOneWidget);
      expect(find.text('Level 5 na ang susunod · 4 ng $levels'), findsWidgets);
      final bar = find.byKey(EraSelectionScreen.progressKey(_grade5[0].id));
      expect(bar, findsOneWidget);
      final fill = tester.widget<FractionallySizedBox>(find.descendant(
          of: bar, matching: find.byType(FractionallySizedBox)));
      expect(fill.widthFactor, closeTo(4 / levels, 0.001));
      expect(find.byKey(EraSelectionScreen.prevKey), findsNothing,
          reason: 'the arrows wait while a book is open');
      expect(find.byKey(EraSelectionScreen.nextKey), findsNothing);
    });

    testWidgets(
        'the back chip closes an open book, and a tap on a closed one opens it again',
        (tester) async {
      await _open(tester, animations: true);
      await _openFront(tester, 0);
      expect(find.byKey(EraSelectionScreen.playKey), findsOneWidget);

      await tester.tap(find.byTooltip('Bumalik'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1300));
      expect(find.byKey(EraSelectionScreen.playKey), findsNothing);
      expect(_cover(0), findsOneWidget);
      expect(find.byKey(EraSelectionScreen.nextKey), findsOneWidget,
          reason: 'the arrows are back');
    });

    testWidgets(
        'a finished era has a star on its cover, says Tapos na and offers BALIKAN',
        (tester) async {
      await _open(tester,
          done: {'pre-colonial': 10},
          bossDown: {'pre-colonial'},
          animations: true);
      // The next era is the one in front; go back to the finished one.
      await _prev(tester);
      final levels = _grade5[0].levels.length;

      expect(_assetsIn(tester, _cover(0)), contains('assets/ui/star_full.png'));
      await _openFront(tester, 0);
      expect(find.text('Tapos na · $levels ng $levels level'), findsWidgets);
      expect(
          find.descendant(
              of: find.byKey(EraSelectionScreen.playKey),
              matching: find.text('BALIKAN')),
          findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(EraSelectionScreen.playKey),
              matching: find.text('MAGLARO')),
          findsNothing);
    });

    testWidgets(
        'a locked era is chained: a lock, a dark boss and what to finish first',
        (tester) async {
      await _open(tester);
      await _next(tester);

      expect(_assetsIn(tester, _cover(1)), contains('assets/ui/lock_icon.png'));
      expect(_assetsIn(tester, _cover(1)),
          contains('assets/bosses/${_grade5[1].bossName}_idle.png'));
      expect(
          find.descendant(of: _cover(1), matching: find.byType(ColorFiltered)),
          findsWidgets,
          reason: 'the boss is a dark shape');
      final note =
          tester.widget<Text>(find.byKey(EraSelectionScreen.lockedNoteKey));
      expect(note.textSpan!.toPlainText(),
          'Tapusin muna ang ${_grade5[0].name} para mabuksan ito.');
      expect(
          find.descendant(
              of: _cover(1), matching: find.text('PINDUTIN PARA BUKSAN')),
          findsNothing);
    });
  });

  group('moving along the shelf', () {
    testWidgets('the arrows step one book at a time and stop at the ends',
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
      await tester.tapAt(tester.getCenter(_cover(1)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(_width(tester, 1), greaterThan(_width(tester, 0)));
    });

    testWidgets('a swipe to the left goes on, a swipe to the right goes back',
        (tester) async {
      await _open(tester);
      await tester.fling(
          find.byType(EraSelectionScreen), const Offset(-300, 0), 1200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(_width(tester, 1), greaterThan(_width(tester, 0)));

      await tester.fling(
          find.byType(EraSelectionScreen), const Offset(300, 0), 1200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
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
      await _openFront(tester, 1);
      expect(
          find.text(
              'Level 4 na ang susunod · 3 ng ${_grade5[1].levels.length}'),
          findsWidgets);
    });
  });

  testWidgets('the screen has few words: the era names and one title',
      (tester) async {
    await _open(tester);

    expect(find.text('PANAHON'), findsOneWidget);
    expect(find.text('PILIIN ANG PANAHON'), findsNothing);
    expect(find.text(_grade5[0].subtitle), findsNothing,
        reason: 'no English subtitle');
    expect(find.text('Rodel'), findsNothing, reason: 'no name line');
    expect(find.text('1240'), findsNothing,
        reason: 'the score lives on the profile, not here');
    expect(find.byType(CharacterPortrait), findsNothing,
        reason: 'no hero face at the bottom');
    expect(find.textContaining('pts'), findsNothing);
    expect(find.text('TINDAHAN'), findsNothing,
        reason: 'the shop is only the small cart chip here');
    expect(find.byTooltip('Tindahan'), findsOneWidget);
  });

  group('tapping', () {
    testWidgets(
        'MAGLARO on an open book goes to the levels (the lesson comes with each level)',
        (tester) async {
      final landed = <String>[];
      await _open(tester, landedOn: landed, animations: true);
      await _openFront(tester, 0);

      await tester.tap(find.byKey(EraSelectionScreen.playKey));
      await tester.pumpAndSettle(const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
      expect(landed, ['/level-select/${_grade5[0].id}']);
    });

    testWidgets('an era in progress goes to its levels too', (tester) async {
      final landed = <String>[];
      await _open(tester,
          done: {'pre-colonial': 4}, landedOn: landed, animations: true);
      await _openFront(tester, 0);

      await tester.tap(find.byKey(EraSelectionScreen.playKey));
      await tester.pumpAndSettle(const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
      expect(landed, ['/level-select/${_grade5[0].id}']);
    });

    testWidgets('a finished era goes to its levels (BALIKAN)', (tester) async {
      final landed = <String>[];
      await _open(tester,
          done: {'pre-colonial': 10},
          bossDown: {'pre-colonial'},
          landedOn: landed,
          animations: true);
      await _prev(tester);
      await _openFront(tester, 0);

      await tester.tap(find.byKey(EraSelectionScreen.playKey));
      await tester.pumpAndSettle(const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
      expect(landed, ['/level-select/${_grade5[0].id}']);
    });

    testWidgets('a chained book does not open, it only wobbles',
        (tester) async {
      final landed = <String>[];
      await _open(tester, landedOn: landed, animations: true);
      await _next(tester);

      await tester.tapAt(tester.getCenter(_cover(1)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(landed, isEmpty);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(EraSelectionScreen.playKey), findsNothing,
          reason: 'still shut');
      expect(_cover(1), findsOneWidget);
    });
  });

  testWidgets(
      'the front book pulses its pill, and nothing moves when the phone removes animations',
      (tester) async {
    await _open(tester, animations: false);
    expect(tester.hasRunningAnimations, isFalse);
  });

  for (final size in const [Size(732, 320), Size(640, 360), Size(400, 700)]) {
    testWidgets(
        'fits ${size.width.toInt()}x${size.height.toInt()} on every book, closed and open',
        (tester) async {
      await _open(tester,
          size: size, animations: true, done: {'pre-colonial': 5});
      await tester.pump(const Duration(seconds: 1));

      for (var i = 0; i < _grade5.length; i++) {
        expect(tester.takeException(), isNull, reason: 'book $i');
        final r = tester.getRect(_cover(i));
        expect(r.top, greaterThanOrEqualTo(0));
        expect(r.bottom, lessThanOrEqualTo(size.height), reason: 'book $i');
        if (i == 0) {
          expect(r.left, greaterThanOrEqualTo(0),
              reason: 'the front book is all on screen');
          expect(r.right, lessThanOrEqualTo(size.width));
        }
        if (i < _grade5.length - 1) {
          await _next(tester);
        }
      }
      // Open the last one that is open (the first): the whole spread is on screen.
      while (find.byKey(EraSelectionScreen.prevKey).evaluate().isNotEmpty) {
        await _prev(tester);
      }
      await _openFront(tester, 0);
      expect(tester.takeException(), isNull);
      final play = tester.getRect(find.byKey(EraSelectionScreen.playKey));
      expect(Offset.zero & size, containsRectOf(play),
          reason: 'the gold button is on screen');
    });
  }

  group('the chain break', () {
    Future<void> setUpUnlock(WidgetTester tester,
        {String mark = 'spanish',
        bool unlockAll = false,
        bool animations = true}) async {
      unawaited(StorageService.setPendingBookUnlock(mark));
      await _open(tester,
          done: {'pre-colonial': 10},
          bossDown: {'pre-colonial'},
          animations: animations,
          unlockAll: unlockAll,
          settle: const Duration(milliseconds: 50));
    }

    testWidgets(
        'a boss that just fell: the finished book first, then the next one, chained, then its chains break once',
        (tester) async {
      await setUpUnlock(tester);
      // The shelf turns to the finished book first (the books glide for about half a second).
      await _advance(tester, 550);

      expect(find.byKey(EraSelectionScreen.unlockLayerKey), findsOneWidget,
          reason: 'the break is playing');
      expect(_width(tester, 0), greaterThan(_width(tester, 1)),
          reason: 'the finished book is in front first');

      // The shelf moves on to the book that is about to come free.
      await _advance(tester, 1500);
      expect(_width(tester, 1), greaterThan(_width(tester, 0)));
      expect(find.byKey(EraSelectionScreen.bannerKey), findsNothing,
          reason: 'not yet');

      // The lock opens and the banner pops up.
      await _advance(tester, 1800);
      await _advance(tester, 400);
      expect(find.byKey(EraSelectionScreen.bannerKey), findsOneWidget);
      expect(find.text('BAGONG PANAHON!'), findsOneWidget);

      // It ends by itself and the mark is gone, so it plays once.
      await _advance(tester, 3000);
      await _advance(tester, 1000);
      expect(find.byKey(EraSelectionScreen.unlockLayerKey), findsNothing);
      expect(StorageService.getPendingBookUnlock(), isNull);
      expect(find.byKey(EraSelectionScreen.bannerKey), findsNothing);
    });

    testWidgets(
        'while it plays the books cannot be moved or opened, and a tap skips the rest',
        (tester) async {
      await setUpUnlock(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(EraSelectionScreen.unlockLayerKey));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(EraSelectionScreen.unlockLayerKey), findsNothing);
      expect(StorageService.getPendingBookUnlock(), isNull);
    });

    testWidgets('with nothing waiting there is no break', (tester) async {
      await _open(tester,
          done: {'pre-colonial': 10},
          bossDown: {'pre-colonial'},
          animations: true);
      expect(find.byKey(EraSelectionScreen.unlockLayerKey), findsNothing);
    });

    testWidgets(
        'a phone set to remove animations opens the book at once and clears the mark',
        (tester) async {
      await setUpUnlock(tester, animations: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(EraSelectionScreen.unlockLayerKey), findsNothing);
      expect(StorageService.getPendingBookUnlock(), isNull);
    });

    testWidgets(
        'a mark for a book that is not open (or not on this shelf) is dropped, not played',
        (tester) async {
      unawaited(StorageService.setPendingBookUnlock('nationalism'));
      await _open(tester,
          done: {'pre-colonial': 10},
          bossDown: {'pre-colonial'},
          animations: true);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(EraSelectionScreen.unlockLayerKey), findsNothing);
      expect(StorageService.getPendingBookUnlock(), isNull);
    });

    testWidgets(
        'the tester build can replay the break on a book that is already open (Test Mode on)',
        (tester) async {
      await setUpUnlock(tester,
          mark: '${BookUnlock.replayPrefix}spanish', unlockAll: true);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(EraSelectionScreen.unlockLayerKey), findsOneWidget);
      await tester.tap(find.byKey(EraSelectionScreen.unlockLayerKey));
      await _advance(tester, 400);
      await _advance(tester, 400);
      expect(StorageService.getPendingBookUnlock(), isNull);
    });

    testWidgets(
        'the chains are drawn on a locked book and only while it is locked',
        (tester) async {
      await _open(tester, animations: true);
      await _next(tester);
      final chains = find.byWidgetPredicate((w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == '_ChainsPainter');
      // The second book is in front and chained, and so is the third beside it.
      expect(chains, findsNWidgets(2));

      await _prev(tester);
      expect(chains, findsOneWidget,
          reason:
              'the first book is free; only the second beside it is chained');
    });
  });
}

/// A matcher: the rectangle holds [inner] completely.
Matcher containsRectOf(Rect inner) => predicate<Rect>(
    (outer) =>
        outer.contains(inner.topLeft) && outer.contains(inner.bottomRight),
    'holds $inner');
