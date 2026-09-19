import 'dart:math';

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

  /// Returns a new [Question] with the options in random order, relabelled
  /// A, B, C... in that order, and [correctAnswer] pointing at wherever the
  /// original correct option landed. Leaves this instance untouched so the
  /// cached copy in QuestionBank stays in source order, and the copy starts
  /// with a fresh [elapsedSeconds].
  ///
  /// The correct option is tracked by position, not by text, so options with
  /// identical text can't cause the wrong label to be marked correct.
  Question withShuffledOptions([Random? random]) {
    if (options.isEmpty) return _copyWith(options, correctAnswer);

    final correctIndex = options.indexWhere((o) => o.label == correctAnswer);
    final order = List<int>.generate(options.length, (i) => i)
      ..shuffle(random);

    final shuffled = <QuestionOption>[];
    var newCorrect = correctAnswer;
    for (var i = 0; i < order.length; i++) {
      final label = String.fromCharCode(65 + i); // A, B, C...
      shuffled.add(QuestionOption(label: label, text: options[order[i]].text));
      if (order[i] == correctIndex) newCorrect = label;
    }
    return _copyWith(shuffled, newCorrect);
  }

  Question _copyWith(List<QuestionOption> options, String correctAnswer) {
    return Question(
      id: id,
      era: era,
      subTopic: subTopic,
      gradeLevel: gradeLevel,
      level: level,
      difficulty: difficulty,
      questionType: questionType,
      questionText: questionText,
      options: options,
      correctAnswer: correctAnswer,
      explanation: explanation,
    );
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
