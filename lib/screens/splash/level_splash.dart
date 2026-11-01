import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../data/era_story.dart';
import '../../game/components/parallax_background.dart';
import '../../widgets/forest_backdrop.dart';
import '../../widgets/loading_line.dart';
import '../../widgets/scene_clock.dart';

/// What covers a level while it opens: the era, the level (or BOSS), the student's
/// own hero walking through that era's forest, a fact about the era (or the boss's
/// own line), and the same line-to-the-gate as the opening splash. A tap skips it
/// once the level is ready.
class LevelSplash extends StatelessWidget {
  final String eraId;
  final int level;
  final String charId;

  /// True once the level has loaded and has been covered long enough to read.
  final bool ready;
  final VoidCallback? onSkip;

  const LevelSplash({
    super.key,
    required this.eraId,
    required this.level,
    required this.charId,
    required this.ready,
    this.onSkip,
  });

  /// The fact shown for [level]: a beat of the era's story, so it is always true.
  static String factFor(String eraId, int level) {
    final beats = eraStories[eraId]?.beats ?? const <StoryBeat>[];
    if (beats.isEmpty) return '';
    return beats[(level - 1).clamp(0, 1 << 20) % beats.length].text;
  }

  @override
  Widget build(BuildContext context) {
    final era = getEraById(eraId);
    final boss = level == era.levels.length;
    final tint = boss
        ? const Color(0x946E1222)
        : (ParallaxBackground.eraTints[eraId] ?? const Color(0x665E8C3A));
    final bossName = era.bossName.replaceAll('_', ' ').toUpperCase();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: ready ? onSkip : null,
      child: ColoredBox(
        color: const Color(0xFF0F0A18),
        child: SceneClock(
          peek: 1500,
          builder: (context, ms) {
            final progress = ready ? 1.0 : (ms / 2200).clamp(0.0, 0.9);
            return Stack(
              fit: StackFit.expand,
              children: [
                ForestBackdrop(seconds: ms / 1000, tint: tint),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                        radius: 0.95,
                        colors: [Color(0x4D0C0816), Color(0xDB0C0816)]),
                  ),
                ),
                Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 640,
                      height: 300,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 16,
                            left: 0,
                            right: 0,
                            child: Text(
                              era.name.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3.2,
                                color: AppColors.surface,
                                shadows: const [
                                  Shadow(
                                      color: AppColors.primaryDark,
                                      offset: Offset(0, 2))
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 44,
                            left: 0,
                            right: 0,
                            height: 118,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _Walker(charId: charId, ms: ms),
                                const SizedBox(width: 22),
                                _LevelBlock(level: level, boss: boss),
                                if (boss) ...[
                                  const SizedBox(width: 22),
                                  _BossPortrait(name: era.bossName),
                                ],
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 66,
                            left: 320 - 120,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(end: progress),
                              duration: const Duration(milliseconds: 300),
                              builder: (context, v, _) =>
                                  LoadingLine(progress: v, charId: charId),
                            ),
                          ),
                          Positioned(
                            bottom: 14,
                            left: 50,
                            right: 50,
                            child: _FactPill(
                              lead: boss ? '$bossName:' : 'Alam mo ba?',
                              text: boss
                                  ? '“${era.bossDialogue}”'
                                  : factFor(eraId, level),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Walker extends StatelessWidget {
  final String charId;
  final int ms;
  const _Walker({required this.charId, required this.ms});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 104,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: -4,
            child: Container(
                width: 70,
                height: 10,
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(5))),
          ),
          Image.asset(
            'assets/characters/${charId}_walk_${(ms ~/ 140) % 4 + 1}.png',
            width: 80,
            height: 104,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) =>
                const SizedBox(width: 80, height: 104),
          ),
        ],
      ),
    );
  }
}

class _LevelBlock extends StatelessWidget {
  final int level;
  final bool boss;
  const _LevelBlock({required this.level, required this.boss});

  @override
  Widget build(BuildContext context) {
    const shadows = [
      Shadow(color: AppColors.primaryDark, offset: Offset(0, 4)),
      Shadow(color: Color(0x66000000), offset: Offset(0, 8))
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          boss ? 'LEVEL $level' : 'LEVEL',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.4,
            height: 1,
            color: AppColors.surface,
            shadows: const [
              Shadow(color: AppColors.primaryDark, offset: Offset(0, 2))
            ],
          ),
        ),
        Text(
          boss ? 'BOSS' : '$level',
          style: GoogleFonts.poppins(
            fontSize: boss ? 58 : 92,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: boss ? 1 : 0,
            color: AppColors.accent,
            shadows: shadows,
          ),
        ),
      ],
    );
  }
}

class _BossPortrait extends StatelessWidget {
  final String name;
  const _BossPortrait({required this.name});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -30,
            right: -30,
            top: -30,
            bottom: -30,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.danger.withValues(alpha: 0.6),
                  AppColors.danger.withValues(alpha: 0)
                ]),
              ),
            ),
          ),
          Image.asset(
            'assets/bosses/${name}_idle.png',
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, __, ___) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class _FactPill extends StatelessWidget {
  final String lead;
  final String text;
  const _FactPill({required this.lead, required this.text});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.poppins(
        fontSize: 9.6,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: AppColors.surface);
    final parts = text.split('**');
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4A3A5E), width: 2),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
                text: '$lead ',
                style: base.copyWith(
                    color: AppColors.accent, fontWeight: FontWeight.w700)),
            for (var i = 0; i < parts.length; i++)
              TextSpan(
                  text: parts[i],
                  style: i.isOdd
                      ? base.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)
                      : base),
          ],
        ),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
