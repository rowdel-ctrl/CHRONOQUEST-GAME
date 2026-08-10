import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/game_provider.dart';
import '../../widgets/pixel_ui.dart';

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
    _pageController = PageController(viewportFraction: 0.55, initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showMechanics() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        side: BorderSide(color: AppColors.primaryDark, width: 3),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paano Maglaro',
              style: GoogleFonts.pressStart2p(
                fontSize: 15,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _mechanicRow(Icons.touch_app, 'I-tap ang screen para tumalon sa mga hadlang'),
            _mechanicRow(Icons.quiz, 'Talunin ang kaaway sa pamamagitan ng tamang sagot'),
            _mechanicRow(Icons.favorite, 'Maling sagot = mawawalan ng puso'),
            _mechanicRow(Icons.bolt, 'Gumamit ng powerups para sa mahirap na tanong'),
            _mechanicRow(Icons.flag, 'Tapusin lahat ng 10 level para makumpleto ang era'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _mechanicRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.pixelifySans(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PixelBackdrop(
        baseColor: AppColors.background,
        child: SafeArea(
          // Column instead of a Stack of fixed top/bottom-offset
          // Positioned widgets — the old layout assumed a fixed screen
          // height and the character cards could overflow their
          // allotted band on shorter landscape phones. A Column with
          // Expanded lets the carousel take exactly whatever space is
          // actually left after the header and footer, on any screen.
          child: Column(
            children: [
              // Header row: side buttons + title
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Row(
                  children: [
                    _SideIconButton(
                      icon: Icons.menu_book,
                      tooltip: 'Mechanics',
                      onTap: _showMechanics,
                    ),
                    const SizedBox(width: 6),
                    _SideIconButton(
                      icon: Icons.emoji_events,
                      tooltip: 'Leaderboard',
                      onTap: () => context.push('/leaderboard'),
                    ),
                    Expanded(
                      child: Text(
                        'PILIIN ANG IYONG BAYANI',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: GoogleFonts.pressStart2p(
                          fontSize: 11,
                          height: 1.4,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    // Spacer matching the two side buttons' width so the
                    // title stays visually centered.
                    const SizedBox(width: 84),
                  ],
                ),
              ),

              // Character carousel — takes whatever vertical space is
              // left, on any screen size.
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _selectedIndex = i),
                  itemCount: allCharacters.length,
                  itemBuilder: (context, index) {
                    final char = allCharacters[index];
                    final isSelected = index == _selectedIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: isSelected ? 6 : 18,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.surface
                            : AppColors.surface.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.primaryDark,
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: AppColors.primaryDark,
                                  offset: Offset(4, 4),
                                  blurRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Character avatar — real sprite, falls back
                            // to an initial if the asset is ever missing.
                            Container(
                              width: 64,
                              height: 64,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: _getCharColor(char.id),
                                border: Border.all(
                                  color: AppColors.accent,
                                  width: 2,
                                ),
                              ),
                              child: Image.asset(
                                'assets/characters/${char.id}_walk_1.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    Center(
                                  child: Text(
                                    char.name[0],
                                    style: GoogleFonts.pressStart2p(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              char.name,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.pressStart2p(
                                fontSize: 10,
                                height: 1.4,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              char.era,
                              style: GoogleFonts.pixelifySans(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  char.description,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.pixelifySans(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Footer: dots + start button
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: List.generate(
                        allCharacters.length,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _selectedIndex ? 18 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _selectedIndex
                                ? AppColors.accent
                                : AppColors.textMuted,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    PixelButton(
                      label: 'SIMULA!',
                      fontSize: 12,
                      onPressed: () {
                        ref
                            .read(gameProvider.notifier)
                            .selectCharacter(allCharacters[_selectedIndex].id);
                        context.go('/era-selection');
                      },
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

  Color _getCharColor(String id) {
    switch (id) {
      case 'lapu':
        return const Color(0xFF6B3A1F);
      case 'rizal':
        return const Color(0xFF2C3E50);
      case 'mabini':
        return const Color(0xFF1A5276);
      case 'escoda':
        return const Color(0xFFC0392B);
      case 'aquino':
        return const Color(0xFFD4AC0D);
      default:
        return const Color(0xFF2C3E50);
    }
  }
}

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
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.primaryDark, width: 2),
          ),
          child: Icon(icon, color: AppColors.accent, size: 20),
        ),
      ),
    );
  }
}