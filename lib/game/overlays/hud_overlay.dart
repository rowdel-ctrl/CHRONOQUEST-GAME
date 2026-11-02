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
        if (boss == null || boss.maxHealth <= 0) return const SizedBox.shrink();

        // Top middle, between the hearts on the left and the score and pause on the right.
        // Low on the screen it covered the boss's head and the student.
        final screenWidth = MediaQuery.sizeOf(context).width;
        final barWidth = (screenWidth - 2 * 215).clamp(200.0, 520.0);
        return Positioned.fill(child: IgnorePointer(child: Stack(children: [
          if (boss.scrollSide != 0) _scrollArrow(boss.scrollSide),
          Positioned(
          top: 10,
          left: 40,
          right: 40,
          child: Column(
            children: [
              SizedBox(
                width: barWidth,
                child: GameProgressBar(
                  value: boss.health / boss.maxHealth,
                  fillColor: boss.health > (boss.maxHealth * 0.2).ceil() ? AppColors.danger : Colors.orange,
                  backgroundColor: Colors.grey.shade800,
                  height: 18,
                  segments: boss.maxHealth,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tamang sagot: ${boss.maxHealth - boss.health}/${boss.maxHealth}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  height: 1.4,
                  shadows: const [Shadow(blurRadius: 3, color: Colors.black)],
                ),
              ),
              Text(
                boss.banner ?? boss.askTag ?? _getBossDialogue(game.currentEra),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: boss.banner != null || boss.askTag != null ? Colors.orangeAccent : Colors.yellowAccent,
                  fontSize: boss.banner != null ? 20 : (boss.askTag != null ? 17 : 15),
                  fontWeight: FontWeight.bold,
                  shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
            ],
          ),
          ),
        ])));
      },
    );
  }

  /// Points at the scroll while it is off screen: [side] is -1 for left, 1 for right.
  Widget _scrollArrow(int side) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: side < 0 ? 10 : null,
      right: side > 0 ? 10 : null,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (side < 0) const Icon(Icons.arrow_back_ios_new, color: Colors.amber, size: 22),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.menu_book, color: Colors.amber, size: 22),
              ),
              if (side > 0) const Icon(Icons.arrow_forward_ios, color: Colors.amber, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  String _getBossDialogue(String era) {
    final eraData = getEraById(era);
    return '"${eraData.bossDialogue}"';
  }
}
