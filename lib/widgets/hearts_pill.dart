import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../providers/game_provider.dart';
import 'game_ui.dart';

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

  const HeartsPill({super.key, this.heartSize = 16});

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
              onTap: () => showBuyHeartDialog(context),
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

/// The buy-a-heart dialog opened by the plus button.
///
/// Three states: the pool is already full (nothing to buy), the student
/// cannot afford it, or they can and BILHIN spends the coins and adds a heart.
/// The coins are the wallet's (`GameNotifier.buyHeart`), kept on the phone.
Future<void> showBuyHeartDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _BuyHeartDialog(),
  );
}

class _BuyHeartDialog extends ConsumerWidget {
  const _BuyHeartDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hearts = ref.watch(gameProvider).hearts;
    final coins = ref.watch(gameProvider).coins;
    const price = GameConstants.heartPriceCoins;
    final isFull = hearts.count >= GameConstants.maxHearts;
    final canAfford = coins >= price;

    final textStyle = GoogleFonts.poppins(
      fontSize: 13,
      height: 1.5,
      color: AppColors.textSecondary,
    );

    Widget line(String label, Widget value) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: textStyle),
              value,
            ],
          ),
        );

    Widget coinText(int n) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/collectibles/coin.png', width: 16, height: 16),
            const SizedBox(width: 4),
            Text(
              '$n',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        );

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: GamePanel(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isFull ? 'Puno na ang Puso' : 'Bumili ng Puso',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                if (isFull)
                  Text(
                    'Hindi mo na kailangang bumili. May '
                    '${GameConstants.maxHearts} puso ka na.',
                    style: textStyle,
                  )
                else ...[
                  Text(
                    'Gamitin ang coins para makakuha agad ng isang puso.',
                    style: textStyle,
                  ),
                  const SizedBox(height: 10),
                  line('Presyo', coinText(price)),
                  line('Iyong coins', coinText(coins)),
                  line(
                    'Puso',
                    Text(
                      '${hearts.count}/${GameConstants.maxHearts}  →  '
                      '${hearts.count + 1}/${GameConstants.maxHearts}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (!canAfford)
                    Text(
                      'Kulang ang coins. Mangolekta pa sa mga level.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                    )
                  else
                    Text(
                      'Ibabawas ang $price coins sa iyong ipon.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GameButton(
                        label: isFull ? 'SIGE' : 'KANSELAHIN',
                        color: isFull ? AppColors.accent : AppColors.surfaceAlt,
                        fontSize: 8,
                        minHeight: 44,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    if (!isFull) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: GameButton(
                          label: 'BILHIN',
                          fontSize: 8,
                          minHeight: 44,
                          onPressed: canAfford
                              ? () => ref.read(gameProvider.notifier).buyHeart()
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
