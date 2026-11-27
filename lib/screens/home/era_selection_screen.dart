// Destination in your repo: lib/screens/home/era_selection_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/unlock_all_provider.dart';
import '../../services/audio_service.dart';
import '../../services/guest_mode.dart';
import '../../services/storage_service.dart';
import '../../utils/book_unlock.dart';
import '../../widgets/era_book.dart';
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

/// Choose an era: a shelf of books, one era each. The book in front is closed (its cover shows
/// the era's colour, the number, the boss and the name) with the two next to it tilted away
/// behind. A tap on the front book opens it: the left page tells the era, the right shows the
/// progress and the gold button that goes to the levels. A book whose era is not open yet is
/// chained shut; when the boss before it falls, the chains break here (once), and the book can
/// be opened. Arrows, a tap on a neighbour or a swipe move along the shelf; dots at the bottom
/// show all the eras.
class EraSelectionScreen extends ConsumerStatefulWidget {
  const EraSelectionScreen({super.key});

  /// The cover of an era's book (it is the closed book's size).
  static Key cardKey(String eraId) => ValueKey('era_card_$eraId');
  static Key progressKey(String eraId) => ValueKey('era_progress_$eraId');
  static Key dotKey(int i) => ValueKey('era_dot_$i');
  static const Key prevKey = Key('era_prev');
  static const Key nextKey = Key('era_next');
  static const Key playKey = Key('era_play');
  static const Key lockedNoteKey = Key('era_locked_note');

  /// The banner that pops up when a book's chains break.
  static const Key bannerKey = Key('era_unlock_banner');

  /// Covers the shelf while the chains are breaking: a tap on it skips what is left.
  static const Key unlockLayerKey = Key('era_unlock_layer');

  @override
  ConsumerState<EraSelectionScreen> createState() => _EraSelectionScreenState();
}

class _EraSelectionScreenState extends ConsumerState<EraSelectionScreen> with TickerProviderStateMixin {
  /// The book the student moved to. Until they move, the book in front is the era that is next
  /// to play (so it follows the progress as it loads).
  int? _picked;

  /// The book that is open, or null.
  int? _open;

  // The chain break.
  String? _unlockId;
  bool _unlockChecked = false;
  bool _skip = false;
  late final AnimationController _charge = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  late final AnimationController _burst =
      AnimationController(vsync: this, duration: Duration(milliseconds: (BookChainFx.burstSeconds * 1000).round()));
  late final BookChainFx _fx = BookChainFx(charge: _charge, burst: _burst);

  /// A tap on a shut book makes it wobble.
  late final AnimationController _wobble = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  int _wobbleIndex = -1;

  final AudioService _audio = AudioService();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(progressProvider.notifier).loadProgress();
      // The score changes on the server after every level.
      ref.read(authProvider.notifier).refreshProfile();
      _audio.playLobbyBgm();
    });
  }

  @override
  void dispose() {
    _unlockId = null; // a running sequence stops at its next step
    _charge.dispose();
    _burst.dispose();
    _wobble.dispose();
    // The music must not stay ducked after the chain break was cut short.
    _audio.duckMusic(1.0);
    super.dispose();
  }

  void _focusOn(int i, int count) {
    if (_unlockId != null) return;
    final next = i.clamp(0, count - 1);
    if (next == (_picked ?? -1)) return;
    setState(() => _picked = next);
    _audio.playBookSlide();
  }

  void _openBook(int i) {
    setState(() => _open = i);
    _audio.playBookOpen();
  }

  void _closeBook() {
    if (_open == null) return;
    setState(() => _open = null);
    _audio.playBookClose();
  }

  void _shake(int i) {
    _wobbleIndex = i;
    _wobble.forward(from: 0);
    _audio.playBookLocked();
  }

  // ─── THE CHAIN BREAK ──────────────────────────────────────────────────────

  /// Looks for a book waiting to be unchained (a boss fell, see BookUnlock) and plays it once.
  void _maybeStartUnlock(List<EraData> eras, bool Function(EraData) unlocked, {required bool allowed}) {
    if (_unlockChecked) return;
    _unlockChecked = true;
    String? pending;
    try {
      pending = StorageService.getPendingBookUnlock();
    } catch (_) {
      return; // no local storage
    }
    if (pending == null) return;
    // The tester build's replay button asks for the break on a book that is already open.
    final replay = pending.startsWith(BookUnlock.replayPrefix);
    final id = replay ? pending.substring(BookUnlock.replayPrefix.length) : pending;
    final i = eras.indexWhere((e) => e.id == id);
    final playable = i > 0 && (replay || (allowed && unlocked(eras[i]))) && motionAllowed(context);
    if (!playable) {
      StorageService.setPendingBookUnlock(null);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _runUnlock(i, eras);
    });
  }

  /// Waits [ms], unless the student skipped (or left); false then.
  Future<bool> _wait(int ms) async {
    var left = ms;
    while (left > 0) {
      if (!mounted || _unlockId == null || _skip) return false;
      final step = left > 50 ? 50 : left;
      await Future<void>.delayed(Duration(milliseconds: step));
      left -= step;
    }
    return mounted && _unlockId != null && !_skip;
  }

  Future<void> _runUnlock(int i, List<EraData> eras) async {
    _skip = false;
    setState(() {
      _unlockId = eras[i].id;
      _picked = i - 1; // the finished book first
      _open = null;
    });
    _audio.duckMusic(0.3);
    if (await _wait(700)) {
      setState(() => _picked = i);
      _audio.playBookSlide();
      if (await _wait(950)) {
        _audio.playChainStrain();
        _charge.forward(from: 0);
        if (await _wait(1350)) {
          _audio.playChainUnlock();
          _burst.forward(from: 0);
          if (await _wait(450)) {
            _audio.playBookReveal();
            await _wait(2300);
          }
        }
      }
    }
    _finishUnlock();
  }

  void _finishUnlock() {
    StorageService.setPendingBookUnlock(null);
    _audio.duckMusic(1.0);
    if (!mounted) return;
    _charge.value = 1;
    _burst.value = 1;
    setState(() {
      _unlockId = null;
      _skip = false;
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
    final visibleEras = unlockAll ? allEras.toList() : allEras.where((era) => 'grade${era.grade}' == gradeLevel).toList();

    final visibleEraIds = visibleEras.map((e) => e.id).toList();
    final notifier = ref.read(progressProvider.notifier);
    bool unlocked(EraData e) => isGuest ? e.id == GuestMode.eraId : unlockAll || notifier.isEraUnlocked(e.id, visibleEraIds);
    final guestDone = isGuest && notifier.getEraProgress(GuestMode.eraId).isCompleted;
    // The one to play next: the first open era that is not finished.
    final current = visibleEras.indexWhere(
      (e) => unlocked(e) && !notifier.getEraProgress(e.id).isCompleted,
    );
    final count = visibleEras.length;
    // Nothing left to play: stand on the last era that is open.
    final focus = count == 0 ? 0 : (_picked ?? (current < 0 ? visibleEras.lastIndexWhere(unlocked) : current)).clamp(0, count - 1);
    final lit = current < 0 ? null : visibleEras[current];

    if (!progressState.isLoading && count > 0 && !_unlockChecked) {
      _maybeStartUnlock(visibleEras, unlocked, allowed: !isGuest && !unlockAll);
    }

    return PopScope(
      canPop: _open == null && _unlockId == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeBook();
      },
      child: Scaffold(
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
                      onBack: () => _open != null ? _closeBook() : context.go('/character-selection'),
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

                    // The shelf
                    Expanded(
                      child: progressState.isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
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

                    // The dots for the eras.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
                      child: Center(
                        child: _Dots(
                          eras: visibleEras,
                          focus: focus,
                          done: (e) => notifier.getEraProgress(e.id).isCompleted,
                          onTap: (i) => _focusOn(i, count),
                        ),
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

  /// How big a book is drawn: its box is two pages wide (the open spread) and a page high
  /// with its thickness and tilt; the shelf scales it to the room.
  static const double _boxW = kBookPageW * 2;
  static const double _boxH = kBookPageH + 2 * kBookDepth + 16;

  /// How big a book beside the front one is, compared with the front one.
  static const double _sideScale = 0.72;

  /// Lays the books out in the room the screen has: the front book as large as fits (never
  /// more than its design size), the two neighbours tilted away behind it.
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
    final room = math.max(0.3, (box.maxHeight - 6) / _boxH);
    final closedScale = math.max(0.3, math.min(1.0, math.min(room, box.maxWidth * 0.62 / kBookPageW)));
    final openScale = math.max(0.3, math.min(1.0, math.min(room, box.maxWidth * 0.94 / _boxW)));
    final step = (kBookPageW * closedScale * (1 + _sideScale)) / 2 + 8;
    final cx = box.maxWidth / 2;
    final cy = box.maxHeight / 2;
    final moving = motionAllowed(context);
    final duration = moving ? const Duration(milliseconds: 320) : Duration.zero;
    final reading = _open != null;
    final unlocking = _unlockId != null;

    Widget book(int i) {
      final era = eras[i];
      final d = i - focus;
      final big = d == 0;
      final progress = notifier.getEraProgress(era.id);
      final isUnlocking = era.id == _unlockId;
      final shut = isUnlocking || !unlocked(era);
      final guestLocked = isGuest && !unlocked(era);
      final isOpen = _open == i;
      final scale = isOpen ? openScale : (big ? closedScale : closedScale * _sideScale);
      // The books beside the front one slide away while one is open.
      final slide = d * step * (reading && !big ? 3.2 : 1.0);
      Widget b = EraBook(
        era: era,
        number: eraNumberFor(era.id),
        color: eraCardColor(era.id),
        progress: progress,
        locked: shut,
        guestLocked: guestLocked,
        previousName: i > 0 ? eras[i - 1].name : null,
        focused: big,
        open: isOpen,
        chainFx: isUnlocking ? _fx : null,
        coverKey: EraSelectionScreen.cardKey(era.id),
        playKey: isOpen ? EraSelectionScreen.playKey : null,
        progressKey: isOpen ? EraSelectionScreen.progressKey(era.id) : null,
        lockedNoteKey: big && shut && !isUnlocking ? EraSelectionScreen.lockedNoteKey : null,
        onCover: () {
          if (unlocking) return;
          if (!big) return _focusOn(i, count);
          if (shut) return _shake(i);
          _openBook(i);
        },
        onPlay: unlocked(era) ? () => context.go('/level-select/${era.id}') : null,
      );
      // The tilt of a book that is not in front: turned away from the middle.
      b = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0009)
          ..rotateY(-d.clamp(-1, 1) * 0.5 * (isOpen ? 0 : 1)),
        child: b,
      );
      // A tap on a shut book makes it wobble; the book that is being unchained lifts.
      b = AnimatedBuilder(
        animation: Listenable.merge([_wobble, _burst]),
        child: b,
        builder: (context, child) {
          var dx = 0.0;
          var dy = 0.0;
          var lift = 1.0;
          if (i == _wobbleIndex && _wobble.isAnimating) {
            dx = math.sin(_wobble.value * math.pi * 6) * 7 * (1 - _wobble.value);
          }
          if (isUnlocking) {
            final t = _burst.value * BookChainFx.burstSeconds;
            final k = ((t - 0.1) / 1.3).clamp(0.0, 1.0);
            lift = 1 + 0.07 * math.sin(math.pi * k);
            dy = -10 * math.sin(math.pi * k);
          }
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.scale(scale: lift, child: child),
          );
        },
      );
      return AnimatedPositioned(
        // Keyed by era, so a book keeps its own state (open or closed, its slide and scale) when
        // the shelf moves and the books around it change.
        key: ValueKey('shelf_${era.id}'),
        duration: duration,
        curve: Curves.easeOutCubic,
        left: cx + slide - _boxW / 2,
        top: cy - _boxH / 2,
        width: _boxW,
        height: _boxH,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: scale),
          duration: moving ? const Duration(milliseconds: 520) : Duration.zero,
          curve: Curves.easeInOutCubic,
          builder: (context, s, child) => Transform.scale(scale: s, child: child),
          child: b,
        ),
      );
    }

    Widget stage = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        if (reading || unlocking) return;
        final v = details.primaryVelocity ?? 0;
        if (v < -250) _focusOn(focus + 1, count);
        if (v > 250) _focusOn(focus - 1, count);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The golden rays behind the book that is being unchained.
          if (unlocking)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _burst,
                  builder: (context, _) => CustomPaint(
                    painter: _RaysPainter(t: _burst.value * BookChainFx.burstSeconds, center: Offset(cx, cy)),
                  ),
                ),
              ),
            ),
          // Neighbours first, so the front book is drawn over them.
          for (var d = -1; d <= 1; d++)
            if (d != 0 && focus + d >= 0 && focus + d < count) book(focus + d),
          book(focus),
          if (focus > 0 && !reading)
            Positioned(
              left: 6,
              top: cy - 24,
              child: _Arrow(
                key: EraSelectionScreen.prevKey,
                forward: false,
                onTap: () => _focusOn(focus - 1, count),
              ),
            ),
          if (focus < count - 1 && !reading)
            Positioned(
              right: 6,
              top: cy - 24,
              child: _Arrow(
                key: EraSelectionScreen.nextKey,
                forward: true,
                onTap: () => _focusOn(focus + 1, count),
              ),
            ),
          // The banner that pops up when the chains break.
          if (unlocking)
            Positioned(
              left: 0,
              right: 0,
              top: 6,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _burst,
                  builder: (context, _) => _UnlockBanner(t: _burst.value * BookChainFx.burstSeconds, eraName: eras[focus].name),
                ),
              ),
            ),
          // While the chains break, a tap anywhere skips what is left of it.
          if (unlocking)
            Positioned.fill(
              child: GestureDetector(
                key: EraSelectionScreen.unlockLayerKey,
                behavior: HitTestBehavior.opaque,
                onTap: () => _skip = true,
              ),
            ),
        ],
      ),
    );
    // The whole shelf shakes for a moment when the lock opens.
    if (unlocking) {
      stage = AnimatedBuilder(
        animation: _burst,
        child: stage,
        builder: (context, child) {
          final t = _burst.value * BookChainFx.burstSeconds;
          final k = (1 - t / 0.55).clamp(0.0, 1.0);
          return Transform.translate(
            offset: Offset(math.sin(t * 95) * 6 * k, math.cos(t * 80) * 3 * k),
            child: child,
          );
        },
      );
    }
    return stage;
  }
}

/// Golden rays that turn behind the book while its chains break.
class _RaysPainter extends CustomPainter {
  final double t;
  final Offset center;
  const _RaysPainter({required this.t, required this.center});

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0.2) return;
    final k = ((t - 0.2) / 2.2).clamp(0.0, 1.0);
    final a = k < 0.15 ? k / 0.15 : 1 - (k - 0.15) / 0.85;
    final r = size.longestSide * 0.55;
    final rot = t * 0.4;
    final shader = RadialGradient(colors: [
      const Color(0xFFFFE27A).withValues(alpha: 0.5 * a),
      const Color(0xFFFFE27A).withValues(alpha: 0),
    ]).createShader(Rect.fromCircle(center: center, radius: r));
    final paint = Paint()..shader = shader;
    for (var i = 0; i < 14; i++) {
      final a0 = rot + i * math.pi * 2 / 14;
      final a1 = a0 + 0.13;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + math.cos(a0) * r, center.dy + math.sin(a0) * r)
        ..lineTo(center.dx + math.cos(a1) * r, center.dy + math.sin(a1) * r)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.t != t || old.center != center;
}

/// "BAGONG PANAHON!" and the era's name, popping up over the shelf as the lock opens.
class _UnlockBanner extends StatelessWidget {
  final double t;
  final String eraName;
  const _UnlockBanner({required this.t, required this.eraName});

  @override
  Widget build(BuildContext context) {
    const start = 0.05;
    final u = t - start;
    if (u < 0 || t > 2.45) return const SizedBox.shrink();
    final scale = u < 0.14 ? 0.3 + u / 0.14 * 0.9 : (u < 0.24 ? 1.2 - (u - 0.14) * 2 : 1.0);
    final alpha = t > 2.15 ? 1 - (t - 2.15) / 0.3 : (u < 0.1 ? u / 0.1 : 1.0);
    return Center(
      child: Opacity(
        opacity: alpha.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale,
          child: Container(
            key: EraSelectionScreen.bannerKey,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryDark, width: 3),
              boxShadow: [
                const BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 4)),
                BoxShadow(color: AppColors.accent.withValues(alpha: 0.6), blurRadius: 18),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BAGONG PANAHON!',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.primaryDark),
                ),
                Text(
                  eraName,
                  style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A round arrow chip beside the books: 48 to hit, 38 to look at.
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
