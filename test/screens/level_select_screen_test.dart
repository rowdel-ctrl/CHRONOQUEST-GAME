// The levels of an era as a winding path: gold nodes with stars for the levels
// done, the hero on the next one, locked ones after it, the boss at the end.
import 'dart:io';

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/providers/unlock_all_provider.dart';
import 'package:chronoquest/screens/game/level_node.dart';
import 'package:chronoquest/screens/game/level_path.dart';
import 'package:chronoquest/screens/game/level_select_screen.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame(int hearts, String hero)
      : super(GameState(
          selectedCharacterId: hero,
          hearts: HeartsState(count: hearts, regenStartMs: null),
        ));
  @override
  bool get canStartLevel => state.hearts.count > 0;
  @override
  Duration? get heartCountdown => null;
  @override
  void refreshHearts() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUnlock extends StateNotifier<bool> implements UnlockAllNotifier {
  _FakeUnlock(super.value);
  @override
  Future<void> set(bool value) async => state = value;
}

const _era = 'pre-colonial';
final _levels = getEraById(_era).levels.length; // 10

Future<void> _open(
  WidgetTester tester, {
  Map<int, int> done = const {},
  int hearts = 3,
  bool unlockAll = false,
  String hero = 'rizal',
  Size size = const Size(732, 320),
  bool animations = false,
  List<String>? landedOn,
}) async {
  // Hive writes to a real file, which a test's fake clock would wait on forever.
  await tester.runAsync(() async {
    await StorageService.appBox.delete('levels_$_era');
    for (final e in done.entries) {
      await StorageService.saveLevelCompleted(_era, e.key, e.value);
    }
    await StorageService.markTutorialSeen();
  });
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
    GoRoute(path: '/', builder: (_, __) => const LevelSelectScreen(eraId: _era)),
    GoRoute(
      path: '/game/:eraId/:level',
      builder: (_, s) {
        landedOn?.add('/game/${s.pathParameters['eraId']}/${s.pathParameters['level']}');
        return const Scaffold(body: Text('game stand-in'));
      },
    ),
    GoRoute(path: '/era-selection', builder: (_, __) => const Scaffold(body: Text('eras stand-in'))),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      gameProvider.overrideWith((ref) => _FakeGame(hearts, hero)),
      unlockAllProvider.overrideWith((ref) => _FakeUnlock(unlockAll)),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

LevelNode _node(WidgetTester tester, int level) =>
    tester.widget<LevelNode>(find.byKey(LevelSelectScreen.nodeKey(level)));

String _assetOf(Image i) => (i.image as AssetImage).assetName;

void main() {
  final hiveDir = Directory.systemTemp.createTempSync('chronoquest_levelselect_test_').path;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    Hive.init(hiveDir);
    await Hive.openBox('chronoquest');
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      Directory(hiveDir).deleteSync(recursive: true);
    } catch (_) {}
  });

  group('the path', () {
    test('wide: runs left to right across the screen, swaying a little', () {
      final pts = levelPathPoints(10, const Size(732, 260), vertical: false);

      expect(pts.length, 10);
      for (var i = 1; i < pts.length; i++) {
        expect(pts[i].dx, greaterThan(pts[i - 1].dx), reason: 'always moving right');
      }
      expect(pts.first.dx, greaterThanOrEqualTo(40));
      expect(pts.last.dx, lessThanOrEqualTo(732 - 40));
      final ys = pts.map((p) => p.dy);
      expect(ys.reduce((a, b) => a > b ? a : b) - ys.reduce((a, b) => a < b ? a : b), greaterThan(10));
    });

    test('wide: a short era (5 levels) is spread over the same width', () {
      final pts = levelPathPoints(5, const Size(732, 260), vertical: false);
      expect(pts.last.dx - pts.first.dx, closeTo(732 - 88, 0.01));
    });

    test('narrow: runs top to bottom, an even step apart, inside the width', () {
      final pts = levelPathPoints(10, const Size(400, 600), vertical: true);

      for (var i = 1; i < pts.length; i++) {
        expect(pts[i].dy - pts[i - 1].dy, levelPathStep);
        expect(pts[i].dx, inInclusiveRange(30, 370));
      }
      expect(levelPathHeight(10), greaterThan(pts.last.dy), reason: 'room for the last one and its stars');
    });

    test('one level, none', () {
      expect(levelPathPoints(0, const Size(700, 300), vertical: false), isEmpty);
      expect(levelPathPoints(1, const Size(700, 300), vertical: false).single.dx, 350);
    });
  });

  group('the levels', () {
    testWidgets('a new student: level 1 is next, the rest are locked, the boss last', (tester) async {
      await _open(tester);

      expect(_node(tester, 1).state, LevelNodeState.current);
      for (var l = 2; l < _levels; l++) {
        expect(_node(tester, l).state, LevelNodeState.locked, reason: 'level $l');
      }
      expect(_node(tester, _levels).state, LevelNodeState.locked);
      expect(_node(tester, _levels).isBoss, isTrue);
      expect(_node(tester, 1).isBoss, isFalse);
    });

    testWidgets('levels done are gold with their stars; the next one after them is current',
        (tester) async {
      await _open(tester, done: {1: 3, 2: 1, 3: 2});

      expect(_node(tester, 1).state, LevelNodeState.done);
      expect(_node(tester, 2).state, LevelNodeState.done);
      expect(_node(tester, 3).state, LevelNodeState.done);
      expect(_node(tester, 4).state, LevelNodeState.current);
      expect(_node(tester, 5).state, LevelNodeState.locked);
      expect(_node(tester, 2).stars, 1);

      final stars = tester
          .widgetList<Image>(find.descendant(
              of: find.byKey(LevelSelectScreen.nodeKey(1)), matching: find.byType(Image)))
          .map(_assetOf);
      expect(stars.where((a) => a == 'assets/ui/star_full.png').length, 3);
      final onTwo = tester
          .widgetList<Image>(find.descendant(
              of: find.byKey(LevelSelectScreen.nodeKey(2)), matching: find.byType(Image)))
          .map(_assetOf)
          .toList();
      expect(onTwo.where((a) => a == 'assets/ui/star_full.png').length, 1);
      expect(onTwo.where((a) => a == 'assets/ui/star_empty.png').length, 2);
    });

    testWidgets('the boss opens after the levels before it', (tester) async {
      await _open(tester, done: {for (var l = 1; l < _levels; l++) l: 3});
      expect(_node(tester, _levels).state, LevelNodeState.current);
    });

    testWidgets('everything finished: no level is "next"', (tester) async {
      await _open(tester, done: {for (var l = 1; l <= _levels; l++) l: 3});
      for (var l = 1; l <= _levels; l++) {
        expect(_node(tester, l).state, LevelNodeState.done);
      }
    });

    testWidgets('with the testing switch on, every level is open and the first unfinished is next',
        (tester) async {
      await _open(tester, unlockAll: true, done: {1: 3});

      expect(_node(tester, 1).state, LevelNodeState.done);
      expect(_node(tester, 2).state, LevelNodeState.current);
      expect(_node(tester, 7).state, LevelNodeState.open);
      expect(_node(tester, _levels).state, LevelNodeState.open);
    });
  });

  testWidgets('the student\'s own hero stands on the level to play next, and only there', (tester) async {
    await _open(tester, done: {1: 3}, hero: 'bonifacio');

    final heroes = [
      for (var l = 1; l <= _levels; l++)
        tester
            .widgetList<Image>(find.descendant(
                of: find.byKey(LevelSelectScreen.nodeKey(l)), matching: find.byType(Image)))
            .map(_assetOf)
            .where((a) => a.startsWith('assets/characters/'))
            .length,
    ];
    expect(heroes[1], 1, reason: 'level 2 is next');
    expect(heroes.where((n) => n > 0).length, 1, reason: 'one hero');
    expect(
      tester
          .widgetList<Image>(find.descendant(
              of: find.byKey(LevelSelectScreen.nodeKey(2)), matching: find.byType(Image)))
          .map(_assetOf),
      contains('assets/characters/bonifacio_walk_1.png'),
    );
  });

  group('the screen has few words', () {
    testWidgets('the era name, and numbers: no "Level n" labels, no "Levels Tapos" line', (tester) async {
      await _open(tester, done: {1: 3, 2: 2});

      expect(find.text(getEraById(_era).name.toUpperCase()), findsOneWidget);
      expect(find.textContaining('Level '), findsNothing);
      expect(find.textContaining('Tapos'), findsNothing);
      expect(find.text('BOSS'), findsNothing, reason: 'the boss is a skull');
    });
  });

  group('tapping', () {
    testWidgets('the next level starts it', (tester) async {
      final landed = <String>[];
      await _open(tester, done: {1: 3}, landedOn: landed);

      await tester.tap(find.byKey(LevelSelectScreen.nodeKey(2)));
      await tester.pumpAndSettle();
      expect(landed, ['/game/$_era/2']);
    });

    testWidgets('a finished level can be played again', (tester) async {
      final landed = <String>[];
      await _open(tester, done: {1: 3}, landedOn: landed);

      await tester.tap(find.byKey(LevelSelectScreen.nodeKey(1)));
      await tester.pumpAndSettle();
      expect(landed, ['/game/$_era/1']);
    });

    testWidgets('a locked level does nothing', (tester) async {
      final landed = <String>[];
      await _open(tester, landedOn: landed);

      await tester.tap(find.byKey(LevelSelectScreen.nodeKey(5)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(landed, isEmpty);
    });

    testWidgets('with no hearts it says so instead of starting', (tester) async {
      final landed = <String>[];
      await _open(tester, hearts: 0, landedOn: landed);

      await tester.tap(find.byKey(LevelSelectScreen.nodeKey(1)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(landed, isEmpty);
      expect(find.text('Wala nang Puso'), findsOneWidget);
    });

    testWidgets('each node is a 48 pixel target at least', (tester) async {
      await _open(tester);
      for (var l = 1; l <= _levels; l++) {
        final size = tester.getSize(find.byKey(LevelSelectScreen.nodeKey(l)));
        expect(size.width, greaterThanOrEqualTo(48), reason: 'level $l');
        expect(size.height, greaterThanOrEqualTo(48), reason: 'level $l');
      }
    });
  });

  testWidgets('the next level pulses, and nothing moves when the phone removes animations', (tester) async {
    await _open(tester, animations: true);
    expect(tester.hasRunningAnimations, isTrue);

    await _open(tester, animations: false);
    expect(tester.hasRunningAnimations, isFalse);
  });

  for (final size in const [Size(732, 320), Size(640, 360)]) {
    testWidgets('fits ${size.width.toInt()}x${size.height.toInt()}: every node on screen, no scrolling',
        (tester) async {
      await _open(tester, size: size, done: {1: 3, 2: 2, 3: 1}, animations: true);
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsNothing, reason: 'a wide screen needs no scrolling');
      for (var l = 1; l <= _levels; l++) {
        final r = tester.getRect(find.byKey(LevelSelectScreen.nodeKey(l)));
        expect(r.left, greaterThanOrEqualTo(0), reason: 'level $l');
        expect(r.right, lessThanOrEqualTo(size.width), reason: 'level $l');
        expect(r.bottom, lessThanOrEqualTo(size.height), reason: 'level $l');
        expect(find.byKey(LevelSelectScreen.nodeKey(l)).hitTestable(), findsOneWidget, reason: 'level $l');
      }
    });
  }

  testWidgets('a narrow phone runs the path downwards and scrolls to the level to play next',
      (tester) async {
    await _open(tester, size: const Size(400, 700), done: {for (var l = 1; l <= 7; l++) l: 3});
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    // The next level (8) is on screen, though the path is taller than the room.
    final r = tester.getRect(find.byKey(LevelSelectScreen.nodeKey(8)));
    expect(r.top, greaterThanOrEqualTo(0));
    expect(r.bottom, lessThanOrEqualTo(700));
    expect(find.byKey(LevelSelectScreen.nodeKey(8)).hitTestable(), findsOneWidget);
  });
}
