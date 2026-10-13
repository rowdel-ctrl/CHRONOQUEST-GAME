// The leaderboard: where the student stands, the top three, the rest, and the
// states for no data and no connection.
import 'package:chronoquest/models/student.dart';
import 'package:chronoquest/providers/auth_provider.dart';
import 'package:chronoquest/screens/profile/leaderboard_screen.dart';
import 'package:chronoquest/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuth(String id, String name)
      : super(AuthState(
          student: Student.fromJson({'id': id, 'name': name}),
          isLoggedIn: true,
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _row(String id, String name, int score, {int level = 5, String code = 'RIZAL-A'}) =>
    {'_id': id, 'name': name, 'score': score, 'levelReached': level, 'classCode': code};

final _top = [
  _row('a', 'Ana', 1040),
  _row('m', 'Maria', 820),
  _row('j', 'Jose', 760),
  _row('c', 'Carlo', 685, level: 15),
  _row('r', 'Rodel', 650, level: 14),
  _row('l', 'Lea', 610),
];

Future<void> _open(
  WidgetTester tester, {
  required LeaderboardLoader loader,
  String myId = 'r',
  String myName = 'Rodel',
  Size size = const Size(812, 375),
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  await tester.pumpWidget(ProviderScope(
    overrides: [authProvider.overrideWith((ref) => _FakeAuth(myId, myName))],
    child: MaterialApp(home: LeaderboardScreen(loader: loader)),
  ));
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows the student their place and how far the next one is', (tester) async {
    await _open(tester, loader: (_) async => LeaderboardBoard(leaders: _top, myRank: 5, myScore: 650));

    final me = find.byKey(LeaderboardScreen.meCardKey);
    expect(find.descendant(of: me, matching: find.text('#5', findRichText: true)), findsOneWidget);
    expect(find.descendant(of: me, matching: find.text('Rodel')), findsOneWidget);
    expect(find.descendant(of: me, matching: find.text('Antas 14')), findsOneWidget);
    expect(
      find.descendant(of: me, matching: find.textContaining('35 puntos na lang para maabot si Carlo (#4)')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the top three are on the podium and the rest in the list', (tester) async {
    await _open(tester, loader: (_) async => LeaderboardBoard(leaders: _top, myRank: 5, myScore: 650));

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('1,040'), findsOneWidget);
    expect(find.byKey(LeaderboardScreen.rowKey(4)), findsOneWidget);
    expect(find.text('Rodel (ikaw)'), findsOneWidget, reason: 'the own row is marked');
    // Ranks 1 to 3 are not repeated in the list.
    expect(find.byKey(LeaderboardScreen.rowKey(1)), findsNothing);
  });

  testWidgets('the leader is told they are on top', (tester) async {
    await _open(tester,
        myId: 'a', myName: 'Ana', loader: (_) async => LeaderboardBoard(leaders: _top, myRank: 1, myScore: 1040));
    expect(find.text('Ikaw ang nangunguna!'), findsOneWidget);
  });

  testWidgets('a student below the top 20 is pinned under the list', (tester) async {
    await _open(tester,
        myId: 'zed',
        myName: 'Zed',
        loader: (_) async => LeaderboardBoard(leaders: _top, myRank: null, myScore: 120));

    expect(find.text('Zed (ikaw)'), findsOneWidget);
    expect(find.text('20+'), findsWidgets);
    expect(find.textContaining('puntos pa para makapasok sa top 20'), findsOneWidget);
  });

  testWidgets('the school tab also shows each class code', (tester) async {
    await _open(tester, loader: (_) async => LeaderboardBoard(leaders: _top, myRank: 5, myScore: 650));
    expect(find.text('Antas 15 · RIZAL-A'), findsNothing);

    await tester.tap(find.byKey(LeaderboardScreen.tabKey(1)));
    await tester.pump();
    expect(find.text('Antas 15 · RIZAL-A'), findsOneWidget);
  });

  testWidgets('says so when nobody has points', (tester) async {
    await _open(tester, loader: (_) async => const LeaderboardBoard(leaders: []));
    expect(find.text('WALA PANG PUNTOS'), findsOneWidget);
  });

  testWidgets('says so when the server cannot be reached, and tries again', (tester) async {
    var calls = 0;
    await _open(tester, loader: (_) async {
      calls++;
      if (calls <= 1) throw 'offline';
      return LeaderboardBoard(leaders: _top, myRank: 5, myScore: 650);
    });
    expect(find.text('HINDI MA-LOAD'), findsOneWidget);
    expect(find.text('Ana'), findsNothing, reason: 'no made-up names');

    await tester.tap(find.text('SUBUKAN MULI'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('Ana'), findsOneWidget);
  });

  testWidgets('fits small phones, wide and narrow', (tester) async {
    for (final size in const [Size(640, 360), Size(732, 320), Size(390, 780)]) {
      await _open(tester,
          size: size,
          loader: (_) async => LeaderboardBoard(
                leaders: [for (var i = 0; i < 20; i++) _row('s$i', 'Mag-aaral $i', 2000 - i * 30)],
                myRank: 5,
                myScore: 1850,
              ),
          myId: 's4');
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });
}
