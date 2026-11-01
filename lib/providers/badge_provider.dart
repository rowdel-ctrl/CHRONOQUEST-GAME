import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/badge_defs.dart';
import '../models/badge_facts.dart';
import '../models/quiz_result.dart';
import '../services/api_service.dart';
import '../services/badge_rules.dart';
import '../services/guest_mode.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';
import 'game_provider.dart';

class BadgeState {
  /// Whose badges these are. Null with nobody signed in.
  final String? studentId;

  /// False for a guest and with nobody signed in: nothing is earned or kept.
  final bool enabled;
  final BadgeFacts facts;

  const BadgeState(
      {this.studentId, this.enabled = false, this.facts = const BadgeFacts()});

  bool has(String badgeId) => facts.earned.containsKey(badgeId);
  int get earnedCount => facts.earned.length;

  /// Earned and not seen yet: the red BAGO count.
  int get unseenCount => facts.unseen.length;

  /// Earned without a fanfare and not mentioned yet.
  int get quietCount => facts.quiet;
}

/// The student's badges: records what they do, earns what that adds up to, and gives
/// the one-time coin gift for each new badge.
///
/// Badges earned at the end of a level or a boss come back from [recordLevel] so the
/// screen can announce them. Ones that arrive with the update, or from the server on
/// a new phone, come quietly: they are held with the BAGO tag and counted for one
/// line on the eras screen, never a pile of pop-ups, and they pay no coin gift. The gift
/// was paid when the badge was first earned, and on a new phone the wallet already has
/// it, so paying again would let a reinstall farm coins.
class BadgeNotifier extends StateNotifier<BadgeState> {
  BadgeNotifier({
    required this.payCoins,
    this.loadResults,
    int Function()? codexTotal,
    DateTime Function()? now,
    Map<String, dynamic>? Function(String studentId)? readSaved,
    void Function(String studentId, Map<String, dynamic> facts)? write,
    Map<int, int> Function(String eraId)? completedLevels,
  })  : _codexTotal = codexTotal ?? StorageService.getCodexTotal,
        _now = now ?? DateTime.now,
        _readSaved = readSaved ?? StorageService.getBadges,
        _write = write ?? StorageService.saveBadges,
        _completedLevels = completedLevels ?? StorageService.getCompletedLevels,
        super(const BadgeState());

  /// Puts coins in the wallet.
  final void Function(int coins) payCoins;

  /// Reads the student's attempts from the server. Null: this phone only (tests).
  final Future<List<QuizResult>> Function()? loadResults;

  // Where the record is read and kept: the phone's storage, unless a test brings its own.
  final int Function() _codexTotal;
  final DateTime Function() _now;
  final Map<String, dynamic>? Function(String studentId) _readSaved;
  final void Function(String studentId, Map<String, dynamic> facts) _write;
  final Map<int, int> Function(String eraId) _completedLevels;

  /// Switches to [studentId]'s badges. With none yet (the first time with badges)
  /// they are worked out from what the phone already holds, quietly.
  void load(String? studentId) {
    if (studentId == null || studentId == GuestMode.studentId) {
      state = const BadgeState();
      return;
    }
    final saved = _readSaved(studentId);
    if (saved != null) {
      state = BadgeState(
          studentId: studentId,
          enabled: true,
          facts: BadgeFacts.fromJson(saved));
      return;
    }
    state = BadgeState(studentId: studentId, enabled: true);
    final known = BadgeRules.fromLocalLevels({
      for (final era in allEras) era.id: _completedLevels(era.id),
    });
    _earn(known, quiet: true);
  }

  /// A level was finished. Returns the badges it earned, newest first to show.
  List<EarnedBadge> recordLevel({
    required String eraId,
    required int level,
    required int correct,
    required int total,
    required int healthLost,
    required bool anyWrong,
  }) {
    if (!state.enabled) return const [];
    final facts = BadgeRules.applyLevel(
      state.facts,
      eraId: eraId,
      level: level,
      correct: correct,
      total: total,
      healthLost: healthLost,
      anyWrong: anyWrong,
      day: BadgeRules.dayOf(_now()),
    );
    return _earn(facts);
  }

  /// A level was lost: no badge, but it was a day of play.
  void recordFailed() {
    if (!state.enabled) return;
    _commit(BadgeRules.applyFailed(state.facts, day: BadgeRules.dayOf(_now())));
  }

  /// Something was bought in the Tindahan. Returns what that earned.
  List<EarnedBadge> recordPurchase() {
    if (!state.enabled) return const [];
    return _earn(state.facts.copyWith(bought: true));
  }

  /// Joins what the server keeps with what the phone knows, which brings badges back
  /// on a new phone. Quiet. Does nothing offline.
  Future<void> syncFromServer() async {
    final read = loadResults;
    final id = state.studentId;
    if (read == null || !state.enabled || id == null) return;
    final List<QuizResult> results;
    try {
      results = await read();
    } catch (_) {
      return;
    }
    // Another student may have signed in while this was on its way.
    if (!mounted || state.studentId != id) return;
    _earn(BadgeRules.mergeResults(state.facts, results), quiet: true);
  }

  /// Looks again at what the Kodeks holds, which can earn a Kolektor badge.
  void refresh() {
    if (!state.enabled) return;
    _earn(state.facts, quiet: true);
  }

  /// The shelf has been opened: nothing is new any more.
  void markAllSeen() {
    if (!state.enabled || state.facts.unseen.isEmpty) return;
    _commit(state.facts.copyWith(unseen: const {}));
  }

  /// The one line on the eras screen has been shown.
  void clearQuiet() {
    if (!state.enabled || state.facts.quiet == 0) return;
    _commit(state.facts.copyWith(quiet: 0));
  }

  List<EarnedBadge> _earn(BadgeFacts facts, {bool quiet = false}) {
    final earned = BadgeRules.newlyEarned(facts, codexTotal: _codexTotal());
    _commit(
      BadgeRules.withEarned(facts, earned,
          nowMs: _now().millisecondsSinceEpoch, quiet: quiet),
      gift: quiet ? 0 : earned.fold<int>(0, (sum, b) => sum + b.coins),
    );
    return earned;
  }

  void _commit(BadgeFacts facts, {int gift = 0}) {
    final id = state.studentId;
    if (id == null) return;
    state = BadgeState(studentId: id, enabled: true, facts: facts);
    _write(id, facts.toJson());
    if (gift > 0) payCoins(gift);
  }
}

final badgeProvider = StateNotifierProvider<BadgeNotifier, BadgeState>((ref) {
  // The wallet is loaded for the student first, so a gift lands in the right one.
  ref.read(gameProvider);
  final notifier = BadgeNotifier(
    payCoins: (n) => ref.read(gameProvider.notifier).addCoins(n),
    loadResults: ApiService().getResults,
  );
  // The badges follow whoever is logged in.
  ref.listen<String?>(
    authProvider.select((s) => s.student?.id),
    (_, id) => notifier.load(id),
    fireImmediately: true,
  );
  return notifier;
});
