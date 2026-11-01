import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_info.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/update_provider.dart';
import 'living_backdrop.dart';
import 'pixel_icon.dart';

/// The "new version" card, drawn over a menu screen (put it last in the screen's
/// Stack, inside a `Positioned.fill`). It shows once for each version: DOWNLOAD
/// opens the download page, LATER puts it away and leaves the small
/// [UpdateChip]. A required update has no LATER and stays up. Draws nothing when
/// there is no newer version, which includes no internet.
class UpdateCard extends ConsumerWidget {
  const UpdateCard({super.key});

  static const Key cardKey = Key('update_card');
  static const Key downloadKey = Key('update_download');
  static const Key laterKey = Key('update_later');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateProvider);
    final latest = state.latest;
    if (latest == null || !state.showCard) return const SizedBox.shrink();
    final must = latest.required;
    final tone = must ? AppColors.danger : AppColors.accent;
    final notifier = ref.read(updateProvider.notifier);
    final bullets =
        must ? [if (latest.reason != null) latest.reason!] : latest.notes;

    return Stack(
      children: [
        // Nothing behind the card can be tapped.
        const ModalBarrier(dismissible: false, color: Color(0xC40A0612)),
        SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 340,
                    minHeight: box.maxHeight > 44 ? box.maxHeight - 44 : 0,
                  ),
                  child: Center(
                    child: Semantics(
                      container: true,
                      label:
                          must ? 'Kailangan mag-update' : 'May bagong version',
                      child: PanelCard(
                        key: cardKey,
                        tone: tone,
                        ribbon: must ? 'REQUIRED' : 'NEW!',
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 14),
                            Text(
                              must
                                  ? 'Mag-update muna bago maglaro'
                                  : 'May bagong version na!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                height: 1.2,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _Versions(from: appVersion, to: latest.version),
                            if (bullets.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              PanelNotes(
                                heading: must ? 'BAKIT?' : "WHAT'S NEW",
                                lines: bullets,
                                tone: tone,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: GoldButton(
                                    key: downloadKey,
                                    label: 'DOWNLOAD',
                                    onTap: notifier.openDownload,
                                  ),
                                ),
                                if (!must) ...[
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: WoodButton(
                                      key: laterKey,
                                      label: 'LATER',
                                      onTap: notifier.dismiss,
                                    ),
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
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The dark panel with the gold (or red) edge and the ribbon on top.
class PanelCard extends StatelessWidget {
  final Color tone;
  final String ribbon;
  final Widget child;
  const PanelCard(
      {super.key,
      required this.tone,
      required this.ribbon,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF231838),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primaryDark, width: 3),
            boxShadow: [
              const BoxShadow(
                  color: AppColors.primaryDark, offset: Offset(0, 5)),
              BoxShadow(
                  color: tone.withValues(alpha: 0.3),
                  blurRadius: 26,
                  spreadRadius: 2),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border:
                  Border.all(color: tone.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Padding(padding: const EdgeInsets.all(10), child: child),
          ),
        ),
        Positioned(
          top: -13,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            decoration: BoxDecoration(
              color: tone,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.primaryDark, width: 3),
              boxShadow: const [
                BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 3))
              ],
            ),
            child: Text(
              ribbon,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.6,
                color: tone == AppColors.danger
                    ? Colors.white
                    : AppColors.primaryDark,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "1.3.2 → 1.3.3": the old one small and crossed out, the new one big and gold.
class _Versions extends StatelessWidget {
  final String from;
  final String to;
  const _Versions({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Version $from papuntang $to',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            from,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8E7FA8),
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 10),
          const PixelIcon(PixelGlyph.chevron,
              size: 16, color: AppColors.accent),
          const SizedBox(width: 10),
          Text(
            to,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
              shadows: const [
                Shadow(color: AppColors.primaryDark, offset: Offset(0, 2))
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small box of lines, each with a gold diamond.
class PanelNotes extends StatelessWidget {
  final String heading;
  final List<String> lines;
  final Color tone;
  const PanelNotes(
      {super.key,
      required this.heading,
      required this.lines,
      required this.tone});

  @override
  Widget build(BuildContext context) {
    final head =
        tone == AppColors.danger ? const Color(0xFFFF8F86) : AppColors.accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: head,
            ),
          ),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5, right: 8),
                    child: Transform.rotate(
                      angle: 0.785398,
                      child: Container(
                          width: 6, height: 6, color: AppColors.accent),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        height: 1.3,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The gold button (DOWNLOAD, MAGLARO...). It breathes, unless the phone removes
/// animations.
class GoldButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final PixelGlyph? icon;
  final String? semanticLabel;
  const GoldButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = PixelGlyph.download,
    this.semanticLabel = 'I-download ang bagong version',
  });

  @override
  State<GoldButton> createState() => GoldButtonState();
}

class GoldButtonState extends State<GoldButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionAllowed(context)) {
      if (!_beat.isAnimating) _beat.repeat(reverse: true);
    } else {
      _beat.stop();
      _beat.value = 0;
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _beat,
          builder: (context, child) => Transform.scale(
            scale: 1 + 0.04 * Curves.easeInOut.transform(_beat.value),
            child: child,
          ),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.primaryDark, width: 3),
              boxShadow: const [
                BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 3))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  PixelIcon(widget.icon!,
                      size: 18, color: AppColors.primaryDark),
                  const SizedBox(width: 7),
                ],
                Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The wooden button (LATER, BUMALIK...).
class WoodButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final String? semanticLabel;
  const WoodButton({
    super.key,
    required this.label,
    required this.onTap,
    this.semanticLabel = 'Mamaya na',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.primaryDark, width: 3),
            boxShadow: const [
              BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 3))
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.accent,
            ),
          ),
        ),
      ),
    );
  }
}

/// The small gold "NEW UPDATE · 1.3.3" pill for a menu's top bar, shown after
/// LATER while the new version is still not installed. Tapping it opens the
/// download page. Draws nothing otherwise.
class UpdateChip extends ConsumerWidget {
  const UpdateChip({super.key});

  static const Key chipKey = Key('update_chip');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateProvider);
    final latest = state.latest;
    if (latest == null || !state.showChip) return const SizedBox.shrink();
    return Semantics(
      button: true,
      label: 'May bagong version ${latest.version}. I-download',
      excludeSemantics: true,
      child: GestureDetector(
        key: chipKey,
        onTap: ref.read(updateProvider.notifier).openDownload,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryDark, width: 2),
              boxShadow: const [
                BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PixelIcon(PixelGlyph.download,
                    size: 13, color: AppColors.primaryDark),
                const SizedBox(width: 5),
                Text(
                  'NEW UPDATE · ${latest.version}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A row for Settings: the version on this phone, and when there is a newer one,
/// what it is and a DOWNLOAD button (the way back for a student who tapped LATER).
class UpdateRow extends ConsumerWidget {
  const UpdateRow({super.key});

  static const Key rowKey = Key('update_row');
  static const Key downloadKey = Key('update_row_download');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(updateProvider).latest;
    final guest = ref.watch(authProvider.select((s) => s.isGuest));
    final has = latest != null;
    return Container(
      key: rowKey,
      constraints: const BoxConstraints(maxWidth: 360),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: has ? 8 : 6),
      decoration: BoxDecoration(
        color: has
            ? AppColors.accent.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: has ? AppColors.accent : Colors.white.withValues(alpha: 0.16),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  guest ? 'Guest · Version $appVersion' : 'Version $appVersion',
                  style: GoogleFonts.poppins(
                    fontSize: has ? 12 : 11,
                    fontWeight: FontWeight.w700,
                    color: has ? Colors.white : Colors.white70,
                  ),
                ),
                if (latest != null)
                  Text(
                    'May new version: ${latest.version}',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: AppColors.surface),
                  ),
              ],
            ),
          ),
          if (latest != null)
            Semantics(
              button: true,
              label: 'I-download ang bagong version',
              excludeSemantics: true,
              child: GestureDetector(
                key: downloadKey,
                onTap: ref.read(updateProvider.notifier).openDownload,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: AppColors.primaryDark, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.primaryDark, offset: Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PixelIcon(PixelGlyph.download,
                          size: 14, color: AppColors.primaryDark),
                      const SizedBox(width: 5),
                      Text(
                        'DOWNLOAD',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
