// Phase 3 scoring (GAMEPLAY-V2.md Sections 6 and 12).
//
// Section 6 introduces retries — a wrong answer costs no HP and the question
// comes back. Section 12 freezes the POST payload, which logs *every*
// attempt. Scored naively, those two together mean a student who answers
// everything correctly on the second try scores 50% and one star, punishing
// exactly the learning the explanation panel exists to produce.
//
// Resolved by scoring per distinct question, best attempt — which changes
// only the two derived numbers. These tests pin both halves: the fairer
// percentage, and the payload array staying byte-identical.
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/models/quiz_result.dart';

ChronoGame _game() {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.images.prefix = 'assets/';
  final player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(96, 120)
    ..position = Vector2(0, game.groundY - 120);
  player.game = game;
  game.player = player;
  return game;
}

QuestionSnapshot _snap(String id, bool correct) => QuestionSnapshot(
      questionId: id,
      questionText: 'Q$id',
      studentAnswer: correct ? 'right' : 'wrong',
      correctAnswer: 'right',
      isCorrect: correct,
      timeTaken: 5,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('percentage', () {
    test('a wrong-then-right question counts as correct', () {
      final game = _game();
      int? reportedCorrect;
      int? reportedTotal;
      game.onLevelComplete = (score, correct, total, answers) {
        reportedCorrect = correct;
        reportedTotal = total;
      };

      // Three questions, every one missed once and then answered correctly.
      for (final id in ['q1', 'q2', 'q3']) {
        game.answers.add(_snap(id, false));
        game.answers.add(_snap(id, true));
      }

      game.levelComplete();

      expect(reportedTotal, 3, reason: 'three distinct questions were asked');
      expect(reportedCorrect, 3,
          reason: 'all three were eventually answered correctly');
    });

    test('a question never answered correctly still counts as wrong', () {
      final game = _game();
      int? reportedCorrect;
      game.onLevelComplete = (score, correct, total, answers) {
        reportedCorrect = correct;
      };

      game.answers.add(_snap('q1', true));
      game.answers.add(_snap('q2', false));
      game.answers.add(_snap('q2', false));

      game.levelComplete();

      expect(reportedCorrect, 1,
          reason: 'q2 was missed twice and never got right');
    });

    test('first-try-perfect and retry-perfect both score full marks', () {
      // The point of the change: retrying costs time, charges and artifact
      // reward — it must not also cost stars.
      final firstTry = _game();
      int? firstTryCorrect;
      int? firstTryTotal;
      firstTry.onLevelComplete = (s, c, t, a) {
        firstTryCorrect = c;
        firstTryTotal = t;
      };
      firstTry.answers.add(_snap('q1', true));
      firstTry.answers.add(_snap('q2', true));
      firstTry.levelComplete();

      final onRetry = _game();
      int? retryCorrect;
      int? retryTotal;
      onRetry.onLevelComplete = (s, c, t, a) {
        retryCorrect = c;
        retryTotal = t;
      };
      onRetry.answers.add(_snap('q1', false));
      onRetry.answers.add(_snap('q1', true));
      onRetry.answers.add(_snap('q2', false));
      onRetry.answers.add(_snap('q2', true));
      onRetry.levelComplete();

      expect(retryCorrect, firstTryCorrect);
      expect(retryTotal, firstTryTotal);
    });
  });

  group('a level with artifacts is scored per artifact', () {
    test('ten artifacts read as x/10 even when only five questions exist', () {
      final game = _game()
        ..artifactsTotal = 10
        ..artifactsClaimed = 8;
      int? reportedCorrect;
      int? reportedTotal;
      game.onLevelComplete = (score, correct, total, answers) {
        reportedCorrect = correct;
        reportedTotal = total;
      };
      // Five distinct questions, each served twice: the old count said 5.
      for (var i = 0; i < 10; i++) {
        game.answers.add(_snap('q${i % 5}', true));
      }

      game.levelComplete();

      expect(reportedTotal, 10);
      expect(reportedCorrect, 8);
    });

    test('all ten claimed earns the perfect-level bonus', () {
      final plain = _game()
        ..artifactsTotal = 10
        ..artifactsClaimed = 9;
      final perfect = _game()
        ..artifactsTotal = 10
        ..artifactsClaimed = 10;
      int? plainScore;
      int? perfectScore;
      plain.onLevelComplete = (s, c, t, a) => plainScore = s;
      perfect.onLevelComplete = (s, c, t, a) => perfectScore = s;

      plain.levelComplete();
      perfect.levelComplete();

      expect(perfectScore! - plainScore!, 50);
    });

    test('a level with no artifacts keeps the per-question count', () {
      final game = _game();
      int? reportedTotal;
      game.onLevelComplete = (s, c, t, a) => reportedTotal = t;
      game.answers.add(_snap('q1', true));
      game.answers.add(_snap('q2', true));

      game.levelComplete();

      expect(reportedTotal, 2);
    });
  });

  group('payload is unchanged', () {
    test('every attempt is still handed to onLevelComplete, not deduplicated',
        () {
      // Section 12: "Log gate and artifact attempts into the same
      // per-question array that exists today." Collapsing them here would
      // silently change what the backend receives.
      final game = _game();
      List<QuestionSnapshot>? posted;
      game.onLevelComplete = (s, c, t, answers) => posted = answers;

      game.answers.add(_snap('q1', false));
      game.answers.add(_snap('q1', true));
      game.answers.add(_snap('q2', true));

      game.levelComplete();

      expect(posted, isNotNull);
      expect(posted!.length, 3,
          reason: 'all three attempts must reach the payload');
      expect(posted!.where((s) => s.questionId == 'q1').length, 2,
          reason: 'both attempts at q1 are recorded, wrong one included');
    });
  });
}
