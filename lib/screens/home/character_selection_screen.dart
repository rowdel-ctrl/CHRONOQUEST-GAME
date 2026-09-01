import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/game_provider.dart';
import '../../widgets/game_ui.dart';

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
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final char = allCharacters[_selectedIndex];

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
                          GameButton(
                            label: 'PILIIN SI ${char.name.toUpperCase()}!',
                            fontSize: 11,
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () {
                              ref
                                  .read(gameProvider.notifier)
                                  .selectCharacter(
                                      allCharacters[_selectedIndex].id);
                              context.go('/era-selection');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Leaderboard top-left button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: _SideIconButton(
              icon: Icons.emoji_events,
              tooltip: 'Leaderboard',
              onTap: () => context.push('/leaderboard'),
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

  const _CharCard({
    required this.char,
    required this.isSelected,
    required this.charColor,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sprite with colored glow
            _IdleAvatar(charId: char.id, color: charColor),
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
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: charColor,
                ),
              ),
            ),
            const SizedBox(height: 10),

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

// ── Side Icon Button ───────────────────────────────────────────────────────────
class _SideIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SideIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Icon(icon, color: AppColors.accent, size: 20),
        ),
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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
          'assets/characters/${widget.charId}_walk_1.png',
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
