// The full background of each era: the text in assets/data/history_full.json, how a story
// card is tied to a chapter (and a chapter to the questions of its level), the reader
// screen, and the button on the story card that opens it.
import 'dart:convert';
import 'dart:io';

import 'package:chronoquest/data/era_story.dart';
import 'package:chronoquest/data/history_full.dart';
import 'package:chronoquest/screens/game/background_history_screen.dart';
import 'package:chronoquest/screens/game/full_story_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _eras = [
  'pre-colonial',
  'spanish',
  'nationalism',
  'american',
  'ww2',
  'modern',
];

FullChapter _chapter(String weeks,
        {int paragraphs = 14, int terms = 2, String? title}) =>
    FullChapter(
      weeks: weeks,
      title: title ?? 'Pamagat $weeks',
      paragraphs: [
        for (var i = 0; i < paragraphs; i++)
          'Talata $i ng kabanata: ang **barangay** ay maliit na komunidad na '
              'pinamumunuan ng isang datu, at ang mga tao ay nagtutulungan sa '
              'pagsasaka, pangingisda, at pakikipagkalakalan sa mga karatig na pulo.',
      ],
      terms: [for (var i = 0; i < terms; i++) ('Salita $i', 'Kahulugan $i')],
    );

void _fake(Map<String, List<FullChapter>> data) {
  HistoryFull.loader = () async => data;
  HistoryFull.reset();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('the text in the asset', () {
    late Map<String, List<FullChapter>> real;

    setUpAll(() async {
      HistoryFull.reset();
      real = {for (final e in _eras) e: await HistoryFull.chapters(e)};
    });

    test('every era has its chapters: a chapter per week of the DepEd guides',
        () {
      expect(real['pre-colonial']!.length, 10);
      expect(real['spanish']!.length, 5);
      expect(real['nationalism']!.length, 7);
      expect(real['american']!.length, 8);
      expect(real['ww2']!.length, 8);
      expect(real['modern']!.length, 5);
    });

    test(
        'every chapter has a title, a lesson of at least two paragraphs and its terms',
        () {
      for (final e in _eras) {
        for (final c in real[e]!) {
          final where = '$e ${c.weeks}';
          expect(c.title.trim(), isNotEmpty, reason: where);
          expect(c.paragraphs.length, greaterThanOrEqualTo(2), reason: where);
          expect(c.wordCount, greaterThan(100), reason: where);
          expect(c.terms.length, greaterThanOrEqualTo(3), reason: where);
          for (final (term, meaning) in c.terms) {
            expect(term.trim(), isNotEmpty, reason: where);
            expect(meaning.trim().length, greaterThan(8),
                reason: '$where $term');
          }
        }
      }
    });

    test('no garbled characters, no page headers, bold marks in pairs', () {
      for (final e in _eras) {
        for (final c in real[e]!) {
          final all = [
            c.title,
            ...c.paragraphs,
            for (final t in c.terms) ...[t.$1, t.$2]
          ];
          for (final s in all) {
            expect(s.contains('�'), isFalse, reason: '$e ${c.weeks}: $s');
            expect(s.contains('Pahina'), isFalse, reason: '$e ${c.weeks}: $s');
            expect(s.contains('Araling Panlipunan 5'), isFalse,
                reason: '$e ${c.weeks}');
            expect(RegExp(r'\s{2,}').hasMatch(s), isFalse,
                reason: '$e ${c.weeks}: $s');
          }
          for (final p in c.paragraphs) {
            expect('**'.allMatches(p).length.isEven, isTrue,
                reason: '$e ${c.weeks}');
          }
        }
      }
    });

    test('the weeks of a chapter are in order and start at week 1', () {
      for (final e in _eras) {
        final firsts = [
          for (final c in real[e]!) int.parse(c.weeks.split('-').first),
        ];
        expect(firsts.first, 1, reason: e);
        for (var i = 1; i < firsts.length; i++) {
          expect(firsts[i], greaterThan(firsts[i - 1]),
              reason: '$e chapter $i');
        }
      }
    });

    test(
        'the later eras have a chapter per question topic, so a story card, a chapter '
        'and a level go together', () {
      for (final e in ['american', 'ww2', 'modern']) {
        final questions =
            jsonDecode(File('assets/data/questions_$e.json').readAsStringSync())
                as Map<String, dynamic>;
        final topics = <String>[];
        for (final level in (questions.keys.toList()
          ..sort((a, b) => int.parse(a).compareTo(int.parse(b))))) {
          final list = (questions[level] as List).cast<Map<String, dynamic>>();
          topics.add(list.first['subTopic'] as String);
        }
        // The last level of an era (american, ww2) is a mix of the others, whose topic
        // is its own; either way there is one chapter per level.
        expect(real[e]!.length, questions.length, reason: e);
        expect(eraStories[e]!.beats.length, questions.length,
            reason: '$e cards');
        expect(topics.length, real[e]!.length, reason: e);
      }
    });

    test(
        'a chapter says what its card does: first words of the card appear in its lesson',
        () {
      // The card of the first modern level is about martial law, its chapter too.
      final modern = real['modern']!;
      expect(
          modern.first.paragraphs.join(' ').contains('Batas Militar'), isTrue);
      expect(eraStories['modern']!.beats.first.text.contains('Batas Militar'),
          isTrue);
      // EDSA: the second card and chapter.
      expect(modern[1].paragraphs.join(' ').contains('EDSA'), isTrue);
      expect(eraStories['modern']!.beats[1].text.contains('EDSA'), isTrue);
    });
  });

  group('which chapter a card opens', () {
    test('cards and chapters match one to one when there are as many', () {
      for (var i = 0; i < 8; i++) {
        expect(HistoryFull.chapterForBeat(i, 8, 8), i);
      }
    });

    test('5 cards over 10 chapters take every second one', () {
      expect([for (var i = 0; i < 5; i++) HistoryFull.chapterForBeat(i, 5, 10)],
          [0, 2, 4, 6, 8]);
    });

    test('5 cards over 7 chapters stay inside the chapters', () {
      final picks = [
        for (var i = 0; i < 5; i++) HistoryFull.chapterForBeat(i, 5, 7)
      ];
      expect(picks.first, 0);
      expect(picks.last, lessThan(7));
      for (var i = 1; i < picks.length; i++) {
        expect(picks[i], greaterThan(picks[i - 1]));
      }
    });

    test('no chapters gives chapter 0', () {
      expect(HistoryFull.chapterForBeat(3, 5, 0), 0);
    });
  });

  group('the reader', () {
    Future<void> open(
      WidgetTester tester, {
      int chapter = 0,
      Size size = const Size(732, 360),
      void Function(String, int)? onRead,
      bool Function(String, int)? wasRead,
    }) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      final router = GoRouter(initialLocation: '/start', routes: [
        GoRoute(
          path: '/start',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push('/story/pre-colonial/$chapter'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/story/:eraId/:chapter',
          builder: (context, state) => FullStoryScreen(
            eraId: state.pathParameters['eraId']!,
            chapter: int.parse(state.pathParameters['chapter']!),
            onChapterRead: onRead ?? (_, __) {},
            wasRead: wasRead ?? (_, __) => false,
          ),
        ),
        GoRoute(
            path: '/background/:eraId',
            builder: (_, __) => const Scaffold(body: Text('story stand-in'))),
      ]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    setUp(() {
      _fake({
        'pre-colonial': [
          _chapter('1'),
          _chapter('2', paragraphs: 14),
          _chapter('3-4', paragraphs: 1, terms: 0),
        ],
      });
    });

    testWidgets(
        'opens at the chapter asked for, with its title and no reading counted yet',
        (tester) async {
      await open(tester, chapter: 1);
      expect(find.text('Pamagat 2'), findsOneWidget);
      expect(find.text('LINGGO 2'), findsOneWidget);
      expect(find.text('2 NG 3'), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(FullStoryScreen.meterKey),
              matching: find.textContaining('NABASA 0%')),
          findsOneWidget);
    });

    testWidgets('scrolling to the end counts the chapter as read, once',
        (tester) async {
      final read = <String>[];
      await open(tester, onRead: (e, i) => read.add('$e/$i'));
      expect(read, isEmpty);
      await tester.drag(
          find.byKey(FullStoryScreen.scrollKey), const Offset(0, -6000));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.drag(
          find.byKey(FullStoryScreen.scrollKey), const Offset(0, -6000));
      await tester.pump(const Duration(milliseconds: 300));
      expect(read, ['pre-colonial/0']);
      expect(find.textContaining('NABASA NA'), findsWidgets);
      expect(find.text('NABASA NA ✓'), findsWidgets);
    });

    testWidgets('a chapter read halfway is not read', (tester) async {
      final read = <String>[];
      await open(tester, onRead: (e, i) => read.add('$e/$i'));
      await tester.drag(
          find.byKey(FullStoryScreen.scrollKey), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(read, isEmpty);
    });

    testWidgets('a chapter that fits without scrolling is read at once',
        (tester) async {
      final read = <String>[];
      await open(tester,
          chapter: 2,
          size: const Size(900, 700),
          onRead: (e, i) => read.add('$e/$i'));
      expect(read, ['pre-colonial/2']);
    });

    testWidgets('a chapter read before shows as read from the start',
        (tester) async {
      await open(tester, wasRead: (e, i) => i == 0);
      expect(find.text('NABASA NA ✓'), findsWidgets);
    });

    testWidgets('the arrows change the chapter, and stop at the ends',
        (tester) async {
      await open(tester);
      expect(find.text('Pamagat 1'), findsOneWidget);
      await tester.tap(find.byKey(FullStoryScreen.prevKey));
      await tester.pump();
      expect(find.text('Pamagat 1'), findsOneWidget,
          reason: 'there is none before the first');
      await tester.tap(find.byKey(FullStoryScreen.nextKey));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Pamagat 2'), findsOneWidget);
      await tester.tap(find.byKey(FullStoryScreen.nextKey));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Pamagat 3-4'), findsOneWidget);
      await tester.tap(find.byKey(FullStoryScreen.nextKey));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Pamagat 3-4'), findsOneWidget,
          reason: 'there is none after the last');
    });

    testWidgets('A+ and A- change the size of the letters', (tester) async {
      await open(tester);
      double size() => tester
          .widget<Text>(find.byKey(FullStoryScreen.titleKey))
          .style!
          .fontSize!;
      final start = size();
      await tester.tap(find.byKey(FullStoryScreen.largerKey));
      await tester.pump(const Duration(milliseconds: 100));
      expect(size(), greaterThan(start));
      await tester.tap(find.byKey(FullStoryScreen.smallerKey));
      await tester.tap(find.byKey(FullStoryScreen.smallerKey));
      await tester.pump(const Duration(milliseconds: 100));
      expect(size(), lessThan(start));
    });

    testWidgets('the key terms are shown with their meanings', (tester) async {
      await open(tester);
      await tester.drag(
          find.byKey(FullStoryScreen.scrollKey), const Offset(0, -6000));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(FullStoryScreen.termKey(0)), findsOneWidget);
      expect(find.textContaining('Kahulugan 1', findRichText: true),
          findsOneWidget);
    });

    testWidgets('fits a small phone held sideways and upright without overflow',
        (tester) async {
      for (final size in const [
        Size(640, 360),
        Size(732, 320),
        Size(400, 700)
      ]) {
        await open(tester, size: size);
        expect(tester.takeException(), isNull, reason: '$size');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('the back chip returns to where the reader came from',
        (tester) async {
      await open(tester);
      await tester.tap(find.byKey(FullStoryScreen.backKey));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('an era with no full text says so instead of failing',
        (tester) async {
      _fake({});
      await open(tester);
      expect(find.textContaining('Wala pang buong kwento'), findsOneWidget);
    });
  });

  group('the button on the story card', () {
    Future<GoRouter> openCard(WidgetTester tester,
        {String era = 'pre-colonial'}) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(732, 320);
      addTearDown(tester.view.reset);
      final router = GoRouter(initialLocation: '/background/$era', routes: [
        GoRoute(
          path: '/background/:eraId',
          builder: (context, state) => BackgroundHistoryScreen(
            eraId: state.pathParameters['eraId']!,
            alreadyRead: false,
            onStoryRead: (_) {},
          ),
        ),
        GoRoute(
          path: '/story/:eraId/:chapter',
          builder: (context, state) => FullStoryScreen(
            eraId: state.pathParameters['eraId']!,
            chapter: int.parse(state.pathParameters['chapter']!),
            onChapterRead: (_, __) {},
            wasRead: (_, __) => false,
          ),
        ),
        GoRoute(path: '/era-selection', builder: (_, __) => const SizedBox()),
      ]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump(const Duration(milliseconds: 600));
      return router;
    }

    testWidgets('shows on the card with the name of the chapter it opens',
        (tester) async {
      _fake({
        'pre-colonial': [for (var i = 1; i <= 10; i++) _chapter('$i')],
      });
      await openCard(tester);
      expect(find.byKey(BackgroundHistoryScreen.fullStoryKey), findsOneWidget);
      expect(find.textContaining('BASAHIN ANG BUONG KWENTO'), findsOneWidget);
      expect(find.textContaining('LINGGO 1'), findsWidgets);
    });

    testWidgets('opens the chapter of the card and comes back to the same card',
        (tester) async {
      _fake({
        'pre-colonial': [for (var i = 1; i <= 10; i++) _chapter('$i')],
      });
      await openCard(tester);
      // turn to card 2: it must stay up for its reading time first
      final first = eraStories['pre-colonial']!.beats.first;
      await tester.pump(BackgroundHistoryScreen.readTimeFor(first) +
          const Duration(milliseconds: 100));
      await tester.tap(find.byKey(BackgroundHistoryScreen.beatDotKey(1)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(BackgroundHistoryScreen.fullStoryKey));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      // card 2 of 5 in an era of 10 chapters opens chapter 3 (week 3)
      expect(find.byKey(FullStoryScreen.titleKey), findsOneWidget);
      expect(find.text('Pamagat 3'), findsOneWidget);
      await tester.tap(find.byKey(FullStoryScreen.backKey));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(BackgroundHistoryScreen.beatKey), findsOneWidget);
      expect(find.byKey(BackgroundHistoryScreen.fullStoryKey), findsOneWidget);
    });

    testWidgets('is not there when the era has no full text', (tester) async {
      _fake({});
      await openCard(tester);
      expect(find.byKey(BackgroundHistoryScreen.fullStoryKey), findsNothing);
    });

    testWidgets('does not stop the key terms or the story from working',
        (tester) async {
      _fake({
        'pre-colonial': [for (var i = 1; i <= 10; i++) _chapter('$i')],
      });
      await openCard(tester);
      expect(find.byKey(BackgroundHistoryScreen.lockNoteKey), findsOneWidget);
      expect(
          find.byKey(BackgroundHistoryScreen.readyButtonKey), findsOneWidget);
    });
  });
}
