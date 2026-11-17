// The lesson card: the lesson of one level, read before the level starts. How long it must be
// read, that START stays locked until the time is up AND the text has been read to its end,
// that a lesson finished before opens START at once, and that a level without a lesson text
// goes straight to the game. Also that every real level has exactly one lesson.
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/data/history_full.dart';
import 'package:chronoquest/screens/game/full_story_screen.dart';
import 'package:chronoquest/screens/game/lesson_card_screen.dart';
import 'package:chronoquest/widgets/game_ui.dart';
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

FullChapter _chapter(String weeks, {int paragraphs = 14, int terms = 2}) =>
    FullChapter(
      weeks: weeks,
      title: 'Pamagat $weeks',
      paragraphs: [
        for (var i = 0; i < paragraphs; i++)
          'Talata $i ng kabanata: ang **barangay** ay maliit na komunidad na '
              'pinamumunuan ng isang datu, at ang mga tao ay nagtutulungan sa '
              'pagsasaka, pangingisda, at pakikipagkalakalan sa mga karatig na pulo.',
      ],
      terms: [for (var i = 0; i < terms; i++) ('Salita $i', 'Kahulugan $i')],
    );

FullChapter _words(int n) => FullChapter(
      weeks: '1',
      title: 'Pamagat',
      paragraphs: [List.filled(n, 'salita').join(' ')],
      terms: const [],
    );

void _fake(Map<String, List<FullChapter>> data) {
  HistoryFull.loader = () async => data;
  HistoryFull.reset();
}

List<int> _weeksOf(String weeks) {
  final parts = weeks.split('-').map(int.parse).toList();
  return [for (var w = parts.first; w <= parts.last; w++) w];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('the reading time', () {
    test('is the words at 250 a minute, rounded up, at least 20 s and at most 150 s',
        () {
      expect(LessonCardScreen.readSeconds(_words(168)), 41);
      expect(LessonCardScreen.readSeconds(_words(250)), 60);
      expect(LessonCardScreen.readSeconds(_words(10)), 20);
      expect(LessonCardScreen.readSeconds(_words(5000)), 150);
    });
  });

  group('the real lessons', () {
    late Map<String, List<FullChapter>> real;

    setUpAll(() async {
      HistoryFull.reset();
      real = {for (final e in _eras) e: await HistoryFull.chapters(e)};
    });

    test('every level has exactly one lesson, the chapter of its own weeks', () {
      for (final e in _eras) {
        final levels = getEraById(e).levels;
        expect(real[e]!.length, levels.length, reason: e);
        for (var i = 0; i < levels.length; i++) {
          expect(_weeksOf(real[e]![i].weeks), levels[i].curriculum.weeks,
              reason: '$e level ${i + 1}');
        }
      }
    });

    test('every lesson is read for a fair time, under a minute and 40 seconds', () {
      for (final e in _eras) {
        for (final c in real[e]!) {
          final s = LessonCardScreen.readSeconds(c);
          expect(s, inInclusiveRange(20, 100), reason: '$e ${c.weeks}');
        }
      }
    });
  });

  group('the card', () {
    final events = <String>[];

    Future<void> open(
      WidgetTester tester, {
      int level = 1,
      Size size = const Size(732, 360),
      bool done = false,
      String era = 'pre-colonial',
    }) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      final router = GoRouter(initialLocation: '/lesson/$era/$level', routes: [
        GoRoute(
          path: '/lesson/:eraId/:level',
          builder: (context, state) => LessonCardScreen(
            eraId: state.pathParameters['eraId']!,
            level: int.parse(state.pathParameters['level']!),
            wasDone: (e, i) => done,
            onDone: (e, i) => events.add('done $e/$i'),
          ),
        ),
        GoRoute(
          path: '/game/:eraId/:level',
          builder: (context, state) {
            events.add(
                'game ${state.pathParameters['eraId']}/${state.pathParameters['level']}');
            return const Scaffold(body: Text('game stand-in'));
          },
        ),
        GoRoute(
          path: '/level-select/:eraId',
          builder: (context, state) {
            events.add('select ${state.pathParameters['eraId']}');
            return const Scaffold(body: Text('level select stand-in'));
          },
        ),
      ]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> scrollToEnd(WidgetTester tester) async {
      for (var i = 0; i < 3; i++) {
        await tester.drag(
            find.byKey(LessonCardScreen.scrollKey), const Offset(0, -6000));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    bool startOpen(WidgetTester tester) =>
        tester.widget<GameButton>(find.byKey(LessonCardScreen.startKey))
            .onPressed !=
        null;

    String note(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(LessonCardScreen.noteKey)).data!;

    setUp(() {
      events.clear();
      _fake({
        'pre-colonial': [
          _chapter('1'),
          _chapter('2'),
          _chapter('3', paragraphs: 1, terms: 0),
        ],
      });
    });

    testWidgets('opens with the lesson of that level, START locked and the time running',
        (tester) async {
      await open(tester, level: 2);
      expect(find.text('Pamagat 2'), findsOneWidget);
      expect(find.text('LINGGO 2'), findsOneWidget);
      expect(find.text('MAHAHALAGANG SALITA'), findsOneWidget);
      expect(startOpen(tester), isFalse);
      expect(note(tester), 'Basahin muna ang aralin');
      final secs = LessonCardScreen.readSeconds(_chapter('2'));
      final shown = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
      expect(
          find.descendant(
              of: find.byKey(LessonCardScreen.timerKey),
              matching: find.text(shown)),
          findsOneWidget);
    });

    testWidgets('no arrows to other lessons: only this level is on the card',
        (tester) async {
      await open(tester);
      expect(find.text('KABANATA'), findsNothing);
      expect(find.text('Pamagat 2'), findsNothing);
      expect(find.text('Pamagat 3'), findsNothing);
    });

    testWidgets('scrolling to the end is not enough while the time runs',
        (tester) async {
      await open(tester);
      await scrollToEnd(tester);
      expect(startOpen(tester), isFalse);
      expect(note(tester), 'Hintayin ang oras');
      expect(events, isEmpty, reason: 'the lesson is not finished yet');
    });

    testWidgets('the time up is not enough while the text is not read to its end',
        (tester) async {
      await open(tester);
      await tester.pump(
          Duration(seconds: LessonCardScreen.readSeconds(_chapter('1')) + 2));
      expect(startOpen(tester), isFalse);
      expect(note(tester), 'Ibaba pa hanggang dulo');
      expect(events, isEmpty);
    });

    testWidgets('both done: START opens, the lesson is saved once, and START starts the level',
        (tester) async {
      await open(tester);
      await tester.pump(
          Duration(seconds: LessonCardScreen.readSeconds(_chapter('1')) + 2));
      await scrollToEnd(tester);
      expect(startOpen(tester), isTrue);
      expect(note(tester), 'Handa ka na!');
      expect(events, ['done pre-colonial/0']);
      await tester.tap(find.byKey(LessonCardScreen.startKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(events.last, 'game pre-colonial/1');
      expect(events.where((e) => e.startsWith('done')).length, 1);
    });

    testWidgets('a lesson that fits without scrolling is read at once: only the time is left',
        (tester) async {
      await open(tester, level: 3, size: const Size(900, 700));
      expect(startOpen(tester), isFalse);
      await tester.pump(
          Duration(seconds: LessonCardScreen.readSeconds(_chapter('3')) + 1));
      expect(startOpen(tester), isTrue);
    });

    testWidgets('a lesson finished before opens START at once, with no waiting',
        (tester) async {
      await open(tester, done: true);
      expect(startOpen(tester), isTrue);
      expect(find.text('TAPOS NA'), findsOneWidget);
      await tester.tap(find.byKey(LessonCardScreen.startKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(events, ['game pre-colonial/1']);
    });

    testWidgets('the time only runs while the game is in front', (tester) async {
      await open(tester);
      final timer = find.descendant(
          of: find.byKey(LessonCardScreen.timerKey),
          matching: find.byType(Text));
      final before = tester.widget<Text>(timer.at(1)).data;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 30));
      expect(tester.widget<Text>(timer.at(1)).data, before);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 5));
      expect(tester.widget<Text>(timer.at(1)).data, isNot(before));
    });

    testWidgets('a level with no lesson text goes straight to the game',
        (tester) async {
      await open(tester, level: 9);
      await tester.pump(const Duration(milliseconds: 200));
      expect(events, ['game pre-colonial/9']);
      expect(find.text('game stand-in'), findsOneWidget);
    });

    testWidgets('an era with no lessons at all goes straight to the game',
        (tester) async {
      _fake({'pre-colonial': const []});
      await open(tester);
      await tester.pump(const Duration(milliseconds: 200));
      expect(events, ['game pre-colonial/1']);
    });

    testWidgets('A- and A+ change the size of the letters, and stop at the ends',
        (tester) async {
      await open(tester);
      double size() =>
          tester.widget<Text>(find.byKey(LessonCardScreen.titleKey)).style!
              .fontSize!;
      final start = size();
      await tester.tap(find.byKey(LessonCardScreen.largerKey));
      await tester.pump(const Duration(milliseconds: 100));
      expect(size(), greaterThan(start));
      for (var i = 0; i < 8; i++) {
        await tester.tap(find.byKey(LessonCardScreen.smallerKey));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(size(), FullStoryScreen.sizes.first + 2);
    });

    testWidgets('the back button goes to the levels of the era', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(LessonCardScreen.backKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(events, ['select pre-colonial']);
    });

    testWidgets('on a narrow screen the card, the controls and START still fit',
        (tester) async {
      await open(tester, size: const Size(400, 700));
      expect(find.text('SIMULAN ANG LEVEL'), findsOneWidget);
      expect(find.byKey(LessonCardScreen.meterKey), findsOneWidget);
      expect(find.byKey(LessonCardScreen.smallerKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a short wide screen shows every control without overflowing',
        (tester) async {
      await open(tester, size: const Size(640, 360));
      expect(find.text('SIMULAN!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
