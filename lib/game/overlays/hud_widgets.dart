import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/combat_constants.dart';
import '../../core/constants.dart';
import '../chrono_game.dart';

/// A row of equal segments, the first [filled] of them lit. Used for both
/// the health and Kaalaman bars so they read as one family.
class _SegmentRow extends StatelessWidget {
  final int segments;
  final int filled;
  final Color color;
  final double gap;

  const _SegmentRow({
    required this.segments,
    required this.filled,
    required this.color,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(segments, (i) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == segments - 1 ? 0 : gap),
            color: i < filled ? color : Colors.black38,
          ),
        );
      }),
    );
  }
}

/// Top-left resource block: a wide health bar with a thinner Kaalaman bar
/// hanging directly beneath it.
class HudStatusBars extends StatelessWidget {
  final ChronoGame game;
  const HudStatusBars({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    const hpWidth = 156.0;
    final hearts = game.hearts.clamp(0, GameConstants.maxHearts);
    final kaalaman = game.kaalaman.clamp(0, CombatConstants.kaalamanDisplayMax);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Buhay: $hearts / ${GameConstants.maxHearts}',
          child: Container(
            width: hpWidth,
            height: 26,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryDark, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _SegmentRow(
                    segments: GameConstants.maxHearts,
                    filled: hearts,
                    color: AppColors.danger,
                    gap: 2,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        '$hearts/${GameConstants.maxHearts}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          shadows: const [
                            Shadow(blurRadius: 2, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Semantics(
          label: 'Kaalaman: ${game.kaalaman}',
          child: Container(
            width: hpWidth * 0.72,
            height: 10,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryDark, width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: _SegmentRow(
                segments: CombatConstants.kaalamanDisplayMax,
                filled: kaalaman,
                color: AppColors.info,
                gap: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Top-centre pill: how many artifacts have been answered, out of the
/// level's total. Hidden on levels with none (boss levels), so it never
/// shows a meaningless 0/0.
///
/// Counts *answered*, not *claimed*. Since 2026-10-03 the end gate opens on
/// every artifact having been answered right **or wrong**, so a counter
/// tracking only correct answers would tell a student they still had work to
/// do when in fact the gate was already open. The gate itself is no longer
/// counted here: there is exactly one per level and it is the exit, so a
/// "0/1" told nobody anything.
class HudProgressPill extends StatelessWidget {
  final ChronoGame game;
  const HudProgressPill({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    if (game.artifactsTotal == 0) {
      return const SizedBox.shrink();
    }

    final allAnswered = game.canPassEndGate;
    return Semantics(
      label: 'Mga artifact na nasagot: ${game.artifactsAnswered} ng '
          '${game.artifactsTotal}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          border: allAnswered
              ? Border.all(color: AppColors.success, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/collectibles/artifact_1.png',
                width: 18, height: 18),
            const SizedBox(width: 6),
            _Count(game.artifactsAnswered, game.artifactsTotal),
            if (allAnswered) ...[
              const SizedBox(width: 8),
              // The gate is open — the student can head for the exit.
              const Icon(Icons.lock_open,
                  size: 16, color: AppColors.success),
            ],
          ],
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final int done;
  final int total;
  const _Count(this.done, this.total);

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$done',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        children: [
          TextSpan(
            text: '/$total',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Score and coins in one shared panel with a divider between them.
class HudStatsPanel extends StatelessWidget {
  final ChronoGame game;
  const HudStatsPanel({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/ui/star_full.png', width: 16, height: 16),
          const SizedBox(width: 5),
          _statText('${game.score}'),
          Container(
            width: 1,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: Colors.white38,
          ),
          Image.asset('assets/collectibles/coin.png', width: 16, height: 16),
          const SizedBox(width: 5),
          _statText('${game.playerCoins}'),
        ],
      ),
    );
  }

  Widget _statText(String text) => Text(
        text,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, height: 1.4),
      );
}
