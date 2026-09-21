import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/question.dart';
import '../../widgets/game_ui.dart';
import 'answer_feedback.dart';

/// Seconds spent on the current question; turns red after 15 s.
class TimerChip extends StatelessWidget {
  final int seconds;
  const TimerChip({super.key, required this.seconds});

  @override
  Widget build(BuildContext context) {
    final late = seconds > 15;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: late
            ? AppColors.danger.withValues(alpha: 0.2)
            : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: late ? AppColors.danger : AppColors.primaryDark,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 14,
            color: late ? AppColors.danger : AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            '${seconds}s',
            style: GoogleFonts.poppins(
              fontSize: 10,
              height: 1.4,
              color: late ? AppColors.danger : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// One option in the question overlay's 2×2 answer grid.
class AnswerButton extends StatelessWidget {
  final QuestionOption option;
  final AnswerState state;
  final bool selected;
  final VoidCallback onTap;

  const AnswerButton({
    super.key,
    required this.option,
    required this.state,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color buttonColor = AppColors.surface;
    Color borderColor = AppColors.border;
    if (state == AnswerState.correct) {
      buttonColor = AppColors.success.withValues(alpha: 0.15);
      borderColor = AppColors.success;
    } else if (state == AnswerState.wrong) {
      buttonColor = AppColors.danger.withValues(alpha: 0.15);
      borderColor = AppColors.danger;
    }

    return Semantics(
      button: true,
      label: 'Sagot ${option.label}: ${option.text}',
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: buttonColor,
            border: Border.all(color: borderColor, width: 2.5),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          // The mark sits in the corner rather than beside the text, so
          // options keep their full width and don't wrap or truncate sooner.
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Text(
                  '${option.label}) ${option.text}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: state == AnswerState.correct
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Positioned(
                top: 3,
                right: -4,
                child: AnswerMark(state: state),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown inline after a wrong answer so the player sees *why* before the
/// game moves on. They tap Continue when ready, rather than it
/// auto-advancing.
class ExplanationPanel extends StatelessWidget {
  final Question question;
  final VoidCallback onContinue;

  const ExplanationPanel({
    super.key,
    required this.question,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: AppColors.accent),
              SizedBox(width: 6),
              Text(
                'Paliwanag',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            question.explanation.isNotEmpty
                ? question.explanation
                : 'Ang tamang sagot ay ${question.correctAnswer}.',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          GameButton(
            label: 'SUSUNOD',
            fontSize: 11,
            width: double.infinity,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class PowerupButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;
  final bool enabled;

  const PowerupButton({
    super.key,
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
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
