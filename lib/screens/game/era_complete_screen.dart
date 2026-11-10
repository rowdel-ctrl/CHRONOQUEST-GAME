// Destination in your repo: lib/screens/game/era_complete_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/badge_defs.dart';
import '../../models/quiz_result.dart';
import '../../providers/game_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/confetti.dart';
import '../../widgets/era_medal.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/living_backdrop.dart';
import '../../widgets/new_badge.dart';
import '../../widgets/pixel_icon.dart';

/// The end of an era: the era's gold medal, "TAPOS!", the two scores (the average
/// of the levels and the boss) and the learning gain between them as small round
/// chips, the coins the boss paid, and one button.
class EraCompleteScreen extends ConsumerStatefulWidget {
  final String eraId;

  /// The coins picked up in the boss fight, now in the wallet. Zero hides the line.
  final int coins;

  /// The badges the boss fight earned. A medal for the boss (or a grade's trophy) gets
  /// a pop-up, anything else a strip across the top.
  final List<EarnedBadge> badges;

  /// The free power-ups the boss gave (one of each), already in the wallet.
  final List<PowerUpKind> powerUps;

  /// Reads the student's results. Tests pass their own; the app asks the server.
  final Future<List<QuizResult>> Function()? loadResults;

  const EraCompleteScreen({
    super.key,
    required this.eraId,
    this.coins = 0,
    this.badges = const [],
    this.powerUps = const [],
    this.loadResults,
  });

  static const coinsKey = Key('era_complete_coins');
  static const powerUpsKey = Key('era_complete_powerups');
  static const medalKey = Key('era_complete_medal');
  static const levelsKey = Key('era_complete_levels');
  static const bossKey = Key('era_complete_boss');
  static const gainKey = Key('era_complete_gain');
  static const goKey = Key('era_complete_go');
  static const noDataKey = Key('era_complete_no_data');
  static const heroKey = Key('era_complete_hero');
  static const defeatedBossKey = Key('era_complete_defeated_boss');

  @override
  ConsumerState<EraCompleteScreen> createState() => _EraCompleteScreenState();
}

class _EraCompleteScreenState extends ConsumerState<EraCompleteScreen> {
  // Baseline is now the average of Levels 1-9 ("pre_test" type results),
  // not a separate cold pre-test. Both are nullable so we can tell the
  // difference between "0%" and "no data yet" instead of faking numbers.
  double? levelsAverage;
  int? postTestScore;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    try {
      final results =
          await (widget.loadResults ?? () => ApiService().getResults())();
      final eraResults = results.where((r) => r.era == widget.eraId).toList();

      final levels = eraResults.where((r) => r.type == 'pre_test');
      final post = eraResults.where((r) => r.type == 'post_test');

      if (!mounted) return;
      setState(() {
        levelsAverage = levels.isNotEmpty
            ? levels
                    .map((r) => r.percentage.toDouble())
                    .reduce((a, b) => a + b) /
                levels.length
            : null;
        postTestScore = post.isNotEmpty ? post.first.percentage : null;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
    _announceBadges();
  }

  /// A new era medal or trophy gets its pop-up once the screen is showing.
  void _announceBadges() {
    if (!hasBossBadge(widget.badges)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showBossBadges(context, widget.badges);
    });
  }

  bool get hasCompleteData => levelsAverage != null && postTestScore != null;

  // Learning Gain = Boss level score - Average(every level before it)
  int get learningGain =>
      hasCompleteData ? (postTestScore! - levelsAverage!.round()) : 0;

  @override
  Widget build(BuildContext context) {
    final era = getEraById(widget.eraId);
    final wide = MediaQuery.sizeOf(context).width >= 560;
    final heroId = ref.watch(gameProvider).selectedCharacterId;

    final medal = Bob(
      height: 6,
      child: EraMedal(
        key: EraCompleteScreen.medalKey,
        number: eraNumberFor(era.id),
        width: wide ? 88 : 104,
      ),
    );
    final words = _words(era);
    Widget centre = Column(
      mainAxisSize: MainAxisSize.min,
      children: [medal, const SizedBox(height: 4), words],
    );
    // A fixed width on a wide screen, so a long era name and the chips wrap.
    if (wide) centre = SizedBox(width: 260, child: centre);

    // The hero cheers on the left and the boss it beat lies on the right, both on
    // one ground line (the bottom of the row).
    final Widget body = wide
        ? Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _WinHero(heroId: heroId, height: 170),
              const SizedBox(width: 20),
              centre,
              const SizedBox(width: 20),
              _DefeatedBoss(bossName: era.bossName, height: 140),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              centre,
              const SizedBox(height: 12),
              // Smaller on a narrow screen, side by side under the button.
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _WinHero(heroId: heroId, height: 100),
                  const SizedBox(width: 16),
                  _DefeatedBoss(bossName: era.bossName, height: 84),
                ],
              ),
            ],
          );

    return Scaffold(
      body: GameBackdrop(
        baseColor: AppColors.background,
        child: Stack(
          children: [
            const Positioned.fill(
              child: LivingBackdrop(),
            ),
            const Positioned.fill(child: Confetti()),
            SafeArea(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accent))
                  : Center(
                      child: wide
                          // Shrinks a little on a screen too short for it.
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: body,
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: body,
                            ),
                    ),
            ),
            // Badges that are not a boss medal slide in over the top.
            if (widget.badges.isNotEmpty &&
                !hasBossBadge(widget.badges) &&
                !isLoading)
              Positioned.fill(child: NewBadgeStrip(badges: widget.badges)),
          ],
        ),
      ),
    );
  }

  Widget _words(EraData era) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'TAPOS!',
          style: GoogleFonts.poppins(
            fontSize: 34,
            height: 1.1,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
            shadows: const [
              Shadow(color: AppColors.primaryDark, offset: Offset(0, 4))
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          era.name,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.surface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            if (hasCompleteData) ...[
              _Stat(
                key: EraCompleteScreen.levelsKey,
                icon: const PixelIcon(PixelGlyph.book,
                    size: 15, color: AppColors.accent),
                text: '${levelsAverage!.round()}%',
              ),
              _Stat(
                key: EraCompleteScreen.bossKey,
                icon: const PixelIcon(PixelGlyph.skull,
                    size: 15, color: AppColors.accent),
                text: '$postTestScore%',
              ),
              _Stat(
                key: EraCompleteScreen.gainKey,
                icon: Icon(
                  learningGain >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color:
                      learningGain >= 10 ? AppColors.success : AppColors.accent,
                ),
                text: '${learningGain >= 0 ? '+' : ''}$learningGain%',
              ),
            ],
            if (widget.powerUps.isNotEmpty)
              _Stat(
                key: EraCompleteScreen.powerUpsKey,
                icon: const Icon(Icons.card_giftcard,
                    size: 16, color: AppColors.accent),
                text: '+${widget.powerUps.length} power-up',
              ),
            if (widget.coins > 0)
              _Stat(
                key: EraCompleteScreen.coinsKey,
                icon: Image.asset('assets/collectibles/coin.png',
                    width: 15, height: 15, filterQuality: FilterQuality.none),
                text: '+${widget.coins}',
              ),
          ],
        ),
        if (!hasCompleteData) ...[
          const SizedBox(height: 8),
          // Honest empty/error state instead of fake numbers.
          Text(
            hasError
                ? 'Hindi ma-load ang scores mo ngayon.'
                : 'Kulang pa ang data sa scores mo.',
            key: EraCompleteScreen.noDataKey,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white60),
          ),
        ],
        const SizedBox(height: 16),
        GameButton(
          key: EraCompleteScreen.goKey,
          label: 'SUSUNOD',
          fontSize: 13,
          width: 230,
          icon: Icons.arrow_forward_rounded,
          onPressed: () => context.go('/era-selection'),
        ),
      ],
    );
  }
}

/// A round chip: a small icon and one number.
class _Stat extends StatelessWidget {
  final Widget icon;
  final String text;
  const _Stat({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 15,
              height: 1.2,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// The hero's win pose, standing on its feet (the picture is a padded canvas with
/// the feet at the bottom middle) with warm light behind it. It rises and settles
/// slowly, unless the phone removes animations.
class _WinHero extends StatelessWidget {
  final String heroId;
  final double height;
  const _WinHero({required this.heroId, required this.height});

  @override
  Widget build(BuildContext context) {
    final glow = height * 1.15;
    return SizedBox(
      key: EraCompleteScreen.heroKey,
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
                      AppColors.accent.withValues(alpha: 0.4),
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

/// The boss the student beat, lying defeated.
class _DefeatedBoss extends StatelessWidget {
  final String bossName;
  final double height;
  const _DefeatedBoss({required this.bossName, required this.height});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.9,
      child: Image.asset(
        'assets/bosses/${bossName}_defeated.png',
        key: EraCompleteScreen.defeatedBossKey,
        height: height,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => SizedBox(height: height),
      ),
    );
  }
}
