import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/era_progress.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ProgressState {
  final Map<String, EraProgress> eraProgress;
  final bool isLoading;
  final String? error;

  const ProgressState({
    this.eraProgress = const {},
    this.isLoading = false,
    this.error,
  });

  ProgressState copyWith({
    Map<String, EraProgress>? eraProgress,
    bool? isLoading,
    String? error,
  }) {
    return ProgressState(
      eraProgress: eraProgress ?? this.eraProgress,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProgressNotifier extends StateNotifier<ProgressState> {
  ProgressNotifier() : super(const ProgressState());

  final _api = ApiService();

  Future<void> loadProgress() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final progress = await _api.getEraProgress();
      state = ProgressState(eraProgress: progress);
    } catch (e) {
      // Try loading from cache
      final Map<String, EraProgress> cached = {};
      for (final eraId
          in ['pre-colonial', 'spanish', 'american', 'ww2', 'modern']) {
        final data = StorageService.getCachedEraProgress(eraId);
        if (data != null) {
          cached[eraId] = EraProgress.fromJson(data);
        }
      }
      state = ProgressState(
        eraProgress: cached,
        error: cached.isEmpty ? e.toString() : null,
      );
    }
  }

  EraProgress getEraProgress(String eraId) {
    return state.eraProgress[eraId] ?? EraProgress(eraId: eraId);
  }

  bool isEraUnlocked(String eraId, List<String> visibleEraIds) {
    final index = visibleEraIds.indexOf(eraId);
    if (index <= 0) return true; // First era always unlocked
    final prevEraId = visibleEraIds[index - 1];
    final prevProgress = getEraProgress(prevEraId);
    return prevProgress.isCompleted;
  }

  void markLevelCompleted(String eraId, int level, int stars) {
    StorageService.saveLevelCompleted(eraId, level, stars);
  }
}

final progressProvider =
    StateNotifierProvider<ProgressNotifier, ProgressState>(
        (ref) => ProgressNotifier());
