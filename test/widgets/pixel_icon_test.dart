// The menu icons: every glyph is a full 12 x 12 grid with something drawn, and
// the chip that carries them is a 48 pixel target that reports taps.
import 'package:chronoquest/widgets/menu_chip.dart';
import 'package:chronoquest/widgets/pixel_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every glyph has art, and it is a 12 x 12 grid', () {
    for (final glyph in PixelGlyph.values) {
      final rows = pixelGlyphRows[glyph];
      expect(rows, isNotNull, reason: '$glyph has no art');
      expect(rows!.length, 12, reason: '$glyph needs 12 rows');
      for (final row in rows) {
        expect(row.length, 12, reason: '$glyph has a row of ${row.length}');
        expect(RegExp(r'^[#.]+$').hasMatch(row), isTrue,
            reason: '$glyph row "$row" holds something other than # and .');
      }
      expect(rows.join().contains('#'), isTrue, reason: '$glyph is blank');
    }
  });

  testWidgets('the chip is 48 square to hit and says what it is', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: MenuChip(
          icon: PixelGlyph.gear,
          tooltip: 'Settings',
          onTap: () => taps++,
        ),
      ),
    ));

    expect(tester.getSize(find.byType(MenuChip)), const Size(48, 48));
    expect(find.byTooltip('Settings'), findsOneWidget);

    await tester.tap(find.byType(MenuChip));
    expect(taps, 1);
  });

  testWidgets('every glyph paints without error', (tester) async {
    for (final glyph in PixelGlyph.values) {
      await tester.pumpWidget(MaterialApp(
        home: Center(child: PixelIcon(glyph, size: 17, color: Colors.amber)),
      ));
      expect(tester.takeException(), isNull, reason: '$glyph');
    }
  });
}
