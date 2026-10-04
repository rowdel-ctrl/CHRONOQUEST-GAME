import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../game/chrono_game.dart';
import '../../core/combat_constants.dart';
import '../../game/answer_point_handler.dart';
import '../../game/quiz_handler.dart';
import '../../game/overlays/gate_locked_overlay.dart';
import '../../game/overlays/hud_overlay.dart';
import '../../game/overlays/question_overlay.dart';
import '../../game/overlays/pause_overlay.dart';
import '../../models/control_scheme.dart';
import '../../providers/control_scheme_provider.dart';
import '../../providers/game_provider.dart';
import '../../services/storage_service.dart';
import 'level_complete_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String eraId;
  final int level;
  const GameScreen({super.key, required this.eraId, required this.level});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late ChronoGame game;

  @override
  void initState() {
    super.initState();
    final gameState = ref.read(gameProvider);

    game = ChronoGame()
      ..currentEra = widget.eraId
      ..currentLevel = widget.level
      ..selectedCharacterId = gameState.selectedCharacterId
      ..playerPowerUps = gameState.powerUps
      ..hearts = gameState.hearts.count
      ..controlScheme = ref.read(controlSchemeProvider)
      // Section 4's sanctioned tutorial freebie. Set here rather than in
      // ChronoGame's field initialiser, which runs before currentLevel is
      // assigned and so could not see the level number.
      ..kaalaman = widget.level <= CombatConstants.kaalamanTutorialLevels
          ? CombatConstants.kaalamanTutorialStart
          : CombatConstants.kaalamanStart;

    // Every heart lost in-level spends from the same persistent pool shown
    // on the menu screens (GAMEPLAY-V2.md section 8 — one shared pool, not
    // a level-local counter).
    game.onHeartLost = () => ref.read(gameProvider.notifier).loseHeart();

    // Set callbacks for navigation
    game.onLevelComplete = (score, correct, total, answers) {
      // Save level completion
      final percentage = total > 0 ? (correct / total * 100).round() : 0;
      final stars = percentage >= 90
          ? 3
          : percentage >= 70
              ? 2
              : 1;
      StorageService.saveLevelCompleted(widget.eraId, widget.level, stars);

      // Award powerup at milestones
      ref.read(gameProvider.notifier).awardPowerUp(widget.level);

      // Navigate, carrying the attempt's real result so the completion
      // screen reports what the player actually scored.
      if (widget.level == getEraById(widget.eraId).levels.length) {
        context.go('/era-complete/${widget.eraId}');
      } else {
        context.go(
          '/level-complete/${widget.eraId}/${widget.level}',
          extra: LevelCompleteResult(
            score: score,
            correct: correct,
            total: total,
          ),
        );
      }
    };

    game.onLevelFailed = () {
      // The pool is already at 0 by the time this fires — every hit that
      // got here already went through onHeartLost above.
      context.go('/level-failed/${widget.eraId}/${widget.level}');
    };
  }

  /// Leaves the level from the pause menu.
  ///
  /// Navigates from the screen's own context rather than the one Flame
  /// hands the overlay builder: that context belongs to GameWidget, and
  /// guarding it with `context.mounted` meant any moment it wasn't mounted
  /// turned quitting into a silent no-op that left the student in the level
  /// with no way out. This element lives exactly as long as the route does.
  void _quitToLevelSelect() {
    // Cleared first — a frame landing between here and the route teardown
    // could otherwise fire level-complete/failed and navigate over the top
    // of this.
    game.onLevelComplete = null;
    game.onLevelFailed = null;
    if (!mounted) return;
    // Resume before leaving. A paused Flame engine stops stepping its own
    // render loop, so the GameWidget held a frozen frame while the route
    // tore down around it — read on device as "the screen freezes and I have
    // to wait". Nothing can navigate over this any more: both callbacks are
    // already null.
    game.resumeEngine();
    context.go('/level-select/${widget.eraId}');
  }

  @override
  void dispose() {
    // The era BGM loops forever once started, and nothing else in the app
    // stops it — without this it would keep playing over the menus after the
    // level is completed, failed or quit.
    //
    // Deliberately unawaited and scheduled off this frame. `stopBgm()` is an
    // async platform-channel call, and on the first level of a session the
    // audio plugin is still initialising, so letting it run inside dispose()
    // stalled the very frame that should have painted the next route — the
    // "freezes on the first try" half of the same playtest report.
    final audio = game.audioService;
    Future<void>.microtask(audio.stopBgm);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A student can open Settings from the pause menu and change their
    // controls; the level swaps them in as soon as the choice is made. The
    // engine is paused, so the new buttons appear on the first frame after
    // Ituloy. `isLoaded` guards the brief window before the level has built
    // its input.
    ref.listen<ControlScheme>(controlSchemeProvider, (_, next) {
      if (game.isLoaded) game.gameInput.setScheme(next);
    });

    return Scaffold(
      backgroundColor: Colors.black,
      // No wrapping GestureDetector — jump/attack are now the on-screen
      // HudButtonComponents and movement is the joystick (game_input.dart),
      // both driven through Flame's own gesture handling on GameWidget. A
      // Flutter GestureDetector layered on top of it would compete with
      // those components' TapCallbacks/DragCallbacks for the same touches.
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Pillarbox on windows wider than GameConstants.maxAspectRatio so
          // the scrolling background (which tiles horizontally past its own
          // art's aspect ratio) never shows a visible seam — see that
          // constant's doc comment for the math.
          final maxWidth =
              constraints.maxHeight * GameConstants.maxAspectRatio;
          final width = constraints.maxWidth < maxWidth
              ? constraints.maxWidth
              : maxWidth;
          return Center(
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: GameWidget(
                game: game,
                overlayBuilderMap: {
                  'HudOverlay': (context, game) =>
                      HudOverlayWidget(game: game as ChronoGame),
                  'QuestionOverlay': (context, chronoGame) {
                    final g = chronoGame as ChronoGame;
                    // Artifacts and gates resolve their own way (claim,
                    // charges, retry, crumble); boss questions keep the
                    // original path, which is bound by Section 12's frozen
                    // POST payload.
                    final fromAnswerPoint = g.activeArtifact != null;
                    return QuestionOverlayWidget(
                      game: g,
                      onAnswer: fromAnswerPoint
                          ? g.handleAnswerPointAnswer
                          : g.handleAnswer,
                    );
                  },
                  'BossHealthOverlay': (context, game) =>
                      BossHealthOverlayWidget(game: game as ChronoGame),
                  'GateLockedOverlay': (context, game) =>
                      GateLockedOverlayWidget(game: game as ChronoGame),
                  'PauseOverlay': (context, game) => PauseOverlayWidget(
                        game: game as ChronoGame,
                        onQuit: _quitToLevelSelect,
                        // Opens over the paused level; Back returns to the
                        // pause menu, which is still showing underneath.
                        onSettings: () => context.push('/settings'),
                      ),
                },
                initialActiveOverlays: const ['HudOverlay'],
                loadingBuilder: (context) => Container(
                  color: Colors.black,
                  child: const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFFD4AF37)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
