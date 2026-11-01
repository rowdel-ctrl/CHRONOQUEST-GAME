// Destination in your repo: lib/screens/home/era_selection_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/era_progress.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/unlock_all_provider.dart';
import '../../services/guest_mode.dart';
import '../../widgets/character_portrait.dart';
import '../../widgets/guest_card.dart';
import '../../widgets/living_backdrop.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/menu_top_bar.dart';
import '../../widgets/new_badge.dart';
import '../../widgets/pixel_icon.dart';
import '../../widgets/update_card.dart';

/// The picture of each era's cards: one of its enemies, standing in the colour.
String eraSprite(String eraId) {
  switch (eraId) {
    case 'pre-colonial':
      return 'assets/enemies/tribal_warrior_1.png';
    case 'spanish':
      return 'assets/enemies/spanish_soldier_1.png';
    case 'nationalism':
      return 'assets/enemies/propaganda_1.png';
    case 'american':
      return 'assets/enemies/american_soldier_1.png';
    case 'ww2':
      return 'assets/enemies/japanese_soldier_1.png';
    case 'modern':
      return 'assets/enemies/corruption_figure_1.png';
    default:
      return 'assets/enemies/spanish_soldier_1.png';
  }
}

/// The colour of each era's card.
Color eraCardColor(String id) {
  switch (id) {
    case 'pre-colonial':
      return const Color(0xFF2E7D32);
    case 'spanish':
      return const Color(0xFF8B4513);
    case 'nationalism':
      return const Color(0xFF6A5ACD);
    case 'american':
      return const Color(0xFF1565C0);
    case 'ww2':
      return const Color(0xFF546E7A);
    case 'modern':
      return const Color(0xFF8E24AA);
    default:
      return const Color(0xFF8B4513);
  }
}

/// Choose an era: a tall card for each, with its number, one of its enemies, its
/// name and a pip for every level. The open one that is next to play glows and
/// stands a little forward with light behind it; a finished one has a gold edge and
/// a star; a locked one is grey with a lock.
class EraSelectionScreen extends ConsumerStatefulWidget {
  const EraSelectionScreen({super.key});

  static Key cardKey(String eraId) => ValueKey('era_card_$eraId');
  static Key pipKey(String eraId, int i) => ValueKey('era_pip_${eraId}_$i');

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
    final isGuest = authState.isGuest;
    // A guest has the first era only, whatever the testing switch says.
    final unlockAll = ref.watch(unlockAllProvider) && !isGuest;

    // Filter eras by grade level — unless the testing switch is on, which
    // shows all six so every era can be reached.
    final visibleEras = unlockAll
        ? allEras.toList()
        : allEras.where((era) => 'grade${era.grade}' == gradeLevel).toList();

    final visibleEraIds = visibleEras.map((e) => e.id).toList();
    final notifier = ref.read(progressProvider.notifier);
    bool unlocked(EraData e) => isGuest
        ? e.id == GuestMode.eraId
        : unlockAll || notifier.isEraUnlocked(e.id, visibleEraIds);
    final guestDone =
        isGuest && notifier.getEraProgress(GuestMode.eraId).isCompleted;
    // The one to play next: the first open era that is not finished.
    final current = visibleEras.indexWhere(
      (e) => unlocked(e) && !notifier.getEraProgress(e.id).isCompleted,
    );
    final columns = math.min(math.max(visibleEras.length, 1), 3);
    final lit = current < 0 ? null : visibleEras[current];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(color: AppColors.background),
        child: Stack(
          children: [
            if (lit != null)
              Positioned.fill(
                child: LivingBackdrop(
                  color: eraCardColor(lit.id),
                  fireflies: 0,
                  center: Offset(((current % columns) + 0.5) / columns, 0.5),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  // Header: the menu's shared top bar. Settings is the right-most
                  // chip and Profile sits just left of it.
                  MenuTopBar(
                    title: 'PANAHON',
                    onBack: () => context.go('/character-selection'),
                    actions: [
                      // After "Later" on the new-version card, until it is installed.
                      const UpdateChip(),
                      // A guest is told so, and has no profile (it lives on the server).
                      if (isGuest) const GuestTag(),
                      MenuChip(
                        icon: PixelGlyph.cart,
                        tooltip: 'Tindahan',
                        onTap: () => context.push('/shop'),
                      ),
                      if (!isGuest)
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

                  // The era cards
                  Expanded(
                    child: progressState.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.accent))
                        : LayoutBuilder(
                            builder: (context, box) => _buildShelf(
                              box,
                              visibleEras,
                              current,
                              unlocked,
                            ),
                          ),
                  ),

                  // Who is playing, and the score: a face and a number.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                    child: Row(
                      children: [
                        CharacterPortrait(
                          characterId:
                              ref.watch(gameProvider).selectedCharacterId,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                        const SizedBox(width: 12),
                        Image.asset('assets/ui/star_full.png',
                            width: 18,
                            height: 18,
                            filterQuality: FilterQuality.none),
                        const SizedBox(width: 5),
                        Text(
                          '${student?.score ?? 0}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // A guest who finished the first era is asked to sign in.
            if (guestDone)
              Positioned.fill(
                child: GuestDoneCard(
                  onSignIn: _guestSignIn,
                  onPlayAgain: _guestPlayAgain,
                ),
              ),
            // One line for badges that came with the update or a new phone.
            const Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: SafeArea(child: Center(child: QuietBadgeNote())),
            ),
            // The new-version card, over everything, when there is one.
            const Positioned.fill(child: UpdateCard()),
          ],
        ),
      ),
    );
  }

  Future<void> _guestSignIn() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  /// A fresh guest: nothing from the last one is kept.
  Future<void> _guestPlayAgain() async {
    final auth = ref.read(authProvider.notifier);
    await auth.logout();
    await auth.startGuest();
    if (mounted) ref.read(progressProvider.notifier).loadProgress();
  }

  static const double _gap = 14;
  static const double _sidePadding = 16;
  static const double _maxCardWidth = 180;
  static const double _fullCardHeight = 200;

  /// Vertical breathing room kept free above and below the cards, so a full
  /// shelf does not touch the title or the student bar. (The open card also
  /// stands 8 forward, so it needs a little more.)
  static const double _shelfMargin = 28;

  /// Below this height a card cannot carry the tall layout (picture over name over
  /// pips), so it switches to the compact one (picture beside the text).
  static const double _compactBelow = 150;

  /// Lays the era cards out in the space the screen actually has.
  ///
  /// Cards are at most three across and sized from the space available: full
  /// height when everything fits, otherwise a compact card. (A landscape phone has
  /// only about 230px between the title and the bottom bar, and the six cards the
  /// testing switch shows must all stay on screen and tappable: children drawn
  /// outside their parent are not hit-testable.)
  Widget _buildShelf(
    BoxConstraints box,
    List<EraData> visibleEras,
    int current,
    bool Function(EraData) unlocked,
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
    final notifier = ref.read(progressProvider.notifier);
    final isGuest = ref.read(authProvider).isGuest;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (var i = 0; i < count; i++)
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _EraCard(
                  key: EraSelectionScreen.cardKey(visibleEras[i].id),
                  era: visibleEras[i],
                  number: eraNumberFor(visibleEras[i].id),
                  progress: notifier.getEraProgress(visibleEras[i].id),
                  isUnlocked: unlocked(visibleEras[i]),
                  guestLocked: isGuest && !unlocked(visibleEras[i]),
                  isCurrent: i == current,
                  compact: compact,
                  onTap: unlocked(visibleEras[i])
                      ? () {
                          if (notifier
                                  .getEraProgress(visibleEras[i].id)
                                  .levelsCompleted >
                              0) {
                            context.go('/level-select/${visibleEras[i].id}');
                          } else {
                            context.go('/background/${visibleEras[i].id}');
                          }
                        }
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One era: its number, an enemy on its colour, its name and a pip per level.
class _EraCard extends StatefulWidget {
  final EraData era;
  final int number;
  final EraProgress progress;
  final bool isUnlocked;

  /// Shut for a guest: says it is for signed-in students.
  final bool guestLocked;
  final bool isCurrent;

  /// The picture beside the text, for when the card is too short for the tall layout.
  final bool compact;
  final VoidCallback? onTap;

  const _EraCard({
    super.key,
    required this.era,
    required this.number,
    required this.progress,
    required this.isUnlocked,
    this.guestLocked = false,
    required this.isCurrent,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_EraCard> createState() => _EraCardState();
}

class _EraCardState extends State<_EraCard>
    with SingleTickerProviderStateMixin {
  /// The open card breathes: a slow swell and back.
  late final AnimationController _breath = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = widget.isCurrent && motionAllowed(context);
    if (on && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    } else if (!on && _breath.isAnimating) {
      _breath.stop();
    }
  }

  @override
  void didUpdateWidget(_EraCard old) {
    super.didUpdateWidget(old);
    didChangeDependencies();
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final era = widget.era;
    final done = widget.progress.isCompleted;
    final locked = !widget.isUnlocked;
    final color = eraCardColor(era.id);
    final levels = era.levels.length;
    final filled =
        done ? levels : widget.progress.levelsCompleted.clamp(0, levels);

    final art = _Art(
      era: era,
      number: widget.number,
      color: color,
      locked: locked,
      done: done,
      compact: widget.compact,
    );
    final text = _Name(
        era: era, levels: levels, filled: filled, compact: widget.compact);

    Widget card = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1530),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: widget.isCurrent || done
              ? AppColors.accent
              : AppColors.primaryDark,
          width: 3,
        ),
        boxShadow: [
          if (widget.isCurrent)
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.45),
              blurRadius: 22,
              spreadRadius: 2,
            ),
          const BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.compact
          ? Row(
              children: [
                SizedBox(width: 62, child: art),
                Expanded(child: text),
              ],
            )
          : Column(
              children: [
                Expanded(flex: 5, child: art),
                Expanded(flex: 4, child: text),
              ],
            ),
    );

    if (locked) {
      card = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.25,
          0.5,
          0.1,
          0,
          0,
          0.25,
          0.5,
          0.1,
          0,
          0,
          0.25,
          0.5,
          0.1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: Opacity(opacity: 0.75, child: card),
      );
      if (widget.guestLocked) {
        card = Stack(
          children: [
            Positioned.fill(child: card),
            Positioned(
              left: 4,
              right: 4,
              bottom: widget.compact ? 4 : 12,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF231838),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                  child: Text(
                    'PARA SA NAKA-SIGN IN',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }
    }

    // The open card stands forward and swells a little.
    return Semantics(
      button: widget.onTap != null,
      label: locked
          ? (widget.guestLocked
              ? '${era.name}, para sa naka-sign in'
              : '${era.name}, naka-lock')
          : era.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _breath,
          child: card,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, widget.isCurrent ? -8 : 0),
            child: Transform.scale(
              scale: 1 + 0.03 * Curves.easeInOut.transform(_breath.value),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// The top of a card: the era's colour, its number, an enemy and (locked or
/// finished) a lock or a star.
class _Art extends StatelessWidget {
  final EraData era;
  final int number;
  final Color color;
  final bool locked;
  final bool done;
  final bool compact;
  const _Art({
    required this.era,
    required this.number,
    required this.color,
    required this.locked,
    required this.done,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.black, 0.3)!,
            Color.lerp(color, const Color(0xFF140E1F), 0.7)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 4,
            child: Text(
              '$number',
              style: GoogleFonts.poppins(
                fontSize: compact ? 18 : 26,
                height: 1.1,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: const [
                  Shadow(color: Colors.black54, offset: Offset(0, 2))
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  compact ? 6 : 16, compact ? 18 : 28, compact ? 6 : 16, 6),
              child: Image.asset(
                eraSprite(era.id),
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
          if (locked)
            Center(
              child: Image.asset('assets/ui/lock_icon.png',
                  width: compact ? 20 : 34,
                  height: compact ? 20 : 34,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none),
            ),
          if (done)
            Positioned(
              right: 6,
              top: 6,
              child: Image.asset('assets/ui/star_full.png',
                  width: compact ? 16 : 24,
                  height: compact ? 16 : 24,
                  filterQuality: FilterQuality.none),
            ),
        ],
      ),
    );
  }
}

/// The bottom of a card: the era's name and a pip for every level.
class _Name extends StatelessWidget {
  final EraData era;
  final int levels;
  final int filled;
  final bool compact;
  const _Name(
      {required this.era,
      required this.levels,
      required this.filled,
      required this.compact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          compact ? 8 : 9, compact ? 4 : 8, compact ? 8 : 9, compact ? 6 : 9),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: Text(
              era.name,
              // Era titles run up to 47 characters.
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var i = 0; i < levels; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                Expanded(
                  child: Container(
                    key: EraSelectionScreen.pipKey(era.id, i),
                    height: compact ? 5 : 7,
                    decoration: BoxDecoration(
                      color: i < filled
                          ? AppColors.success
                          : const Color(0xFF3A2E52),
                      border:
                          Border.all(color: AppColors.primaryDark, width: 1),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
