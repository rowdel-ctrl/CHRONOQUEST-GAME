// The Profile: the student's hero (idle pose) and name, two totals as round chips, an
// era number with a thin bar and n/10 (the real number of levels), a star or a lock,
// the power-ups carried and three tiles, with no overflow on a short landscape phone.
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
import 'package:chronoquest/models/codex_entry.dart';
import 'package:chronoquest/screens/profile/codex_screen.dart';
import 'package:chronoquest/services/storage_service.dart';
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

class _FakeProgress extends StateNotifier<ProgressState>
    implements ProgressNotifier {
  _FakeProgress() : super(const ProgressState());
  @override
  Future<void> loadProgress() async {}
  @override
  EraProgress getEraProgress(String eraId) {
    if (eraId == 'pre-colonial') {
      return EraProgress(eraId: eraId, bossDefeated: true, levelsCompleted: 10);
    }
    if (eraId == 'spanish')
      return EraProgress(eraId: eraId, levelsCompleted: 3);
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
      badgeProvider
          .overrideWith((ref) => badges ?? (MemoryBadges()..load('s'))),
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
    .widgetList<Text>(
        find.descendant(of: find.byKey(key), matching: find.byType(Text)))
    .single
    .data!;

void main() {
  final dir =
      Directory.systemTemp.createTempSync('chronoquest_profile_test_').path;

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

  testWidgets('asks the server for the score again when it opens',
      (tester) async {
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
    expect(
        (hero.image as AssetImage).assetName, 'assets/characters/boy_idle.png');
  });

  testWidgets('the school and the labels are not on the page', (tester) async {
    await _pump(tester, const Size(800, 360));
    expect(find.text('Rizal Elementary School'), findsNothing);
    expect(find.text('Puntos'), findsNothing);
    expect(find.text('Coins'), findsNothing);
    expect(find.text('PAGLALAKBAY'), findsNothing);
    expect(find.text('MGA GAMIT'), findsNothing);
  });

  testWidgets('the two totals are round chips with one number each, grouped',
      (tester) async {
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

  testWidgets('has a way into the shop, which is where things are bought',
      (tester) async {
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

    testWidgets(
        'is a row to the shelf with how many are held, and no tag when none are new',
        (tester) async {
      await _pump(tester, const Size(812, 375));
      await tester.ensureVisible(find.byKey(ProfileScreen.badgesKey));
      expect(find.text('MGA BADGE'), findsOneWidget);
      expect(find.text('0 ng 40 badge'), findsOneWidget);
      expect(find.byKey(ProfileScreen.badgesNewKey), findsNothing);
    });

    testWidgets('a red BAGO counts the badges not looked at yet',
        (tester) async {
      final badges = holding();
      await _pump(tester, const Size(812, 375), badges: badges);
      await tester.ensureVisible(find.byKey(ProfileScreen.badgesKey));
      expect(find.text('3 ng 40 badge'), findsOneWidget);
      expect(find.text('BAGO 3'), findsOneWidget);
    });

    testWidgets('and the tag is gone once they have been seen', (tester) async {
      final badges = holding(seen: true);
      await _pump(tester, const Size(812, 375), badges: badges);
      expect(find.text('3 ng 40 badge'), findsOneWidget);
      expect(find.byKey(ProfileScreen.badgesNewKey), findsNothing);
    });
  });

  group('the eras', () {
    testWidgets('each is its number, a bar and a count of its own levels',
        (tester) async {
      await _pump(tester, const Size(800, 360));

      for (final era in allEras) {
        expect(find.byKey(ProfileScreen.eraKey(era.id)), findsOneWidget,
            reason: era.id);
        expect(
            find.descendant(
                of: find.byKey(ProfileScreen.eraKey(era.id)),
                matching: find.text('${eraNumberFor(era.id)}')),
            findsOneWidget);
        expect(find.byKey(ProfileScreen.barKey(era.id)), findsOneWidget,
            reason: '${era.id} bar');
        expect(find.byKey(ProfileScreen.countKey(era.id)), findsOneWidget,
            reason: '${era.id} count');
      }
      // Spanish has 5 levels, not the 10 the old screen assumed for every era.
      expect(allEras.firstWhere((e) => e.id == 'spanish').levels.length, 5);
    });

    testWidgets('there are no pips any more', (tester) async {
      await _pump(tester, const Size(800, 360));
      expect(find.byKey(const ValueKey('profile_pip_pre-colonial_0')),
          findsNothing);
    });

    testWidgets('the titles are not here: they are on the era screen',
        (tester) async {
      await _pump(tester, const Size(800, 360));
      for (final era in allEras) {
        expect(find.text(era.name), findsNothing, reason: era.name);
      }
    });

    testWidgets(
        'the bar is filled by the levels done, and fully for a finished era',
        (tester) async {
      await _pump(tester, const Size(800, 360));
      double filledOf(String id) => tester
          .widget<FractionallySizedBox>(find.descendant(
              of: find.byKey(ProfileScreen.barKey(id)),
              matching: find.byType(FractionallySizedBox)))
          .widthFactor!;

      expect(filledOf('spanish'), closeTo(3 / 5, 0.001),
          reason: '3 of 5 are done');
      expect(filledOf('pre-colonial'), 1, reason: 'a finished era is full');
      expect(filledOf('nationalism'), 0);
    });

    testWidgets(
        'the count says n/total (the real total), and a shut era not started says nothing',
        (tester) async {
      await _pump(tester, const Size(800, 360));
      String countOf(String id) =>
          tester.widget<Text>(find.byKey(ProfileScreen.countKey(id))).data!;

      expect(countOf('spanish'), '3/5');
      expect(countOf('pre-colonial'), '10/10');
      expect(countOf('nationalism'), '', reason: 'locked, nothing done yet');
    });

    testWidgets(
        'a finished era has a star, a shut one a lock, an open one neither',
        (tester) async {
      await _pump(tester, const Size(800, 360));

      expect(_asset('assets/ui/star_full.png'), findsNWidgets(2),
          reason: 'one in the points chip, one on the finished era');
      Finder inRow(String id, String asset) => find.descendant(
          of: find.byKey(ProfileScreen.eraKey(id)),
          matching: find.byWidgetPredicate((w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == asset));
      expect(inRow('pre-colonial', 'assets/ui/star_full.png'), findsOneWidget);
      expect(inRow('nationalism', 'assets/ui/lock_icon.png'), findsOneWidget);
      expect(inRow('spanish', 'assets/ui/star_full.png'), findsNothing);
      expect(inRow('spanish', 'assets/ui/lock_icon.png'), findsNothing);
    });
  });

  group('the Kodeks tile', () {
    testWidgets('says how many of the 60 artifacts are claimed',
        (tester) async {
      await _pump(tester, const Size(812, 375));
      await tester.ensureVisible(find.byKey(ProfileScreen.codexKey));
      expect(find.text('KODEKS'), findsOneWidget);
      expect(
          find.text('${codexClaimedTotal()} ng 60 artifact'), findsOneWidget);
    });

    testWidgets('counts a picture once however many answers gave it',
        (tester) async {
      await tester.runAsync(() async {
        for (final q in ['a', 'b']) {
          await StorageService.saveCodexEntry(CodexEntry(
              eraId: 'spanish',
              questionId: q,
              artifactSprite: 3,
              questionText: 't',
              blurb: 'b',
              claimedAtMs: 1));
        }
        await StorageService.saveCodexEntry(const CodexEntry(
            eraId: 'modern',
            questionId: 'c',
            artifactSprite: 1,
            questionText: 't',
            blurb: 'b',
            claimedAtMs: 1));
      });
      await _pump(tester, const Size(812, 375));
      await tester.ensureVisible(find.byKey(ProfileScreen.codexKey));
      expect(find.text('2 ng 60 artifact'), findsOneWidget,
          reason: 'three answers, two pictures');
    });
  });

  testWidgets('has Back and Settings chips but no Profile chip',
      (tester) async {
    await _pump(tester, const Size(800, 360));

    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.byTooltip('Bumalik'), findsOneWidget);
    expect(find.byTooltip('Profile'), findsNothing);
  });

  for (final size in const [Size(732, 320), Size(640, 360), Size(400, 700)]) {
    testWidgets(
        'lays out without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await _pump(tester, size);
      expect(tester.takeException(), isNull);
      // Everything is reachable: the Kodeks and the shop, last on the page, can be scrolled to.
      for (final key in [
        ProfileScreen.codexKey,
        ProfileScreen.badgesKey,
        ProfileScreen.shopKey
      ]) {
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

  testWidgets("without it, eras beyond the student's progress are locked",
      (tester) async {
    await _pump(tester, const Size(800, 360));
    expect(_asset('assets/ui/lock_icon.png'), findsNWidgets(4),
        reason: 'nationalism, and the three Grade 6 eras');
  });
}
