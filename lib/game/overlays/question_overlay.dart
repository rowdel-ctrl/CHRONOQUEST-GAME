import 'dart:async' as async;
import 'package:flutter/material.dart';
import '../boss_countdown.dart';
import '../chrono_game.dart';
import 'question_card.dart';

/// Question overlay — pure Flutter widget displayed over Flame canvas.
/// Owns the timer, tap handling and power-up state; the card itself (2×2
/// answer grid, timer chip, powerup buttons) is QuestionCard.
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
  async.Timer? _clock;

  /// The boss question's 15 seconds; null on every other question.
  BossCountdown? _countdown;
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

    if (widget.game.bossPhase) {
      _countdown = BossCountdown();
      const step = Duration(milliseconds: 100);
      _clock = async.Timer.periodic(step, (_) {
        final countdown = _countdown;
        if (!mounted || answered || countdown == null) return;
        setState(() => countdown.tick(step.inMilliseconds / 1000));
        if (countdown.expired) _timeUp();
      });
    }

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
    _clock?.cancel();
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
      // The cheer follows the ding, so a right answer sounds like a reward.
      Future.delayed(const Duration(milliseconds: 250), () {
        widget.game.audioService.playPraise();
      });
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

  /// The boss countdown ran out: the same as a wrong answer, with the right
  /// one shown. Answered with '' so nothing is chosen.
  void _timeUp() {
    setState(() {
      answered = true;
      selectedAnswer = '';
    });
    widget.game.audioService.playWrong();
  }

  void _useTimeFreeze() {
    final countdown = _countdown;
    if (countdown == null || countdown.frozen || answered) return;
    if (widget.game.playerPowerUps.timeFreeze <= 0) return;
    widget.game.playerPowerUps.timeFreeze--;
    widget.game.audioService.playPowerup();
    setState(countdown.freeze);
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

  void _useShield() {
    if (widget.game.playerPowerUps.shield > 0) {
      widget.game.shieldActive = true;
      widget.game.playerPowerUps.shield--;
      widget.game.audioService.playPowerup();
      setState(() {});
    }
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
            child: QuestionCard(
              question: question,
              secondsElapsed: secondsElapsed,
              answered: answered,
              selectedAnswer: selectedAnswer,
              hiddenOptions: hiddenOptions,
              showPowerups: !widget.game.bossPhase,
              countdownFraction: _countdown?.fraction,
              countdownSeconds: _countdown?.secondsLeft.ceil() ?? 0,
              countdownFrozen: _countdown?.frozen ?? false,
              timeFreezeCount: widget.game.playerPowerUps.timeFreeze,
              onTimeFreeze: _useTimeFreeze,
              fiftyFiftyCount: widget.game.playerPowerUps.fiftyFifty,
              shieldCount: widget.game.playerPowerUps.shield,
              shieldActive: widget.game.shieldActive,
              onAnswer: handleTap,
              onContinue: _continueAfterWrongAnswer,
              onFiftyFifty: _useFiftyFifty,
              onShield: _useShield,
            ),
          ),
        ),
      ),
    );
  }
}
