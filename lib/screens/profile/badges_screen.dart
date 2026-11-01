import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/badge_defs.dart';
import '../../models/badge_facts.dart';
import '../../providers/badge_provider.dart';
import '../../services/badge_rules.dart';
import '../../services/storage_service.dart';
import '../../widgets/badge_medal.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/living_backdrop.dart';
import '../../widgets/menu_top_bar.dart';
import '../../widgets/pixel_icon.dart';

/// The shelf (MGA BADGE): every badge in three rows of tiles, the earned ones in
/// colour and the rest dark with how far they are. A tile opens what the badge needs.
/// A badge earned since the shelf was last open carries a red BAGO tag.
class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});

  static const Key countKey = Key('badges_count');
  static const Key detailKey = Key('badge_detail');
  static const Key closeKey = Key('badge_detail_close');
  static Key tileKey(String familyId) => ValueKey('badge_tile_$familyId');
  static Key newKey(String familyId) => ValueKey('badge_new_$familyId');
  static Key stepKey(String badgeId) => ValueKey('badge_step_$badgeId');

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {
  /// What was new when the shelf opened. The tags stay for this visit; the next one
  /// finds them gone.
  late Set<String> _fresh = ref.read(badgeProvider).facts.unseen;

  @override
  void initState() {
    super.initState();
    // Not in this build: a provider may not change while the tree is being built.
    Future<void>.microtask(() {
      if (!mounted) return;
      final notifier = ref.read(badgeProvider.notifier);
      notifier.refresh(); // the Kodeks may have grown since the last level
      setState(() => _fresh = ref.read(badgeProvider).facts.unseen);
      notifier.markAllSeen();
    });
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(badgeProvider);
    final codex = StorageService.getCodexTotal();

    Widget group(String label, BadgeGroup g) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.6,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: [
                for (final f in badgeFamilies.where((f) => f.group == g))
                  _Tile(
                    family: f,
                    facts: state.facts,
                    codex: codex,
                    isNew: f.steps.any((s) => _fresh.contains(s.id)),
                    onTap: () =>
                        showBadgeDetail(context, f, state.facts, codex),
                  ),
              ],
            ),
          ],
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: LivingBackdrop(
              center: Offset(0.5, 0.2),
              fireflies: 0,
              rays: false,
              animate: false,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                MenuTopBar(
                  title: 'MGA BADGE',
                  onBack: _back,
                  actions: [_CountPill(earned: state.earnedCount)],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            group('HUSAY', BadgeGroup.husay),
                            const SizedBox(height: 16),
                            group('PAGLALAKBAY', BadgeGroup.paglalakbay),
                            const SizedBox(height: 16),
                            group('KODEKS AT SIPAG', BadgeGroup.kodeks),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// How much of the badge is done, as one short line under its name.
String badgeSubtitle(BadgeFamily f, BadgeFacts facts, int codex) {
  final got = BadgeRules.progress(f, facts, codexTotal: codex);
  final held = f.steps.where((s) => facts.earned.containsKey(s.id)).length;
  if (f.id.startsWith('era:')) return held > 0 ? 'Natalo si Boss' : 'Boss';
  if (f.id == 'firstbuy') return held > 0 ? 'Nakuha na' : 'Tindahan';
  if (f.id == 'bossclean') return held > 0 ? 'Nakuha na' : 'Boss';
  final unit = f.id == 'collector' || f.unit.isEmpty ? '' : ' ${f.unit}';
  if (held == f.steps.length) return '$got$unit';
  final next = f.steps.firstWhere((s) => !facts.earned.containsKey(s.id));
  return '${got.clamp(0, next.need)}/${next.need}$unit';
}

/// The metal of the badge's best level held, or null if it holds none.
BadgeMetal? heldMetal(BadgeFamily f, BadgeFacts facts) {
  BadgeMetal? metal;
  for (final s in f.steps) {
    if (facts.earned.containsKey(s.id)) metal = s.metal;
  }
  return metal;
}

class _CountPill extends StatelessWidget {
  final int earned;
  const _CountPill({required this.earned});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xB8140E1F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PixelIcon(PixelGlyph.trophy, size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            '$earned/${allBadgeSteps.length}',
            key: BadgesScreen.countKey,
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

/// One badge on the shelf: its medal, its name, and how far it is.
class _Tile extends StatelessWidget {
  final BadgeFamily family;
  final BadgeFacts facts;
  final int codex;
  final bool isNew;
  final VoidCallback onTap;

  const _Tile({
    required this.family,
    required this.facts,
    required this.codex,
    required this.isNew,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final metal = heldMetal(family, facts);
    final locked = metal == null;
    final sub = badgeSubtitle(family, facts, codex);
    return Semantics(
      button: true,
      label:
          '${family.shelfName}, $sub, ${locked ? 'hindi pa nakukuha' : 'nakuha na'}',
      excludeSemantics: true,
      child: GestureDetector(
        key: BadgesScreen.tileKey(family.id),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 86,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  BadgeMedal(
                      glyph: family.glyph,
                      metal: metal,
                      honor: family.honor,
                      width: 44),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 28,
                    child: Center(
                      child: Text(
                        family.shelfName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: locked
                              ? const Color(0xFF9B8DB5)
                              : const Color(0xFFF5E3BE),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      height: 1.2,
                      color: locked
                          ? const Color(0xFF8A7BA3)
                          : const Color(0xFFCDBA94),
                    ),
                  ),
                ],
              ),
              if (isNew)
                Positioned(
                  top: -2,
                  right: 0,
                  child: Container(
                    key: BadgesScreen.newKey(family.id),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'BAGO',
                      style: GoogleFonts.poppins(
                        fontSize: 8.5,
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
      ),
    );
  }
}

/// What a badge needs: its levels, the coin gift for each, and how far the next one is.
Future<void> showBadgeDetail(
    BuildContext context, BadgeFamily f, BadgeFacts facts, int codex) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x8C140E1F),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: BadgeDetail(family: f, facts: facts, codex: codex),
    ),
  );
}

class BadgeDetail extends StatelessWidget {
  final BadgeFamily family;
  final BadgeFacts facts;
  final int codex;
  const BadgeDetail(
      {super.key,
      required this.family,
      required this.facts,
      required this.codex});

  @override
  Widget build(BuildContext context) {
    final got = BadgeRules.progress(family, facts, codexTotal: codex);
    final next = family.steps.cast<BadgeStep?>().firstWhere(
          (s) => !facts.earned.containsKey(s!.id),
          orElse: () => null,
        );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: GamePanel(
            key: BadgesScreen.detailKey,
            color: AppColors.surface,
            borderRadius: 4,
            shadowOffset: 4,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    BadgeMedal(
                      glyph: family.glyph,
                      metal: heldMetal(family, facts),
                      honor: family.honor,
                      width: 52,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            family.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              height: 1.15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            family.rule,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              height: 1.3,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final s in family.steps) ...[
                  _StepRow(
                    family: family,
                    step: s,
                    held: facts.earned.containsKey(s.id),
                    current: identical(s, next),
                    got: got,
                  ),
                  const SizedBox(height: 5),
                ],
                const SizedBox(height: 6),
                Center(
                  child: GameButton(
                    key: BadgesScreen.closeKey,
                    label: 'ISARA',
                    width: 170,
                    minHeight: 44,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final BadgeFamily family;
  final BadgeStep step;
  final bool held;

  /// The first one not held: the one being worked on.
  final bool current;
  final int got;
  const _StepRow({
    required this.family,
    required this.step,
    required this.held,
    required this.current,
    required this.got,
  });

  @override
  Widget build(BuildContext context) {
    final metal = metalName(step.metal);
    final unit = family.unit.isEmpty ? '' : ' ${family.unit}';
    final label = family.tiered
        ? '$metal · ${step.need}$unit'
        : (held ? 'Nakuha na' : 'Hindi pa nakukuha');
    final small = GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: AppColors.textSecondary,
    );
    return Container(
      key: BadgesScreen.stepKey(step.id),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: current ? const Color(0xFFFFE9A8) : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.primaryDark, width: 2),
      ),
      child: Row(
        children: [
          BadgeMedal(
            glyph: family.glyph,
            metal: held ? step.metal : null,
            honor: false,
            width: 26,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text('+${step.coins}', style: small),
          const SizedBox(width: 8),
          if (held)
            Text(
              '✓',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F6A1B),
              ),
            )
          else if (current && step.need > 1) ...[
            Container(
              width: 56,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFFB99A68),
                border: Border.all(color: AppColors.primaryDark, width: 1.5),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (got / step.need).clamp(0.0, 1.0),
                child: Container(color: AppColors.success),
              ),
            ),
            const SizedBox(width: 6),
            Text('${got.clamp(0, step.need)}/${step.need}', style: small),
          ] else
            const SizedBox(width: 14),
        ],
      ),
    );
  }
}
