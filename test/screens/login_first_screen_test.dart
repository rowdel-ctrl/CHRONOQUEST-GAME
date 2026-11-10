// The first screen's extras: the living backdrop, the "Alam mo ba?" line and the
// two corners (the connection, and the version).
import 'package:chronoquest/core/app_info.dart';
import 'package:chronoquest/data/login_facts.dart';
import 'package:chronoquest/providers/auth_provider.dart';
import 'package:chronoquest/screens/splash/splash_screen.dart';
import 'package:chronoquest/screens/auth/login_screen.dart';
import 'package:chronoquest/widgets/connection_corner.dart';
import 'package:chronoquest/widgets/fact_ticker.dart';
import 'package:chronoquest/widgets/living_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuth() : super(const AuthState());

  @override
  void clearError() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(
  WidgetTester tester, {
  Size size = const Size(800, 360),
  ValueNotifier<bool?>? connection,
  VoidCallback? check,
  bool animations = false,
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
  await tester.pumpWidget(ProviderScope(
    overrides: [authProvider.overrideWith((ref) => _FakeAuth())],
    child: MaterialApp(
      home: LoginScreen(
        // No camera in a test.
        scannerBuilder: (context, onRaw, onFailure) => const SizedBox(),
        connection: connection ?? ValueNotifier<bool?>(true),
        checkConnection: check ?? () {},
        lastSignIn: () => null,
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('the living backdrop', () {
    testWidgets('is behind the first screen and moves', (tester) async {
      await _open(tester, animations: true);

      expect(find.byKey(ChoiceKeys.backdrop), findsOneWidget);
      expect(find.byType(Bob), findsOneWidget, reason: 'the hero breathes');
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('does not get in the way of the two buttons', (tester) async {
      await _open(tester, animations: true);

      expect(find.byKey(LoginScreen.newKey), findsOneWidget);
      await tester.tap(find.byKey(LoginScreen.newKey));
      await tester.pump();
      expect(find.text('Anong class code ng klase mo?'), findsOneWidget);
      expect(find.byKey(ChoiceKeys.backdrop), findsNothing,
          reason: 'the questions stay as they are');
      expect(find.byType(FactTicker), findsNothing);
    });

    testWidgets('stands still when the phone removes animations',
        (tester) async {
      await _open(tester);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('the left side', () {
    testWidgets('has the name, the tagline and both free heroes facing right',
        (tester) async {
      await _open(tester);

      expect(find.text('CHRONOQUEST'), findsOneWidget);
      expect(find.text(SplashScreen.tagline), findsOneWidget);
      expect(find.byKey(ChoiceKeys.juan), findsOneWidget);
      expect(find.byKey(ChoiceKeys.maria), findsOneWidget);
      String? asset(Key k) {
        final image = tester.widget<Image>(
            find.descendant(of: find.byKey(k), matching: find.byType(Image)));
        return (image.image as AssetImage).assetName;
      }

      expect(asset(ChoiceKeys.juan), 'assets/characters/boy_idle.png');
      expect(asset(ChoiceKeys.maria), 'assets/characters/girl_idle.png');
      expect(
          find.byType(Transform).evaluate().where((e) {
            final t = e.widget as Transform;
            return t.transform.entry(0, 0) < 0;
          }),
          isEmpty,
          reason: 'nobody is mirrored: both face right');
      // Juan on the left, close to Maria.
      final j = tester.getRect(find.byKey(ChoiceKeys.juan));
      final m = tester.getRect(find.byKey(ChoiceKeys.maria));
      expect(j.right, lessThanOrEqualTo(m.left));
      expect(m.left - j.right, lessThan(12));
      // Luna no longer walks here.
      expect(
          find.byWidgetPredicate((w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName.contains('luna')),
          findsNothing);
    });

    testWidgets('the heroes stand left of the buttons and keep the three words',
        (tester) async {
      await _open(tester);
      final maria = tester.getRect(find.byKey(ChoiceKeys.maria));
      expect(maria.right,
          lessThan(tester.getRect(find.byKey(LoginScreen.newKey)).left));
      expect(find.text('BAGO AKO'), findsOneWidget);
      expect(find.text('BALIK NA AKO'), findsOneWidget);
      expect(find.text('PLAY AS A GUEST'), findsOneWidget);
    });

    testWidgets(
        'on a narrow phone the heroes sit between the name and the buttons',
        (tester) async {
      await _open(tester, size: const Size(400, 700));
      final title = tester.getRect(find.text('CHRONOQUEST'));
      final hero = tester.getRect(find.byKey(ChoiceKeys.juan));
      final buttons = tester.getRect(find.byKey(LoginScreen.newKey));
      expect(hero.top, greaterThanOrEqualTo(title.bottom));
      expect(hero.bottom, lessThanOrEqualTo(buttons.top));
    });
  });

  group('the "Alam mo ba?" line', () {
    testWidgets('is at the foot of the first screen with a real fact',
        (tester) async {
      await _open(tester);

      expect(find.byKey(ChoiceKeys.fact), findsOneWidget);
      expect(find.textContaining('Alam mo ba?'), findsOneWidget);
      expect(
        loginFacts
            .where((f) => find.textContaining(f.text).evaluate().isNotEmpty),
        hasLength(1),
      );
    });
  });

  group('the corners', () {
    testWidgets('show the version', (tester) async {
      await _open(tester);
      expect(find.text('v$appVersion'), findsOneWidget);
    });

    testWidgets(
        'the connection icon says "Walang internet" only when it cannot connect',
        (tester) async {
      final status = ValueNotifier<bool?>(true);
      await _open(tester, connection: status);
      expect(find.byKey(ConnectionCorner.chipKey), findsOneWidget);
      expect(find.text('Walang internet'), findsNothing);

      status.value = false;
      await tester.pump();
      expect(find.text('Walang internet'), findsOneWidget);

      status.value = true;
      await tester.pump();
      expect(find.text('Walang internet'), findsNothing);
    });

    testWidgets('with no internet the two buttons still work', (tester) async {
      await _open(tester, connection: ValueNotifier<bool?>(false));

      await tester.tap(find.byKey(LoginScreen.returningKey));
      await tester.pump();
      expect(find.text('Anong class code ng klase mo?'), findsOneWidget);
    });

    testWidgets(
        'asks for the connection when it opens, then every 20 seconds, not after',
        (tester) async {
      var asked = 0;
      await _open(tester, check: () => asked++);
      expect(asked, 1);

      await tester.pump(const Duration(seconds: 19));
      expect(asked, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(asked, 2);
      await tester.pump(const Duration(seconds: 20));
      expect(asked, 3);

      // Once the student has chosen, this screen is gone and so is the asking.
      await tester.tap(find.byKey(LoginScreen.newKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 60));
      expect(asked, 3);
    });
  });

  for (final size in const [Size(732, 320), Size(640, 360), Size(400, 700)]) {
    testWidgets(
        'fits ${size.width.toInt()}x${size.height.toInt()} with nothing overlapping the buttons',
        (tester) async {
      await _open(tester,
          size: size,
          animations: true,
          connection: ValueNotifier<bool?>(false));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      final fact = tester.getRect(find.byKey(ChoiceKeys.fact));
      final buttons = tester.getRect(find.byKey(LoginScreen.returningKey));
      expect(fact.top, greaterThanOrEqualTo(buttons.bottom),
          reason: 'the fact line sits under the second button');
      expect(fact.bottom, lessThanOrEqualTo(size.height));
      expect(tester.getRect(find.byKey(ConnectionCorner.chipKey)).right,
          lessThanOrEqualTo(size.width));
    });
  }
}
