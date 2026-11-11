import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/bonus_constants.dart';
import '../../widgets/pixel_icon.dart';
import '../bonus/bonus_game.dart';
import 'bonus_hud.dart';

/// The tally after the 20 seconds: "Tapos na ang oras!", the coins grabbed, the
/// coins knocked loose, and "Bonus +N coins" counting up. When it is done (or the
/// student taps) it calls [onDone], which pays the wallet and leaves the round.
class BonusTallyWidget extends StatefulWidget {
  static const totalKey = ValueKey('bonus-tally-total');
  static const panelKey = ValueKey('bonus-tally-panel');

  final BonusGame game;
  final VoidCallback onDone;

  /// Called once, when the count has reached its final number: the coins go to the
  /// wallet then, so "Nadagdag sa wallet" is true when it appears.
  final VoidCallback? onCounted;
  const BonusTallyWidget(
      {super.key, required this.game, required this.onDone, this.onCounted});

  @override
  State<BonusTallyWidget> createState() => _BonusTallyWidgetState();
}

class _BonusTallyWidgetState extends State<BonusTallyWidget>
    with SingleTickerProviderStateMixin {
  static const double _panelIn = .45;

  late final double _total = _panelIn +
      BonusConstants.tallyCountSeconds +
      BonusConstants.tallyHoldSeconds;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_total * 1000).round()),
  )
    ..addListener(_watch)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    })
    ..forward();

  bool _finished = false;
  bool _counted = false;

  double get _countDoneAt => (_panelIn + BonusConstants.tallyCountSeconds) / _total;

  void _watch() {
    if (!_counted && _c.value >= _countDoneAt) {
      _counted = true;
      widget.onCounted?.call();
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _watch(); // a finished animation is at its end: the count is done
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// First tap shows the final numbers at once, the next one carries on.
  void _tap() {
    if (_c.value < _countDoneAt) {
      _c.value = _countDoneAt;
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value * _total;
          final dim = (t / .4).clamp(0.0, 1.0);
          final p = (t / _panelIn).clamp(0.0, 1.0);
          const c1 = 1.70158, c3 = c1 + 1;
          final pop = 1 + c3 * math.pow(p - 1, 3) + c1 * math.pow(p - 1, 2);
          final count = ((t - _panelIn) / BonusConstants.tallyCountSeconds)
              .clamp(0.0, 1.0);
          final shown = (game.counter * (1 - math.pow(1 - count, 2))).round();
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: const Color(0xFF0A041E).withValues(alpha: .66 * dim)),
              Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: dim,
                        child: Transform.scale(
                          scale: pop.toDouble(),
                          child: Text(
                            'Tapos na ang oras!',
                            style: bonusText(34,
                                    color: BonusColors.coin,
                                    weight: FontWeight.w900,
                                    height: 1.2)
                                .copyWith(shadows: const [
                              Shadow(color: Color(0xFF2A1058), blurRadius: 6),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: p,
                        child: Transform.scale(
                          scale: pop.toDouble(),
                          child: _Panel(
                            game: game,
                            shown: shown,
                            countDone: count >= 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final BonusGame game;
  final int shown;
  final bool countDone;
  const _Panel(
      {required this.game, required this.shown, required this.countDone});

  Widget _row(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: bonusText(16,
                      color: const Color(0xFFE6DCFF),
                      weight: FontWeight.w600)),
            ),
            Text(value,
                style: bonusText(20, color: color, weight: FontWeight.w900)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      key: BonusTallyWidget.panelKey,
      width: 340,
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [BonusColors.panelTop, BonusColors.panelBottom],
        ),
        border: Border.all(color: BonusColors.gold, width: 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row('Nakuhang coins', '${game.grabbed}', BonusColors.coin),
          _row('Natanggal ng kalaban', '-${game.knockedLoose}',
              BonusColors.loose),
          const Divider(color: Color(0x66FFE9A0), height: 12, thickness: 2),
          Text(
            'Bonus +$shown coins',
            key: BonusTallyWidget.totalKey,
            style: bonusText(28, color: BonusColors.coin, weight: FontWeight.w900)
                .copyWith(shadows: const [
              Shadow(color: Color(0xFF2A1058), blurRadius: 5),
            ]),
          ),
          const SizedBox(height: 4),
          Opacity(
            opacity: countDone ? 1 : 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PixelIcon(PixelGlyph.coin, size: 18, color: BonusColors.coin),
                const SizedBox(width: 6),
                Text('Nadagdag sa wallet',
                    style: bonusText(14,
                        color: const Color(0xFFBFE9FF),
                        weight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
