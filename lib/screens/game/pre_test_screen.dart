import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/question.dart';
import '../../models/quiz_result.dart';
import '../../services/api_service.dart';
import '../../data/question_bank.dart';

class PreTestScreen extends StatefulWidget {
  final String eraId;
  const PreTestScreen({super.key, required this.eraId});

  @override
  State<PreTestScreen> createState() => _PreTestScreenState();
}

class _PreTestScreenState extends State<PreTestScreen> {
  List<Question> questions = [];
  int currentIndex = 0;
  bool isLoading = true;
  bool isComplete = false;
  bool hasStarted = false;
  String? error;
  List<QuestionSnapshot> answers = [];
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      // Use local question bank for level 1 (pre-test)
      final qs = QuestionBank.getQuestions(widget.eraId, 1);
      setState(() {
        questions = qs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  void _startTest() {
    setState(() => hasStarted = true);
    _stopwatch.start();
  }

  void _answerQuestion(String answer) {
    final q = questions[currentIndex];
    answers.add(QuestionSnapshot(
      questionId: q.id,
      studentAnswer: answer,
      correctAnswer: q.correctAnswer,
      isCorrect: answer == q.correctAnswer,
      timeTaken: _stopwatch.elapsed.inSeconds,
    ));

    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
    } else {
      _completeTest();
    }
  }

  Future<void> _completeTest() async {
    _stopwatch.stop();
    setState(() => isComplete = true);

    final correct = answers.where((a) => a.isCorrect).length;
    final percentage =
        answers.isNotEmpty ? (correct / answers.length * 100).round() : 0;

    try {
      await ApiService().submitResult(QuizResult(
        era: widget.eraId,
        level: 1,
        type: 'cold_pre_test',
        correctAnswersCount: correct,
        totalQuestions: answers.length,
        percentage: percentage,
        timeTakenTotal: _stopwatch.elapsed.inSeconds,
        questionSnapshots: answers,
      ));
    } catch (_) {}

    // Auto-navigate after 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        context.go('/background/${widget.eraId}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eraData = getEraById(widget.eraId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            margin: const EdgeInsets.all(20),
            child: isLoading
                ? const CircularProgressIndicator(color: AppColors.primary)
                : error != null
                    ? _buildError()
                    : !hasStarted
                        ? _buildIntro(eraData)
                        : isComplete
                            ? _buildComplete()
                            : _buildQuestion(),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro(EraData era) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              era.name,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bago tayo magsimula...',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sagutin ang 10 tanong tungkol sa paksang ito. '
              'Hindi ito may tama o mali — gusto lang naming malaman '
              'kung ano na ang alam mo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: const Text(
                'MAGSIMULA',
                style: TextStyle(letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final q = questions[currentIndex];
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress
            Row(
              children: [
                Text(
                  'Tanong ${currentIndex + 1} ng ${questions.length}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (currentIndex + 1) / questions.length,
              backgroundColor: AppColors.surfaceAlt,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),

            // Question text
            Text(
              q.questionText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Answer options
            ...q.options.map((option) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _answerQuestion(option.label),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        '${option.label}) ${option.text}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildComplete() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 48),
            const SizedBox(height: 16),
            Text(
              'Magaling!',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Basahin natin ang kasaysayan.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: 12),
            const Text('Walang tanong na makita'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Bumalik'),
            ),
          ],
        ),
      ),
    );
  }
}
