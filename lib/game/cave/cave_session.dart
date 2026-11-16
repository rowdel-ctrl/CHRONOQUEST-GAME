import '../../models/quiz_result.dart' show QuestionSnapshot;
import '../chrono_game.dart';
import '../components/pipe_component.dart';

/// What the level hands to the cave screen when the student walks onto the pipe.
/// The cave is its own small game on top of the level (like the bonus round), but
/// it plays with the level's hearts, power-ups, coins and question supply, so the
/// request carries the level's game itself: the screen wires the cave to it.
class CaveRequest {
  /// The level the student is in, held still underneath until they are back.
  final ChronoGame level;

  /// Where the pipe is on the level's screen, as fractions of its width and height.
  final double pipeX;
  final double pipeY;

  const CaveRequest({
    required this.level,
    this.pipeX = 0.5,
    this.pipeY = 0.5,
  });
}

/// How the cave ended.
class CaveResult {
  /// True when the student answered the cave's artifact (right or wrong) and came
  /// back up the exit pipe: the level counts one more artifact.
  final bool answered;

  /// True when that answer was right at some try.
  final bool claimed;

  /// Every answer given in the cave, in order, for the level's own list.
  final List<QuestionSnapshot> answers;

  /// What the cave added: coins picked up, points, and the Kaalaman left.
  final int coins;
  final int score;
  final int kaalaman;

  /// Hearts left, after whatever the cave took.
  final int hearts;

  /// Whether a Shield the student switched on is still up (it goes back to the
  /// level with them).
  final bool shieldActive;

  /// True when the last heart went in the cave: the level is failed.
  final bool failed;

  const CaveResult({
    this.answered = false,
    this.claimed = false,
    this.answers = const [],
    this.coins = 0,
    this.score = 0,
    this.kaalaman = 0,
    this.hearts = 0,
    this.shieldActive = false,
    this.failed = false,
  });
}

/// The level's side of the cave: whether it has been done, whether the student is
/// down there right now, and who shows it. One of these lives on each `ChronoGame`.
class CaveSession {
  /// True once the cave artifact has been answered and the student is back.
  bool done = false;

  /// True from the walk onto the pipe until the student is back: the level is held
  /// still.
  bool away = false;

  /// The pipe standing in the level now, if this level has one.
  PipeComponent? pipe;

  /// Shows the cave and gives back how it ended (null if it was torn down). Set by
  /// the game screen; null in a bare game, where the pipe then does nothing.
  Future<CaveResult?> Function(CaveRequest request)? onEnter;
}
