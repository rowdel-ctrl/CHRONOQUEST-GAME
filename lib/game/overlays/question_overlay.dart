import 'dart:async' as async;
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../chrono_game.dart';

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
      if (mounted) {
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

    final isCorrect =
        answer == widget.game.currentQuestion!.correctAnswer;
    if (isCorrect) {
      widget.game.audioService.playCorrect();
    } else {
      widget.game.audioService.playWrong();
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      widget.onAnswer(answer);
    });
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
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'HAMON NG KAAWAY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: secondsElapsed > 15
                                ? AppColors.danger.withValues(alpha: 0.2)
                                : AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: secondsElapsed > 15
                                    ? AppColors.danger
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${secondsElapsed}s',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: secondsElapsed > 15
                                      ? AppColors.danger
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
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

                        Color buttonColor = AppColors.surface;
                        Color borderColor = AppColors.border;

                        if (answered) {
                          if (option.label == question.correctAnswer) {
                            buttonColor =
                                AppColors.success.withValues(alpha: 0.15);
                            borderColor = AppColors.success;
                          } else if (option.label == selectedAnswer) {
                            buttonColor =
                                AppColors.danger.withValues(alpha: 0.15);
                            borderColor = AppColors.danger;
                          }
                        }

                        return Semantics(
                          button: true,
                          label: 'Sagot ${option.label}: ${option.text}',
                          selected: answered && option.label == selectedAnswer,
                          child: GestureDetector(
                          onTap: () => handleTap(option.label),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: buttonColor,
                              border:
                                  Border.all(color: borderColor, width: 1.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${option.label}) ${option.text}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                fontWeight: answered &&
                                        option.label ==
                                            question.correctAnswer
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Powerup row (not shown during boss fight or pre-test)
                    // Note: "Freeze" is intentionally omitted here — the
                    // timeFreeze power-up has no working use during
                    // questions anywhere in the game, so showing it as a
                    // permanently greyed-out button only confused players.
                    if (!widget.game.bossPhase)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PowerupButton(
                            icon: Icons.filter_2,
                            label: '50/50',
                            count: widget.game.playerPowerUps.fiftyFifty,
                            onTap: _useFiftyFifty,
                            enabled: !answered &&
                                hiddenOptions.isEmpty,
                          ),
                          const SizedBox(width: 16),
                          _PowerupButton(
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

class _PowerupButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;
  final bool enabled;

  const _PowerupButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final isUsable = enabled && count > 0;
    return GestureDetector(
      onTap: isUsable ? onTap : null,
      child: Opacity(
        opacity: isUsable ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isUsable ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.accent),
              const SizedBox(width: 4),
              Text(
                '$label ×$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}