import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/badge_defs.dart';
import '../../models/student.dart';
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/unlock_all_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/living_backdrop.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/menu_top_bar.dart';
import '../../widgets/pixel_icon.dart';
import '../home/character_selection_screen.dart';
import '../home/era_selection_screen.dart';
import 'codex_screen.dart';

/// The student's own page: their hero in its own light, their name, the two
/// totals (points and coins) as round chips, a number and a row of pips for each
/// of the six eras, the power-ups they carry, and two tiles: the Kodeks and the
/// shop. The era titles are on the era screen; here an era is its number.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  /// Below this width the hero sits above the journey, not beside it.
  static const double twoColumnMinWidth = 520;

  static const Key codexKey = Key('profile_codex');
  static const Key badgesKey = Key('profile_badges');
  static const Key badgesNewKey = Key('profile_badges_new');
  static const Key shopKey = Key('profile_open_shop');
  static const Key heroKey = Key('profile_hero');
  static const Key scoreKey = Key('profile_score');
  static const Key coinsKey = Key('profile_coins');
  static Key eraKey(String eraId) => ValueKey('profile_era_$eraId');
  static Key pipKey(String eraId, int i) => ValueKey('profile_pip_${eraId}_$i');
  static Key powerKey(String name) => ValueKey('profile_power_$name');

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
      backgroundColor: AppColors.background,
      // Wide or narrow by the room this page really has, not by the phone's width.
      body: LayoutBuilder(builder: (context, box) {
        final wide = box.maxWidth >= ProfileScreen.twoColumnMinWidth;
        return _page(context, student, game, characterId, wide);
      }),
    );
  }

  Widget _page(BuildContext context, Student? student, GameState game,
      String characterId, bool wide) {
    final identity = _Identity(
      characterId: characterId,
      name: student?.name ?? 'Student',
      classCode: student?.classCode ?? '',
      username: student?.username ?? '',
      score: student?.score ?? 0,
      coins: game.coins,
      compact: !wide,
    );
    final journey =
        _Journey(gradeLevel: student?.gradeLevel ?? 'grade5', narrow: !wide);

    return Stack(
      children: [
        Positioned.fill(
          child: LivingBackdrop(
            color: characterColor(characterId),
            fireflies: 0,
            center: wide ? const Offset(0.16, 0.4) : const Offset(0.5, 0.18),
          ),
        ),
        SafeArea(
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
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 190, child: identity),
                            const SizedBox(width: 18),
                            Expanded(child: journey),
                          ],
                        )
                      : Column(children: [
                          identity,
                          const SizedBox(height: 14),
                          journey
                        ]),
                ),
              ),
            ],
          ),
        ),
      ],
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

/// The hero, the name, and the two totals.
class _Identity extends StatelessWidget {
  final String characterId;
  final String name;
  final String classCode;
  final String username;
  final int score;
  final int coins;
  final bool compact;

  const _Identity({
    required this.characterId,
    required this.name,
    required this.classCode,
    required this.username,
    required this.score,
    required this.coins,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/characters/${characterId}_walk_1.png',
          key: ProfileScreen.heroKey,
          height: compact ? 96 : 120,
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => SizedBox(height: compact ? 96 : 120),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        // Where a student finds the username again, to sign in on another phone.
        if (username.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            username,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
                fontSize: 11, color: const Color(0xFFCDBA94)),
          ),
        ],
        if (classCode.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2), width: 2),
            ),
            child: Text(
              classCode,
              // The phone's own monospace face: no download, and still fixed width.
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _Chip(
              key: ProfileScreen.scoreKey,
              icon: Image.asset('assets/ui/star_full.png',
                  width: 16, height: 16, filterQuality: FilterQuality.none),
              text: _grouped(score),
            ),
            _Chip(
              key: ProfileScreen.coinsKey,
              icon: Image.asset('assets/collectibles/coin.png',
                  width: 16, height: 16, filterQuality: FilterQuality.none),
              text: _grouped(coins),
            ),
          ],
        ),
      ],
    );
  }
}

/// A round chip: a small icon and one number.
class _Chip extends StatelessWidget {
  final Widget icon;
  final String text;
  const _Chip({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.2,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// The six eras with their progress, the power-ups carried, and the two tiles.
class _Journey extends ConsumerWidget {
  final String gradeLevel;

  /// A narrow screen: one column of eras and one tile under the other.
  final bool narrow;

  const _Journey({required this.gradeLevel, required this.narrow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched so the rows redraw when progress finishes loading.
    ref.watch(progressProvider);
    final progress = ref.read(progressProvider.notifier);
    final unlockAll = ref.watch(unlockAllProvider);
    final gradeIds = allEras
        .where((e) => 'grade${e.grade}' == gradeLevel)
        .map((e) => e.id)
        .toList();

    final rows = [
      for (final era in allEras)
        _EraRow(
          era: era,
          number: eraNumberFor(era.id),
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
        if (narrow)
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            rows[i],
          ]
        else
          for (var i = 0; i < rows.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: rows[i]),
                const SizedBox(width: 18),
                Expanded(child: rows[i + 1]),
              ],
            ),
          ],
        const SizedBox(height: 14),
        const _PowerUps(),
        const SizedBox(height: 12),
        if (narrow) ...const [
          _Kodeks(),
          SizedBox(height: 10),
          _BadgesTile(),
          SizedBox(height: 10),
          _ShopTile(),
        ] else
          const Row(
            children: [
              Expanded(child: _Kodeks()),
              SizedBox(width: 10),
              Expanded(child: _BadgesTile()),
              SizedBox(width: 10),
              Expanded(child: _ShopTile()),
            ],
          ),
      ],
    );
  }
}

/// One era: its number in its colour, a pip for every level, and a star when
/// finished or a lock when not yet open.
class _EraRow extends StatelessWidget {
  final EraData era;
  final int number;
  final int done;
  final bool completed;
  final bool locked;

  const _EraRow({
    required this.era,
    required this.number,
    required this.done,
    required this.completed,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    final levels = era.levels.length;
    final filled = completed ? levels : done.clamp(0, levels);
    return Semantics(
      label: locked
          ? '${era.name}, naka-lock'
          : completed
              ? '${era.name}, tapos'
              : '${era.name}, $filled sa $levels',
      child: ExcludeSemantics(
        child: Opacity(
          opacity: locked ? 0.45 : 1,
          child: Row(
            key: ProfileScreen.eraKey(era.id),
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: eraCardColor(era.id),
                  border: Border.all(color: AppColors.primaryDark, width: 2),
                ),
                child: Text(
                  '$number',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < levels; i++) ...[
                      if (i > 0) const SizedBox(width: 2),
                      Expanded(
                        child: Container(
                          key: ProfileScreen.pipKey(era.id, i),
                          height: 7,
                          decoration: BoxDecoration(
                            color: i < filled
                                ? AppColors.success
                                : const Color(0xFF3A2E52),
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
              SizedBox(
                width: 16,
                child: completed
                    ? Image.asset('assets/ui/star_full.png',
                        width: 16,
                        height: 16,
                        filterQuality: FilterQuality.none)
                    : locked
                        ? Image.asset('assets/ui/lock_icon.png',
                            width: 16,
                            height: 16,
                            filterQuality: FilterQuality.none)
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The power-ups the student carries: a picture and a count each. They are the
/// phone's own wallet (GameNotifier); buying happens in the shop.
class _PowerUps extends ConsumerWidget {
  const _PowerUps();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(gameProvider).powerUps;
    Widget item(String name, String asset, int n) => _Chip(
          key: ProfileScreen.powerKey(name),
          icon: Image.asset(asset,
              width: 22, height: 22, filterQuality: FilterQuality.none),
          text: '×$n',
        );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        item('fiftyFifty', 'assets/powerups/fifty_fifty.png', p.fiftyFifty),
        item('shield', 'assets/powerups/shield.png', p.shield),
        item('timeFreeze', 'assets/powerups/time_freeze.png', p.timeFreeze),
      ],
    );
  }
}

/// A wooden tile with an icon on the left and a number or nothing on the right. A
/// [tag] is a small red label on its corner ("BAGO 3").
class _Tile extends StatelessWidget {
  final Widget icon;
  final String label;
  final String? trailing;
  final String? tag;
  final Key? tagKey;
  final String semantics;
  final VoidCallback onTap;

  const _Tile({
    super.key,
    required this.icon,
    required this.label,
    required this.semantics,
    required this.onTap,
    this.trailing,
    this.tag,
    this.tagKey,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                border: Border.all(color: AppColors.primaryDark, width: 3),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 3))
                ],
              ),
              child: Row(
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Expanded(
                    // A long label shrinks a little rather than wrapping.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                  if (trailing != null)
                    Text(
                      trailing!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
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
            if (tag != null)
              Positioned(
                top: -7,
                right: 10,
                child: Container(
                  key: tagKey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(3),
                    border:
                        Border.all(color: AppColors.primaryDark, width: 1.5),
                  ),
                  child: Text(
                    tag!,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      height: 1.3,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

/// The way to the shelf of badges: how many are held, and BAGO with the count of the
/// ones not looked at yet.
class _BadgesTile extends ConsumerWidget {
  const _BadgesTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(badgeProvider);
    return _Tile(
      key: ProfileScreen.badgesKey,
      icon:
          const PixelIcon(PixelGlyph.trophy, size: 26, color: AppColors.accent),
      label: 'MGA BADGE',
      trailing: '${badges.earnedCount}/${allBadgeSteps.length}',
      tag: badges.unseenCount > 0 ? 'BAGO ${badges.unseenCount}' : null,
      tagKey: ProfileScreen.badgesNewKey,
      semantics: badges.unseenCount > 0
          ? 'Buksan ang mga badge, ${badges.unseenCount} bago'
          : 'Buksan ang mga badge',
      onTap: () => context.push('/badges'),
    );
  }
}

/// The way to the shop.
class _ShopTile extends StatelessWidget {
  const _ShopTile();

  @override
  Widget build(BuildContext context) {
    return _Tile(
      key: ProfileScreen.shopKey,
      icon: const PixelIcon(PixelGlyph.cart, size: 26, color: AppColors.accent),
      label: 'TINDAHAN',
      semantics: 'Buksan ang Tindahan',
      onTap: () => context.push('/shop'),
    );
  }
}

/// Claimed artifacts (GAMEPLAY-V2.md Section 6). Opens its own screen rather
/// than inlining a grid here, since the collection grows past what fits.
class _Kodeks extends StatelessWidget {
  const _Kodeks();

  @override
  Widget build(BuildContext context) {
    return _Tile(
      key: ProfileScreen.codexKey,
      icon: Image.asset('assets/collectibles/artifact_1.png',
          width: 26, height: 26, filterQuality: FilterQuality.none),
      label: 'KODEKS',
      trailing: '${StorageService.getCodexTotal()}',
      semantics: 'Buksan ang Codex',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CodexScreen()),
      ),
    );
  }
}
