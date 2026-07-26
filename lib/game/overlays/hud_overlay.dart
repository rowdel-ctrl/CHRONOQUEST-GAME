import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../chrono_game.dart';

/// HUD overlay — shows hearts, level, score over Flame canvas.
class HudOverlayWidget extends StatelessWidget {
  final ChronoGame game;
  const HudOverlayWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: game,
        builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Hearts
            Row(
              children: List.generate(
                GameConstants.livesPerLevel,
                (i) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Image.asset(
                    i < game.lives
                        ? 'assets/ui/heart_full.png'
                        : 'assets/ui/heart_empty.png',
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Level indicator
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                game.currentLevel == 10
                    ? 'BOSS'
                    : 'Level ${game.currentLevel}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            // Score
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Image.asset('assets/ui/star_full.png', width: 18, height: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${game.score}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Coins
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Image.asset('assets/collectibles/coin.png',
                      width: 18, height: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${game.playerCoins}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Pause button
            Semantics(
              button: true,
              label: 'I-pause ang laro',
              child: GestureDetector(
                onTap: () {
                  game.pauseEngine();
                  game.overlays.add('PauseOverlay');
                },
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pause,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// Boss health bar overlay shown during Level 10 boss fight.
class BossHealthOverlayWidget extends StatelessWidget {
  final ChronoGame game;
  const BossHealthOverlayWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final boss = game.boss;
        if (boss == null) return const SizedBox.shrink();

        return Positioned(
      bottom: 80,
      left: 40,
      right: 40,
      child: Column(
        children: [
          Text(
            _getBossDialogue(game.currentEra),
            style: const TextStyle(
              color: Colors.yellowAccent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 4, color: Colors.black)],
            ),
          ),
          const SizedBox(height: 8),
          // Health bar
          Container(
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: boss.health / boss.maxHealth,
                backgroundColor: Colors.grey.shade800,
                valueColor: AlwaysStoppedAnimation<Color>(
                  boss.health > 2 ? AppColors.danger : Colors.orange,
                ),
                minHeight: 16,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${boss.health}/${boss.maxHealth}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  String _getBossDialogue(String era) {
    final eraData = getEraById(era);
    return '"${eraData.bossDialogue}"';
  }
}