// Sign in and sign up, one question at a time: pick "Bago ako" or "Balik na ako"
// first, then answer one box per screen. The QR scan card shows on the class code
// question only; on the others the guide takes its place.
import 'package:chronoquest/models/student.dart';
import 'package:chronoquest/providers/auth_provider.dart';
import 'package:chronoquest/screens/auth/auth_widgets.dart';
import 'package:chronoquest/screens/auth/login_screen.dart';
import 'package:chronoquest/utils/login_errors.dart';
import 'package:chronoquest/widgets/qr_scan_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _Call {
  final String classCode, username, password;
  final String? name;
  _Call(this.classCode, this.username, this.name, this.password);
}

class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  final calls = <_Call>[];

  /// What the next login does: an error message to fail with, or null to succeed.
  String? failWith;
  bool mustChange = false;

  _FakeAuth() : super(const AuthState());

  @override
  void clearError() {
    if (state.error != null) state = state.copyWith(error: null);
  }

  @override
  Future<Map<String, dynamic>> login({
    required String classCode,
    required String username,
    String? name,
    required String password,
  }) async {
    calls.add(_Call(classCode, username, name, password));
    if (failWith != null) {
      state = AuthState(error: failWith);
      return {'success': false};
    }
    state = AuthState(
      isLoggedIn: true,
      student: Student.fromJson({
        'id': 's',
        'name': 'Juan',
        'classCode': classCode,
        'mustChangePassword': mustChange,
      }),
    );
    return {'success': true};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ScannerViewBuilder _camera(String link) => (context, onRaw, onFailure) =>
    TextButton(onPressed: () => onRaw(link), child: const Text('see-code'));

late _FakeAuth _auth;

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(800, 360),
  String link = 'chronoquest://join?code=EDG5A1',
  List<String>? landedOn,
}) async {
  _auth = _FakeAuth();
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => LoginScreen(scannerBuilder: _camera(link)),
    ),
    GoRoute(
      path: '/character-selection',
      builder: (_, __) {
        landedOn?.add('/character-selection');
        return const Scaffold(body: Text('hero stand-in'));
      },
    ),
    GoRoute(
      path: '/change-password',
      builder: (_, __) {
        landedOn?.add('/change-password');
        return const Scaffold(body: Text('password stand-in'));
      },
    ),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [authProvider.overrideWith((ref) => _auth)],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pump();
}

Future<void> _choose(WidgetTester tester, {required bool joining}) async {
  await tester.tap(find.byKey(joining ? LoginScreen.newKey : LoginScreen.returningKey));
  await tester.pump();
}

/// Types into the one box on screen and taps the button.
Future<void> _answer(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.byKey(LoginScreen.nextKey));
  await tester.pump();
}

String _typed(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

Finder get _scanCard => find.byType(QrScanPanel);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('the first screen', () {
    testWidgets('has two choices and nothing to type', (tester) async {
      await _pump(tester);

      expect(find.text('CHRONOQUEST'), findsOneWidget);
      expect(find.text('BAGO AKO'), findsOneWidget);
      expect(find.text('BALIK NA AKO'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(_scanCard, findsNothing);
    });

    testWidgets('"Bago ako" starts five questions, "Balik na ako" three', (tester) async {
      await _pump(tester);
      await _choose(tester, joining: true);
      expect(find.text('Bago ako · Hakbang 1 ng 5'), findsOneWidget);
      expect(find.text('Anong class code ng klase mo?'), findsOneWidget);

      await tester.tap(find.byKey(LoginScreen.backKey));
      await tester.pump();
      await _choose(tester, joining: false);
      expect(find.text('Balik na ako · Hakbang 1 ng 3'), findsOneWidget);
    });
  });

  group('answering', () {
    testWidgets('a new student answers five questions, then joins once', (tester) async {
      await _pump(tester);
      await _choose(tester, joining: true);

      await _answer(tester, 'edg5a1');
      expect(find.text('Ano ang tunay mong pangalan?'), findsOneWidget);
      await _answer(tester, 'Juan Dela Cruz');
      expect(find.text('Gumawa ng username mo.'), findsOneWidget);
      await _answer(tester, 'JuanNinja99');
      expect(find.text('Gumawa ng password.'), findsOneWidget);
      await _answer(tester, 'secret1');
      expect(find.text('Ulitin ang password.'), findsOneWidget);
      expect(find.text('SUMALI SA KLASE'), findsOneWidget);
      expect(_auth.calls, isEmpty, reason: 'nothing is sent until the last answer');

      await _answer(tester, 'secret1');
      await tester.pumpAndSettle();

      expect(_auth.calls, hasLength(1));
      final c = _auth.calls.single;
      expect((c.classCode, c.name, c.username, c.password),
          ('edg5a1', 'Juan Dela Cruz', 'JuanNinja99', 'secret1'));
    });

    testWidgets('a returning student answers three and sends no name', (tester) async {
      await _pump(tester);
      await _choose(tester, joining: false);

      await _answer(tester, 'EDG5A1');
      expect(find.text('Ano ang username mo?'), findsOneWidget);
      await _answer(tester, 'juan');
      expect(find.text('Ano ang password mo?'), findsOneWidget);
      expect(find.text('MAG-LOGIN'), findsOneWidget);
      await _answer(tester, 'abc');
      await tester.pumpAndSettle();

      expect(_auth.calls, hasLength(1));
      expect(_auth.calls.single.name, isNull);
      expect(_auth.calls.single.password, 'abc',
          reason: 'the 6-character rule is for choosing a password, not for logging back in');
    });

    testWidgets('an empty box stays put and says what is missing', (tester) async {
      await _pump(tester);
      await _choose(tester, joining: true);
      await tester.tap(find.byKey(LoginScreen.nextKey));
      await tester.pump();

      expect(find.text('Kailangan ang class code'), findsOneWidget);
      expect(find.text('Anong class code ng klase mo?'), findsOneWidget);

      // Typing clears it.
      await tester.enterText(find.byType(TextField), 'E');
      await tester.pump();
      expect(find.text('Kailangan ang class code'), findsNothing);
    });

    testWidgets('a new password under 6 characters is refused, and the line says so',
        (tester) async {
      await _pump(tester);
      await _choose(tester, joining: true);
      await _answer(tester, 'EDG5A1');
      await _answer(tester, 'Juan');
      await _answer(tester, 'juan1');
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      expect(find.text('Hindi bababa sa 6 na character'), findsOneWidget);
      await tester.tap(find.byKey(LoginScreen.nextKey));
      await tester.pump();

      expect(find.text('Hindi bababa sa 6 na characters'), findsOneWidget);
      expect(find.text('Gumawa ng password.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'abcdef');
      await tester.pump();
      expect(find.text('✓ 6 o higit pang character'), findsOneWidget);
    });

    testWidgets('the repeat must match', (tester) async {
      await _pump(tester);
      await _choose(tester, joining: true);
      await _answer(tester, 'EDG5A1');
      await _answer(tester, 'Juan');
      await _answer(tester, 'juan1');
      await _answer(tester, 'secret1');

      await tester.enterText(find.byType(TextField), 'secret2');
      await tester.pump();
      expect(find.text('Hindi pa magkatugma'), findsOneWidget);
      await tester.tap(find.byKey(LoginScreen.nextKey));
      await tester.pump();

      expect(find.text('Hindi magkatugma ang password'), findsOneWidget);
      expect(_auth.calls, isEmpty);

      await tester.enterText(find.byType(TextField), 'secret1');
      await tester.pump();
      expect(find.text('✓ Magkatugma'), findsOneWidget);
    });

    testWidgets('the back arrow goes to the last question and keeps the answer',
        (tester) async {
      await _pump(tester);
      await _choose(tester, joining: true);
      await _answer(tester, 'EDG5A1');
      await _answer(tester, 'Juan Dela Cruz');
      expect(find.text('Bago ako · Hakbang 3 ng 5'), findsOneWidget);

      await tester.tap(find.byKey(LoginScreen.backKey));
      await tester.pump();
      expect(find.text('Ano ang tunay mong pangalan?'), findsOneWidget);
      expect(_typed(tester), 'Juan Dela Cruz');

      await tester.tap(find.byKey(LoginScreen.backKey));
      await tester.pump();
      expect(_typed(tester), 'EDG5A1');

      await tester.tap(find.byKey(LoginScreen.backKey));
      await tester.pump();
      expect(find.byKey(LoginScreen.newKey), findsOneWidget, reason: 'back on the first screen');
    });
  });

  group('the scan card and the guide', () {
    testWidgets('the scan card is on the class code question only', (tester) async {
      await _pump(tester);
      await _choose(tester, joining: true);
      expect(_scanCard, findsOneWidget);
      expect(find.byType(AuthGuide), findsNothing);
      expect(find.text('CHRONOQUEST'), findsOneWidget, reason: 'the wordmark stays');

      await _answer(tester, 'EDG5A1');
      expect(_scanCard, findsNothing);
      expect(find.byType(AuthGuide), findsOneWidget);
      expect(find.text('Para makilala ka ni titser.'), findsOneWidget);
    });

    testWidgets('scanning fills the class code box and marks it green', (tester) async {
      await _pump(tester);
      await _choose(tester, joining: true);
      await tester.tap(find.text('BUKSAN ANG CAMERA'));
      await tester.pump();
      await tester.tap(find.text('see-code'));
      await tester.pump();

      expect(_typed(tester), 'EDG5A1');
      expect(find.byIcon(Icons.check_circle), findsWidgets);
      expect(find.text('Na-scan mula sa QR ni titser.'), findsOneWidget);
    });

    testWidgets('a scanned code stays editable, and the green mark goes when it changes',
        (tester) async {
      await _pump(tester);
      await _choose(tester, joining: true);
      await tester.tap(find.text('BUKSAN ANG CAMERA'));
      await tester.pump();
      await tester.tap(find.text('see-code'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'EDG5A2');
      await tester.pump();

      expect(_typed(tester), 'EDG5A2');
      expect(find.text('Na-scan mula sa QR ni titser.'), findsNothing);
    });

    testWidgets('a wrong QR leaves the box empty', (tester) async {
      await _pump(tester, link: 'https://example.com');
      await _choose(tester, joining: true);
      await tester.tap(find.text('BUKSAN ANG CAMERA'));
      await tester.pump();
      await tester.tap(find.text('see-code'));
      await tester.pump();

      expect(_typed(tester), isEmpty);
      expect(find.textContaining('Hindi ito QR ng ChronoQuest'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a narrow phone has no card but a scan button inside the box',
        (tester) async {
      await _pump(tester, size: const Size(640, 360));
      await _choose(tester, joining: true);
      expect(_scanCard, findsNothing);
      expect(find.byTooltip('I-scan ang QR'), findsOneWidget);

      await tester.tap(find.byTooltip('I-scan ang QR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('see-code'));
      await tester.pumpAndSettle();

      expect(_typed(tester), 'EDG5A1');
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });
  });

  group('when the server says no', () {
    Future<void> joinAs(WidgetTester tester) async {
      await _choose(tester, joining: true);
      await _answer(tester, 'EDG5A1');
      await _answer(tester, 'Juan Dela Cruz');
      await _answer(tester, 'JuanNinja99');
      await _answer(tester, 'secret1');
      await _answer(tester, 'secret1');
      await tester.pumpAndSettle();
    }

    testWidgets('a taken username goes back to the username question, answers kept',
        (tester) async {
      await _pump(tester);
      const taken = "May gumagamit na ng username na ito sa klase. Kung ikaw iyon, piliin ang 'Babalik'.";
      _auth.failWith = taken;
      await joinAs(tester);

      expect(find.text('Gumawa ng username mo.'), findsOneWidget);
      expect(find.text('Bago ako · Hakbang 3 ng 5'), findsOneWidget);
      expect(find.text(taken), findsOneWidget);
      expect(_typed(tester), 'JuanNinja99');

      // Editing the box clears the message.
      await tester.enterText(find.byType(TextField), 'JuanNinja98');
      await tester.pump();
      expect(find.text(taken), findsNothing);
    });

    testWidgets('a wrong class code goes back to the first question', (tester) async {
      await _pump(tester);
      _auth.failWith = 'Mali ang class code. Itanong sa titser ang tamang code.';
      await joinAs(tester);

      expect(find.text('Anong class code ng klase mo?'), findsOneWidget);
      expect(find.textContaining('Mali ang class code'), findsOneWidget);
      expect(_scanCard, findsOneWidget, reason: 'the scan card is back for another try');
    });

    testWidgets('a wrong password stays on the password question', (tester) async {
      await _pump(tester);
      _auth.failWith = 'Mali ang password. Subukan muli.';
      await _choose(tester, joining: false);
      await _answer(tester, 'EDG5A1');
      await _answer(tester, 'juan');
      await _answer(tester, 'nope');
      await tester.pumpAndSettle();

      expect(find.text('Ano ang password mo?'), findsOneWidget);
      expect(find.text('Mali ang password. Subukan muli.'), findsOneWidget);
    });

    testWidgets('no internet stays on the last question and says so', (tester) async {
      await _pump(tester);
      _auth.failWith = 'Mabagal o walang internet. Subukan muli.';
      await joinAs(tester);

      expect(find.text('Ulitin ang password.'), findsOneWidget);
      expect(find.text('Mabagal o walang internet. Subukan muli.'), findsOneWidget);
    });

    testWidgets('every real server message points at the right question', (tester) async {
      // The messages loginErrorMessage can produce, and the question each is about.
      const expected = {
        'Mali ang class code. Itanong sa titser ang tamang code.': LoginField.classCode,
        'Punan ang class code at username.': LoginField.classCode,
        'May gumagamit na ng username na ito sa klase.': LoginField.username,
        "Walang account na may ganitong username sa class code na ito. Tingnan ang username, o piliin ang 'Bago' para sumali.":
            LoginField.username,
        'Ilagay ang tunay mong pangalan para kay titser.': LoginField.name,
        'Ang password ay hindi bababa sa 6 na characters.': LoginField.password,
        'Mali ang password. Subukan muli.': LoginField.password,
        'Mabagal o walang internet. Subukan muli.': null,
        'Hindi makakonekta sa server. Subukan muli.': null,
        'Masyadong maraming subok. Maghintay sandali bago subukan muli.': null,
        'May problema sa server. Subukan muli mamaya.': null,
      };
      for (final e in expected.entries) {
        expect(loginErrorField(e.key), e.value, reason: e.key);
      }
    });
  });

  group('after a good login', () {
    testWidgets('goes on to choose a hero', (tester) async {
      final landed = <String>[];
      await _pump(tester, landedOn: landed);
      await _choose(tester, joining: false);
      await _answer(tester, 'EDG5A1');
      await _answer(tester, 'juan');
      await _answer(tester, 'abc123');
      await tester.pumpAndSettle();

      expect(find.text('hero stand-in'), findsOneWidget);
    });

    testWidgets('goes to change the password when the teacher set it', (tester) async {
      final landed = <String>[];
      await _pump(tester, landedOn: landed);
      _auth.mustChange = true;
      await _choose(tester, joining: false);
      await _answer(tester, 'EDG5A1');
      await _answer(tester, 'juan');
      await _answer(tester, 'abc123');
      await tester.pumpAndSettle();

      expect(find.text('password stand-in'), findsOneWidget);
    });

    testWidgets('shows a busy button while the server answers', (tester) async {
      await _pump(tester);
      _auth.state = const AuthState(isLoading: true);
      await _choose(tester, joining: false);
      expect(find.text('SANDALI LANG…'), findsOneWidget);
      expect(find.byKey(LoginScreen.nextKey), findsNothing);
    });
  });

  group('fits small phones', () {
    for (final size in const [
      Size(800, 360),
      Size(732, 320),
      Size(900, 412),
      Size(640, 360),
      Size(400, 700),
    ]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        await _pump(tester, size: size);
        expect(tester.takeException(), isNull, reason: 'first screen');

        await _choose(tester, joining: true);
        expect(tester.takeException(), isNull, reason: 'class code question');

        await _answer(tester, 'EDG5A1');
        expect(tester.takeException(), isNull, reason: 'name question with the guide');

        await _answer(tester, 'Juan Dela Cruz');
        _auth.state = const AuthState(
            error: "May gumagamit na ng username na ito sa klase. Kung ikaw iyon, piliin ang 'Babalik'. Kung hindi, gumamit ng ibang username.");
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'the longest message');
      });
    }
  });
}
