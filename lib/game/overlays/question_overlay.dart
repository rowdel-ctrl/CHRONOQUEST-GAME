import 'dart:async' as async;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/pixel_ui.dart';
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

  // Retry handling: game.handleAnswer() no longer closes+reopens this
  // overlay for a first wrong answer — it keeps this same widget mounted
  // and bumps game.retryTick instead. We watch for that change and reset
  // our own state, showing a short "try again" badge so it reads as a
  // second chance rather than an unexplained reset.
  late int _lastRetryTick;
  bool _showRetryBadge = false;

  @override
  void initState() {
    super.initState();
    _lastRetryTick = widget.game.retryTick;
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

    widget.game.addListener(_onGameChanged);
  }

  void _onGameChanged() {
    if (!mounted) return;
    if (widget.game.retryTick != _lastRetryTick) {
      _lastRetryTick = widget.game.retryTick;
      setState(() {
        answered = false;
        selectedAnswer = null;
        hiddenOptions = [];
        secondsElapsed = 0;
        widget.game.currentQuestion?.elapsedSeconds = 0;
        _showRetryBadge = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showRetryBadge = false);
      });
    }
  }

  @override
  void dispose() {
    timer.cancel();
    _slideController.dispose();
    widget.game.removeListener(_onGameChanged);
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
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(4),
                            border:
                                Border.all(color: AppColors.accent, width: 2),
                          ),
                          child: Text(
                            'HAMON',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 9,
                              height: 1.4,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: secondsElapsed > 15
                                ? AppColors.danger.withValues(alpha: 0.2)
                                : AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: secondsElapsed > 15
                                  ? AppColors.danger
                                  : AppColors.primaryDark,
                              width: 2,
                            ),
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
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 10,
                                  height: 1.4,
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

                    // Retry badge — shown briefly when the overlay resets
                    // itself for a second attempt (see _onGameChanged).
                    // Styling deliberately mirrors the HAMON chip and the
                    // timer's overtime state above (same padding/radius/
                    // border-width/font-size formula) instead of inventing
                    // a new pill style for this one banner.
                    if (_showRetryBadge)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(color: AppColors.warning, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh_rounded,
                                size: 14, color: AppColors.warning),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'SUBUKAN MULI! HULING PAGKAKATAON',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 9,
                                  height: 1.4,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

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
                                    Border.all(color: borderColor, width: 2.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '${option.label}) ${option.text}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.pixelifySans(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  fontWeight: answered &&
                                          option.label == question.correctAnswer
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

                    // Explanation — shown inline after a wrong answer so the
                    // player sees *why* before the game moves on. They tap
                    // Continue when ready, rather than it auto-advancing.
                    if (answered && selectedAnswer != question.correctAnswer)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lightbulb_outline,
                                    size: 18, color: AppColors.accent),
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
                            PixelButton(
                              label: 'SUSUNOD',
                              fontSize: 11,
                              width: double.infinity,
                              onPressed: _continueAfterWrongAnswer,
                            ),
                          ],
                        ),
                      )
                    else if (!widget.game.bossPhase)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PowerupButton(
                            icon: Icons.filter_2,
                            label: '50/50',
                            count: widget.game.playerPowerUps.fiftyFifty,
                            onTap: _useFiftyFifty,
                            enabled: !answered && hiddenOptions.isEmpty,
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
