// The Profile: the student's hero and name, two totals as round chips, an era
// number with a pip per level (the real number of levels), the power-ups carried
// and two tiles, with no overflow on a short landscape phone.
import 'dart:io';

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/era_progress.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/models/student.dart';
import 'package:chronoquest/providers/auth_provider.dart';
import 'package:chronoquest/providers/badge_provider.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/providers/progress_provider.dart';
import 'package:chronoquest/providers/unlock_all_provider.dart';
import 'package:chronoquest/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import '../fixtures/memory_badges.dart';

class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame()
      : super(GameState(
          coins: 85,
          powerUps: PowerUps(fiftyFifty: 2, shield: 1),
          hearts: const HeartsState(count: 3, regenStartMs: null),
        ));
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
            'name': 'Juan Dela Cruz',
            'classCode': 'EDG5A1',
            'schoolName': 'Rizal Elementary School',
            'gradeLevel': 'grade5',
            'score': 1240,
            'coins': 85,
            'powerUps': {'fiftyFifty': 2, 'shield': 1},
          }),
          isLoggedIn: true,
        ));
  static int refreshes = 0;
  @override
  Future<void> refreshProfile() async => refreshes++;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProgress extends StateNotifier<ProgressState> implements ProgressNotifier {
  _FakeProgress() : super(const ProgressState());
  @override
  Future<void> loadProgress() async {}
  @override
  EraProgress getEraProgress(String eraId) {
    if (eraId == 'pre-colonial') {
      return EraProgress(eraId: eraId, bossDefeated: true, levelsCompleted: 10);
    }
    if (eraId == 'spanish') return EraProgress(eraId: eraId, levelsCompleted: 3);
    return EraProgress(eraId: eraId);
  }

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, Size size,
    {bool unlockAll = false, BadgeNotifier? badges}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(ProviderScope(
    overrides: [
      gameProvider.overrideWith((ref) => _FakeGame()),
      authProvider.overrideWith((ref) => _FakeAuth()),
      progressProvider.overrideWith((ref) => _FakeProgress()),
      unlockAllProvider.overrideWith((ref) => _FakeUnlock(unlockAll)),
      // The badges kept in memory: a Hive write started in a widget test never finishes.
      badgeProvider.overrideWith((ref) => badges ?? (MemoryBadges()..load('s'))),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Finder _asset(String name) => find.byWidgetPredicate((w) =>
    w is Image &&
    w.image is AssetImage &&
    (w.image as AssetImage).assetName == name);

String _textIn(WidgetTester tester, Key key) => tester
    .widgetList<Text>(find.descendant(of: find.byKey(key), matching: find.byType(Text)))
    .single
    .data!;

void main() {
  final dir = Directory.systemTemp.createTempSync('chronoquest_profile_test_').path;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    Hive.init(dir);
    await Hive.openBox('chronoquest');
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      Directory(dir).deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('asks the server for the score again when it opens', (tester) async {
    _FakeAuth.refreshes = 0;
    await _pump(tester, const Size(800, 360));
    expect(_FakeAuth.refreshes, 1);
  });

  testWidgets("shows the student's own hero and name", (tester) async {
    await _pump(tester, const Size(800, 360));

    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('EDG5A1'), findsOneWidget);
    expect(find.byKey(ProfileScreen.heroKey), findsOneWidget);
    final hero = tester.widget<Image>(find.byKey(ProfileScreen.heroKey));
    expect((hero.image as AssetImage).assetName, 'assets/characters/rizal_walk_1.png');
  });

  testWidgets('the school and the labels are not on the page', (tester) async {
    await _pump(tester, const Size(800, 360));
    expect(find.text('Rizal Elementary School'), findsNothing);
    expect(find.text('Puntos'), findsNothing);
    expect(find.text('Coins'), findsNothing);
    expect(find.text('PAGLALAKBAY'), findsNothing);
    expect(find.text('MGA GAMIT'), findsNothing);
  });

  testWidgets('the two totals are round chips with one number each, grouped', (tester) async {
    await _pump(tester, const Size(800, 360));

    expect(_textIn(tester, ProfileScreen.scoreKey), '1,240');
    expect(_textIn(tester, ProfileScreen.coinsKey), '85');
  });

  testWidgets('the power-ups are a picture and a count each', (tester) async {
    await _pump(tester, const Size(800, 360));

    expect(_textIn(tester, ProfileScreen.powerKey('fiftyFifty')), '×2');
    expect(_textIn(tester, ProfileScreen.powerKey('shield')), '×1');
    expect(_textIn(tester, ProfileScreen.powerKey('timeFreeze')), '×0');
    expect(find.text('50/50  ×2'), findsNothing, reason: 'no words');
  });

  testWidgets('has a way into the shop, which is where things are bought', (tester) async {
    await _pump(tester, const Size(812, 375));
    await tester.ensureVisible(find.byKey(ProfileScreen.shopKey));

    expect(find.byKey(ProfileScreen.shopKey), findsOneWidget);
    expect(find.byKey(const ValueKey('buy_timeFreeze')), findsNothing,
        reason: 'purchases are on the TINDAHAN screen');
  });

  group('the badges tile', () {
    BadgeNotifier holding({bool seen = false}) {
      final n = MemoryBadges()..load('student');
      n.recordLevel(
        eraId: 'spanish',
        level: 1,
        correct: 10,
        total: 10,
        healthLost: 0,
        anyWrong: false,
      );
      if (seen) n.markAllSeen();
      return n;
    }

    testWidgets('is a row to the shelf with how many are held, and no tag when none are new', (tester) async {
      await _pump(tester, const Size(812, 375));
      await tester.ensureVisible(find.byKey(ProfileScreen.badgesKey));
      expect(find.text('MGA BADGE'), findsOneWidget);
      expect(find.text('0/28'), findsOneWidget);
      expect(find.byKey(ProfileScreen.badgesNewKey), findsNothing);
    });

    testWidgets('a red BAGO counts the badges not looked at yet', (tester) async {
      final badges = holding();
      await _pump(tester, const Size(812, 375), badges: badges);
      await tester.ensureVisible(find.byKey(ProfileScreen.badgesKey));
      expect(find.text('3/28'), findsOneWidget);
      expect(find.text('BAGO 3'), findsOneWidget);
    });

    testWidgets('and the tag is gone once they have been seen', (tester) async {
      final badges = holding(seen: true);
      await _pump(tester, const Size(812, 375), badges: badges);
      expect(find.text('3/28'), findsOneWidget);
      expect(find.byKey(ProfileScreen.badgesNewKey), findsNothing);
    });
  });

  group('the eras', () {
    testWidgets('each is its number, with a pip for every one of its own levels', (tester) async {
      await _pump(tester, const Size(800, 360));

      for (final era in allEras) {
        expect(find.byKey(ProfileScreen.eraKey(era.id)), findsOneWidget, reason: era.id);
        expect(
            find.descendant(
                of: find.byKey(ProfileScreen.eraKey(era.id)),
                matching: find.text('${eraNumberFor(era.id)}')),
            findsOneWidget);
        for (var i = 0; i < era.levels.length; i++) {
          expect(find.byKey(ProfileScreen.pipKey(era.id, i)), findsOneWidget,
              reason: '${era.id} pip $i');
        }
        expect(find.byKey(ProfileScreen.pipKey(era.id, era.levels.length)), findsNothing);
      }
      // Spanish has 5 levels, not the 10 the old screen assumed for every era.
      expect(allEras.firstWhere((e) => e.id == 'spanish').levels.length, 5);
    });

    testWidgets('the titles are not here: they are on the era screen', (tester) async {
      await _pump(tester, const Size(800, 360));
      for (final era in allEras) {
        expect(find.text(era.name), findsNothing, reason: era.name);
      }
    });

    testWidgets('pips are filled for the levels done, and all of them for a finished era',
        (tester) async {
      await _pump(tester, const Size(800, 360));
      Color? colorOf(String id, int i) => (tester
              .widget<Container>(find.byKey(ProfileScreen.pipKey(id, i)))
              .decoration as BoxDecoration)
          .color;

      expect(colorOf('spanish', 2), AppColors.success, reason: 'the third of 5 is done');
      expect(colorOf('spanish', 3), isNot(AppColors.success));
      expect(colorOf('pre-colonial', 9), AppColors.success, reason: 'a finished era is full');
    });

    testWidgets('a finished era shows a star instead of a count', (tester) async {
      await _pump(tester, const Size(800, 360));

      expect(find.text('10/10'), findsNothing);
      expect(find.text('3/5'), findsNothing);
      expect(_asset('assets/ui/star_full.png'), findsNWidgets(2),
          reason: 'one in the points chip, one on the finished era');
    });
  });

  testWidgets('has Back and Settings chips but no Profile chip', (tester) async {
    await _pump(tester, const Size(800, 360));

    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.byTooltip('Bumalik'), findsOneWidget);
    expect(find.byTooltip('Profile'), findsNothing);
  });

  for (final size in const [Size(732, 320), Size(640, 360), Size(400, 700)]) {
    testWidgets('lays out without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await _pump(tester, size);
      expect(tester.takeException(), isNull);
      // Everything is reachable: the Kodeks and the shop, last on the page, can be scrolled to.
      for (final key in [ProfileScreen.codexKey, ProfileScreen.badgesKey, ProfileScreen.shopKey]) {
        await tester.ensureVisible(find.byKey(key));
        await tester.pump();
        expect(find.byKey(key).hitTestable(), findsOneWidget, reason: '$key');
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('with Test Mode on, no era is shown locked', (tester) async {
    await _pump(tester, const Size(800, 360), unlockAll: true);
    expect(_asset('assets/ui/lock_icon.png'), findsNothing);
  });

  testWidgets("without it, eras beyond the student's progress are locked", (tester) async {
    await _pump(tester, const Size(800, 360));
    expect(_asset('assets/ui/lock_icon.png'), findsNWidgets(4),
        reason: 'nationalism, and the three Grade 6 eras');
  });
}
