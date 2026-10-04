import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';

/// The header Settings and Controls share with the rest of the menu screens:
/// a back arrow on the left, the title in gold in the middle.
///
/// Back pops, so it returns to whichever screen opened Settings (the main
/// menu, or the pause menu over a level). The `go` fallback is only for a
/// screen reached with nothing beneath it, such as a restored session.
class SettingsHeader extends StatelessWidget {
  final String title;
  const SettingsHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Bumalik',
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go('/character-selection'),
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 48), // balances the back button
        ],
      ),
    );
  }
}
