import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/game_ui.dart';
import '../chrono_game.dart';
import 'gate_hud.dart';
import 'hud_widgets.dart';
import 'level_progress_bar.dart';

/// HUD overlay — health and Kaalaman bars, gate/artifact progress, score and
/// coins over the Flame canvas.
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
            // Under the artifact counter: once every artifact is answered, how
            // far the gate is (gate_hud.dart). Ignores touches so it can never
            // get in the way of the controls.
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 46),
                child: IgnorePointer(child: GateHud(game: game)),
              ),
            ),
            // How far along the level the student is. Between the joystick and
            // the buttons; not on a boss level, which has no distance to cover.
            if (!game.isBossLevel)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: IgnorePointer(child: LevelProgressBar(game: game)),
                ),
              ),
            // The Shield, in the boss fight: on the right edge so it can be switched on any
            // time (walking to a rune, in a minion wave, or while a question is open).
            if (game.bossPhase)
              Align(
                alignment: const Alignment(1, 0.2),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: BossShieldButton(game: game),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HudStatusBars(game: game),
                  const Spacer(),
                  HudProgressPill(game: game),
                  const Spacer(),
                  HudStatsPanel(game: game),
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
          ],
        ),
      ),
    );
  }
}

/// The Shield button of the boss fight: shows how many are left, lights up while the bubble is on,
/// and switches it on with one tap.
class BossShieldButton extends StatelessWidget {
  static const shieldKey = ValueKey('boss-shield');

  final ChronoGame game;
  const BossShieldButton({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final on = game.shieldActive;
    final count = game.playerPowerUps.shield;
    final usable = !on && count > 0 && !game.levelEnded;
    return Semantics(
      button: true,
      label: 'Shield',
      child: GestureDetector(
        key: shieldKey,
        onTap: usable ? game.activateShield : null,
        child: Opacity(
          opacity: usable || on ? 1 : 0.45,
          child: Container(
            width: 52,
            height: 58,
            decoration: BoxDecoration(
              color: on ? AppColors.info.withValues(alpha: 0.55) : AppColors.primaryDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: on ? Colors.white : AppColors.accent, width: 2),
              boxShadow: on
                  ? [BoxShadow(color: AppColors.info.withValues(alpha: 0.7), blurRadius: 12)]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield, color: Colors.white, size: 24),
                Text(
                  '×$count',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The boss fight's top strip: the boss's name, its 22-segment health bar and which round is
/// being played ("Tanong 3 ng 22"). The hearts are the normal HUD's. The question card sits
/// just below it (see BossQuestionCard.topInset).
class BossHealthOverlayWidget extends StatelessWidget {
  static const nameKey = ValueKey('boss-name');
  static const roundKey = ValueKey('boss-round');

  final ChronoGame game;
  const BossHealthOverlayWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final boss = game.boss;
        if (boss == null || boss.maxHealth <= 0) return const SizedBox.shrink();

        // Top middle, between the hearts on the left and the score and pause on the right.
        final screenWidth = MediaQuery.sizeOf(context).width;
        final barWidth = (screenWidth - 2 * 215).clamp(180.0, 300.0);
        final shadow = [const Shadow(blurRadius: 3, color: Colors.black)];
        return Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      boss.profile.name,
                      key: nameKey,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        shadows: shadow,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: barWidth,
                      child: GameProgressBar(
                        value: boss.health / boss.maxHealth,
                        fillColor:
                            boss.health > (boss.maxHealth * 0.2).ceil() ? AppColors.danger : Colors.orange,
                        backgroundColor: Colors.grey.shade800,
                        height: 14,
                        segments: boss.maxHealth,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      boss.roundTag,
                      key: roundKey,
                      style: GoogleFonts.poppins(
                        color: Colors.yellowAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        shadows: shadow,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
