import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/badge_defs.dart';
import '../../providers/game_provider.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/living_backdrop.dart';
import '../../widgets/new_badge.dart';

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

  /// The badges this attempt earned (already held, with their coin gift paid). They
  /// are announced on the next screen.
  final List<EarnedBadge> badges;

  /// The free power-ups this attempt gave (one at random for a level with no wrong
  /// answer, one of each for a boss), already in the wallet.
  final List<PowerUpKind> powerUps;

  const LevelCompleteResult({
    required this.score,
    required this.correct,
    required this.total,
    this.coins = 0,
    this.badges = const [],
    this.powerUps = const [],
  });

  /// Used when this screen is reached without a result payload — a deep link
  /// or a hot restart, never a finished level. Shows an honest zero rather
  /// than a plausible-looking guess.
  static const empty = LevelCompleteResult(score: 0, correct: 0, total: 0);
}

/// The end of a level: the stars are the one big thing, on the dark with light
/// behind them that matches the result (rays for three stars, a soft glow for two,
/// none for one, so a low score is calm rather than scolding). Under them the
/// score as x/y and one line of what was earned, then one gold button.
class LevelCompleteScreen extends StatefulWidget {
  static const Key titleKey = Key('level_complete_title');
  static const Key scoreKey = Key('level_complete_score');
  static const Key pointsKey = Key('level_complete_points');
  static const Key coinsKey = Key('level_complete_coins');
  static const Key giftKey = Key('level_complete_gift');
  static const Key freeKey = Key('level_complete_free');
  static const Key goKey = Key('level_complete_go');
  static const Key backdropKey = Key('level_complete_backdrop');

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
  int get _stars => _percentage >= 90
      ? 3
      : _percentage >= 70
          ? 2
          : 1;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The phone removes animations: everything is simply there.
    if (!motionAllowed(context)) {
      _starController.value = 1;
      _scaleController.value = 1;
    }
  }

  @override
  void dispose() {
    _starController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackdrop(
        baseColor: AppColors.background,
        child: Stack(
          children: [
            // The light matches the result. One star gets none.
            if (_stars >= 2)
              Positioned.fill(
                child: LivingBackdrop(
                  key: LevelCompleteScreen.backdropKey,
                  center: const Offset(0.5, 0.4),
                  fireflies: 0,
                  rays: _stars == 3,
                ),
              ),
            SafeArea(
              child: Center(
                // Shrinks a little on a screen too short for it, rather than scrolling.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      child: _content(),
                    ),
                  ),
                ),
              ),
            ),
            // New badges slide in over the top for a few seconds.
            if (widget.result.badges.isNotEmpty)
              Positioned.fill(
                  child: NewBadgeStrip(badges: widget.result.badges)),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'LEVEL ${widget.level} TAPOS!',
          key: LevelCompleteScreen.titleKey,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
            letterSpacing: 0.7,
            shadows: const [
              Shadow(color: AppColors.primaryDark, offset: Offset(0, 3)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _stars3(),
        if (_total > 0) ...[
          const SizedBox(height: 4),
          Text(
            '$_correct/$_total',
            key: LevelCompleteScreen.scoreKey,
            style: GoogleFonts.poppins(
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.bold,
              color: AppColors.surface,
            ),
          ),
        ],
        const SizedBox(height: 6),
        _earned(),
        if (widget.result.powerUps.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            key: LevelCompleteScreen.freeKey,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.card_giftcard,
                  color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Libre: ${widget.result.powerUps.map(powerUpTitle).join(', ')}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.surface,
                ),
              ),
            ],
          ),
        ],
        if (widget.level == 3 || widget.level == 7) ...[
          const SizedBox(height: 8),
          Row(
            key: LevelCompleteScreen.giftKey,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.card_giftcard,
                  color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                _getPowerupName(widget.level),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.surface,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        GameButton(
          key: LevelCompleteScreen.goKey,
          label: 'SUSUNOD',
          width: 220,
          onPressed: () => context.go('/level-select/${widget.eraId}'),
        ),
      ],
    );
  }

  /// Three stars in an arc, the middle one the biggest, each popping in in turn.
  Widget _stars3() {
    const sizes = [56.0, 72.0, 56.0];
    const turns = [-0.17, 0.0, 0.17];
    return SizedBox(
      height: 82,
      child: AnimatedBuilder(
        animation: _starController,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final delay = i * 0.3;
              final progress =
                  ((_starController.value - delay) / 0.4).clamp(0.0, 1.0);
              final filled = i < _stars;
              final pop = Curves.easeOutBack.transform(progress);
              return Padding(
                padding: EdgeInsets.only(
                    left: i == 0 ? 0 : 4, bottom: i == 1 ? 0 : 2),
                child: Transform.rotate(
                  angle: turns[i],
                  child: Transform.scale(
                    scale: filled ? (progress > 0 ? pop : 0.2) : 1,
                    child: Opacity(
                      opacity: filled ? 1 : 0.55,
                      child: Image.asset(
                        filled
                            ? 'assets/ui/star_full.png'
                            : 'assets/ui/star_empty.png',
                        width: sizes[i],
                        height: sizes[i],
                        // Without this an image is never drawn bigger than it is.
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        errorBuilder: (_, __, ___) => Icon(
                          filled ? Icons.star : Icons.star_border,
                          color:
                              filled ? AppColors.accent : AppColors.textMuted,
                          size: sizes[i],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  /// One quiet line: the points, and the coins when there are any.
  Widget _earned() {
    final style = GoogleFonts.poppins(
      fontSize: 18,
      height: 1.2,
      fontWeight: FontWeight.bold,
      color: AppColors.accent,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/ui/star_full.png',
            width: 18, height: 18, filterQuality: FilterQuality.none),
        const SizedBox(width: 5),
        Text('+$_points', key: LevelCompleteScreen.pointsKey, style: style),
        if (widget.result.coins > 0) ...[
          Container(
            width: 2,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: const Color(0xFF4A3A5E),
          ),
          Row(
            key: LevelCompleteScreen.coinsKey,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/collectibles/coin.png',
                  width: 18, height: 18),
              const SizedBox(width: 5),
              Text('+${widget.result.coins}', style: style),
            ],
          ),
        ],
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
