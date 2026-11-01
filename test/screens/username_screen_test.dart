// The screen a new student sees once, right after joining: the username the server made.
import 'package:chronoquest/models/student.dart';
import 'package:chronoquest/providers/auth_provider.dart';
import 'package:chronoquest/screens/auth/username_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuth(String username)
      : super(AuthState(
          student: Student.fromJson({'id': 's', 'name': 'Juan Dela Cruz', 'username': username}),
          isLoggedIn: true,
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(
  WidgetTester tester, {
  String username = 'juandelacruz',
  Size size = const Size(800, 360),
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const UsernameScreen()),
    GoRoute(
      path: '/character-selection',
      builder: (_, __) => const Scaffold(body: Text('hero stand-in')),
    ),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [authProvider.overrideWith((ref) => _FakeAuth(username))],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pump();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows the username the server made, and says to keep it', (tester) async {
    await _open(tester);

    expect(find.text('Ito ang username mo.'), findsOneWidget);
    expect(find.text('juandelacruz'), findsOneWidget);
    expect(find.text('Isulat mo o i-screenshot ito, ha!'), findsOneWidget);
    expect(find.textContaining('ibang phone'), findsOneWidget);
  });

  testWidgets('copy puts the username on the clipboard and says it did', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await _open(tester);

    expect(find.text('KOPYAHIN'), findsOneWidget);
    await tester.tap(find.byKey(UsernameScreen.copyKey));
    await tester.pump();

    expect(copied, 'juandelacruz');
    expect(find.text('NAKOPYA'), findsOneWidget);
  });

  testWidgets('TULOY goes on to choose a hero', (tester) async {
    await _open(tester);
    await tester.tap(find.byKey(UsernameScreen.goKey));
    await tester.pumpAndSettle();
    expect(find.text('hero stand-in'), findsOneWidget);
  });

  testWidgets('a long username shrinks to fit instead of overflowing', (tester) async {
    for (final size in const [Size(732, 320), Size(640, 360), Size(400, 700)]) {
      await _open(tester, username: 'maryjanedeguzman'.padRight(24, 'x'), size: size);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });
}
