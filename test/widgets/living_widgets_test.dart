// The pieces of the first screen that move or report: the lantern night, the
// "Alam mo ba?" line and the connection icon.
import 'package:chronoquest/data/login_facts.dart';
import 'package:chronoquest/widgets/confetti.dart';
import 'package:chronoquest/widgets/connection_corner.dart';
import 'package:chronoquest/widgets/fact_ticker.dart';
import 'package:chronoquest/widgets/living_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _show(WidgetTester tester, Widget child, {bool animations = true}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: !animations);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('the living backdrop', () {
    testWidgets('moves, and takes no taps', (tester) async {
      var taps = 0;
      await _show(
        tester,
        Stack(children: [
          const Positioned.fill(child: LivingBackdrop()),
          Positioned.fill(
            child: GestureDetector(onTap: () => taps++, behavior: HitTestBehavior.opaque),
          ),
        ]),
      );
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);

      await tester.tapAt(const Offset(100, 100));
      expect(taps, 1, reason: 'the taps go through to what is on top');
    });

    testWidgets('is one still picture when the phone removes animations', (tester) async {
      await _show(tester, const SizedBox.expand(child: LivingBackdrop()), animations: false);
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('draws on every kind of screen without trouble', (tester) async {
      // Landscape phone, long phone, portrait phone, a tablet, and a tiny box.
      for (final size in const [
        Size(732, 320),
        Size(873, 393),
        Size(360, 760),
        Size(1280, 800),
        Size(40, 30),
      ]) {
        await _show(
          tester,
          Center(child: SizedBox.fromSize(size: size, child: const LivingBackdrop())),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });

    testWidgets('a new colour repaints it, and it keeps the colour it was given', (tester) async {
      await _show(tester, const SizedBox.expand(child: LivingBackdrop(color: Color(0xFF9B6BD1))));
      expect(tester.widget<LivingBackdrop>(find.byType(LivingBackdrop)).color, const Color(0xFF9B6BD1));
      await _show(tester, const SizedBox.expand(child: LivingBackdrop(color: Color(0xFFD97BB6))));
      await tester.pump();
      expect(tester.widget<LivingBackdrop>(find.byType(LivingBackdrop)).color, const Color(0xFFD97BB6));
      expect(tester.takeException(), isNull);
    });

    testWidgets('animate: false stays still even when the phone allows motion', (tester) async {
      await _show(tester, const SizedBox.expand(child: LivingBackdrop(animate: false)));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('the hero bobs, and stays still when animations are off', (tester) async {
      await _show(tester, const Bob(child: SizedBox(width: 10, height: 10)));
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('the hero does not bob when animations are off', (tester) async {
      await _show(tester, const Bob(child: SizedBox(width: 10, height: 10)), animations: false);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('the confetti', () {
    testWidgets('falls', (tester) async {
      await _show(tester, const SizedBox.expand(child: Confetti()));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('is not drawn at all when the phone removes animations', (tester) async {
      await _show(tester, const SizedBox.expand(child: Confetti()), animations: false);
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.descendant(of: find.byType(Confetti), matching: find.byType(CustomPaint)),
          findsNothing);
    });
  });

  group('the "Alam mo ba?" line', () {
    testWidgets('starts with the lead-in and one fact', (tester) async {
      await _show(tester, const Center(child: FactTicker(start: 0)));
      expect(find.textContaining('Alam mo ba?'), findsOneWidget);
      expect(find.textContaining(loginFacts[0].text), findsOneWidget);
    });

    testWidgets('changes fact every few seconds, in order, and wraps round', (tester) async {
      await _show(tester, const Center(child: FactTicker(start: 0)));

      await tester.pump(FactTicker.every);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining(loginFacts[1].text), findsOneWidget);
      expect(find.textContaining(loginFacts[0].text), findsNothing);

      for (var i = 2; i <= loginFacts.length; i++) {
        await tester.pump(FactTicker.every);
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(find.textContaining(loginFacts[0].text), findsOneWidget,
          reason: 'after the last one it starts again');
    });

    testWidgets('stays on one fact when the phone removes animations', (tester) async {
      await _show(tester, const Center(child: FactTicker(start: 2)), animations: false);
      await tester.pump(const Duration(seconds: 30));
      expect(find.textContaining(loginFacts[2].text), findsOneWidget);
    });

    testWidgets('does not start in the same place every time', (tester) async {
      final seen = <String>{};
      for (var i = 0; i < 40; i++) {
        await _show(tester, Center(key: UniqueKey(), child: const FactTicker()));
        for (final f in loginFacts) {
          if (find.textContaining(f.text).evaluate().isNotEmpty) seen.add(f.text);
        }
      }
      expect(seen.length, greaterThan(1));
    });
  });

  group('the connection corner', () {
    testWidgets('is grey while it finds out, green when connected', (tester) async {
      final status = ValueNotifier<bool?>(null);
      await _show(tester, Center(child: ConnectionCorner(status: status)));
      expect(find.bySemanticsLabel('Chine-check ang internet'), findsOneWidget);
      expect(find.byKey(ConnectionCorner.offlineKey), findsNothing);

      status.value = true;
      await tester.pump();
      expect(find.bySemanticsLabel('May internet'), findsOneWidget);
      expect(find.byKey(ConnectionCorner.offlineKey), findsNothing);
    });

    testWidgets('says "Walang internet" when it cannot connect, and clears when it can',
        (tester) async {
      final status = ValueNotifier<bool?>(false);
      await _show(tester, Center(child: ConnectionCorner(status: status)));
      expect(find.text('Walang internet'), findsOneWidget);

      status.value = true;
      await tester.pump();
      expect(find.text('Walang internet'), findsNothing);
    });

    testWidgets('the chip is a small square', (tester) async {
      await _show(tester, Center(child: ConnectionCorner(status: ValueNotifier<bool?>(true))));
      expect(tester.getSize(find.byKey(ConnectionCorner.chipKey)), const Size(34, 34));
    });
  });
}
