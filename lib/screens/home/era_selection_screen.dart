// Destination in your repo: lib/screens/home/era_selection_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/unlock_all_provider.dart';
import '../../widgets/character_portrait.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/menu_top_bar.dart';
import '../../widgets/pixel_icon.dart';

class EraSelectionScreen extends ConsumerStatefulWidget {
  const EraSelectionScreen({super.key});

  @override
  ConsumerState<EraSelectionScreen> createState() => _EraSelectionScreenState();
}

class _EraSelectionScreenState extends ConsumerState<EraSelectionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(progressProvider.notifier).loadProgress();
      // The score changes on the server after every level.
      ref.read(authProvider.notifier).refreshProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final progressState = ref.watch(progressProvider);
    final student = authState.student;
    final gradeLevel = student?.gradeLevel ?? 'grade5';
    final unlockAll = ref.watch(unlockAllProvider);

    // Filter eras by grade level — unless the testing switch is on, which
    // shows all six so every era can be reached.
    final visibleEras = unlockAll
        ? allEras.toList()
        : allEras.where((era) => 'grade${era.grade}' == gradeLevel).toList();

    final visibleEraIds = visibleEras.map((e) => e.id).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backgrounds/bookshelf_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        foregroundDecoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.35),
              Colors.black.withValues(alpha: 0.15),
              Colors.black.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header: the menu's shared top bar. Settings is the right-most
              // chip and Profile sits just left of it.
              MenuTopBar(
                title: 'PILIIN ANG PANAHON',
                onBack: () => context.go('/character-selection'),
                actions: [
                  MenuChip(
                    icon: PixelGlyph.cart,
                    tooltip: 'Tindahan',
                    onTap: () => context.push('/shop'),
                  ),
                  MenuChip(
                    icon: PixelGlyph.profile,
                    tooltip: 'Profile',
                    onTap: () => context.push('/profile'),
                  ),
                  MenuChip(
                    icon: PixelGlyph.gear,
                    tooltip: 'Settings',
                    onTap: () => context.push('/settings'),
                  ),
                ],
              ),

              // Era books shelf
              Expanded(
                child: progressState.isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.accent))
                    : LayoutBuilder(
                        builder: (context, box) => _buildShelf(
                          box,
                          visibleEras,
                          visibleEraIds,
                          unlockAll,
                        ),
                      ),
              ),

              // Student info bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  border: Border(
                    top: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    // The chosen hero, as on the Profile screen.
                    CharacterPortrait(
                      characterId: ref.watch(gameProvider).selectedCharacterId,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      student?.name ?? 'Student',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Spacer(),
                    Image.asset('assets/ui/star_full.png',
                        width: 18, height: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${student?.score ?? 0} pts',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const double _gap = 12;
  static const double _sidePadding = 16;
  static const double _maxCardWidth = 220;
  static const double _fullCardHeight = 200;

  /// Vertical breathing room kept free above and below the cards, so a full
  /// shelf does not touch the title or the student bar.
  static const double _shelfMargin = 20;

  /// Below this height a card cannot carry the tall layout (icon over name
  /// over subtitle), so it switches to the compact one (icon beside text).
  static const double _compactBelow = 150;

  /// Lays the era cards out in the space the screen actually has.
  ///
  /// This used to be a Wrap of fixed 220x200 cards. That is fine for the three
  /// eras of one grade on a tall enough screen, but a landscape phone only has
  /// about 230px between the title and the student bar: three cards need
  /// 684px of width (so they wrapped on a 640px-wide phone), and the six cards
  /// shown by the testing switch wrapped into two 200px rows, pushing the
  /// second row behind the bottom bar. Children drawn outside their parent are
  /// not hit-testable, so those eras could not be tapped at all.
  ///
  /// Cards are now at most three across, and sized from the space available:
  /// full height when everything fits, otherwise a compact card.
  Widget _buildShelf(
    BoxConstraints box,
    List<EraData> visibleEras,
    List<String> visibleEraIds,
    bool unlockAll,
  ) {
    final count = visibleEras.length;
    if (count == 0) return const SizedBox.shrink();

    final columns = math.min(count, 3);
    final rows = (count / columns).ceil();

    final usableWidth = box.maxWidth - _sidePadding * 2;
    // Floored so three cards never add up to a hair more than the row and
    // wrap the last one onto its own line.
    final cardWidth = math
        .min(_maxCardWidth, (usableWidth - _gap * (columns - 1)) / columns)
        .floorToDouble();
    final cardHeight = math.min(
      _fullCardHeight,
      (box.maxHeight - _gap * (rows - 1) - _shelfMargin) / rows,
    );
    final compact = cardHeight < _compactBelow;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: _gap,
          runSpacing: _gap,
          children: visibleEras.asMap().entries.map((entry) {
            final index = entry.key;
            final era = entry.value;
            final progress =
                ref.read(progressProvider.notifier).getEraProgress(era.id);
            final isUnlocked = unlockAll ||
                ref
                    .read(progressProvider.notifier)
                    .isEraUnlocked(era.id, visibleEraIds);

            return SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _EraBook(
                era: era,
                progress: progress,
                isUnlocked: isUnlocked,
                index: index,
                compact: compact,
                onTap: isUnlocked
                    ? () {
                        if (progress.levelsCompleted > 0) {
                          context.go('/level-select/${era.id}');
                        } else {
                          context.go('/background/${era.id}');
                        }
                      }
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EraBook extends StatelessWidget {
  final EraData era;
  final dynamic progress;
  final bool isUnlocked;
  final int index;
  final VoidCallback? onTap;

  /// Icon beside the text, for when the card is too short for the tall layout.
  final bool compact;

  const _EraBook({
    required this.era,
    required this.progress,
    required this.isUnlocked,
    required this.index,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = progress.isCompleted;
    final isInProgress = progress.isInProgress;
    final levelsCompleted = progress.levelsCompleted as int;
    final bookColor = isCompleted
        ? const Color(0xFFD4AF37)
        : isUnlocked
            ? _getEraBookColor(era.id)
            : Colors.grey.shade600;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isUnlocked ? 1.0 : 0.75,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          // Sized by the parent SizedBox (see _buildShelf), not fixed here.
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: bookColor.withValues(alpha: isUnlocked ? 0.82 : 0.60),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnlocked
                  ? bookColor.withValues(alpha: 0.7)
                  : Colors.grey.shade600,
              width: isUnlocked ? 2 : 1.5,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: bookColor.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: compact
              ? _compactBody(
                  bookColor, isCompleted, isInProgress, levelsCompleted)
              : Stack(
                  children: [
                    // Subtle top color band
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: bookColor.withValues(alpha: 0.8),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(13)),
                        ),
                      ),
                    ),

                    // Card body
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            // Icon / status
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: bookColor.withValues(alpha: 0.22),
                                shape: BoxShape.circle,
                              ),
                              child: isCompleted
                                  ? Image.asset('assets/ui/star_full.png',
                                      width: 26, height: 26)
                                  : !isUnlocked
                                      ? Image.asset('assets/ui/lock_icon.png',
                                          width: 22, height: 22)
                                      // White: the card is bookColor, so the
                                      // book in bookColor vanished into it.
                                      : const PixelIcon(PixelGlyph.book,
                                          color: Colors.white, size: 26),
                            ),
                            const SizedBox(height: 8),

                            // Era name
                            Text(
                              era.name,
                              textAlign: TextAlign.center,
                              // Era titles run up to 47 characters.
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Subtitle
                            Text(
                              era.subtitle,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Progress pill pinned to bottom
                    if (isInProgress)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: bookColor.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: bookColor.withValues(alpha: 0.5),
                                width: 1),
                          ),
                          child: Text(
                            '$levelsCompleted/${era.levels.length} levels',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  /// The short card: a thin colour band, then icon beside name and subtitle.
  /// Progress, when there is any, replaces the subtitle line rather than
  /// getting a pill of its own, since there is no room for one.
  Widget _compactBody(
    Color bookColor,
    bool isCompleted,
    bool isInProgress,
    int levelsCompleted,
  ) {
    final Widget icon = isCompleted
        ? Image.asset('assets/ui/star_full.png', width: 20, height: 20)
        : !isUnlocked
            ? Image.asset('assets/ui/lock_icon.png', width: 18, height: 18)
            : const PixelIcon(PixelGlyph.book, color: Colors.white, size: 20);

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: bookColor.withValues(alpha: 0.8),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bookColor.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: icon,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        era.name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isInProgress
                            ? '$levelsCompleted/${era.levels.length} levels'
                            : era.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight:
                              isInProgress ? FontWeight.w600 : FontWeight.w400,
                          color: isInProgress ? Colors.white : Colors.white54,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getEraBookColor(String id) {
    switch (id) {
      case 'pre-colonial':
        return const Color(0xFF2E7D32);
      case 'spanish':
        return const Color(0xFF8B4513);
      case 'nationalism':
        return const Color(0xFF8B4513);
      case 'american':
        return const Color(0xFF1565C0);
      case 'ww2':
        return const Color(0xFF424242);
      case 'modern':
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF8B4513);
    }
  }
}
