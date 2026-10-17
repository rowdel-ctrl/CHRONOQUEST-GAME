import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/unlock_all_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/character_portrait.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/menu_top_bar.dart';
import '../../widgets/pixel_icon.dart';
import 'codex_screen.dart';

/// The student's own page: who they are, how far each era has got, and what
/// they carry. Built from the same parts as the other menu screens (the shared
/// top bar, parchment panels, pixel icons) instead of its own look.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  /// Below this width the identity card sits above the journey, not beside it.
  static const double twoColumnMinWidth = 520;

  static const Key codexKey = Key('profile_codex');

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Reached from character select now, which does not load progress.
    Future.microtask(() {
      ref.read(progressProvider.notifier).loadProgress();
      // The score changes on the server after every level.
      ref.read(authProvider.notifier).refreshProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(authProvider).student;
    final game = ref.watch(gameProvider);
    final characterId = game.selectedCharacterId;

    return Scaffold(
      body: GameBackdrop(
        baseColor: AppColors.background,
        child: SafeArea(
          child: Column(
            children: [
              MenuTopBar(
                title: 'PROFILE',
                onBack: () => context.canPop()
                    ? context.pop()
                    : context.go('/era-selection'),
                // Profile hides its own chip; Settings stays right-most.
                actions: [
                  MenuChip(
                    icon: PixelGlyph.gear,
                    tooltip: 'Settings',
                    onTap: () => context.push('/settings'),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: LayoutBuilder(builder: (context, box) {
                    final identity = _IdentityCard(
                      characterId: characterId,
                      name: student?.name ?? 'Student',
                      classCode: student?.classCode ?? '',
                      school: student?.schoolName ?? '',
                      score: student?.score ?? 0,
                      coins: game.coins,
                    );
                    final journey = _Journey(
                      gradeLevel: student?.gradeLevel ?? 'grade5',
                    );
                    if (box.maxWidth >= ProfileScreen.twoColumnMinWidth) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 212, child: identity),
                          const SizedBox(width: 14),
                          Expanded(child: journey),
                        ],
                      );
                    }
                    return Column(
                      children: [identity, const SizedBox(height: 14), journey],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 1240 -> "1,240".
String _grouped(int n) {
  final s = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

/// Portrait, name, class code, school, and the two totals.
class _IdentityCard extends StatelessWidget {
  final String characterId;
  final String name;
  final String classCode;
  final String school;
  final int score;
  final int coins;

  const _IdentityCard({
    required this.characterId,
    required this.name,
    required this.classCode,
    required this.school,
    required this.score,
    required this.coins,
  });

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      color: AppColors.surface,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          CharacterPortrait(characterId: characterId, width: 70, height: 84),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),
          if (classCode.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                border: Border.all(color: AppColors.primaryDark, width: 2),
              ),
              child: Text(
                classCode,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
          if (school.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              school,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Total(
                  image: 'assets/ui/star_full.png',
                  value: _grouped(score),
                  label: 'Puntos',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Total(
                  image: 'assets/collectibles/coin.png',
                  value: _grouped(coins),
                  label: 'Coins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final String image;
  final String value;
  final String label;

  const _Total({required this.image, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.primaryDark, width: 2),
      ),
      child: Column(
        children: [
          Image.asset(image,
              width: 18, height: 18, filterQuality: FilterQuality.none),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// The six eras with their progress, then the powerups and the Kodeks.
class _Journey extends ConsumerWidget {
  final String gradeLevel;

  const _Journey({required this.gradeLevel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched so the tiles redraw when progress finishes loading.
    ref.watch(progressProvider);
    final progress = ref.read(progressProvider.notifier);
    final unlockAll = ref.watch(unlockAllProvider);
    final gradeIds = allEras
        .where((e) => 'grade${e.grade}' == gradeLevel)
        .map((e) => e.id)
        .toList();

    final tiles = [
      for (final era in allEras)
        _EraTile(
          name: era.name,
          total: era.levels.length,
          done: progress.getEraProgress(era.id).levelsCompleted,
          completed: progress.getEraProgress(era.id).isCompleted,
          locked: !unlockAll &&
              !(gradeIds.contains(era.id) &&
                  progress.isEraUnlocked(era.id, gradeIds)),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PAGLALAKBAY',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: 8),
              Expanded(child: tiles[i + 1]),
            ],
          ),
        ],
        const SizedBox(height: 8),
        const _Shop(),
        const SizedBox(height: 8),
        const _Kodeks(),
      ],
    );
  }
}

/// One era: its title, a pip for every level, and how far along it is.
class _EraTile extends StatelessWidget {
  final String name;
  final int total;
  final int done;
  final bool completed;
  final bool locked;

  const _EraTile({
    required this.name,
    required this.total,
    required this.done,
    required this.completed,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    final dim = locked && done == 0 && !completed;
    final filled = completed ? total : done.clamp(0, total);
    final ink = dim ? AppColors.textSecondary : AppColors.textPrimary;

    return GamePanel(
      color: dim ? const Color(0xFFCDB78F) : AppColors.surface,
      borderWidth: 2,
      shadowOffset: 3,
      borderRadius: 4,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: SizedBox(
        height: 42,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: ink,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      for (var i = 0; i < total; i++) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Expanded(
                          child: Container(
                            height: 7,
                            decoration: BoxDecoration(
                              color: i < filled
                                  ? AppColors.success
                                  : const Color(0xFFB99A68),
                              border: Border.all(
                                  color: AppColors.primaryDark, width: 1),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (completed)
                  Image.asset('assets/ui/star_full.png',
                      width: 16, height: 16, filterQuality: FilterQuality.none)
                else if (dim)
                  Opacity(
                    opacity: 0.6,
                    child: Image.asset('assets/ui/lock_icon.png',
                        width: 16,
                        height: 16,
                        filterQuality: FilterQuality.none),
                  )
                else
                  Text(
                    '$done/$total',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1.1,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// What the student carries, and the way to the shop. The coins and the
/// power-ups are the phone's own wallet (GameNotifier); buying happens on the
/// TINDAHAN screen.
class _Shop extends ConsumerWidget {
  const _Shop();

  static const Key openKey = Key('profile_open_shop');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final line = GoogleFonts.poppins(
      fontSize: 11,
      height: 1.3,
      color: AppColors.textSecondary,
    );

    return GamePanel(
      color: AppColors.surface,
      borderWidth: 2,
      shadowOffset: 3,
      borderRadius: 4,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'MGA GAMIT',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Image.asset('assets/collectibles/coin.png', width: 14, height: 14),
              const SizedBox(width: 4),
              Text(
                _grouped(game.coins),
                key: const ValueKey('shop_coins'),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('50/50  ×${game.powerUps.fiftyFifty}', style: line),
          Text('Shield  ×${game.powerUps.shield}', style: line),
          Text('Time Freeze  ×${game.powerUps.timeFreeze}', style: line),
          const SizedBox(height: 8),
          GameButton(
            key: openKey,
            label: 'TINDAHAN',
            leading: const PixelIcon(PixelGlyph.cart,
                size: 18, color: AppColors.primaryDark),
            fontSize: 9,
            minHeight: 38,
            onPressed: () => context.push('/shop'),
          ),
        ],
      ),
    );
  }
}

/// Claimed artifacts (GAMEPLAY-V2.md Section 6). Opens its own screen rather
/// than inlining a grid here, since the collection grows past what fits.
class _Kodeks extends StatelessWidget {
  const _Kodeks();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Buksan ang Codex',
      child: GestureDetector(
        key: ProfileScreen.codexKey,
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CodexScreen()),
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            border: Border.all(color: AppColors.primaryDark, width: 2),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.primaryDark,
                  offset: Offset(3, 3),
                  blurRadius: 0),
            ],
          ),
          child: Row(
            children: [
              Image.asset('assets/collectibles/artifact_1.png',
                  width: 26, height: 26, filterQuality: FilterQuality.none),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'KODEKS',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ),
              Text(
                '${StorageService.getCodexTotal()}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              const PixelIcon(PixelGlyph.chevron,
                  size: 16, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
