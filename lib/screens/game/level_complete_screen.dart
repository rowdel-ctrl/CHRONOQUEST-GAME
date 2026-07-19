import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';

class LevelCompleteScreen extends StatefulWidget {
  final String eraId;
  final int level;
  const LevelCompleteScreen({
    super.key,
    required this.eraId,
    required this.level,
  });

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // These would come from game state in a real scenario
  int get _correct => 7 + (widget.level % 3);
  int get _total => 10;
  int get _percentage => (_correct / _total * 100).round();
  int get _stars => _percentage >= 90 ? 3 : _percentage >= 70 ? 2 : 1;
  int get _points => _correct * 10 + (_percentage >= 90 ? 50 : 0);

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _starController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final era = getEraById(widget.eraId);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFD4AF37).withValues(alpha: 0.3),
              _getEraColor(widget.eraId).withValues(alpha: 0.6),
              Colors.black87,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "Level Complete" header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'LEVEL ${widget.level} TAPOS!',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stars animation
                    AnimatedBuilder(
                      animation: _starController,
                      builder: (context, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            final delay = i * 0.3;
                            final progress =
                                ((_starController.value - delay) / 0.4)
                                    .clamp(0.0, 1.0);
                            final show = i < _stars && progress > 0;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Transform.scale(
                                scale: show ? progress : 0.5,
                                child: Icon(
                                  show ? Icons.star : Icons.star_border,
                                  color: show
                                      ? AppColors.accent
                                      : Colors.grey.shade300,
                                  size: 44,
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Score
                    Text(
                      '$_correct/$_total Tama',
                      style: GoogleFonts.sourceSans3(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Points earned
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+$_points puntos',
                        style: GoogleFonts.sourceSans3(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Era info
                    Text(
                      era.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),

                    // Powerup earned indicator
                    if (widget.level == 3 ||
                        widget.level == 7)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.card_giftcard,
                                  color: AppColors.accent, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _getPowerupName(widget.level),
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Next button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.go('/level-select/${widget.eraId}');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'SUSUNOD',
                          style: GoogleFonts.sourceSans3(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
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
      ),
    );
  }

  String _getPowerupName(int level) {
    switch (level) {
      case 3:
        return 'Nakakuha ng 50/50!';
      case 7:
        return 'Nakakuha ng Shield!';
      default:
        return '';
    }
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