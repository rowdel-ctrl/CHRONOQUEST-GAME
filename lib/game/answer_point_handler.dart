import '../models/codex_entry.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../services/storage_service.dart';
import 'chrono_game.dart';
import 'components/artifact_component.dart';
import 'components/gate_component.dart';

/// The question flow for artifacts, and the end gate that follows them.
///
/// Kept separate from `quiz_handler.dart` on purpose: that file's
/// `handleAnswer` is the boss path and is bound by Section 12's frozen POST
/// payload, so bolting retry/claim/charge logic into it would have risked
/// the contract the prompt says not to touch. Both paths still append to
/// the same `game.answers` array, which is what keeps the payload identical
/// in shape.
extension AnswerPointHandler on ChronoGame {
  /// Opens a question for an artifact the player walked into.
  void showArtifactQuestion(ArtifactComponent artifact) {
    final question = drawQuestion(exclude: artifact.lastQuestion);
    if (question == null) return; // no content for this level at all

    artifact.lastQuestion = question;
    activeArtifact = artifact;
    _openQuestion(question);
  }

  /// Opens the end gate. It asks nothing: the student has already answered
  /// every artifact, which is the whole requirement. If it is the level's
  /// exit, the level completes once the crumble effect has started.
  void passEndGate(GateComponent gate) {
    if (gate.opened) return;
    gate.open();
    if (gate.isLevelExit) {
      // Deferred so the crumble starts before the completion screen takes
      // over. levelComplete() is itself guarded against running twice, since
      // reaching the exit marker can also trigger it.
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (isMounted) levelComplete();
      });
    }
    notifyState();
  }

  void _openQuestion(Question question) {
    currentQuestion = question;
    questionShowing = true;
    pauseEngine();
    overlays.add('QuestionOverlay');
  }

  /// Resolves an answer to an artifact question.
  ///
  /// Records the attempt in the same `answers` array boss questions use —
  /// Section 12 says to log every attempt, and de-duplicating here would
  /// silently change the POST payload's contents.
  void handleAnswerPointAnswer(String answer) {
    final question = currentQuestion;
    if (question == null) return;

    final isCorrect = answer == question.correctAnswer;

    answers.add(QuestionSnapshot(
      questionId: question.id,
      questionText: question.questionText,
      studentAnswer: answer,
      correctAnswer: question.correctAnswer,
      isCorrect: isCorrect,
      timeTaken: question.elapsedSeconds,
    ));

    final artifact = activeArtifact;

    // Counted once per artifact, on its first answer, right or wrong — the end
    // gate requires engagement, not perfection (see `artifactsAnswered`). Its
    // own flag, not `attempted`: a Shield absorbs a wrong answer without
    // setting `attempted`, which would have counted the same artifact twice.
    if (artifact != null && !artifact.counted) {
      artifact.counted = true;
      artifactsAnswered++;
    }

    if (isCorrect) {
      score += 10;
      if (question.elapsedSeconds < 10) score += 5;
      player.triggerCheer();

      if (artifact != null) {
        grantCharges(artifact.reward);
        _recordCodexEntry(artifact, question);
        artifact.claim();
        artifactsClaimed++;
      }
    } else {
      // No HP is lost — Section 6 is explicit. A Shield absorbs the
      // consequence entirely: no inert penalty, so the reward stays full.
      final absorbed = shieldActive;
      if (absorbed) shieldActive = false;

      if (artifact != null && !absorbed) {
        artifact.goInert();
      }
    }

    activeArtifact = null;
    currentQuestion = null;
    overlays.remove('QuestionOverlay');
    questionShowing = false;
    resumeEngine();
    notifyState();
  }

  void _recordCodexEntry(ArtifactComponent artifact, Question question) {
    StorageService.saveCodexEntry(
      CodexEntry(
        eraId: currentEra,
        questionId: question.id,
        artifactSprite: artifact.spriteIndex,
        questionText: question.questionText,
        blurb: question.explanation,
        claimedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Adds [amount] charges. Uncapped: a level only holds a fixed number of
  /// artifacts, so supply is bounded by content, and a cap would only punish
  /// students who answer the most.
  void grantCharges(int amount) {
    kaalaman += amount;
    notifyState();
  }
}
