import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/game_ui.dart';
import '../chrono_game.dart';

/// Shown when the student walks into the end gate with artifacts still
/// unanswered.
///
/// The gate is the level's exit, so being stopped by it with no explanation
/// is the kind of dead end that reads as a broken game to a 10-year-old.
/// This names what is missing and how many, and the HUD counter shows the
/// same number while they go back for it.
class GateLockedOverlayWidget extends StatelessWidget {
  final ChronoGame game;
  const GateLockedOverlayWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final remaining = game.artifactsRemaining;

    return Center(
      child: GamePanel(
        color: AppColors.surface,
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/ui/lock_icon.png', width: 22, height: 22),
                const SizedBox(width: 10),
                Text(
                  'LOCKED ANG GATE',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              remaining == 1
                  ? 'May 1 artifact pang hindi mo nasasagot. Hanapin ito '
                      'para makalabas.'
                  : 'May $remaining artifact pang hindi mo nasasagot. '
                      'Hanapin ang mga ito para makalabas.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            GameButton(
              label: 'SIGE',
              width: 180,
              onPressed: game.dismissGateLockedNotice,
            ),
          ],
        ),
      ),
    );
  }
}
