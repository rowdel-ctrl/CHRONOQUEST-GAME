import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';
import '../models/era_progress.dart';

/// One page of an era's book, in design units. A closed book is one page wide; an open one is
/// two. The shelf scales the whole book to fit the screen.
const double kBookPageW = 236;
const double kBookPageH = 252;

/// How thick the book is, in the same units (the mockup's 2.2% of the screen width on a 24%
/// wide page, so the same 9% of a page).
const double kBookDepth = 22;

/// How far the cover floats above the pages, and the chains above the cover (the mockup's .8
/// and 1.8, in the same units as the page).
const double _kCoverLift = 8;
const double _kChainLift = 18;

/// The cover's own thickness, and how far the back boards stick out past the pages.
const double _kCoverThick = 9;
const double _kBoardOverhang = 11;

/// A line about each era for the left page, in everyday words.
String eraBlurb(String eraId) {
  switch (eraId) {
    case 'pre-colonial':
      return 'Ang buhay ng mga Pilipino bago dumating ang mga dayuhan.';
    case 'spanish':
      return 'Mahigit tatlong daang taon sa ilalim ng Espanya.';
    case 'nationalism':
      return 'Ang paggising ng pagmamahal sa bayan.';
    case 'american':
      return 'Ang himagsikan at ang pagdating ng mga Amerikano.';
    case 'ww2':
      return 'Ang pamahalaang kolonyal at ang pananakop ng mga Hapon.';
    case 'modern':
      return 'Mula sa Batas Militar hanggang sa muling pagbangon ng demokrasya.';
    default:
      return '';
  }
}

/// The animations that play on a book while its chains come off: [charge] is the build-up
/// (0 to 1), [burst] the break itself (0 to 1 over [burstSeconds]). [seed] makes the links
/// of one book fly the same way every time.
class BookChainFx {
  final Animation<double> charge;
  final Animation<double> burst;
  final int seed;

  /// How long the burst animation runs, in seconds (the shelf sets the controller to this).
  static const double burstSeconds = 2.6;

  const BookChainFx({required this.charge, required this.burst, this.seed = 7});

  Listenable get listenable => Listenable.merge([charge, burst]);

  /// How locked the book still looks: 1 chained and grey, 0 free and in colour. The colour
  /// comes back while the chains fly off.
  double get lockLook {
    final t = burst.value * burstSeconds;
    if (t < 0.45) return 1;
    return 1 - Curves.easeOut.transform(((t - 0.45) / 0.8).clamp(0.0, 1.0));
  }

  /// Whether the chains are still on (until the last link has gone).
  bool get chainsOn => burst.value * burstSeconds < 1.7;
}

/// An era's book. Closed it is a cover (the colour, the number, the boss, the name); open it is
/// a spread: the left page tells the era, the right shows the progress and the gold button. A
/// locked book is chained shut, and [chainFx] plays the chains coming off.
class EraBook extends StatefulWidget {
  final EraData era;
  final int number;
  final Color color;
  final EraProgress progress;

  /// Whether the book is shut: chained (or a guest's). Ignored while [chainFx] says otherwise.
  final bool locked;
  final bool guestLocked;
  final String? previousName;

  /// In front of the shelf: shows the line on its cover and the pulsing hint.
  final bool focused;

  /// The spread is open.
  final bool open;
  final BookChainFx? chainFx;

  /// A tap on the cover.
  final VoidCallback? onCover;

  /// The gold button on the right page.
  final VoidCallback? onPlay;
  final Key? coverKey;
  final Key? playKey;
  final Key? progressKey;
  final Key? lockedNoteKey;

  const EraBook({
    super.key,
    required this.era,
    required this.number,
    required this.color,
    required this.progress,
    required this.locked,
    required this.guestLocked,
    required this.previousName,
    required this.focused,
    required this.open,
    this.chainFx,
    this.onCover,
    this.onPlay,
    this.coverKey,
    this.playKey,
    this.progressKey,
    this.lockedNoteKey,
  });

  @override
  State<EraBook> createState() => _EraBookState();
}

class _EraBookState extends State<EraBook> with SingleTickerProviderStateMixin {
  late final AnimationController _open = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 850));

  @override
  void initState() {
    super.initState();
    _open.value = widget.open ? 1 : 0;
  }

  @override
  void didUpdateWidget(EraBook old) {
    super.didUpdateWidget(old);
    if (widget.open != old.open) {
      final moving = MediaQuery.maybeOf(context)?.disableAnimations != true;
      if (!moving) {
        _open.value = widget.open ? 1 : 0;
      } else if (widget.open) {
        _open.forward();
      } else {
        _open.reverse();
      }
    }
  }

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  static Matrix4 _plane(double z) =>
      Matrix4.identity()..setTranslationRaw(0, 0, z);

  @override
  Widget build(BuildContext context) {
    final fx = widget.chainFx;
    return AnimatedBuilder(
      animation: Listenable.merge([_open, if (fx != null) fx.listenable]),
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_open.value);
        final lock = fx != null ? fx.lockLook : (widget.locked ? 1.0 : 0.0);
        final chained = fx != null ? fx.chainsOn : widget.locked;
        final spine = kBookPageW / 2 + t * kBookPageW / 2;
        final angle = math.pi * t;
        final color =
            Color.lerp(widget.color, const Color(0xFF3A3548), 0.55 * lock)!;

        final tilt = Matrix4.identity()
          ..setEntry(3, 2, -0.0011)
          ..rotateX(0.42);

        final cover = _Cover(
          era: widget.era,
          number: widget.number,
          color: color,
          progress: widget.progress,
          lock: lock,
          guestLocked: widget.guestLocked,
          previousName: widget.previousName,
          focused: widget.focused,
          coverKey: widget.coverKey,
          lockedNoteKey: widget.lockedNoteKey,
        );
        final left = _LeftPage(
            era: widget.era, number: widget.number, color: widget.color);

        return SizedBox(
          width: kBookPageW * 2,
          height: kBookPageH + 2 * kBookDepth + 16,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The shadow on the table, flat under the tilted book.
              Positioned(
                left: spine +
                    kBookPageW / 2 * (1 - t) -
                    kBookPageW * (0.85 + 1.1 * t) / 2,
                width: kBookPageW * (0.85 + 1.1 * t),
                bottom: 2,
                height: 18,
                child: const CustomPaint(painter: _TableShadow()),
              ),
              Positioned.fill(
                child: Transform(
                  alignment: Alignment.center,
                  transform: tilt,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // The back boards: the cover's colour, a little bigger than the pages.
                      if (t > 0.02)
                        _at(spine, 0,
                            _plate(color, left: true, alpha: t.clamp(0.0, 1.0)),
                            z: -kBookDepth,
                            w: kBookPageW,
                            left: spine - kBookPageW),
                      _at(spine, 0, _plate(color, left: false, alpha: 1),
                          z: -kBookDepth, w: kBookPageW),
                      // The page edges, so the book has thickness.
                      ..._edges(spine, t),
                      // The right page, under the cover.
                      _at(
                          spine,
                          0,
                          _RightPage(
                            era: widget.era,
                            color: widget.color,
                            progress: widget.progress,
                            onPlay: widget.onPlay,
                            playKey: widget.playKey,
                            progressKey: widget.progressKey,
                          ),
                          w: kBookPageW),
                      // The cover turns about the spine; its back is the left page.
                      Positioned(
                        left: spine,
                        top: kBookDepth + 8,
                        width: kBookPageW,
                        height: kBookPageH,
                        child: Transform(
                          alignment: Alignment.centerLeft,
                          transform: _plane(_kCoverLift)..rotateY(-angle),
                          child: angle < math.pi / 2
                              ? Stack(clipBehavior: Clip.none, children: [
                                  ..._coverEdges(color),
                                  Positioned.fill(
                                    child: Semantics(
                                      button: true,
                                      selected: widget.focused,
                                      label: lock > 0.5
                                          ? (widget.guestLocked
                                              ? '${widget.era.name}, para sa naka-sign in'
                                              : '${widget.era.name}, naka-lock')
                                          : widget.era.name,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: widget.onCover,
                                        child: cover,
                                      ),
                                    ),
                                  ),
                                ])
                              : Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.rotationY(math.pi),
                                  child: left,
                                ),
                        ),
                      ),
                      // The chains, over the closed cover.
                      if (chained && t < 0.05)
                        Positioned(
                          left: spine,
                          top: kBookDepth + 8,
                          width: kBookPageW,
                          height: kBookPageH,
                          child: Transform(
                            transform: _plane(_kChainLift),
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _ChainsPainter(
                                  charge: fx?.charge.value ?? 0,
                                  burst: fx?.burst.value ?? 0,
                                  seed: fx?.seed ?? widget.era.id.hashCode,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// A page-sized box at [spine] (or [left]), lifted by [z] toward the viewer.
  Widget _at(double spine, double top, Widget child,
      {double z = 0, required double w, double? left}) {
    return Positioned(
      left: left ?? spine,
      top: kBookDepth + 8,
      width: w,
      height: kBookPageH,
      child: z == 0 ? child : Transform(transform: _plane(z), child: child),
    );
  }

  Widget _plate(Color color, {required bool left, required double alpha}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: left ? -_kBoardOverhang : 0,
          top: -_kBoardOverhang,
          right: left ? 0 : -_kBoardOverhang,
          bottom: -_kBoardOverhang,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: alpha),
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(left ? 18 : 0),
                right: Radius.circular(left ? 0 : 18),
              ),
              border: Border.all(
                  color: Colors.black.withValues(alpha: 0.3 * alpha), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  /// The stacked pages seen from the side: the bottom of each half and the right edge.
  List<Widget> _edges(double spine, double t) {
    Widget stripes({required bool vertical, double alpha = 1}) =>
        CustomPaint(painter: _PageStripes(vertical: vertical, alpha: alpha));
    const top = kBookDepth + 8;
    return [
      // bottom, right half
      Positioned(
        left: spine,
        top: top + kBookPageH,
        width: kBookPageW,
        height: kBookDepth,
        child: Transform(
          alignment: Alignment.topCenter,
          transform: Matrix4.rotationX(-math.pi / 2),
          child: stripes(vertical: false),
        ),
      ),
      // right edge
      Positioned(
        left: spine + kBookPageW,
        top: top,
        width: kBookDepth,
        height: kBookPageH,
        child: Transform(
          alignment: Alignment.centerLeft,
          transform: Matrix4.rotationY(math.pi / 2),
          child: stripes(vertical: true),
        ),
      ),
      // the left half, once the book is opening
      if (t > 0.02) ...[
        Positioned(
          left: spine - kBookPageW,
          top: top + kBookPageH,
          width: kBookPageW,
          height: kBookDepth,
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.rotationX(-math.pi / 2),
            child: stripes(vertical: false, alpha: t.clamp(0.0, 1.0)),
          ),
        ),
        Positioned(
          left: spine - kBookPageW - kBookDepth,
          top: top,
          width: kBookDepth,
          height: kBookPageH,
          child: Transform(
            alignment: Alignment.centerRight,
            transform: Matrix4.rotationY(-math.pi / 2),
            child: stripes(vertical: true, alpha: t.clamp(0.0, 1.0)),
          ),
        ),
      ],
    ];
  }

  /// The cover's own thin edges (its thickness), in a darker colour of the cover.
  List<Widget> _coverEdges(Color color) {
    final dark = Color.lerp(color, Colors.black, 0.4)!;
    return [
      Positioned(
        left: 0,
        top: kBookPageH,
        width: kBookPageW,
        height: _kCoverThick,
        child: Transform(
          alignment: Alignment.topCenter,
          transform: Matrix4.rotationX(-math.pi / 2),
          child: ColoredBox(color: dark),
        ),
      ),
      Positioned(
        left: kBookPageW,
        top: 0,
        width: _kCoverThick,
        height: kBookPageH,
        child: Transform(
          alignment: Alignment.centerLeft,
          transform: Matrix4.rotationY(math.pi / 2),
          child: ColoredBox(color: dark),
        ),
      ),
    ];
  }
}

/// The soft dark oval under a book on the table.
class _TableShadow extends CustomPainter {
  const _TableShadow();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Offset.zero & size,
      Paint()
        ..color = const Color(0xB3000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
  }

  @override
  bool shouldRepaint(_TableShadow old) => false;
}

/// The pages of a book seen from the side: thin light lines with a darker line between.
class _PageStripes extends CustomPainter {
  final bool vertical;
  final double alpha;
  const _PageStripes({required this.vertical, this.alpha = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()
      ..color = const Color(0xFFF6ECD2).withValues(alpha: alpha);
    final dark = Paint()
      ..color = const Color(0xFFB39A62).withValues(alpha: alpha);
    canvas.drawRect(Offset.zero & size, dark);
    const step = 3.0;
    if (vertical) {
      for (var x = 0.0; x < size.width; x += step) {
        canvas.drawRect(Rect.fromLTWH(x, 0, step - 0.8, size.height), light);
      }
    } else {
      for (var y = 0.0; y < size.height; y += step) {
        canvas.drawRect(Rect.fromLTWH(0, y, size.width, step - 0.8), light);
      }
    }
  }

  @override
  bool shouldRepaint(_PageStripes old) =>
      old.vertical != vertical || old.alpha != alpha;
}

// ─── THE COVER ───────────────────────────────────────────────────────────────

class _Cover extends StatelessWidget {
  final EraData era;
  final int number;
  final Color color;
  final EraProgress progress;
  final double lock;
  final bool guestLocked;
  final String? previousName;
  final bool focused;
  final Key? coverKey;
  final Key? lockedNoteKey;

  const _Cover({
    required this.era,
    required this.number,
    required this.color,
    required this.progress,
    required this.lock,
    required this.guestLocked,
    required this.previousName,
    required this.focused,
    required this.coverKey,
    required this.lockedNoteKey,
  });

  @override
  Widget build(BuildContext context) {
    final locked = lock > 0.5;
    final done = progress.isCompleted;
    final levels = era.levels.length;
    final filled =
        done ? levels : progress.levelsCompleted.clamp(0, levels).toInt();
    Widget boss = _eraMedalPicture(era);
    if (lock > 0.01) {
      // A dark shape: the enemy is not known yet.
      boss = ColorFiltered(
        colorFilter: ColorFilter.mode(
            Color.lerp(Colors.transparent, const Color(0x99000000), lock)!,
            BlendMode.srcATop),
        child: boss,
      );
    }
    return Container(
      key: coverKey,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.1)!,
            Color.lerp(color, Colors.black, 0.28)!
          ],
        ),
        // A thin dark rim, like the edge of the board.
        border: Border.all(color: const Color(0x38000000), width: 5),
      ),
      child: Stack(
        children: [
          // The gold frame, set in from the edge.
          Positioned(
            left: 5,
            top: 5,
            right: 5,
            bottom: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(8)),
                border: Border.all(color: AppColors.accent, width: 4),
              ),
            ),
          ),
          // The shadow of the spine.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 22,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent
                ]),
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 14,
            right: 18,
            bottom: 16,
            child: Center(
                child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                        width: 200,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'KABANATA $number',
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2.4,
                                  color: AppColors.accent),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 96,
                              height: 96,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.25),
                                border: Border.all(
                                    color: AppColors.accent, width: 4),
                              ),
                              child: boss,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              era.name,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  height: 1.2,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            if (guestLocked)
                              const _Pill(
                                  label: 'PARA SA NAKA-SIGN IN',
                                  color: Color(0xFF231838),
                                  textColor: AppColors.accent,
                                  border: AppColors.accent)
                            else if (locked)
                              Text.rich(
                                previousName == null
                                    ? const TextSpan(
                                        text: 'Naka-lock pa ang era na ito.')
                                    : TextSpan(children: [
                                        const TextSpan(
                                            text: 'Tapusin muna ang '),
                                        TextSpan(
                                            text: previousName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                        const TextSpan(
                                            text: ' para mabuksan ito.'),
                                      ]),
                                key: lockedNoteKey,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    height: 1.35,
                                    color: const Color(0xFFE2D9F0)),
                              )
                            else ...[
                              Container(
                                height: 10,
                                width: 130,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                clipBehavior: Clip.antiAlias,
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  heightFactor: 1,
                                  widthFactor:
                                      levels == 0 ? 0 : filled / levels,
                                  child:
                                      const ColoredBox(color: AppColors.accent),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _Pill(
                                label: done
                                    ? 'BALIKAN ANG LIBRO'
                                    : 'PINDUTIN PARA BUKSAN',
                                color: AppColors.accent,
                                textColor: AppColors.primaryDark,
                                border: AppColors.primaryDark,
                              ),
                            ],
                          ],
                        )))),
          ),
          if (done && !locked)
            Positioned(
              right: 10,
              top: 8,
              child: Image.asset('assets/ui/star_full.png',
                  width: 24, height: 24, filterQuality: FilterQuality.none),
            ),
          if (locked && lock > 0.9)
            Positioned(
              right: 10,
              top: 8,
              child: Image.asset('assets/ui/lock_icon.png',
                  width: 22, height: 22, filterQuality: FilterQuality.none),
            ),
        ],
      ),
    );
  }
}

/// The picture on an era's medal: the first enemy of the era (a tribal warrior, a Spanish soldier,
/// ...), as on the mockup. They face left, so it is drawn as it is.
Widget _eraMedalPicture(EraData era) {
  if (era.enemyTypes.isEmpty) return const SizedBox();
  return Image.asset(
    'assets/enemies/${era.enemyTypes.first}_1.png',
    fit: BoxFit.contain,
    filterQuality: FilterQuality.none,
    errorBuilder: (_, __, ___) => const SizedBox(),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final Color border;
  const _Pill(
      {required this.label,
      required this.color,
      required this.textColor,
      required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 2),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: GoogleFonts.poppins(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
            color: textColor),
      ),
    );
  }
}

// ─── THE PAGES ───────────────────────────────────────────────────────────────

BoxDecoration _paper({required bool left}) => BoxDecoration(
      color: const Color(0xFFF3E4BF),
      borderRadius: BorderRadius.horizontal(
        left: Radius.circular(left ? 10 : 0),
        right: Radius.circular(left ? 0 : 10),
      ),
      gradient: LinearGradient(
        begin: left ? Alignment.centerLeft : Alignment.centerRight,
        end: left ? Alignment.centerRight : Alignment.centerLeft,
        colors: const [Color(0xFFF3E4BF), Color(0xFFF3E4BF), Color(0xFFD9C08A)],
        stops: const [0, 0.78, 1],
      ),
    );

class _LeftPage extends StatelessWidget {
  final EraData era;
  final int number;
  final Color color;
  const _LeftPage(
      {required this.era, required this.number, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _paper(left: true),
      padding: const EdgeInsets.fromLTRB(18, 18, 22, 14),
      child: Center(
          child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                  width: 196,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('KABANATA $number',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.4,
                              color: const Color(0xFF7A5C34))),
                      const SizedBox(height: 8),
                      Container(
                        width: 96,
                        height: 96,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border:
                                Border.all(color: AppColors.accent, width: 4)),
                        child: _eraMedalPicture(era),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        era.name,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 17,
                            height: 1.2,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3B2812)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        eraBlurb(era.id),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            height: 1.4,
                            color: const Color(0xFF7A5C34)),
                      ),
                    ],
                  )))),
    );
  }
}

class _RightPage extends StatelessWidget {
  final EraData era;
  final Color color;
  final EraProgress progress;
  final VoidCallback? onPlay;
  final Key? playKey;
  final Key? progressKey;
  const _RightPage({
    required this.era,
    required this.color,
    required this.progress,
    required this.onPlay,
    required this.playKey,
    required this.progressKey,
  });

  @override
  Widget build(BuildContext context) {
    final levels = era.levels.length;
    final done = progress.isCompleted;
    final filled =
        done ? levels : progress.levelsCompleted.clamp(0, levels).toInt();
    final next = (filled + 1).clamp(1, levels);
    final pct =
        done ? 100 : (levels == 0 ? 0 : (filled / levels * 100).round());
    const ink = Color(0xFF3B2812);
    return Container(
      decoration: _paper(left: false),
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
      child: Center(
          child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                  width: 200,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('PROGRESO',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.4,
                              color: const Color(0xFF7A5C34))),
                      Text('$pct%',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 38,
                              height: 1.1,
                              fontWeight: FontWeight.bold,
                              color: color)),
                      const SizedBox(height: 4),
                      Container(
                        key: progressKey,
                        height: 10,
                        decoration: BoxDecoration(
                          color: ink.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: levels == 0 ? 0 : filled / levels,
                          heightFactor: 1,
                          child: ColoredBox(
                              color: done ? AppColors.accent : color),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        done
                            ? 'Tapos na · $levels ng $levels level'
                            : 'Level $next na ang susunod · $filled ng $levels',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            height: 1.3,
                            color: const Color(0xFF7A5C34)),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onPlay,
                        child: Container(
                          key: playKey,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.primaryDark, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                  color: AppColors.primaryDark,
                                  offset: Offset(0, 3))
                            ],
                          ),
                          child: Text(
                            done ? 'BALIKAN' : 'MAGLARO',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: AppColors.primaryDark),
                          ),
                        ),
                      ),
                    ],
                  )))),
    );
  }
}

// ─── THE CHAINS ──────────────────────────────────────────────────────────────

/// Two bands of chain across the cover and a padlock where they cross. While [charge] runs
/// they shake and the padlock glows; while [burst] runs the padlock opens, every link flies
/// off its own way, and sparks and rings go out from the lock.
class _ChainsPainter extends CustomPainter {
  final double charge;
  final double burst;
  final int seed;
  const _ChainsPainter(
      {required this.charge, required this.burst, required this.seed});

  static const int _across = 13;
  static const int _down = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final bt = burst * BookChainFx.burstSeconds; // seconds into the burst
    final center = Offset(size.width / 2, size.height / 2);
    canvas.save();
    // The strain: everything trembles.
    if (charge > 0 && burst == 0) {
      final k = charge * charge;
      canvas.translate(
          math.sin(charge * 220) * 1.4 * k, math.cos(charge * 190) * 0.9 * k);
    }

    // Links.
    void link(Offset at, bool horizontal, bool narrow, double delay, double dx,
        double up, double dy, double rot) {
      var o = at;
      var angle = 0.0;
      var alpha = 1.0;
      if (bt > 0) {
        final lt = ((bt - 0.3 - delay) / 1.2);
        if (lt >= 1) return;
        if (lt > 0) {
          final y = lt < 0.25
              ? up * (lt / 0.25)
              : up + (dy - up) * Curves.easeIn.transform((lt - 0.25) / 0.75);
          o = at + Offset(dx * lt, y);
          angle = rot * lt;
          alpha = lt < 0.8 ? 1 : 1 - (lt - 0.8) / 0.2;
        }
      }
      final w = (horizontal ? (narrow ? 15.0 : 18.0) : (narrow ? 10.0 : 12.0));
      final h = (horizontal ? (narrow ? 10.0 : 12.0) : (narrow ? 15.0 : 18.0));
      canvas.save();
      canvas.translate(o.dx, o.dy);
      canvas.rotate(angle);
      final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(6));
      canvas.drawRRect(r.shift(const Offset(0, 2)),
          Paint()..color = Colors.black.withValues(alpha: 0.4 * alpha));
      canvas.drawRRect(
          r.deflate(1.6),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.4
            ..color = const Color(0xFFB9BFDC).withValues(alpha: alpha));
      canvas.drawRRect(
          r.deflate(0.2),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9
            ..color = const Color(0xFF4A4F78).withValues(alpha: alpha));
      canvas.restore();
    }

    for (var k = 0; k < _across; k++) {
      final off = k - (_across - 1) / 2;
      link(
        Offset(-4 + (size.width + 8) * k / (_across - 1), size.height / 2),
        true,
        k.isOdd,
        off.abs() * 0.035 + rnd.nextDouble() * 0.06,
        off * (3 + rnd.nextDouble() * 2) * 7 + (rnd.nextDouble() - .5) * 20,
        -(2 + rnd.nextDouble() * 4) * 7,
        (18 + rnd.nextDouble() * 12) * 7,
        (rnd.nextDouble() - .5) * 9,
      );
    }
    for (var k = 0; k < _down; k++) {
      final off = k - (_down - 1) / 2;
      link(
        Offset(size.width / 2, -4 + (size.height + 8) * k / (_down - 1)),
        false,
        k.isOdd,
        off.abs() * 0.03 + rnd.nextDouble() * 0.06,
        (rnd.nextDouble() - .5) * 14 * 7,
        -(1 + rnd.nextDouble() * 4) * 7,
        (off * 1.2 + 14 + rnd.nextDouble() * 12) * 7,
        (rnd.nextDouble() - .5) * 10,
      );
    }

    // The padlock.
    _lock(canvas, center, bt);

    // Rings and sparks from the lock.
    if (bt > 0) {
      for (final ring in const [
        (0.0, 150.0, 1.0, 6.0),
        (0.18, 105.0, 0.9, 4.0)
      ]) {
        final k = ((bt - ring.$1) / ring.$3).clamp(0.0, 1.0);
        if (k <= 0 || k >= 1) continue;
        canvas.drawCircle(
            center,
            ring.$2 * math.sqrt(k),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = ring.$4 * (1 - k * 0.7)
              ..color = const Color(0xFFFFEEA0).withValues(alpha: 1 - k));
      }
      const cols = [
        Color(0xFFFFE27A),
        Colors.white,
        Color(0xFFFFB23E),
        Color(0xFFFFF3B0)
      ];
      final sr = math.Random(seed + 99);
      for (var i = 0; i < 34; i++) {
        final ang = sr.nextDouble() * math.pi * 2;
        final dist = 60 + sr.nextDouble() * 150;
        final delay = sr.nextDouble() * 0.12;
        final k = ((bt - delay) / 0.95).clamp(0.0, 1.0);
        if (k <= 0 || k >= 1) continue;
        final e = Curves.easeOutCubic.transform(k);
        final p = center +
            Offset(math.cos(ang) * dist * e,
                math.sin(ang) * dist * 0.8 * e + 30 * k * k);
        canvas.drawRect(
            Rect.fromCenter(
                center: p, width: 4 * (1.2 - k), height: 4 * (1.2 - k)),
            Paint()..color = cols[i % 4].withValues(alpha: 1 - k));
      }
      // The flash.
      final fk = (bt / 0.8).clamp(0.0, 1.0);
      if (fk < 1) {
        final a = fk < 0.18 ? fk / 0.18 : 1 - (fk - 0.18) / 0.82;
        canvas.drawCircle(
          center,
          size.width * 0.8,
          Paint()
            ..shader = RadialGradient(colors: [
              const Color(0xFFFFF4BE).withValues(alpha: a.clamp(0.0, 1.0)),
              const Color(0xFFFFD65A)
                  .withValues(alpha: (a * 0.5).clamp(0.0, 1.0)),
              Colors.transparent,
            ], stops: const [
              0,
              0.35,
              0.62
            ]).createShader(
                Rect.fromCircle(center: center, radius: size.width * 0.8)),
        );
      }
    }
    canvas.restore();
  }

  void _lock(Canvas canvas, Offset c, double bt) {
    // The glow while it strains.
    if (charge > 0 && bt == 0) {
      final pulse = 0.5 + 0.5 * math.sin(charge * 60);
      canvas.drawCircle(
        c + const Offset(0, 6),
        26 + 10 * pulse * charge,
        Paint()
          ..color = const Color(0xFFFFD65A)
              .withValues(alpha: (0.25 + 0.5 * charge) * (0.6 + 0.4 * pulse))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
    var bodyOffset = Offset.zero;
    var bodyAngle = 0.0;
    var bodyAlpha = 1.0;
    var shackleOffset = Offset.zero;
    var shackleAngle = 0.0;
    var shackleAlpha = 1.0;
    if (bt > 0) {
      final k = (bt / 1.1).clamp(0.0, 1.0);
      if (k >= 1) return;
      // The body hops, then drops away to the right.
      final by = k < 0.2
          ? -8 * (k / 0.2)
          : -8 + (170 + 8) * Curves.easeIn.transform((k - 0.2) / 0.8);
      bodyOffset = Offset(50 * Curves.easeIn.transform(k), by);
      bodyAngle = 0.1 * math.min(k / 0.2, 1) + 3.5 * Curves.easeIn.transform(k);
      bodyAlpha = k < 0.85 ? 1 : 1 - (k - 0.85) / 0.15;
      // The shackle jumps up and falls away to the left.
      final sy = k < 0.3
          ? -24 * (k / 0.3)
          : -24 + (190) * Curves.easeIn.transform((k - 0.3) / 0.7);
      shackleOffset = Offset(-60 * Curves.easeIn.transform(k), sy);
      shackleAngle = -5.9 * Curves.easeOut.transform(k);
      shackleAlpha = k < 0.85 ? 1 : 1 - (k - 0.85) / 0.15;
    }
    // Shackle.
    canvas.save();
    canvas.translate(c.dx + shackleOffset.dx, c.dy + shackleOffset.dy - 4);
    canvas.rotate(shackleAngle);
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(0, -2), width: 22, height: 26),
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFD6D9EE).withValues(alpha: shackleAlpha),
    );
    canvas.restore();
    // Body.
    canvas.save();
    canvas.translate(c.dx + bodyOffset.dx, c.dy + bodyOffset.dy + 4);
    canvas.rotate(bodyAngle);
    final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 34, height: 26),
        const Radius.circular(5));
    canvas.drawRRect(r.shift(const Offset(0, 3)),
        Paint()..color = Colors.black.withValues(alpha: 0.45 * bodyAlpha));
    canvas.drawRRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFD45A).withValues(alpha: bodyAlpha),
            const Color(0xFFD49A1F).withValues(alpha: bodyAlpha)
          ],
        ).createShader(r.outerRect),
    );
    canvas.drawRRect(
        r.deflate(1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFF78460A).withValues(alpha: 0.5 * bodyAlpha));
    final dark = Paint()
      ..color = const Color(0xFF4A2F05).withValues(alpha: bodyAlpha);
    canvas.drawCircle(const Offset(0, -2), 3.2, dark);
    canvas.drawRect(const Rect.fromLTWH(-1.4, -1, 2.8, 8), dark);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChainsPainter old) =>
      old.charge != charge || old.burst != burst || old.seed != seed;
}
