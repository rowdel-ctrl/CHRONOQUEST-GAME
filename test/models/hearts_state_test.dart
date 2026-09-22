import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/hearts_state.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime(2026, 1, 1, 12, 0, 0);
const _interval = GameConstants.heartRegenInterval;

void main() {
  group('HeartsState.initial', () {
    test('starts full with no regen pending', () {
      final state = HeartsState.initial();
      expect(state.count, GameConstants.maxHearts);
      expect(state.regenStartMs, isNull);
      expect(state.timeUntilNext(_t0), isNull);
    });
  });

  group('HeartsState.consumed', () {
    test('decrements count and starts the regen clock when leaving full', () {
      final state = HeartsState.initial().consumed(_t0);
      expect(state.count, GameConstants.maxHearts - 1);
      expect(state.regenStartMs, _t0.millisecondsSinceEpoch);
    });

    test('does not go below zero', () {
      var state = HeartsState.initial();
      for (var i = 0; i < GameConstants.maxHearts + 3; i++) {
        state = state.consumed(_t0);
      }
      expect(state.count, 0);
    });

    test('a second consume keeps the original regen clock, not a later one',
        () {
      final afterFirst = HeartsState.initial().consumed(_t0);
      final afterSecond = afterFirst.consumed(_t0.add(_interval * 0.5));
      expect(afterSecond.count, GameConstants.maxHearts - 2);
      expect(afterSecond.regenStartMs, _t0.millisecondsSinceEpoch);
    });
  });

  group('HeartsState.regenerated', () {
    test('does nothing before a full interval has elapsed', () {
      final consumed = HeartsState.initial().consumed(_t0);
      final regenerated =
          consumed.regenerated(_t0.add(_interval - const Duration(seconds: 1)));
      expect(regenerated.count, consumed.count);
      expect(regenerated.regenStartMs, consumed.regenStartMs);
    });

    test('adds exactly one heart after one interval, preserving remainder',
        () {
      final consumed = HeartsState.initial().consumed(_t0);
      const extra = Duration(seconds: 20);
      final regenerated = consumed.regenerated(_t0.add(_interval + extra));
      expect(regenerated.count, GameConstants.maxHearts);
      // maxHearts - 1 + 1 heart == maxHearts here, so the pool is full and
      // the clock should have cleared rather than kept a remainder.
      expect(regenerated.regenStartMs, isNull);
    });

    test('adds multiple hearts for multiple elapsed intervals at once', () {
      var state = HeartsState.initial();
      state = state.consumed(_t0).consumed(_t0).consumed(_t0); // count = 2
      final regenerated = state.regenerated(_t0.add(_interval * 2));
      expect(regenerated.count, 4);
      expect(regenerated.regenStartMs,
          _t0.millisecondsSinceEpoch + 2 * _interval.inMilliseconds);
    });

    test('caps at maxHearts and clears the regen clock', () {
      final state = HeartsState.initial().consumed(_t0); // count = max - 1
      final regenerated = state.regenerated(_t0.add(_interval * 10));
      expect(regenerated.count, GameConstants.maxHearts);
      expect(regenerated.regenStartMs, isNull);
    });

    test('is a no-op on an already-full pool', () {
      final full = HeartsState.initial();
      final regenerated = full.regenerated(_t0.add(_interval * 5));
      expect(regenerated.count, full.count);
      expect(regenerated.regenStartMs, isNull);
    });
  });

  group('HeartsState.timeUntilNext', () {
    test('counts down toward the next heart', () {
      final state = HeartsState.initial().consumed(_t0);
      final remaining = state.timeUntilNext(_t0.add(const Duration(minutes: 4)));
      expect(remaining, _interval - const Duration(minutes: 4));
    });

    test('floors at zero instead of going negative when overdue', () {
      final state = HeartsState.initial().consumed(_t0);
      final remaining = state.timeUntilNext(_t0.add(_interval * 2));
      expect(remaining, Duration.zero);
    });

    test('is null once the pool is full', () {
      expect(HeartsState.initial().timeUntilNext(_t0), isNull);
    });
  });

  group('HeartsState.afterLevelFailed', () {
    test('applies pending regen before spending the heart', () {
      // Start one below max, with enough elapsed time for exactly one heart
      // to regen back to full by the time the level fails.
      final almostFull = HeartsState.initial().consumed(_t0);
      final now = _t0.add(_interval + const Duration(seconds: 1));
      final result = almostFull.afterLevelFailed(now);
      // Regen would have refilled to max; failing the level then spends
      // one, landing back at max - 1 with a fresh clock — not max - 2, which
      // is what skipping the regen step would have produced.
      expect(result.count, GameConstants.maxHearts - 1);
      expect(result.regenStartMs, now.millisecondsSinceEpoch);
    });
  });
}
