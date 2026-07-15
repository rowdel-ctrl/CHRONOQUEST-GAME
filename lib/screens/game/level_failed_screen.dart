import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';

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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.danger.withValues(alpha: 0.3),
              _getEraColor(eraId).withValues(alpha: 0.5),
              Colors.black87,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.danger.withValues(alpha: 0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Failed icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      color: AppColors.danger,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'Subukan Muli!',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Level $level — Naubusan ng puso',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),

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
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Hint / encouragement
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: AppColors.warning, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tip: Basahin muli ang kasaysayan bago subukan ulit. '
                            'Makakatulong ito sa pagsagot!',
                            style: GoogleFonts.sourceSans3(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Retry button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.go('/game/$eraId/$level');
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        'ULIT',
                        style: GoogleFonts.sourceSans3(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Back to level select
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.go('/level-select/$eraId');
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('BUMALIK SA LEVEL SELECT'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
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

  Color _getEraColor(String id) {
    switch (id) {
      case 'pre-colonial':
        return const Color(0xFF1B5E20);
      case 'spanish':
        return const Color(0xFF4E342E);
      case 'american':
        return const Color(0xFF0D47A1);
      case 'ww2':
        return const Color(0xFF37474F);
      case 'modern':
        return const Color(0xFF1A237E);
      default:
        return const Color(0xFF4E342E);
    }
  }
}
