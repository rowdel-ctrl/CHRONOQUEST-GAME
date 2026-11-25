import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'providers/auth_provider.dart';
import 'providers/badge_provider.dart';
import 'providers/update_provider.dart';
import 'services/guest_mode.dart';
import 'widgets/session_replaced_gate.dart';

class ChronoQuestApp extends ConsumerStatefulWidget {
  const ChronoQuestApp({super.key});

  @override
  ConsumerState<ChronoQuestApp> createState() => _ChronoQuestAppState();
}

class _ChronoQuestAppState extends ConsumerState<ChronoQuestApp>
    with WidgetsBindingObserver {
  /// Coming back to the game asks the server for the profile at most this often, so a phone
  /// whose account was signed in elsewhere finds out without waiting for the next level.
  static const Duration _resumeCheckEvery = Duration(minutes: 2);
  DateTime? _lastResumeCheck;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!ref.read(authProvider).isLoggedIn || GuestMode.active) return;
    final now = DateTime.now();
    final last = _lastResumeCheck;
    if (last != null && now.difference(last) < _resumeCheckEvery) return;
    _lastResumeCheck = now;
    ref.read(authProvider.notifier).refreshProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Is there a newer version? Asked once as the game opens; it never holds
    // anything up, and with no internet it just finds nothing.
    Future.microtask(() => ref.read(updateProvider.notifier).check());
    // Badges come back from what the server keeps whenever a student is signed in (a
    // new phone, or a first run after the update). Quiet, and never holds anything up.
    ref.listenManual<String?>(
      authProvider.select((s) => s.student?.id),
      (_, id) {
        // After this change's listeners have switched the badges to the new student.
        if (id != null) {
          Future.microtask(
              () => ref.read(badgeProvider.notifier).syncFromServer());
        }
      },
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ChronoQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      builder: (context, child) => SessionReplacedGate(
        onReturnToLogin: () async {
          await ref.read(authProvider.notifier).logout();
          appRouter.go('/login');
        },
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
