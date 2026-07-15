import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../chrono_game.dart';

/// Pause menu overlay — resume or quit.
class PauseOverlayWidget extends StatelessWidget {
  final ChronoGame game;
  const PauseOverlayWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Block taps
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.symmetric(horizontal: 48),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pause_circle_filled,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'PAUSE',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),

                // Resume button
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      game.overlays.remove('PauseOverlay');
                      game.resumeEngine();
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('ITULOY'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Quit button
                SizedBox(
                  width: 200,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      game.overlays.remove('PauseOverlay');
                      game.resumeEngine();
                      Navigator.of(game.buildContext!).pop();
                    },
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('UMALIS'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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
