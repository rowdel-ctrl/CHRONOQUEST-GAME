// The welcome a new student sees once, right after joining: confetti, a hero
// jumping for joy and their first name, then on to the username.
import 'package:chronoquest/models/student.dart';
import 'package:chronoquest/providers/auth_provider.dart';
import 'package:chronoquest/screens/auth/welcome_screen.dart';
import 'package:chronoquest/widgets/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuth(String name)
      : super(AuthState(
          student: Student.fromJson({'id': 's', 'name': name, 'username': 'juandelacruz'}),
          isLoggedIn: true,
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(
  WidgetTester tester, {
  String name = 'Juan Dela Cruz',
  Size size = const Size(800, 360),
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
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const WelcomeScreen()),
    GoRoute(
      path: '/your-username',
      builder: (_, __) => const Scaffold(body: Text('username stand-in')),
    ),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [authProvider.overrideWith((ref) => _FakeAuth(name))],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pump();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('the first name is the first word', () {
    expect(firstNameOf('Juan Dela Cruz'), 'Juan');
    expect(firstNameOf('  Maria   Clara Santos '), 'Maria');
    expect(firstNameOf('Juan'), 'Juan');
    expect(firstNameOf(''), '');
  });

  testWidgets('welcomes the student by first name', (tester) async {
    await _open(tester);

    expect(find.text('Maligayang pagdating,'), findsOneWidget);
    expect(find.byKey(WelcomeScreen.nameKey), findsOneWidget);
    expect(find.text('Juan!'), findsOneWidget);
    expect(find.text('TULOY'), findsOneWidget);
  });

  testWidgets('a student with no name still gets a welcome', (tester) async {
    await _open(tester, name: '');

    expect(find.text('Maligayang pagdating!'), findsOneWidget);
    expect(find.byKey(WelcomeScreen.nameKey), findsNothing);
  });

  testWidgets('a long first name shrinks instead of overflowing', (tester) async {
    await _open(tester, name: 'Maximilianoooooooooooooooooooo Dela Cruz', size: const Size(400, 700));

    expect(tester.takeException(), isNull);
    expect(find.byKey(WelcomeScreen.nameKey), findsOneWidget);
  });

  testWidgets('TULOY goes to the username', (tester) async {
    await _open(tester);

    await tester.tap(find.byKey(WelcomeScreen.goKey));
    await tester.pumpAndSettle();

    expect(find.text('username stand-in'), findsOneWidget);
  });

  testWidgets('the confetti falls, unless the phone removes animations', (tester) async {
    await _open(tester, animations: true);
    expect(find.byType(Confetti), findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);

    await _open(tester, animations: false);
    expect(tester.hasRunningAnimations, isFalse);
  });

  for (final size in const [Size(732, 320), Size(640, 360), Size(400, 700)]) {
    testWidgets('fits ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await _open(tester, size: size, animations: true);
      await tester.pump(const Duration(milliseconds: 700));

      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.byKey(WelcomeScreen.goKey)).bottom, lessThanOrEqualTo(size.height));
    });
  }
}
