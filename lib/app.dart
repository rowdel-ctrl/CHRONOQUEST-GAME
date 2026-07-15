import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/router.dart';

class ChronoQuestApp extends StatelessWidget {
  const ChronoQuestApp({super.key});

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
