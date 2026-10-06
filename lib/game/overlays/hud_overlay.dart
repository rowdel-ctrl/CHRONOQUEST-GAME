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
                style: GoogleFonts.poppins(
                  color: Colors.yellowAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
              const SizedBox(height: 8),
              // Health bar
              GameProgressBar(
                value: boss.health / boss.maxHealth,
                fillColor: boss.health > 2 ? AppColors.danger : Colors.orange,
                backgroundColor: Colors.grey.shade800,
                height: 18,
                segments: boss.maxHealth,
              ),
              const SizedBox(height: 4),
              Text(
                '${boss.health}/${boss.maxHealth}',
                style: GoogleFonts.poppins(
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
