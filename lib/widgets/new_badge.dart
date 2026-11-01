import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../models/badge_defs.dart';
import '../providers/badge_provider.dart';
import 'badge_medal.dart';
import 'game_ui.dart';
import 'living_backdrop.dart';
import 'pixel_icon.dart';

/// The badge to make most of among several: a trophy, then an era medal, then the first.
EarnedBadge mainBadge(List<EarnedBadge> badges) {
  for (final prefix in const ['champ:', 'era:']) {
    for (final b in badges) {
      if (b.id.startsWith(prefix)) return b;
    }
  }
  return badges.first;
}

/// Whether [badges] has a medal worth a pop-up (an era's boss or a grade's trophy).
bool hasBossBadge(List<EarnedBadge> badges) =>
    badges.any((b) => b.id.startsWith('era:') || b.id.startsWith('champ:'));

/// "BAGONG BADGE!" as a strip across the top for about three seconds: the badge, its
/// coin gift, and a way to the shelf. With more than one, the main one and "+2 pa".
/// Put it at the top of the screen's Stack.
class NewBadgeStrip extends StatefulWidget {
  final List<EarnedBadge> badges;

  /// How long it stays.
  final Duration stay;

  const NewBadgeStrip({
    super.key,
    required this.badges,
    this.stay = const Duration(milliseconds: 3500),
  });

  static const Key stripKey = Key('new_badge_strip');

  @override
  State<NewBadgeStrip> createState() => _NewBadgeStripState();
}

class _NewBadgeStripState extends State<NewBadgeStrip> {
  bool _shown = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.stay, () {
      if (mounted) setState(() => _shown = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.badges.isEmpty) return const SizedBox.shrink();
    final main = mainBadge(widget.badges);
    final more = widget.badges.length - 1;
    final coins = widget.badges.fold<int>(0, (sum, b) => sum + b.coins);
    final moves = motionAllowed(context);
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
          child: AnimatedSlide(
            duration: moves ? const Duration(milliseconds: 300) : Duration.zero,
            curve: Curves.easeOutBack,
            offset: _shown ? Offset.zero : const Offset(0, -1.6),
            child: AnimatedOpacity(
              duration:
                  moves ? const Duration(milliseconds: 300) : Duration.zero,
              opacity: _shown ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_shown,
                child: Semantics(
                  button: true,
                  label: 'Bagong badge: ${main.title}. Buksan ang mga badge',
                  excludeSemantics: true,
                  child: GestureDetector(
                    key: NewBadgeStrip.stripKey,
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push('/badges'),
                    child: _StripBody(
                      badge: main,
                      more: more,
                      coins: coins,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StripBody extends StatelessWidget {
  final EarnedBadge badge;
  final int more;
  final int coins;
  const _StripBody(
      {required this.badge, required this.more, required this.coins});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 5, 14, 5),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.primaryDark, width: 3),
          boxShadow: const [
            BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            BadgeMedal(
              glyph: badge.family.glyph,
              metal: badge.step.metal,
              honor: badge.family.honor,
              width: 32,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BAGONG BADGE!',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.accent,
                    ),
                  ),
                  Text(
                    more > 0 ? '${badge.title}  +$more pa' : badge.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (coins > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/collectibles/coin.png',
                            width: 11,
                            height: 11,
                            filterQuality: FilterQuality.none),
                        const SizedBox(width: 4),
                        Text(
                          '+$coins coins',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            height: 1.2,
                            color: const Color(0xFFCDBA94),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const PixelIcon(PixelGlyph.chevron,
                size: 16, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

/// The one line on the eras screen for badges that came with the update or a new
/// phone: "May 11 bagong badge ka sa Profile!". Shows for a few seconds and goes; a
/// tap goes to the shelf. Nothing when there is nothing to say.
class QuietBadgeNote extends ConsumerStatefulWidget {
  final Duration stay;
  const QuietBadgeNote({super.key, this.stay = const Duration(seconds: 6)});

  static const Key noteKey = Key('quiet_badge_note');

  @override
  ConsumerState<QuietBadgeNote> createState() => _QuietBadgeNoteState();
}

class _QuietBadgeNoteState extends ConsumerState<QuietBadgeNote> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _arm(ref.read(badgeProvider).quietCount));
  }

  void _arm(int count) {
    if (!mounted) return;
    if (count > 0) {
      _timer ??= Timer(widget.stay, () {
        if (mounted) ref.read(badgeProvider.notifier).clearQuiet();
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(
        badgeProvider.select((s) => s.quietCount), (_, n) => _arm(n));
    final count = ref.watch(badgeProvider.select((s) => s.quietCount));
    if (count <= 0) return const SizedBox.shrink();
    return Semantics(
      button: true,
      label: 'May $count bagong badge ka sa Profile. Buksan ang mga badge',
      excludeSemantics: true,
      child: GestureDetector(
        key: QuietBadgeNote.noteKey,
        behavior: HitTestBehavior.opaque,
        onTap: () {
          ref.read(badgeProvider.notifier).clearQuiet();
          context.push('/badges');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.primaryDark, width: 3),
            boxShadow: const [
              BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 3))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PixelIcon(PixelGlyph.trophy,
                  size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'May $count bagong badge ka sa Profile!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const PixelIcon(PixelGlyph.chevron,
                  size: 14, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// The big pop-up after a boss: the era medal, what it was for, the coin gift, and the
/// other badges that came with it as small medals. Answers when TULOY is tapped.
Future<void> showBossBadges(BuildContext context, List<EarnedBadge> badges) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xB8140E1F),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: BossBadgeCard(badges: badges),
    ),
  );
}

class BossBadgeCard extends StatelessWidget {
  final List<EarnedBadge> badges;
  const BossBadgeCard({super.key, required this.badges});

  static const Key cardKey = Key('boss_badge_card');
  static const Key goKey = Key('boss_badge_go');

  @override
  Widget build(BuildContext context) {
    final main = mainBadge(badges);
    final others = badges.where((b) => b.id != main.id).toList();
    final coins = badges.fold<int>(0, (sum, b) => sum + b.coins);
    final era =
        main.id.startsWith('era:') ? getEraById(main.id.substring(4)) : null;
    final sub = era != null
        ? 'Natalo mo ang ${_cap(era.bossName)}!'
        : 'Natalo mo ang lahat ng boss ng grade mo!';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470),
        child: SingleChildScrollView(
          child: GamePanel(
            key: cardKey,
            color: AppColors.surface,
            borderRadius: 4,
            shadowOffset: 4,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                BadgeMedal(
                  glyph: main.family.glyph,
                  metal: main.step.metal,
                  honor: main.family.honor,
                  width: 82,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                              color: AppColors.primaryDark, width: 2),
                        ),
                        child: Text(
                          'BAGONG BADGE!',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            height: 1.2,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        main.family.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          height: 1.2,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        sub,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          height: 1.3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (coins > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                    color: AppColors.primaryDark, width: 2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset('assets/collectibles/coin.png',
                                      width: 13,
                                      height: 13,
                                      filterQuality: FilterQuality.none),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+$coins',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      height: 1.2,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (others.isNotEmpty) ...[
                            Text(
                              'Kasama pa:',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            for (final b in others.take(4))
                              BadgeMedal(
                                glyph: b.family.glyph,
                                metal: b.step.metal,
                                honor: false,
                                width: 24,
                              ),
                            if (others.length > 4)
                              Text(
                                '+${others.length - 4}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      GameButton(
                        key: goKey,
                        label: 'TULOY',
                        minHeight: 44,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
