import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import 'menu_chip.dart';
import 'pixel_icon.dart';

/// The top bar the menu screens share: a back chip on the left, the title in
/// gold, and [actions] on the right. By rule Settings is the right-most action
/// and Profile sits just left of it, so neither moves from screen to screen.
class MenuTopBar extends StatelessWidget {
  final String title;

  /// Null on a screen with nowhere to go back to; the space is kept so the
  /// title does not shift.
  final VoidCallback? onBack;
  final String backTooltip;
  final List<Widget> actions;

  const MenuTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.backTooltip = 'Bumalik',
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          if (onBack != null)
            MenuChip(
              icon: PixelGlyph.back,
              tooltip: backTooltip,
              onTap: onBack,
            )
          else
            const SizedBox(width: 48, height: 48),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ),
          if (actions.isEmpty)
            const SizedBox(width: 48, height: 48) // balances the back chip
          else
            Row(mainAxisSize: MainAxisSize.min, children: actions),
        ],
      ),
    );
  }
}
