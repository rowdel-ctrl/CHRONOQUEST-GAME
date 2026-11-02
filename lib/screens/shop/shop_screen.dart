import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/badge_defs.dart';
import '../../providers/badge_provider.dart';
import '../../providers/game_provider.dart';
import '../../widgets/hearts_pill.dart' show formatHeartCountdown;
import '../../widgets/living_backdrop.dart';
import '../../widgets/menu_top_bar.dart';
import '../../widgets/new_badge.dart';
import '../../widgets/pixel_icon.dart';

/// TINDAHAN: spend coins on hearts and power-ups. The coins, hearts and
/// power-ups are the phone's own wallet (GameNotifier), so a purchase shows at
/// once and is kept.
///
/// Four tall cards, one picture each, and the price is the button. Few words: a
/// power-up has one short line, and a card that cannot be bought says how many
/// coins are missing.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  static const Key buyHeartKey = Key('shop_buy_heart');
  static const Key fillHeartsKey = Key('shop_fill_hearts');
  static const Key coinsKey = Key('shop_coins');
  static const Key toastKey = Key('shop_toast');
  static Key buyKey(PowerUpKind kind) => ValueKey('shop_buy_${kind.name}');
  static Key ownedKey(PowerUpKind kind) => ValueKey('shop_owned_${kind.name}');

  /// One of the five hearts on the Puso card; [full] is whether it is filled.
  static Key pipKey(int index, bool full) =>
      ValueKey('shop_pip_${index}_${full ? 'full' : 'empty'}');

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  Timer? _ticker;
  Timer? _toastTimer;
  String? _toast;

  /// How many times each card has been bought from, so it can give a bump.
  final Map<String, int> _bumps = {};

  /// A badge the last purchase earned, shown as a strip across the top.
  List<EarnedBadge> _newBadges = const [];

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

  /// Said after every purchase: the green line, the card's bump, and the first ever
  /// purchase earns the Unang Bili badge.
  void _say(String text, String card) {
    _toastTimer?.cancel();
    final earned = ref.read(badgeProvider.notifier).recordPurchase();
    setState(() {
      _toast = text;
      _bumps[card] = (_bumps[card] ?? 0) + 1;
      if (earned.isNotEmpty) _newBadges = earned;
    });
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
    const heartPrice = GameConstants.heartPriceCoins;

    int owned(PowerUpKind k) => switch (k) {
          PowerUpKind.fiftyFifty => game.powerUps.fiftyFifty,
          PowerUpKind.shield => game.powerUps.shield,
          PowerUpKind.timeFreeze => game.powerUps.timeFreeze,
        };

    final canOne = missing > 0 && game.coins >= heartPrice;
    final canFill = missing > 1 && game.coins >= heartPrice * missing;
    final countdown = notifier.heartCountdown;

    final cards = <Widget>[
      _ShopCard(
        bump: _bumps['heart'] ?? 0,
        color: AppColors.danger,
        asset: 'assets/ui/heart_full.png',
        name: 'PUSO',
        poor: missing > 0 && !canOne,
        blurb: _HeartStatus(
          count: game.hearts.count,
          countdown: missing > 0 ? countdown : null,
          offline: missing > 0 && countdown == null,
        ),
        short:
            missing > 0 && !canOne ? 'Kulang ${heartPrice - game.coins}' : null,
        zone: Column(
          children: [
            if (missing <= 0)
              const _PriceButton(
                text: 'PUNO NA',
                semantics: 'Puno na ang puso',
                onTap: null,
              )
            else
              _PriceButton(
                key: ShopScreen.buyHeartKey,
                price: heartPrice,
                semantics: 'Bumili ng 1 puso, $heartPrice coins',
                onTap: canOne
                    ? () {
                        if (notifier.buyHeart()) {
                          _say('NABILI! +1 PUSO', 'heart');
                        }
                      }
                    : null,
              ),
            const SizedBox(height: 4),
            if (missing > 1)
              _FillButton(
                key: ShopScreen.fillHeartsKey,
                price: heartPrice * missing,
                onTap: canFill
                    ? () {
                        if (notifier.buyAllHearts()) {
                          _say('PUNO NA ANG PUSO!', 'heart');
                        }
                      }
                    : null,
              ),
          ],
        ),
      ),
      for (final kind in PowerUpKind.values)
        _ShopCard(
          bump: _bumps[kind.name] ?? 0,
          color: _colors[kind]!,
          asset: _icons[kind]!,
          name: _names[kind]!.toUpperCase(),
          poor: game.coins < kind.priceCoins,
          blurb: Text(
            _blurbs[kind]!,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: _blurbStyle,
          ),
          short: game.coins < kind.priceCoins
              ? 'Kulang ${kind.priceCoins - game.coins}'
              : null,
          zone: Column(
            children: [
              _PriceButton(
                key: ShopScreen.buyKey(kind),
                price: kind.priceCoins,
                semantics:
                    'Bumili ng ${_names[kind]}, ${kind.priceCoins} coins',
                onTap: game.coins >= kind.priceCoins
                    ? () {
                        if (notifier.buyPowerUp(kind)) {
                          // Read it back: the notifier changes the count in place.
                          final now = ref.read(gameProvider).powerUps;
                          final count = switch (kind) {
                            PowerUpKind.fiftyFifty => now.fiftyFifty,
                            PowerUpKind.shield => now.shield,
                            PowerUpKind.timeFreeze => now.timeFreeze,
                          };
                          _say('NABILI! ${_names[kind]!.toUpperCase()} ×$count',
                              kind.name);
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'MERON KA',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: _soft,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '×${owned(kind)}',
                          key: ShopScreen.ownedKey(kind),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: LivingBackdrop(
              center: Offset(0.5, 0.4),
              fireflies: 0,
              rays: false,
              animate: false,
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    MenuTopBar(
                      title: 'TINDAHAN',
                      onBack: _back,
                      actions: [_CoinsPill(coins: game.coins)],
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          if (box.maxWidth >= 600) {
                            return Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 820),
                                child: SingleChildScrollView(
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 4, 14, 16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (var i = 0;
                                          i < cards.length;
                                          i++) ...[
                                        if (i > 0) const SizedBox(width: 10),
                                        Expanded(child: cards[i]),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                          // A narrow phone: two cards a row.
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            child: Column(
                              children: [
                                for (var r = 0; r < cards.length; r += 2) ...[
                                  if (r > 0) const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: cards[r]),
                                      const SizedBox(width: 10),
                                      Expanded(child: cards[r + 1]),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (_newBadges.isNotEmpty)
                  Positioned.fill(child: NewBadgeStrip(badges: _newBadges)),
                if (_toast != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 14,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          key: ShopScreen.toastKey,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppColors.primaryDark, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                  color: AppColors.primaryDark,
                                  offset: Offset(0, 3)),
                            ],
                          ),
                          child: Text(
                            _toast!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
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
        ],
      ),
    );
  }
}

const _names = {
  PowerUpKind.fiftyFifty: '50/50',
  PowerUpKind.shield: 'Shield',
  PowerUpKind.timeFreeze: 'Time Freeze',
};

/// One short line each: what it does.
const _blurbs = {
  PowerUpKind.fiftyFifty: 'Tanggal 2 mali',
  PowerUpKind.shield: 'Salo ng 1 mali o hit',
  PowerUpKind.timeFreeze: 'Hinto ang oras',
};

const _icons = {
  PowerUpKind.fiftyFifty: 'assets/powerups/fifty_fifty.png',
  PowerUpKind.shield: 'assets/powerups/shield.png',
  PowerUpKind.timeFreeze: 'assets/powerups/time_freeze.png',
};

/// The light behind each picture.
const _colors = {
  PowerUpKind.fiftyFifty: AppColors.accent,
  PowerUpKind.shield: AppColors.success,
  PowerUpKind.timeFreeze: AppColors.info,
};

const _soft = Color(0xFFCDBA94);
const _lack = Color(0xFFFF8F86);

final _blurbStyle =
    GoogleFonts.poppins(fontSize: 11, height: 1.25, color: _soft);

String _grouped(int n) {
  final s = n.toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

/// The coins, top right. The number counts down when something is bought and a
/// red "-20" drifts off it.
class _CoinsPill extends StatefulWidget {
  final int coins;
  const _CoinsPill({required this.coins});

  @override
  State<_CoinsPill> createState() => _CoinsPillState();
}

class _CoinsPillState extends State<_CoinsPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  int _lost = 0;

  @override
  void didUpdateWidget(_CoinsPill old) {
    super.didUpdateWidget(old);
    if (widget.coins < old.coins && motionAllowed(context)) {
      _lost = old.coins - widget.coins;
      _float.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = motionAllowed(context)
        ? const Duration(milliseconds: 280)
        : Duration.zero;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xB8140E1F),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.accent, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/collectibles/coin.png',
                  width: 18, height: 18, filterQuality: FilterQuality.none),
              const SizedBox(width: 6),
              TweenAnimationBuilder<int>(
                tween: IntTween(end: widget.coins),
                duration: count,
                builder: (context, value, _) => Text(
                  _grouped(value),
                  key: ShopScreen.coinsKey,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 10,
          top: 26,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _float,
              builder: (context, _) {
                final t = _float.value;
                final opacity = t <= 0 || t >= 1
                    ? 0.0
                    : (t < 0.2 ? t / 0.2 : 1 - (t - 0.2) / 0.8);
                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, 14 * t),
                    child: Text(
                      '−$_lost',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _lack,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// A tall card: the picture with its light, the name, [blurb], the red
/// [short] line, and [zone] for the buttons. Gives a small bump when [bump]
/// goes up.
class _ShopCard extends StatefulWidget {
  final Color color;
  final String asset;
  final String name;
  final bool poor;
  final int bump;
  final Widget blurb;
  final String? short;
  final Widget zone;

  const _ShopCard({
    required this.color,
    required this.asset,
    required this.name,
    required this.poor,
    required this.bump,
    required this.blurb,
    required this.short,
    required this.zone,
  });

  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bump = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));

  @override
  void didUpdateWidget(_ShopCard old) {
    super.didUpdateWidget(old);
    if (widget.bump != old.bump && motionAllowed(context)) {
      _bump.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Out of reach: the picture goes dull and stops bobbing.
    Widget picture = Image.asset(
      widget.asset,
      width: 54,
      height: 54,
      filterQuality: FilterQuality.none,
    );
    if (widget.poor) {
      picture = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.5488, 0.2736, 0.0276, 0, 0, //
          0.0813, 0.7411, 0.0276, 0, 0,
          0.0813, 0.2736, 0.4951, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: picture,
      );
    }

    return AnimatedBuilder(
      animation: _bump,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.06 * math.sin(math.pi * _bump.value),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2B1F42), Color(0xFF1B1230)],
          ),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.primaryDark, width: 3),
          boxShadow: const [
            BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 66,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.color.withValues(alpha: 0.48),
                          widget.color.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  Bob(
                      height: 4,
                      animate: widget.poor ? false : null,
                      child: picture),
                ],
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.name,
                maxLines: 1,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 30, child: Center(child: widget.blurb)),
            SizedBox(
              height: 14,
              child: widget.short == null
                  ? null
                  : Center(
                      child: Text(
                        widget.short!,
                        maxLines: 1,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          height: 1.1,
                          fontWeight: FontWeight.bold,
                          color: _lack,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            SizedBox(height: 72, child: widget.zone),
          ],
        ),
      ),
    );
  }
}

/// The five hearts and the wait for the next free one.
class _HeartStatus extends StatelessWidget {
  final int count;
  final Duration? countdown;

  /// Hearts are missing but there is no countdown to show.
  final bool offline;
  const _HeartStatus(
      {required this.count, required this.countdown, required this.offline});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Puso: $count sa ${GameConstants.maxHearts}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < GameConstants.maxHearts; i++) ...[
                  if (i > 0) const SizedBox(width: 2),
                  Image.asset(
                    i < count
                        ? 'assets/ui/heart_full.png'
                        : 'assets/ui/heart_empty.png',
                    key: ShopScreen.pipKey(i, i < count),
                    width: 15,
                    height: 15,
                    filterQuality: FilterQuality.none,
                  ),
                ],
              ],
            ),
            if (countdown != null) ...[
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PixelIcon(PixelGlyph.clock, size: 11, color: _soft),
                  const SizedBox(width: 4),
                  Text(
                    formatHeartCountdown(countdown!),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: _soft,
                    ),
                  ),
                ],
              ),
            ] else if (offline) ...[
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Mag-online para sa libreng puso',
                  style: GoogleFonts.poppins(
                      fontSize: 10, height: 1.1, color: _soft),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The gold button that is also the price: the coin and the number. Dull, with
/// the number in red, and unpressable when [onTap] is null. [text] stands in for
/// the price (PUNO NA).
class _PriceButton extends StatefulWidget {
  final int? price;
  final String? text;
  final String semantics;
  final VoidCallback? onTap;
  const _PriceButton({
    super.key,
    this.price,
    this.text,
    required this.semantics,
    required this.onTap,
  });

  @override
  State<_PriceButton> createState() => _PriceButtonState();
}

class _PriceButtonState extends State<_PriceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final off = widget.onTap == null;
    final ink = off
        ? (widget.price != null ? _lack : const Color(0xFF8E7FA8))
        : AppColors.primaryDark;
    return Semantics(
      button: true,
      enabled: !off,
      label: widget.semantics,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: off ? null : (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Transform.translate(
          offset: _pressed ? const Offset(0, 2) : Offset.zero,
          child: Container(
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: off ? const Color(0xFF4A3C5E) : AppColors.accent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.primaryDark, width: 3),
              boxShadow: _pressed
                  ? null
                  : const [
                      BoxShadow(
                          color: AppColors.primaryDark, offset: Offset(0, 3))
                    ],
            ),
            child: widget.price != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/collectibles/coin.png',
                          width: 16,
                          height: 16,
                          filterQuality: FilterQuality.none),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.price}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          height: 1.1,
                          fontWeight: FontWeight.bold,
                          color: ink,
                        ),
                      ),
                    ],
                  )
                : Text(
                    widget.text ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: ink,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// The small wooden "PUNUIN" under the Puso price: every missing heart in one
/// go. Dim when the coins do not cover them all.
class _FillButton extends StatelessWidget {
  final int price;
  final VoidCallback? onTap;
  const _FillButton({super.key, required this.price, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final off = onTap == null;
    final style = GoogleFonts.poppins(
      fontSize: 11,
      height: 1.1,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.6,
      color: AppColors.accent,
    );
    return Semantics(
      button: true,
      enabled: !off,
      label: 'Punuin ang puso, $price coins',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: off ? 0.4 : 1,
          child: Container(
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.primaryDark, width: 2.5),
              boxShadow: const [
                BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 2))
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('PUNUIN', style: style),
                  const SizedBox(width: 6),
                  Image.asset('assets/collectibles/coin.png',
                      width: 12, height: 12, filterQuality: FilterQuality.none),
                  const SizedBox(width: 3),
                  Text('$price', style: style),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
