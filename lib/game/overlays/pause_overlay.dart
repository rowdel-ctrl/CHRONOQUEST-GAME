import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/living_backdrop.dart' show motionAllowed;
import '../../widgets/pixel_icon.dart';
import '../chrono_game.dart';

/// Pause menu overlay: one big gold play button in the middle, with Settings
/// and Umalis (leave) as small round buttons either side. Each has one word
/// under it, so what it does is never a guess.
///
/// Keeps the panel out of the picture: the level shows dimmed behind a few
/// slow rays, and the whole menu is about 170 high, which fits a sideways
/// phone's short screen without scrolling.
class PauseOverlayWidget extends StatelessWidget {
  static const playKey = ValueKey('pause-play');
  static const settingsKey = ValueKey('pause-settings');
  static const quitKey = ValueKey('pause-quit');

  final ChronoGame game;
  final VoidCallback onQuit;

  /// Opens Settings over the paused level. Null hides the button, which is
  /// how the overlay behaves wherever there is no router to open it with.
  final VoidCallback? onSettings;
  const PauseOverlayWidget(
      {super.key, required this.game, required this.onQuit, this.onSettings});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Block taps
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.black.withValues(alpha: 0.72)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PAUSE',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      height: 1.2,
                      color: AppColors.accent,
                      shadows: const [
                        Shadow(
                            color: AppColors.primaryDark, offset: Offset(0, 3)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (onSettings != null) ...[
                        _PauseAction(
                          key: settingsKey,
                          label: 'SETTINGS',
                          onTap: onSettings!,
                          face: const _SmallFace(
                              glyph: PixelGlyph.gear, color: AppColors.primary),
                        ),
                        const SizedBox(width: 34),
                      ],
                      _PauseAction(
                        key: playKey,
                        label: 'ITULOY',
                        onTap: () {
                          game.overlays.remove('PauseOverlay');
                          game.resumeEngine();
                        },
                        face: const _PlayFace(),
                        topGap: 0,
                      ),
                      const SizedBox(width: 34),
                      _PauseAction(
                        key: quitKey,
                        label: 'UMALIS',
                        onTap: () => _confirmQuit(context),
                        face: const _SmallFace(
                            glyph: PixelGlyph.door, color: Color(0xFF8F2A22)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmQuit(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          side: BorderSide(color: AppColors.primaryDark, width: 3),
        ),
        title: Text(
          'Umalis sa Level?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Mawawala ang progress mo sa level na ito kung aalis ka ngayon.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Kanselahin',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              game.overlays.remove('PauseOverlay');
              // Deliberately does NOT resume the engine: this level is being
              // torn down, and resuming restarts the game loop immediately,
              // so frames run between here and the route actually changing.
              // Those frames can reach levelComplete()/showLevelFailed(),
              // whose callbacks navigate somewhere else on top of this quit.
              onQuit();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(
              'Umalis',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// A round button and the one word under it. The whole column is the target, so
/// a thumb that lands on the word still works.
class _PauseAction extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Widget face;
  final double topGap;

  const _PauseAction({
    super.key,
    required this.label,
    required this.onTap,
    required this.face,
    this.topGap = 17,
  });

  @override
  State<_PauseAction> createState() => _PauseActionState();
}

class _PauseActionState extends State<_PauseAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Padding(
          padding: EdgeInsets.only(top: widget.topGap),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _pressed ? 0.92 : 1,
                duration: const Duration(milliseconds: 80),
                child: widget.face,
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  height: 1.2,
                  color: const Color(0xFFCDBA94),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The big gold play button. It breathes slowly, unless the phone has animations
/// removed.
class _PlayFace extends StatefulWidget {
  const _PlayFace();

  @override
  State<_PlayFace> createState() => _PlayFaceState();
}

class _PlayFaceState extends State<_PlayFace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionAllowed(context)) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.045 * Curves.easeInOut.transform(_controller.value),
        child: child,
      ),
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accent,
          border: Border.all(color: AppColors.primaryDark, width: 4),
          boxShadow: const [
            BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 4)),
          ],
        ),
        child: const Icon(Icons.play_arrow_rounded,
            size: 52, color: AppColors.primaryDark),
      ),
    );
  }
}

class _SmallFace extends StatelessWidget {
  final PixelGlyph glyph;
  final Color color;
  const _SmallFace({required this.glyph, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryDark, width: 3),
        boxShadow: const [
          BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 3)),
        ],
      ),
      child: PixelIcon(glyph, size: 28, color: AppColors.accent),
    );
  }
}
