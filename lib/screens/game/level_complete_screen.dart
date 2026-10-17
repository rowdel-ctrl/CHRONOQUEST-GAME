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

  /// The coins picked up in this attempt, now in the wallet. Zero hides the line.
  final int coins;

  const LevelCompleteResult({
    required this.score,
    required this.correct,
    required this.total,
    this.coins = 0,
  });

  /// Used when this screen is reached without a result payload — a deep link
  /// or a hot restart, never a finished level. Shows an honest zero rather
  /// than a plausible-looking guess.
  static const empty = LevelCompleteResult(score: 0, correct: 0, total: 0);
}

class LevelCompleteScreen extends StatefulWidget {
  static const Key dotsKey = Key('level_complete_dots');
  static const Key coinsKey = Key('level_complete_coins');

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

  /// Cards wider than this lay out in two columns. The game is landscape, where
  /// a one-column card (331 tall, 382 with a power-up) was taller than the
  /// screen and scrolled; two columns come to about 190 (playtest, 2026-10-06).
  static const double twoColumnMinWidth = 520;

  @override
  Widget build(BuildContext context) {
    final era = getEraById(widget.eraId);

    return Scaffold(
      body: GameBackdrop(
        baseColor: AppColors.background,
        child: SafeArea(
          child: Center(
            // Still scrollable as a safety net on a screen shorter than the
            // card, but in two columns that no longer happens on a phone.
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: LayoutBuilder(builder: (context, box) {
                  final wide = box.maxWidth - 40 >= twoColumnMinWidth;
                  return GamePanel(
                    color: AppColors.surface,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: wide
                        ? const EdgeInsets.symmetric(horizontal: 22, vertical: 18)
                        : const EdgeInsets.all(24),
                    borderColor: AppColors.accent,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 516 : 380),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: _resultColumn(compact: true)),
                                const SizedBox(width: 22),
                                Expanded(child: _actionColumn(era, compact: true)),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _resultColumn(compact: false),
                                const SizedBox(height: 10),
                                _actionColumn(era, compact: false),
                              ],
                            ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Badge, stars, the score and one dot per artifact.
  Widget _resultColumn({required bool compact}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GameBadge(
          text: 'LEVEL ${widget.level} TAPOS!',
          color: AppColors.accent,
          fontSize: 11,
        ),
        SizedBox(height: compact ? 8 : 18),
        AnimatedBuilder(
          animation: _starController,
          builder: (context, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final delay = i * 0.3;
                final progress =
                    ((_starController.value - delay) / 0.4).clamp(0.0, 1.0);
                final show = i < _stars && progress > 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Transform.scale(
                    scale: show ? progress : 0.5,
                    child: Icon(
                      show ? Icons.star : Icons.star_border,
                      color: show ? AppColors.accent : AppColors.textMuted,
                      size: compact ? 34 : 40,
                    ),
                  ),
                );
              }),
            );
          },
        ),
        SizedBox(height: compact ? 8 : 16),
        Text(
          '$_correct/$_total TAMA',
          style: GoogleFonts.poppins(
            fontSize: 15,
            height: 1.4,
            color: AppColors.textPrimary,
          ),
        ),
        if (_total > 0 && _total <= maxDots) ...[
          const SizedBox(height: 6),
          _dots(),
        ],
      ],
    );
  }

  /// The most dots drawn; a level with more artifacts than this shows the
  /// number only, so the row cannot outgrow the column.
  static const int maxDots = 12;

  /// One dot per artifact: green for each one answered right, an outline for
  /// each one missed. Says the same as the score, at a glance.
  Widget _dots() {
    return Semantics(
      label: '$_correct sa $_total artifact ang tama',
      child: ExcludeSemantics(
        child: Row(
          key: LevelCompleteScreen.dotsKey,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_total, (i) {
            final right = i < _correct;
            return Container(
              width: 10,
              height: 10,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: right ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: right ? AppColors.primaryDark : AppColors.textMuted,
                  width: 1.5,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Points, the era, the power-up if one was earned, and the button.
  Widget _actionColumn(EraData era, {required bool compact}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GameBadge(
          text: '+$_points PUNTOS',
          color: AppColors.success,
          textColor: Colors.white,
          fontSize: 10,
        ),
        if (widget.result.coins > 0) ...[
          SizedBox(height: compact ? 6 : 8),
          GameBadge(
            key: LevelCompleteScreen.coinsKey,
            text: '+${widget.result.coins} COINS',
            leading: Image.asset(
              'assets/collectibles/coin.png',
              width: 16,
              height: 16,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, __, ___) => const SizedBox(width: 16, height: 16),
            ),
            fontSize: 10,
          ),
        ],
        SizedBox(height: compact ? 6 : 10),
        Text(
          era.name,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
        if (widget.level == 3 || widget.level == 7)
          Padding(
            padding: EdgeInsets.only(top: compact ? 8 : 12),
            child: GamePanel(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderWidth: 2,
              shadowOffset: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.card_giftcard,
                      color: AppColors.accent, size: 18),
                  const SizedBox(width: 8),
                  // Shrinks rather than overflows if a column is narrow.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _getPowerupName(widget.level),
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(height: compact ? 14 : 22),
        GameButton(
          label: 'SUSUNOD',
          width: double.infinity,
          onPressed: () {
            context.go('/level-select/${widget.eraId}');
          },
        ),
      ],
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