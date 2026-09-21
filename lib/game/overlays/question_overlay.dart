import 'dart:async' as async;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../chrono_game.dart';
import 'answer_feedback.dart';
import 'question_widgets.dart';

/// Question overlay — pure Flutter widget displayed over Flame canvas.
/// Shows quiz question with 2×2 answer grid, timer, and powerup buttons.
class QuestionOverlayWidget extends StatefulWidget {
  final ChronoGame game;
  final Function(String answer) onAnswer;
  const QuestionOverlayWidget({
    super.key,
    required this.game,
    required this.onAnswer,
  });

  @override
  State<QuestionOverlayWidget> createState() => _QuestionOverlayWidgetState();
}

class _QuestionOverlayWidgetState extends State<QuestionOverlayWidget>
    with SingleTickerProviderStateMixin {
  bool answered = false;
  String? selectedAnswer;
  int secondsElapsed = 0;
  late async.Timer timer;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Track which options are hidden by 50/50
  List<String> hiddenOptions = [];

  @override
  void initState() {
    super.initState();
    widget.game.currentQuestion?.elapsedSeconds = 0;
    timer = async.Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !answered) {
        setState(() {
          secondsElapsed++;
          widget.game.currentQuestion?.elapsedSeconds = secondsElapsed;
        });
      }
    });

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    timer.cancel();
    _slideController.dispose();
    super.dispose();
  }

  void handleTap(String answer) {
    if (answered) return;
    setState(() {
      answered = true;
      selectedAnswer = answer;
    });

    final isCorrect = answer == widget.game.currentQuestion!.correctAnswer;
    if (isCorrect) {
      widget.game.audioService.playCorrect();
      // Correct answers keep the game moving at a brisk pace.
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) widget.onAnswer(answer);
      });
    } else {
      widget.game.audioService.playWrong();
      // Wrong answers show the explanation inline (see build()) and wait
      // for the player to tap "Susunod" — don't force-pace text they
      // can't control by auto-advancing.
    }
  }

  void _continueAfterWrongAnswer() {
    final answer = selectedAnswer;
    if (answer == null) return;
    widget.onAnswer(answer);
  }

  void _useFiftyFifty() {
    final question = widget.game.currentQuestion;
    if (question == null) return;
    if (widget.game.playerPowerUps.fiftyFifty <= 0) return;

    widget.game.playerPowerUps.fiftyFifty--;
    widget.game.audioService.playPowerup();

    // Hide 2 wrong options
    final wrongOptions = question.options
        .where((o) => o.label != question.correctAnswer)
        .toList();
    wrongOptions.shuffle();
    setState(() {
      hiddenOptions = wrongOptions.take(2).map((o) => o.label).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.game.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return GestureDetector(
      // Block tap-to-jump while question is showing
      onTap: () {},
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.all(Radius.circular(6)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark,
                    offset: Offset(6, 6),
                    blurRadius: 0,
                  ),
                ],
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.primaryDark, width: 3),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header row. The TAMA!/MALI! badge sits centred on top
                    // of it so answering doesn't shift the card's layout.
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: AppColors.accent, width: 2),
                              ),
                              child: Text(
                                'HAMON',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  height: 1.4,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            TimerChip(seconds: secondsElapsed),
                          ],
                        ),
                        if (answered)
                          AnswerFeedbackBadge(
                            correct: selectedAnswer == question.correctAnswer,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Question text
                    Text(
                      question.questionText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Answer buttons — 2×2 grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.8,
                      children: question.options.map((option) {
                        if (hiddenOptions.contains(option.label)) {
                          return const SizedBox.shrink();
                        }
                        var state = AnswerState.neutral;
                        if (answered) {
                          if (option.label == question.correctAnswer) {
                            state = AnswerState.correct;
                          } else if (option.label == selectedAnswer) {
                            state = AnswerState.wrong;
                          }
                        }
                        return AnswerButton(
                          option: option,
                          state: state,
                          selected: answered && option.label == selectedAnswer,
                          onTap: () => handleTap(option.label),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    if (answered && selectedAnswer != question.correctAnswer)
                      ExplanationPanel(
                        question: question,
                        onContinue: _continueAfterWrongAnswer,
                      )
                    else if (!widget.game.bossPhase)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PowerupButton(
                            icon: Icons.filter_2,
                            label: '50/50',
                            count: widget.game.playerPowerUps.fiftyFifty,
                            onTap: _useFiftyFifty,
                            enabled: !answered && hiddenOptions.isEmpty,
                          ),
                          const SizedBox(width: 16),
                          PowerupButton(
                            icon: Icons.shield,
                            label: 'Shield',
                            count: widget.game.playerPowerUps.shield,
                            onTap: () {
                              if (widget.game.playerPowerUps.shield > 0) {
                                widget.game.shieldActive = true;
                                widget.game.playerPowerUps.shield--;
                                widget.game.audioService.playPowerup();
                                setState(() {});
                              }
                            },
                            enabled: !answered &&
                                widget.game.playerPowerUps.shield > 0 &&
                                !widget.game.shieldActive,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
