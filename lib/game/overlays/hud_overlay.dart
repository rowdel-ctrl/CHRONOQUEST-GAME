import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/pixel_ui.dart';
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
        builder: (context, _) => Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          width: 26,
                          height: 26,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Level indicator
                  PixelBadge(
                    text: game.currentLevel == 10
                        ? 'BOSS'
                        : 'LVL ${game.currentLevel}',
                    color: AppColors.primary,
                    textColor: Colors.white,
                    fontSize: 10,
                  ),
                  const Spacer(),
                  // Score
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    child: Row(
                      children: [
                        Image.asset('assets/ui/star_full.png',
                            width: 16, height: 16),
                        const SizedBox(width: 5),
                        Text(
                          '${game.score}',
                          style: GoogleFonts.pressStart2p(
                            color: Colors.white,
                            fontSize: 10,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Coins
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    child: Row(
                      children: [
                        Image.asset('assets/collectibles/coin.png',
                            width: 16, height: 16),
                        const SizedBox(width: 5),
                        Text(
                          '${game.playerCoins}',
                          style: GoogleFonts.pressStart2p(
                            color: Colors.white,
                            fontSize: 10,
                            height: 1.4,
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
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.accent, width: 2),
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
            if (!game.hasJumped)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'TAP SCREEN TO JUMP',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
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
                textAlign: TextAlign.center,
                style: GoogleFonts.pixelifySans(
                  color: Colors.yellowAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
              const SizedBox(height: 8),
              // Health bar
              PixelProgressBar(
                value: boss.health / boss.maxHealth,
                fillColor: boss.health > 2 ? AppColors.danger : Colors.orange,
                backgroundColor: Colors.grey.shade800,
                height: 18,
                segments: boss.maxHealth,
              ),
              const SizedBox(height: 4),
              Text(
                '${boss.health}/${boss.maxHealth}',
                style: GoogleFonts.pressStart2p(
                  color: Colors.white,
                  fontSize: 10,
                  height: 1.4,
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
