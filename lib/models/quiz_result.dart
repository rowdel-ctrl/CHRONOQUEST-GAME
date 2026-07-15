class QuestionSnapshot {
  final String questionId;
  final String studentAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final int timeTaken;

  const QuestionSnapshot({
    required this.questionId,
    required this.studentAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.timeTaken,
  });

  factory QuestionSnapshot.fromJson(Map<String, dynamic> json) {
    return QuestionSnapshot(
      questionId: json['questionId'] as String? ?? '',
      studentAnswer: json['studentAnswer'] as String? ?? '',
      correctAnswer: json['correctAnswer'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      timeTaken: json['timeTaken'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'studentAnswer': studentAnswer,
        'correctAnswer': correctAnswer,
        'isCorrect': isCorrect,
        'timeTaken': timeTaken,
      };
}

class QuizResult {
  final String? id;
  final String era;
  final int level;
  final String type; // cold_pre_test | pre_test | post_test
  final int correctAnswersCount;
  final int totalQuestions;
  final int percentage;
  final int timeTakenTotal;
  final List<QuestionSnapshot> questionSnapshots;
  final String? testDate;

  const QuizResult({
    this.id,
    required this.era,
    required this.level,
    required this.type,
    required this.correctAnswersCount,
    required this.totalQuestions,
    required this.percentage,
    required this.timeTakenTotal,
    required this.questionSnapshots,
    this.testDate,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      id: json['_id'] as String? ?? json['id'] as String?,
      era: json['era'] as String? ?? '',
      level: json['level'] as int? ?? 1,
      type: json['type'] as String? ?? 'pre_test',
      correctAnswersCount: json['correctAnswersCount'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      percentage: json['percentage'] as int? ?? 0,
      timeTakenTotal: json['timeTakenTotal'] as int? ?? 0,
      questionSnapshots: (json['questionSnapshots'] as List<dynamic>?)
              ?.map(
                  (s) => QuestionSnapshot.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      testDate: json['testDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'era': era,
        'level': level,
        'type': type,
        'correctAnswersCount': correctAnswersCount,
        'totalQuestions': totalQuestions,
        'percentage': percentage,
        'timeTakenTotal': timeTakenTotal,
        'questionSnapshots':
            questionSnapshots.map((s) => s.toJson()).toList(),
      };
}
