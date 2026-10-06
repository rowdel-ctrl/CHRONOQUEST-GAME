import '../core/constants.dart';

/// The single persistent pool of hearts shared by everything (GAMEPLAY-V2.md
/// section 8): it gates starting or retrying a level, and every in-level
/// damage event (enemy contact, hazard hit, falling) spends from it
/// directly — there is no separate level-local HP counter. Hearts
/// regenerate automatically over real time (`GameConstants.heartRegenInterval`),
/// capped at `GameConstants.maxHearts`, continuing to accrue even while the
/// app is closed since regen is computed lazily from a stored timestamp
/// rather than a running timer.
class HeartsState {
  /// Hearts currently available, 0..GameConstants.maxHearts.
  final int count;

  /// Epoch-ms anchor that the current regen countdown is measured from.
  /// Null whenever [count] is already at the cap — there's nothing pending.
  final int? regenStartMs;

  const HeartsState({required this.count, this.regenStartMs});

  factory HeartsState.initial() =>
      const HeartsState(count: GameConstants.maxHearts, regenStartMs: null);

  /// Applies however many regen intervals have elapsed since [regenStartMs],
  /// preserving any partial progress toward the next heart.
  HeartsState regenerated(DateTime now) {
    if (count >= GameConstants.maxHearts || regenStartMs == null) return this;

    final intervalMs = GameConstants.heartRegenInterval.inMilliseconds;
    final elapsedMs = now.millisecondsSinceEpoch - regenStartMs!;
    final heartsToAdd = elapsedMs ~/ intervalMs;
    if (heartsToAdd <= 0) return this;

    final newCount = count + heartsToAdd;
    if (newCount >= GameConstants.maxHearts) {
      return const HeartsState(count: GameConstants.maxHearts, regenStartMs: null);
    }
    return HeartsState(
      count: newCount,
      regenStartMs: regenStartMs! + heartsToAdd * intervalMs,
    );
  }

  /// Spends one heart, starting the regen countdown if it wasn't already
  /// running (i.e. the pool was full).
  HeartsState consumed(DateTime now) {
    if (count <= 0) return this;
    return HeartsState(
      count: count - 1,
      regenStartMs: regenStartMs ?? now.millisecondsSinceEpoch,
    );
  }

  /// Convenience for a level-failed event: applies any pending regen first,
  /// then spends one heart — keeps that ordering from being duplicated (or
  /// forgotten) at call sites.
  HeartsState afterLevelFailed(DateTime now) => regenerated(now).consumed(now);

  /// The pool as it should be when a level ends, given that the regen clock
  /// does not run during a level. [remaining] is the time that was left until
  /// the next heart when the level began (null if no countdown was running, in
  /// which case a fresh full interval starts now). The countdown picks up where
  /// it left off, however long the level took.
  HeartsState resumedAfterLevel(DateTime now, Duration? remaining) {
    if (count >= GameConstants.maxHearts) {
      return HeartsState(count: count, regenStartMs: null);
    }
    final intervalMs = GameConstants.heartRegenInterval.inMilliseconds;
    final remainingMs = (remaining?.inMilliseconds ?? intervalMs).clamp(0, intervalMs);
    return HeartsState(
      count: count,
      regenStartMs: now.millisecondsSinceEpoch - (intervalMs - remainingMs),
    );
  }

  /// Time remaining until the next heart, or null if the pool is full.
  Duration? timeUntilNext(DateTime now) {
    if (count >= GameConstants.maxHearts || regenStartMs == null) return null;
    final remainingMs = (regenStartMs! + GameConstants.heartRegenInterval.inMilliseconds) -
        now.millisecondsSinceEpoch;
    return Duration(milliseconds: remainingMs > 0 ? remainingMs : 0);
  }
}
