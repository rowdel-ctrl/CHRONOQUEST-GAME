// The redesigned Profile: the same top bar and parchment panels as the other
// menu screens, a tile per era with the real number of levels, and no overflow
// on a short landscape phone.
import 'dart:io';

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/era_progress.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/models/student.dart';
import 'package:chronoquest/providers/auth_provider.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/providers/progress_provider.dart';
import 'package:chronoquest/providers/unlock_all_provider.dart';
import 'package:chronoquest/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame()
      : super(GameState(hearts: const HeartsState(count: 3, regenStartMs: null)));
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

Future<void> _pump(WidgetTester tester, Size size, {bool unlockAll = false}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(ProviderScope(
    overrides: [
      gameProvider.overrideWith((ref) => _FakeGame()),
      authProvider.overrideWith((ref) => _FakeAuth()),
      progressProvider.overrideWith((ref) => _FakeProgress()),
      unlockAllProvider.overrideWith((ref) => _FakeUnlock(unlockAll)),
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

  testWidgets('shows who the student is, with the totals grouped', (tester) async {
    await _pump(tester, const Size(800, 360));

    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('EDG5A1'), findsOneWidget);
    expect(find.text('Rizal Elementary School'), findsOneWidget);
    expect(find.text('1,240'), findsOneWidget);
    expect(find.text('85'), findsOneWidget);
    expect(find.text('×2'), findsOneWidget, reason: '50/50 powerups');
    expect(find.text('×1'), findsOneWidget, reason: 'shields');
  });

  testWidgets('each era counts against its own number of levels', (tester) async {
    await _pump(tester, const Size(800, 360));

    for (final era in allEras) {
      expect(find.text(era.name), findsOneWidget, reason: era.name);
    }
    // Spanish has 5 levels, not the 10 the old screen assumed for every era.
    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('3/10'), findsNothing);
  });

  testWidgets('a finished era shows a star instead of a count', (tester) async {
    await _pump(tester, const Size(800, 360));

    expect(find.text('10/10'), findsNothing);
    expect(_asset('assets/ui/star_full.png'), findsNWidgets(2),
        reason: 'one in the Puntos total, one on the finished era');
  });

  testWidgets('has Back and Settings chips but no Profile chip', (tester) async {
    await _pump(tester, const Size(800, 360));

    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.byTooltip('Bumalik'), findsOneWidget);
    expect(find.byTooltip('Profile'), findsNothing);
  });

  for (final size in const [
    Size(800, 360),
    Size(732, 320),
    Size(640, 360),
    Size(400, 700),
  ]) {
    testWidgets('lays out without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await _pump(tester, size);
      expect(tester.takeException(), isNull);
      // Everything is reachable: the Kodeks, last on the page, can be scrolled to.
      await tester.ensureVisible(find.byKey(ProfileScreen.codexKey));
      await tester.pump();
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
