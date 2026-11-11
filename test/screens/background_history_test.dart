// The era background screen: its story one event at a time, and three sealed
// key terms that are plainly meant to be tapped. It can be left, and the button
// to go on opens only once every term has been read.
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/data/era_story.dart';
import 'package:chronoquest/screens/game/background_history_screen.dart';
import 'package:chronoquest/widgets/game_ui.dart';
import 'package:chronoquest/widgets/pixel_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// What the screen under test is told about the era having been read before, and
/// what it calls when the story is read through (set per test).
bool _alreadyRead = false;
final List<String> _marked = [];

GoRouter _router() => GoRouter(
      initialLocation: '/background/spanish',
      routes: [
        GoRoute(
          path: '/era-selection',
          builder: (context, state) =>
              const Scaffold(body: Text('era list stand-in')),
        ),
        GoRoute(
          path: '/level-select/:eraId',
          builder: (context, state) =>
              const Scaffold(body: Text('levels stand-in')),
        ),
        GoRoute(
          path: '/background/:eraId',
          builder: (context, state) =>
              BackgroundHistoryScreen(
            eraId: state.pathParameters['eraId']!,
            alreadyRead: _alreadyRead,
            onStoryRead: _marked.add,
          ),
        ),
      ],
    );

Future<void> _open(
  WidgetTester tester, {
  Size size = const Size(732, 320),
  bool animations = true,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: !animations);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
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

/// Opens term [i] and lets the flip finish.
Future<void> _openTerm(WidgetTester tester, int i) async {
  final card = find.byKey(BackgroundHistoryScreen.termKey(i));
  await tester.ensureVisible(card);
  await tester.tap(card);
  await _settle(tester);
}

/// An animation started by a tap begins on the frame after it, so pump twice.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

/// Lets [beat] stay on screen for its whole reading time, so it counts as read.
Future<void> _stay(WidgetTester tester, StoryBeat beat) =>
    tester.pump(BackgroundHistoryScreen.readTimeFor(beat) +
        const Duration(milliseconds: 100));

/// Stays on each event for its reading time and turns with the arrow, so the whole
/// story counts as read and the terms unlock.
Future<void> _readStory(WidgetTester tester, [String era = 'spanish']) async {
  final beats = eraStories[era]!.beats;
  for (var i = 0; i < beats.length; i++) {
    await tester.pump(BackgroundHistoryScreen.readTimeFor(beats[i]) +
        const Duration(milliseconds: 100));
    if (i < beats.length - 1) {
      await tester.tap(find.byKey(BackgroundHistoryScreen.nextKey));
      await _settle(tester);
    }
  }
  await tester.pump(const Duration(milliseconds: 600));
}

GameButton _ready(WidgetTester tester) => tester
    .widget<GameButton>(find.byKey(BackgroundHistoryScreen.readyButtonKey));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() {
    _alreadyRead = false;
    _marked.clear();
  });

  group('an era read before', () {
    testWidgets('the first time there is no skip button and the terms are locked',
        (tester) async {
      await _open(tester);
      expect(find.byKey(BackgroundHistoryScreen.skipKey), findsNothing);
      expect(find.byKey(BackgroundHistoryScreen.lockNoteKey), findsOneWidget);
    });

    testWidgets('shows LAKTAWAN, has nothing locked, and skips to the levels',
        (tester) async {
      _alreadyRead = true;
      await _open(tester);
      expect(find.byKey(BackgroundHistoryScreen.skipKey), findsOneWidget);
      expect(find.text('LAKTAWAN'), findsOneWidget);
      expect(find.byKey(BackgroundHistoryScreen.lockNoteKey), findsNothing,
          reason: 'no waiting to read it again');

      await tester.tap(find.byKey(BackgroundHistoryScreen.skipKey));
      await tester.pumpAndSettle();
      expect(find.text('levels stand-in'), findsOneWidget);
    });

    testWidgets('a read before story can still be turned and read again',
        (tester) async {
      _alreadyRead = true;
      await _open(tester);
      await tester.tap(find.byKey(BackgroundHistoryScreen.nextKey));
      await _settle(tester);
      expect(find.byKey(BackgroundHistoryScreen.beatKey), findsWidgets);
    });

    testWidgets('reading every event the first time is saved once',
        (tester) async {
      await _open(tester);
      await _readStory(tester);
      expect(_marked, ['spanish']);
      await tester.pump(const Duration(seconds: 10));
      expect(_marked, ['spanish'], reason: 'only once');
    });

    testWidgets('a story already read is not saved again', (tester) async {
      _alreadyRead = true;
      await _open(tester);
      await tester.pump(const Duration(seconds: 10));
      expect(_marked, isEmpty);
    });
  });

  testWidgets('has a back button that returns to the era list', (tester) async {
    await _open(tester);
    expect(find.byKey(BackgroundHistoryScreen.backButtonKey), findsOneWidget);

    await tester.tap(find.byKey(BackgroundHistoryScreen.backButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('era list stand-in'), findsOneWidget);
  });

  group('the story', () {
    testWidgets('shows one event at a time, starting with the first',
        (tester) async {
      await _open(tester);
      final beats = eraStories['spanish']!.beats;

      expect(find.text(beats[0].label), findsOneWidget);
      expect(find.textContaining('Legazpi'), findsOneWidget);
      expect(find.textContaining('Intramuros'), findsNothing,
          reason: 'that is the next event');
    });

    testWidgets('a dot for each event; tapping one shows that event',
        (tester) async {
      await _open(tester);
      final beats = eraStories['spanish']!.beats;
      for (var i = 0; i < beats.length; i++) {
        expect(
            find.byKey(BackgroundHistoryScreen.beatDotKey(i)), findsOneWidget);
      }

      await _stay(tester, beats[0]);
      await tester.tap(find.byKey(BackgroundHistoryScreen.beatDotKey(1)));
      await _settle(tester);
      expect(find.text(beats[1].label), findsOneWidget);
      expect(find.textContaining('Intramuros'), findsOneWidget);
      expect(find.textContaining('Legazpi'), findsNothing);
    });

    testWidgets(
        'the card shows it can be turned once read: a curling corner and an arrow',
        (tester) async {
      await _open(tester);
      final beats = eraStories['spanish']!.beats;
      await _stay(tester, beats[0]);
      expect(find.byKey(BackgroundHistoryScreen.curlKey), findsOneWidget);
      expect(find.byKey(BackgroundHistoryScreen.nextKey), findsOneWidget);
      expect(tester.getSize(find.byKey(BackgroundHistoryScreen.nextKey)).width,
          greaterThanOrEqualTo(40));
    });

    testWidgets(
        'tapping the arrow, tapping the card, or swiping it each turn to the next event',
        (tester) async {
      await _open(tester);
      final beats = eraStories['spanish']!.beats;

      await _stay(tester, beats[0]);
      await tester.tap(find.byKey(BackgroundHistoryScreen.nextKey));
      await _settle(tester);
      expect(find.text(beats[1].label), findsOneWidget);

      await _stay(tester, beats[1]);
      await tester.tap(find.byKey(BackgroundHistoryScreen.beatKey));
      await _settle(tester);
      expect(find.text(beats[2].label), findsOneWidget);

      await _stay(tester, beats[2]);
      await tester.fling(find.byKey(BackgroundHistoryScreen.beatKey),
          const Offset(-200, 0), 800);
      await _settle(tester);
      expect(find.text(beats[3].label), findsOneWidget);

      await tester.fling(find.byKey(BackgroundHistoryScreen.beatKey),
          const Offset(200, 0), 800);
      await _settle(tester);
      expect(find.text(beats[2].label), findsOneWidget,
          reason: 'a swipe the other way goes back');
    });

    testWidgets('on the last event the hint goes away: nothing more to turn to',
        (tester) async {
      await _open(tester);
      await _readStory(tester);

      expect(find.byKey(BackgroundHistoryScreen.nextKey), findsNothing);
      expect(find.byKey(BackgroundHistoryScreen.curlKey), findsNothing);
    });

    testWidgets('each dot is a 40 pixel target', (tester) async {
      await _open(tester);
      final size =
          tester.getSize(find.byKey(BackgroundHistoryScreen.beatDotKey(0)));
      expect(size.width, greaterThanOrEqualTo(40));
    });
  });

  group('the screen has few words', () {
    testWidgets(
        'no era subtitle, no "PANAHON n NG 6", no speech, no "i-tap" instructions',
        (tester) async {
      await _open(tester);

      expect(find.text('Pananakop ng Espanya'), findsOneWidget,
          reason: 'the era, once, as the title');
      expect(find.text('PANAHON 2 NG 6'), findsNothing);
      expect(find.textContaining('Ako si '), findsNothing);
      expect(find.textContaining('i-tap'), findsNothing);
      expect(find.textContaining('I-tap'), findsNothing);
      expect(find.textContaining('NG 3 TERMINO'), findsNothing);
      expect(find.textContaining('termino pa'), findsNothing);
    });
  });

  group('reading the story first', () {
    testWidgets(
        'the terms start locked, with a note of how many events are read',
        (tester) async {
      await _open(tester);
      final beats = eraStories['spanish']!.beats;

      expect(find.text('Basahin muna ang kuwento (0 ng ${beats.length})'),
          findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsNWidgets(3));
      expect(find.byKey(BackgroundHistoryScreen.ringKey), findsNothing,
          reason: 'nothing to point at yet');
      expect(find.byKey(BackgroundHistoryScreen.readBarKey), findsOneWidget);

      await tester.tap(find.byKey(BackgroundHistoryScreen.termKey(0)));
      await _settle(tester);
      expect(find.text(keyTermsFor('spanish')[0]['def']!), findsNothing,
          reason: 'locked');
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('jumping with the dots to the last event does not unlock them',
        (tester) async {
      await _open(tester);
      final beats = eraStories['spanish']!.beats;
      for (var i = 1; i < beats.length; i++) {
        await tester.tap(find.byKey(BackgroundHistoryScreen.beatDotKey(i)));
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(find.text(beats[0].label), findsOneWidget,
          reason: 'the dots could not skip the first event');
      expect(find.byIcon(Icons.lock_rounded), findsNWidgets(3));
      await tester.tap(find.byKey(BackgroundHistoryScreen.termKey(0)));
      await _settle(tester);
      expect(find.text(keyTermsFor('spanish')[0]['def']!), findsNothing);
    });

    testWidgets(
        'an event counts once it has stayed up for its time, and the note counts them',
        (tester) async {
      await _open(tester);
      final beats = eraStories['spanish']!.beats;

      // _open has already let one second go by.
      await tester.pump(BackgroundHistoryScreen.readTimeFor(beats[0]) -
          const Duration(seconds: 2));
      expect(find.text('Basahin muna ang kuwento (0 ng ${beats.length})'),
          findsOneWidget,
          reason: 'not long enough yet');

      await tester.pump(const Duration(seconds: 1, milliseconds: 100));
      expect(find.text('Basahin muna ang kuwento (1 ng ${beats.length})'),
          findsOneWidget);
    });

    testWidgets(
        'the arrow, the card, a swipe and the dots do nothing until the event is read',
        (tester) async {
      await _open(tester);
      final beats = eraStories['spanish']!.beats;
      expect(find.byKey(BackgroundHistoryScreen.curlKey), findsNothing,
          reason: 'nothing to turn to yet');

      await tester.tap(find.byKey(BackgroundHistoryScreen.nextKey));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(BackgroundHistoryScreen.beatKey));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.fling(find.byKey(BackgroundHistoryScreen.beatKey),
          const Offset(-200, 0), 800);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(BackgroundHistoryScreen.beatDotKey(1)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(beats[0].label), findsOneWidget,
          reason: 'still on the first event');
      expect(find.text('Basahin muna ang kuwento (0 ng ${beats.length})'),
          findsOneWidget);

      await _stay(tester, beats[0]);
      expect(find.byKey(BackgroundHistoryScreen.curlKey), findsOneWidget);
      await tester.tap(find.byKey(BackgroundHistoryScreen.nextKey));
      await _settle(tester);
      expect(find.text(beats[1].label), findsOneWidget,
          reason: 'read, so it turns');
    });

    testWidgets(
        'going back is always allowed, and the next one has to be read again',
        (tester) async {
      await _open(tester);
      final beats = eraStories['spanish']!.beats;
      await _stay(tester, beats[0]);
      await tester.tap(find.byKey(BackgroundHistoryScreen.nextKey));
      await _settle(tester);

      await tester.tap(find.byKey(BackgroundHistoryScreen.beatDotKey(0)));
      await _settle(tester);
      expect(find.text(beats[0].label), findsOneWidget);

      await tester.tap(find.byKey(BackgroundHistoryScreen.nextKey));
      await _settle(tester);
      expect(find.text(beats[1].label), findsOneWidget,
          reason: 'the first was read');

      await tester.tap(find.byKey(BackgroundHistoryScreen.beatKey));
      await _settle(tester);
      expect(find.text(beats[1].label), findsOneWidget,
          reason: 'the second has not stayed up long enough yet');
    });

    testWidgets(
        'after the whole story is read the terms wake up and can be opened',
        (tester) async {
      await _open(tester);
      await _readStory(tester);

      expect(find.byKey(BackgroundHistoryScreen.lockNoteKey), findsNothing);
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
      expect(find.byKey(BackgroundHistoryScreen.ringKey), findsOneWidget);

      await _openTerm(tester, 0);
      expect(find.text(keyTermsFor('spanish')[0]['def']!), findsOneWidget);
    });

    testWidgets('it works with the phone animations off too', (tester) async {
      await _open(tester, animations: false);
      await _readStory(tester);

      await tester.tap(find.byKey(BackgroundHistoryScreen.termKey(0)));
      await tester.pump();
      expect(find.text(keyTermsFor('spanish')[0]['def']!), findsOneWidget);
    });

    test(
        'the time to read an event is 2.5 to 7 seconds and grows with its words',
        () {
      for (final story in eraStories.values) {
        for (final beat in story.beats) {
          final t = BackgroundHistoryScreen.readTimeFor(beat);
          expect(t, greaterThanOrEqualTo(const Duration(milliseconds: 2500)),
              reason: beat.label);
          expect(t, lessThanOrEqualTo(const Duration(seconds: 7)),
              reason: beat.label);
        }
      }
      expect(
        BackgroundHistoryScreen.readTimeFor(const StoryBeat('A',
            'isa dalawa tatlo apat lima anim pito walo siyam sampu labing-isa')),
        greaterThan(BackgroundHistoryScreen.readTimeFor(
            const StoryBeat('A', 'isa dalawa'))),
      );
    });

    test('every era tells its story in five to eight events, one per topic', () {
      for (final entry in eraStories.entries) {
        expect(entry.value.beats.length, inInclusiveRange(5, 8),
            reason: entry.key);
      }
    });
  });

  group('the sealed terms', () {
    testWidgets('are shut, each with its name and no meaning yet',
        (tester) async {
      await _open(tester);
      await _readStory(tester);
      final terms = keyTermsFor('spanish');

      for (var i = 0; i < terms.length; i++) {
        expect(find.byKey(BackgroundHistoryScreen.termKey(i)), findsOneWidget);
        expect(find.text(terms[i]['term']!.toUpperCase()), findsOneWidget);
        expect(find.text(terms[i]['def']!), findsNothing, reason: 'sealed');
      }
      expect(find.text('?'), findsNWidgets(terms.length));
    });

    testWidgets(
        'there is no hand: the first shut card rings instead, then the next, then none',
        (tester) async {
      await _open(tester);
      await _readStory(tester);
      final ring = find.byKey(BackgroundHistoryScreen.ringKey);
      double ringY() => tester.getCenter(ring).dy;
      double cardY(int i) =>
          tester.getCenter(find.byKey(BackgroundHistoryScreen.termKey(i))).dy;

      expect(
          find
              .byType(PixelIcon)
              .evaluate()
              .where((e) => (e.widget as PixelIcon).glyph == PixelGlyph.hand),
          isEmpty);
      expect(ring, findsOneWidget);
      expect((ringY() - cardY(0)).abs(), lessThan(40),
          reason: 'at the first card');

      await _openTerm(tester, 0);
      expect(ring, findsOneWidget);
      expect((ringY() - cardY(1)).abs(), lessThan(40),
          reason: 'now at the second');

      await _openTerm(tester, 1);
      await _openTerm(tester, 2);
      expect(ring, findsNothing, reason: 'nothing left to open');
    });

    testWidgets(
        'the shut cards shimmer, so something moves across each of them',
        (tester) async {
      await _open(tester);
      await _readStory(tester);
      // One slanted band of light per shut card.
      final bands = find.byWidgetPredicate((w) =>
          w is Transform &&
          w.child is Container &&
          (w.child as Container).decoration is BoxDecoration &&
          ((w.child as Container).decoration as BoxDecoration).gradient
              is LinearGradient &&
          (w.child as Container).constraints?.maxWidth == 34);
      expect(bands, findsNWidgets(3));
      await _openTerm(tester, 0);
      expect(bands, findsNWidgets(2), reason: 'an open card stops shimmering');
    });

    testWidgets('tapping one flips it open to its meaning with a green seal',
        (tester) async {
      await _open(tester);
      await _readStory(tester);
      final terms = keyTermsFor('spanish');

      await _openTerm(tester, 0);

      expect(find.text(terms[0]['def']!), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('?'), findsNWidgets(terms.length - 1));
      expect(find.text(terms[1]['def']!), findsNothing,
          reason: 'the others stay sealed');
    });

    testWidgets(
        'they glow and wobble while shut, and settle when the phone removes animations',
        (tester) async {
      await _open(tester);
      expect(tester.hasRunningAnimations, isTrue);

      await _open(tester, animations: false);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets(
        'with animations off a tap opens it at once, and the first card still rings',
        (tester) async {
      await _open(tester, animations: false);
      await _readStory(tester);
      final terms = keyTermsFor('spanish');
      expect(find.byKey(BackgroundHistoryScreen.ringKey), findsOneWidget);

      await tester.tap(find.byKey(BackgroundHistoryScreen.termKey(0)));
      await tester.pump();

      expect(find.text(terms[0]['def']!), findsOneWidget);
    });
  });

  group('HANDA NA AKO', () {
    testWidgets('opens only after every term is read, and fills a dot for each',
        (tester) async {
      await _open(tester);
      await _readStory(tester);

      expect(_ready(tester).onPressed, isNull);
      for (var i = 0; i < 3; i++) {
        expect(
            find.byKey(BackgroundHistoryScreen.termDotKey(i)), findsOneWidget);
      }

      for (var i = 0; i < 3; i++) {
        await _openTerm(tester, i);
        expect(_ready(tester).onPressed, i < 2 ? isNull : isNotNull,
            reason: 'after term $i');
      }
      expect(find.text('Sistema ng pagbibigay ng lupain sa mga Espanyol'),
          findsOneWidget);
    });

    testWidgets('goes on to the levels of the era', (tester) async {
      await _open(tester);
      await _readStory(tester);
      for (var i = 0; i < 3; i++) {
        await _openTerm(tester, i);
      }

      await tester.tap(find.byKey(BackgroundHistoryScreen.readyButtonKey));
      await tester.pumpAndSettle();

      expect(find.text('levels stand-in'), findsOneWidget);
    });
  });

  testWidgets(
      'every era fits a small phone, with all its terms and the button reachable',
      (tester) async {
    for (final size in const [Size(732, 320), Size(640, 360), Size(400, 700)]) {
      for (final era in allEras) {
        await tester.binding.setSurfaceSize(size);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = size;
        await tester.pumpWidget(
            MaterialApp(home: BackgroundHistoryScreen(eraId: era.id)));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: '${era.id} at $size');

        final terms = keyTermsFor(era.id);
        for (var i = 0; i < terms.length; i++) {
          await tester
              .ensureVisible(find.byKey(BackgroundHistoryScreen.termKey(i)));
          expect(find.byKey(BackgroundHistoryScreen.termKey(i)).hitTestable(),
              findsOneWidget,
              reason: '${era.id} term $i at $size');
        }
        await tester
            .ensureVisible(find.byKey(BackgroundHistoryScreen.readyButtonKey));
        expect(find.byKey(BackgroundHistoryScreen.readyButtonKey).hitTestable(),
            findsOneWidget,
            reason: '${era.id} button at $size');
      }
    }
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
  });
}
