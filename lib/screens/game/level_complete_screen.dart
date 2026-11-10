import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/artifact_art.dart';
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

  /// Whether each question was answered right, in the order the artifacts lie in the
  /// level (so artifact 1 is the first entry). Empty when the caller only knows the
  /// count: the screen then lights the first [correct] artifacts.
  final List<bool> answers;

  const LevelCompleteResult({
    required this.score,
    required this.correct,
    required this.total,
    this.coins = 0,
    this.badges = const [],
    this.powerUps = const [],
    this.answers = const [],
  });

  /// Used when this screen is reached without a result payload — a deep link
  /// or a hot restart, never a finished level. Shows an honest zero rather
  /// than a plausible-looking guess.
  static const empty = LevelCompleteResult(score: 0, correct: 0, total: 0);
}

/// The end of a level: the hero cheers in its win pose on the left, with warm light
/// behind it. On the right "LEVEL N TAPOS!", the stars, the level's artifacts (a
/// lit parchment tile for each right answer, a dark shape for each miss), the
/// points and coins, and one gold button. The light behind the whole screen matches
/// the result (a lantern night for two or three stars, none for one, so a low score
/// is calm rather than scolding). On a narrow screen the hero sits above the rest.
class LevelCompleteScreen extends ConsumerStatefulWidget {
  static const Key titleKey = Key('level_complete_title');
  static const Key scoreKey = Key('level_complete_score');
  static const Key pointsKey = Key('level_complete_points');
  static const Key coinsKey = Key('level_complete_coins');
  static const Key giftKey = Key('level_complete_gift');
  static const Key freeKey = Key('level_complete_free');
  static const Key goKey = Key('level_complete_go');
  static const Key backdropKey = Key('level_complete_backdrop');
  static const Key heroKey = Key('level_complete_hero');
  static const Key artifactsKey = Key('level_complete_artifacts');

  /// The tile of artifact [i] (0-based), lit or dark.
  static Key artifactKey(int i) => ValueKey('level_complete_artifact_$i');

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
  ConsumerState<LevelCompleteScreen> createState() =>
      _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends ConsumerState<LevelCompleteScreen>
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

  /// How many artifact tiles to show: one for each question, up to the ten an era
  /// has pictures for. None for a result with no questions.
  int get _slots => _total <= 0 ? 0 : math.min(_total, artifactIconsPerEra);

  /// Whether artifact [i] was won. With the answers in the result it is the real
  /// one; with only a count, the first [_correct] are lit.
  bool _lit(int i) {
    final answers = widget.result.answers;
    if (answers.isNotEmpty) return i < answers.length && answers[i];
    return i < _correct;
  }

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
    final wide = MediaQuery.sizeOf(context).width >= 560;
    final heroId = ref.watch(gameProvider).selectedCharacterId;
    return Scaffold(
      body: GameBackdrop(
        baseColor: AppColors.background,
        child: Stack(
          children: [
            // The light matches the result. One star gets none.
            if (_stars >= 2)
              const Positioned.fill(
                child: LivingBackdrop(
                  key: LevelCompleteScreen.backdropKey,
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
                      child: _content(wide, heroId),
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

  Widget _content(bool wide, String heroId) {
    if (wide) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _WinHero(heroId: heroId, height: 190),
          const SizedBox(width: 12),
          _details(wide: true),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WinHero(heroId: heroId, height: 120),
        const SizedBox(height: 2),
        _details(wide: false),
      ],
    );
  }

  /// Everything but the hero.
  Widget _details({required bool wide}) {
    final align = wide ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final grid = _artifacts(wide ? 46 : 40);
    final hasPowerUp = widget.result.powerUps.isNotEmpty;
    final hasGift = widget.level == 3 || widget.level == 7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        Text(
          'LEVEL ${widget.level} TAPOS!',
          key: LevelCompleteScreen.titleKey,
          style: GoogleFonts.poppins(
            fontSize: wide ? 28 : 24,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
            letterSpacing: 0.7,
            shadows: const [
              Shadow(color: AppColors.primaryDark, offset: Offset(0, 3)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _stars3(compact: wide),
        if (_slots > 0) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MGA ARTIFACT NA NAKUHA',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  letterSpacing: 0.6,
                  color: const Color(0xFFE9D9B0),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$_correct/$_total',
                key: LevelCompleteScreen.scoreKey,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        if (wide)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_slots > 0) grid,
              if (_slots > 0) const SizedBox(width: 16),
              // The earnings sit beside the artifacts. Scaled down as a block when
              // the words are wide, rather than overflowing.
              SizedBox(
                width: 150,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: _earnedColumn(),
                ),
              ),
            ],
          )
        else ...[
          if (_slots > 0) grid,
          const SizedBox(height: 8),
          _earned(),
          if (hasPowerUp) ...[
            const SizedBox(height: 8),
            _freeLine(),
          ],
          if (hasGift) ...[
            const SizedBox(height: 8),
            _giftLine(),
          ],
        ],
        const SizedBox(height: 14),
        GameButton(
          key: LevelCompleteScreen.goKey,
          label: 'SUSUNOD',
          width: wide ? 300 : 220,
          onPressed: () => context.go('/level-select/${widget.eraId}'),
        ),
      ],
    );
  }

  /// The free power-up line, and the level 3 / 7 gift line under it.
  Widget _freeLine() => Row(
        key: LevelCompleteScreen.freeKey,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_giftcard, color: AppColors.accent, size: 18),
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
      );

  Widget _giftLine() => Row(
        key: LevelCompleteScreen.giftKey,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_giftcard, color: AppColors.accent, size: 18),
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
      );

  /// The level's artifacts in two rows of five: a lit parchment tile with the
  /// era's picture for a right answer, a dark shape for a miss.
  Widget _artifacts(double tile) {
    final slots = _slots;
    if (slots == 0) return const SizedBox.shrink();
    Widget row(int from, int to) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = from; i < to; i++) ...[
              if (i > from) const SizedBox(width: 6),
              _ArtifactTile(
                key: LevelCompleteScreen.artifactKey(i),
                asset: artifactAsset(widget.eraId, i + 1),
                number: i + 1,
                lit: _lit(i),
                size: tile,
              ),
            ],
          ],
        );
    return Column(
      key: LevelCompleteScreen.artifactsKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        row(0, math.min(5, slots)),
        if (slots > 5) ...[
          const SizedBox(height: 6),
          row(5, slots),
        ],
      ],
    );
  }

  /// Three stars in an arc, the middle one the biggest, each popping in in turn.
  Widget _stars3({required bool compact}) {
    final sizes = compact ? const [40.0, 52.0, 40.0] : const [56.0, 72.0, 56.0];
    const turns = [-0.17, 0.0, 0.17];
    return SizedBox(
      height: compact ? 60 : 82,
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

  TextStyle get _earnedStyle => GoogleFonts.poppins(
        fontSize: 18,
        height: 1.2,
        fontWeight: FontWeight.bold,
        color: AppColors.accent,
      );

  Widget _pointsRow() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/ui/star_full.png',
              width: 18, height: 18, filterQuality: FilterQuality.none),
          const SizedBox(width: 5),
          Text('+$_points',
              key: LevelCompleteScreen.pointsKey, style: _earnedStyle),
        ],
      );

  Widget _coinsRow() => Row(
        key: LevelCompleteScreen.coinsKey,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/collectibles/coin.png', width: 18, height: 18),
          const SizedBox(width: 5),
          Text('+${widget.result.coins}', style: _earnedStyle),
        ],
      );

  /// Narrow screens: one quiet line, the points and the coins when there are any.
  Widget _earned() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pointsRow(),
        if (widget.result.coins > 0) ...[
          Container(
            width: 2,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: const Color(0xFF4A3A5E),
          ),
          _coinsRow(),
        ],
      ],
    );
  }

  /// Wide screens: the points, the coins and the free gifts, one under another,
  /// to the right of the artifacts.
  Widget _earnedColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pointsRow(),
        if (widget.result.coins > 0) ...[
          const SizedBox(height: 8),
          _coinsRow(),
        ],
        if (widget.result.powerUps.isNotEmpty) ...[
          const SizedBox(height: 8),
          _freeLine(),
        ],
        if (widget.level == 3 || widget.level == 7) ...[
          const SizedBox(height: 8),
          _giftLine(),
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

/// One artifact: a lit parchment tile with the picture, or a dark tile with the
/// picture as a shadow.
class _ArtifactTile extends StatelessWidget {
  final String asset;
  final int number;
  final bool lit;
  final double size;
  const _ArtifactTile({
    super.key,
    required this.asset,
    required this.number,
    required this.lit,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    Widget picture = Image.asset(
      asset,
      width: size - 12,
      height: size - 12,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, __, ___) => const SizedBox(),
    );
    if (!lit) {
      picture = ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0x66000000), BlendMode.srcIn),
        child: picture,
      );
    }
    final edge = lit ? AppColors.primaryDark : const Color(0xFF1B1230);
    return Semantics(
      label:
          lit ? 'Artifact $number, nakuha' : 'Artifact $number, hindi nakuha',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: lit ? AppColors.surface : const Color(0xFF241A36),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: edge, width: 3),
          boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 3))],
        ),
        child: picture,
      ),
    );
  }
}

/// The hero's win pose, standing on its feet (the picture is a padded canvas with
/// the feet at the bottom middle) with warm light behind it. The hero rises and
/// settles slowly, unless the phone removes animations.
class _WinHero extends StatelessWidget {
  final String heroId;
  final double height;
  const _WinHero({required this.heroId, required this.height});

  @override
  Widget build(BuildContext context) {
    final glow = height * 1.15;
    return SizedBox(
      key: LevelCompleteScreen.heroKey,
      width: height * 0.8,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The warm light.
          Positioned.fill(
            child: OverflowBox(
              alignment: Alignment.bottomCenter,
              minWidth: 0,
              minHeight: 0,
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Container(
                width: glow,
                height: glow,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.45),
                      AppColors.accent.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.65],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: OverflowBox(
              alignment: Alignment.bottomCenter,
              minWidth: 0,
              minHeight: 0,
              maxWidth: double.infinity,
              maxHeight: height,
              child: Bob(
                height: 4,
                child: Image.asset(
                  'assets/characters/${heroId}_win.png',
                  height: height,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, __, ___) => SizedBox(height: height),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
