import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../game/chrono_game.dart';
import '../../game/overlays/hud_overlay.dart';
import '../../game/overlays/question_overlay.dart';
import '../../game/overlays/pause_overlay.dart';
import '../../providers/game_provider.dart';
import '../../services/storage_service.dart';

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
      ..playerPowerUps = gameState.powerUps;

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

      // Navigate
      if (widget.level == 10) {
        context.go('/era-complete/${widget.eraId}');
      } else {
        context.go('/level-complete/${widget.eraId}/${widget.level}');
      }
    };

    game.onLevelFailed = () {
      context.go('/level-failed/${widget.eraId}/${widget.level}');
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!game.questionShowing) {
            game.onPlayerJump();
          }
        },
        child: GameWidget(
          game: game,
          overlayBuilderMap: {
            'HudOverlay': (context, game) =>
                HudOverlayWidget(game: game as ChronoGame),
            'QuestionOverlay': (context, chronoGame) {
              final g = chronoGame as ChronoGame;
              return QuestionOverlayWidget(
                game: g,
                onAnswer: g.handleAnswer,
              );
            },
            'BossHealthOverlay': (context, game) =>
                BossHealthOverlayWidget(game: game as ChronoGame),
            'PauseOverlay': (context, game) => PauseOverlayWidget(
                  game: game as ChronoGame,
                  onQuit: () {
                    if (context.mounted) {
                      context.go('/level-select/${widget.eraId}');
                    }
                  },
                ),
          },
          initialActiveOverlays: const ['HudOverlay'],
          loadingBuilder: (context) => Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            ),
          ),
        ),
      ),
    );
  }
}
