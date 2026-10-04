// The end gate (playtest decision, 2026-10-03) replaces the level's exit and
// stays shut until every artifact has been answered — **right or wrong**.
//
// The "or wrong" half is the point, and is deliberately pinned here: if the
// gate demanded correct answers, every student would eventually reach 100%
// and the teacher dashboard would measure nothing — no error rates, no weak
// topics, no learning gain. Wrong answers must still count toward progress
// while still being recorded as wrong.
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/game/chrono_game.dart';

void main() {
  group('end gate requirement', () {
    test('is unmet while artifacts are unanswered', () {
      final game = ChronoGame()
        ..artifactsTotal = 5
        ..artifactsAnswered = 3;

      expect(game.canPassEndGate, isFalse);
      expect(game.artifactsRemaining, 2);
    });

    test('is met once every artifact has been answered', () {
      final game = ChronoGame()
        ..artifactsTotal = 5
        ..artifactsAnswered = 5;

      expect(game.canPassEndGate, isTrue);
      expect(game.artifactsRemaining, 0);
    });

    test('a level with no artifacts never blocks', () {
      // Boss levels and the procedural fallback place none.
      final game = ChronoGame()..artifactsTotal = 0;

      expect(game.canPassEndGate, isTrue);
    });

    test('remaining never goes negative', () {
      final game = ChronoGame()
        ..artifactsTotal = 3
        ..artifactsAnswered = 7;

      expect(game.artifactsRemaining, 0);
    });
  });

  group('the locked notice', () {
    test('shows once rather than on every frame of contact', () {
      final game = ChronoGame()
        ..artifactsTotal = 5
        ..artifactsAnswered = 1;

      game.showGateLockedNotice();
      expect(game.gateLockedNoticeShowing, isTrue);

      // The player's update loop calls this every frame it is held at the
      // gate; the flag is what stops that re-adding the overlay forever.
      game.showGateLockedNotice();
      game.showGateLockedNotice();
      expect(game.gateLockedNoticeShowing, isTrue);
    });

    test('dismisses, and does not immediately re-show', () {
      final game = ChronoGame()
        ..artifactsTotal = 5
        ..artifactsAnswered = 1;

      game.showGateLockedNotice();
      game.dismissGateLockedNotice();
      expect(game.gateLockedNoticeShowing, isFalse);

      // A cooldown keeps the student from being trapped in a loop of the
      // same dialog while they are still standing against the gate.
      game.showGateLockedNotice();
      expect(game.gateLockedNoticeShowing, isFalse);
    });
  });
}
