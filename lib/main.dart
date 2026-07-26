import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'data/question_bank.dart';
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

  // Load quiz questions from assets/data/*.json before any screen can ask
  // QuestionBank for questions. This replaced a ~5,300-line hardcoded Dart
  // literal, so it's no longer instant/synchronous — it must complete
  // before the first level starts.
  await QuestionBank.loadAll();

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