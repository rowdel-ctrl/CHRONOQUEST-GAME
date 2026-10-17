import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/control_scheme.dart';
import '../../providers/control_scheme_provider.dart';
import '../../widgets/game_ui.dart';
import 'settings_header.dart';

/// Kontrol: pick how to move. Two cards, each showing where the controls sit
/// in a level, so a student can choose by what they see. The choice is saved
/// at once on this device and applies the next time a level is on screen.
class ControlsScreen extends ConsumerWidget {
  const ControlsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = ref.watch(controlSchemeProvider);
    void choose(ControlScheme s) =>
        ref.read(controlSchemeProvider.notifier).set(s);

    return Scaffold(
      body: GameBackdrop(
        baseColor: AppColors.background,
        child: SafeArea(
          child: Column(
            children: [
              const SettingsHeader(title: 'KONTROL'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ControlSchemeCard(
                                  scheme: ControlScheme.joystick,
                                  title: 'JOYSTICK',
                                  hint: 'I-drag ang bilog para gumalaw',
                                  selected: scheme == ControlScheme.joystick,
                                  onTap: () => choose(ControlScheme.joystick),
                                ),
                              ),
                              const SizedBox(width: 22),
                              Expanded(
                                child: ControlSchemeCard(
                                  scheme: ControlScheme.arrows,
                                  title: 'MGA ARROW',
                                  hint: 'Pindutin ang kaliwa o kanan',
                                  selected: scheme == ControlScheme.arrows,
                                  onTap: () => choose(ControlScheme.arrows),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Saved na sa device na ito.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
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

/// One choice on the Controls screen: a picture of the layout, its name and a
/// one-line hint. The chosen card is lit with a gold ring and a NAKAPILI tag.
class ControlSchemeCard extends StatelessWidget {
  final ControlScheme scheme;
  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  const ControlSchemeCard({
    super.key,
    required this.scheme,
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $hint',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: selected
                    ? const [
                        BoxShadow(color: AppColors.accent, spreadRadius: 4),
                      ]
                    : null,
              ),
              child: GamePanel(
                color: selected ? const Color(0xFFFFF3D2) : AppColors.surface,
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: AspectRatio(
                        aspectRatio: 200 / 90,
                        child: CustomPaint(
                          painter: ControlLayoutPainter(scheme),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        height: 1.3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (selected)
              const Positioned(
                top: -12,
                right: 10,
                child: GameBadge(text: 'NAKAPILI', fontSize: 6),
              ),
          ],
        ),
      ),
    );
  }
}

/// A small drawing of a level with the chosen movement control in the bottom
/// left and Jump and Attack on the right, drawn in a 200 x 90 box.
class ControlLayoutPainter extends CustomPainter {
  final ControlScheme scheme;
  const ControlLayoutPainter(this.scheme);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 90);

    Paint fill(Color c) => Paint()..color = c;
    const white = Colors.white;

    canvas.drawRect(const Rect.fromLTWH(0, 0, 200, 90), fill(const Color(0xFF3A2D63)));
    canvas.drawRect(const Rect.fromLTWH(0, 72, 200, 18), fill(const Color(0xFF5D4E37)));
    canvas.drawRect(const Rect.fromLTWH(0, 72, 200, 4), fill(const Color(0xFF5AA845)));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(92, 40, 14, 32), const Radius.circular(3)),
      fill(const Color(0xFF2F5F9E)),
    );

    if (scheme == ControlScheme.joystick) {
      canvas.drawCircle(const Offset(30, 56), 16, fill(white.withValues(alpha: 0.3)));
      canvas.drawCircle(const Offset(30, 56), 7.5, fill(white.withValues(alpha: 0.8)));
    } else {
      for (final cx in const [24.0, 56.0]) {
        canvas.drawCircle(Offset(cx, 60), 13, fill(white.withValues(alpha: 0.35)));
      }
      final left = Path()
        ..moveTo(27, 53)
        ..lineTo(27, 67)
        ..lineTo(17, 60)
        ..close();
      final right = Path()
        ..moveTo(53, 53)
        ..lineTo(53, 67)
        ..lineTo(63, 60)
        ..close();
      canvas.drawPath(left, fill(white));
      canvas.drawPath(right, fill(white));
    }

    canvas.drawCircle(const Offset(150, 60), 12, fill(white.withValues(alpha: 0.35)));
    canvas.drawCircle(const Offset(178, 60), 12, fill(Colors.redAccent.withValues(alpha: 0.5)));
    canvas.restore();
  }

  @override
  bool shouldRepaint(ControlLayoutPainter old) => old.scheme != scheme;
}
