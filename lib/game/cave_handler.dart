import 'answer_point_handler.dart';
import 'cave/cave_session.dart';
import 'chrono_game.dart';
import 'components/pipe_component.dart';

/// The level's side of the underground cave: handing the student over to the cave
/// when the pipe is walked onto, and picking the level up again, exactly as it
/// was, when they come back. The cave itself is `cave/cave_game.dart`.
extension CaveHandler on ChronoGame {
  /// True while the level's last artifact is the one in the cave: the student has
  /// answered everything on the road and the way on is down the pipe.
  bool get pipeIsTheWay =>
      cave.pipe != null &&
      !cave.done &&
      !cave.away &&
      artifactsTotal > 0 &&
      artifactsRemaining == 1;

  /// How far, in world units, the student still has to walk to the pipe, from
  /// their right edge to the pipe's middle. Null when the pipe is not the way.
  double? pipeDistanceUnits() {
    final pipe = cave.pipe;
    if (!pipeIsTheWay || pipe == null) return null;
    final left = pipe.centerX - (player.position.x + player.size.x / 2);
    final abs = left < 0 ? -left : left;
    return abs;
  }

  /// The student has stood on the pipe long enough: hold the level still and show
  /// the cave. Nothing here runs again until the cave is over and [finishCave]
  /// has put the level back to work.
  Future<void> enterCavePipe(PipeComponent pipe) async {
    if (cave.away || cave.done || levelEnded || questionShowing || gateReveal != null) {
      return;
    }
    final show = cave.onEnter;
    if (show == null) return; // a bare game: the pipe does nothing
    cave.away = true;
    audioService.playTeleport();
    pauseEngine();
    CaveResult? result;
    try {
      result = await show(CaveRequest(
        level: this,
        pipeX: _frac((pipe.centerX - cameraLeftEdgeX) / size.x),
        pipeY: _frac((pipe.position.y) / size.y),
      ));
    } catch (_) {
      result = null; // the cave could not be shown: carry on as normal
    }
    finishCave(result);
  }

  /// The student is back (or the cave could not be shown): what they did down there
  /// joins the level, and the level carries on from the exact moment it was held.
  void finishCave(CaveResult? result) {
    if (!cave.away) return;
    cave.away = false;
    final pipe = cave.pipe;
    if (result != null) {
      hearts = result.hearts;
      kaalaman = result.kaalaman;
      shieldActive = result.shieldActive;
      playerCoins += result.coins;
      score += result.score;
      answers.addAll(result.answers);
      if (result.answered) {
        artifactsAnswered++;
        if (result.claimed) artifactsClaimed++;
        cave.done = true;
        pipe?.done = true;
      }
    }
    pipe?.settleStudent();
    if (result != null && result.failed) {
      showLevelFailed();
      notifyState();
      return;
    }
    if (isMounted && !levelEnded) {
      // The cave's answer may have been the last one: the gate opens, with the
      // same trip as for any last artifact.
      if (cave.done && canPassEndGate) startGateReveal();
      resumeEngine();
    }
    notifyState();
  }

  double _frac(double v) => v.isFinite ? v.clamp(0.0, 1.0) : 0.5;
}
