// The Codex: all ten artifacts of an era are always there. A claimed one is in colour
// on a parchment tile, one still to find is a dark shape with a "?". Six era tabs
// with "claimed/10", a "N ng 60" pill, and a panel for the artifact that is tapped.
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/codex_entry.dart';
import 'package:chronoquest/screens/profile/codex_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

CodexEntry _entry(String era, int sprite,
        {String? id, int at = 0, String? blurb}) =>
    CodexEntry(
      eraId: era,
      questionId: id ?? '$era-q$sprite',
      artifactSprite: sprite,
      questionText: 'Tanong $sprite ng $era',
      blurb: blurb ?? 'Kasaysayan ng artifact $sprite sa $era.',
      claimedAtMs: at,
    );

Future<void> _open(
  WidgetTester tester,
  Map<String, List<CodexEntry>> claims, {
  Size size = const Size(732, 320),
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
      home: CodexScreen(entriesFor: (era) => claims[era] ?? const [])));
  await tester.pump();
}

Color? _tileColor(WidgetTester tester, int n) => (tester
        .widget<Container>(find
            .descendant(
                of: find.byKey(CodexScreen.slotKey(n)),
                matching: find.byType(Container))
            .first)
        .decoration as BoxDecoration)
    .color;

String _assetOf(Image i) => (i.image as AssetImage).assetName;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final claims = {
    'pre-colonial': [
      for (var n = 1; n <= 10; n++) _entry('pre-colonial', n, at: n)
    ],
    'spanish': [_entry('spanish', 2, at: 5), _entry('spanish', 4, at: 6)],
  };

  testWidgets(
      'shows all ten slots of the era, claimed in colour and the rest dark with a ?',
      (tester) async {
    await _open(tester, claims);
    // It opens on the first era with claims (the first one here), so use the second.
    await tester.tap(find.byKey(CodexScreen.tabKey(1)));
    await tester.pump();

    for (var n = 1; n <= 10; n++) {
      expect(find.byKey(CodexScreen.slotKey(n)), findsOneWidget,
          reason: 'slot $n');
      expect(
          tester
              .widgetList<Image>(find.descendant(
                  of: find.byKey(CodexScreen.slotKey(n)),
                  matching: find.byType(Image)))
              .map(_assetOf),
          ['assets/collectibles/artifact_spanish_$n.png']);
      final claimed = n == 2 || n == 4;
      expect(_tileColor(tester, n) == AppColors.surface, claimed,
          reason: 'slot $n');
      expect(
          find.descendant(
              of: find.byKey(CodexScreen.slotKey(n)), matching: find.text('?')),
          claimed ? findsNothing : findsOneWidget,
          reason: 'slot $n');
    }
    expect(find.byKey(CodexScreen.slotKey(11)), findsNothing);
  });

  testWidgets(
      'a tab for each era with its number and claimed/10, and the total is N ng 60',
      (tester) async {
    await _open(tester, claims);

    expect(find.text('10/10'), findsOneWidget);
    expect(find.text('2/10'), findsOneWidget);
    expect(find.text('0/10'), findsNWidgets(4));
    for (var i = 0; i < 6; i++) {
      expect(find.byKey(CodexScreen.tabKey(i)), findsOneWidget);
    }
    expect(
        find.descendant(
            of: find.byKey(CodexScreen.totalKey),
            matching: find.text('12 ng 60')),
        findsOneWidget);
    expect(find.text('KODEKS'), findsOneWidget);
  });

  testWidgets(
      'the selected tab is gold and tapping another one changes the era',
      (tester) async {
    await _open(tester, claims);
    Color? tabColor(int i) => (tester
            .widget<Container>(find
                .descendant(
                    of: find.byKey(CodexScreen.tabKey(i)),
                    matching: find.byType(Container))
                .first)
            .decoration as BoxDecoration)
        .color;

    expect(tabColor(0), AppColors.accent);
    expect(tabColor(1), isNot(AppColors.accent));
    await tester.tap(find.byKey(CodexScreen.tabKey(1)));
    await tester.pump();
    expect(tabColor(1), AppColors.accent);
    expect(tabColor(0), isNot(AppColors.accent));
    expect(find.text(allEras[1].name), findsWidgets);
    // The panel moved to the first artifact of that era that is claimed (the 2nd).
    expect(
        find.descendant(
            of: find.byKey(CodexScreen.detailKey),
            matching: find.text('Artifact 2')),
        findsOneWidget);
  });

  testWidgets(
      'a claimed artifact is described with the same blurb the dialog used to show',
      (tester) async {
    await _open(tester, claims);
    await tester.tap(find.byKey(CodexScreen.slotKey(3)));
    await tester.pump();

    final panel = find.byKey(CodexScreen.detailKey);
    expect(find.descendant(of: panel, matching: find.text('Artifact 3')),
        findsOneWidget);
    expect(find.descendant(of: panel, matching: find.text(allEras[0].name)),
        findsOneWidget);
    expect(
        find.descendant(
            of: panel,
            matching: find.text('Kasaysayan ng artifact 3 sa pre-colonial.')),
        findsOneWidget);
    expect(
        find.descendant(
            of: panel, matching: find.text('Tanong 3 ng pre-colonial')),
        findsOneWidget);
    expect(find.text(CodexScreen.unclaimedText), findsNothing);
  });

  testWidgets('an artifact still to find says how to get it', (tester) async {
    await _open(tester, claims);
    await tester.tap(find.byKey(CodexScreen.tabKey(1)));
    await tester.pump();
    await tester.tap(find.byKey(CodexScreen.slotKey(7)));
    await tester.pump();

    final panel = find.byKey(CodexScreen.detailKey);
    expect(find.descendant(of: panel, matching: find.text('Artifact 7')),
        findsOneWidget);
    expect(
        find.descendant(
            of: panel, matching: find.text(CodexScreen.unclaimedText)),
        findsOneWidget);
    expect(CodexScreen.unclaimedText,
        'Sagutin nang tama ang tanong ng artifact na ito sa isang level para makuha ito.');
  });

  testWidgets(
      'an artifact more than one answer gave can be paged, newest first',
      (tester) async {
    await _open(tester, {
      'pre-colonial': [
        _entry('pre-colonial', 1, id: 'old', at: 1, blurb: 'Luma.'),
        _entry('pre-colonial', 1, id: 'new', at: 9, blurb: 'Bago.'),
      ],
    });
    expect(find.text('Bago.'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    await tester.tap(find.byKey(CodexScreen.nextEntryKey));
    await tester.pump();
    expect(find.text('Luma.'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
    // It counts as one artifact, not two.
    expect(
        find.descendant(
            of: find.byKey(CodexScreen.totalKey),
            matching: find.text('1 ng 60')),
        findsOneWidget);
  });

  testWidgets('with nothing claimed every slot is dark, with a short hint',
      (tester) async {
    await _open(tester, const {});

    for (var n = 1; n <= 10; n++) {
      expect(_tileColor(tester, n), isNot(AppColors.surface),
          reason: 'slot $n');
    }
    expect(
        find.descendant(
            of: find.byKey(CodexScreen.totalKey),
            matching: find.text('0 ng 60')),
        findsOneWidget);
    expect(find.text('Wala ka pang nakukuhang artifact.'), findsOneWidget);
    expect(find.text(CodexScreen.unclaimedText), findsOneWidget);
    expect(find.text('0/10'), findsNWidgets(6));
  });

  testWidgets('the helpers count a picture once however many answers gave it',
      (tester) async {
    final slots = codexSlots([
      _entry('spanish', 3, id: 'a', at: 1),
      _entry('spanish', 3, id: 'b', at: 2),
      _entry('spanish', 5)
    ]);
    expect(slots.keys.toSet(), {3, 5});
    expect(slots[3]!.first.questionId, 'b', reason: 'newest first');
  });

  for (final size in const [Size(732, 320), Size(640, 360), Size(400, 700)]) {
    testWidgets(
        'fits ${size.width.toInt()}x${size.height.toInt()}, tiles and tabs on screen',
        (tester) async {
      await _open(tester, claims, size: size);
      // A long blurb must not overflow either.
      expect(tester.takeException(), isNull);
      final screen = Offset.zero & size;
      for (var n = 1; n <= 10; n++) {
        final r = tester.getRect(find.byKey(CodexScreen.slotKey(n)));
        expect(screen.contains(r.center), isTrue,
            reason: 'slot $n is on screen');
        expect(find.byKey(CodexScreen.slotKey(n)).hitTestable(), findsOneWidget,
            reason: 'slot $n');
      }
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(CodexScreen.tabKey(i)).hitTestable(), findsOneWidget,
            reason: 'tab $i');
      }
      expect(find.byKey(CodexScreen.detailKey), findsOneWidget);
      expect(find.byKey(CodexScreen.totalKey).hitTestable(), findsOneWidget);
    });

    testWidgets(
        'a long blurb scrolls instead of overflowing at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await _open(
          tester,
          {
            'pre-colonial': [
              _entry('pre-colonial', 1,
                  blurb: List.filled(40, 'Mahabang kasaysayan').join(' '))
            ],
          },
          size: size);
      expect(tester.takeException(), isNull);
    });
  }
}
