// The module (era background) screen: it can be left, and the guide speaks as the
// hero the player picked.
import 'dart:io';

import 'package:chronoquest/screens/game/background_history_screen.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

GoRouter _router() => GoRouter(
      initialLocation: '/background/spanish',
      routes: [
        GoRoute(
          path: '/era-selection',
          builder: (context, state) =>
              const Scaffold(body: Text('era list stand-in')),
        ),
        GoRoute(
          path: '/background/:eraId',
          builder: (context, state) =>
              BackgroundHistoryScreen(eraId: state.pathParameters['eraId']!),
        ),
      ],
    );

void main() {
  final hiveDir =
      Directory.systemTemp.createTempSync('chronoquest_background_test_').path;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    Hive.init(hiveDir);
    final box = await Hive.openBox('chronoquest');
    // Lapu-Lapu is chosen, on the Spanish era whose lore mentor is Rizal.
    await box.put('selected_character', 'lapu');
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      Directory(hiveDir).deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<void> open(WidgetTester tester) async {
    const size = Size(800, 360);
    await tester.binding.setSurfaceSize(size);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('has a back button that returns to the era list', (tester) async {
    await open(tester);
    expect(find.byKey(BackgroundHistoryScreen.backButtonKey), findsOneWidget);

    await tester.tap(find.byKey(BackgroundHistoryScreen.backButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('era list stand-in'), findsOneWidget);
  });

  testWidgets('the guide speaks as the chosen hero, not the era mentor',
      (tester) async {
    await open(tester);
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -2000));
    await tester.pump();

    expect(StorageService.getCharacter(), 'lapu');
    expect(find.textContaining('Ako si '), findsOneWidget);
    expect(find.textContaining('gagabayan ni'), findsNothing,
        reason: 'the era mentor must not speak over a Lapu-Lapu player');
  });
}
