import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/gate_icon.dart';
import '../chrono_game.dart';

/// How far along the level the student is, as a bar along the bottom: the
/// hero's face moves from the start to the gate at the right end, with a small
/// tick where each artifact waits. Like the wave bar in Plants vs Zombies, so a
/// child can see how much is left without counting.
///
/// The position changes every frame but the HUD only rebuilds when game state
/// notifies, so this runs its own short ticker (the same approach as
/// `GateHud`). It ignores touches, so it can never get in the way of the
/// controls.
class LevelProgressBar extends StatefulWidget {
  final ChronoGame game;
  const LevelProgressBar({super.key, required this.game});

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
  List<double> _artifacts = const [];

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

  /// Where each artifact sits along the bar. Read from the level data rather
  /// than the live components, because far-away artifacts are not in the world.
  List<double> _artifactFractions() {
    final game = widget.game;
    final level = game.tiledLevel;
    if (level == null) return const [];
    return [
      for (final e in level.entities.where((e) => e.type == 'artifact'))
        LevelProgressBar.fractionFor(
            playerX: e.x, startX: level.spawnX, endX: game.levelEndX),
    ];
  }

  void _refresh() {
    if (!mounted) return;
    final game = widget.game;
    // Before the level has loaded there is no player to follow yet.
    if (!game.isLoaded) return;
    if (_artifacts.isEmpty) _artifacts = _artifactFractions();
    final next = LevelProgressBar.fractionFor(
      playerX: game.player.worldX,
      startX: _startX,
      endX: game.levelEndX,
    );
    // Whole pixels are all a 300-wide bar can show.
    if ((next - _fraction).abs() >= 0.002) setState(() => _fraction = next);
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_fraction * 100).round();
    return Semantics(
      label: '$percent% ng level ang natapos',
      child: LayoutBuilder(builder: (context, box) {
        // Between the joystick on the left and the buttons on the right.
        final width = (box.maxWidth - 340).clamp(120.0, 340.0).toDouble();
        return SizedBox(
          width: width,
          height: 30,
          child: CustomPaint(
            painter: _BarPainter(fraction: _fraction, artifacts: _artifacts),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // The gate the bar leads to, standing past its right end.
                const Positioned(
                  right: -6,
                  top: 0,
                  child: GateIcon(size: 26),
                ),
                // The hero's face, riding the fill.
                Positioned(
                  left: (width - 38) * _fraction,
                  top: 4,
                  child: _HeroMarker(characterId: widget.game.selectedCharacterId),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _HeroMarker extends StatelessWidget {
  final String characterId;
  const _HeroMarker({required this.characterId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryDark,
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/characters/${characterId}_walk_1.png',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final double fraction;
  final List<double> artifacts;
  const _BarPainter({required this.fraction, required this.artifacts});

  @override
  void paint(Canvas canvas, Size size) {
    // The track runs between the hero's start spot and the gate.
    final track = Rect.fromLTWH(11, size.height / 2 - 5, size.width - 38, 10);
    final r = RRect.fromRectAndRadius(track, const Radius.circular(5));

    canvas.drawRRect(r, Paint()..color = Colors.black54);

    // The part walked so far.
    final fill = Rect.fromLTWH(track.left, track.top, track.width * fraction, track.height);
    if (fill.width > 0) {
      canvas.save();
      canvas.clipRRect(r);
      canvas.drawRect(
        fill,
        Paint()
          ..shader = const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
          ).createShader(track),
      );
      canvas.restore();
    }

    // An artifact tick: gold once passed, white ahead.
    for (final a in artifacts) {
      final x = track.left + track.width * a;
      canvas.drawLine(
        Offset(x, track.top - 2),
        Offset(x, track.bottom + 2),
        Paint()
          ..color = a <= fraction ? AppColors.accent : Colors.white70
          ..strokeWidth = 2,
      );
    }

    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.primaryDark,
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.fraction != fraction || old.artifacts != artifacts;
}
