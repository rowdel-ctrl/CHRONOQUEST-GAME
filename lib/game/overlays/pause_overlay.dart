import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/pixel_ui.dart';
import '../chrono_game.dart';

/// Pause menu overlay — resume or quit.
class PauseOverlayWidget extends StatelessWidget {
  final ChronoGame game;
  final VoidCallback onQuit;
  const PauseOverlayWidget(
      {super.key, required this.game, required this.onQuit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Block taps
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: PixelPanel(
              color: AppColors.surface,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pause,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PAUSE',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 20,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Resume button
                  PixelButton(
                    label: 'ITULOY',
                    icon: Icons.play_arrow,
                    color: AppColors.success,
                    textColor: Colors.white,
                    width: 220,
                    onPressed: () {
                      game.overlays.remove('PauseOverlay');
                      game.resumeEngine();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Quit button
                  PixelButton(
                    label: 'UMALIS',
                    icon: Icons.exit_to_app,
                    color: AppColors.surfaceAlt,
                    textColor: AppColors.danger,
                    width: 220,
                    onPressed: () => _confirmQuit(context),
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
          style: GoogleFonts.pressStart2p(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Mawawala ang iyong progress sa level na ito kung aalis ka ngayon.',
          style: GoogleFonts.pixelifySans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Kanselahin',
              style: GoogleFonts.pixelifySans(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              game.overlays.remove('PauseOverlay');
              game.resumeEngine();
              onQuit();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(
              'Umalis',
              style: GoogleFonts.pixelifySans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
