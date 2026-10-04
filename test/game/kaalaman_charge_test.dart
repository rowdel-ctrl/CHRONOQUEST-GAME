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

    test('is uncapped: a full level of artifacts is never clamped away', () {
      final game = ChronoGame()..kaalaman = 0;

      for (var i = 0; i < CombatConstants.artifactsPerLevel; i++) {
        game.grantCharges(CombatConstants.artifactReward);
      }

      expect(game.kaalaman,
          CombatConstants.artifactsPerLevel * CombatConstants.artifactReward);
    });
  });

  group('regeneration', () {
    test('restores one charge after the regen time when at zero', () {
      final game = ChronoGame()..kaalaman = 0;

      game.updateKaalamanRegen(CombatConstants.kaalamanRegenSeconds - 1);
      expect(game.kaalaman, 0);

      game.updateKaalamanRegen(1);
      expect(game.kaalaman, CombatConstants.kaalamanRegenFloor);
    });

    test('stops at the floor and never tops up past it', () {
      final game = ChronoGame()..kaalaman = 0;

      game.updateKaalamanRegen(CombatConstants.kaalamanRegenSeconds);
      game.updateKaalamanRegen(CombatConstants.kaalamanRegenSeconds * 5);

      expect(game.kaalaman, CombatConstants.kaalamanRegenFloor);
    });

    test('does not regenerate when the player already has charges', () {
      final game = ChronoGame()..kaalaman = 2;

      game.updateKaalamanRegen(CombatConstants.kaalamanRegenSeconds * 3);

      expect(game.kaalaman, 2);
    });

    test('spending down to zero starts a full wait, not a partial one', () {
      final game = ChronoGame()..kaalaman = 1;
      game.updateKaalamanRegen(CombatConstants.kaalamanRegenSeconds * 0.9);
      game.trySpendCharge();

      game.updateKaalamanRegen(CombatConstants.kaalamanRegenSeconds * 0.5);

      expect(game.kaalaman, 0);
    });
  });

  group('starting charges', () {
    test('levels start at 0 — artifacts are the only source', () {
      // Phase 2 temporarily started at 3 so combat was testable before
      // artifacts existed; Section 4 specifies 0 and Phase 3 restored it.
      expect(CombatConstants.kaalamanStart, 0);
    });

    test('the tutorial freebie is smaller than one artifact reward', () {
      // A freebie big enough to skip the first artifact would undercut the
      // loop it exists to bootstrap.
      expect(CombatConstants.kaalamanTutorialStart,
          lessThanOrEqualTo(CombatConstants.artifactReward));
    });
  });
}
