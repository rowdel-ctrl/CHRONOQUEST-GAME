import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'providers/auth_provider.dart';
import 'providers/badge_provider.dart';
import 'providers/update_provider.dart';
import 'widgets/session_replaced_gate.dart';

class ChronoQuestApp extends ConsumerStatefulWidget {
  const ChronoQuestApp({super.key});

  @override
  ConsumerState<ChronoQuestApp> createState() => _ChronoQuestAppState();
}

class _ChronoQuestAppState extends ConsumerState<ChronoQuestApp>
    with WidgetsBindingObserver {
  /// A phone whose account was signed in on another device finds out without waiting for the
  /// next level: the server is asked when the game opens or comes back, every [_watchEvery]
  /// while it is open, and when a menu opens (see AuthNotifier.checkSession). A short gap keeps
  /// it from asking twice in a row; a whole class on one network is many phones.
  static const Duration _watchEvery = Duration(minutes: 2);
  Timer? _watch;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref.read(authProvider.notifier).checkSession();
  }

  @override
  void dispose() {
    _watch?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _watch = Timer.periodic(_watchEvery, (_) {
      ref.read(authProvider.notifier).checkSession(minGap: const Duration(seconds: 90));
    });
    // The saved login is read a moment after the game opens; then ask the server about it.
    Future<void>.delayed(const Duration(seconds: 3),
        () => mounted ? ref.read(authProvider.notifier).checkSession() : null);
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
