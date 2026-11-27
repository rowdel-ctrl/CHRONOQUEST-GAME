// One era's book: a cover when closed, a spread when open, chains while it is locked, and the
// chain break (the padlock opens, the links fly, the colour comes back).
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/era_progress.dart';
import 'package:chronoquest/widgets/era_book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

EraData get _era => allEras.firstWhere((e) => e.id == 'spanish');

Widget _app(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

EraBook _book({
  bool locked = false,
  bool open = false,
  BookChainFx? fx,
  bool done = false,
  int levels = 0,
  VoidCallback? onCover,
  VoidCallback? onPlay,
}) =>
    EraBook(
      era: _era,
      number: 2,
      color: const Color(0xFF8B4513),
      progress: EraProgress(
          eraId: _era.id, levelsCompleted: levels, bossDefeated: done),
      locked: locked,
      guestLocked: false,
      previousName: 'Sinaunang Pilipinas',
      focused: true,
      open: open,
      chainFx: fx,
      coverKey: const Key('cover'),
      playKey: const Key('play'),
      lockedNoteKey: const Key('note'),
      onCover: onCover,
      onPlay: onPlay,
    );

AnimationController _ctl(WidgetTester tester, double value) {
  final c =
      AnimationController(vsync: tester, duration: const Duration(seconds: 1))
        ..value = value;
  addTearDown(c.dispose);
  return c;
}

final _chainsFinder = find.byWidgetPredicate((w) =>
    w is CustomPaint && w.painter.runtimeType.toString() == '_ChainsPainter');

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
      'closed: the cover shows the number, the boss, the name and the pill',
      (tester) async {
    await tester.pumpWidget(_app(_book()));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.byKey(const Key('cover')), findsOneWidget);
    expect(find.text('KABANATA 2'), findsWidgets);
    expect(find.text(_era.name), findsWidgets);
    expect(find.text('PINDUTIN PARA BUKSAN'), findsOneWidget);
    expect(find.byKey(const Key('note')), findsNothing);
  });

  testWidgets('a tap on the cover calls back', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(_book(onCover: () => taps++)));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.tapAt(tester.getCenter(find.byKey(const Key('cover'))));
    expect(taps, 1);
  });

  testWidgets(
      'open: the cover turns away and the right page offers MAGLARO (or BALIKAN when finished)',
      (tester) async {
    var plays = 0;
    await tester
        .pumpWidget(_app(_book(open: true, levels: 2, onPlay: () => plays++)));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.byKey(const Key('cover')), findsNothing);
    expect(find.text('MAGLARO'), findsOneWidget);
    await tester.tap(find.byKey(const Key('play')));
    expect(plays, 1);

    await tester.pumpWidget(_app(_book(open: true, done: true, levels: 5)));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('BALIKAN'), findsOneWidget);
    expect(find.text('Tapos na · 5 ng 5 level'), findsOneWidget);
  });

  testWidgets('it opens and closes by animation when [open] changes',
      (tester) async {
    await tester.pumpWidget(_app(_book()));
    await tester.pumpWidget(_app(_book(open: true)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('cover')), findsOneWidget,
        reason: 'still turning');
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byKey(const Key('cover')), findsNothing);
    await tester.pumpWidget(_app(_book()));
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byKey(const Key('cover')), findsOneWidget);
  });

  testWidgets(
      'locked: the lock, the dark boss and what to finish first; chains over the cover',
      (tester) async {
    await tester.pumpWidget(_app(_book(locked: true)));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.byKey(const Key('note')), findsOneWidget);
    expect(find.text('PINDUTIN PARA BUKSAN'), findsNothing);
    expect(_chainsFinder, findsOneWidget);
    expect(find.byType(ColorFiltered), findsWidgets);
  });

  testWidgets('an unlocked book has no chains', (tester) async {
    await tester.pumpWidget(_app(_book()));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(_chainsFinder, findsNothing);
  });

  testWidgets("a guest's book says it is for signed-in students",
      (tester) async {
    await tester.pumpWidget(_app(EraBook(
      era: _era,
      number: 2,
      color: const Color(0xFF8B4513),
      progress: EraProgress(eraId: _era.id),
      locked: true,
      guestLocked: true,
      previousName: null,
      focused: true,
      open: false,
    )));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('PARA SA NAKA-SIGN IN'), findsOneWidget);
  });

  group('the chain break', () {
    testWidgets(
        'the book stays grey for the first part of the burst, then its colour comes back',
        (tester) async {
      final charge = _ctl(tester, 0);
      final burst = _ctl(tester, 0);
      final fx = BookChainFx(charge: charge, burst: burst);
      expect(fx.lockLook, 1, reason: 'before the burst: chained and grey');
      expect(fx.chainsOn, isTrue);
      burst.value = 0.3 / BookChainFx.burstSeconds;
      expect(fx.lockLook, 1);
      burst.value = 0.9 / BookChainFx.burstSeconds;
      expect(fx.lockLook, inExclusiveRange(0, 1), reason: 'colour coming back');
      burst.value = 1.8 / BookChainFx.burstSeconds;
      expect(fx.lockLook, 0);
      expect(fx.chainsOn, isFalse, reason: 'the last link has gone');
      burst.value = 1;
      expect(fx.lockLook, 0);
    });

    testWidgets(
        'drawn at every moment of the charge and the burst without a problem; the chains are gone at the end',
        (tester) async {
      final charge = _ctl(tester, 0);
      final burst = _ctl(tester, 0);
      final fx = BookChainFx(charge: charge, burst: burst);
      await tester.pumpWidget(_app(_book(locked: true, fx: fx)));
      await tester.pump(const Duration(milliseconds: 1200));
      for (final c in [0.0, 0.3, 0.7, 1.0]) {
        charge.value = c;
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(_chainsFinder, findsOneWidget);
      }
      for (var t = 0.05; t < BookChainFx.burstSeconds; t += 0.15) {
        burst.value = t / BookChainFx.burstSeconds;
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'at $t s');
      }
      burst.value = 1;
      await tester.pump();
      expect(_chainsFinder, findsNothing, reason: 'every link has gone');
    });
  });
}
