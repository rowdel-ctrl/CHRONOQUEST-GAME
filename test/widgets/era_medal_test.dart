// The era medal: a gold disc with the era's number and a red ribbon, drawn in code.
import 'package:chronoquest/widgets/era_medal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('paints every era number, 1 to 6, without error', (tester) async {
    for (var n = 1; n <= 6; n++) {
      await tester.pumpWidget(MaterialApp(home: Center(child: EraMedal(number: n))));
      expect(tester.takeException(), isNull, reason: 'era $n');
    }
  });

  testWidgets('a number out of range is held to 1..6, not a crash', (tester) async {
    for (final n in [0, 7, -3]) {
      await tester.pumpWidget(MaterialApp(home: Center(child: EraMedal(number: n))));
      expect(tester.takeException(), isNull, reason: 'era $n');
    }
  });

  testWidgets('with the ribbon it is a little taller than wide (20 by 22), without it square',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Center(child: EraMedal(number: 2, width: 100))));
    expect(tester.getSize(find.byType(EraMedal)), const Size(100, 110));

    await tester.pumpWidget(
        const MaterialApp(home: Center(child: EraMedal(number: 2, width: 100, ribbon: false))));
    expect(tester.getSize(find.byType(EraMedal)), const Size(100, 100));
  });

  testWidgets('says which era it is for, in words', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Center(child: EraMedal(number: 4))));
    expect(find.bySemanticsLabel('Medalya ng Panahon 4'), findsOneWidget);
  });
}
