// A learner whose class has ended joins the new class with its code: type the code, check
// "Is this your class?", move, and see what came along. The server is faked here.
import 'package:chronoquest/models/class_move.dart';
import 'package:chronoquest/models/student.dart';
import 'package:chronoquest/providers/auth_provider.dart';
import 'package:chronoquest/screens/auth/move_up_screen.dart';
import 'package:chronoquest/utils/login_errors.dart';
import 'package:chronoquest/widgets/qr_scan_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _Move {
  final String oldClassCode, username, password, newClassCode;
  final bool takeOver;
  final String? oldGrade, newGrade;
  _Move(this.oldClassCode, this.username, this.password, this.newClassCode,
      this.takeOver, this.oldGrade, this.newGrade);
}

class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  final moves = <_Move>[];

  /// What the next move does: fail with this, or null to succeed.
  MoveUpError? failWith;

  /// The username the server gives back (a number is added when it is taken).
  String newUsername = 'juan';
  bool mustChange = false;

  _FakeAuth() : super(const AuthState());

  @override
  Future<MoveUpResult> moveUp({
    required String oldClassCode,
    required String username,
    required String password,
    required String newClassCode,
    bool takeOver = false,
    String? oldGrade,
    String? newGrade,
  }) async {
    moves.add(_Move(oldClassCode, username, password, newClassCode, takeOver,
        oldGrade, newGrade));
    if (failWith != null) throw failWith!;
    final student = Student.fromJson({
      'id': 's1',
      'name': 'Juan Dela Cruz',
      'username': newUsername,
      'classCode': newClassCode,
      'score': 1250,
      'coins': 340,
      'unlockedCharacters': ['luna', 'bonifacio'],
      'mustChangePassword': mustChange,
    });
    state = AuthState(student: student, isLoggedIn: true);
    return MoveUpResult(
      student: student,
      section: ClassInfo(classCode: newClassCode, sectionName: 'Rosal'),
      fromSection: 'Sampaguita',
      fromYear: '2025-2026',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _args = MoveUpArgs(
  classCode: 'EDG5A1',
  username: 'juan',
  password: 'secret1',
  info: ClassEndedInfo(
    name: 'Juan Dela Cruz',
    username: 'juan',
    sectionName: 'Sampaguita',
    grade: 'Grade 5',
    schoolYear: '2025-2026',
  ),
);

const _rosal = ClassInfo(
  classCode: 'EDG6A1',
  sectionName: 'Rosal',
  gradeLevel: 'grade6',
  grade: 'Grade 6',
  teacherName: 'Ana Reyes',
  schoolName: 'Bangbangalon Elementary School',
  schoolYear: '2026-2027',
);

late _FakeAuth _auth;
late List<String> _asked;

/// What the next look-up does: answers with a class, or throws a message.
Object _lookupResult = _rosal;

ScannerViewBuilder _camera(String code) => (context, onRaw, onFailure) =>
    TextButton(onPressed: () => onRaw(code), child: const Text('see-code'));

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(800, 360),
  MoveUpArgs args = _args,
  List<String>? landedOn,
  List<Object?>? loginExtras,
}) async {
  _auth = _FakeAuth();
  _asked = [];
  _lookupResult = _rosal;
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
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => MoveUpScreen(
        args: args,
        scannerBuilder: _camera('EDG6A1'),
        lookup: (code) async {
          _asked.add(code);
          final r = _lookupResult;
          if (r is String) throw r;
          return r as ClassInfo;
        },
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (_, state) {
        loginExtras?.add(state.extra);
        return const Scaffold(body: Text('login stand-in'));
      },
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

Future<void> _typeCode(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Key key) async {
  // A form taller than a small sideways phone scrolls: bring the button into view first.
  await tester.ensureVisible(find.byKey(key));
  await tester.pump();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// Types the new code and taps TULOY, so "Is this your class?" shows.
Future<void> _toConfirm(WidgetTester tester, {String code = 'edg6a1'}) async {
  await _typeCode(tester, code);
  await _tap(tester, MoveUpScreen.goKey);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('"Tapos na ang klase mo"', () {
    testWidgets('greets the learner by first name and names the old class',
        (tester) async {
      await _pump(tester);

      expect(find.text('Tapos na ang klase mo.'), findsOneWidget);
      final line = tester.widget<Text>(find.byKey(MoveUpScreen.endedKey)).data!;
      expect(line, contains('Hi Juan!'));
      expect(line, contains('Sampaguita (2025-2026)'));
      expect(line, contains('points at progress'));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(MoveUpScreen.goKey), findsOneWidget);
      expect(find.byKey(MoveUpScreen.noCodeKey), findsOneWidget);
    });

    testWidgets(
        'asks nothing of the old class when the server did not say its name',
        (tester) async {
      await _pump(
        tester,
        args: const MoveUpArgs(
          classCode: 'EDG5A1',
          username: 'juan',
          password: 'secret1',
          info: ClassEndedInfo(username: 'juan'),
        ),
      );
      final line = tester.widget<Text>(find.byKey(MoveUpScreen.endedKey)).data!;
      expect(line, startsWith('Hi! Tapos na ang klase mo.'));
    });

    testWidgets('an empty box says to type the code and asks nothing',
        (tester) async {
      await _pump(tester);
      await _tap(tester, MoveUpScreen.goKey);

      expect(find.text('I-type ang bagong class code.'), findsOneWidget);
      expect(_asked, isEmpty);
    });

    testWidgets('the code is sent in capitals and trimmed', (tester) async {
      await _pump(tester);
      await _toConfirm(tester, code: '  edg6a1 ');
      expect(_asked, ['EDG6A1']);
    });

    testWidgets('a wrong code shows the message and stays here',
        (tester) async {
      await _pump(tester);
      _lookupResult =
          'Mali ang class code. Itanong sa teacher mo ang tamang code.';
      await _toConfirm(tester, code: 'NOPE');

      expect(find.textContaining('Mali ang class code'), findsOneWidget);
      expect(find.byKey(MoveUpScreen.classCardKey), findsNothing);
      expect(find.byKey(MoveUpScreen.goKey), findsOneWidget);
    });

    testWidgets('typing again clears the message', (tester) async {
      await _pump(tester);
      _lookupResult =
          'Mali ang class code. Itanong sa teacher mo ang tamang code.';
      await _toConfirm(tester, code: 'NOPE');
      await _typeCode(tester, 'NOP');
      expect(find.textContaining('Mali ang class code'), findsNothing);
    });

    testWidgets('a scanned QR fills the box', (tester) async {
      await _pump(tester);
      await tester.tap(find.byKey(MoveUpScreen.scanKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('see-code'));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'EDG6A1');
    });

    testWidgets(
        '"Wala akong code" goes to the sign-in screen with the line to ask the teacher',
        (tester) async {
      final extras = <Object?>[];
      await _pump(tester, loginExtras: extras);
      await _tap(tester, MoveUpScreen.noCodeKey);

      expect(find.text('login stand-in'), findsOneWidget);
      expect(extras.single, askTeacherForNewCode);
      expect(askTeacherForNewCode, contains('teacher'));
      expect(askTeacherForNewCode, contains('class code'));
      expect(_auth.moves, isEmpty);
    });
  });

  group('"Ito ba ang klase mo?"', () {
    testWidgets(
        'shows the section, the year and grade, the teacher and the school',
        (tester) async {
      await _pump(tester);
      await _toConfirm(tester);

      expect(find.text('Ito ba ang klase mo?'), findsOneWidget);
      expect(find.text('Rosal'), findsOneWidget);
      expect(find.text('2026-2027 · Grade 6'), findsOneWidget);
      expect(find.text('Ana Reyes'), findsOneWidget);
      expect(find.text('Bangbangalon Elementary School'), findsOneWidget);
      expect(find.byKey(MoveUpScreen.yesKey), findsOneWidget);
      expect(find.byKey(MoveUpScreen.noKey), findsOneWidget);
      expect(_auth.moves, isEmpty,
          reason: 'nothing moves until the learner says yes');
    });

    testWidgets(
        '"Hindi, bumalik" goes back to the code box, with the code still in it',
        (tester) async {
      await _pump(tester);
      await _toConfirm(tester);
      await _tap(tester, MoveUpScreen.noKey);

      expect(find.text('Tapos na ang klase mo.'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'edg6a1');
      expect(_auth.moves, isEmpty);
    });

    testWidgets(
        'the back button on the first question leaves for the sign-in screen',
        (tester) async {
      await _pump(tester);
      await _tap(tester, MoveUpScreen.backKey);
      expect(find.text('login stand-in'), findsOneWidget);
    });
  });

  group('moving', () {
    testWidgets(
        '"Oo" sends the old class, username and password with the new code',
        (tester) async {
      await _pump(tester);
      await _toConfirm(tester);
      await _tap(tester, MoveUpScreen.yesKey);

      final m = _auth.moves.single;
      expect(
          (m.oldClassCode, m.username, m.password, m.newClassCode, m.takeOver),
          ('EDG5A1', 'juan', 'secret1', 'EDG6A1', false));
      expect((m.oldGrade, m.newGrade), ('Grade 5', 'Grade 6'));
    });

    testWidgets(
        'then says welcome with the points, coins and heroes that came along',
        (tester) async {
      await _pump(tester);
      await _toConfirm(tester);
      await _tap(tester, MoveUpScreen.yesKey);

      expect(find.text('Welcome sa Rosal!'), findsOneWidget);
      expect(find.text('1250'), findsOneWidget);
      expect(find.text('340'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.byKey(MoveUpScreen.usernameKey), findsNothing,
          reason: 'the username did not change');
      expect(find.byKey(MoveUpScreen.backKey), findsNothing,
          reason: 'a done move is not undone');
      expect(_auth.state.isLoggedIn, isTrue);
    });

    testWidgets('a username the server changed is said out loud',
        (tester) async {
      await _pump(tester);
      _auth.newUsername = 'juan2';
      await _toConfirm(tester);
      await _tap(tester, MoveUpScreen.yesKey);

      expect(find.text('juan2'), findsOneWidget);
      expect(find.text('BAGO ANG USERNAME MO'), findsOneWidget);
      expect(find.textContaining('susunod na login'), findsOneWidget);
    });

    testWidgets('TULOY goes on to the heroes', (tester) async {
      final landed = <String>[];
      await _pump(tester, landedOn: landed);
      await _toConfirm(tester);
      await _tap(tester, MoveUpScreen.yesKey);
      await _tap(tester, MoveUpScreen.startKey);

      expect(landed, ['/character-selection']);
    });

    testWidgets('a learner who must change the password goes there first',
        (tester) async {
      final landed = <String>[];
      await _pump(tester, landedOn: landed);
      _auth.mustChange = true;
      await _toConfirm(tester);
      await _tap(tester, MoveUpScreen.yesKey);
      await _tap(tester, MoveUpScreen.startKey);

      expect(landed, ['/change-password']);
    });

    for (final code in const [
      'WRONG_GRADE',
      'CLASS_FULL',
      'CLASS_ENDED',
      'SAME_CLASS',
      'WRONG_YEAR',
      'YEAR_ENDED',
      'CLASS_NOT_ENDED',
    ]) {
      testWidgets('$code shows its message on the card and moves nothing',
          (tester) async {
        await _pump(tester);
        _auth.failWith = MoveUpError('Mensahe para sa $code.', code: code);
        await _toConfirm(tester);
        await _tap(tester, MoveUpScreen.yesKey);

        expect(find.text('Mensahe para sa $code.'), findsOneWidget);
        expect(find.byKey(MoveUpScreen.classCardKey), findsOneWidget);
        expect(find.byKey(MoveUpScreen.welcomeKey), findsNothing);
        expect(_auth.state.isLoggedIn, isFalse);
      });
    }

    testWidgets('after a message the learner may go back and try another code',
        (tester) async {
      await _pump(tester);
      _auth.failWith = const MoveUpError(
          'Puno na ang klase na ito. Itanong sa teacher mo.',
          code: 'CLASS_FULL');
      await _toConfirm(tester);
      await _tap(tester, MoveUpScreen.yesKey);
      await _tap(tester, MoveUpScreen.noKey);

      expect(find.text('Tapos na ang klase mo.'), findsOneWidget);
      expect(find.textContaining('Puno na ang klase'), findsNothing);
    });
  });

  group('the account is open on another phone', () {
    Future<void> asked(WidgetTester tester) async {
      _auth.failWith =
          const MoveUpError(sessionActiveMessage, code: 'SESSION_ACTIVE');
      await _toConfirm(tester);
      await _tap(tester, MoveUpScreen.yesKey);
    }

    testWidgets('asks first, as the sign-in does', (tester) async {
      await _pump(tester);
      await asked(tester);

      expect(find.text('Gamit na ang account mo sa ibang device.'),
          findsOneWidget);
      expect(find.byKey(MoveUpScreen.sessionGoOnKey), findsOneWidget);
      expect(find.text(sessionActiveMessage), findsNothing,
          reason: 'a question, not a banner');
      expect(_auth.moves.single.takeOver, isFalse);
    });

    testWidgets('"Ituloy dito" sends the move again with takeOver',
        (tester) async {
      await _pump(tester);
      await asked(tester);
      _auth.failWith = null;
      await _tap(tester, MoveUpScreen.sessionGoOnKey);

      expect(_auth.moves, hasLength(2));
      expect(_auth.moves.last.takeOver, isTrue);
      expect(_auth.moves.last.newClassCode, 'EDG6A1');
      expect(find.text('Welcome sa Rosal!'), findsOneWidget);
    });

    testWidgets('"Huwag na" goes back to the class card and sends nothing more',
        (tester) async {
      await _pump(tester);
      await asked(tester);
      await _tap(tester, MoveUpScreen.sessionCancelKey);

      expect(find.byKey(MoveUpScreen.classCardKey), findsOneWidget);
      expect(_auth.moves, hasLength(1));
    });
  });

  for (final size in const [
    Size(732, 320),
    Size(640, 360),
    Size(400, 700),
    Size(320, 568)
  ]) {
    testWidgets(
        'every step fits at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await _pump(tester, size: size);
      _auth.newUsername = 'juan2';
      expect(tester.takeException(), isNull);

      await _toConfirm(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(MoveUpScreen.yesKey), findsOneWidget);

      _auth.failWith =
          const MoveUpError(sessionActiveMessage, code: 'SESSION_ACTIVE');
      await _tap(tester, MoveUpScreen.yesKey);
      expect(tester.takeException(), isNull);
      expect(find.byKey(MoveUpScreen.sessionGoOnKey), findsOneWidget);

      _auth.failWith = null;
      await _tap(tester, MoveUpScreen.sessionGoOnKey);
      expect(tester.takeException(), isNull);
      expect(find.byKey(MoveUpScreen.startKey), findsOneWidget);
    });
  }
}
