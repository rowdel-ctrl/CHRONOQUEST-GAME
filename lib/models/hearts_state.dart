import '../core/constants.dart';

/// A persistent pool of hearts that gates starting or retrying a level —
/// distinct from the in-level HP (`GameConstants.livesPerLevel`) spent on
/// individual mistakes during an attempt already in progress. One heart is
/// spent when a level attempt is fully failed, and hearts regenerate
/// automatically over real time (`GameConstants.heartRegenInterval`),
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

  /// Time remaining until the next heart, or null if the pool is full.
  Duration? timeUntilNext(DateTime now) {
    if (count >= GameConstants.maxHearts || regenStartMs == null) return null;
    final remainingMs = (regenStartMs! + GameConstants.heartRegenInterval.inMilliseconds) -
        now.millisecondsSinceEpoch;
    return Duration(milliseconds: remainingMs > 0 ? remainingMs : 0);
  }
}
