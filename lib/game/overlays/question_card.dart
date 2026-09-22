import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/question.dart';
import 'answer_feedback.dart';
import 'question_layout.dart';
import 'question_widgets.dart';

/// The quiz card: header chips, question text, 2×2 answer grid, and either the
/// power-up buttons or, after a wrong answer, the explanation.
///
/// Purely presentational. QuestionOverlayWidget owns the timer, the tap logic
/// and the power-up state and hands them in, which is what lets the layout be
/// tested at phone sizes without a running game.
class QuestionCard extends StatelessWidget {
  /// Key on the decorated card itself, so tests can measure it.
  static const cardKey = ValueKey('question-card');

  final Question question;
  final int secondsElapsed;
  final bool answered;
  final String? selectedAnswer;

  /// Option labels hidden by the 50/50 power-up.
  final List<String> hiddenOptions;

  /// False during the boss fight, which has no power-ups.
  final bool showPowerups;
  final int fiftyFiftyCount;
  final int shieldCount;
  final bool shieldActive;

  final void Function(String label) onAnswer;
  final VoidCallback onContinue;
  final VoidCallback onFiftyFifty;
  final VoidCallback onShield;

  const QuestionCard({
    super.key,
    required this.question,
    required this.secondsElapsed,
    required this.answered,
    required this.selectedAnswer,
    required this.hiddenOptions,
    required this.showPowerups,
    required this.fiftyFiftyCount,
    required this.shieldCount,
    required this.shieldActive,
    required this.onAnswer,
    required this.onContinue,
    required this.onFiftyFifty,
    required this.onShield,
  });

  bool get _wrongAnswerShowing =>
      answered && selectedAnswer != question.correctAnswer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = QuestionLayout.forHeight(constraints.maxHeight);
        final width = math.min(
          layout.maxWidth,
          constraints.maxWidth - layout.margin.horizontal,
        );
        return Padding(
          padding: layout.margin,
          // The compact layout is sized for a typical question, but a long
          // explanation or a large system font can still make the card taller
          // than the screen. Scaling it down uniformly keeps every option
          // and the Continue button on screen (a scrolling card left C and D
          // below the fold with the timer running). It never scales up, and
          // taps still land: hit-testing follows the transform.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(width: width, child: _card(layout)),
          ),
        );
      },
    );
  }

  Widget _card(QuestionLayout layout) {
    return Container(
      key: cardKey,
      padding: EdgeInsets.all(layout.padding),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          SizedBox(height: layout.headerGap),
          Text(
            question.questionText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: layout.questionFontSize,
              color: AppColors.textPrimary,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: layout.questionGap),
          _options(layout),
          SizedBox(height: layout.optionsGap),
          if (_wrongAnswerShowing)
            ExplanationPanel(
              question: question,
              onContinue: onContinue,
              layout: layout,
            )
          else if (showPowerups)
            _powerups(layout),
        ],
      ),
    );
  }

  /// The TAMA!/MALI! badge sits centred on top of the header row so answering
  /// doesn't shift the card's layout.
  Widget _header() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.accent, width: 2),
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
    );
  }

  Widget _options(QuestionLayout layout) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: layout.optionHeight,
      ),
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
          layout: layout,
          onTap: () => onAnswer(option.label),
        );
      }).toList(),
    );
  }

  Widget _powerups(QuestionLayout layout) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PowerupButton(
          icon: Icons.filter_2,
          label: '50/50',
          count: fiftyFiftyCount,
          onTap: onFiftyFifty,
          enabled: !answered && hiddenOptions.isEmpty,
          layout: layout,
        ),
        const SizedBox(width: 16),
        PowerupButton(
          icon: Icons.shield,
          label: 'Shield',
          count: shieldCount,
          onTap: onShield,
          enabled: !answered && shieldCount > 0 && !shieldActive,
          layout: layout,
        ),
      ],
    );
  }
}
