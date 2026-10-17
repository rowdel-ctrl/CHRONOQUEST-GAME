// Change password: two big boxes, a line that turns green as the password becomes
// good enough, and a button that waits until both rules are met.
import 'package:chronoquest/screens/auth/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

late List<String> _saved;
Object? _failWith;

Future<void> _fakeSave(String password) async {
  if (_failWith != null) throw _failWith!;
  _saved.add(password);
}

Future<void> _pump(WidgetTester tester, {Size size = const Size(800, 360)}) async {
  _saved = [];
  _failWith = null;
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const ChangePasswordScreen(save: _fakeSave)),
    GoRoute(
      path: '/character-selection',
      builder: (_, __) => const Scaffold(body: Text('hero stand-in')),
    ),
  ]);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pump();
}

Future<void> _type(WidgetTester tester, {String first = '', String second = ''}) async {
  await tester.enterText(find.byKey(ChangePasswordScreen.newKey).descendantsOf<TextField>(), first);
  await tester.enterText(
      find.byKey(ChangePasswordScreen.confirmKey).descendantsOf<TextField>(), second);
  await tester.pump();
}

extension on Finder {
  Finder descendantsOf<T extends Widget>() =>
      find.descendant(of: this, matching: find.byType(T));
}

bool _saveEnabled(WidgetTester tester) {
  // A disabled GameButton has no tap handler: a tap does nothing.
  final button = find.byKey(ChangePasswordScreen.saveKey);
  return button.evaluate().isNotEmpty &&
      tester.widget<GestureDetector>(find.descendant(
              of: button, matching: find.byType(GestureDetector)).first).onTap !=
          null;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('opens with two empty boxes and a grey button', (tester) async {
    await _pump(tester);

    expect(find.text('BAGONG PASSWORD'), findsOneWidget);
    expect(find.text('ULITIN ANG PASSWORD'), findsOneWidget);
    expect(find.text('Gumawa ng sarili mong password. Ikaw lang ang dapat makaalam.'),
        findsOneWidget);
    expect(_saveEnabled(tester), isFalse);
  });

  testWidgets('the line ticks green at 6 characters', (tester) async {
    await _pump(tester);
    await _type(tester, first: 'abcd');
    expect(find.text('✓ 6 o higit pang character'), findsNothing);

    await _type(tester, first: 'abcdef');
    expect(find.text('✓ 6 o higit pang character'), findsOneWidget);
    expect(_saveEnabled(tester), isFalse, reason: 'the repeat is still empty');
  });

  testWidgets('the repeat must match, and says so while it does not', (tester) async {
    await _pump(tester);
    await _type(tester, first: 'abcdef', second: 'abcde');

    expect(find.text('Hindi pareho ang dalawa.'), findsOneWidget);
    expect(find.text('Halos tama na! Dapat pareho ang dalawa.'), findsOneWidget);
    expect(_saveEnabled(tester), isFalse);
  });

  testWidgets('a short password never enables the button, even when both match',
      (tester) async {
    await _pump(tester);
    await _type(tester, first: 'abc', second: 'abc');
    expect(_saveEnabled(tester), isFalse);
  });

  testWidgets('both rules met: the guide cheers and the button saves and moves on',
      (tester) async {
    await _pump(tester);
    await _type(tester, first: 'secret1', second: 'secret1');

    expect(find.text('Ayos! Handa ka na.'), findsOneWidget);
    expect(find.text('✓ 6 o higit pang character   ✓ Pareho na'), findsOneWidget);
    expect(_saveEnabled(tester), isTrue);

    await tester.tap(find.byKey(ChangePasswordScreen.saveKey));
    await tester.pumpAndSettle();

    expect(_saved, ['secret1']);
    expect(find.text('hero stand-in'), findsOneWidget);
  });

  testWidgets('a failed save says so in Filipino, stays, and clears when typing',
      (tester) async {
    await _pump(tester);
    _failWith = 'Hindi ma-save ang password. I-check ang internet at subukan ulit.';
    await _type(tester, first: 'secret1', second: 'secret1');
    await tester.tap(find.byKey(ChangePasswordScreen.saveKey));
    await tester.pumpAndSettle();

    expect(find.text(_failWith as String), findsOneWidget);
    expect(find.text('Hindi pa na-save. Subukan ulit.'), findsOneWidget);
    expect(find.text('hero stand-in'), findsNothing);
    expect(_saved, isEmpty);

    await _type(tester, first: 'secret12', second: 'secret12');
    expect(find.text(_failWith as String), findsNothing);
  });

  testWidgets('a failure that is not a ready message still reads as a plain sentence',
      (tester) async {
    await _pump(tester);
    _failWith = StateError('boom');
    await _type(tester, first: 'secret1', second: 'secret1');
    await tester.tap(find.byKey(ChangePasswordScreen.saveKey));
    await tester.pumpAndSettle();

    expect(find.text('Hindi ma-save ang password. Subukan ulit.'), findsOneWidget);
  });

  testWidgets('the eye shows what was typed', (tester) async {
    await _pump(tester);
    await _type(tester, first: 'secret1');
    TextField field() => tester.widget<TextField>(
        find.byKey(ChangePasswordScreen.newKey).descendantsOf<TextField>());
    expect(field().obscureText, isTrue);

    await tester.tap(find.descendant(
        of: find.byKey(ChangePasswordScreen.newKey), matching: find.byType(IconButton)));
    await tester.pump();
    expect(field().obscureText, isFalse);
  });

  testWidgets('has no way back: it is required', (tester) async {
    await _pump(tester);
    expect(find.byTooltip('Bumalik'), findsNothing);
    expect(find.byType(BackButton), findsNothing);
  });

  for (final size in const [
    Size(800, 360),
    Size(732, 320),
    Size(900, 412),
    Size(640, 360),
    Size(400, 700),
  ]) {
    testWidgets('fits ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await _pump(tester, size: size);
      expect(tester.takeException(), isNull);
      await _type(tester, first: 'secret1', second: 'secret2');
      expect(tester.takeException(), isNull);
      _failWith = 'Hindi ma-save ang password. I-check ang internet at subukan ulit.';
      await _type(tester, first: 'secret1', second: 'secret1');
      await tester.tap(find.byKey(ChangePasswordScreen.saveKey));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'with the error banner');
    });
  }
}
