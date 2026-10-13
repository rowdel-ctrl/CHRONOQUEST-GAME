// The module (era background) screen: it can be left, and the guide speaks as the
// hero the player picked.
import 'dart:io';

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/screens/game/background_history_screen.dart';
import 'package:chronoquest/services/storage_service.dart';
import 'package:chronoquest/widgets/game_ui.dart';
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

    expect(StorageService.getCharacter(), 'lapu');
    expect(find.textContaining('Ako si '), findsOneWidget);
    expect(find.textContaining('gagabayan ni'), findsNothing,
        reason: 'the era mentor must not speak over a Lapu-Lapu player');
  });

  testWidgets('the story is cut into events and a timeline', (tester) async {
    await open(tester);
    expect(find.text('PANAHON 2 NG 6'), findsOneWidget);
    expect(find.text('Pananakop ng Espanya'), findsOneWidget);
    expect(find.text('1565'), findsWidgets);
    expect(find.text('Intramuros'), findsOneWidget, reason: 'a timeline node');
  });

  testWidgets('HANDA NA AKO opens only after every term is read', (tester) async {
    await open(tester);
    GameButton ready() => tester
        .widget<GameButton>(find.byKey(BackgroundHistoryScreen.readyButtonKey));

    expect(ready().onPressed, isNull);
    expect(find.text('0 NG 3 TERMINO'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      final card = find.byKey(BackgroundHistoryScreen.termKey(i));
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pump();
      expect(ready().onPressed, i < 2 ? isNull : isNotNull);
    }
    expect(find.text('3 NG 3 TERMINO'), findsOneWidget);
    expect(find.text('Sistema ng pagbibigay ng lupain sa mga Espanyol'),
        findsOneWidget);
  });

  testWidgets('every era fits a small landscape phone', (tester) async {
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    for (final size in const [Size(640, 360), Size(732, 320)]) {
      for (final era in allEras) {
        await tester.binding.setSurfaceSize(size);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = size;
        await tester.pumpWidget(
            MaterialApp(home: BackgroundHistoryScreen(eraId: era.id)));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: '${era.id} at $size');
      }
    }
  });
}
