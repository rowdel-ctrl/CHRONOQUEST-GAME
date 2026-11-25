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
  setUp(() => SessionReplaced.notifier.value = false);
  tearDown(() => SessionReplaced.notifier.value = false);

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
