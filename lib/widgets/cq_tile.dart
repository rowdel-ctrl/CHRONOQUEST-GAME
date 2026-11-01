import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';

/// The game's mark: "CQ" in gold on a wooden tile with a dark pixel border. The same
/// tile is the app icon, the phone's launch screen and the landing page's icon.
class CqTile extends StatelessWidget {
  final double size;

  const CqTile({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(size * 0.1875),
          border:
              Border.all(color: AppColors.primaryDark, width: size * 0.0625),
          boxShadow: [
            BoxShadow(
                color: AppColors.primaryDark, offset: Offset(0, size * 0.078))
          ],
        ),
        child: Text(
          'CQ',
          style: GoogleFonts.poppins(
            fontSize: size * 0.45,
            fontWeight: FontWeight.w900,
            height: 1,
            color: AppColors.accent,
            shadows: [
              Shadow(
                  color: AppColors.primaryDark, offset: Offset(0, size * 0.03))
            ],
          ),
        ),
      ),
    );
  }
}
