import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../models/control_scheme.dart';
import '../../widgets/action_disc.dart';
import '../../widgets/gate_icon.dart';
import '../../widgets/pixel_icon.dart';
import '../../widgets/scene_clock.dart';
import 'tutorial_scenes.dart';

/// What a page needs to know about the student when it is built.
class TutorialContext {
  /// True when the screen is wide enough for the picture beside the words.
  final bool wide;
  final String charId;
  final ControlScheme scheme;

  const TutorialContext(
      {required this.wide, required this.charId, required this.scheme});
}

/// One page of "Paano laruin": the colour of the light behind it and how to build it.
class TutorialStep {
  final String title;
  final Color color;
  final Widget Function(TutorialContext) build;

  const TutorialStep(
      {required this.title, required this.color, required this.build});
}

/// The pages in order: the three buttons, the artifact and the gate, Kaalaman, the
/// hearts, the coins and power-ups, the boss.
final List<TutorialStep> tutorialSteps = [
  TutorialStep(
      title: 'ANG MGA BUTTON',
      color: AppColors.accent,
      build: (c) => ControlsPage(context: c)),
  TutorialStep(
    title: 'ARTIFACT AT GATE',
    color: const Color(0xFFA77BFF),
    build: (c) => TutorialPageLayout(
      wide: c.wide,
      window: SceneClock(
          peek: 6300, builder: (_, ms) => FlowScene(charId: c.charId, ms: ms)),
      text: TutorialText(title: 'ARTIFACT AT GATE', children: [
        TutorialRow(
            leading: _asset('assets/collectibles/artifact_1.png'),
            text: 'Lapitan ang **artifact** at sagutin ang tanong.'),
        const TutorialRow(
            leading: GateIcon(size: 28),
            text: 'Kapag nasagot mo **lahat**, bubukas ang gate sa dulo.'),
        const TutorialNote(
            '**Mali ang sagot?** Walang mawawalang puso. Basahin ang paliwanag at subukan ulit.'),
      ]),
    ),
  ),
  TutorialStep(
    title: 'KAALAMAN ANG LAKAS MO',
    color: AppColors.info,
    build: (c) => TutorialPageLayout(
      wide: c.wide,
      window: SceneClock(
          peek: 4300,
          builder: (_, ms) => KaalamanScene(charId: c.charId, ms: ms)),
      text: TutorialText(title: 'KAALAMAN ANG LAKAS MO', children: [
        const TutorialRow(
            leading:
                ActionDisc(kind: ActionDiscKind.attack, size: 28, alpha: 1),
            text: 'Tumama ang atake',
            chip: TutorialChip('−1', AppColors.info)),
        TutorialRow(
            leading: _asset('assets/collectibles/artifact_1.png'),
            text: 'Tamang sagot sa artifact',
            chip: const TutorialChip('+2', AppColors.info)),
        const TutorialNote(
            'Ubos na ang Kaalaman? Babalik ang **1** pagkaraan ng ilang segundo.'),
      ]),
    ),
  ),
  TutorialStep(
    title: 'ALAGAAN ANG PUSO',
    color: AppColors.danger,
    build: (c) => TutorialPageLayout(
      wide: c.wide,
      window: SceneClock(
          peek: 4200, builder: (_, ms) => HeartScene(charId: c.charId, ms: ms)),
      text: TutorialText(title: 'ALAGAAN ANG PUSO', children: [
        TutorialRow(
            leading: _asset('assets/enemies/spanish_soldier_1.png'),
            text: 'Natamaan o nahulog',
            chip: const TutorialChip('−1', AppColors.danger,
                icon: 'assets/ui/heart_full.png')),
        const TutorialRow(
            leading:
                PixelIcon(PixelGlyph.clock, size: 22, color: AppColors.accent),
            text: 'Bawat 1 minuto',
            chip: TutorialChip('+1', AppColors.success,
                icon: 'assets/ui/heart_full.png')),
        const TutorialNote(
            '**${GameConstants.maxHearts} puso** lang sa buong laro, hindi sa isang level.'),
      ]),
    ),
  ),
  TutorialStep(
    title: 'COINS AT POWER-UP',
    color: AppColors.success,
    build: (c) => TutorialPageLayout(
      wide: c.wide,
      window: SceneClock(peek: 2300, builder: (_, ms) => ShopScene(ms: ms)),
      text: TutorialText(title: 'COINS AT POWER-UP', children: [
        TutorialRow(
            leading: _asset('assets/collectibles/coin.png'),
            text: '**Kunin** ang coins sa daan.'),
        const TutorialRow(
            leading:
                PixelIcon(PixelGlyph.cart, size: 22, color: AppColors.accent),
            text: '**Ipambili** sa Tindahan.'),
        const TutorialNote(
            'Gamitin ang **power-up** kapag mahirap ang tanong.'),
      ]),
    ),
  ),
  TutorialStep(
    title: 'BOSS SA DULO',
    color: const Color(0xFFFF7A2A),
    build: (c) => TutorialPageLayout(
      wide: c.wide,
      window: SceneClock(
          peek: 3600, builder: (_, ms) => BossScene(charId: c.charId, ms: ms)),
      text: const TutorialText(title: 'BOSS SA DULO', children: [
        TutorialRow(
            leading:
                PixelIcon(PixelGlyph.skull, size: 22, color: Color(0xFFFF8F86)),
            text: 'May **boss** sa dulo ng bawat panahon.'),
        TutorialRow(
            leading:
                Icon(Icons.check_circle, size: 24, color: AppColors.success),
            text: 'Sagutin nang tama ang **lahat** ng tanong.'),
        TutorialNote('**Mali o naubos ang oras?** Uulitin lang ang tanong.'),
      ]),
    ),
  ),
];

Widget _asset(String path) => Image.asset(path,
    width: 26,
    height: 26,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.none,
    errorBuilder: (_, __, ___) => const SizedBox(width: 26, height: 26));

// ── Layout ─────────────────────────────────────────────────────────────────────

/// A page laid out on a fixed board that the screen scales to fit: the picture
/// beside the words, or above them on a narrow phone.
class TutorialPageLayout extends StatelessWidget {
  final bool wide;
  final Widget window;
  final Widget text;

  const TutorialPageLayout(
      {super.key,
      required this.wide,
      required this.window,
      required this.text});

  static const double wideW = 640;
  static const double wideH = 212;
  static const double narrowW = 340;
  static const double narrowH = 440;

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return SizedBox(
        width: wideW,
        height: wideH,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              window,
              const SizedBox(width: 22),
              Expanded(
                  child: SizedBox(height: SceneWindow.outerH, child: text)),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      width: narrowW,
      height: narrowH,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
        child: Column(
          children: [
            window,
            const SizedBox(height: 14),
            Expanded(child: text),
          ],
        ),
      ),
    );
  }
}

/// The title and the lines of a page, centred on the picture's height. Scrolls
/// rather than overflow if a phone's font is large.
class TutorialText extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const TutorialText({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: AppColors.accent,
                    shadows: const [
                      Shadow(color: AppColors.primaryDark, offset: Offset(0, 2))
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                for (final c in children) ...[c, const SizedBox(height: 10)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `**word**` is bold and white; the rest is cream.
TextSpan tutorialSpan(String text, {double size = 12.5}) {
  final base = GoogleFonts.poppins(
      fontSize: size,
      height: 1.25,
      fontWeight: FontWeight.w500,
      color: const Color(0xFFF5E3BE));
  final bold = base.copyWith(fontWeight: FontWeight.w700, color: Colors.white);
  final parts = text.split('**');
  return TextSpan(children: [
    for (var i = 0; i < parts.length; i++)
      TextSpan(text: parts[i], style: i.isOdd ? bold : base)
  ]);
}

/// One line of a page: a small picture, the words, and sometimes a chip like "−1".
class TutorialRow extends StatelessWidget {
  final Widget leading;
  final String text;
  final String? small;
  final Widget? chip;
  final Widget? number;
  final bool selected;
  final VoidCallback? onTap;

  const TutorialRow(
      {super.key,
      required this.leading,
      required this.text,
      this.small,
      this.chip,
      this.number,
      this.selected = false,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final row = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: selected
            ? AppColors.accent.withValues(alpha: 0.13)
            : Colors.transparent,
        border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.65)
                : Colors.transparent,
            width: 2),
      ),
      child: Row(
        children: [
          if (number != null) ...[number!, const SizedBox(width: 6)],
          SizedBox(width: 28, height: 28, child: Center(child: leading)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(tutorialSpan(text)),
                if (small != null)
                  Text(small!,
                      style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFCDBA94))),
              ],
            ),
          ),
          if (chip != null) ...[const SizedBox(width: 6), chip!],
        ],
      ),
    );
    if (onTap == null) return row;
    return GestureDetector(
        behavior: HitTestBehavior.opaque, onTap: onTap, child: row);
  }
}

class TutorialNote extends StatelessWidget {
  final String text;
  const TutorialNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
            color: const Color(0xFFF5E3BE).withValues(alpha: 0.24), width: 1.5),
      ),
      child: Text.rich(tutorialSpan(text, size: 11.5)),
    );
  }
}

class TutorialChip extends StatelessWidget {
  final String text;
  final Color color;
  final String? icon;
  const TutorialChip(this.text, this.color, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.primaryDark, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Image.asset(icon!,
                width: 11,
                height: 11,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) => const SizedBox(width: 11)),
            const SizedBox(width: 3)
          ],
          Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2)),
        ],
      ),
    );
  }
}

// ── Page 1: the buttons, which can be tried ───────────────────────────────────

/// The three buttons. The picture shows each in turn by itself; tapping a line or
/// a button in the picture shows that one for a few seconds.
class ControlsPage extends StatefulWidget {
  final TutorialContext context;
  const ControlsPage({super.key, required this.context});

  static const Duration each = Duration(milliseconds: 2500);
  static const int forcedFor = 5200;

  @override
  State<ControlsPage> createState() => _ControlsPageState();
}

class _ControlsPageState extends State<ControlsPage> {
  ControlAct? _forced;
  int _forcedAt = 0;
  int _ms = 0;

  void _force(ControlAct act) => setState(() {
        _forced = act;
        _forcedAt = _ms;
      });

  @override
  Widget build(BuildContext context) {
    final c = widget.context;
    return TutorialPageLayout(
      wide: c.wide,
      window: SceneClock(
        builder: (_, ms) {
          _ms = ms;
          final (act, local) = _now(ms);
          return ControlsScene(
              charId: c.charId,
              scheme: c.scheme,
              act: act,
              local: local,
              ms: ms,
              onTapControl: _force);
        },
      ),
      text: SceneClock(
        builder: (_, ms) {
          final (act, _) = _now(ms);
          final arrows = c.scheme == ControlScheme.arrows;
          return TutorialText(title: 'ANG MGA BUTTON', children: [
            TutorialRow(
              number: const NumberBadge(1),
              leading: arrows ? const ArrowPair(size: 13) : const _StickIcon(),
              text: '**GUMALAW**',
              small:
                  arrows ? 'Pindutin ang kaliwa o kanan' : 'I-drag ang bilog',
              selected: act == ControlAct.move,
              onTap: () => _force(ControlAct.move),
            ),
            TutorialRow(
              number: const NumberBadge(2),
              leading: const ActionDisc(
                  kind: ActionDiscKind.jump, size: 28, alpha: 1),
              text: '**TUMALON**',
              small: 'Iwas sa kalaban at butas',
              selected: act == ControlAct.jump,
              onTap: () => _force(ControlAct.jump),
            ),
            TutorialRow(
              number: const NumberBadge(3),
              leading: const ActionDisc(
                  kind: ActionDiscKind.attack, size: 28, alpha: 1),
              text: '**UMATAKE**',
              small: 'Gumagamit ng Kaalaman',
              selected: act == ControlAct.attack,
              onTap: () => _force(ControlAct.attack),
            ),
          ]);
        },
      ),
    );
  }

  /// Which act is on show at clock time [ms], and how long it has been showing.
  (ControlAct, int) _now(int ms) {
    final forced = _forced;
    if (forced != null && ms - _forcedAt < ControlsPage.forcedFor) {
      return (forced, ms - _forcedAt);
    }
    final each = ControlsPage.each.inMilliseconds;
    final k = (ms ~/ each) % ControlAct.values.length;
    return (ControlAct.values[k], ms % each);
  }
}

class _StickIcon extends StatelessWidget {
  const _StickIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.3))),
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.85))),
      ],
    );
  }
}
