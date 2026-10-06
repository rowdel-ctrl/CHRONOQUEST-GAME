// The error under the login form belongs to what was typed and to the tab it came
// from: switching tabs or editing any field clears it. And the "at least 6
// characters" rule is for choosing a password ("Bago"), not for logging back in.
import 'package:chronoquest/providers/auth_provider.dart';
import 'package:chronoquest/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  int logins = 0;

  _FakeAuth(String? error) : super(AuthState(error: error));

  @override
  void clearError() => state = state.copyWith(error: null);

  @override
  Future<Map<String, dynamic>> login({
    required String classCode,
    required String username,
    String? name,
    required String password,
  }) async {
    logins++;
    return {'success': false};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _message = 'Mali ang password. Subukan muli.';
const _lengthRule = 'Hindi bababa sa 6 na characters';

Future<_FakeAuth> _pump(WidgetTester tester, {String? error}) async {
  const size = Size(800, 360);
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  final auth = _FakeAuth(error);
  await tester.pumpWidget(ProviderScope(
    overrides: [authProvider.overrideWith((ref) => auth)],
    child: const MaterialApp(home: LoginScreen()),
  ));
  await tester.pump(const Duration(seconds: 2));
  return auth;
}

Future<void> _scrollDown(WidgetTester tester) async {
  await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -500));
  await tester.pump();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('switching tabs clears the last error', (tester) async {
    await _pump(tester, error: _message);
    await _scrollDown(tester);
    expect(find.text(_message), findsOneWidget);

    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, 500));
    await tester.pump();
    await tester.tap(find.text('Babalik'));
    await tester.pump();

    expect(find.text(_message), findsNothing);
  });

  testWidgets('deleting the class code after a failed try clears the error',
      (tester) async {
    final auth = await _pump(tester);
    await tester.tap(find.text('Babalik'));
    await tester.pump();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'EDG5A1');
    await tester.enterText(fields.at(1), 'juan');
    await tester.enterText(fields.at(2), 'secret1');
    // The server answered "wrong password" for this form.
    auth.state = auth.state.copyWith(error: _message);
    await _scrollDown(tester);
    expect(find.text(_message), findsOneWidget);

    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, 500));
    await tester.pump();
    await tester.enterText(fields.at(0), '');
    await tester.pump();
    await _scrollDown(tester);

    expect(find.text(_message), findsNothing);
  });

  testWidgets('"Babalik" does not apply the 6-character rule', (tester) async {
    final auth = await _pump(tester);
    await tester.tap(find.text('Babalik'));
    await tester.pump();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'EDG5A1');
    await tester.enterText(fields.at(1), 'juan');
    await tester.enterText(fields.at(2), 'abc');
    await _scrollDown(tester);
    await tester.tap(find.text('MAG-LOGIN'));
    await tester.pump();

    expect(find.text(_lengthRule), findsNothing);
    expect(auth.logins, 1, reason: 'the server decides whether it is wrong');
  });

  testWidgets('"Bago" does apply it', (tester) async {
    final auth = await _pump(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'EDG5A1');
    await tester.enterText(fields.at(1), 'juan');
    await tester.enterText(fields.at(2), 'Juan Dela Cruz');
    await tester.enterText(fields.at(3), 'abc');
    await tester.enterText(fields.at(4), 'abc');
    await _scrollDown(tester);
    await tester.tap(find.text('SUMALI SA KLASE'));
    await tester.pump();

    expect(find.text(_lengthRule), findsOneWidget);
    expect(auth.logins, 0);
  });
}
