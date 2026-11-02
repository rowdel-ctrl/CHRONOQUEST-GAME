// Kaalaman (attack charge) grant/spend (GAMEPLAY-V2.md Section 4,
// implemented Phase 2 via kaalaman_handler.dart). No components involved —
// a bare, unloaded ChronoGame is enough since kaalaman is a plain field.
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/answer_point_handler.dart';
import 'package:chronoquest/game/kaalaman_handler.dart';

void main() {
  group('trySpendCharge', () {
    test('decrements by attackChargeCost and succeeds when charges > 0', () {
      final game = ChronoGame()..kaalaman = 3;

      final spent = game.trySpendCharge();

      expect(spent, true);
      expect(game.kaalaman, 3 - CombatConstants.attackChargeCost);
    });

    test('fails and leaves kaalaman unchanged at 0', () {
      final game = ChronoGame()..kaalaman = 0;

      final spent = game.trySpendCharge();

      expect(spent, false);
      expect(game.kaalaman, 0);
    });
  });

  // Phase 3 replaced Phase 2's debug keyboard grant with the real source:
  // claiming an artifact. The cap behaviour these used to cover now belongs
  // to grantCharges, which is what artifacts call.
  group('grantCharges', () {
    test('adds the artifact reward', () {
      final game = ChronoGame()..kaalaman = 0;

      game.grantCharges(CombatConstants.artifactReward);

      expect(game.kaalaman, CombatConstants.artifactReward);
    });

    test('the retry reward is smaller than the first-try reward', () {
      // Section 6: being wrong costs you power, not HP.
      expect(CombatConstants.artifactRetryReward,
          lessThan(CombatConstants.artifactReward));
    });

    test('stops at the full bar, so the bar shows what there is', () {
      final game = ChronoGame()..kaalaman = CombatConstants.kaalamanDisplayMax - 1;

      game.grantCharges(CombatConstants.artifactReward);

      expect(game.kaalaman, CombatConstants.kaalamanDisplayMax);
    });
  });

  group('regeneration', () {
    test('is one charge every 8 seconds', () {
      expect(CombatConstants.kaalamanRegenSeconds, 8);
    });

    test('restores one charge after the regen time when at zero', () {
      final game = ChronoGame()..kaalaman = 0;

      game.updateKaalamanRegen(CombatConstants.kaalamanRegenSeconds - 1);
      expect(game.kaalaman, 0);

      game.updateKaalamanRegen(1);
      expect(game.kaalaman, 1);
    });

    test('keeps going whenever the bar is below full, not only at zero', () {
      final game = ChronoGame()..kaalaman = 4;

      game.updateKaalamanRegen(CombatConstants.kaalamanRegenSeconds);
      expect(game.kaalaman, 5);
      game.updateKaalamanRegen(CombatConstants.kaalamanRegenSeconds);
      expect(game.kaalaman, 6);
    });

    test('stops at the full bar', () {
      final game = ChronoGame()
        ..kaalaman = CombatConstants.kaalamanDisplayMax - 1;

      game.updateKaalamanRegen(CombatConstants.kaalamanRegenSeconds);
      game.updateKaalamanRegen(CombatConstants.kaalamanRegenSeconds * 5);

      expect(game.kaalaman, CombatConstants.kaalamanDisplayMax);
    });

    test('spending the first charge from a full bar starts a full wait', () {
      final game = ChronoGame();
      game.updateKaalamanRegen(CombatConstants.kaalamanRegenSeconds * 0.9);
      game.trySpendCharge();

      game.updateKaalamanRegen(CombatConstants.kaalamanRegenSeconds * 0.5);

      expect(game.kaalaman, CombatConstants.kaalamanDisplayMax - 1);
    });
  });

  group('streak of right answers', () {
    test('every third one in a row gives one extra charge', () {
      final game = ChronoGame()..kaalaman = 2;

      expect(game.noteAnswer(correct: true), isFalse);
      expect(game.noteAnswer(correct: true), isFalse);
      expect(game.kaalaman, 2);
      expect(game.noteAnswer(correct: true), isTrue);
      expect(game.kaalaman, 3);
      expect(game.noteAnswer(correct: true), isFalse);
      expect(game.noteAnswer(correct: true), isFalse);
      expect(game.noteAnswer(correct: true), isTrue, reason: 'and again at six');
      expect(game.kaalaman, 4);
      expect(game.stats.bestStreak, 6);
    });

    test('a wrong answer starts the count again, and the best run is kept', () {
      final game = ChronoGame()..kaalaman = 2;
      game.noteAnswer(correct: true);
      game.noteAnswer(correct: true);
      game.noteAnswer(correct: false);
      expect(game.noteAnswer(correct: true), isFalse);
      expect(game.noteAnswer(correct: true), isFalse);
      expect(game.kaalaman, 2, reason: 'no bonus: the run was broken');
      expect(game.stats.bestStreak, 2);
      expect(game.stats.wrongAnswers, 1);
    });

    test('the bonus cannot go over the full bar', () {
      final game = ChronoGame();
      for (var i = 0; i < 3; i++) {
        game.noteAnswer(correct: true);
      }
      expect(game.kaalaman, CombatConstants.kaalamanDisplayMax);
    });
  });

  group('starting charges', () {
    test('every level, boss included, starts with the bar full', () {
      expect(CombatConstants.kaalamanStart, CombatConstants.kaalamanDisplayMax);
      expect(CombatConstants.bossStartCharges, CombatConstants.kaalamanDisplayMax);
      expect(ChronoGame().kaalaman, CombatConstants.kaalamanDisplayMax);
    });

    test('a student who answers wrong still has charges to attack with', () {
      final game = ChronoGame();
      expect(game.canAttack, isTrue);
    });
  });
}
