import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../providers/game_provider.dart';

String formatHeartCountdown(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// The shared heart pool, shown on every menu screen as one heart icon, a
/// count such as 3/5, and a plus button that opens the buy-a-heart dialog.
///
/// Hearts gate starting *and* retrying a level, so a student needs to see
/// them before they commit to a screen that leads into one. The countdown to
/// the next free heart only renders when the pool is short, so a full pool
/// stays quiet.
///
/// Owns its own 1s ticker: `HeartsState.regenerated()` is computed lazily
/// from a stored timestamp, so without something calling `refreshHearts()`
/// the count and countdown would both sit stale until the next rebuild.
class HeartsPill extends ConsumerStatefulWidget {
  final double heartSize;

  /// What the plus button does; by default it opens the shop.
  final VoidCallback? onBuy;

  const HeartsPill({super.key, this.heartSize = 16, this.onBuy});

  @override
  ConsumerState<HeartsPill> createState() => _HeartsPillState();
}

class _HeartsPillState extends ConsumerState<HeartsPill> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => ref.read(gameProvider.notifier).refreshHearts(),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hearts = ref.watch(gameProvider).hearts;
    final timeUntilNext = ref.read(gameProvider.notifier).heartCountdown;
    final isFull = hearts.count >= GameConstants.maxHearts;
    final isEmpty = hearts.count <= 0;

    return Semantics(
      label: 'Puso: ${hearts.count} sa ${GameConstants.maxHearts}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              isEmpty ? 'assets/ui/heart_empty.png' : 'assets/ui/heart_full.png',
              width: widget.heartSize,
              height: widget.heartSize,
            ),
            const SizedBox(width: 6),
            Text.rich(
              TextSpan(
                text: '${hearts.count}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                children: [
                  TextSpan(
                    text: '/${GameConstants.maxHearts}',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (timeUntilNext != null) ...[
              const SizedBox(width: 6),
              Text(
                formatHeartCountdown(timeUntilNext),
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(width: 8),
            _PlusButton(
              enabled: !isFull,
              onTap: widget.onBuy ?? () => context.push('/shop'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlusButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _PlusButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Still tappable when greyed out: a full pool gets an explanation rather
    // than a button that silently does nothing.
    return Semantics(
      button: true,
      label: 'Bumili ng puso',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? AppColors.accent : Colors.white24,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: enabled ? AppColors.primaryDark : Colors.white30,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.add,
            size: 18,
            color: enabled ? AppColors.primaryDark : Colors.white54,
          ),
        ),
      ),
    );
  }
}
