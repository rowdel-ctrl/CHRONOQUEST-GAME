import 'dart:async' as async;
import 'package:flutter/material.dart';
import '../../data/question_bank.dart';
import '../boss_countdown.dart';
import '../chrono_game.dart';
import 'boss_question_card.dart';
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

  /// The clock on this question: the boss's 15 seconds, or the teacher's time
  /// for the level. Null on a question with no timer.
  BossCountdown? _countdown;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Track which options are hidden by 50/50
  List<String> hiddenOptions = [];

  /// A boss question: the boss owns the clock (its attack's flight), the card only shows it
  /// and passes the taps on. The game keeps running underneath, so the card is small and
  /// leaves the rest of the screen alone (see BossQuestionCard).
  bool get _bossMode => widget.game.bossPhase && widget.game.boss != null;

  @override
  void initState() {
    super.initState();
    if (_bossMode) {
      // Only redraws the bar and the seconds ten times a second.
      timer = async.Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted) setState(() {});
      });
      _initSlide();
      return;
    }
    widget.game.currentQuestion?.elapsedSeconds = 0;
    timer = async.Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !answered) {
        setState(() {
          secondsElapsed++;
          widget.game.currentQuestion?.elapsedSeconds = secondsElapsed;
        });
      }
    });

    // Any question here is timed only when the student's teacher set a timer for this
    // level (the boss's question has its own clock, above).
    final seconds =
        QuestionBank.timerSecondsFor(widget.game.currentEra, widget.game.currentLevel);
    if (seconds > 0) {
      _countdown = BossCountdown(seconds: seconds.toDouble());
    }
    if (_countdown != null) {
      const step = Duration(milliseconds: 100);
      _clock = async.Timer.periodic(step, (_) {
        final countdown = _countdown;
        if (!mounted || answered || countdown == null) return;
        setState(() => countdown.tick(step.inMilliseconds / 1000));
        if (countdown.expired) _timeUp();
      });
    }

    _initSlide();
  }

  void _initSlide() {
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

  /// A tap on an option of a boss question: it counts at once (the attack is already flying),
  /// and the boss answers it (a counter, or the hit).
  void _tapBoss(String answer) {
    final boss = widget.game.boss;
    if (boss == null || !boss.asking) return;
    if (answer == widget.game.currentQuestion!.correctAnswer) {
      widget.game.audioService.playCorrect();
    } else {
      widget.game.audioService.playWrong();
    }
    widget.onAnswer(answer);
    if (mounted) setState(() {});
  }

  void handleTap(String answer) {
    if (_bossMode) {
      _tapBoss(answer);
      return;
    }
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

  void _useBossTimeFreeze() {
    final boss = widget.game.boss;
    if (boss == null || !boss.asking || boss.frozen || boss.freezeUsed) return;
    if (widget.game.playerPowerUps.timeFreeze <= 0) return;
    widget.game.playerPowerUps.timeFreeze--;
    widget.game.onPowerUpUsed?.call('timeFreeze');
    widget.game.stats.powerUpsUsed++;
    widget.game.audioService.playPowerup();
    boss.freezeClock();
    setState(() {});
  }

  void _useTimeFreeze() {
    if (_bossMode) {
      _useBossTimeFreeze();
      return;
    }
    final countdown = _countdown;
    if (countdown == null || countdown.frozen || countdown.usedFreeze || answered) return;
    if (widget.game.playerPowerUps.timeFreeze <= 0) return;
    widget.game.playerPowerUps.timeFreeze--;
    widget.game.onPowerUpUsed?.call('timeFreeze');
    widget.game.stats.powerUpsUsed++;
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
    // Hiding two options of a 3-option question would leave only the right one, and a
    // second use on the same question would waste the power-up.
    if (question.options.length < 4 || hiddenOptions.isNotEmpty) return;

    widget.game.playerPowerUps.fiftyFifty--;
    widget.game.onPowerUpUsed?.call('fiftyFifty');
    widget.game.stats.powerUpsUsed++;
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
    if (widget.game.activateShield()) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.game.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    final boss = widget.game.boss;
    if (_bossMode && boss != null) {
      // Answered once the boss has taken the answer (or the time ran out): the card then
      // shows the right one until the boss takes it down.
      final answered = !boss.asking;
      return BossQuestionCard(
        question: question,
        phaseTag: boss.phaseTag,
        fraction: boss.clockFraction,
        secondsLeft: boss.secondsLeft.ceil(),
        frozen: boss.frozen,
        answered: answered,
        selectedAnswer: answered ? (boss.lastAnswer ?? '') : null,
        timeFreezeCount: widget.game.playerPowerUps.timeFreeze,
        onTimeFreeze: _useBossTimeFreeze,
        freezeSecondsLeft: boss.frozenSecondsLeft.ceil(),
        freezeUsed: boss.freezeUsed,
        fiftyFiftyCount: widget.game.playerPowerUps.fiftyFifty,
        onFiftyFifty: _useFiftyFifty,
        hiddenOptions: hiddenOptions,
        onAnswer: handleTap,
      );
    }

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
