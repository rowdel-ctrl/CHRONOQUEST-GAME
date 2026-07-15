class EraProgress {
  final String eraId;
  final bool preTestTaken;
  final int preTestScore;
  final int levelsCompleted;
  final Map<int, LevelResult> levelResults;
  final bool bossDefeated;
  final int postTestScore;

  const EraProgress({
    required this.eraId,
    this.preTestTaken = false,
    this.preTestScore = 0,
    this.levelsCompleted = 0,
    this.levelResults = const {},
    this.bossDefeated = false,
    this.postTestScore = 0,
  });

  bool get isCompleted => bossDefeated;
  bool get isInProgress => preTestTaken && !bossDefeated;
  bool get isNotStarted => !preTestTaken;

  bool isLevelUnlocked(int level) {
    if (level == 1) return true;
    if (level == 10) {
      // Boss level — all 9 levels must be done
      return levelsCompleted >= 9;
    }
    return levelsCompleted >= level - 1;
  }

  int getLevelStars(int level) {
    final result = levelResults[level];
    if (result == null) return 0;
    if (result.percentage >= 90) return 3;
    if (result.percentage >= 70) return 2;
    return 1;
  }

  double get averageLevelScore {
    if (levelResults.isEmpty) return 0;
    final scores = levelResults.values
        .where((r) => r.level < 10)
        .map((r) => r.percentage.toDouble());
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  factory EraProgress.fromJson(Map<String, dynamic> json) {
    final Map<int, LevelResult> results = {};
    if (json['levelResults'] != null) {
      final lr = json['levelResults'] as Map<String, dynamic>;
      lr.forEach((key, value) {
        results[int.parse(key)] =
            LevelResult.fromJson(value as Map<String, dynamic>);
      });
    }

    return EraProgress(
      eraId: json['eraId'] as String? ?? '',
      preTestTaken: json['preTestTaken'] as bool? ?? false,
      preTestScore: json['preTestScore'] as int? ?? 0,
      levelsCompleted: json['levelsCompleted'] as int? ?? 0,
      levelResults: results,
      bossDefeated: json['bossDefeated'] as bool? ?? false,
      postTestScore: json['postTestScore'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'eraId': eraId,
        'preTestTaken': preTestTaken,
        'preTestScore': preTestScore,
        'levelsCompleted': levelsCompleted,
        'levelResults': levelResults
            .map((k, v) => MapEntry(k.toString(), v.toJson())),
        'bossDefeated': bossDefeated,
        'postTestScore': postTestScore,
      };
}

class LevelResult {
  final int level;
  final int percentage;
  final int stars;
  final int score;

  const LevelResult({
    required this.level,
    required this.percentage,
    required this.stars,
    this.score = 0,
  });

  factory LevelResult.fromJson(Map<String, dynamic> json) {
    final pct = json['percentage'] as int? ?? 0;
    return LevelResult(
      level: json['level'] as int? ?? 1,
      percentage: pct,
      stars: pct >= 90
          ? 3
          : pct >= 70
              ? 2
              : 1,
      score: json['score'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'percentage': percentage,
        'stars': stars,
        'score': score,
      };
}
