import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'providers/auth_provider.dart';
import 'providers/badge_provider.dart';
import 'providers/update_provider.dart';

class ChronoQuestApp extends ConsumerStatefulWidget {
  const ChronoQuestApp({super.key});

  @override
  ConsumerState<ChronoQuestApp> createState() => _ChronoQuestAppState();
}

class _ChronoQuestAppState extends ConsumerState<ChronoQuestApp> {
  @override
  void initState() {
    super.initState();
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
    );
  }
}
