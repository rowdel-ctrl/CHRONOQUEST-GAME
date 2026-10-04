import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/game_ui.dart';
import '../chrono_game.dart';

/// Pause menu overlay: resume, open settings, or quit.
///
/// Ituloy has the full width and Settings and Umalis share the row beneath
/// it. Three stacked buttons made the panel as tall as a sideways phone's
/// whole screen (about 360), so the panel stays compact instead.
class PauseOverlayWidget extends StatelessWidget {
  final ChronoGame game;
  final VoidCallback onQuit;

  /// Opens Settings over the paused level. Null hides the button, which is
  /// how the overlay behaves wherever there is no router to open it with.
  final VoidCallback? onSettings;
  const PauseOverlayWidget(
      {super.key, required this.game, required this.onQuit, this.onSettings});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Block taps
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: GamePanel(
              color: AppColors.surface,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.pause,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'PAUSE',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          height: 1.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Resume button
                  GameButton(
                    label: 'ITULOY',
                    icon: Icons.play_arrow,
                    color: AppColors.success,
                    textColor: Colors.white,
                    width: 280,
                    onPressed: () {
                      game.overlays.remove('PauseOverlay');
                      game.resumeEngine();
                    },
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: 280,
                    child: Row(
                      children: [
                        if (onSettings != null) ...[
                          Expanded(
                            child: GameButton(
                              label: 'SETTINGS',
                              icon: Icons.settings,
                              color: AppColors.surfaceAlt,
                              textColor: AppColors.textPrimary,
                              fontSize: 8,
                              minHeight: 48,
                              horizontalPadding: 10,
                              onPressed: onSettings,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: GameButton(
                            label: 'UMALIS',
                            icon: Icons.exit_to_app,
                            color: AppColors.surfaceAlt,
                            textColor: AppColors.danger,
                            fontSize: 8,
                            minHeight: 48,
                            horizontalPadding: 10,
                            onPressed: () => _confirmQuit(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmQuit(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          side: BorderSide(color: AppColors.primaryDark, width: 3),
        ),
        title: Text(
          'Umalis sa Level?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Mawawala ang iyong progress sa level na ito kung aalis ka ngayon.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Kanselahin',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              game.overlays.remove('PauseOverlay');
              // Deliberately does NOT resume the engine: this level is being
              // torn down, and resuming restarts the game loop immediately,
              // so frames run between here and the route actually changing.
              // Those frames can reach levelComplete()/showLevelFailed(),
              // whose callbacks navigate somewhere else on top of this quit.
              onQuit();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(
              'Umalis',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
