// The "new version" card: shown once for each version, DOWNLOAD opens the page,
// LATER puts it away and leaves a small chip, a required update has no LATER.
import 'package:chronoquest/core/app_info.dart';
import 'package:chronoquest/providers/update_provider.dart';
import 'package:chronoquest/services/update_check.dart';
import 'package:chronoquest/widgets/update_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _normal = LatestVersion(
  version: '1.9.0',
  notes: ['Saved na ang coins mo kahit magpalit ng phone', 'Bagong pause screen'],
  url: 'https://example.test/get',
);
const _must = LatestVersion(
  version: '2.0.0',
  required: true,
  reason: 'Hindi na makaka-save ng coins at score ang old version',
);

class _Spy {
  final opened = <String>[];
}

Future<UpdateNotifier> _pump(
  WidgetTester tester, {
  LatestVersion? latest,
  String? dismissed,
  _Spy? spy,
  Widget extra = const SizedBox.shrink(),
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 360));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  // Animations off: the DOWNLOAD button would breathe for ever.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAllTestValues);

  final notifier = UpdateNotifier(
    fetch: () async => latest,
    open: (url) async => spy?.opened.add(url),
    dismissed: dismissed,
  );
  await notifier.check();
  await tester.pumpWidget(ProviderScope(
    overrides: [updateProvider.overrideWith((ref) => notifier)],
    child: MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            const Center(child: Text('behind')),
            Positioned(top: 0, right: 0, child: Row(children: [const UpdateChip(), extra])),
            const Positioned.fill(child: UpdateCard()),
            Positioned(bottom: 0, left: 0, child: UpdateRow(key: UniqueKey())),
          ],
        ),
      ),
    ),
  ));
  await tester.pump();
  return notifier;
}

void main() {
  testWidgets('with no newer version nothing shows but the version row', (tester) async {
    await _pump(tester);
    expect(find.byKey(UpdateCard.cardKey), findsNothing);
    expect(find.byKey(UpdateChip.chipKey), findsNothing);
    expect(find.text('Version $appVersion'), findsOneWidget);
    expect(find.byKey(UpdateRow.downloadKey), findsNothing);
  });

  testWidgets('a newer version shows the card with both versions and what is new', (tester) async {
    await _pump(tester, latest: _normal);
    expect(find.byKey(UpdateCard.cardKey), findsOneWidget);
    expect(find.text('May bagong version na!'), findsOneWidget);
    expect(find.text('NEW!'), findsOneWidget);
    expect(find.text('1.9.0'), findsWidgets);
    expect(find.text(appVersion), findsWidgets);
    expect(find.text("WHAT'S NEW"), findsOneWidget);
    expect(find.text('Saved na ang coins mo kahit magpalit ng phone'), findsOneWidget);
    expect(find.byKey(UpdateCard.downloadKey), findsOneWidget);
    expect(find.byKey(UpdateCard.laterKey), findsOneWidget);
    expect(find.byKey(UpdateChip.chipKey), findsNothing, reason: 'the card stands in for it');
  });

  testWidgets('the card shows no notes box when the file has none', (tester) async {
    await _pump(tester, latest: const LatestVersion(version: '1.9.0'));
    expect(find.byKey(UpdateCard.cardKey), findsOneWidget);
    expect(find.text("WHAT'S NEW"), findsNothing);
  });

  testWidgets('DOWNLOAD opens the page from the file', (tester) async {
    final spy = _Spy();
    await _pump(tester, latest: _normal, spy: spy);
    await tester.tap(find.byKey(UpdateCard.downloadKey));
    await tester.pump();
    expect(spy.opened, ['https://example.test/get']);
    expect(find.byKey(UpdateCard.cardKey), findsOneWidget, reason: 'still there until installed');
  });

  testWidgets('LATER puts the card away and leaves the chip, and the chip downloads',
      (tester) async {
    final spy = _Spy();
    await _pump(tester, latest: _normal, spy: spy);
    await tester.tap(find.byKey(UpdateCard.laterKey));
    await tester.pump();

    expect(find.byKey(UpdateCard.cardKey), findsNothing);
    expect(find.byKey(UpdateChip.chipKey), findsOneWidget);
    expect(find.text('NEW UPDATE · 1.9.0'), findsOneWidget);
    // Settings still offers it.
    expect(find.byKey(UpdateRow.downloadKey), findsOneWidget);
    expect(find.text('May new version: 1.9.0'), findsOneWidget);

    await tester.tap(find.byKey(UpdateChip.chipKey));
    await tester.pump();
    expect(spy.opened, ['https://example.test/get']);
  });

  testWidgets('a version already put away does not show the card again', (tester) async {
    await _pump(tester, latest: _normal, dismissed: '1.9.0');
    expect(find.byKey(UpdateCard.cardKey), findsNothing);
    expect(find.byKey(UpdateChip.chipKey), findsOneWidget);
  });

  testWidgets('a still newer version shows the card again', (tester) async {
    await _pump(tester, latest: _normal, dismissed: '1.8.0');
    expect(find.byKey(UpdateCard.cardKey), findsOneWidget);
  });

  testWidgets('a required update has no LATER, says why, and cannot be put away',
      (tester) async {
    final n = await _pump(tester, latest: _must, dismissed: '2.0.0');
    expect(find.byKey(UpdateCard.cardKey), findsOneWidget, reason: 'even if put away before');
    expect(find.text('REQUIRED'), findsOneWidget);
    expect(find.text('Mag-update muna bago maglaro'), findsOneWidget);
    expect(find.text('BAKIT?'), findsOneWidget);
    expect(find.text('Hindi na makaka-save ng coins at score ang old version'), findsOneWidget);
    expect(find.byKey(UpdateCard.laterKey), findsNothing);
    expect(find.byKey(UpdateCard.downloadKey), findsOneWidget);

    n.dismiss();
    await tester.pump();
    expect(find.byKey(UpdateCard.cardKey), findsOneWidget);
  });

  testWidgets('nothing behind the card can be tapped', (tester) async {
    var tapped = false;
    await _pump(
      tester,
      latest: _normal,
      extra: GestureDetector(onTap: () => tapped = true, child: const SizedBox(key: Key('behind_box'), width: 200, height: 200)),
    );
    await tester.tap(find.byKey(const Key('behind_box')), warnIfMissed: false);
    await tester.pump();
    expect(tapped, isFalse, reason: 'the dim layer takes the tap');
  });

  testWidgets('the card fits a short landscape phone', (tester) async {
    await _pump(tester, latest: _normal);
    await tester.binding.setSurfaceSize(const Size(640, 300));
    await tester.pump();
    expect(tester.takeException(), isNull);
    final box = tester.getRect(find.byKey(UpdateCard.downloadKey));
    expect(box.bottom, lessThanOrEqualTo(300));
    expect(box.height, greaterThanOrEqualTo(40), reason: 'big enough to hit');
  });
}
