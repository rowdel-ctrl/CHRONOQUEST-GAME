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
extension QuizHandler on ChronoGame {
  void showBossQuestion(Question q, BossComponent bossRef) {
    currentQuestion = q;
    questionShowing = true;
    pauseEngine();
    overlays.add('QuestionOverlay');
  }

  void handleAnswer(String answer) {
    final isCorrect = answer == currentQuestion!.correctAnswer;

    answers.add(QuestionSnapshot(
      questionId: currentQuestion!.id,
      questionText: currentQuestion!.questionText,
      studentAnswer: answer,
      correctAnswer: currentQuestion!.correctAnswer,
      isCorrect: isCorrect,
      timeTaken: currentQuestion!.elapsedSeconds,
    ));

    // The streak counts boss answers too, the wrong ones ending it.
    final streakBonus = noteAnswer(correct: isCorrect);

    if (isCorrect) {
      overlays.remove('QuestionOverlay');
      player.triggerCheer();
      if (streakBonus) audioService.playStreak();
      if (streakBonus && player.isMounted) {
        player.add(PraiseComponent(word: '+1 KAALAMAN!')
          ..position = Vector2(player.size.x / 2, -4));
      }
      score += 10;
      // Speed bonus
      if (currentQuestion!.elapsedSeconds < 10) {
        score += 5;
      }

      boss?.takeDamage();
      questionShowing = false;
      resumeEngine();
      notifyState(); // score changed, and possibly boss health
    } else {
      // Wrong answer: no HP lost (GAMEPLAY-V2.md Section 6/8) — just close
      // the question. A Shield is not spent here: there is nothing to absorb, and it
      // stays for a minion's hit or the boss's shockwave.
      overlays.remove('QuestionOverlay');
      questionShowing = false;
      resumeEngine();
      boss?.missed();
    }
  }
}
