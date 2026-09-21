import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';

/// How an answer button should look once the player has answered.
enum AnswerState { neutral, correct, wrong }

/// Pops a child in from nothing with a slight overshoot, once, when first
/// built. Used so right/wrong icons read as a reaction to the tap instead of
/// just appearing.
class _PopIn extends StatelessWidget {
  final Widget child;
  const _PopIn({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: child,
    );
  }
}

/// Check / X icon shown on an answer button after the player answers.
class AnswerMark extends StatelessWidget {
  final AnswerState state;
  const AnswerMark({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state == AnswerState.neutral) return const SizedBox.shrink();
    final correct = state == AnswerState.correct;
    return _PopIn(
      child: Icon(
        correct ? Icons.check_circle : Icons.cancel,
        size: 18,
        color: correct ? AppColors.success : AppColors.danger,
      ),
    );
  }
}

/// "TAMA!" / "MALI!" badge shown in the question header after answering,
/// so the result is clear at a glance (correct answers close the card
/// after 800 ms, too quickly to rely on button colours alone).
class AnswerFeedbackBadge extends StatelessWidget {
  final bool correct;
  const AnswerFeedbackBadge({super.key, required this.correct});

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.success : AppColors.danger;
    return Semantics(
      liveRegion: true,
      label: correct ? 'Tama ang sagot' : 'Mali ang sagot',
      child: _PopIn(
        child: Container(
          // Kept no taller than the HAMON/timer chips (~28 px) so the
          // header row doesn't grow and nudge the card when it appears.
          padding: const EdgeInsets.fromLTRB(4, 2, 12, 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryDark, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                correct ? Icons.check_circle : Icons.cancel,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                correct ? 'TAMA!' : 'MALI!',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
