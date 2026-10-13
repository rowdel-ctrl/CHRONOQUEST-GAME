import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/game_provider.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/hearts_pill.dart' show formatHeartCountdown;
import '../../widgets/menu_chip.dart';
import '../../widgets/pixel_icon.dart';

/// TINDAHAN: spend coins on hearts and power-ups. The coins, hearts and
/// power-ups are the phone's own wallet (GameNotifier), so a purchase shows at
/// once and is kept.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  static const Key buyHeartKey = Key('shop_buy_heart');
  static const Key fillHeartsKey = Key('shop_fill_hearts');
  static const Key coinsKey = Key('shop_coins');
  static const Key toastKey = Key('shop_toast');
  static Key buyKey(PowerUpKind kind) => ValueKey('shop_buy_${kind.name}');
  static Key ownedKey(PowerUpKind kind) => ValueKey('shop_owned_${kind.name}');

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  Timer? _ticker;
  Timer? _toastTimer;
  String? _toast;

  @override
  void initState() {
    super.initState();
    // Hearts come back on their own; this keeps the countdown moving.
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => ref.read(gameProvider.notifier).refreshHearts(),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }

  void _say(String text) {
    _toastTimer?.cancel();
    setState(() => _toast = text);
    _toastTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/era-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final missing = GameConstants.maxHearts - game.hearts.count;

    int owned(PowerUpKind k) => switch (k) {
          PowerUpKind.fiftyFifty => game.powerUps.fiftyFifty,
          PowerUpKind.shield => game.powerUps.shield,
          PowerUpKind.timeFreeze => game.powerUps.timeFreeze,
        };

    final hearts = _HeartsPanel(
      count: game.hearts.count,
      missing: missing,
      coins: game.coins,
      countdown: notifier.heartCountdown,
      onBuyOne: () {
        if (notifier.buyHeart()) _say('NABILI! +1 PUSO');
      },
      onFill: () {
        if (notifier.buyAllHearts()) _say('PUNO NA ANG PUSO!');
      },
    );

    final cards = [
      for (final kind in PowerUpKind.values)
        _PowerUpCard(
          kind: kind,
          owned: owned(kind),
          coins: game.coins,
          onBuy: () {
            if (notifier.buyPowerUp(kind)) {
              // Read it back: the notifier changes the count in place.
              final now = ref.read(gameProvider).powerUps;
              final count = switch (kind) {
                PowerUpKind.fiftyFifty => now.fiftyFifty,
                PowerUpKind.shield => now.shield,
                PowerUpKind.timeFreeze => now.timeFreeze,
              };
              _say('NABILI! ${_names[kind]!.$1.toUpperCase()} ×$count');
            }
          },
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF140E1F), Color(0xFF2A1A3A), Color(0xFF3A2433)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        MenuChip(
                          icon: PixelGlyph.back,
                          tooltip: 'Bumalik',
                          onTap: _back,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'TINDAHAN',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        _Pill(
                          leading: Image.asset('assets/collectibles/coin.png',
                              width: 16, height: 16),
                          text: _grouped(game.coins),
                          textKey: ShopScreen.coinsKey,
                          textColor: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        _Pill(
                          leading: Image.asset('assets/ui/heart_full.png',
                              width: 16, height: 16),
                          text:
                              '${game.hearts.count}/${GameConstants.maxHearts}',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        if (box.maxWidth >= 600) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 238,
                                        child: SingleChildScrollView(
                                            child: hearts),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              for (var i = 0;
                                                  i < cards.length;
                                                  i++) ...[
                                                if (i > 0)
                                                  const SizedBox(width: 10),
                                                Expanded(child: cards[i]),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const _Footer(),
                              ],
                            ),
                          );
                        }
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              hearts,
                              for (final c in cards) ...[
                                const SizedBox(height: 10),
                                c
                              ],
                              const SizedBox(height: 10),
                              const _Footer(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (_toast != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        key: ShopScreen.toastKey,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          border: Border.all(
                              color: AppColors.primaryDark, width: 3),
                          boxShadow: const [
                            BoxShadow(
                                color: AppColors.primaryDark,
                                offset: Offset(0, 4)),
                          ],
                        ),
                        child: Text(
                          _toast!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
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

const _names = {
  PowerUpKind.fiftyFifty: ('50/50', 'Tinatanggal ang dalawang maling sagot.'),
  PowerUpKind.shield: (
    'Shield',
    'Sumasalo ng isang pagkakamali o pagkaubos ng oras.'
  ),
  PowerUpKind.timeFreeze: (
    'Time Freeze',
    'Pinahihinto ang oras sa tanong ng boss.'
  ),
};

const _icons = {
  PowerUpKind.fiftyFifty: 'assets/powerups/fifty_fifty.png',
  PowerUpKind.shield: 'assets/powerups/shield.png',
  PowerUpKind.timeFreeze: 'assets/powerups/time_freeze.png',
};

String _grouped(int n) {
  final s = n.toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

class _Pill extends StatelessWidget {
  final Widget leading;
  final String text;
  final Key? textKey;
  final Color textColor;
  const _Pill({
    required this.leading,
    required this.text,
    this.textKey,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        border: Border.all(color: AppColors.primaryDark, width: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 6),
          Text(
            text,
            key: textKey,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 6, left: 2),
        child: Text(
          'Makakakuha ng coins sa paglalaro ng mga level.',
          style:
              GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFCDBA94)),
        ),
      ),
    );
  }
}

/// A price on a button: the coin and the number.
Widget _price(int n) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$n'),
        const SizedBox(width: 4),
        Image.asset('assets/collectibles/coin.png', width: 14, height: 14),
      ],
    );

/// The pixel-style buy button: label on the left, price on the right. Grey and
/// unpressable when [onPressed] is null.
class _BuyButton extends StatelessWidget {
  final String label;
  final int price;
  final VoidCallback? onPressed;
  const _BuyButton(
      {super.key,
      required this.label,
      required this.price,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final off = onPressed == null;
    return Semantics(
      button: true,
      enabled: !off,
      label: '$label, $price coins',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: off ? const Color(0xFFBDA97F) : AppColors.accent,
            border: Border.all(
              color: off ? const Color(0xFF6B5A3C) : AppColors.primaryDark,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: off ? const Color(0xFF6B5A3C) : AppColors.primaryDark,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: DefaultTextStyle(
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: off ? const Color(0xFF6B5A3C) : AppColors.primaryDark,
            ),
            child: Opacity(
              opacity: off ? 0.8 : 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(label,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 6),
                  _price(price),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeartsPanel extends StatelessWidget {
  final int count;
  final int missing;
  final int coins;
  final Duration? countdown;
  final VoidCallback onBuyOne;
  final VoidCallback onFill;
  const _HeartsPanel({
    required this.count,
    required this.missing,
    required this.coins,
    required this.countdown,
    required this.onBuyOne,
    required this.onFill,
  });

  @override
  Widget build(BuildContext context) {
    const price = GameConstants.heartPriceCoins;
    final small = GoogleFonts.poppins(
      fontSize: 12,
      height: 1.3,
      color: AppColors.textSecondary,
    );
    final canOne = missing > 0 && coins >= price;
    final canFill = missing > 1 && coins >= price * missing;

    return GamePanel(
      color: AppColors.surface,
      borderWidth: 3,
      shadowOffset: 4,
      borderRadius: 4,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MGA PUSO',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < GameConstants.maxHearts; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ColorFiltered(
                      colorFilter: i < count
                          ? const ColorFilter.mode(
                              Colors.transparent, BlendMode.dst)
                          : const ColorFilter.matrix(<double>[
                              0.2, 0, 0, 0, 0, //
                              0, 0.2, 0, 0, 0,
                              0, 0, 0.2, 0, 0,
                              0, 0, 0, 1, 0,
                            ]),
                      child: Image.asset(
                        'assets/ui/heart_full.png',
                        filterQuality: FilterQuality.none,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (missing <= 0)
            Text('Puno na ang puso mo. Walang kailangang bilhin.', style: small)
          else ...[
            Text(
              countdown == null
                  ? 'Mag-online para bumalik ang libreng puso.'
                  : 'Susunod na libreng puso: ${formatHeartCountdown(countdown!)}',
              style: small,
            ),
            const SizedBox(height: 8),
            _BuyButton(
              key: ShopScreen.buyHeartKey,
              label: 'BUMILI NG 1',
              price: price,
              onPressed: canOne ? onBuyOne : null,
            ),
            if (missing > 1) ...[
              const SizedBox(height: 8),
              _BuyButton(
                key: ShopScreen.fillHeartsKey,
                label: 'PUNUIN ($missing)',
                price: price * missing,
                onPressed: canFill ? onFill : null,
              ),
            ],
            if (!canOne) ...[
              const SizedBox(height: 6),
              Text(
                'Kulang ng ${price - coins} coins',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PowerUpCard extends StatelessWidget {
  final PowerUpKind kind;
  final int owned;
  final int coins;
  final VoidCallback onBuy;
  const _PowerUpCard({
    required this.kind,
    required this.owned,
    required this.coins,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final (name, blurb) = _names[kind]!;
    final can = coins >= kind.priceCoins;

    return GamePanel(
      color: can ? AppColors.surface : const Color(0xFFD9C79C),
      borderWidth: 3,
      shadowOffset: 4,
      borderRadius: 4,
      padding: const EdgeInsets.all(9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              border: Border.all(color: AppColors.primaryDark, width: 3),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  _icons[kind]!,
                  width: 44,
                  height: 44,
                  filterQuality: FilterQuality.none,
                ),
                Positioned(
                  right: 5,
                  top: 3,
                  child: Text(
                    '×$owned',
                    key: ShopScreen.ownedKey(kind),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 50,
            child: Text(
              blurb,
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.25,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          _BuyButton(
            key: ShopScreen.buyKey(kind),
            label: 'BILHIN',
            price: kind.priceCoins,
            onPressed: can ? onBuy : null,
          ),
          if (!can) ...[
            const SizedBox(height: 5),
            Text(
              'Kulang ng ${kind.priceCoins - coins}',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
