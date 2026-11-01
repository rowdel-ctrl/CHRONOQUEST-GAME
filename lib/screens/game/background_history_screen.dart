import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../data/era_story.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/living_backdrop.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/pixel_icon.dart';

/// The era's background before its levels: its story one event at a time (dots
/// to move between them) and three sealed key terms to tap open. The levels open
/// for the next step ("HANDA NA AKO!") once every term has been read.
///
/// The sealed cards glow, shimmer one after another and wobble their seals, and the
/// first one still shut breathes and rings, so it is plain they are to be tapped.
/// The story card has a curling corner and a bouncing arrow, and the next dot rings,
/// so it is plain it can be turned (tap it, tap the arrow, or swipe).
class BackgroundHistoryScreen extends StatefulWidget {
  final String eraId;
  const BackgroundHistoryScreen({super.key, required this.eraId});

  static const Key backButtonKey = Key('background_back_button');
  static const Key readyButtonKey = Key('background_ready_button');
  static const Key beatKey = Key('background_beat');
  static const Key ringKey = Key('background_ring');
  static const Key nextKey = Key('background_next');
  static const Key curlKey = Key('background_curl');
  static Key termKey(int i) => ValueKey('background_term_$i');
  static Key beatDotKey(int i) => ValueKey('background_beat_dot_$i');
  static Key termDotKey(int i) => ValueKey('background_term_dot_$i');

  @override
  State<BackgroundHistoryScreen> createState() =>
      _BackgroundHistoryScreenState();
}

class _BackgroundHistoryScreenState extends State<BackgroundHistoryScreen> {
  final Set<int> _opened = {};
  int _beat = 0;

  /// Back to the era list. The screen is reached with `go`, so there is no
  /// page under it for the phone's own back button to return to.
  void _back() => context.go('/era-selection');

  @override
  Widget build(BuildContext context) {
    final era = getEraById(widget.eraId);
    final eraColor = eraColorFor(widget.eraId);
    final terms = keyTermsFor(widget.eraId);
    final story = eraStories[widget.eraId];
    final beats = story?.beats ?? [StoryBeat('', era.historicalText)];
    final beat = beats[_beat.clamp(0, beats.length - 1)];
    final ready = _opened.length >= terms.length;
    final wide = MediaQuery.sizeOf(context).width >= 560;
    // The first card still shut is the one that breathes and rings.
    final first = [for (var i = 0; i < terms.length; i++) i]
        .where((i) => !_opened.contains(i));
    final pointAt = first.isEmpty ? -1 : first.first;

    final storyCard = _StoryCard(
      beat: beat,
      beatCount: beats.length,
      current: _beat.clamp(0, beats.length - 1),
      onPick: (i) => setState(() => _beat = i),
      onStep: (forward) => setState(() =>
          _beat = (_beat + (forward ? 1 : -1)).clamp(0, beats.length - 1)),
      scrolls: story == null,
    );
    final termCards = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < terms.length; i++) ...[
          if (i > 0) const SizedBox(height: 7),
          _TermCard(
            key: BackgroundHistoryScreen.termKey(i),
            term: terms[i],
            open: _opened.contains(i),
            pointing: i == pointAt,
            order: i,
            onTap: () => setState(() => _opened.add(i)),
          ),
        ],
      ],
    );
    final footer = _Footer(
      done: _opened.length,
      total: terms.length,
      ready: ready,
      onGo: () => context.go('/level-select/${widget.eraId}'),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(const Color(0xFF140E1F), eraColor, 0.6)!,
                const Color(0xFF140E1F),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: LivingBackdrop(
                  color: Color.lerp(eraColor, Colors.white, 0.4)!,
                  fireflies: 0,
                  center:
                      wide ? const Offset(0.27, 0.45) : const Offset(0.5, 0.25),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: Row(
                        children: [
                          MenuChip(
                            key: BackgroundHistoryScreen.backButtonKey,
                            icon: PixelGlyph.back,
                            tooltip: 'Bumalik',
                            onTap: _back,
                          ),
                          Expanded(
                            child: Text(
                              era.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Expanded(
                      child: wide
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 11, child: storyCard),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    flex: 10,
                                    // Centred when it fits; scrolls on a screen too short for it.
                                    child: LayoutBuilder(
                                      builder: (context, box) =>
                                          SingleChildScrollView(
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                              minHeight: box.maxHeight),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              termCards,
                                              const SizedBox(height: 8),
                                              footer,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(height: 230, child: storyCard),
                                  const SizedBox(height: 16),
                                  termCards,
                                  const SizedBox(height: 14),
                                  footer,
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `**bold**` markers in the story text become bold spans.
List<TextSpan> _spans(String text, TextStyle base, Color boldColor) {
  final parts = text.split('**');
  return [
    for (var i = 0; i < parts.length; i++)
      if (parts[i].isNotEmpty)
        TextSpan(
          text: parts[i],
          style: i.isOdd
              ? base.copyWith(fontWeight: FontWeight.w700, color: boldColor)
              : base,
        ),
  ];
}

// ── The story: one event on a parchment card, dots to move between them ─────────
class _StoryCard extends StatefulWidget {
  final StoryBeat beat;
  final int beatCount;
  final int current;
  final ValueChanged<int> onPick;

  /// One step on: true for the next event, false for the one before.
  final ValueChanged<bool> onStep;

  /// The whole paragraph on one card (an era with no cut-up story): it scrolls.
  final bool scrolls;

  const _StoryCard({
    required this.beat,
    required this.beatCount,
    required this.current,
    required this.onPick,
    required this.onStep,
    required this.scrolls,
  });

  @override
  State<_StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<_StoryCard> with TickerProviderStateMixin {
  /// The corner curls and the arrow bounces on this one loop.
  late final AnimationController _hint = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));

  /// A ring spreads from the next dot.
  late final AnimationController _ring = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionAllowed(context)) {
      if (!_hint.isAnimating) _hint.repeat(reverse: true);
      if (!_ring.isAnimating) _ring.repeat();
    } else {
      _hint.stop();
      _hint.value = 0;
      _ring.stop();
      _ring.value = 1;
    }
  }

  @override
  void dispose() {
    _hint.dispose();
    _ring.dispose();
    super.dispose();
  }

  bool get _hasNext => widget.current < widget.beatCount - 1;

  @override
  Widget build(BuildContext context) {
    final beat = widget.beat;
    final body = GoogleFonts.poppins(
      fontSize: 15,
      height: 1.45,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    );
    final text = Text.rich(
      TextSpan(children: _spans(beat.text, body, const Color(0xFF8A3B12))),
    );
    return Column(
      children: [
        Expanded(
          // Tap the card to go on; swipe it either way.
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _hasNext ? () => widget.onStep(true) : null,
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v.abs() > 200) widget.onStep(v < 0);
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: GamePanel(
                    key: BackgroundHistoryScreen.beatKey,
                    color: AppColors.surface,
                    borderWidth: 3,
                    shadowOffset: 4,
                    borderRadius: 5,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: SizedBox.expand(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (beat.label.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                beat.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          if (beat.label.isNotEmpty) const SizedBox(height: 10),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              layoutBuilder: (current, previous) => Stack(
                                alignment: Alignment.topLeft,
                                children: [
                                  ...previous,
                                  if (current != null) current
                                ],
                              ),
                              child: KeyedSubtree(
                                key: ValueKey(beat.text),
                                // Long text shrinks a little rather than being cut off.
                                child: widget.scrolls
                                    ? SingleChildScrollView(child: text)
                                    : FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.topLeft,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              maxWidth: 380),
                                          child: text,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // The corner of the page, curling up: there is more to turn to.
                if (_hasNext)
                  Positioned(
                    right: 3,
                    bottom: 3,
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _hint,
                        builder: (context, _) => Transform.scale(
                          alignment: Alignment.bottomRight,
                          scale:
                              1 + 0.4 * Curves.easeInOut.transform(_hint.value),
                          child: CustomPaint(
                            key: BackgroundHistoryScreen.curlKey,
                            size: const Size(30, 30),
                            painter: _CurlPainter(),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.beatCount > 1) ...[
          const SizedBox(height: 6),
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.beatCount; i++)
                    _BeatDot(
                      key: BackgroundHistoryScreen.beatDotKey(i),
                      on: i == widget.current,
                      ring: i == widget.current + 1 ? _ring : null,
                      label: '${i + 1} ng ${widget.beatCount}',
                      onTap: () => widget.onPick(i),
                    ),
                ],
              ),
              // A round arrow beside the dots that bounces the way it points.
              if (_hasNext)
                Align(
                  alignment: Alignment.centerRight,
                  child: Semantics(
                    button: true,
                    label: 'Susunod na pangyayari',
                    child: GestureDetector(
                      key: BackgroundHistoryScreen.nextKey,
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onStep(true),
                      child: SizedBox(
                        width: 48,
                        height: 32,
                        child: AnimatedBuilder(
                          animation: _hint,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(
                                4 * Curves.easeInOut.transform(_hint.value), 0),
                            child: child,
                          ),
                          child: Center(
                            child: Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent,
                                border: Border.all(
                                    color: AppColors.primaryDark, width: 2.5),
                                boxShadow: const [
                                  BoxShadow(
                                      color: AppColors.primaryDark,
                                      offset: Offset(0, 2)),
                                ],
                              ),
                              child: const PixelIcon(PixelGlyph.chevron,
                                  size: 16, color: AppColors.primaryDark),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The turned-up corner of a page: a light triangle with a soft shadow.
class _CurlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fold = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fold.shift(const Offset(-1.5, -1.5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawPath(
      fold,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9D6A6), Color(0xFFB8995F)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_CurlPainter old) => false;
}

/// One dot of the timeline: 40 square to hit, a small gold light to look at.
class _BeatDot extends StatelessWidget {
  final bool on;
  final String label;
  final VoidCallback onTap;

  /// The next one to go to: a ring spreads from it. Null for every other dot.
  final Animation<double>? ring;
  const _BeatDot(
      {super.key,
      required this.on,
      required this.label,
      required this.onTap,
      this.ring});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 32,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (ring != null)
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: ring!,
                      builder: (context, _) => Opacity(
                        opacity: 0.9 * (1 - ring!.value),
                        child: Container(
                          width: 15 * (0.9 + 0.9 * ring!.value) + 6,
                          height: 15 * (0.9 + 0.9 * ring!.value) + 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.accent, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: on ? 20 : 15,
                  height: on ? 20 : 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on ? AppColors.accent : const Color(0xFF3A2E52),
                    border: Border.all(color: AppColors.primaryDark, width: 3),
                    boxShadow: on
                        ? [
                            BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.7),
                                blurRadius: 10)
                          ]
                        : null,
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

// ── A sealed key term ──────────────────────────────────────────────────────────
/// Shut: dark wood with a glowing gold edge, a wobbling red seal and the term in
/// gold, with a band of light sweeping across it (one card after another). The
/// first one shut also breathes and sends a ring out from its seal. Tapped: it
/// flips open to parchment with the meaning, and the seal turns green.
class _TermCard extends StatefulWidget {
  final Map<String, String> term;
  final bool open;
  final bool pointing;

  /// Its place in the list, so the light sweeps over the cards in turn.
  final int order;
  final VoidCallback onTap;
  const _TermCard({
    super.key,
    required this.term,
    required this.open,
    required this.pointing,
    required this.order,
    required this.onTap,
  });

  @override
  State<_TermCard> createState() => _TermCardState();
}

class _TermCardState extends State<_TermCard> with TickerProviderStateMixin {
  /// One loop drives the glow, the seal and the breathing: a breath every 1.6 s.
  late final AnimationController _loop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));

  /// The band of light: once every 2.8 s, started a little later on each card.
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
    value: (widget.order * 0.22) % 1,
  );

  /// The ring that spreads from the seal of the card to open next.
  late final AnimationController _ring = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300));

  /// The flip when it opens.
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: widget.open ? 1 : 0,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_TermCard old) {
    super.didUpdateWidget(old);
    if (widget.open && !old.open) {
      if (motionAllowed(context)) {
        _flip.forward(from: 0);
      } else {
        _flip.value = 1;
      }
    }
    _sync();
  }

  void _sync() {
    final shouldMove = !widget.open && motionAllowed(context);
    if (shouldMove && !_loop.isAnimating) {
      _loop.repeat(reverse: true);
      _shimmer.repeat();
    } else if (!shouldMove && _loop.isAnimating) {
      _loop.stop();
      _shimmer.stop();
    }
    final ring = shouldMove && widget.pointing;
    if (ring && !_ring.isAnimating) {
      _ring.repeat();
    } else if (!ring && _ring.isAnimating) {
      _ring.stop();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _shimmer.dispose();
    _ring.dispose();
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final term = widget.term;
    return Semantics(
      button: !widget.open,
      label: widget.open
          ? '${term['term']}: ${term['def']}'
          : 'Buksan ang ${term['term']}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.open ? null : widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_loop, _flip, _shimmer, _ring]),
          builder: (context, _) {
            // Flipping: the card turns edge-on showing its shut face, then comes
            // back showing the open one. Resting, the angle is 0.
            final v = _flip.value;
            final open = widget.open && v >= 0.5;
            final angle = (v < 0.5 ? v * 2 : (1 - v) * 2) * (math.pi / 2);
            final breath = Curves.easeInOut.transform(_loop.value);
            // The card to open next breathes a little.
            final scale = widget.pointing && !open ? 1 + 0.02 * breath : 1.0;
            return Transform.scale(
              scale: scale,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateX(angle),
                child: Container(
                  // Tall enough for the meaning, so opening a card does not move the others.
                  constraints: const BoxConstraints(minHeight: 62),
                  decoration: BoxDecoration(
                    color: open ? AppColors.surface : null,
                    gradient: open
                        ? null
                        : const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF5B2F18), Color(0xFF3A1D0E)],
                          ),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: AppColors.primaryDark, width: 2.5),
                    boxShadow: [
                      if (!open)
                        BoxShadow(
                          color:
                              AppColors.accent.withValues(alpha: 0.6 * breath),
                          blurRadius: 16 * breath,
                          spreadRadius: 3 * breath,
                        ),
                      const BoxShadow(
                          color: AppColors.primaryDark, offset: Offset(0, 3)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3.5),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              _seal(open, breath),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      open
                                          ? term['term']!
                                          : term['term']!.toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        fontSize: open ? 13 : 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: open ? 0 : 0.5,
                                        height: 1.2,
                                        color: open
                                            ? AppColors.primaryDark
                                            : AppColors.accent,
                                      ),
                                    ),
                                    if (open)
                                      Text(
                                        term['def']!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          height: 1.25,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!open) _shimmerBand(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// The red seal (green with a tick once open). On the card to open next a ring
  /// spreads out from it.
  Widget _seal(bool open, double breath) {
    final seal = Transform.rotate(
      angle: open ? 0 : (breath - 0.5) * 0.3,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: open ? AppColors.success : AppColors.danger,
          border: Border.all(color: AppColors.primaryDark, width: 2.5),
        ),
        child: open
            ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
            : Text(
                '?',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFE98A),
                  height: 1.1,
                ),
              ),
      ),
    );
    if (open || !widget.pointing) return seal;
    final t = _ring.value;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        IgnorePointer(
          child: Opacity(
            opacity: 0.9 * (1 - t),
            child: Container(
              key: BackgroundHistoryScreen.ringKey,
              width: 28 * (0.8 + 0.9 * t),
              height: 28 * (0.8 + 0.9 * t),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFE98A), width: 2.5),
              ),
            ),
          ),
        ),
        seal,
      ],
    );
  }

  /// A slanted band of light that crosses the card in the first part of each
  /// cycle and then rests.
  Widget _shimmerBand() {
    final p = (_shimmer.value / 0.6).clamp(0.0, 1.0);
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment(-1.6 + 3.2 * p, 0),
          child: Transform(
            transform: Matrix4.skewX(-0.3),
            child: Container(
              width: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: p > 0 && p < 1 ? 0.3 : 0),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Footer: three dots, one per term, and the button ───────────────────────────
class _Footer extends StatelessWidget {
  final int done;
  final int total;
  final bool ready;
  final VoidCallback onGo;
  const _Footer(
      {required this.done,
      required this.total,
      required this.ready,
      required this.onGo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          _TermDot(key: BackgroundHistoryScreen.termDotKey(i), full: i < done),
        ],
        const SizedBox(width: 14),
        Expanded(
          child: GameButton(
            key: BackgroundHistoryScreen.readyButtonKey,
            label: 'HANDA NA AKO!',
            fontSize: 12,
            minHeight: 44,
            onPressed: ready ? onGo : null,
          ),
        ),
      ],
    );
  }
}

/// A dot that fills with a pop when its term is opened.
class _TermDot extends StatelessWidget {
  final bool full;
  const _TermDot({super.key, required this.full});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: full ? 1 : 0),
      duration: motionAllowed(context)
          ? const Duration(milliseconds: 350)
          : Duration.zero,
      curve: Curves.elasticOut,
      builder: (context, t, _) => Transform.scale(
        scale: 1 + 0.25 * (t > 1 ? t - 1 : 0),
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: full ? AppColors.accent : const Color(0xFF3A2E52),
            border: Border.all(color: AppColors.primaryDark, width: 2.5),
          ),
        ),
      ),
    );
  }
}

// ── Era data ─────────────────────────────────────────────────────────────────
Color eraColorFor(String id) {
  switch (id) {
    case 'pre-colonial':
      return const Color(0xFF1B5E20);
    case 'spanish':
      return const Color(0xFF4E342E);
    case 'nationalism':
      return const Color(0xFF4E342E);
    case 'american':
      return const Color(0xFF0D47A1);
    case 'ww2':
      return const Color(0xFF37474F);
    case 'modern':
      return const Color(0xFF1A237E);
    default:
      return const Color(0xFF4E342E);
  }
}

List<Map<String, String>> keyTermsFor(String eraId) {
  switch (eraId) {
    case 'pre-colonial':
      return [
        {
          'term': 'Barangay',
          'icon': '🏘️',
          'def': 'Maliit na komunidad na pinamumunuan ng datu'
        },
        {
          'term': 'Baybayin',
          'icon': '✍️',
          'def': 'Sistema ng pagsulat ng sinaunang Pilipino'
        },
        {'term': 'Datu', 'icon': '👑', 'def': 'Pinuno ng barangay'},
      ];
    case 'spanish':
      return [
        {
          'term': 'Encomienda',
          'icon': '🏰',
          'def': 'Sistema ng pagbibigay ng lupain sa mga Espanyol'
        },
        {
          'term': 'Katipunan',
          'icon': '⚔️',
          'def': 'Lihim na samahan laban sa Espanya'
        },
        {
          'term': 'Himagsikan',
          'icon': '🔥',
          'def': 'Rebolusyon ng mga Pilipino'
        },
      ];
    case 'nationalism':
      return [
        {
          'term': 'Propaganda Movement',
          'icon': '📰',
          'def': 'Kampanya ng mga ilustrado para sa reporma sa Espanya'
        },
        {
          'term': 'La Liga Filipina',
          'icon': '🤝',
          'def': 'Samahang itinatag ni Rizal noong 1892'
        },
        {
          'term': 'GOMBURZA',
          'icon': '✝️',
          'def': 'Tatlong paring pinatay noong 1872, sagisag ng paglaban'
        },
      ];
    case 'american':
      return [
        {
          'term': 'Thomasites',
          'icon': '📚',
          'def': 'Mga gurong Amerikano na dumating sa Pilipinas'
        },
        {
          'term': 'Commonwealth',
          'icon': '🏛️',
          'def': 'Pamahalaan bago ang ganap na kalayaan'
        },
        {
          'term': 'Malolos',
          'icon': '📜',
          'def': 'Lugar kung saan itinatag ang unang republika'
        },
      ];
    case 'ww2':
      return [
        {
          'term': 'Bataan Death March',
          'icon': '⚠️',
          'def': 'Malupit na martsa ng mga bihag ng Hapon'
        },
        {
          'term': 'Gerilya',
          'icon': '🌿',
          'def': 'Mga lihim na mandirigma laban sa Hapon'
        },
        {
          'term': 'Liberation',
          'icon': '🕊️',
          'def': 'Pagpapalaya ng Pilipinas'
        },
      ];
    case 'modern':
      return [
        {
          'term': 'EDSA Revolution',
          'icon': '✊',
          'def': 'People Power na nagpabagsak sa diktadura'
        },
        {
          'term': 'Martial Law',
          'icon': '⛓️',
          'def': 'Batas militar na idineklara ni Marcos'
        },
        {'term': 'Demokrasya', 'icon': '🗳️', 'def': 'Pamahalaan ng mamamayan'},
      ];
    default:
      return [];
  }
}
