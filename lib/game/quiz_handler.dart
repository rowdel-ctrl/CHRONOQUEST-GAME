import 'package:flame/components.dart' show Vector2;
import '../models/question.dart';
import '../models/quiz_result.dart';
import 'chrono_game.dart';
import 'components/boss_component.dart';
import 'components/praise_component.dart';
import 'kaalaman_handler.dart';

/// Question flow for [ChronoGame]: showing a question and resolving the
/// player's answer. Split out of chrono_game.dart to keep that file within
/// the line budget.
///
/// Only boss fights reach this now (GAMEPLAY-V2.md Section 15, Phase 2:
/// enemies no longer open the quiz on contact — that's contact damage now,
/// see PlayerComponent). `showQuestion()`/the enemy-linked branches this
/// used to have are gone with it, not just their `currentEnemy?.defeat()`
/// calls — nothing else ever called `showQuestion()`.
///
/// The boss question does not pause the game any more: the boss's attack flies towards
/// the hero while the card is open, and its flight is the answer timer (BossComponent),
/// so the game has to keep running. Pausing from the pause button still stops it all.
extension QuizHandler on ChronoGame {
  void showBossQuestion(Question q, BossComponent bossRef) {
    currentQuestion = q;
    questionShowing = true;
    // A card still up from the last round makes way for the new one.
    overlays.remove('QuestionOverlay');
    overlays.add('QuestionOverlay');
  }

  /// Takes the question card down (the round is over, or the fight is).
  void closeBossQuestion() {
    questionShowing = false;
    overlays.remove('QuestionOverlay');
  }

  /// The student answered the boss question. [answer] is empty when the time ran out (the
  /// boss calls it that way, once, when its attack arrives).
  void handleAnswer(String answer) {
    final q = currentQuestion;
    if (q == null) return;
    // Only the first answer of a round counts: a tap in the same moment as the timeout, or
    // one after the question has gone, is ignored.
    final fight = boss;
    if (fight != null && !fight.asking) return;
    if (fight != null) q.elapsedSeconds = fight.elapsedSeconds;

    final isCorrect = answer == q.correctAnswer;

    answers.add(QuestionSnapshot(
      questionId: q.id,
      questionText: q.questionText,
      studentAnswer: answer,
      correctAnswer: q.correctAnswer,
      isCorrect: isCorrect,
      timeTaken: q.elapsedSeconds,
    ));

    // The streak counts boss answers too, the wrong ones ending it.
    final streakBonus = noteAnswer(correct: isCorrect);
    questionShowing = false;

    if (isCorrect) {
      player.triggerCheer();
      if (streakBonus) audioService.playStreak();
      if (streakBonus && player.isMounted) {
        player.add(PraiseComponent(word: '+1 KAALAMAN!')
          ..position = Vector2(player.size.x / 2, -4));
      }
      score += 10;
      // Speed bonus
      if (q.elapsedSeconds < 10) {
        score += 5;
      }
      notifyState(); // score changed
    }
    // A wrong answer costs the boss nothing and the hero a heart, when the attack arrives
    // (the boss does that); a Shield is spent only then, by the hit itself.
    fight?.answered(correct: isCorrect, timedOut: answer.isEmpty, answer: answer);
  }
}
