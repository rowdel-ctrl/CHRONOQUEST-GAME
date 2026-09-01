import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/game_ui.dart';

class LevelFailedScreen extends StatelessWidget {
  final String eraId;
  final int level;
  const LevelFailedScreen({
    super.key,
    required this.eraId,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackdrop(
        baseColor: AppColors.background,
        child: SafeArea(
          child: Center(
            // SingleChildScrollView is the actual bug fix here — this
            // screen has two stacked buttons at the bottom, and without a
            // scroll view, short landscape phones would push "BUMALIK SA
            // LEVEL SELECT" off the bottom of the visible screen entirely.
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: GamePanel(
                color: AppColors.surface,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Failed icon
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.danger,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: AppColors.danger,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        'SUBUKAN MULI!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          height: 1.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Level $level — Naubusan ng puso',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Hearts display (all empty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (i) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.favorite_border,
                              color: AppColors.danger,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Hint / encouragement
                      GamePanel(
                        color: AppColors.surfaceAlt,
                        borderWidth: 2,
                        shadowOffset: 0,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb_outline,
                                color: AppColors.warning, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tip: Basahin muli ang kasaysayan bago '
                                'subukan ulit. Makakatulong ito sa '
                                'pagsagot!',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Retry button
                      GameButton(
                        label: 'ULIT',
                        icon: Icons.refresh,
                        color: AppColors.accent,
                        width: double.infinity,
                        onPressed: () {
                          context.go('/game/$eraId/$level');
                        },
                      ),
                      const SizedBox(height: 10),

                      // Back to level select
                      GameButton(
                        label: 'BUMALIK',
                        icon: Icons.arrow_back,
                        color: AppColors.surfaceAlt,
                        textColor: AppColors.textSecondary,
                        width: double.infinity,
                        onPressed: () {
                          context.go('/level-select/$eraId');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}