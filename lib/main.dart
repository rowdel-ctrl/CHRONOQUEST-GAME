import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape for game experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide status bar for immersive game
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Hive for local storage
  await StorageService.initHive();

  // Retry any quiz results that failed to submit while offline last session.
  // Fire-and-forget: don't block app launch on network access, and any
  // still-unsent results just stay queued for the next attempt.
  ApiService().flushPendingResults();

  runApp(
    const ProviderScope(
      child: ChronoQuestApp(),
    ),
  );
}