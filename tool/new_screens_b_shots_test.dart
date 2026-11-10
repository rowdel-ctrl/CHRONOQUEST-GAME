// A development tool, not a test of behaviour: draws the redesigned level complete, era
// selection, codex, era complete and profile screens at a few phone sizes and writes a PNG
// for each, so they can be looked at without a device. It loads the real Poppins font.
//
//   flutter test tool/new_screens_b_shots_test.dart --dart-define=SHOT_OUT=C:/temp/shots
//
// Without SHOT_OUT the test does nothing, so it is safe in a full `flutter test tool` run.
// SHOT_FONTS is the folder holding Poppins-Regular/Medium/SemiBold/Bold.ttf.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chronoquest/models/codex_entry.dart';
import 'package:chronoquest/models/era_progress.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/models/quiz_result.dart';
import 'package:chronoquest/models/student.dart';
import 'package:chronoquest/providers/auth_provider.dart';
import 'package:chronoquest/providers/badge_provider.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/providers/progress_provider.dart';
import 'package:chronoquest/providers/unlock_all_provider.dart';
import 'package:chronoquest/screens/game/era_complete_screen.dart';
import 'package:chronoquest/screens/game/level_complete_screen.dart';
import 'package:chronoquest/screens/home/era_selection_screen.dart';
import 'package:chronoquest/screens/profile/codex_screen.dart';
import 'package:chronoquest/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import '../test/fixtures/memory_badges.dart';

const _out = String.fromEnvironment('SHOT_OUT');
const _fonts = String.fromEnvironment('SHOT_FONTS');

class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame(String hero)
      : super(GameState(
          selectedCharacterId: hero,
          coins: 340,
          powerUps: PowerUps(fiftyFifty: 3, shield: 5, timeFreeze: 2),
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
            'username': 'juan.dc',
            'classCode': 'EDG5A1',
            'gradeLevel': 'grade5',
            'score': 12480,
          }),
          isLoggedIn: true,
        ));
  @override
  Future<void> refreshProfile() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Pre-colonial and Spanish finished, nationalism 4 levels in, the rest not started.
class _FakeProgress extends StateNotifier<ProgressState>
    implements ProgressNotifier {
  _FakeProgress(this.done) : super(const ProgressState());
  final Map<String, int> done;
  @override
  Future<void> loadProgress() async {}
  @override
  EraProgress getEraProgress(String eraId) {
    final n = done[eraId] ?? 0;
    return EraProgress(
        eraId: eraId,
        levelsCompleted: n,
        bossDefeated: n >= 10 || (eraId == 'spanish' && n >= 5));
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

Future<void> _loadFonts() async {
  final dir = _fonts.isEmpty
      ? 'assets/google_fonts'
      : _fonts;
  const files = {
    'Poppins_regular': 'Poppins-Regular.ttf',
    'Poppins_500': 'Poppins-Medium.ttf',
    'Poppins_600': 'Poppins-SemiBold.ttf',
    'Poppins_700': 'Poppins-Bold.ttf',
  };
  for (final e in files.entries) {
    final bytes = File('$dir/${e.value}').readAsBytesSync();
    final loader = FontLoader(e.key)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}

CodexEntry _claim(String era, int n) => CodexEntry(
      eraId: era,
      questionId: '$era-$n',
      artifactSprite: n,
      questionText: 'Ano ang tawag sa sinaunang bangka ng mga Pilipino?',
      blurb:
          'Ang balangay ay isang malaking bangkang yari sa kahoy na ginamit ng mga sinaunang Pilipino sa paglalakbay at pangangalakal sa pagitan ng mga isla.',
      claimedAtMs: n,
    );

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    if (_out.isNotEmpty) {
      await _loadFonts();
      Hive.init(Directory.systemTemp.createTempSync('shots_b_').path);
      await Hive.openBox('chronoquest');
    }
  });

  testWidgets('new screens shots', (tester) async {
    if (_out.isEmpty) return;
    Directory(_out).createSync(recursive: true);

    Future<void> shot(String name, Size size, Widget screen,
        {String hero = 'boy',
        bool unlockAll = false,
        Map<String, int>? done}) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      final key = GlobalKey();
      // A fresh tree each time, so no provider state carries over.
      await tester.pumpWidget(const SizedBox());
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = size;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          gameProvider.overrideWith((ref) => _FakeGame(hero)),
          authProvider.overrideWith((ref) => _FakeAuth()),
          progressProvider.overrideWith((ref) => _FakeProgress(
              done ?? {'pre-colonial': 10, 'spanish': 5, 'nationalism': 4})),
          unlockAllProvider.overrideWith((ref) => _FakeUnlock(unlockAll)),
          badgeProvider.overrideWith((ref) => MemoryBadges()..load('s')),
        ],
        child: RepaintBoundary(
          key: key,
          child: MaterialApp.router(
            routerConfig: GoRouter(routes: [
              GoRoute(path: '/', builder: (_, __) => screen),
              GoRoute(path: '/:any', builder: (_, __) => const SizedBox()),
              GoRoute(path: '/:a/:b', builder: (_, __) => const SizedBox()),
            ]),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(seconds: 2));
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      File('$_out/${name}_${size.width.toInt()}x${size.height.toInt()}.png')
          .writeAsBytesSync(bytes!);
    }

    const sizes = [Size(732, 320), Size(400, 700)];

    // Level complete: 7 of 10 right.
    const right = [
      true,
      true,
      false,
      true,
      true,
      true,
      false,
      true,
      true,
      false
    ];
    for (final size in sizes) {
      for (final hero in ['boy', 'girl']) {
        await shot(
          'level_$hero',
          size,
          const LevelCompleteScreen(
            eraId: 'pre-colonial',
            level: 3,
            result: LevelCompleteResult(
                score: 1240, correct: 7, total: 10, coins: 86, answers: right),
          ),
          hero: hero,
        );
      }
    }

    // Era selection: the current era in the middle, a finished one before it and a
    // locked one after it.
    for (final size in const [Size(732, 320), Size(640, 360), Size(400, 700)]) {
      await shot('era', size, const EraSelectionScreen(),
          unlockAll: true,
          done: {
            'pre-colonial': 10,
            'spanish': 5,
            'nationalism': 10,
            'american': 3
          });
    }
    await shot(
        'era_locked_next', const Size(732, 320), const EraSelectionScreen(),
        unlockAll: true,
        done: {'pre-colonial': 10, 'spanish': 5, 'nationalism': 4});

    // A locked era in front of a finished one (the normal grade view).
    await shot('era_locked', const Size(732, 320), const EraSelectionScreen(),
        done: {'pre-colonial': 10, 'spanish': 2});

    // Codex.
    final claims = {
      'pre-colonial': [
        for (final n in [1, 2, 4, 5, 7, 8, 9]) _claim('pre-colonial', n)
      ],
      'spanish': [_claim('spanish', 2)],
    };
    for (final size in sizes) {
      await shot(
          'codex', size, CodexScreen(entriesFor: (e) => claims[e] ?? const []));
      await shot('codex_empty', size, CodexScreen(entriesFor: (e) => const []));
    }

    // Era complete.
    for (final size in sizes) {
      await shot(
        'done',
        size,
        EraCompleteScreen(
          eraId: 'pre-colonial',
          coins: 120,
          powerUps: const [
            PowerUpKind.fiftyFifty,
            PowerUpKind.shield,
            PowerUpKind.timeFreeze
          ],
          loadResults: () async => [
            for (var i = 1; i <= 9; i++)
              QuizResult(
                  era: 'pre-colonial',
                  level: i,
                  type: 'pre_test',
                  correctAnswersCount: 8,
                  totalQuestions: 10,
                  percentage: 82,
                  timeTakenTotal: 60,
                  questionSnapshots: const []),
            QuizResult(
                era: 'pre-colonial',
                level: 10,
                type: 'post_test',
                correctAnswersCount: 9,
                totalQuestions: 10,
                percentage: 90,
                timeTakenTotal: 60,
                questionSnapshots: const []),
          ],
        ),
        hero: 'girl',
      );
    }

    // Profile.
    for (final size in sizes) {
      await shot('profile', size, const ProfileScreen());
    }
    addTearDown(tester.view.reset);
  });
}
