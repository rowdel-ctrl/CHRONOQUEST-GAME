import '../models/question.dart';
import '../models/quiz_result.dart';
import 'chrono_game.dart';
import 'components/boss_component.dart';
import 'components/enemy_component.dart';

/// Question flow for [ChronoGame]: showing a question and resolving the
/// player's answer. Split out of chrono_game.dart to keep that file within
/// the line budget; behavior is unchanged.
extension QuizHandler on ChronoGame {
  void showQuestion(Question q, EnemyComponent enemy) {
    currentQuestion = q;
    currentEnemy = enemy;
    questionShowing = true;
    pauseEngine();
    overlays.add('QuestionOverlay');
  }

  void showBossQuestion(Question q, BossComponent bossRef) {
    currentQuestion = q;
    currentEnemy = null;
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

    if (isCorrect) {
      overlays.remove('QuestionOverlay');
      player.triggerCheer();
      score += 10;
      // Speed bonus
      if (currentQuestion!.elapsedSeconds < 10) {
        score += 5;
      }

      if (bossPhase && boss != null) {
        boss!.takeDamage();
      } else {
        currentEnemy?.defeat();
      }
      questionShowing = false;
      resumeEngine();
      notifyState(); // score changed, and possibly boss health
    } else {
      // Shield absorbs wrong answer
      if (shieldActive) {
        overlays.remove('QuestionOverlay');
        shieldActive = false;
        questionShowing = false;
        if (bossPhase && boss != null) {
          // No damage to boss, but no life lost either
        } else {
          currentEnemy?.defeat();
        }
        resumeEngine();
        return;
      }

      // Wrong answer: lose a life, close the question, enemy passes
      overlays.remove('QuestionOverlay');
      questionShowing = false;
      if (loseLife()) return;
      currentEnemy?.defeat();
      resumeEngine();
    }
  }
}
