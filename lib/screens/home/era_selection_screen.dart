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

/// Choose an era: one big card at a time, with the two neighbours peeking in on
/// each side. The big card shows the era's colour, its number, the era's boss
/// (a dark shape while the era is locked), a star or a lock, the full name, a
/// progress bar and a gold button. Arrows, a tap on a neighbour or a swipe move
/// to the next card; dots at the bottom show all the eras.
class EraSelectionScreen extends ConsumerStatefulWidget {
  const EraSelectionScreen({super.key});

  static Key cardKey(String eraId) => ValueKey('era_card_$eraId');
  static Key progressKey(String eraId) => ValueKey('era_progress_$eraId');
  static Key dotKey(int i) => ValueKey('era_dot_$i');
  static const Key prevKey = Key('era_prev');
  static const Key nextKey = Key('era_next');
  static const Key playKey = Key('era_play');
  static const Key lockedNoteKey = Key('era_locked_note');

  @override
  ConsumerState<EraSelectionScreen> createState() => _EraSelectionScreenState();
}

class _EraSelectionScreenState extends ConsumerState<EraSelectionScreen> {
  /// The card the student moved to. Until they move, the card in front is the
  /// era that is next to play (so it follows the progress as it loads).
  int? _picked;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(progressProvider.notifier).loadProgress();
      // The score changes on the server after every level.
      ref.read(authProvider.notifier).refreshProfile();
    });
  }

  void _focusOn(int i, int count) {
    final next = i.clamp(0, count - 1);
    if (next == (_picked ?? -1)) return;
    setState(() => _picked = next);
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
    final count = visibleEras.length;
    // Nothing left to play: stand on the last era that is open.
    final focus = count == 0
        ? 0
        : (_picked ??
                (current < 0 ? visibleEras.lastIndexWhere(unlocked) : current))
            .clamp(0, count - 1);
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
                            builder: (context, box) => _buildStage(
                              box,
                              visibleEras,
                              focus,
                              current,
                              unlocked,
                              isGuest,
                            ),
                          ),
                  ),

                  // Who is playing and the score, then the dots for the eras.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
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
                        Expanded(
                          child: Center(
                            child: _Dots(
                              eras: visibleEras,
                              focus: focus,
                              done: (e) =>
                                  notifier.getEraProgress(e.id).isCompleted,
                              onTap: (i) => _focusOn(i, count),
                            ),
                          ),
                        ),
                        // Balances the score side so the dots stay near the middle.
                        const SizedBox(width: 32),
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

  /// The size a big card is drawn at, before it is scaled to the screen.
  static const double _designW = 236;
  static const double _designH = 252;

  /// How big a card beside the big one is, compared with the big one.
  static const double _sideScale = 0.72;

  /// Lays the cards out in the space the screen has: the big card as large as
  /// fits (never more than its design size), the two neighbours behind it.
  Widget _buildStage(
    BoxConstraints box,
    List<EraData> eras,
    int focus,
    int current,
    bool Function(EraData) unlocked,
    bool isGuest,
  ) {
    final count = eras.length;
    if (count == 0) return const SizedBox.shrink();

    final notifier = ref.read(progressProvider.notifier);
    final scale = math.max(
      0.3,
      math.min(
        1.0,
        math.min(
            (box.maxHeight - 10) / _designH, box.maxWidth * 0.62 / _designW),
      ),
    );
    final bigW = _designW * scale;
    final bigH = _designH * scale;
    final sideW = bigW * _sideScale;
    final sideH = bigH * _sideScale;
    final step = (bigW + sideW) / 2 + 8;
    final cx = box.maxWidth / 2;
    final cy = box.maxHeight / 2;
    final duration = motionAllowed(context)
        ? const Duration(milliseconds: 260)
        : Duration.zero;

    Widget card(int i) {
      final era = eras[i];
      final d = i - focus;
      final big = d == 0;
      final w = big ? bigW : sideW;
      final h = big ? bigH : sideH;
      final progress = notifier.getEraProgress(era.id);
      final open = unlocked(era);
      return AnimatedPositioned(
        key: EraSelectionScreen.cardKey(era.id),
        duration: duration,
        curve: Curves.easeOutCubic,
        left: cx + d * step - w / 2,
        top: cy - h / 2,
        width: w,
        height: h,
        child: _EraCard(
          era: era,
          number: eraNumberFor(era.id),
          progress: progress,
          isUnlocked: open,
          guestLocked: isGuest && !open,
          previousName: i > 0 ? eras[i - 1].name : null,
          big: big,
          breathing: big && i == current,
          designSize: const Size(_designW, _designH),
          onTap: big
              ? (open
                  ? () {
                      if (progress.levelsCompleted > 0) {
                        context.go('/level-select/${era.id}');
                      } else {
                        context.go('/background/${era.id}');
                      }
                    }
                  : null)
              : () => _focusOn(i, count),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < -250) _focusOn(focus + 1, count);
        if (v > 250) _focusOn(focus - 1, count);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Neighbours first, so the big card is drawn over them.
          if (focus > 0) card(focus - 1),
          if (focus < count - 1) card(focus + 1),
          card(focus),
          if (focus > 0)
            Positioned(
              left: 6,
              top: cy - 24,
              child: _Arrow(
                key: EraSelectionScreen.prevKey,
                forward: false,
                onTap: () => _focusOn(focus - 1, count),
              ),
            ),
          if (focus < count - 1)
            Positioned(
              right: 6,
              top: cy - 24,
              child: _Arrow(
                key: EraSelectionScreen.nextKey,
                forward: true,
                onTap: () => _focusOn(focus + 1, count),
              ),
            ),
        ],
      ),
    );
  }
}

/// A round arrow chip beside the cards: 48 to hit, 38 to look at.
class _Arrow extends StatelessWidget {
  final bool forward;
  final VoidCallback onTap;
  const _Arrow({super.key, required this.forward, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: forward ? 'Susunod na panahon' : 'Nakaraang panahon',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: AppColors.primaryDark, width: 2),
                boxShadow: const [
                  BoxShadow(color: AppColors.primaryDark, offset: Offset(2, 2))
                ],
              ),
              child: Transform.scale(
                scaleX: forward ? 1 : -1,
                child: const PixelIcon(PixelGlyph.chevron,
                    size: 22, color: AppColors.accent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One dot per era; the one in front is a long gold pill, a finished one is a
/// dull gold, the rest dark.
class _Dots extends StatelessWidget {
  final List<EraData> eras;
  final int focus;
  final bool Function(EraData) done;
  final ValueChanged<int> onTap;
  const _Dots({
    required this.eras,
    required this.focus,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < eras.length; i++)
            Semantics(
              button: true,
              selected: i == focus,
              label: 'Panahon ${i + 1} ng ${eras.length}',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    key: EraSelectionScreen.dotKey(i),
                    duration: const Duration(milliseconds: 200),
                    width: i == focus ? 22 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: i == focus
                          ? AppColors.accent
                          : done(eras[i])
                              ? const Color(0xFFB98A22)
                              : const Color(0xFF3A2E52),
                      borderRadius: BorderRadius.circular(5),
                      border:
                          Border.all(color: AppColors.primaryDark, width: 2),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One era card. It is always laid out at [designSize] (the big card) and scaled
/// to the box it is given, so it never overflows while it grows or shrinks. The
/// big card also shows the progress and the button; the neighbours show only the
/// colour, the boss and the name.
class _EraCard extends StatefulWidget {
  final EraData era;
  final int number;
  final EraProgress progress;
  final bool isUnlocked;

  /// Shut for a guest: says it is for signed-in students.
  final bool guestLocked;

  /// The era before this one, named in the line that says what to finish first.
  final String? previousName;
  final bool big;

  /// The big card of the era that is next to play: it breathes.
  final bool breathing;
  final Size designSize;
  final VoidCallback? onTap;

  const _EraCard({
    required this.era,
    required this.number,
    required this.progress,
    required this.isUnlocked,
    required this.guestLocked,
    required this.previousName,
    required this.big,
    required this.breathing,
    required this.designSize,
    required this.onTap,
  });

  @override
  State<_EraCard> createState() => _EraCardState();
}

class _EraCardState extends State<_EraCard>
    with SingleTickerProviderStateMixin {
  /// The card that is next to play breathes: a slow swell and back.
  late final AnimationController _breath = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = widget.breathing && motionAllowed(context);
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
    final glow = widget.big && !locked;

    Widget card = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF241A36),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: glow ? AppColors.accent : const Color(0xFF1B1230),
          width: 3,
        ),
        boxShadow: [
          if (glow)
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 22,
            ),
          const BoxShadow(color: Color(0xFF1B1230), offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 124,
            child: _Art(
              era: era,
              number: widget.number,
              locked: locked,
              done: done,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: _Lower(
                era: era,
                progress: widget.progress,
                locked: locked,
                guestLocked: widget.guestLocked,
                previousName: widget.previousName,
                big: widget.big,
              ),
            ),
          ),
        ],
      ),
    );

    // Drawn at the design size, then scaled to whatever box the carousel gives.
    card = FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: widget.designSize.width,
        height: widget.designSize.height,
        child: card,
      ),
    );

    return Semantics(
      button: widget.onTap != null,
      selected: widget.big,
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
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: widget.big ? 1 : 0.78,
            child: card,
          ),
          builder: (context, child) => Transform.scale(
            scale: 1 + 0.03 * Curves.easeInOut.transform(_breath.value),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The top of a card: the era's colour, its number, the era's boss and (locked or
/// finished) a lock or a star.
class _Art extends StatelessWidget {
  final EraData era;
  final int number;
  final bool locked;
  final bool done;
  const _Art({
    required this.era,
    required this.number,
    required this.locked,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final base = eraCardColor(era.id);
    final color =
        locked ? Color.lerp(base, const Color(0xFF3A3548), 0.55)! : base;
    Widget boss = Image.asset(
      'assets/bosses/${era.bossName}_idle.png',
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, __, ___) => const SizedBox(),
    );
    if (locked) {
      // A dark shape: the boss is not known yet.
      boss = ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0x80000000), BlendMode.srcIn),
        child: boss,
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, const Color(0xFF1E1530)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: boss,
            ),
          ),
          Positioned(
            left: 8,
            top: 6,
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDark,
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: Text(
                '$number',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          if (locked)
            Positioned(
              right: 8,
              top: 6,
              child: Image.asset('assets/ui/lock_icon.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none),
            ),
          if (done)
            Positioned(
              right: 8,
              top: 6,
              child: Image.asset('assets/ui/star_full.png',
                  width: 24, height: 24, filterQuality: FilterQuality.none),
            ),
        ],
      ),
    );
  }
}

/// The bottom of a card: the full name, then (on the big card) the progress, the
/// line about the next level and the gold button, or why the era is locked. It is
/// scaled down as a whole if the name is long, instead of overflowing.
class _Lower extends StatelessWidget {
  final EraData era;
  final EraProgress progress;
  final bool locked;
  final bool guestLocked;
  final String? previousName;
  final bool big;
  const _Lower({
    required this.era,
    required this.progress,
    required this.locked,
    required this.guestLocked,
    required this.previousName,
    required this.big,
  });

  @override
  Widget build(BuildContext context) {
    final levels = era.levels.length;
    final done = progress.isCompleted;
    final filled =
        done ? levels : progress.levelsCompleted.clamp(0, levels).toInt();
    final next = (filled + 1).clamp(1, levels);

    final children = <Widget>[
      Text(
        era.name,
        style: GoogleFonts.poppins(
          fontSize: 14.5,
          height: 1.25,
          fontWeight: FontWeight.bold,
          color: AppColors.surface,
        ),
      ),
    ];

    if (guestLocked) {
      children.addAll([
        const SizedBox(height: 6),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF231838),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            child: Text(
              'PARA SA NAKA-SIGN IN',
              maxLines: 1,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
      ]);
    } else if (big && locked) {
      final previous = previousName;
      children.addAll([
        const SizedBox(height: 6),
        Text.rich(
          previous == null
              ? const TextSpan(text: 'Naka-lock pa ang era na ito.')
              : TextSpan(children: [
                  const TextSpan(text: 'Tapusin muna ang '),
                  TextSpan(
                    text: previous,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.surface),
                  ),
                  const TextSpan(text: ' para mabuksan ito.'),
                ]),
          key: EraSelectionScreen.lockedNoteKey,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            height: 1.4,
            color: const Color(0xFFC9BEDB),
          ),
        ),
      ]);
    } else if (big) {
      children.addAll([
        const SizedBox(height: 6),
        Container(
          key: EraSelectionScreen.progressKey(era.id),
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF3A2E52),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFF1B1230), width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: levels == 0 ? 0 : filled / levels,
            heightFactor: 1,
            child: ColoredBox(
              color: done ? AppColors.accent : const Color(0xFFE0A52B),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          done
              ? 'Tapos na · $levels ng $levels level'
              : 'Level $next na ang susunod · $filled ng $levels',
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            color: const Color(0xFFC9BEDB),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          key: EraSelectionScreen.playKey,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.primaryDark, width: 3),
            boxShadow: const [
              BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 3)),
            ],
          ),
          child: Text(
            done ? 'BALIKAN' : 'MAGLARO',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ]);
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 216,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
