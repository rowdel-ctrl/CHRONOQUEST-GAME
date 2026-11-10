import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/control_scheme.dart';
import '../../providers/control_scheme_provider.dart';
import '../../providers/game_provider.dart';
import '../../widgets/game_ui.dart';
import 'settings_header.dart';

/// Kontrol: pick how to move. Two cards, each showing a level as it looks in play
/// (your own hero on the deck, the hearts, pause, jump and attack) with the
/// movement control in the bottom left, so a student can choose by what they see.
/// The choice is saved at once on this device and applies the next time a level
/// is on screen. The cards sit side by side, or one above the other on a narrow
/// phone.
class ControlsScreen extends ConsumerWidget {
  const ControlsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = ref.watch(controlSchemeProvider);
    final hero = ref.watch(gameProvider.select((s) => s.selectedCharacterId));
    void choose(ControlScheme s) =>
        ref.read(controlSchemeProvider.notifier).set(s);

    final joystick = ControlSchemeCard(
      scheme: ControlScheme.joystick,
      title: 'JOYSTICK',
      hint: 'I-drag ang bilog para gumalaw',
      selected: scheme == ControlScheme.joystick,
      heroId: hero,
      onTap: () => choose(ControlScheme.joystick),
    );
    final arrows = ControlSchemeCard(
      scheme: ControlScheme.arrows,
      title: 'MGA ARROW',
      hint: 'Pindutin ang kaliwa o kanan',
      selected: scheme == ControlScheme.arrows,
      heroId: hero,
      onTap: () => choose(ControlScheme.arrows),
    );

    return Scaffold(
      body: GameBackdrop(
        baseColor: AppColors.background,
        child: SafeArea(
          child: Column(
            children: [
              const SettingsHeader(title: 'KONTROL'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        children: [
                          if (MediaQuery.sizeOf(context).width >= 560)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: joystick),
                                const SizedBox(width: 22),
                                Expanded(child: arrows),
                              ],
                            )
                          else ...[
                            joystick,
                            const SizedBox(height: 18),
                            arrows,
                          ],
                          const SizedBox(height: 14),
                          Text(
                            'Saved na sa device na ito.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFFC9BEDB),
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

/// One choice on the Controls screen: a picture of a level with that layout, a
/// round marker, its name and a one-line hint. The chosen card is lit with a gold
/// ring, a filled marker and a green NAKAPILI tag. Tap it to choose it.
class ControlSchemeCard extends StatelessWidget {
  final ControlScheme scheme;
  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  /// Whose walking picture stands on the deck in the drawing.
  final String heroId;

  const ControlSchemeCard({
    super.key,
    required this.scheme,
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
    this.heroId = 'boy',
  });

  /// The round marker (filled when chosen), for tests.
  static ValueKey<String> markerKey(ControlScheme s) =>
      ValueKey('control_marker_${s.name}');

  /// The gold ring around the chosen card, for tests.
  static ValueKey<String> ringKey(ControlScheme s) =>
      ValueKey('control_ring_${s.name}');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $hint',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            key: ringKey(scheme),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: selected
                  ? [
                      const BoxShadow(color: AppColors.accent, spreadRadius: 4),
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.4),
                        spreadRadius: 4,
                        blurRadius: 24,
                      ),
                    ]
                  : null,
            ),
            child: GamePanel(
              color: selected ? const Color(0xFFFFF3D2) : AppColors.surface,
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ControlPreview(scheme: scheme, heroId: heroId),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        key: markerKey(scheme),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? AppColors.accent : null,
                          border: Border.all(
                              color: AppColors.primaryDark, width: 3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  letterSpacing: 0.6,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              hint,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                height: 1.3,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 8),
                        const GameBadge(
                          text: 'NAKAPILI',
                          color: AppColors.success,
                          textColor: Color(0xFF0E2A0C),
                          fontSize: 8,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A picture of a level in play, with the chosen movement control: night sky, the
/// wooden deck, the player's hero walking on it, three hearts top left, the pause
/// square top right, Jump and Attack round buttons bottom right, and the joystick
/// (with a gold knob) or the two arrow buttons bottom left. It is drawn on a
/// 306 x 132 grid and scaled to the width it is given.
class ControlPreview extends StatelessWidget {
  final ControlScheme scheme;
  final String heroId;

  const ControlPreview({super.key, required this.scheme, this.heroId = 'boy'});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.primaryDark, width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AspectRatio(
          aspectRatio:
              ControlLayoutPainter.gridWidth / ControlLayoutPainter.gridHeight,
          child: LayoutBuilder(builder: (context, box) {
            final k = box.maxWidth / ControlLayoutPainter.gridWidth;
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: ControlLayoutPainter(scheme)),
                ),
                // The hero stands a little onto the deck.
                Positioned(
                  left: 96 * k,
                  bottom: 24 * k,
                  height: 52 * k,
                  child: Image.asset(
                    'assets/characters/${heroId}_walk_1.png',
                    height: 52 * k,
                    fit: BoxFit.fitHeight,
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.none,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                Positioned(
                  left: 8 * k,
                  top: 6 * k,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) SizedBox(width: 2 * k),
                        Image.asset(
                          'assets/ui/heart_full.png',
                          width: 14 * k,
                          height: 14 * k,
                          filterQuality: FilterQuality.none,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// The drawing under [ControlPreview]: sky, deck, pause square, Jump and Attack,
/// and the joystick or the arrows. Drawn in a [gridWidth] x [gridHeight] box and
/// scaled to the space it is given.
class ControlLayoutPainter extends CustomPainter {
  final ControlScheme scheme;
  const ControlLayoutPainter(this.scheme);

  static const double gridWidth = 306;
  static const double gridHeight = 132;

  static const Color _gold = Color(0xFFFFC531);
  static const Color _ink = Color(0xFF2E1608);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / gridWidth, size.height / gridHeight);
    const sky = Rect.fromLTWH(0, 0, gridWidth, gridHeight);

    // The night sky.
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A1B50), Color(0xFF5E3A74), Color(0xFF5E3A74)],
          stops: [0, 0.7, 1],
        ).createShader(sky),
    );

    // The wooden deck, with a light edge.
    canvas.drawRect(const Rect.fromLTWH(0, 106, gridWidth, 26),
        Paint()..color = const Color(0xFF6B3A1F));
    canvas.drawRect(const Rect.fromLTWH(0, 106, gridWidth, 3),
        Paint()..color = const Color(0xFFB8763E));

    // The pause square, top right.
    final pause = RRect.fromRectAndRadius(
        const Rect.fromLTWH(278, 6, 20, 20), const Radius.circular(5));
    canvas.drawRRect(pause, Paint()..color = const Color(0xFF6B3A1F));
    canvas.drawRRect(
      pause.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _ink,
    );

    if (scheme == ControlScheme.joystick) {
      _circle(canvas, const Offset(38, 96), 28);
      // The knob, pushed a little to one side.
      canvas.drawCircle(const Offset(44, 93), 12, Paint()..color = _gold);
      canvas.drawCircle(
        const Offset(44, 93),
        11,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _ink,
      );
    } else {
      for (final (x, chevron) in [(10.0, _left), (46.0, _right)]) {
        final r = RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 88, 30, 34), const Radius.circular(7));
        _plate(canvas, r);
        _glyph(canvas, chevron, Offset(x + 15, 105));
      }
    }

    // Jump, then Attack.
    _circle(canvas, const Offset(236, 102), 18);
    _glyph(canvas, _up, const Offset(236, 102));
    _circle(canvas, const Offset(276, 104), 20);
    _glyph(canvas, _attack, const Offset(276, 104));
    canvas.restore();
  }

  void _plate(Canvas canvas, RRect r) {
    canvas.drawRRect(r, Paint()..color = const Color.fromRGBO(10, 6, 18, 0.45));
    canvas.drawRRect(
      r.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _gold.withValues(alpha: 0.85),
    );
  }

  void _circle(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
        c, r, Paint()..color = const Color.fromRGBO(10, 6, 18, 0.45));
    canvas.drawCircle(
      c,
      r - 1.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _gold.withValues(alpha: 0.85),
    );
  }

  // Icons, drawn on a 24 x 24 grid and shown 20 across.
  static Path get _up => Path()
    ..moveTo(6, 15)
    ..relativeLineTo(6, -6)
    ..relativeLineTo(6, 6);
  static Path get _left => Path()
    ..moveTo(15, 5)
    ..relativeLineTo(-7, 7)
    ..relativeLineTo(7, 7);
  static Path get _right => Path()
    ..moveTo(9, 5)
    ..relativeLineTo(7, 7)
    ..relativeLineTo(-7, 7);
  static Path get _attack => Path()
    ..moveTo(7, 17)
    ..lineTo(17, 7)
    ..moveTo(14, 6)
    ..relativeLineTo(4, 0)
    ..relativeLineTo(0, 4)
    ..moveTo(6, 14)
    ..relativeLineTo(4, 4);

  void _glyph(Canvas canvas, Path path, Offset c) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(20 / 24);
    canvas.translate(-12, -12);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = _gold,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(ControlLayoutPainter old) => old.scheme != scheme;
}
