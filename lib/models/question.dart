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
  late final List<QuestionOption> options;
  late final String correctAnswer;
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
    required List<QuestionOption> options,
    required String correctAnswer,
    this.explanation = '',
    this.elapsedSeconds = 0,
  }) {
    if (options.isEmpty) {
      this.options = [];
      this.correctAnswer = correctAnswer;
      return;
    }

    // Find the text of the correct answer before shuffling
    final correctOpt = options.firstWhere(
      (o) => o.label == correctAnswer,
      orElse: () => options.first,
    );
    final correctText = correctOpt.text;

    // Shuffle the options
    final shuffled = List<QuestionOption>.from(options)..shuffle();
    final labels = ['A', 'B', 'C', 'D', 'E', 'F'];
    
    final newOptions = <QuestionOption>[];
    String newCorrect = correctAnswer;

    // Reassign labels A, B, C, D...
    for (int i = 0; i < shuffled.length; i++) {
      final label = i < labels.length ? labels[i] : String.fromCharCode(65 + i);
      newOptions.add(QuestionOption(label: label, text: shuffled[i].text));
      if (shuffled[i].text == correctText) {
        newCorrect = label;
      }
    }
    
    this.options = newOptions;
    this.correctAnswer = newCorrect;
  }

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
