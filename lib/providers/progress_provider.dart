import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/era_progress.dart';
import '../models/quiz_result.dart';
import '../services/api_service.dart';
import '../services/guest_mode.dart';
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
  ProgressNotifier({
    Future<Map<String, EraProgress>> Function()? fetchProgress,
    Future<List<QuizResult>> Function()? fetchResults,
  })  : _fetchProgress = fetchProgress ?? ApiService().getEraProgress,
        _fetchResults = fetchResults ?? ApiService().getResults,
        super(const ProgressState());

  final Future<Map<String, EraProgress>> Function() _fetchProgress;
  final Future<List<QuizResult>> Function() _fetchResults;

  Future<void> loadProgress() async {
    state = state.copyWith(isLoading: true, error: null);
    if (GuestMode.active) {
      // A guest has no server record: progress is what this phone saved.
      state = ProgressState(eraProgress: {
        for (final era in allEras) era.id: _localProgress(era),
      });
      return;
    }
    try {
      final progress = await _fetchProgress();
      state = ProgressState(eraProgress: progress);
      // Which levels are done (and their stars) is kept on the phone, and a logout wipes it. A
      // student who logged out and in again (or came to a new phone) found the level map empty
      // although the server had the results. If the server counts more levels than this phone
      // knows, the level map is rebuilt from the results.
      if (await _restoreLevelsIfBehind(progress)) {
        state = ProgressState(eraProgress: progress); // a new state, so the level map redraws
      }
    } catch (e) {
      // Try loading from cache
      final Map<String, EraProgress> cached = {};
      for (final eraId in allEras.map((e) => e.id)) {
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

  /// The stars for a score, as the game screen gives them when a level ends.
  static int starsFor(int percentage) => percentage >= 90 ? 3 : (percentage >= 70 ? 2 : 1);

  /// Fills in the levels this phone has forgotten from the results the server kept. Never
  /// removes a level or lowers its stars. The server scores every attempt, so a restored star
  /// count can be lower than the one the student first earned. True when it changed something.
  Future<bool> _restoreLevelsIfBehind(Map<String, EraProgress> server) async {
    try {
      var behind = false;
      for (final era in allEras) {
        final onServer = server[era.id]?.levelsCompleted ?? 0;
        if (onServer > StorageService.getCompletedLevels(era.id).length) {
          behind = true;
          break;
        }
      }
      if (!behind) return false;
      final results = await _fetchResults();
      final best = <String, Map<int, int>>{};
      for (final r in results) {
        if (r.level < 1 || (r.type != 'pre_test' && r.type != 'post_test')) continue;
        final stars = starsFor(r.percentage);
        final forEra = best.putIfAbsent(r.era, () => <int, int>{});
        if (stars > (forEra[r.level] ?? 0)) forEra[r.level] = stars;
      }
      var changed = false;
      for (final era in allEras) {
        final have = StorageService.getCompletedLevels(era.id);
        for (final entry in (best[era.id] ?? const <int, int>{}).entries) {
          if (entry.key > era.levels.length) continue;
          if (entry.value > (have[entry.key] ?? 0)) {
            await StorageService.saveLevelCompleted(era.id, entry.key, entry.value);
            changed = true;
          }
        }
      }
      return changed;
    } catch (_) {
      return false; // offline, or no local storage (a test): the map stays as it was
    }
  }

  EraProgress _localProgress(EraData era) {
    final done = StorageService.getCompletedLevels(era.id);
    return EraProgress(
      eraId: era.id,
      levelsCompleted: done.length,
      // The last level of an era is its boss.
      bossDefeated: done.containsKey(era.levels.length),
    );
  }

  EraProgress getEraProgress(String eraId) {
    return state.eraProgress[eraId] ?? EraProgress(eraId: eraId);
  }

  bool isEraUnlocked(String eraId, List<String> visibleEraIds) {
    final index = visibleEraIds.indexOf(eraId);
    if (index <= 0) return true; // First era always unlocked
    final prevEraId = visibleEraIds[index - 1];
    final prevProgress = getEraProgress(prevEraId);
    // The server's answer can be behind (a boss won offline, a result still queued): the boss
    // level saved on this phone counts too, so a book that just came unchained does not close
    // again.
    return prevProgress.isCompleted || _bossDownOnThisPhone(prevEraId);
  }

  bool _bossDownOnThisPhone(String eraId) {
    try {
      final era = allEras.where((e) => e.id == eraId);
      if (era.isEmpty) return false;
      return StorageService.getCompletedLevels(eraId).containsKey(era.first.levels.length);
    } catch (_) {
      return false; // no local storage (a test)
    }
  }

  void markLevelCompleted(String eraId, int level, int stars) {
    StorageService.saveLevelCompleted(eraId, level, stars);
  }
}

final progressProvider = StateNotifierProvider<ProgressNotifier, ProgressState>(
    (ref) => ProgressNotifier());
