import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../core/test_mode.dart';
import '../../data/history_full.dart';
import '../../services/audio_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/living_backdrop.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/pixel_icon.dart';
import 'background_history_screen.dart' show eraColorFor;
import 'full_story_screen.dart' show FullStoryScreen;

/// The lesson card: the lesson of one level, read before the level starts.
///
/// A level's weeks are exactly one chapter of the era's full story (level 3 of Spanish is
/// weeks 6-7, chapter "6-7"), so the card shows that chapter and nothing else: its title, its
/// text and its key terms. It is required: START stays locked until the reading time is up
/// AND the text has been read to its end, so flicking to the bottom is not enough. The time is
/// [readSeconds] (about 250 words a minute) and only runs while the app is in front.
///
/// Once a lesson has been finished on this phone, replaying the level opens START at once.
/// A level with no lesson text goes straight to the game.
class LessonCardScreen extends StatefulWidget {
  final String eraId;

  /// The level, 1-based. Its lesson is chapter `level - 1` of the era.
  final int level;

  /// Whether the lesson was finished before. Null asks the phone's storage.
  final bool Function(String eraId, int chapter)? wasDone;

  /// Called once when the lesson is finished. Null saves it on the phone.
  final void Function(String eraId, int chapter)? onDone;

  const LessonCardScreen({
    super.key,
    required this.eraId,
    required this.level,
    this.wasDone,
    this.onDone,
  });

  /// Reading speed the time is worked out from, a little faster than a Grade 5-6 student reads.
  static const int wordsPerMinute = 250;
  static const int minSeconds = 20;
  static const int maxSeconds = 150;

  /// Seconds a lesson must be open before it counts as read.
  static int readSeconds(FullChapter chapter) =>
      (chapter.wordCount / wordsPerMinute * 60)
          .ceil()
          .clamp(minSeconds, maxSeconds);

  static const Key backKey = Key('lesson_back');
  static const Key scrollKey = Key('lesson_scroll');
  static const Key titleKey = Key('lesson_title');
  static const Key timerKey = Key('lesson_timer');
  static const Key meterKey = Key('lesson_meter');
  static const Key smallerKey = Key('lesson_smaller');
  static const Key largerKey = Key('lesson_larger');
  static const Key startKey = Key('lesson_start');
  static const Key noteKey = Key('lesson_note');
  static const Key endKey = Key('lesson_end');

  @override
  State<LessonCardScreen> createState() => _LessonCardScreenState();
}

class _LessonCardScreenState extends State<LessonCardScreen>
    with WidgetsBindingObserver {
  FullChapter? _chapter;
  bool _skipped = false;
  int _size = FullStoryScreen.defaultSize;
  final ScrollController _scroll = ScrollController();
  double _progress = 0;
  int _total = 0;
  int _left = 0;
  bool _wasDone = false;

  /// Test Mode: no reading time and no reading to the end, and nothing is saved.
  bool _testMode = false;
  bool _saved = false;
  bool _inFront = true;
  Timer? _ticker;

  int get _index => widget.level - 1;

  @override
  void initState() {
    super.initState();
    // Silent while reading: the lobby music stops here and comes back on the level map.
    Future<void>.microtask(() => AudioService().stopBgm());
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inFront = state == AppLifecycleState.resumed;
  }

  Future<void> _load() async {
    List<FullChapter> list;
    try {
      list = await HistoryFull.chapters(widget.eraId);
    } catch (_) {
      list = const [];
    }
    if (!mounted) return;
    if (_index < 0 ||
        _index >= list.length ||
        list[_index].paragraphs.isEmpty) {
      _goToGame();
      return;
    }
    final chapter = list[_index];
    setState(() {
      _chapter = chapter;
      _total = LessonCardScreen.readSeconds(chapter);
      _testMode = TestMode.on;
      _wasDone = _isDone();
      _left = _wasDone || _testMode ? 0 : _total;
    });
    if (_left > 0) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
    _afterLayout();
  }

  bool _isDone() {
    final ask = widget.wasDone;
    if (ask != null) return ask(widget.eraId, _index);
    try {
      return StorageService.hasDoneLesson(widget.eraId, _index);
    } catch (_) {
      return false; // storage not ready: not done yet
    }
  }

  void _tick() {
    if (!mounted || !_inFront) return;
    if (_left > 0) setState(() => _left--);
    if (_left <= 0) {
      _ticker?.cancel();
      _saveIfDone();
    }
  }

  /// A chapter that fits without scrolling counts as read to its end.
  void _afterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onScroll();
    });
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final p = max <= 0 ? 1.0 : (_scroll.offset / max).clamp(0.0, 1.0);
    if ((p - _progress).abs() > 0.004 || (p >= 0.98) != (_progress >= 0.98)) {
      setState(() => _progress = p);
    }
    _saveIfDone();
  }

  bool get _atEnd => _progress >= 0.98;
  bool get _timeUp => _left <= 0;
  bool get _ready => _wasDone || _testMode || (_timeUp && _atEnd);

  void _saveIfDone() {
    if (_saved || _wasDone || _testMode || !_timeUp || !_atEnd) return;
    _saved = true;
    final cb = widget.onDone;
    if (cb != null) {
      cb(widget.eraId, _index);
      return;
    }
    try {
      StorageService.markLessonDone(widget.eraId, _index);
    } catch (_) {
      // The phone's storage is not ready (a test): the mark just stays for this visit.
    }
  }

  void _bigger(int delta) {
    final to = (_size + delta).clamp(0, FullStoryScreen.sizes.length - 1);
    if (to == _size) return;
    setState(() => _size = to);
    _afterLayout();
  }

  void _goToGame() {
    if (_skipped) return;
    _skipped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/game/${widget.eraId}/${widget.level}');
    });
  }

  void _back() => context.go('/level-select/${widget.eraId}');

  String get _note {
    if (_ready) return 'Handa ka na!';
    if (!_timeUp && _atEnd) return 'Hintayin ang oras';
    if (_timeUp && !_atEnd) return 'Ibaba pa hanggang dulo';
    return 'Basahin muna ang aralin';
  }

  @override
  Widget build(BuildContext context) {
    final era = getEraById(widget.eraId);
    final eraColor = eraColorFor(widget.eraId);
    final wide = MediaQuery.sizeOf(context).width >= 560;
    final chapter = _chapter;

    Widget body;
    if (chapter == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final panel = _LessonPanel(
        chapter: chapter,
        fontSize: FullStoryScreen.sizes[_size],
        controller: _scroll,
        ready: _ready,
      );
      final timer = _Timer(left: _left, total: _total, done: _timeUp);
      final meter = _Meter(progress: _wasDone ? 1.0 : _progress, ready: _ready);
      final sizes = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TextChip(
              key: LessonCardScreen.smallerKey,
              text: 'A-',
              tooltip: 'Paliitin ang letra',
              onTap: _size > 0 ? () => _bigger(-1) : null),
          const SizedBox(width: 8),
          _TextChip(
              key: LessonCardScreen.largerKey,
              text: 'A+',
              tooltip: 'Palakihin ang letra',
              onTap: _size < FullStoryScreen.sizes.length - 1
                  ? () => _bigger(1)
                  : null),
        ],
      );
      final label = GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.accent,
      );
      Widget start(String text) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GameButton(
                key: LessonCardScreen.startKey,
                label: text,
                fontSize: 12,
                minHeight: 44,
                icon: _ready ? null : Icons.lock_rounded,
                onPressed: _ready ? () => _goToGame() : null,
              ),
              const SizedBox(height: 4),
              Text(
                _note,
                key: LessonCardScreen.noteKey,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _ready ? const Color(0xFF8BE287) : AppColors.accent,
                ),
              ),
            ],
          );
      body = wide
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: panel),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 150,
                    // Centred when it fits; scrolls on a screen too short for it.
                    child: LayoutBuilder(
                      builder: (context, box) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: box.maxHeight),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              timer,
                              const SizedBox(height: 12),
                              meter,
                              const SizedBox(height: 12),
                              Text('LAKI NG LETRA', style: label),
                              const SizedBox(height: 6),
                              Center(child: sizes),
                              const SizedBox(height: 14),
                              start('SIMULAN!'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: timer),
                      const SizedBox(width: 12),
                      Expanded(child: meter),
                      const SizedBox(width: 12),
                      sizes,
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: panel),
                  const SizedBox(height: 10),
                  start('SIMULAN ANG LEVEL'),
                ],
              ),
            );
    }

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
                            key: LessonCardScreen.backKey,
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

// ── The lesson: a parchment panel that scrolls ───────────────────────────────────
class _LessonPanel extends StatelessWidget {
  final FullChapter chapter;
  final double fontSize;
  final ScrollController controller;
  final bool ready;

  const _LessonPanel({
    required this.chapter,
    required this.fontSize,
    required this.controller,
    required this.ready,
  });

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: AppColors.accent,
          ),
        ),
      );

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
          key: LessonCardScreen.scrollKey,
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tag(chapter.label),
              const SizedBox(height: 8),
              Text(
                chapter.title,
                key: LessonCardScreen.titleKey,
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
                _tag('MAHAHALAGANG SALITA'),
                const SizedBox(height: 8),
                for (final t in chapter.terms)
                  Container(
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
                            text: t.$1,
                            style: body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _boldInk,
                              fontSize: fontSize - 1,
                            ),
                          ),
                          TextSpan(
                            text: ' – ${t.$2}',
                            style: body.copyWith(fontSize: fontSize - 1),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 10),
              Container(
                key: LessonCardScreen.endKey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: ready ? AppColors.success : Colors.grey.shade400,
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
                  ready ? 'NABASA NA ✓' : 'DULO NG KWENTO',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ready ? Colors.white : Colors.grey.shade700,
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

// ── The reading time and how much of the text is read ────────────────────────────
Widget _bar(double fraction, bool done) => Container(
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
            color: AppColors.primaryDark.withValues(alpha: 0.7), width: 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: done ? AppColors.success : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );

TextStyle get _labelStyle => GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: AppColors.accent,
    );

class _Timer extends StatelessWidget {
  final int left;
  final int total;
  final bool done;
  const _Timer({required this.left, required this.total, required this.done});

  @override
  Widget build(BuildContext context) {
    final mmss = '${left ~/ 60}:${(left % 60).toString().padLeft(2, '0')}';
    return Column(
      key: LessonCardScreen.timerKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('ORAS NG PAGBASA', style: _labelStyle),
        const SizedBox(height: 2),
        Text(
          done ? 'TAPOS NA' : mmss,
          style: GoogleFonts.poppins(
            fontSize: done ? 15 : 20,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: done ? const Color(0xFF8BE287) : Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        _bar(total == 0 ? 1 : 1 - left / total, done),
      ],
    );
  }
}

class _Meter extends StatelessWidget {
  final double progress;
  final bool ready;
  const _Meter({required this.progress, required this.ready});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: LessonCardScreen.meterKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ready ? 'NABASA NA ✓' : 'NABASA ${(progress * 100).round()}%',
          style: _labelStyle.copyWith(
              color: ready ? const Color(0xFF8BE287) : AppColors.accent),
        ),
        const SizedBox(height: 4),
        _bar(progress, ready),
      ],
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
        onTap: on ? onTap : null,
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
