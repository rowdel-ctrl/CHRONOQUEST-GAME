import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../data/history_full.dart';
import '../../services/audio_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/living_backdrop.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/pixel_icon.dart';
import 'background_history_screen.dart' show eraColorFor;

/// The full background of an era, one chapter (a week or a few weeks of the lesson) at a
/// time. It opens from the "BASAHIN ANG BUONG KWENTO" button on a story card of
/// [BackgroundHistoryScreen] and is never needed to play: nothing waits for it.
///
/// A chapter is the text of the lesson, then its key terms. It counts as read once it has
/// been scrolled to the end (or fits without scrolling); the phone remembers that and the
/// button on the card turns green. Chapters can be changed with the arrows, and the
/// letters made smaller or bigger.
class FullStoryScreen extends StatefulWidget {
  final String eraId;

  /// The chapter to open (0 is the first).
  final int chapter;

  /// Called once when a chapter is read to its end. Null saves it on the phone.
  final void Function(String eraId, int chapter)? onChapterRead;

  /// Whether a chapter was read before. Null asks the phone's storage.
  final bool Function(String eraId, int chapter)? wasRead;

  const FullStoryScreen({
    super.key,
    required this.eraId,
    this.chapter = 0,
    this.onChapterRead,
    this.wasRead,
  });

  /// Text sizes the A- and A+ buttons step through, and the one it opens at.
  static const List<double> sizes = [12, 13.5, 15, 16.5, 18, 20];
  static const int defaultSize = 2;

  static const Key backKey = Key('full_story_back');
  static const Key prevKey = Key('full_story_prev');
  static const Key nextKey = Key('full_story_next');
  static const Key smallerKey = Key('full_story_smaller');
  static const Key largerKey = Key('full_story_larger');
  static const Key scrollKey = Key('full_story_scroll');
  static const Key meterKey = Key('full_story_meter');
  static const Key endKey = Key('full_story_end');
  static const Key titleKey = Key('full_story_title');
  static Key termKey(int i) => ValueKey('full_story_term_$i');

  @override
  State<FullStoryScreen> createState() => _FullStoryScreenState();
}

class _FullStoryScreenState extends State<FullStoryScreen> {
  List<FullChapter>? _chapters;
  late int _index = widget.chapter;
  int _size = FullStoryScreen.defaultSize;
  final ScrollController _scroll = ScrollController();
  double _progress = 0;

  /// The chapters read to the end during this visit.
  final Set<int> _done = {};

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  Future<void> _load() async {
    List<FullChapter> list;
    try {
      list = await HistoryFull.chapters(widget.eraId);
    } catch (_) {
      list = const [];
    }
    if (!mounted) return;
    setState(() {
      _chapters = list;
      _index = list.isEmpty ? 0 : _index.clamp(0, list.length - 1);
    });
    _afterLayout();
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  bool _isRead(int i) {
    if (_done.contains(i)) return true;
    final ask = widget.wasRead;
    if (ask != null) return ask(widget.eraId, i);
    try {
      return StorageService.hasReadChapter(widget.eraId, i);
    } catch (_) {
      return false; // storage not ready: not read yet
    }
  }

  void _markRead(int i) {
    if (_done.contains(i)) return;
    _done.add(i);
    final cb = widget.onChapterRead;
    if (cb != null) {
      cb(widget.eraId, i);
      return;
    }
    try {
      StorageService.markChapterRead(widget.eraId, i);
    } catch (_) {
      // The phone's storage is not ready (a test): the mark just stays for this visit.
    }
  }

  /// After the chapter is on screen: a chapter that fits without scrolling is read.
  void _afterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onScroll();
    });
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final p = max <= 0 ? 1.0 : (_scroll.offset / max).clamp(0.0, 1.0);
    final list = _chapters;
    if (list != null && list.isNotEmpty && p >= 0.98) _markRead(_index);
    if ((p - _progress).abs() > 0.004 || (p >= 0.98) != (_progress >= 0.98)) {
      setState(() => _progress = p);
    }
  }

  void _go(int delta) {
    final list = _chapters;
    if (list == null) return;
    final to = (_index + delta).clamp(0, list.length - 1);
    if (to == _index) return;
    setState(() {
      _index = to;
      _progress = 0;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _afterLayout();
  }

  void _bigger(int delta) {
    final to = (_size + delta).clamp(0, FullStoryScreen.sizes.length - 1);
    if (to == _size) return;
    setState(() => _size = to);
    _afterLayout();
  }

  /// Back to the story card the student came from (or to the era's story if this page was
  /// opened on its own).
  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/background/${widget.eraId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final era = getEraById(widget.eraId);
    final eraColor = eraColorFor(widget.eraId);
    final list = _chapters;
    final wide = MediaQuery.sizeOf(context).width >= 560;

    Widget body;
    if (list == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (list.isEmpty) {
      body = Center(
        child: Text(
          'Wala pang buong kwento para sa panahong ito.',
          style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.surface),
        ),
      );
    } else {
      final chapter = list[_index];
      final read = _isRead(_index);
      final panel = _ChapterPanel(
        chapter: chapter,
        fontSize: FullStoryScreen.sizes[_size],
        controller: _scroll,
        read: read,
      );
      final controls = _Controls(
        index: _index,
        count: list.length,
        progress: read ? 1.0 : _progress,
        read: read,
        canSmaller: _size > 0,
        canLarger: _size < FullStoryScreen.sizes.length - 1,
        onPrev: _index > 0 ? () => _go(-1) : null,
        onNext: _index < list.length - 1 ? () => _go(1) : null,
        onSmaller: () => _bigger(-1),
        onLarger: () => _bigger(1),
        horizontal: !wide,
      );
      body = wide
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: panel),
                  const SizedBox(width: 16),
                  SizedBox(width: 150, child: controls),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  controls,
                  const SizedBox(height: 10),
                  Expanded(child: panel),
                ],
              ),
            );
    }

    return Scaffold(
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
                          key: FullStoryScreen.backKey,
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
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `**bold**` markers become bold spans.
List<TextSpan> _boldSpans(String text, TextStyle base, Color boldColor) {
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

const Color _boldInk = Color(0xFF8A3B12);

// ── The chapter: a parchment panel that scrolls ──────────────────────────────────
class _ChapterPanel extends StatelessWidget {
  final FullChapter chapter;
  final double fontSize;
  final ScrollController controller;
  final bool read;

  const _ChapterPanel({
    required this.chapter,
    required this.fontSize,
    required this.controller,
    required this.read,
  });

  @override
  Widget build(BuildContext context) {
    final body = GoogleFonts.poppins(
      fontSize: fontSize,
      height: 1.55,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    );
    return GamePanel(
      color: AppColors.surface,
      borderWidth: 3,
      shadowOffset: 4,
      borderRadius: 5,
      padding: EdgeInsets.zero,
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        child: SingleChildScrollView(
          key: FullStoryScreen.scrollKey,
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  chapter.label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                chapter.title,
                key: FullStoryScreen.titleKey,
                style: GoogleFonts.poppins(
                  fontSize: fontSize + 2,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              for (final p in chapter.paragraphs) ...[
                Text.rich(TextSpan(children: _boldSpans(p, body, _boldInk))),
                const SizedBox(height: 12),
              ],
              if (chapter.terms.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'MAHAHALAGANG SALITA',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < chapter.terms.length; i++)
                  Container(
                    key: FullStoryScreen.termKey(i),
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: chapter.terms[i].$1,
                            style: body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _boldInk,
                              fontSize: fontSize - 1,
                            ),
                          ),
                          TextSpan(
                            text: ' – ${chapter.terms[i].$2}',
                            style: body.copyWith(fontSize: fontSize - 1),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 10),
              Container(
                key: FullStoryScreen.endKey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: read ? AppColors.success : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primaryDark, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.primaryDark,
                        offset: Offset(0, 3),
                        blurRadius: 0),
                  ],
                ),
                child: Text(
                  read ? 'NABASA NA ✓' : 'DULO NG KWENTO',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: read ? Colors.white : Colors.grey.shade700,
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

// ── The controls: chapter arrows, how much is read, letter size ──────────────────
class _Controls extends StatelessWidget {
  final int index;
  final int count;
  final double progress;
  final bool read;
  final bool canSmaller;
  final bool canLarger;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onSmaller;
  final VoidCallback onLarger;

  /// A row above the panel (a phone held upright) instead of a column beside it.
  final bool horizontal;

  const _Controls({
    required this.index,
    required this.count,
    required this.progress,
    required this.read,
    required this.canSmaller,
    required this.canLarger,
    required this.onPrev,
    required this.onNext,
    required this.onSmaller,
    required this.onLarger,
    required this.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final label = GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: AppColors.accent,
    );
    final stepper = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundButton(
            key: FullStoryScreen.prevKey,
            glyph: '‹',
            tooltip: 'Nakaraang kabanata',
            onTap: onPrev),
        const SizedBox(width: 8),
        Text('${index + 1} NG $count', style: label),
        const SizedBox(width: 8),
        _RoundButton(
            key: FullStoryScreen.nextKey,
            glyph: '›',
            tooltip: 'Susunod na kabanata',
            onTap: onNext),
      ],
    );
    final meter = Column(
      key: FullStoryScreen.meterKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(read ? 'NABASA NA ✓' : 'NABASA ${(progress * 100).round()}%',
            style: label.copyWith(
                color: read ? const Color(0xFF8BE287) : AppColors.accent)),
        const SizedBox(height: 4),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
                color: AppColors.primaryDark.withValues(alpha: 0.7), width: 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: read ? AppColors.success : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
    final sizes = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TextChip(
            key: FullStoryScreen.smallerKey,
            text: 'A-',
            tooltip: 'Paliitin ang letra',
            onTap: canSmaller ? onSmaller : null),
        const SizedBox(width: 8),
        _TextChip(
            key: FullStoryScreen.largerKey,
            text: 'A+',
            tooltip: 'Palakihin ang letra',
            onTap: canLarger ? onLarger : null),
      ],
    );

    if (horizontal) {
      return Row(
        children: [
          stepper,
          const SizedBox(width: 12),
          Expanded(child: meter),
          const SizedBox(width: 12),
          sizes,
        ],
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('KABANATA', style: label),
          const SizedBox(height: 6),
          Center(child: stepper),
          const SizedBox(height: 16),
          meter,
          const SizedBox(height: 16),
          Text('LAKI NG LETRA', style: label),
          const SizedBox(height: 6),
          Center(child: sizes),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final String glyph;
  final String tooltip;
  final VoidCallback? onTap;

  const _RoundButton({
    super.key,
    required this.glyph,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return Semantics(
      button: true,
      enabled: on,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: on
            ? () {
                AudioService().playTap();
                onTap!();
              }
            : null,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? AppColors.accent : const Color(0xFF6A5A46),
            border: Border.all(color: AppColors.primaryDark, width: 2.5),
            boxShadow: on
                ? const [
                    BoxShadow(
                        color: AppColors.primaryDark,
                        offset: Offset(0, 3),
                        blurRadius: 0),
                  ]
                : null,
          ),
          child: Text(
            glyph,
            style: GoogleFonts.poppins(
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w700,
              color: on ? AppColors.primaryDark : const Color(0xFF3A2E52),
            ),
          ),
        ),
      ),
    );
  }
}

class _TextChip extends StatelessWidget {
  final String text;
  final String tooltip;
  final VoidCallback? onTap;

  const _TextChip({
    super.key,
    required this.text,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return Semantics(
      button: true,
      enabled: on,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: on
            ? () {
                AudioService().playTap();
                onTap!();
              }
            : null,
        child: Container(
          width: 44,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.primary : const Color(0xFF4A3A30),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.primaryDark, width: 2.5),
            boxShadow: on
                ? const [
                    BoxShadow(
                        color: AppColors.primaryDark,
                        offset: Offset(0, 3),
                        blurRadius: 0),
                  ]
                : null,
          ),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: on ? AppColors.accent : const Color(0xFF8A7A66),
            ),
          ),
        ),
      ),
    );
  }
}
