import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_info.dart';
import '../core/constants.dart';
import 'pixel_icon.dart';

/// The top-right corner of the first screen: four signal bars that say whether the
/// game can reach its server. Green when it can, a red crossed-out chip with
/// "Walang internet" when it cannot, grey while it is still finding out.
class ConnectionCorner extends StatelessWidget {
  final ValueListenable<bool?> status;

  const ConnectionCorner({super.key, required this.status});

  static const chipKey = ValueKey('connection_chip');
  static const offlineKey = ValueKey('connection_offline');

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool?>(
      valueListenable: status,
      builder: (context, ok, _) {
        final bad = ok == false;
        return Semantics(
          label: ok == null
              ? 'Chine-check ang internet'
              : ok
                  ? 'May internet'
                  : 'Walang internet',
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (bad) ...[
                  Text(
                    'Walang internet',
                    key: offlineKey,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF9C92),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  key: chipKey,
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bad ? const Color(0xFF5A1620) : AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primaryDark, width: 2),
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.primaryDark, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PixelIcon(
                        PixelGlyph.signal,
                        size: 18,
                        color: bad
                            ? const Color(0xFFFF8F86)
                            : ok == true
                                ? AppColors.success
                                : AppColors.textMuted,
                      ),
                      if (bad)
                        Transform.rotate(
                          angle: -0.785,
                          child: Container(
                              width: 24,
                              height: 3,
                              color: const Color(0xFFFF8F86)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// "v1.3.2" in small muted type, for the bottom corner.
class VersionLabel extends StatelessWidget {
  const VersionLabel({super.key});

  static const textKey = ValueKey('version_label');

  @override
  Widget build(BuildContext context) {
    return Text(
      'v$appVersion',
      key: textKey,
      style: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF7A6B94),
      ),
    );
  }
}
