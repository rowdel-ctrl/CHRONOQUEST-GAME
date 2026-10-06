import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/gate_icon.dart';
import '../chrono_game.dart';

/// How far along the level the student is: a small pill at the bottom centre
/// with the hero's face riding a thin gold line towards the gate. Like the wave
/// bar in Plants vs Zombies, but quiet (playtest, 2026-10-06: the first version
/// was 340 wide and too spacious on small screens; this is the "mini pill" from
/// the approved mockup).
///
/// The position changes every frame but the HUD only rebuilds when game state
/// notifies, so this runs its own short ticker (the same approach as
/// `GateHud`). It ignores touches, so it can never get in the way of the
/// controls.
class LevelProgressBar extends StatefulWidget {
  final ChronoGame game;
  const LevelProgressBar({super.key, required this.game});

  static const double width = 112;
  static const double height = 18;

  /// The fraction of the way from the start to the end, 0 to 1.
  static double fractionFor({
    required double playerX,
    required double startX,
    required double endX,
  }) {
    final span = endX - startX;
    if (span <= 0) return 0;
    return ((playerX - startX) / span).clamp(0.0, 1.0).toDouble();
  }

  @override
  State<LevelProgressBar> createState() => _LevelProgressBarState();
}

class _LevelProgressBarState extends State<LevelProgressBar> {
  static const _tick = Duration(milliseconds: 100);

  Timer? _ticker;
  double _fraction = 0;

  double get _startX => widget.game.tiledLevel?.spawnX ?? 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(_tick, (_) => _refresh());
    _refresh();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    final game = widget.game;
    // Before the level has loaded there is no player to follow yet.
    if (!game.isLoaded) return;
    final next = LevelProgressBar.fractionFor(
      playerX: game.player.worldX,
      startX: _startX,
      endX: game.levelEndX,
    );
    // Whole pixels are all a 112-wide pill can show.
    if ((next - _fraction).abs() >= 0.004) setState(() => _fraction = next);
  }

  @override
  Widget build(BuildContext context) {
    const w = LevelProgressBar.width;
    const trackLeft = 9.0;
    const trackRight = 22.0; // leaves room for the gate
    const trackWidth = w - trackLeft - trackRight;
    final percent = (_fraction * 100).round();

    return Semantics(
      label: '$percent% ng level ang natapos',
      child: Opacity(
        opacity: 0.78,
        child: Container(
          width: w,
          height: LevelProgressBar.height,
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The line: faint all the way, gold as far as the hero has come.
              Positioned(
                left: trackLeft - 1,
                top: 6,
                width: trackWidth,
                height: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _fraction,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // The hero's face, riding the line.
              Positioned(
                left: trackLeft - 1 + trackWidth * _fraction - 6,
                top: 1,
                child: _HeroMarker(characterId: widget.game.selectedCharacterId),
              ),
              // The gate the line leads to.
              const Positioned(
                right: 3,
                top: 1,
                child: GateIcon(size: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroMarker extends StatelessWidget {
  final String characterId;
  const _HeroMarker({required this.characterId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryDark,
        border: Border.all(color: AppColors.accent, width: 1.2),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/characters/${characterId}_walk_1.png',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.none,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
