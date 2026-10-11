import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/game_provider.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/hearts_pill.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/pixel_icon.dart';

class CharacterSelectionScreen extends ConsumerStatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  ConsumerState<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState
    extends ConsumerState<CharacterSelectionScreen> {
  late PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.62, initialPage: 0);
    // The first-play tutorial no longer auto-triggers here (it used to fire
    // on every visit to this screen until seen — i.e. on app open, not on
    // starting a level). It's now gated at the point a level is actually
    // started, in LevelSelectScreen._startLevel. The book icon below still
    // opens it manually at any time.
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final char = allCharacters[_selectedIndex];
    ref.watch(gameProvider); // redraw when a character is bought
    final notifier = ref.read(gameProvider.notifier);
    bool unlocked(String id) => notifier.isCharacterUnlocked(id);

    return Scaffold(
      body: Stack(
        children: [
          // ── Bookshelf background ───────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/bookshelf_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark overlay — neutral navy so it works for any character color
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0D0B1E).withValues(alpha: 0.88),
                    const Color(0xFF0D0B1E).withValues(alpha: 0.78),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ───────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Header ─────────────────────────────────────────────
                _CharHeader(),

                // ── Carousel + arrows ───────────────────────────────────
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Character page carousel
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (i) =>
                            setState(() => _selectedIndex = i),
                        itemCount: allCharacters.length,
                        itemBuilder: (context, index) {
                          final c = allCharacters[index];
                          final isSelected = index == _selectedIndex;
                          return _CharCard(
                            char: c,
                            isSelected: isSelected,
                            charColor: _getCharColor(c.id),
                            locked: !unlocked(c.id),
                          );
                        },
                      ),

                      // Left arrow
                      if (_selectedIndex > 0)
                        Positioned(
                          left: 8,
                          child: _NavArrow(
                            icon: Icons.chevron_left_rounded,
                            onTap: () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                          ),
                        ),

                      // Right arrow
                      if (_selectedIndex < allCharacters.length - 1)
                        Positioned(
                          right: 8,
                          child: _NavArrow(
                            icon: Icons.chevron_right_rounded,
                            onTap: () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Footer: dots + CTA ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      // Indicator dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          allCharacters.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _selectedIndex ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _selectedIndex
                                  ? _getCharColor(
                                      allCharacters[i].id)
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CTA — GameButton style (user's favourite!)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (unlocked(char.id))
                            GameButton(
                              label: 'PILIIN SI ${char.name.toUpperCase()}!',
                              fontSize: 11,
                              icon: Icons.arrow_forward_rounded,
                              onPressed: () {
                                notifier.selectCharacter(char.id);
                                context.go('/era-selection');
                              },
                            )
                          else
                            GameButton(
                              key: const ValueKey('unlock_character'),
                              label: 'I-UNLOCK SI ${char.name.toUpperCase()}',
                              fontSize: 11,
                              leading: Image.asset('assets/collectibles/coin.png',
                                  width: 16, height: 16),
                              onPressed: () => showUnlockCharacterDialog(context, char),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Leaderboard top-left button. The chips are 48 square to hit and
          // 40 to look at, so they sit 4 higher and 4 nearer the edge than
          // the 40 square buttons they replaced.
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 8,
            child: MenuChip(
              icon: PixelGlyph.trophy,
              tooltip: 'Leaderboard',
              onTap: () => context.push('/leaderboard'),
            ),
          ),

          // Hearts, how to play, Profile and Settings, top right. Hearts sit in
          // this existing icon row rather than taking a new band of vertical
          // space, which a 320px-tall landscape phone does not have to spare.
          // Settings is always the right-most chip and Profile just left of it.
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HeartsPill(),
                const SizedBox(width: 4),
                MenuChip(
                  icon: PixelGlyph.book,
                  tooltip: 'Paano Laruin',
                  onTap: () => context.push('/tutorial'),
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
          ),
        ],
      ),
    );
  }

  Color _getCharColor(String id) {
    switch (id) {
      case 'lapu':
        return const Color(0xFFD4A853);
      case 'rizal':
        return const Color(0xFF5B9BD5);
      case 'mabini':
        return const Color(0xFF5BA88A);
      case 'escoda':
        return const Color(0xFFD45B5B);
      case 'aquino':
        return const Color(0xFFD4C44A);
      default:
        return AppColors.accent;
    }
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────
class _CharHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'PILIIN ANG IYONG',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.accent.withValues(alpha: 0.75),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'BAYANI',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 2,
                width: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.shield_rounded,
                    color: AppColors.accent.withValues(alpha: 0.7), size: 16),
              ),
              Container(
                height: 2,
                width: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Character Card ─────────────────────────────────────────────────────────────
class _CharCard extends StatelessWidget {
  final CharacterData char;
  final bool isSelected;
  final Color charColor;

  /// Not bought yet: shown dimmed, with its price.
  final bool locked;

  const _CharCard({
    required this.char,
    required this.isSelected,
    required this.charColor,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isSelected ? 8 : 24,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? charColor.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.12),
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: charColor.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        // FittedBox(scaleDown) safety net — same pattern as the quiz card
        // (question_card.dart): the avatar + name + badge + description
        // column has a fixed intrinsic height, but the card itself is only
        // as tall as whatever's left after the header/footer on a short
        // landscape phone. Without this the column overflows its bounds and
        // gets clipped instead of shrinking to fit.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sprite with colored glow
              Opacity(
                opacity: locked ? 0.35 : 1,
                child: _IdleAvatar(charId: char.id, color: charColor),
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                char.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Era pill badge
              Container(
                // Wraps to two lines instead of widening the card: era titles
                // run up to 47 characters.
                constraints: const BoxConstraints(maxWidth: 170),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: charColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: charColor.withValues(alpha: 0.5), width: 1),
                ),
                child: Text(
                  char.era,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: charColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              if (locked) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Image.asset('assets/collectibles/coin.png', width: 14, height: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${char.unlockCost}',
                      key: const ValueKey('character_price'),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],

              // Description
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  char.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav Arrow ──────────────────────────────────────────────────────────────────
class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Icon(icon, color: Colors.white70, size: 26),
      ),
    );
  }
}

// ── Idle Avatar (bob animation) ────────────────────────────────────────────────
class _IdleAvatar extends StatefulWidget {
  final String charId;
  final Color color;
  const _IdleAvatar({required this.charId, required this.color});

  @override
  State<_IdleAvatar> createState() => _IdleAvatarState();
}

class _IdleAvatarState extends State<_IdleAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  /// There's no dedicated idle art for any character (only walk/jump/hurt),
  /// so this cycles the 4 walk frames slowly — much slower than the
  /// in-level walk animation's 150ms step — to read as a gentle idle shift
  /// rather than a run cycle. Combined with the existing bob below, this is
  /// the difference between "a single frame floating up and down" and an
  /// avatar that looks genuinely alive while a student picks their hero.
  late final Timer _frameTimer;
  int _frame = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _frameTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (mounted) setState(() => _frame = (_frame + 1) % 4);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _frameTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -5 * _ctrl.value),
        child: child,
      ),
      child: Container(
        width: 120,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.6),
              blurRadius: 32,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Image.asset(
          'assets/characters/${widget.charId}_walk_${_frame + 1}.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => Center(
            child: Text(
              widget.charId[0].toUpperCase(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks before spending coins on a locked character. Shows the price and the
/// student's coins, and only offers BILHIN when they can pay.
Future<void> showUnlockCharacterDialog(BuildContext context, CharacterData char) {
  return showDialog<void>(
    context: context,
    builder: (_) => _UnlockCharacterDialog(char: char),
  );
}

class _UnlockCharacterDialog extends ConsumerWidget {
  final CharacterData char;
  const _UnlockCharacterDialog({required this.char});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(gameProvider).coins;
    final canAfford = coins >= char.unlockCost;
    final style = GoogleFonts.poppins(fontSize: 13, height: 1.5, color: AppColors.textSecondary);

    Widget coinLine(String label, int n) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: style),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/collectibles/coin.png', width: 16, height: 16),
                  const SizedBox(width: 4),
                  Text('$n',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
            ],
          ),
        );

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: GamePanel(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'I-unlock si ${char.name}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Magagamit mo na siya sa lahat ng level.', style: style),
                const SizedBox(height: 10),
                coinLine('Presyo', char.unlockCost),
                coinLine('Iyong coins', coins),
                if (!canAfford)
                  Text(
                    'Kulang ang coins. Mangolekta pa sa mga level.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GameButton(
                        label: 'KANSELAHIN',
                        color: AppColors.surfaceAlt,
                        fontSize: 8,
                        minHeight: 44,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GameButton(
                        key: const ValueKey('confirm_unlock'),
                        label: 'BILHIN',
                        fontSize: 8,
                        minHeight: 44,
                        onPressed: canAfford
                            ? () {
                                ref.read(gameProvider.notifier).unlockCharacter(char.id);
                                Navigator.of(context).pop();
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
