import 'dart:math' as math;

import '../core/constants.dart';
import '../models/badge_defs.dart';
import '../models/badge_facts.dart';
import '../models/quiz_result.dart';

/// The rules of the badges, with no screen and no storage: what counts, and when a
/// badge is earned. Learning, not grinding: nothing here rewards speed, rank or
/// playing every day, and doing the same thing again never counts twice.
class BadgeRules {
  BadgeRules._();

  static String levelKey(String eraId, int level) => '$eraId:$level';

  /// The day as `2026-10-30`, in the phone's own time.
  static String dayOf(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  /// How far [family] has got: the number its levels ask for. [codexTotal] is the
  /// artifacts in the Kodeks, which the Kodeks itself keeps.
  static int progress(BadgeFamily family, BadgeFacts facts,
      {required int codexTotal}) {
    final id = family.id;
    if (id.startsWith('era:')) {
      return facts.bosses.contains(id.substring(4)) ? 1 : 0;
    }
    if (id.startsWith('champ:')) {
      final grade = int.parse(id.substring(6));
      return allEras
          .where((e) => e.grade == grade && facts.bosses.contains(e.id))
          .length;
    }
    return switch (id) {
      'stars3' => facts.threeStar.length,
      'perfect' => facts.perfect.length,
      'comeback' => facts.comebacks,
      'collector' => codexTotal,
      'days' => facts.days.length,
      'nodamage' => facts.noDamage.length,
      'firstbuy' => facts.bought ? 1 : 0,
      'bossclean' => facts.bossClean ? 1 : 0,
      _ => 0,
    };
  }

  /// Every badge whose need is met and which is not held yet.
  static List<EarnedBadge> newlyEarned(BadgeFacts facts,
      {required int codexTotal}) {
    final out = <EarnedBadge>[];
    for (final family in badgeFamilies) {
      final got = progress(family, facts, codexTotal: codexTotal);
      for (final step in family.steps) {
        if (got >= step.need && !facts.earned.containsKey(step.id)) {
          out.add(EarnedBadge(family, step));
        }
      }
    }
    return out;
  }

  /// [facts] with [badges] held from [nowMs]. They carry the BAGO tag until the
  /// shelf is opened. [quiet] ones are also counted for the one line on the eras
  /// screen (they came with the update or a new phone, with no fanfare).
  static BadgeFacts withEarned(
    BadgeFacts facts,
    List<EarnedBadge> badges, {
    required int nowMs,
    bool quiet = false,
  }) {
    if (badges.isEmpty) return facts;
    return facts.copyWith(
      earned: {...facts.earned, for (final b in badges) b.id: nowMs},
      unseen: {...facts.unseen, for (final b in badges) b.id},
      quiet: quiet ? facts.quiet + badges.length : facts.quiet,
    );
  }

  static BadgeFacts playedOn(BadgeFacts facts, String day) =>
      facts.days.contains(day)
          ? facts
          : facts.copyWith(days: {...facts.days, day});

  /// A level finished. [correct] of [total] is the game's own score for it,
  /// [healthLost] the hearts lost in it, and [anyWrong] whether any answer was ever
  /// wrong (even one put right on a retry).
  static BadgeFacts applyLevel(
    BadgeFacts facts, {
    required String eraId,
    required int level,
    required int correct,
    required int total,
    required int healthLost,
    required bool anyWrong,
    required String day,
  }) {
    final key = levelKey(eraId, level);
    final percent = total > 0 ? (correct / total * 100).round() : 0;
    final before = facts.best[key];
    final isBoss = level == getEraById(eraId).levels.length;
    return playedOn(facts, day).copyWith(
      best: {...facts.best, key: math.max(before ?? 0, percent)},
      comebacks: before != null && percent > before
          ? facts.comebacks + 1
          : facts.comebacks,
      threeStar: percent >= 90 ? {...facts.threeStar, key} : facts.threeStar,
      perfect: total > 0 && correct == total
          ? {...facts.perfect, key}
          : facts.perfect,
      noDamage: healthLost == 0 ? {...facts.noDamage, key} : facts.noDamage,
      bosses: isBoss ? {...facts.bosses, eraId} : facts.bosses,
      bossClean: facts.bossClean || (isBoss && total > 0 && !anyWrong),
    );
  }

  /// A level lost: nothing is earned, but it was a day of play.
  static BadgeFacts applyFailed(BadgeFacts facts, {required String day}) =>
      playedOn(facts, day);

  /// What the phone already knows when the badges first appear: the best stars of
  /// each finished level, per era (`levels_<era>` in storage). Stars say less than a
  /// score, so each is taken at the top of its range and a later replay is not
  /// wrongly counted as a comeback.
  static BadgeFacts fromLocalLevels(Map<String, Map<int, int>> starsByEra) {
    final best = <String, int>{};
    final threeStar = <String>{};
    final bosses = <String>{};
    for (final entry in starsByEra.entries) {
      final bossLevel = getEraById(entry.key).levels.length;
      for (final level in entry.value.entries) {
        final key = levelKey(entry.key, level.key);
        best[key] = switch (level.value) { >= 3 => 100, 2 => 89, _ => 69 };
        if (level.value >= 3) threeStar.add(key);
        if (level.key == bossLevel) bosses.add(entry.key);
      }
    }
    return BadgeFacts(best: best, threeStar: threeStar, bosses: bosses);
  }

  /// [facts] joined with the attempts the server keeps for the student. This is what
  /// brings the badges back on a new phone.
  static BadgeFacts mergeResults(BadgeFacts facts, List<QuizResult> results) {
    final byLevel = <String, List<QuizResult>>{};
    final bosses = {...facts.bosses};
    for (final r in results) {
      if (!allEras.any((e) => e.id == r.era)) continue;
      byLevel.putIfAbsent(levelKey(r.era, r.level), () => []).add(r);
      if (r.type == 'post_test') bosses.add(r.era);
    }

    final best = {...facts.best};
    final threeStar = {...facts.threeStar};
    final perfect = {...facts.perfect};
    var comebacks = 0;
    for (final entry in byLevel.entries) {
      // Oldest first, so a replay is compared with what came before it.
      final attempts = [...entry.value]..sort((a, b) =>
          (DateTime.tryParse(a.testDate ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(DateTime.tryParse(b.testDate ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0)));
      var top = -1;
      for (final a in attempts) {
        if (top >= 0 && a.percentage > top) comebacks++;
        top = math.max(top, a.percentage);
        if (a.percentage >= 90) threeStar.add(entry.key);
        if (a.percentage >= 100) perfect.add(entry.key);
      }
      best[entry.key] = math.max(best[entry.key] ?? 0, top);
    }

    return facts.copyWith(
      best: best,
      threeStar: threeStar,
      perfect: perfect,
      bosses: bosses,
      // What this phone counted itself and what the server shows are the same replays
      // seen twice, so the larger of the two stands.
      comebacks: math.max(facts.comebacks, comebacks),
    );
  }
}
