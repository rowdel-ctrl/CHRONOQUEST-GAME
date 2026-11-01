import 'package:chronoquest/providers/badge_provider.dart';

/// A [BadgeNotifier] that keeps its record in memory instead of the phone's storage
/// (Hive writes started in a widget test never finish, and block the ones after them),
/// and that is not disposed with the screen's scope, so a test can open the screen
/// twice on the same student.
///
/// [levels] is what the phone already holds for the first run with badges: the best
/// stars per level, per era.
class MemoryBadges extends BadgeNotifier {
  MemoryBadges({
    Map<String, Map<int, int>> levels = const {},
    int codex = 0,
    void Function(int coins)? payCoins,
  }) : this._(<String, Map<String, dynamic>>{}, levels, codex, payCoins);

  MemoryBadges._(
    Map<String, Map<String, dynamic>> saved,
    Map<String, Map<int, int>> levels,
    int codex,
    void Function(int coins)? payCoins,
  ) : super(
          payCoins: payCoins ?? (_) {},
          codexTotal: () => codex,
          now: () => DateTime(2026, 10, 30),
          readSaved: (id) => saved[id],
          write: (id, facts) => saved[id] = facts,
          completedLevels: (era) => levels[era] ?? const {},
        );

  // Deliberately not calling super: this one must outlive the screen's scope.
  @override
  // ignore: must_call_super
  void dispose() {}
}
