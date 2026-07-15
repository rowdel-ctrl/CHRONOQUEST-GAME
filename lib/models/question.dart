class QuestionOption {
  final String label;
  final String text;

  const QuestionOption({required this.label, required this.text});

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      label: json['label'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'text': text};
}

class Question {
  final String id;
  final String era;
  final String subTopic;
  final String gradeLevel;
  final int level;
  final String difficulty;
  final String questionType;
  final String questionText;
  final List<QuestionOption> options;
  final String correctAnswer;
  final String explanation;
  int elapsedSeconds;

  Question({
    required this.id,
    required this.era,
    this.subTopic = '',
    this.gradeLevel = '',
    this.level = 1,
    this.difficulty = 'medium',
    this.questionType = 'multiple_choice',
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.explanation = '',
    this.elapsedSeconds = 0,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      era: json['era'] as String? ?? '',
      subTopic: json['subTopic'] as String? ?? '',
      gradeLevel: json['gradeLevel'] as String? ?? '',
      level: json['level'] as int? ?? 1,
      difficulty: json['difficulty'] as String? ?? 'medium',
      questionType: json['questionType'] as String? ?? 'multiple_choice',
      questionText: json['questionText'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((o) =>
                  QuestionOption.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
      correctAnswer: json['correctAnswer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'era': era,
        'subTopic': subTopic,
        'gradeLevel': gradeLevel,
        'level': level,
        'difficulty': difficulty,
        'questionType': questionType,
        'questionText': questionText,
        'options': options.map((o) => o.toJson()).toList(),
        'correctAnswer': correctAnswer,
        'explanation': explanation,
      };
}
