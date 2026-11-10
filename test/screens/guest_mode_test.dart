// Guest mode: a demo button on the first screen. A guest plays the first era only,
// nothing goes to the server, and every session starts fresh.
import 'dart:io';

import 'package:chronoquest/core/app_info.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/control_scheme.dart';
import 'package:chronoquest/models/era_progress.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:chronoquest/models/quiz_result.dart';
import 'package:chronoquest/models/student.dart';
import 'package:chronoquest/providers/auth_provider.dart';
import 'package:chronoquest/providers/badge_provider.dart';
import 'package:chronoquest/providers/control_scheme_provider.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/providers/progress_provider.dart';
import 'package:chronoquest/providers/unlock_all_provider.dart';
import 'package:chronoquest/screens/auth/login_screen.dart';
import 'package:chronoquest/screens/home/era_selection_screen.dart';
import 'package:chronoquest/screens/settings/settings_screen.dart';
import 'package:chronoquest/services/api_service.dart';
import 'package:chronoquest/services/guest_mode.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:chronoquest/widgets/guest_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

/// Records what the screens ask of the sign-in: start a guest, log out.
class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuth({bool guest = false})
      : super(AuthState(
          student: guest
              ? Student(
                  id: GuestMode.studentId,
                  username: 'guest',
                  name: 'Guest',
                  classCode: '',
                  gradeLevel: 'grade5',
                )
              : Student.fromJson(
                  {'id': 's', 'name': 'Rodel', 'gradeLevel': 'grade5'}),
          isLoggedIn: true,
        ));

  _FakeAuth.signedOut() : super(const AuthState());

  int started = 0;
  int loggedOut = 0;

  @override
  Future<void> startGuest() async => started++;
  @override
  Future<void> logout() async => loggedOut++;
  @override
  Future<void> refreshProfile() async {}
  @override
  void clearError() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame()
      : super(
            GameState(hearts: const HeartsState(count: 3, regenStartMs: null)));
  @override
  Duration? get heartCountdown => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProgress extends StateNotifier<ProgressState>
    implements ProgressNotifier {
  _FakeProgress(this.bossDown) : super(const ProgressState());
  final Set<String> bossDown;
  @override
  Future<void> loadProgress() async {}
  @override
  EraProgress getEraProgress(String eraId) =>
      EraProgress(eraId: eraId, bossDefeated: bossDown.contains(eraId));
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

class _FakeScheme extends StateNotifier<ControlScheme>
    implements ControlSchemeNotifier {
  _FakeScheme() : super(ControlScheme.joystick);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _size(WidgetTester tester, Size size) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

Widget _stand(String name) => Scaffold(body: Text(name));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(() => GuestMode.active = false);

  group('the first screen', () {
    Future<_FakeAuth> openLogin(WidgetTester tester) async {
      await _size(tester, const Size(800, 360));
      final auth = _FakeAuth.signedOut();
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => LoginScreen(
            scannerBuilder: (context, onRaw, onFailure) => const SizedBox(),
            connection: ValueNotifier<bool?>(true),
            checkConnection: () {},
            lastSignIn: () => null,
          ),
        ),
        GoRoute(
            path: '/character-selection',
            builder: (_, __) => _stand('hero stand-in')),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [authProvider.overrideWith((ref) => auth)],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pump();
      return auth;
    }

    testWidgets('has "Play as a guest" under the two ways into a class',
        (tester) async {
      await openLogin(tester);
      expect(find.text('PLAY AS A GUEST'), findsOneWidget);
      expect(find.text('Subukan muna ang laro'), findsOneWidget);
      final guest = tester.getRect(find.byKey(LoginScreen.guestKey));
      expect(
          guest.top,
          greaterThan(
              tester.getRect(find.byKey(LoginScreen.returningKey)).bottom));
      expect(guest.height,
          lessThan(tester.getRect(find.byKey(LoginScreen.newKey)).height),
          reason: 'slimmer than the two main buttons');
      expect(guest.height, greaterThanOrEqualTo(44),
          reason: 'big enough to hit');
    });

    testWidgets('asks first, and BUMALIK changes nothing', (tester) async {
      final auth = await openLogin(tester);
      await tester.tap(find.byKey(LoginScreen.guestKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(GuestConfirmCard.cardKey), findsOneWidget);
      expect(find.text('Play as a guest?'), findsOneWidget);
      expect(
          find.text('Unang panahon lang: Sinaunang Pilipinas'), findsOneWidget);
      expect(find.text('Hindi ito makikita ng teacher mo'), findsOneWidget);

      await tester.tap(find.byKey(GuestConfirmCard.backKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(GuestConfirmCard.cardKey), findsNothing);
      expect(auth.started, 0);
      expect(find.byKey(LoginScreen.guestKey), findsOneWidget,
          reason: 'still on the first screen');
    });

    testWidgets('MAGLARO starts a guest and goes to the hero screen',
        (tester) async {
      final auth = await openLogin(tester);
      await tester.tap(find.byKey(LoginScreen.guestKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(GuestConfirmCard.playKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(auth.started, 1);
      expect(find.text('hero stand-in'), findsOneWidget);
    });
  });

  group('the era screen', () {
    Future<_FakeAuth> openEras(
      WidgetTester tester, {
      bool guest = true,
      Set<String> bossDown = const {},
      List<String>? landedOn,
    }) async {
      await _size(tester, const Size(732, 320));
      final auth = _FakeAuth(guest: guest);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const EraSelectionScreen()),
        GoRoute(
          path: '/background/:eraId',
          builder: (_, s) {
            landedOn?.add('/background/${s.pathParameters['eraId']}');
            return _stand('history stand-in');
          },
        ),
        GoRoute(path: '/login', builder: (_, __) => _stand('login stand-in')),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          gameProvider.overrideWith((ref) => _FakeGame()),
          authProvider.overrideWith((ref) => auth),
          progressProvider.overrideWith((ref) => _FakeProgress(bossDown)),
          unlockAllProvider.overrideWith((ref) => _FakeUnlock()),
          badgeProvider.overrideWith((ref) => BadgeNotifier(payCoins: (_) {})),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      return auth;
    }

    testWidgets('a guest has the Guest tag and no profile chip',
        (tester) async {
      await openEras(tester);
      expect(find.byKey(GuestTag.tagKey), findsOneWidget);
      expect(find.text('GUEST'), findsOneWidget);
      expect(find.byTooltip('Profile'), findsNothing);
      expect(find.byTooltip('Tindahan'), findsOneWidget,
          reason: 'the shop still works on the phone');
      expect(find.byTooltip('Settings'), findsOneWidget);
    });

    testWidgets(
        'only the first era opens; the others say they are for signed-in students',
        (tester) async {
      final landed = <String>[];
      await openEras(tester, landedOn: landed);
      // The first era is in front; the second peeks in beside it and says so.
      expect(find.text('PARA SA NAKA-SIGN IN'), findsOneWidget);

      final grade5 = allEras.where((e) => e.grade == 5).toList();
      await tester.tap(find.byKey(EraSelectionScreen.cardKey(grade5[0].id)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(landed, ['/background/${GuestMode.eraId}']);
    });

    testWidgets(
        'a shut era in front says it is for signed-in students and does nothing',
        (tester) async {
      final landed = <String>[];
      await openEras(tester, landedOn: landed);
      final grade5 = allEras.where((e) => e.grade == 5).toList();

      await tester.tap(find.byKey(EraSelectionScreen.nextKey));
      await tester.pump(const Duration(milliseconds: 400));
      // The second era is the big one now and the third peeks in: both say it.
      expect(find.text('PARA SA NAKA-SIGN IN'), findsNWidgets(2));
      await tester.tap(find.byKey(EraSelectionScreen.cardKey(grade5[1].id)));
      await tester.pump(const Duration(milliseconds: 400));
      expect(landed, isEmpty, reason: 'the second era does nothing');
    });

    testWidgets('a signed-in student sees none of it', (tester) async {
      await openEras(tester, guest: false);
      expect(find.byKey(GuestTag.tagKey), findsNothing);
      expect(find.text('PARA SA NAKA-SIGN IN'), findsNothing);
      expect(find.byTooltip('Profile'), findsOneWidget);
      expect(find.byKey(GuestDoneCard.cardKey), findsNothing);
    });

    testWidgets(
        'finishing the first era asks the guest to sign in, which logs out',
        (tester) async {
      final auth = await openEras(tester, bossDown: {GuestMode.eraId});
      expect(find.byKey(GuestDoneCard.cardKey), findsOneWidget);
      expect(find.text('Tapos mo na ang Guest preview'), findsOneWidget);

      await tester.tap(find.byKey(GuestDoneCard.signInKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(auth.loggedOut, 1);
      expect(find.text('login stand-in'), findsOneWidget);
    });

    testWidgets('LARO ULIT starts a fresh guest', (tester) async {
      final auth = await openEras(tester, bossDown: {GuestMode.eraId});
      await tester.tap(find.byKey(GuestDoneCard.againKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(auth.loggedOut, 1);
      expect(auth.started, 1);
    });

    testWidgets(
        'a signed-in student who finished the first era gets no guest card',
        (tester) async {
      await openEras(tester, guest: false, bossDown: {GuestMode.eraId});
      expect(find.byKey(GuestDoneCard.cardKey), findsNothing);
    });
  });

  group('settings', () {
    Future<_FakeAuth> openSettings(WidgetTester tester,
        {required bool guest}) async {
      await _size(tester, const Size(800, 360));
      final auth = _FakeAuth(guest: guest);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const SettingsScreen()),
        GoRoute(path: '/login', builder: (_, __) => _stand('login stand-in')),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => auth),
          controlSchemeProvider.overrideWith((ref) => _FakeScheme()),
          unlockAllProvider.overrideWith((ref) => _FakeUnlock()),
          testBuildProvider.overrideWithValue(false),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
      return auth;
    }

    testWidgets('a guest has a gold EXIT GUEST MODE tile instead of I-LOGOUT',
        (tester) async {
      final auth = await openSettings(tester, guest: true);
      expect(find.text('EXIT GUEST MODE'), findsOneWidget);
      expect(find.text('I-LOGOUT'), findsNothing);
      expect(find.text('Guest · Version $appVersion'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // CANCEL keeps the guest where they are.
      await tester.tap(find.byKey(const Key('guest_sign_in_button')));
      await tester.pumpAndSettle();
      expect(find.text('Are you sure you want to exit Guest Mode?'),
          findsOneWidget);
      await tester.tap(find.byKey(GuestExitCard.cancelKey));
      await tester.pumpAndSettle();
      expect(auth.loggedOut, 0);
      expect(find.text('login stand-in'), findsNothing);

      // EXIT logs out and goes back to the first screen.
      await tester.tap(find.byKey(const Key('guest_sign_in_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(GuestExitCard.exitKey));
      await tester.pumpAndSettle();
      expect(auth.loggedOut, 1);
      expect(find.text('login stand-in'), findsOneWidget);
    });

    testWidgets('a student still has I-LOGOUT', (tester) async {
      await openSettings(tester, guest: false);
      expect(find.text('I-LOGOUT'), findsOneWidget);
      expect(find.text('EXIT GUEST MODE'), findsNothing);
    });
  });

  group('nothing reaches the server', () {
    final dir =
        Directory.systemTemp.createTempSync('chronoquest_guest_test_').path;

    setUpAll(() async {
      Hive.init(dir);
      await Hive.openBox('chronoquest');
    });

    tearDownAll(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await Hive.close();
      try {
        Directory(dir).deleteSync(recursive: true);
      } catch (_) {}
    });

    test(
        'a guest\'s result is dropped: not sent and not queued for the next account',
        () async {
      GuestMode.active = true;
      const result = QuizResult(
        era: GuestMode.eraId,
        level: 1,
        type: 'pre_test',
        correctAnswersCount: 3,
        totalQuestions: 5,
        percentage: 60,
        timeTakenTotal: 40,
        questionSnapshots: [],
      );
      await ApiService().submitResult(result); // would throw on a real attempt
      expect(StorageService.getPendingResults(), isEmpty);
    });

    test('a guest\'s wallet, results and progress make no calls', () async {
      GuestMode.active = true;
      expect(await ApiService().saveWallet({'coins': 5}), isTrue);
      expect(await ApiService().getResults(), isEmpty);
      expect(await ApiService().getEraProgress(), isEmpty);
      await ApiService().flushPendingResults();
    });

    test('a guest\'s progress is what this phone saved', () async {
      GuestMode.active = true;
      final era = allEras.firstWhere((e) => e.id == GuestMode.eraId);
      await StorageService.saveLevelCompleted(era.id, 1, 3);
      await StorageService.saveLevelCompleted(era.id, 2, 2);

      final progress = ProgressNotifier();
      await progress.loadProgress();
      expect(progress.getEraProgress(era.id).levelsCompleted, 2);
      expect(progress.getEraProgress(era.id).isCompleted, isFalse);

      await StorageService.saveLevelCompleted(era.id, era.levels.length, 3);
      await progress.loadProgress();
      expect(progress.getEraProgress(era.id).isCompleted, isTrue,
          reason: 'the boss is the last level');
    });

    test('clearing the guest empties the wallet and hearts', () async {
      await StorageService.saveWallet(GuestMode.studentId, {'coins': 99});
      await StorageService.setWalletUnsynced(GuestMode.studentId, true);
      await StorageService.clearGuestData(GuestMode.studentId);
      expect(StorageService.getWallet(GuestMode.studentId), isNull);
      expect(StorageService.getWalletUnsynced(GuestMode.studentId), isFalse);
      expect(StorageService.hasHeartsFor(GuestMode.studentId), isFalse);
    });

    test(
        'starting a guest signs in as "guest", with no token, and starts fresh',
        () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // The secure store has no plugin in a test: answer every call with nothing.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async => null,
      );
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel(
                  'plugins.it_nomads.com/flutter_secure_storage'),
              null));
      await StorageService.saveWallet(GuestMode.studentId, {'coins': 99});
      await StorageService.saveLevelCompleted(GuestMode.eraId, 1, 3);

      final auth = AuthNotifier();
      await auth.startGuest();

      expect(auth.state.isGuest, isTrue);
      expect(auth.state.isLoggedIn, isTrue);
      expect(auth.state.student!.id, GuestMode.studentId);
      expect(GuestMode.active, isTrue);
      expect(StorageService.getWallet(GuestMode.studentId), isNull,
          reason: 'a fresh start');
      expect(StorageService.getCompletedLevels(GuestMode.eraId), isEmpty);

      await auth.logout();
      expect(GuestMode.active, isFalse);
      expect(auth.state.isGuest, isFalse);
    });
  });
}
