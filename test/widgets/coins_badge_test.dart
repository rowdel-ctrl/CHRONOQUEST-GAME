// "+35 COINS" with a coin before it: what a level or a boss fight paid.
import 'package:chronoquest/widgets/game_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('says how many coins, with a coin picture before the words', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: CoinsBadge(coins: 35)))),
    );

    expect(find.text('+35 COINS'), findsOneWidget);
    final coin = find.descendant(of: find.byType(CoinsBadge), matching: find.byType(Image));
    expect(coin, findsOneWidget);
    expect(tester.getTopLeft(coin).dx, lessThan(tester.getTopLeft(find.text('+35 COINS')).dx));
  });

  testWidgets('a big number still fits in a narrow space', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox(width: 160, child: CoinsBadge(coins: 12345))),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('+12345 COINS'), findsOneWidget);
  });
}
