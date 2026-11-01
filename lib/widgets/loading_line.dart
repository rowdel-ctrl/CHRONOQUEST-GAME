import 'package:flutter/material.dart';

import '../core/constants.dart';
import 'gate_icon.dart';

/// A thin gold line with the hero's face riding it towards the gate: the same idea
/// as the level's progress pill. [progress] is 0 to 1; the gate opens at 1.
class LoadingLine extends StatelessWidget {
  final double progress;
  final String charId;
  final double width;

  const LoadingLine(
      {super.key,
      required this.progress,
      required this.charId,
      this.width = 240});

  static const double height = 24;
  static const double _gate = 32;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    final track = width - _gate;
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 9,
              width: track,
              height: 7,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.primaryDark, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: p,
                      heightFactor: 1,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFFE08A), AppColors.accent],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: track * p - 11,
              top: 0,
              child: Container(
                width: height,
                height: height,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B2A5E),
                  border: Border.all(color: AppColors.primaryDark, width: 2.5),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/characters/${charId}_walk_1.png',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.88),
                    filterQuality: FilterQuality.none,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            ),
            Positioned(
                right: 0, top: -1, child: GateIcon(size: 26, unlocked: p >= 1)),
          ],
        ),
      ),
    );
  }
}
