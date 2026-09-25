import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/game_ui.dart';

/// What the player actually scored on the attempt that just ended.
///
/// [ChronoGame] already computes all of this and hands it to its
/// `onLevelComplete` callback; this carries it the rest of the way to the
/// screen (via GoRouter's `extra`) instead of the screen inventing numbers.
class LevelCompleteResult {
  /// Final in-game score, including the speed and perfect-level bonuses the
  /// game has already applied.
  final int score;
  final int correct;
  final int total;

  const LevelCompleteResult({
    required this.score,
    required this.correct,
    required this.total,
  });

  /// Used when this screen is reached without a result payload — a deep link
  /// or a hot restart, never a finished level. Shows an honest zero rather
  /// than a plausible-looking guess.
  static const empty = LevelCompleteResult(score: 0, correct: 0, total: 0);
}

class LevelCompleteScreen extends StatefulWidget {
  final String eraId;
  final int level;
  final LevelCompleteResult result;
  const LevelCompleteScreen({
    super.key,
    required this.eraId,
    required this.level,
    required this.result,
  });

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  int get _correct => widget.result.correct;
  int get _total => widget.result.total;
  int get _percentage => _total > 0 ? (_correct / _total * 100).round() : 0;
  int get _stars => _percentage >= 90 ? 3 : _percentage >= 70 ? 2 : 1;

  /// The score the game actually accumulated — not a re-derivation from the
  /// question count, which would silently drop the speed bonus.
  int get _points => widget.result.score;

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
      body: GameBackdrop(
        baseColor: AppColors.background,
        child: SafeArea(
          child: Center(
            // SingleChildScrollView fixes the overflow bug — this card's
            // content (badge + stars + score + points + era + optional
            // powerup badge + button) could exceed a short landscape
            // phone's height and push the SUSUNOD button off-screen.
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GamePanel(
                  color: AppColors.surface,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  borderColor: AppColors.accent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "Level Complete" header
                        GameBadge(
                          text: 'LEVEL ${widget.level} TAPOS!',
                          color: AppColors.accent,
                          fontSize: 11,
                        ),
                        const SizedBox(height: 18),

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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  child: Transform.scale(
                                    scale: show ? progress : 0.5,
                                    child: Icon(
                                      show ? Icons.star : Icons.star_border,
                                      color: show
                                          ? AppColors.accent
                                          : AppColors.textMuted,
                                      size: 40,
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Score
                        Text(
                          '$_correct/$_total TAMA',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            height: 1.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Points earned
                        GameBadge(
                          text: '+$_points PUNTOS',
                          color: AppColors.success,
                          textColor: Colors.white,
                          fontSize: 10,
                        ),
                        const SizedBox(height: 10),

                        // Era info
                        Text(
                          era.name,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),

                        // Powerup earned indicator
                        if (widget.level == 3 || widget.level == 7)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: GamePanel(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderWidth: 2,
                              shadowOffset: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.card_giftcard,
                                      color: AppColors.accent, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getPowerupName(widget.level),
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 22),

                        // Next button
                        GameButton(
                          label: 'SUSUNOD',
                          width: double.infinity,
                          onPressed: () {
                            context.go('/level-select/${widget.eraId}');
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
}