import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/game_provider.dart';

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paano Maglaro',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
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
              style: const TextStyle(
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C1810),
              Color(0xFF3E2723),
              Color(0xFF4E342E),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Title
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Text(
                  'Piliin ang Iyong Bayani',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ),

              // Left side cards
              Positioned(
                left: 12,
                top: 60,
                child: Column(
                  children: [
                    _SideCard(
                      icon: Icons.menu_book,
                      label: 'Mechanics',
                      onTap: _showMechanics,
                    ),
                    const SizedBox(height: 8),
                    _SideCard(
                      icon: Icons.emoji_events,
                      label: 'Leaderboard',
                      onTap: () => context.push('/leaderboard'),
                    ),
                  ],
                ),
              ),

              // Character carousel
              Positioned(
                top: 50,
                bottom: 60,
                left: 80,
                right: 80,
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
                        vertical: isSelected ? 8 : 24,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.surface
                            : AppColors.surface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Character avatar placeholder
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: _getCharColor(char.id),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accent,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  char.name[0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              char.name,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              char.era,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                char.description,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.accent.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
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

              // Bottom: dots + start button
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Page dots
                    Row(
                      children: List.generate(
                        allCharacters.length,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _selectedIndex ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _selectedIndex
                                ? AppColors.accent
                                : Colors.white30,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Start button
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(gameProvider.notifier)
                            .selectCharacter(allCharacters[_selectedIndex].id);
                        context.go('/era-selection');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'SIMULA!',
                        style: GoogleFonts.sourceSans3(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
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

  Color _getCharColor(String id) {
    switch (id) {
      case 'lapu':
        return const Color(0xFF8B4513);
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

class _SideCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SideCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
