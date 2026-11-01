// The era cards: a number, an enemy, the name and a pip per level. The open card
// that is next to play stands forward and glows; a finished one has a star; a
// locked one is grey with a lock and does nothing when tapped.
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
  _FakeGame() : super(GameState(hearts: const HeartsState(count: 3, regenStartMs: null)));
  @override
  Duration? get heartCountdown => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuth()
      : super(AuthState(
          student: Student.fromJson({'id': 's', 'name': 'Rodel', 'gradeLevel': 'grade5', 'score': 1240}),
          isLoggedIn: true,
        ));
  @override
  Future<void> refreshProfile() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// [done] is how many levels of each era are finished; [bossDown] the finished eras.
class _FakeProgress extends StateNotifier<ProgressState> implements ProgressNotifier {
  _FakeProgress(this.done, this.bossDown) : super(const ProgressState());
  final Map<String, int> done;
  final Set<String> bossDown;
  @override
  Future<void> loadProgress() async {}
  @override
  EraProgress getEraProgress(String eraId) =>
      EraProgress(eraId: eraId, levelsCompleted: done[eraId] ?? 0, bossDefeated: bossDown.contains(eraId));
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

/// Where each card's number sits: the card itself does not move, its picture does.
List<double> _numberTops(WidgetTester tester) => [
      for (final e in _grade5)
        tester
            .getTopLeft(find.descendant(
              of: find.byKey(EraSelectionScreen.cardKey(e.id)),
              matching: find.text('${eraNumberFor(e.id)}'),
            ))
            .dy,
    ];

String _assetOf(Image i) => (i.image as AssetImage).assetName;

Iterable<String> _assetsIn(WidgetTester tester, Finder within) => tester
    .widgetList<Image>(find.descendant(of: within, matching: find.byType(Image)))
    .map(_assetOf);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('three cards, one per era of the grade, each with its number, name and enemy',
      (tester) async {
    await _open(tester);

    for (var i = 0; i < _grade5.length; i++) {
      final era = _grade5[i];
      final card = find.byKey(EraSelectionScreen.cardKey(era.id));
      expect(card, findsOneWidget, reason: era.id);
      expect(find.descendant(of: card, matching: find.text('${eraNumberFor(era.id)}')), findsOneWidget);
      expect(find.descendant(of: card, matching: find.text(era.name)), findsOneWidget);
      expect(_assetsIn(tester, card), contains(eraSprite(era.id)), reason: '${era.id} shows an enemy');
    }
  });

  testWidgets('each card has a pip for every level, filled for the levels done', (tester) async {
    await _open(tester, done: {'pre-colonial': 3});
    final first = _grade5.first;

    for (final era in _grade5) {
      for (var i = 0; i < era.levels.length; i++) {
        expect(find.byKey(EraSelectionScreen.pipKey(era.id, i)), findsOneWidget, reason: '${era.id} pip $i');
      }
      expect(find.byKey(EraSelectionScreen.pipKey(era.id, era.levels.length)), findsNothing);
    }
    Color? colorOf(String id, int i) =>
        (tester.widget<Container>(find.byKey(EraSelectionScreen.pipKey(id, i))).decoration as BoxDecoration).color;
    expect(colorOf(first.id, 2), AppColors.success, reason: 'the third level is done');
    expect(colorOf(first.id, 3), isNot(AppColors.success), reason: 'the fourth is not');
  });

  testWidgets('the screen has few words: the era names, one title, a number', (tester) async {
    await _open(tester);

    expect(find.text('PANAHON'), findsOneWidget);
    expect(find.text('PILIIN ANG PANAHON'), findsNothing);
    for (final era in _grade5) {
      expect(find.text(era.subtitle), findsNothing, reason: 'no English subtitle');
    }
    expect(find.textContaining('levels'), findsNothing);
    expect(find.text('Rodel'), findsNothing, reason: 'a face and a score, not a name line');
    expect(find.text('1240'), findsOneWidget);
    expect(find.textContaining('pts'), findsNothing);
  });

  group('which card is open', () {
    testWidgets('a new student: the first is open and stands forward; the others are locked',
        (tester) async {
      await _open(tester);
      final top = _numberTops(tester);

      expect(top[0], top[1] - 8, reason: 'the open card stands 8 forward');
      expect(top[1], top[2]);

      expect(_assetsIn(tester, find.byKey(EraSelectionScreen.cardKey(_grade5[0].id))),
          isNot(contains('assets/ui/lock_icon.png')));
      for (final e in _grade5.skip(1)) {
        expect(_assetsIn(tester, find.byKey(EraSelectionScreen.cardKey(e.id))), contains('assets/ui/lock_icon.png'),
            reason: e.id);
      }
    });

    testWidgets('a finished era has a star and the next one is open', (tester) async {
      await _open(tester, done: {'pre-colonial': 10}, bossDown: {'pre-colonial'});

      expect(_assetsIn(tester, find.byKey(EraSelectionScreen.cardKey(_grade5[0].id))),
          contains('assets/ui/star_full.png'));
      final top = _numberTops(tester);
      expect(top[1], top[0] - 8, reason: 'now the second era stands forward');
      expect(_assetsIn(tester, find.byKey(EraSelectionScreen.cardKey(_grade5[1].id))),
          isNot(contains('assets/ui/lock_icon.png')));
    });
  });

  group('tapping', () {
    testWidgets('an era not started goes to its history', (tester) async {
      final landed = <String>[];
      await _open(tester, landedOn: landed);

      await tester.tap(find.byKey(EraSelectionScreen.cardKey(_grade5[0].id)));
      await tester.pumpAndSettle();
      expect(landed, ['/background/${_grade5[0].id}']);
    });

    testWidgets('an era in progress goes to its levels', (tester) async {
      final landed = <String>[];
      await _open(tester, done: {'pre-colonial': 4}, landedOn: landed);

      await tester.tap(find.byKey(EraSelectionScreen.cardKey(_grade5[0].id)));
      await tester.pumpAndSettle();
      expect(landed, ['/level-select/${_grade5[0].id}']);
    });

    testWidgets('a locked era does nothing', (tester) async {
      final landed = <String>[];
      await _open(tester, landedOn: landed);

      await tester.tap(find.byKey(EraSelectionScreen.cardKey(_grade5[2].id)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(landed, isEmpty);
      expect(find.byType(EraSelectionScreen), findsOneWidget);
    });
  });

  testWidgets('the open card breathes, and nothing moves when the phone removes animations',
      (tester) async {
    await _open(tester, animations: true);
    expect(tester.hasRunningAnimations, isTrue);

    await _open(tester, animations: false);
    expect(tester.hasRunningAnimations, isFalse);
  });

  for (final size in const [Size(732, 320), Size(640, 360), Size(400, 700)]) {
    testWidgets('fits ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await _open(tester, size: size, animations: true, done: {'pre-colonial': 5});
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      for (final era in _grade5) {
        final card = find.byKey(EraSelectionScreen.cardKey(era.id));
        final r = tester.getRect(card);
        expect(r.right, lessThanOrEqualTo(size.width), reason: era.id);
        expect(r.bottom, lessThanOrEqualTo(size.height), reason: era.id);
        expect(card.hitTestable(), findsOneWidget, reason: era.id);
      }
    });
  }
}
