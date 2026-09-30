// Kaalaman (attack charge) grant/spend (GAMEPLAY-V2.md Section 4,
// implemented Phase 2 via kaalaman_handler.dart). No components involved —
// a bare, unloaded ChronoGame is enough since kaalaman is a plain field.
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
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

  group('debugGrantCharges', () {
    test('grants debugGrantAmount from 0', () {
      final game = ChronoGame()..kaalaman = 0;

      game.debugGrantCharges();

      expect(game.kaalaman, CombatConstants.debugGrantAmount);
    });

    test('clamps at kaalamanCap even when called repeatedly', () {
      final game = ChronoGame()..kaalaman = 0;

      for (var i = 0; i < 10; i++) {
        game.debugGrantCharges();
      }

      expect(game.kaalaman, CombatConstants.kaalamanCap);
    });

    test('never exceeds the cap starting from just below it', () {
      final game = ChronoGame()..kaalaman = CombatConstants.kaalamanCap - 1;

      game.debugGrantCharges();

      expect(game.kaalaman, CombatConstants.kaalamanCap);
    });
  });
}
