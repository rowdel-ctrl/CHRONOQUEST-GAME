// The blank hop that starts a level again: it opens the same level's game screen on the next frame.
import 'package:chronoquest/screens/game/restart_level_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('goes straight to the same level\'s game', (tester) async {
    final router = GoRouter(initialLocation: '/restart/spanish/3', routes: [
      GoRoute(
        path: '/restart/:eraId/:level',
        builder: (_, s) => RestartLevelScreen(
          eraId: s.pathParameters['eraId']!,
          level: int.parse(s.pathParameters['level']!),
        ),
      ),
      GoRoute(
        path: '/game/:eraId/:level',
        builder: (_, s) => Text('game ${s.pathParameters['eraId']} ${s.pathParameters['level']}'),
      ),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('game spanish 3'), findsOneWidget);
  });
}
