import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'pixel_icon.dart';

/// The chosen hero in a wooden frame with a gold inner edge, used where the
/// screens used to show the first letter of the student's name in a circle.
///
/// Uses the character's first walk frame. A character with no art falls back
/// to the profile icon rather than a broken image.
class CharacterPortrait extends StatelessWidget {
  final String characterId;
  final double width;
  final double height;

  /// How the sprite sits in the frame: the whole figure for a big portrait,
  /// cropped to the upper body for a small one.
  final BoxFit fit;
  final Alignment alignment;

  const CharacterPortrait({
    super.key,
    required this.characterId,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context) {
    final inset = width < 40 ? 2.0 : 3.0;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primaryDark, width: 3),
      ),
      child: Container(
        margin: EdgeInsets.all(inset),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.accent, width: 1.5),
        ),
        child: ClipRect(
          child: Padding(
            padding: EdgeInsets.all(width < 40 ? 0 : 4),
            child: Image.asset(
              'assets/characters/${characterId}_walk_1.png',
              fit: fit,
              alignment: alignment,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, __, ___) => const Center(
                child: PixelIcon(PixelGlyph.profile,
                    size: 20, color: AppColors.accent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
