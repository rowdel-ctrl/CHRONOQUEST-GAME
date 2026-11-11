import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/bonus_constants.dart';
import '../../widgets/pixel_icon.dart';
import '../bonus/bonus_game.dart';

/// The colours of the bonus round: deep violet and gold.
class BonusColors {
  static const Color gold = Color(0xFFF2C14E);
  static const Color goldLight = Color(0xFFFFE9A0);
  static const Color coin = Color(0xFFFFD34D);
  static const Color night = Color(0xFF1B0C3E);
  static const Color panelTop = Color(0xFF2D1668);
  static const Color panelBottom = Color(0xFF190A3C);
  static const Color loose = Color(0xFFFF8A7C);
}

TextStyle bonusText(double size,
        {Color color = Colors.white,
        FontWeight weight = FontWeight.w700,
        double? height}) =>
    GoogleFonts.poppins(
        fontSize: size, fontWeight: weight, color: color, height: height);

/// The gold frame around the whole round, so it plainly looks like another place.
class BonusFrame extends StatelessWidget {
  const BonusFrame({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border.all(color: BonusColors.gold, width: 5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: BonusColors.goldLight, width: 1.5),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
}

/// The round's HUD: a BONUS ribbon, the countdown bar, the coin counter and the
/// chip that says no heart is lost here. Over the Flame canvas, under the controls.
class BonusHudWidget extends StatelessWidget {
  static const pauseKey = ValueKey('bonus-pause');
  static const counterKey = ValueKey('bonus-counter');
  static const barKey = ValueKey('bonus-bar');

  final BonusGame game;
  final VoidCallback onPause;
  const BonusHudWidget({super.key, required this.game, required this.onPause});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const BonusFrame(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xE00E0628),
                        Color(0x590E0628),
                      ],
                    ),
                    border: Border(
                        bottom: BorderSide(color: BonusColors.gold, width: 3)),
                  ),
                  child: Row(
                    children: [
                      const _Ribbon(),
                      const SizedBox(width: 12),
                      Expanded(flex: 5, child: _TimeBar(game: game)),
                      const SizedBox(width: 12),
                      Expanded(flex: 3, child: _CoinCounter(game: game)),
                      const SizedBox(width: 10),
                      Semantics(
                        button: true,
                        label: 'I-pause ang bonus',
                        child: GestureDetector(
                          key: pauseKey,
                          onTap: onPause,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: BonusColors.night,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: BonusColors.gold, width: 2),
                            ),
                            child: const Icon(Icons.pause,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const _NoHeartsChip(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The gold BONUS ribbon.
class _Ribbon extends StatelessWidget {
  const _Ribbon();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 124,
        height: 38,
        child: CustomPaint(
          painter: _RibbonPainter(),
          child: Center(
            child: Text('BONUS',
                style: bonusText(20,
                    color: const Color(0xFF3A1A00),
                    weight: FontWeight.w900,
                    height: 1.1)),
          ),
        ),
      );
}

class _RibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(s.width - 12, 0)
      ..lineTo(s.width, s.height / 2)
      ..lineTo(s.width - 12, s.height)
      ..lineTo(0, s.height)
      ..lineTo(10, s.height / 2)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE58A), Color(0xFFE9A92C)],
        ).createShader(Offset.zero & s),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF6B3D00),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// The 20 second bar: full gold, running down to nothing, with the seconds on it.
class _TimeBar extends StatelessWidget {
  final BonusGame game;
  const _TimeBar({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: game.clock,
      builder: (context, left, _) {
        final fraction = (left / BonusConstants.roundSeconds).clamp(0.0, 1.0);
        final secs = left <= 0 ? 0 : left.ceil();
        return Container(
          key: BonusHudWidget.barKey,
          height: 26,
          decoration: BoxDecoration(
            color: BonusColors.night,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: BonusColors.gold, width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: fraction,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          const Color(0xFFFFD34D),
                          fraction < .25
                              ? const Color(0xFFFF7A3C)
                              : const Color(0xFFFFB82E),
                        ]),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '$secs s',
                    style: bonusText(15, height: 1.1).copyWith(shadows: const [
                      Shadow(color: Color(0xFF2A1058), blurRadius: 3),
                      Shadow(color: Color(0xFF2A1058), offset: Offset(1, 1)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The coin counter: a spinning-looking coin and the number, which pops when a coin
/// is picked up and flashes red (with a floating "-5") when an enemy touches the hero.
class _CoinCounter extends StatelessWidget {
  final BonusGame game;
  const _CoinCounter({required this.game});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final hurt = game.hits > 0 && game.sinceHit < .5;
        return Container(
          key: BonusHudWidget.counterKey,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: BonusColors.night,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BonusColors.gold, width: 3),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  const PixelIcon(PixelGlyph.coin,
                      size: 20, color: BonusColors.coin),
                  const Spacer(),
                  // A new event (a coin or a touch) restarts the pop.
                  TweenAnimationBuilder<double>(
                    key: ValueKey('${game.grabbed}-${game.hits}'),
                    tween: Tween(begin: 1.25, end: 1),
                    duration: const Duration(milliseconds: 160),
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Text('${game.counter}',
                        style: bonusText(22,
                            color: hurt ? BonusColors.loose : BonusColors.coin,
                            weight: FontWeight.w900,
                            height: 1.1)),
                  ),
                ],
              ),
              if (game.hits > 0 && game.lastLost > 0)
                Positioned(
                  right: 4,
                  top: 30,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('loss-${game.hits}'),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 900),
                    builder: (context, t, child) => Opacity(
                      opacity: (1 - t).clamp(0.0, 1.0),
                      child: Transform.translate(
                          offset: Offset(0, -16 * t), child: child),
                    ),
                    child: Text('-${game.lastLost}',
                        style: bonusText(20,
                                color: const Color(0xFFFF6B5E),
                                weight: FontWeight.w900)
                            .copyWith(shadows: const [
                          Shadow(color: Color(0xFF2A0A10), blurRadius: 3),
                        ])),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// "Walang mawawalang puso": the rule of the round, in a small gold-edged chip.
class _NoHeartsChip extends StatelessWidget {
  const _NoHeartsChip();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(8, 3, 12, 3),
        decoration: BoxDecoration(
          color: const Color(0xD9140834),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BonusColors.gold, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: Color(0xFFE8433A), size: 16),
            const SizedBox(width: 6),
            Text('Walang mawawalang puso',
                style: bonusText(12,
                    color: BonusColors.goldLight,
                    weight: FontWeight.w600,
                    height: 1.2)),
          ],
        ),
      );
}

/// The big "BONUS ROUND!" banner at the start: pops in, holds, fades out.
class BonusBanner extends StatefulWidget {
  const BonusBanner({super.key});

  @override
  State<BonusBanner> createState() => _BonusBannerState();
}

class _BonusBannerState extends State<BonusBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(
        milliseconds: (BonusConstants.bannerSeconds * 1000).round()),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final d = _c.value * BonusConstants.bannerSeconds;
          if (_c.isCompleted) return const SizedBox.shrink();
          final p = (d / .5).clamp(0.0, 1.0);
          const c1 = 1.70158, c3 = c1 + 1;
          final pop = 1 + c3 * math.pow(p - 1, 3) + c1 * math.pow(p - 1, 2);
          final fade = d > 1.1 ? (1 - (d - 1.1) / .5).clamp(0.0, 1.0) : 1.0;
          return Center(
            child: Opacity(
              opacity: fade,
              child: Transform.scale(
                scale: pop.toDouble(),
                child: Text(
                  'BONUS ROUND!',
                  style: bonusText(46,
                          color: BonusColors.coin,
                          weight: FontWeight.w900,
                          height: 1.1)
                      .copyWith(shadows: const [
                    Shadow(color: Color(0xFF2A1058), blurRadius: 0, offset: Offset(0, 4)),
                    Shadow(color: Color(0xFF2A1058), blurRadius: 8),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The pause menu of the round: back to it, or out of it with the coins so far.
class BonusPauseWidget extends StatelessWidget {
  static const playKey = ValueKey('bonus-pause-play');
  static const leaveKey = ValueKey('bonus-pause-leave');

  final BonusGame game;
  final VoidCallback onResume;
  final VoidCallback onLeave;
  const BonusPauseWidget(
      {super.key,
      required this.game,
      required this.onResume,
      required this.onLeave});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // block taps
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.black.withValues(alpha: 0.72)),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('PAUSE',
                      style: bonusText(24,
                          color: BonusColors.coin, height: 1.2)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PauseButton(
                        key: playKey,
                        label: 'ITULOY',
                        icon: Icons.play_arrow_rounded,
                        onTap: onResume,
                      ),
                      const SizedBox(width: 22),
                      _PauseButton(
                        key: leaveKey,
                        label: 'LUMABAS',
                        icon: Icons.logout_rounded,
                        onTap: onLeave,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListenableBuilder(
                    listenable: game,
                    builder: (context, _) => Text(
                      'Kung lalabas ka, makukuha mo ang ${game.counter} coins.',
                      style: bonusText(13,
                          color: BonusColors.goldLight,
                          weight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PauseButton(
      {super.key, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BonusColors.night,
                border: Border.all(color: BonusColors.gold, width: 3),
              ),
              child: Icon(icon, color: BonusColors.coin, size: 38),
            ),
            const SizedBox(height: 6),
            Text(label, style: bonusText(13, color: BonusColors.goldLight)),
          ],
        ),
      );
}
