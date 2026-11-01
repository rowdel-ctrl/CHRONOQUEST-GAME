// The moments a badge shows up: a strip after a level, a pop-up after a boss, and
// one quiet line for badges that came with the update.
import 'package:chronoquest/models/badge_defs.dart';
import 'package:chronoquest/providers/badge_provider.dart';
import 'package:chronoquest/widgets/new_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../fixtures/memory_badges.dart';

EarnedBadge _badge(String id) {
  final family = badgeFamilyOf(id)!;
  return EarnedBadge(family, family.steps.firstWhere((s) => s.id == id));
}

Future<void> _show(WidgetTester tester, Widget child,
    {List<Override> overrides = const [], Size size = const Size(812, 375)}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => Scaffold(body: Stack(children: [child]))),
    GoRoute(path: '/badges', builder: (_, __) => const Scaffold(body: Text('the shelf'))),
  ]);
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('the strip after a level', () {
    testWidgets('names the badge, the gift, and goes to the shelf when tapped', (tester) async {
      await _show(tester, Positioned.fill(child: NewBadgeStrip(badges: [_badge('perfect:2')])));
      expect(find.text('BAGONG BADGE!'), findsOneWidget);
      expect(find.text('Perpekto! · Pilak'), findsOneWidget);
      expect(find.text('+10 coins'), findsOneWidget);

      await tester.tap(find.byKey(NewBadgeStrip.stripKey));
      await tester.pumpAndSettle();
      expect(find.text('the shelf'), findsOneWidget);
    });

    testWidgets('with several, says how many more and adds up the gift', (tester) async {
      await _show(
        tester,
        Positioned.fill(
          child: NewBadgeStrip(badges: [_badge('stars3:1'), _badge('perfect:1'), _badge('nodamage:1')]),
        ),
      );
      expect(find.text('Tatlong Bituin · Tanso  +2 pa'), findsOneWidget);
      expect(find.text('+15 coins'), findsOneWidget);
    });

    testWidgets('a boss medal leads when it came with others', (tester) async {
      await _show(
        tester,
        Positioned.fill(child: NewBadgeStrip(badges: [_badge('perfect:1'), _badge('era:spanish')])),
      );
      expect(find.textContaining('Bayani ng'), findsOneWidget);
    });

    testWidgets('goes away by itself', (tester) async {
      await _show(tester, Positioned.fill(child: NewBadgeStrip(badges: [_badge('perfect:1')])));
      expect(find.byKey(NewBadgeStrip.stripKey).hitTestable(), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 400));
      // Not tappable any more.
      expect(find.byKey(NewBadgeStrip.stripKey).hitTestable(), findsNothing);
    });

    testWidgets('draws nothing for no badges', (tester) async {
      await _show(tester, const Positioned.fill(child: NewBadgeStrip(badges: [])));
      expect(find.byKey(NewBadgeStrip.stripKey), findsNothing);
    });
  });

  group('the pop-up after a boss', () {
    testWidgets('shows the medal, what it was for, the gift and the others', (tester) async {
      await _show(
        tester,
        BossBadgeCard(badges: [_badge('perfect:1'), _badge('era:spanish'), _badge('bossclean')]),
      );
      expect(find.byKey(BossBadgeCard.cardKey), findsOneWidget);
      expect(find.text('BAGONG BADGE!'), findsOneWidget);
      expect(find.text('Bayani ng ${getEraName('spanish')}'), findsOneWidget);
      expect(find.text('Natalo mo ang Governor!'), findsOneWidget);
      expect(find.text('+55'), findsOneWidget, reason: '5 + 30 + 20');
      expect(find.text('Kasama pa:'), findsOneWidget);
      expect(find.text('TULOY'), findsOneWidget);
    });

    testWidgets('a grade trophy says what it took', (tester) async {
      await _show(tester, BossBadgeCard(badges: [_badge('champ:5')]));
      expect(find.text('Kampeon ng Grade 5'), findsOneWidget);
      expect(find.text('Natalo mo ang lahat ng boss ng grade mo!'), findsOneWidget);
      expect(find.text('Kasama pa:'), findsNothing);
    });

    testWidgets('fits a short landscape phone', (tester) async {
      await _show(
        tester,
        BossBadgeCard(
          badges: [_badge('era:spanish'), _badge('perfect:1'), _badge('stars3:1'), _badge('bossclean')],
        ),
        size: const Size(640, 320),
      );
      expect(tester.takeException(), isNull);
    });

    test('a trophy, then an era, then the first', () {
      expect(mainBadge([_badge('perfect:1'), _badge('era:spanish'), _badge('champ:5')]).id, 'champ:5');
      expect(mainBadge([_badge('perfect:1'), _badge('era:spanish')]).id, 'era:spanish');
      expect(mainBadge([_badge('perfect:1'), _badge('stars3:1')]).id, 'perfect:1');
      expect(hasBossBadge([_badge('perfect:1')]), isFalse);
      expect(hasBossBadge([_badge('perfect:1'), _badge('era:ww2')]), isTrue);
    });
  });

  group('the one line for badges that came with the update', () {
    /// A student with one 3-star level on the phone, who has not had badges before.
    BadgeNotifier seeded({bool progress = true}) => MemoryBadges(levels: {
          if (progress) 'spanish': {1: 3},
        })
          ..load('student');

    testWidgets('says how many, goes to the shelf when tapped, and clears', (tester) async {
      final badges = seeded();
      await _show(tester, const QuietBadgeNote(),
          overrides: [badgeProvider.overrideWith((ref) => badges)]);
      expect(find.text('May 1 bagong badge ka sa Profile!'), findsOneWidget);

      await tester.tap(find.byKey(QuietBadgeNote.noteKey));
      await tester.pumpAndSettle();
      expect(find.text('the shelf'), findsOneWidget);
      expect(badges.state.quietCount, 0, reason: 'said once');
    });

    testWidgets('goes away by itself after a few seconds', (tester) async {
      final badges = seeded();
      await _show(tester, const QuietBadgeNote(stay: Duration(seconds: 2)),
          overrides: [badgeProvider.overrideWith((ref) => badges)]);
      expect(find.byKey(QuietBadgeNote.noteKey), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.byKey(QuietBadgeNote.noteKey), findsNothing);
      expect(badges.state.quietCount, 0);
      expect(badges.state.has('stars3:1'), isTrue, reason: 'the badge itself stays');
    });

    testWidgets('says nothing when nothing came quietly', (tester) async {
      final badges = seeded(progress: false);
      await _show(tester, const QuietBadgeNote(),
          overrides: [badgeProvider.overrideWith((ref) => badges)]);
      expect(find.byKey(QuietBadgeNote.noteKey), findsNothing);
    });
  });
}

String getEraName(String id) => badgeFamilyOf('era:$id')!.shelfName;
