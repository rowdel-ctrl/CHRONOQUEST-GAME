// One active session per student: the server refuses an old phone's requests with a 401 coded
// SESSION_REPLACED, and the game tells the student over whatever screen is open, with one button
// back to the login screen.
import 'package:chronoquest/services/session_replaced.dart';
import 'package:chronoquest/widgets/session_replaced_gate.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Response<dynamic> _response(int status, dynamic data) => Response<dynamic>(
      requestOptions: RequestOptions(path: '/student/profile'),
      statusCode: status,
      data: data,
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  void reset() {
    SessionReplaced.notifier.value = false;
    SessionReplaced.endedNotifier.value = false;
  }

  setUp(reset);
  tearDown(reset);

  DioException refused(int status, {dynamic data, bool withLogin = true}) {
    final options = RequestOptions(
      path: '/student/profile',
      headers: {if (withLogin) 'Authorization': 'Bearer old-token'},
    );
    return DioException(
      requestOptions: options,
      response: Response<dynamic>(requestOptions: options, statusCode: status, data: data),
      type: DioExceptionType.badResponse,
    );
  }

  group('what a refusal of a request means', () {
    test('a 401 coded SESSION_REPLACED is "signed in elsewhere"', () {
      expect(SessionReplaced.classify(refused(401, data: {'code': 'SESSION_REPLACED'})),
          LoginRefusal.replaced);
    });

    test('any other 401 on a request that carried a saved login means the login ended', () {
      expect(SessionReplaced.classify(refused(401, data: {'message': 'Invalid token.'})),
          LoginRefusal.ended);
      expect(SessionReplaced.classify(refused(401, data: 'Not found')), LoginRefusal.ended);
      expect(SessionReplaced.classify(refused(401)), LoginRefusal.ended);
    });

    test('a 401 with no saved login (a wrong password at the sign-in screen) is nothing', () {
      expect(SessionReplaced.classify(refused(401, data: {'message': 'Incorrect password'}, withLogin: false)),
          LoginRefusal.none);
    });

    test('other answers, and no answer at all, are nothing', () {
      for (final status in [400, 403, 404, 409, 429, 500]) {
        expect(SessionReplaced.classify(refused(status, data: {'code': 'SESSION_REPLACED'})),
            LoginRefusal.none, reason: '$status');
      }
      final noAnswer = DioException(
        requestOptions: RequestOptions(path: '/x', headers: {'Authorization': 'Bearer t'}),
        type: DioExceptionType.connectionError,
      );
      expect(SessionReplaced.classify(noAnswer), LoginRefusal.none);
    });
  });

  group('which refusals mean "signed in elsewhere"', () {
    test('only a 401 with the SESSION_REPLACED code', () {
      expect(
          SessionReplaced.isReplaced(_response(401, {'success': false, 'code': 'SESSION_REPLACED'})),
          isTrue);
    });

    test('an ordinary 401 (expired token, deleted account) is not', () {
      expect(SessionReplaced.isReplaced(_response(401, {'message': 'No token provided.'})), isFalse);
      expect(SessionReplaced.isReplaced(_response(401, 'text')), isFalse);
      expect(SessionReplaced.isReplaced(_response(401, null)), isFalse);
    });

    test('the code on another status, or no response at all, is not', () {
      expect(SessionReplaced.isReplaced(_response(403, {'code': 'SESSION_REPLACED'})), isFalse);
      expect(SessionReplaced.isReplaced(null), isFalse);
    });
  });

  group('the notice', () {
    Widget app({required Future<void> Function() onReturn}) => MaterialApp(
          home: SessionReplacedGate(
            onReturnToLogin: onReturn,
            child: const Scaffold(body: Center(child: Text('the game'))),
          ),
        );

    testWidgets('is not there until the server says so', (tester) async {
      await tester.pumpWidget(app(onReturn: () async {}));
      expect(find.text('the game'), findsOneWidget);
      expect(find.byKey(SessionReplacedGate.cardKey), findsNothing);
    });

    testWidgets('appears over the screen, says why, and one button returns to login',
        (tester) async {
      var returned = 0;
      await tester.pumpWidget(app(onReturn: () async => returned++));
      SessionReplaced.notifier.value = true;
      await tester.pump();

      expect(find.text('Ginamit ang account mo sa ibang device'), findsOneWidget);
      expect(find.text('BUMALIK SA LOGIN'), findsOneWidget);

      await tester.tap(find.byKey(SessionReplacedGate.buttonKey));
      await tester.pump();
      expect(returned, 1);
      expect(SessionReplaced.notifier.value, isFalse, reason: 'acknowledged: it does not come back');
      expect(find.byKey(SessionReplacedGate.cardKey), findsNothing);
    });

    testWidgets('"your login ended" has its own words and the same one button', (tester) async {
      var returned = 0;
      await tester.pumpWidget(app(onReturn: () async => returned++));
      SessionReplaced.endedNotifier.value = true;
      await tester.pump();

      expect(find.text('Tapos na ang login mo'), findsOneWidget);
      expect(find.text('Ginamit ang account mo sa ibang device'), findsNothing);
      expect(find.textContaining('Mag-login ulit'), findsOneWidget);

      await tester.tap(find.byKey(SessionReplacedGate.buttonKey));
      await tester.pump();
      expect(returned, 1);
      expect(SessionReplaced.endedNotifier.value, isFalse);
      expect(find.byKey(SessionReplacedGate.cardKey), findsNothing);
    });

    testWidgets('"signed in elsewhere" wins when both are raised', (tester) async {
      await tester.pumpWidget(app(onReturn: () async {}));
      SessionReplaced.endedNotifier.value = true;
      SessionReplaced.notifier.value = true;
      await tester.pump();
      expect(find.text('Ginamit ang account mo sa ibang device'), findsOneWidget);
      expect(find.text('Tapos na ang login mo'), findsNothing);
    });

    testWidgets('blocks taps on the screen under it', (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: SessionReplacedGate(
          onReturnToLogin: () async {},
          child: Scaffold(
            body: Center(
              child: ElevatedButton(onPressed: () => taps++, child: const Text('under')),
            ),
          ),
        ),
      ));
      SessionReplaced.notifier.value = true;
      await tester.pump();
      await tester.tap(find.text('under'), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('fits a small sideways phone', (tester) async {
      tester.view.physicalSize = const Size(640, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(onReturn: () async {}));
      SessionReplaced.notifier.value = true;
      await tester.pump();
      expect(tester.takeException(), isNull);
      final button = tester.getRect(find.byKey(SessionReplacedGate.buttonKey));
      expect(button.bottom, lessThanOrEqualTo(320));
    });
  });
}
