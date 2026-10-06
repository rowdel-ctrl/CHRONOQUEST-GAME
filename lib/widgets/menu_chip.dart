import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'pixel_icon.dart';

/// The face of a menu button: a wooden square with a dark pixel border, a hard
/// shadow and a gold [PixelIcon]. Not tappable by itself; [MenuChip] adds the
/// tap, and Settings rows use the bare face next to their text.
class MenuChipFace extends StatelessWidget {
  final PixelGlyph icon;
  final double size;
  final bool pressed;

  const MenuChipFace({
    super.key,
    required this.icon,
    this.size = 40,
    this.pressed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primaryDark, width: 2),
        boxShadow: pressed
            ? null
            : const [
                BoxShadow(
                  color: AppColors.primaryDark,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
      ),
      child: PixelIcon(icon, size: size * 0.6, color: AppColors.accent),
    );
  }
}

/// The one icon button of the menu screens (back, profile, settings,
/// leaderboard, how to play): 40 logical pixels to look at, a 48 pixel square
/// to hit, and it presses in like the game's other buttons.
class MenuChip extends StatefulWidget {
  final PixelGlyph icon;
  final String tooltip;
  final VoidCallback? onTap;

  const MenuChip({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<MenuChip> createState() => _MenuChipState();
}

class _MenuChipState extends State<MenuChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Transform.translate(
                offset: _pressed ? const Offset(3, 3) : Offset.zero,
                child: MenuChipFace(icon: widget.icon, pressed: _pressed),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
