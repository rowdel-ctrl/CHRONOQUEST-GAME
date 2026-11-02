// The shelf of badges: every badge as a tile, earned ones in colour with how far the
// next level is, a red BAGO on the new ones, and a card for what each one needs.
import 'dart:io';

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/badge_defs.dart';
import 'package:chronoquest/providers/badge_provider.dart';
import 'package:chronoquest/screens/profile/badges_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import '../fixtures/memory_badges.dart';

late BadgeNotifier _badges;

/// A student who has done one perfect level (Tanso in three badges).
void _firstPerfectLevel() {
  _badges.recordLevel(
    eraId: 'spanish',
    level: 1,
    correct: 10,
    total: 10,
    healthLost: 0,
    anyWrong: false,
  );
}

Future<void> _open(WidgetTester tester, {Size size = const Size(812, 375)}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: [badgeProvider.overrideWith((ref) => _badges)],
    child: const MaterialApp(home: BadgesScreen()),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _tapTile(WidgetTester tester, String familyId) async {
  final tile = find.byKey(BadgesScreen.tileKey(familyId));
  await tester.ensureVisible(tile);
  await tester.tap(tile);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  final dir = Directory.systemTemp.createTempSync('chronoquest_badges_screen_').path;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    Hive.init(dir);
    await Hive.openBox('chronoquest');
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      Directory(dir).deleteSync(recursive: true);
    } catch (_) {}
  });

  // A student of their own each time, so what one test saves is not seen by the next.
  setUp(() => _badges = MemoryBadges()..load('student'));

  testWidgets('a new student sees every badge dark, 0 of 40', (tester) async {
    await _open(tester);
    expect(find.text('MGA BADGE'), findsOneWidget);
    expect(find.text('0/40'), findsOneWidget);
    expect(find.text('HUSAY'), findsOneWidget);
    expect(find.text('PAGLALAKBAY'), findsOneWidget);
    expect(find.text('KODEKS AT SIPAG'), findsOneWidget);
    for (final f in badgeFamilies) {
      await tester.ensureVisible(find.byKey(BadgesScreen.tileKey(f.id)));
      expect(find.byKey(BadgesScreen.tileKey(f.id)), findsOneWidget, reason: f.id);
    }
    expect(find.byKey(BadgesScreen.newKey('perfect')), findsNothing);
  });

  testWidgets('what is earned shows how far the next level is', (tester) async {
    _firstPerfectLevel();
    await _open(tester);
    expect(find.text('3/40'), findsOneWidget);
    // Perpekto! is at Tanso (1 of 1); Pilak needs 5.
    expect(find.descendant(of: find.byKey(BadgesScreen.tileKey('perfect')), matching: find.text('1/5 level')),
        findsOneWidget);
    expect(find.descendant(of: find.byKey(BadgesScreen.tileKey('stars3')), matching: find.text('1/10 level')),
        findsOneWidget);
    // Not earned yet: the boss ones say what they are for.
    await tester.ensureVisible(find.byKey(BadgesScreen.tileKey('era:spanish')));
    expect(find.descendant(of: find.byKey(BadgesScreen.tileKey('era:spanish')), matching: find.text('Boss')),
        findsOneWidget);
  });

  testWidgets('an era badge says so when the boss is beaten', (tester) async {
    _badges.recordLevel(
      eraId: 'spanish',
      level: getEraById('spanish').levels.length,
      correct: 5,
      total: 10,
      healthLost: 1,
      anyWrong: true,
    );
    await _open(tester);
    await tester.ensureVisible(find.byKey(BadgesScreen.tileKey('era:spanish')));
    expect(find.descendant(of: find.byKey(BadgesScreen.tileKey('era:spanish')), matching: find.text('Natalo si Boss')),
        findsOneWidget);
  });

  testWidgets('new badges carry BAGO for this visit and not the next', (tester) async {
    _firstPerfectLevel();
    await _open(tester);
    expect(find.byKey(BadgesScreen.newKey('perfect')), findsOneWidget);
    expect(find.byKey(BadgesScreen.newKey('stars3')), findsOneWidget);
    // Opening the shelf has already cleared them for the profile's count...
    expect(_badges.state.unseenCount, 0);
    // ...and the next visit has no tags.
    await _open(tester);
    expect(find.byKey(BadgesScreen.newKey('perfect')), findsNothing);
  });

  testWidgets('a tile opens what the badge needs, level by level, with the gift', (tester) async {
    _firstPerfectLevel();
    await _open(tester);
    await _tapTile(tester, 'perfect');

    expect(find.byKey(BadgesScreen.detailKey), findsOneWidget);
    expect(find.text('Tama lahat ng sagot sa isang level.'), findsOneWidget);
    expect(find.text('Tanso · 1 level'), findsOneWidget);
    expect(find.text('Pilak · 5 level'), findsOneWidget);
    expect(find.text('Ginto · 15 level'), findsOneWidget);
    expect(find.text('+5'), findsNWidgets(1));
    expect(find.text('+10'), findsOneWidget);
    expect(find.text('+20'), findsOneWidget);
    expect(find.text('✓'), findsOneWidget, reason: 'Tanso is held');
    expect(find.text('1/5'), findsOneWidget, reason: 'Pilak is the next');

    await tester.tap(find.byKey(BadgesScreen.closeKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(BadgesScreen.detailKey), findsNothing);
  });

  testWidgets('a badge with one level says if it is held', (tester) async {
    await _open(tester);
    await _tapTile(tester, 'firstbuy');
    expect(find.text('Bumili sa Tindahan sa unang pagkakataon.'), findsOneWidget);
    expect(find.text('Hindi pa nakukuha'), findsOneWidget);
    await tester.tap(find.byKey(BadgesScreen.closeKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    _badges.recordPurchase();
    await _open(tester);
    await _tapTile(tester, 'firstbuy');
    expect(find.text('Nakuha na'), findsWidgets);
  });

  testWidgets('fits small phones, wide and narrow, empty and full', (tester) async {
    for (final size in const [Size(640, 360), Size(732, 320), Size(390, 780), Size(360, 640)]) {
      await _open(tester, size: size);
      expect(tester.takeException(), isNull, reason: '$size');
    }
    _firstPerfectLevel();
    for (final size in const [Size(640, 360), Size(360, 640)]) {
      await _open(tester, size: size);
      expect(tester.takeException(), isNull, reason: '$size with badges');
      await _tapTile(tester, 'perfect');
      expect(tester.takeException(), isNull, reason: '$size with the card open');
      await tester.tap(find.byKey(BadgesScreen.closeKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }
  });
}
