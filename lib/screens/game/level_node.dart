import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/living_backdrop.dart';
import '../../widgets/pixel_icon.dart';

/// Where a level stands for this student.
enum LevelNodeState {
  /// Finished: gold, with the stars it earned under it.
  done,

  /// The one to play next: big, white and gold, with a ring spreading out of it and
  /// the student's hero standing on it.
  current,

  /// Open but not the next (a replay, or the testing switch): the plain wooden one.
  open,

  /// Not reached yet: dark, with a lock.
  locked,
}

/// A single tappable level on [LevelSelectScreen]'s winding path. The circle is
/// centred in a 52 pixel square (the target to hit); what hangs outside it (the
/// stars below, the hero above) does not take part in layout.
class LevelNode extends StatefulWidget {
  /// The size of the square the node is centred in.
  static const double target = 52;

  final int level;
  final LevelNodeState state;
  final int stars;
  final bool isBoss;

  /// The hero shown on the current level.
  final String heroId;
  final VoidCallback? onTap;

  const LevelNode({
    super.key,
    required this.level,
    required this.state,
    required this.stars,
    required this.isBoss,
    required this.heroId,
    required this.onTap,
  });

  @override
  State<LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<LevelNode>
    with SingleTickerProviderStateMixin {
  /// The ring that spreads out of the current level, over a second and a half.
  late final AnimationController _ring = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LevelNode old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final on = widget.state == LevelNodeState.current && motionAllowed(context);
    if (on && !_ring.isAnimating) {
      _ring.repeat();
    } else if (!on && _ring.isAnimating) {
      _ring.stop();
    }
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  String get _label {
    final what = widget.isBoss ? 'Boss' : 'Level ${widget.level}';
    switch (widget.state) {
      case LevelNodeState.done:
        return '$what, tapos, ${widget.stars} bituin';
      case LevelNodeState.current:
        return '$what, susunod';
      case LevelNodeState.open:
        return what;
      case LevelNodeState.locked:
        return '$what, naka-lock';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final boss = widget.isBoss;
    final size = boss
        ? 46.0
        : s == LevelNodeState.current
            ? 44.0
            : 34.0;

    final Color fill;
    final Color edge;
    switch (s) {
      case LevelNodeState.done:
        fill = AppColors.accent;
        edge = AppColors.primaryDark;
      case LevelNodeState.current:
        fill = Colors.white;
        edge = AppColors.accent;
      case LevelNodeState.open:
        fill = AppColors.primary;
        edge = AppColors.primaryDark;
      case LevelNodeState.locked:
        fill = boss ? const Color(0xFF3A1620) : const Color(0xFF2B2140);
        edge = const Color(0xFF1A1226);
    }
    final bossFill =
        boss && s != LevelNodeState.locked && s != LevelNodeState.done
            ? const Color(0xFF5A1620)
            : fill;

    final Widget face;
    if (boss) {
      face = PixelIcon(
        PixelGlyph.skull,
        size: 26,
        color: s == LevelNodeState.done
            ? AppColors.primaryDark
            : s == LevelNodeState.locked
                ? const Color(0xFF7A4A55)
                : const Color(0xFFFF8F86),
      );
    } else if (s == LevelNodeState.locked) {
      face = Image.asset('assets/ui/lock_icon.png',
          width: 15,
          height: 15,
          color: Colors.white38,
          filterQuality: FilterQuality.none);
    } else {
      face = Text(
        '${widget.level}',
        style: GoogleFonts.poppins(
          fontSize: s == LevelNodeState.current ? 17 : 14,
          height: 1.1,
          fontWeight: FontWeight.bold,
          color: s == LevelNodeState.open
              ? AppColors.accent
              : AppColors.primaryDark,
        ),
      );
    }

    return Semantics(
      button: widget.onTap != null,
      label: _label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox(
          width: LevelNode.target,
          height: LevelNode.target,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (s == LevelNodeState.current)
                AnimatedBuilder(
                  animation: _ring,
                  builder: (context, _) => Container(
                    width: size * (1 + 0.9 * _ring.value),
                    height: size * (1 + 0.9 * _ring.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accent
                            .withValues(alpha: 0.8 * (1 - _ring.value)),
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: boss ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: boss ? BorderRadius.circular(8) : null,
                  color: bossFill,
                  border: Border.all(color: edge, width: 3),
                  boxShadow: [
                    if (s == LevelNodeState.current)
                      BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.7),
                          blurRadius: 18,
                          spreadRadius: 3),
                    if (boss && s != LevelNodeState.locked)
                      BoxShadow(
                          color: AppColors.danger.withValues(alpha: 0.5),
                          blurRadius: 14),
                    BoxShadow(color: edge, offset: const Offset(0, 2)),
                  ],
                ),
                child: face,
              ),
              // The stars a finished level earned.
              if (s == LevelNodeState.done)
                Positioned(
                  top: LevelNode.target / 2 + size / 2 + 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Image.asset(
                          i < widget.stars
                              ? 'assets/ui/star_full.png'
                              : 'assets/ui/star_empty.png',
                          width: 11,
                          height: 11,
                          filterQuality: FilterQuality.none,
                        ),
                    ],
                  ),
                ),
              // The hero, standing on the level to play next.
              if (s == LevelNodeState.current)
                Positioned(
                  bottom: LevelNode.target / 2 + size / 2 - 2,
                  child: IgnorePointer(
                    child: Bob(
                      height: 4,
                      child: Image.asset(
                        'assets/characters/${widget.heroId}_walk_1.png',
                        height: 44,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox(height: 44, width: 30),
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
