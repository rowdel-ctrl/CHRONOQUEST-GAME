// "Forgot password?": the student reads out, or sends, the class code and username
// to the teacher. If the request cannot be sent, the screen says to tell the
// teacher in person, and the same boxes are already on screen for that.
import 'dart:async';

import 'package:chronoquest/screens/auth/auth_widgets.dart';
import 'package:chronoquest/screens/auth/forgot_password_screen.dart';
import 'package:chronoquest/utils/login_errors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _Sent {
  final String classCode, username;
  _Sent(this.classCode, this.username);
}

/// Opens the forgot screen on top of a stand-in sign-in screen, the way the app does.
Future<void> _pump(
  WidgetTester tester, {
  required Future<void> Function(String, String) send,
  Size size = const Size(800, 360),
  String classCode = 'EDG5A1',
  String username = 'JuanNinja99',
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
    GoRoute(
      path: '/',
      builder: (context, _) => Scaffold(
        body: TextButton(
          onPressed: () => context.push('/forgot'),
          child: const Text('sign-in stand-in'),
        ),
      ),
    ),
    GoRoute(
      path: '/forgot',
      builder: (_, __) => ForgotPasswordScreen(
        classCode: classCode,
        username: username,
        send: send,
      ),
    ),
  ]);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pump();
  await tester.tap(find.text('sign-in stand-in'));
  await tester.pumpAndSettle();
}

Future<void> _tapSend(WidgetTester tester) async {
  await tester.tap(find.byKey(ForgotPasswordScreen.sendKey));
  await tester.pump();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows the class code and username to read out, and the two buttons',
      (tester) async {
    await _pump(tester, send: (_, __) async {});

    expect(find.text('I-send ito sa teacher mo:'), findsOneWidget);
    expect(find.text('CLASS CODE'), findsOneWidget);
    expect(find.text('EDG5A1'), findsOneWidget);
    expect(find.text('USERNAME'), findsOneWidget);
    expect(find.text('JuanNinja99'), findsOneWidget);
    expect(find.text('I-SEND SA TEACHER'), findsOneWidget);
    expect(find.text('MAY PASSWORD NA AKO'), findsOneWidget);
    expect(find.text('Okay lang! Hihingi tayo ng reset sa teacher mo.'), findsOneWidget);
    expect(find.byType(AuthGuide), findsOneWidget);
  });

  group('sending', () {
    testWidgets('sends the class code and username once, then says it was sent',
        (tester) async {
      final sent = <_Sent>[];
      await _pump(tester, send: (c, u) async => sent.add(_Sent(c, u)));

      await _tapSend(tester);
      await tester.pumpAndSettle();

      expect(sent, hasLength(1));
      expect((sent.single.classCode, sent.single.username), ('EDG5A1', 'JuanNinja99'));
      expect(find.text('Na-send na!'), findsWidgets);
      expect(find.textContaining('Makikita ito ng teacher mo'), findsOneWidget);
      expect(find.byKey(ForgotPasswordScreen.sendKey), findsNothing,
          reason: 'it is done; no second request from here');
      expect(find.byKey(ForgotPasswordScreen.doneKey), findsOneWidget);
    });

    testWidgets('shows a busy button while it waits, and a second tap does nothing',
        (tester) async {
      final reply = Completer<void>();
      var calls = 0;
      await _pump(tester, send: (_, __) {
        calls++;
        return reply.future;
      });

      await _tapSend(tester);

      expect(find.text('SENDING…'), findsOneWidget);
      expect(find.byKey(ForgotPasswordScreen.sendKey), findsNothing);
      expect(calls, 1);

      reply.complete();
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('Na-send na!'), findsWidgets);
    });

    testWidgets('the other button is switched off while it waits', (tester) async {
      final reply = Completer<void>();
      await _pump(tester, send: (_, __) => reply.future);
      await _tapSend(tester);

      final have = tester.widget<GestureDetector>(find.descendant(
        of: find.byKey(ForgotPasswordScreen.haveKey),
        matching: find.byType(GestureDetector),
      ));
      expect(have.onTap, isNull);

      reply.complete();
      await tester.pumpAndSettle();
    });
  });

  group('when it cannot be sent', () {
    testWidgets('shows the message and lets the student try again', (tester) async {
      var calls = 0;
      await _pump(tester, send: (_, __) async {
        calls++;
        if (calls == 1) throw 'Mabagal o walang internet. Subukan ulit.';
      });

      await _tapSend(tester);
      await tester.pumpAndSettle();

      expect(find.text('Mabagal o walang internet. Subukan ulit.'), findsOneWidget);
      expect(find.text('Hindi na-send. Subukan ulit.'), findsOneWidget);
      expect(find.byKey(ForgotPasswordScreen.sendKey), findsOneWidget);
      expect(find.text('EDG5A1'), findsOneWidget, reason: 'still there to read out');

      await _tapSend(tester);
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('Na-send na!'), findsWidgets);
      expect(find.text('Mabagal o walang internet. Subukan ulit.'), findsNothing);
    });

    testWidgets('anything unexpected tells the student to say it to the teacher',
        (tester) async {
      await _pump(tester, send: (_, __) async => throw StateError('boom'));

      await _tapSend(tester);
      await tester.pumpAndSettle();

      expect(find.text(resetRequestCannotSend), findsOneWidget);
      expect(find.textContaining('boom'), findsNothing, reason: 'no developer text');
    });
  });

  group('leaving', () {
    testWidgets('"May password na ako" goes back without sending', (tester) async {
      var calls = 0;
      await _pump(tester, send: (_, __) async => calls++);

      await tester.tap(find.byKey(ForgotPasswordScreen.haveKey));
      await tester.pumpAndSettle();

      expect(find.text('sign-in stand-in'), findsOneWidget);
      expect(calls, 0);
    });

    testWidgets('the back arrow goes back to sign in', (tester) async {
      await _pump(tester, send: (_, __) async {});

      await tester.tap(find.byKey(ForgotPasswordScreen.backKey));
      await tester.pumpAndSettle();

      expect(find.text('sign-in stand-in'), findsOneWidget);
    });

    testWidgets('after sending, "Bumalik sa login" goes back to sign in', (tester) async {
      await _pump(tester, send: (_, __) async {});
      await _tapSend(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ForgotPasswordScreen.doneKey));
      await tester.pumpAndSettle();

      expect(find.text('sign-in stand-in'), findsOneWidget);
    });
  });

  group('fits small phones', () {
    for (final size in const [
      Size(800, 360),
      Size(732, 320),
      Size(640, 360),
      Size(400, 700),
    ]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        await _pump(tester,
            size: size,
            username: 'a-very-long-username-that-is-twenty-chars',
            send: (_, __) async => throw 'Mabagal o walang internet. Subukan ulit.');
        expect(tester.takeException(), isNull, reason: 'the first look');

        await _tapSend(tester);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'with the longest message');
        expect(find.byKey(ForgotPasswordScreen.sendKey), findsOneWidget);
      });
    }

    testWidgets('the first look needs no scrolling on a short landscape phone',
        (tester) async {
      await _pump(tester, size: const Size(732, 320), send: (_, __) async {});

      final scroll =
          tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      expect(scroll.maxScrollExtent, 0);
    });
  });
}
