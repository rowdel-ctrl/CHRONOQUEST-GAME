import 'dart:async';

import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';

import '../../core/cave_constants.dart';
import '../../core/constants.dart';
import '../../game/cave/cave_game.dart';
import '../../game/cave/cave_session.dart';
import '../../game/answer_point_handler.dart';
import '../../game/chrono_game.dart';
import '../../game/overlays/hud_overlay.dart';
import '../../game/overlays/pause_overlay.dart';
import '../../game/overlays/question_overlay.dart';
import '../../game/quiz_handler.dart';

/// The underground cave, shown on top of the level (which stays where it is, held
/// still, until this screen is popped with a [CaveResult]).
///
/// The screen fades from black into the cave and, when the student has gone up the
/// pipe (or left, or lost the last heart), fades back to the level. Hearts, coins,
/// power-ups and the question supply are the level's own, wired by [CaveGame].
class CaveScreen extends StatefulWidget {
  final CaveRequest request;
  const CaveScreen({super.key, required this.request});

  /// A route that leaves the level showing underneath while the screen fades.
  static Route<CaveResult> route(CaveRequest request) =>
      PageRouteBuilder<CaveResult>(
        opaque: false,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => CaveScreen(request: request),
      );

  @override
  State<CaveScreen> createState() => _CaveScreenState();
}

class _CaveScreenState extends State<CaveScreen>
    with SingleTickerProviderStateMixin {
  late final CaveGame game;

  /// 1 black, 0 the cave.
  late final AnimationController _fade = AnimationController(
    vsync: this,
    value: 1,
    duration:
        Duration(milliseconds: (CaveConstants.fadeSeconds * 1000).round()),
  );

  Timer? _loadWatch;
  bool _begun = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    game = CaveGame(level: widget.request.level)..onFinish = _leave;
    _loadWatch =
        Timer.periodic(const Duration(milliseconds: 50), (_) => _checkReady());
  }

  /// Opens the black once the cave and the hero are loaded.
  void _checkReady() {
    if (!mounted || _begun) return;
    if (!game.isLoaded || !game.player.isLoaded) return;
    _begun = true;
    _loadWatch?.cancel();
    unawaited(_fade.reverse());
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    game.pauseEngine();
    // Read now: the result is what the cave holds the moment the student goes.
    final result = game.result();
    if (mounted) await _fade.forward();
    if (mounted) Navigator.of(context).pop(result);
  }

  /// Android back: the pause menu, or out of it again.
  void _onBack() {
    if (_leaving || !_begun) return;
    if (game.overlays.isActive('PauseOverlay')) {
      game.overlays.remove('PauseOverlay');
      game.resumeEngine();
    } else if (!game.questionShowing) {
      game.pauseEngine();
      game.overlays.add('PauseOverlay');
    }
  }

  @override
  void dispose() {
    _loadWatch?.cancel();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // Pillarbox on very wide windows, exactly as the level does.
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
                        'HudOverlay': (context, g) =>
                            HudOverlayWidget(game: g as ChronoGame),
                        'QuestionOverlay': (context, g) {
                          final c = g as ChronoGame;
                          return QuestionOverlayWidget(
                            game: c,
                            onAnswer: c.activeArtifact != null
                                ? c.handleAnswerPointAnswer
                                : c.handleAnswer,
                          );
                        },
                        'PauseOverlay': (context, g) => PauseOverlayWidget(
                              game: g as ChronoGame,
                              onQuit: _leave,
                            ),
                      },
                      initialActiveOverlays: const ['HudOverlay'],
                      loadingBuilder: (context) =>
                          const ColoredBox(color: Colors.black),
                    ),
                  ),
                );
              },
            ),
            // The fade: black over everything until the cave is ready, and again
            // while the student goes back up.
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _fade,
                builder: (context, _) => ColoredBox(
                  color: Colors.black.withValues(alpha: _fade.value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
