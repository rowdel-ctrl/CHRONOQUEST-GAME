import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/question.dart';
import 'answer_feedback.dart';
import 'question_layout.dart';
import 'question_widgets.dart';

/// The question card of the boss fight: compact, at the top centre of the screen, so the hero,
/// the boss and the attack flying between them stay in view. The bar is the attack's flight:
/// when it is empty the attack has arrived.
///
/// Purely presentational. QuestionOverlayWidget feeds it from the boss and takes the taps.
/// Only the card takes touches; the rest of the screen stays the game's.
class BossQuestionCard extends StatelessWidget {
  static const cardKey = ValueKey('boss-question-card');
  static const freezeKey = ValueKey('boss-freeze');
  static const fiftyKey = ValueKey('boss-fifty');

  /// Space kept free above the card for the boss's name and health bar.
  static const double topInset = 58;

  /// The card never reaches lower than this share of the screen: below it stand the boss's head
  /// and the attack.
  static const double lowestShare = 0.62;

  final Question question;

  /// "Phase 2 · 12 s".
  final String phaseTag;

  /// The share of the time left (1 to 0), the whole seconds left, and whether Time Freeze holds it.
  final double fraction;
  final int secondsLeft;
  final bool frozen;

  final bool answered;
  final String? selectedAnswer;

  final int timeFreezeCount;
  final VoidCallback? onTimeFreeze;

  /// Whole seconds of Time Freeze left while it holds the clock, and whether it was already used
  /// on this question (one use each).
  final int freezeSecondsLeft;
  final bool freezeUsed;

  /// 50/50: how many are left, what to do, and the option labels it has hidden.
  final int fiftyFiftyCount;
  final VoidCallback? onFiftyFifty;
  final List<String> hiddenOptions;

  final void Function(String label) onAnswer;

  const BossQuestionCard({
    super.key,
    required this.question,
    required this.phaseTag,
    required this.fraction,
    required this.secondsLeft,
    required this.frozen,
    required this.answered,
    required this.selectedAnswer,
    required this.timeFreezeCount,
    required this.onAnswer,
    this.onTimeFreeze,
    this.freezeSecondsLeft = 0,
    this.freezeUsed = false,
    this.fiftyFiftyCount = 0,
    this.onFiftyFifty,
    this.hiddenOptions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenH = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final screenW = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        const layout = QuestionLayout.bossTop;
        final width =
            math.max(260.0, math.min(layout.maxWidth, screenW * 0.56));
        final maxHeight = math.max(80.0, screenH * lowestShare - topInset);
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: topInset),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: screenW, maxHeight: maxHeight),
              // A long question or a large system font scales the card down instead of
              // letting it grow over the boss. Taps still land: hit-testing follows it.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(width: width, child: _card(layout)),
              ),
            ),
          ),
        );
      },
    );
  }

  bool get _correct => selectedAnswer == question.correctAnswer;

  Widget _card(QuestionLayout layout) {
    return Container(
      key: cardKey,
      padding: EdgeInsets.all(layout.padding),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.97),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        boxShadow: const [
          BoxShadow(
              color: AppColors.primaryDark,
              offset: Offset(4, 4),
              blurRadius: 0),
        ],
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.primaryDark, width: 2.5),
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
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: layout.questionGap),
          _options(layout),
        ],
      ),
    );
  }

  /// Phase and time on the left and right; after answering, the TAMA!/MALI! badge takes the
  /// middle, so the header does not change height.
  Widget _header() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.accent, width: 1.5),
              ),
              child: Text(
                phaseTag,
                style: GoogleFonts.poppins(
                    fontSize: 9, height: 1.3, color: Colors.white),
              ),
            ),
            const Spacer(),
            CountdownBar(
                fraction: fraction, secondsLeft: secondsLeft, frozen: frozen),
            const SizedBox(width: 8),
            _freezeButton(),
            const SizedBox(width: 6),
            _fiftyButton(),
          ],
        ),
        if (answered) AnswerFeedbackBadge(correct: _correct),
      ],
    );
  }

  Widget _freezeButton() {
    final usable = !answered && !frozen && !freezeUsed && timeFreezeCount > 0;
    return GestureDetector(
      key: freezeKey,
      onTap: usable ? onTimeFreeze : null,
      child: Opacity(
        opacity: usable ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: usable ? AppColors.accent : AppColors.border,
                width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.ac_unit, size: 13, color: AppColors.info),
              const SizedBox(width: 3),
              Text(
                frozen ? '${freezeSecondsLeft}s' : '×$timeFreezeCount',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  height: 1.3,
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

  Widget _fiftyButton() {
    final usable = !answered &&
        fiftyFiftyCount > 0 &&
        hiddenOptions.isEmpty &&
        question.options.length >= 4;
    return GestureDetector(
      key: fiftyKey,
      onTap: usable ? onFiftyFifty : null,
      child: Opacity(
        opacity: usable ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: usable ? AppColors.accent : AppColors.border, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_2, size: 13, color: AppColors.info),
              const SizedBox(width: 3),
              Text(
                '×$fiftyFiftyCount',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  height: 1.3,
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

  Widget _options(QuestionLayout layout) {
    Widget cell(QuestionOption option) {
      if (hiddenOptions.contains(option.label)) {
        // Hidden by 50/50: the place stays, so the card does not change shape.
        return Opacity(
          opacity: 0,
          child: IgnorePointer(
            child: AnswerButton(
              option: option,
              state: AnswerState.neutral,
              selected: false,
              layout: layout,
              onTap: () {},
            ),
          ),
        );
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
    }

    final options = question.options;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 6),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: layout.optionHeight),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cell(options[i])),
                  const SizedBox(width: 8),
                  Expanded(
                    child: i + 1 < options.length
                        ? cell(options[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
