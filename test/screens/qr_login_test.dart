// Scanning a section QR code on the login screen. A fake camera view stands in
// for the real one, so no camera or plugin is needed.
import 'package:chronoquest/widgets/qr_scan_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// A camera that shows two buttons: one "sees" [good], one "sees" a web link, and
/// a third makes the camera fail.
ScannerViewBuilder _fakeCamera({String good = 'chronoquest://join?code=EDG5A1'}) {
  return (context, onRaw, onFailure) => FittedBox(
          child: Column(
        children: [
          TextButton(onPressed: () => onRaw(good), child: const Text('see-good')),
          TextButton(
              onPressed: () => onRaw('https://example.com'),
              child: const Text('see-web')),
          TextButton(
              onPressed: () => onFailure(ScanFailure.denied),
              child: const Text('deny')),
        ],
      ));
}

Future<void> _pump(WidgetTester tester, Widget child,
    {Size size = const Size(800, 360)}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1.0; // so the size is the logical size
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(backgroundColor: const Color(0xFF140E1F), body: Center(child: child)),
  ));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('the scan card', () {
    testWidgets('starts with the camera off', (tester) async {
      await _pump(tester, QrScanPanel(onCode: (_) {}, scannerBuilder: _fakeCamera()));

      expect(find.text('I-scan ang QR ng titser'), findsOneWidget);
      expect(find.text('see-good'), findsNothing, reason: 'no camera until tapped');
    });

    testWidgets('tapping it opens the camera', (tester) async {
      await _pump(tester, QrScanPanel(onCode: (_) {}, scannerBuilder: _fakeCamera()));
      await tester.tap(find.text('BUKSAN ANG CAMERA'));
      await tester.pump();

      expect(find.text('see-good'), findsOneWidget);
      expect(find.text('Itapat sa QR code ng titser'), findsOneWidget);
    });

    testWidgets('a good scan reports the code and shows it', (tester) async {
      String? got;
      await _pump(tester, QrScanPanel(onCode: (c) => got = c, scannerBuilder: _fakeCamera()));
      await tester.tap(find.text('BUKSAN ANG CAMERA'));
      await tester.pump();
      await tester.tap(find.text('see-good'));
      await tester.pump();

      expect(got, 'EDG5A1');
      expect(find.text('Nakuha na ang class code'), findsOneWidget);
      expect(find.text('EDG5A1'), findsOneWidget);
      expect(find.text('see-good'), findsNothing, reason: 'the camera stopped');
    });

    testWidgets('a wrong QR shows a message, fills nothing, and keeps scanning',
        (tester) async {
      String? got;
      await _pump(tester, QrScanPanel(onCode: (c) => got = c, scannerBuilder: _fakeCamera()));
      await tester.tap(find.text('BUKSAN ANG CAMERA'));
      await tester.pump();
      await tester.tap(find.text('see-web'));
      await tester.pump();

      expect(find.textContaining('Hindi ito QR ng ChronoQuest'), findsOneWidget);
      expect(got, isNull);
      expect(find.text('see-good'), findsOneWidget, reason: 'still looking');

      // The message goes away on its own, and a good code still works after it.
      await tester.pump(const Duration(seconds: 3));
      expect(find.textContaining('Hindi ito QR ng ChronoQuest'), findsNothing);
      await tester.tap(find.text('see-good'));
      await tester.pump();
      expect(got, 'EDG5A1');
    });

    testWidgets('a refused camera says so and offers to try again', (tester) async {
      await _pump(tester, QrScanPanel(onCode: (_) {}, scannerBuilder: _fakeCamera()));
      await tester.tap(find.text('BUKSAN ANG CAMERA'));
      await tester.pump();
      await tester.tap(find.text('deny'));
      await tester.pump();

      expect(find.text('Walang pahintulot sa camera'), findsOneWidget);
      expect(find.textContaining('Pwede pa ring i-type'), findsOneWidget);

      await tester.tap(find.text('Subukan ulit'));
      await tester.pump();
      expect(find.text('see-good'), findsOneWidget);
    });

    testWidgets('"Isara" closes the camera again', (tester) async {
      await _pump(tester, QrScanPanel(onCode: (_) {}, scannerBuilder: _fakeCamera()));
      await tester.tap(find.text('BUKSAN ANG CAMERA'));
      await tester.pump();
      await tester.tap(find.text('Isara'));
      await tester.pump();

      expect(find.text('I-scan ang QR ng titser'), findsOneWidget);
      expect(find.text('see-good'), findsNothing);
    });

    testWidgets('"I-scan ulit" after a scan opens the camera again', (tester) async {
      await _pump(tester, QrScanPanel(onCode: (_) {}, scannerBuilder: _fakeCamera()));
      await tester.tap(find.text('BUKSAN ANG CAMERA'));
      await tester.pump();
      await tester.tap(find.text('see-good'));
      await tester.pump();
      await tester.tap(find.text('I-scan ulit'));
      await tester.pump();

      expect(find.text('see-good'), findsOneWidget);
    });

    // The card sits in a 360-tall landscape screen with 24 of padding each side.
    for (final size in const [
      Size(800, 360),
      Size(732, 320),
      Size(900, 412),
      Size(1024, 600),
      Size(1280, 800),
    ]) {
      testWidgets('fits a ${size.width.toInt()}x${size.height.toInt()} screen in every state',
          (tester) async {
        await _pump(
          tester,
          SizedBox(
            // 24 of padding each side, and the wordmark above the card.
            height: size.height - 48 - 38,
            child: Center(
              child: QrScanPanel(onCode: (_) {}, scannerBuilder: _fakeCamera()),
            ),
          ),
          size: size,
        );
        expect(tester.takeException(), isNull, reason: 'idle');

        await tester.tap(find.text('BUKSAN ANG CAMERA'));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'scanning');

        await tester.tap(find.text('see-web'));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'wrong QR');
        await tester.pump(const Duration(seconds: 3));

        await tester.tap(find.text('see-good'));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'scanned');
      });
    }
  });

  group('the live camera view', () {
    Future<double> cameraSide(WidgetTester tester, Size size) async {
      await _pump(
        tester,
        SizedBox(
          width: size.width / 2,
          height: size.height - 48 - 38, // padding and the wordmark
          child: Center(
            child: QrScanPanel(onCode: (_) {}, scannerBuilder: _fakeCamera()),
          ),
        ),
        size: size,
      );
      await tester.tap(find.text('BUKSAN ANG CAMERA'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      return tester.getSize(find.descendant(
          of: find.byType(QrScanner), matching: find.byType(ClipRect))).width;
    }

    // Playtest 2026-10-06: the camera was still too small on a phone.
    testWidgets('uses the height a landscape phone has left, not a fixed 136',
        (tester) async {
      expect(await cameraSide(tester, const Size(800, 360)), greaterThan(180));
    });

    testWidgets('is still bigger than before on the shortest phone',
        (tester) async {
      expect(await cameraSide(tester, const Size(732, 320)), greaterThan(136));
    });

    testWidgets('does not outgrow the screen on a tablet', (tester) async {
      expect(await cameraSide(tester, const Size(1280, 800)), lessThanOrEqualTo(300));
    });
  });

  group('on a tablet', () {
    Future<double> cardWidth(WidgetTester tester, Size size) async {
      await _pump(
        tester,
        SizedBox(
          width: size.width / 2, // the column beside the form
          height: size.height - 48 - 38,
          child: Center(
            child: QrScanPanel(onCode: (_) {}, scannerBuilder: _fakeCamera()),
          ),
        ),
        size: size,
      );
      return tester.getSize(find.byType(QrScanPanel)).width;
    }

    testWidgets('the card is drawn bigger than on a phone', (tester) async {
      final phone = await cardWidth(tester, const Size(800, 360));
      final tablet = await cardWidth(tester, const Size(1280, 800));

      expect(phone, lessThanOrEqualTo(300));
      expect(tablet, greaterThan(phone * 1.3));
    });
  });

  group('the full-screen scanner for narrow phones', () {
    testWidgets('closes with the code on a good scan', (tester) async {
      String? result;
      await _pump(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async =>
                result = await showQrScanSheet(context, scannerBuilder: _fakeCamera()),
            child: const Text('open'),
          ),
        ),
        size: const Size(640, 360),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('I-scan ang QR'), findsOneWidget);

      await tester.tap(find.text('see-good'));
      await tester.pumpAndSettle();

      expect(result, 'EDG5A1');
      expect(find.text('I-scan ang QR'), findsNothing, reason: 'it closed itself');
    });

    testWidgets('a refused camera says so, with a way back', (tester) async {
      await _pump(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showQrScanSheet(context, scannerBuilder: _fakeCamera()),
            child: const Text('open'),
          ),
        ),
        size: const Size(640, 360),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('deny'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Walang pahintulot sa camera'), findsOneWidget);
      expect(find.byType(BackButton).evaluate().isNotEmpty || find.byType(CloseButton).evaluate().isNotEmpty, isTrue);
    });
  });
}
