// The login screen with the scanner: the scan card where the logo used to be, a
// scan button on narrow phones, and a scanned class code that stays editable.
import 'package:chronoquest/providers/auth_provider.dart';
import 'package:chronoquest/screens/auth/login_screen.dart';
import 'package:chronoquest/widgets/qr_scan_panel.dart';
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

ScannerViewBuilder _camera(String link) => (context, onRaw, onFailure) =>
    TextButton(onPressed: () => onRaw(link), child: const Text('see-code'));

Future<void> _pump(WidgetTester tester, Size size,
    {String link = 'chronoquest://join?code=EDG5A1'}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1.0; // so the size is the logical size
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  await tester.pumpWidget(ProviderScope(
    overrides: [authProvider.overrideWith((ref) => _FakeAuth())],
    child: MaterialApp(home: LoginScreen(scannerBuilder: _camera(link))),
  ));
  await tester.pump(const Duration(seconds: 2)); // the fade-in
}

TextField _classCodeField(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField).first);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a wide screen shows the scan card in place of the logo', (tester) async {
    await _pump(tester, const Size(800, 360));

    expect(find.byType(QrScanPanel), findsOneWidget);
    expect(find.text('I-scan ang QR ng titser'), findsOneWidget);
    expect(find.text('CHRONOQUEST'), findsOneWidget, reason: 'the wordmark stays');
    expect(find.text('Tuklasin ang Kasaysayan\nng Pilipinas'), findsNothing,
        reason: 'the big logo block is gone');
    expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget, reason: 'only the card icon');
    expect(tester.takeException(), isNull);
  });

  testWidgets('scanning fills the Class Code field', (tester) async {
    await _pump(tester, const Size(800, 360));
    await tester.tap(find.text('BUKSAN ANG CAMERA'));
    await tester.pump();
    await tester.tap(find.text('see-code'));
    await tester.pump();

    expect(_classCodeField(tester).controller!.text, 'EDG5A1');
    expect(find.byIcon(Icons.check_circle), findsOneWidget, reason: 'green scanned mark');
  });

  testWidgets('the scanned code stays editable, and the green mark goes when it changes',
      (tester) async {
    await _pump(tester, const Size(800, 360));
    await tester.tap(find.text('BUKSAN ANG CAMERA'));
    await tester.pump();
    await tester.tap(find.text('see-code'));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'EDG5A2');
    await tester.pump();

    expect(_classCodeField(tester).controller!.text, 'EDG5A2');
    expect(_classCodeField(tester).enabled, isNot(false));
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('a wrong QR leaves the field empty', (tester) async {
    await _pump(tester, const Size(800, 360), link: 'https://example.com');
    await tester.tap(find.text('BUKSAN ANG CAMERA'));
    await tester.pump();
    await tester.tap(find.text('see-code'));
    await tester.pump();

    expect(_classCodeField(tester).controller!.text, isEmpty);
    expect(find.textContaining('Hindi ito QR ng ChronoQuest'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a narrow phone has no card but a scan button beside Class Code',
      (tester) async {
    await _pump(tester, const Size(640, 360));

    expect(find.byType(QrScanPanel), findsNothing);
    expect(find.byTooltip('I-scan ang QR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the narrow scan button opens the full-screen scanner and fills the code',
      (tester) async {
    await _pump(tester, const Size(640, 360));
    await tester.tap(find.byTooltip('I-scan ang QR'));
    await tester.pumpAndSettle();
    expect(find.text('I-scan ang QR'), findsWidgets);

    await tester.tap(find.text('see-code'));
    await tester.pumpAndSettle();

    expect(_classCodeField(tester).controller!.text, 'EDG5A1');
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  for (final size in const [Size(800, 360), Size(732, 320), Size(900, 412), Size(640, 360)]) {
    testWidgets('no overflow at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await _pump(tester, size);
      expect(tester.takeException(), isNull);
    });
  }
}
