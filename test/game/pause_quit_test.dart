// Quitting a level from the pause menu was a dead end on-device: the
// confirm dialog's "Umalis" closed the dialog but left the player in
// gameplay. This drives the real PauseOverlayWidget through a real
// GoRouter to cover the whole path — pause -> UMALIS -> confirm -> the
// level-select route actually being reached.
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_spawning.dart';
import 'package:chronoquest/game/overlays/hud_overlay.dart';
import 'package:chronoquest/game/overlays/pause_overlay.dart';

/// ChronoGame without the audio and player art the real onLoad() pulls in,
/// neither of which the quit path touches. The player and spawners are
/// still set up, because update() dereferences both every frame.
class _NoAssetGame extends ChronoGame {
  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    player = PlayerComponent(characterId: 'rizal')
      ..size = Vector2(96, 120)
      ..position = Vector2(0, groundY - 120);
    setupSpawning();
  }
}

Widget _app(ChronoGame game) {
  final router = GoRouter(
    initialLocation: '/game',
    routes: [
      GoRoute(
        path: '/game',
        builder: (context, state) => Scaffold(
          body: PauseOverlayWidget(
            game: game,
            onQuit: () => context.go('/level-select/spanish'),
          ),
        ),
      ),
      GoRoute(
        path: '/level-select/:eraId',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('LEVEL_SELECT')),
        ),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('confirming quit from the pause menu leaves the level',
      (tester) async {
    final game = ChronoGame()..pauseEngine();
    await tester.pumpWidget(_app(game));

    await tester.tap(find.text('UMALIS'));
    await tester.pumpAndSettle();
    expect(find.text('Umalis sa Level?'), findsOneWidget,
        reason: 'UMALIS should raise the confirm dialog');

    await tester.tap(find.text('Umalis'));
    await tester.pumpAndSettle();

    expect(find.text('LEVEL_SELECT'), findsOneWidget,
        reason: 'confirming should land on level select, not stay in game');
    expect(game.paused, isTrue,
        reason: 'the level is being torn down — resuming the loop here lets '
            'stray frames fire level-complete/failed over the quit');
  });

  testWidgets('cancelling quit keeps the player in the level', (tester) async {
    final game = ChronoGame()..pauseEngine();
    await tester.pumpWidget(_app(game));

    await tester.tap(find.text('UMALIS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kanselahin'));
    await tester.pumpAndSettle();

    expect(find.text('LEVEL_SELECT'), findsNothing);
    expect(find.text('PAUSE'), findsOneWidget);
    expect(game.paused, isTrue,
        reason: 'cancelling should leave the game paused behind the menu');
  });

  // The arrangement GameScreen really uses: the overlay is built by
  // GameWidget's overlayBuilderMap, so onQuit closes over GameWidget's own
  // build context rather than the screen's.
  testWidgets('quit works when the overlay is hosted by GameWidget',
      (tester) async {
    final game = _NoAssetGame()..pauseEngine();
    final router = GoRouter(
      initialLocation: '/game',
      routes: [
        GoRoute(
          path: '/game',
          // Mirrors GameScreen._quitToLevelSelect: the overlay is built by
          // GameWidget, but the navigation runs on the route's own context.
          builder: (routeContext, state) => Scaffold(
            body: GameWidget(
              game: game,
              overlayBuilderMap: {
                'PauseOverlay': (context, g) => PauseOverlayWidget(
                      game: g as ChronoGame,
                      onQuit: () => routeContext.go('/level-select/spanish'),
                    ),
              },
              initialActiveOverlays: const ['PauseOverlay'],
            ),
          ),
        ),
        GoRoute(
          path: '/level-select/:eraId',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('LEVEL_SELECT')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('UMALIS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Umalis'));
    await tester.pumpAndSettle();

    expect(find.text('LEVEL_SELECT'), findsOneWidget);
  });

  // The release-build router runs an async redirect on every navigation
  // (DevFlags.skipAuth is false there), and the HUD overlay stays active
  // underneath the pause menu. Closest thing to the on-device arrangement.
  testWidgets('quit works with an async redirect and the HUD still active',
      (tester) async {
    final game = _NoAssetGame()..pauseEngine();
    final router = GoRouter(
      initialLocation: '/game',
      redirect: (context, state) async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return null;
      },
      routes: [
        GoRoute(
          path: '/game',
          builder: (routeContext, state) => Scaffold(
            body: GameWidget(
              game: game,
              overlayBuilderMap: {
                'HudOverlay': (context, g) =>
                    HudOverlayWidget(game: g as ChronoGame),
                'PauseOverlay': (context, g) => PauseOverlayWidget(
                      game: g as ChronoGame,
                      onQuit: () => routeContext.go('/level-select/spanish'),
                    ),
              },
              initialActiveOverlays: const ['HudOverlay', 'PauseOverlay'],
            ),
          ),
        ),
        GoRoute(
          path: '/level-select/:eraId',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('LEVEL_SELECT')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('UMALIS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Umalis'));
    await tester.pumpAndSettle();

    expect(find.text('LEVEL_SELECT'), findsOneWidget);
  });
}
