import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/game_provider.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/living_backdrop.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/pixel_icon.dart';

String _formatCountdown(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// A level lost: the hero, hurt, in red light; "SUBUKAN ULIT!", the hearts that are
/// left, and three buttons: ULIT (gold, the big one), the shop and the way back,
/// both as icons. With no hearts left ULIT waits and a small clock says how long.
class LevelFailedScreen extends ConsumerWidget {
  final String eraId;
  final int level;
  const LevelFailedScreen({
    super.key,
    required this.eraId,
    required this.level,
  });

  static const retryKey = Key('level_failed_retry');
  static const shopKey = Key('level_failed_shop');
  static const backKey = Key('level_failed_back');
  static const heartsKey = Key('level_failed_hearts');
  static const timerKey = Key('level_failed_timer');
  static const heroKey = Key('level_failed_hero');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final hearts = game.hearts;
    final hasHearts = ref.read(gameProvider.notifier).canStartLevel;
    final timeUntilNext = ref.read(gameProvider.notifier).heartCountdown;
    final wide = MediaQuery.sizeOf(context).width >= 560;

    final hero = Image.asset(
      'assets/characters/${game.selectedCharacterId}_hurt.png',
      key: heroKey,
      height: wide ? 150 : 110,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) =>
          SizedBox(height: wide ? 150 : 110, width: 80),
    );

    final words = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          'SUBUKAN ULIT!',
          style: GoogleFonts.poppins(
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFF8F86),
            shadows: const [
              Shadow(color: AppColors.primaryDark, offset: Offset(0, 4))
            ],
          ),
        ),
        const SizedBox(height: 10),
        // The hearts left: the one shared pool this failure just drew from, drawn
        // with the same icons as the game's own hearts.
        Row(
          key: heartsKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < GameConstants.maxHearts; i++)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Image.asset(
                  i < hearts.count
                      ? 'assets/ui/heart_full.png'
                      : 'assets/ui/heart_empty.png',
                  width: 24,
                  height: 24,
                  filterQuality: FilterQuality.none,
                ),
              ),
            // Out of hearts: when the next one comes, or that it needs the internet.
            if (!hasHearts) ...[
              const SizedBox(width: 6),
              Icon(Icons.schedule,
                  size: 18, color: Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              Text(
                timeUntilNext != null
                    ? _formatCountdown(timeUntilNext)
                    : 'Mag-online',
                key: timerKey,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Retry is disabled once the hearts pool is empty, until one regenerates.
            GameButton(
              key: retryKey,
              label: 'ULIT',
              icon: Icons.refresh,
              width: 170,
              onPressed:
                  hasHearts ? () => context.go('/game/$eraId/$level') : null,
            ),
            const SizedBox(width: 10),
            // Out of hearts, or short of a power-up: the shop.
            MenuChip(
              key: shopKey,
              icon: PixelGlyph.cart,
              tooltip: 'Tindahan',
              onTap: () => context.push('/shop'),
            ),
            const SizedBox(width: 6),
            MenuChip(
              key: backKey,
              icon: PixelGlyph.back,
              tooltip: 'Bumalik',
              onTap: () => context.go('/level-select/$eraId'),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A1620), Color(0xFF1A0A10)],
          ),
        ),
        child: Stack(
          children: [
            // Red light, slow. The hero is not lit by it: it is in the dark.
            Positioned.fill(
              child: LivingBackdrop(
                color: AppColors.danger,
                fireflies: 0,
                center: wide ? const Offset(0.3, 0.5) : const Offset(0.5, 0.25),
              ),
            ),
            SafeArea(
              child: Center(
                // Scrolls only on a screen too short for it.
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: wide
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            hero,
                            const SizedBox(width: 44),
                            Flexible(child: words)
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [hero, const SizedBox(height: 14), words],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
