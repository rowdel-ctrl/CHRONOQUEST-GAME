import '../core/constants.dart';

/// Entry switch for the new top-down gameplay (everything under `lib/quest/`).
///
/// Off unless the build was made with `--dart-define=NEW_GAMEPLAY=true`, so the
/// student and tester builds never reach this code and the platformer in `lib/game/`
/// plays exactly as before. Nothing in `lib/game/` may import from `lib/quest/`;
/// `test/quest/isolation_test.dart` fails if it does.
class QuestMode {
  const QuestMode._();

  static const bool enabled = AppFlags.newGameplay;
}
