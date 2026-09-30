import '../core/combat_constants.dart';
import '../models/codex_entry.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../services/storage_service.dart';
import 'chrono_game.dart';
import 'components/artifact_component.dart';
import 'components/gate_component.dart';

/// What opened the question currently on screen. Boss questions keep their
/// own path in `quiz_handler.dart`; these two are Phase 3's answer points
/// (GAMEPLAY-V2.md Section 6).
enum AnswerPointKind { artifact, gate }

/// The question flow for artifacts and gates.
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
    activeGate = null;
    _openQuestion(question);
  }

  /// Opens a question for a gate the player has walked up against.
  void showGateQuestion(GateComponent gate) {
    final question = drawQuestion(exclude: gate.lastQuestion);
    if (question == null) {
      // Nothing to ask — never trap the player behind an unanswerable gate.
      gate.open();
      return;
    }

    gate.lastQuestion = question;
    gate.questionPending = true;
    activeGate = gate;
    activeArtifact = null;
    _openQuestion(question);
  }

  void _openQuestion(Question question) {
    currentQuestion = question;
    questionShowing = true;
    pauseEngine();
    overlays.add('QuestionOverlay');
  }

  /// Resolves an answer to an artifact or gate question.
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
    final gate = activeGate;

    if (isCorrect) {
      score += 10;
      if (question.elapsedSeconds < 10) score += 5;
      player.triggerCheer();

      if (artifact != null) {
        grantCharges(artifact.reward);
        _recordCodexEntry(artifact, question);
        artifact.claim();
      } else if (gate != null) {
        gate.open();
      }
    } else {
      // No HP is lost — Section 6 is explicit. A Shield absorbs the
      // consequence entirely: no inert penalty, so the reward stays full.
      final absorbed = shieldActive;
      if (absorbed) shieldActive = false;

      if (artifact != null && !absorbed) {
        artifact.goInert();
      } else if (gate != null) {
        // The gate stays shut and will re-ask with a different question the
        // next time the player walks into it.
        gate.questionPending = false;
      }
    }

    activeArtifact = null;
    activeGate = null;
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

  /// Adds [amount] charges, capped (Section 4: "Cap: 6. This stops hoarding
  /// and keeps the player returning to artifacts.").
  void grantCharges(int amount) {
    kaalaman = (kaalaman + amount).clamp(0, CombatConstants.kaalamanCap);
    notifyState();
  }
}
