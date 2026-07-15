import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/character_selection_screen.dart';
import '../screens/home/era_selection_screen.dart';
import '../screens/game/pre_test_screen.dart';
import '../screens/game/background_history_screen.dart';
import '../screens/game/level_select_screen.dart';
import '../screens/game/game_screen.dart';
import '../screens/game/level_complete_screen.dart';
import '../screens/game/level_failed_screen.dart';
import '../screens/game/era_complete_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/leaderboard_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/login',
  redirect: (context, state) async {
    final hasToken = await StorageService.hasToken();
    final isLoginRoute = state.matchedLocation == '/login';

    if (!hasToken && !isLoginRoute) return '/login';
    if (hasToken && isLoginRoute) return '/character-selection';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/character-selection',
      builder: (context, state) => const CharacterSelectionScreen(),
    ),
    GoRoute(
      path: '/era-selection',
      builder: (context, state) => const EraSelectionScreen(),
    ),
    GoRoute(
      path: '/pre-test/:eraId',
      builder: (context, state) => PreTestScreen(
        eraId: state.pathParameters['eraId']!,
      ),
    ),
    GoRoute(
      path: '/background/:eraId',
      builder: (context, state) => BackgroundHistoryScreen(
        eraId: state.pathParameters['eraId']!,
      ),
    ),
    GoRoute(
      path: '/level-select/:eraId',
      builder: (context, state) => LevelSelectScreen(
        eraId: state.pathParameters['eraId']!,
      ),
    ),
    GoRoute(
      path: '/game/:eraId/:level',
      builder: (context, state) => GameScreen(
        eraId: state.pathParameters['eraId']!,
        level: int.parse(state.pathParameters['level']!),
      ),
    ),
    GoRoute(
      path: '/level-complete/:eraId/:level',
      builder: (context, state) => LevelCompleteScreen(
        eraId: state.pathParameters['eraId']!,
        level: int.parse(state.pathParameters['level']!),
      ),
    ),
    GoRoute(
      path: '/level-failed/:eraId/:level',
      builder: (context, state) => LevelFailedScreen(
        eraId: state.pathParameters['eraId']!,
        level: int.parse(state.pathParameters['level']!),
      ),
    ),
    GoRoute(
      path: '/era-complete/:eraId',
      builder: (context, state) => EraCompleteScreen(
        eraId: state.pathParameters['eraId']!,
      ),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'Page not found: ${state.error}',
        style: const TextStyle(fontSize: 16),
      ),
    ),
  ),
);
