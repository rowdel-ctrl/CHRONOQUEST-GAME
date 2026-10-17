import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/pixel_icon.dart';

typedef LeaderboardLoader = Future<LeaderboardBoard> Function(String scope);

/// The class and school rankings: who is on top, and where the student stands.
///
/// Wide (a phone on its side): a card for the student, the top three on a
/// podium, and the rest as a list. The student's own row is gold wherever it
/// is, and pinned under the list when they are below the top 20.
class LeaderboardScreen extends ConsumerStatefulWidget {
  /// Where the rankings come from; tests pass their own.
  final LeaderboardLoader? loader;
  const LeaderboardScreen({super.key, this.loader});

  static const Key refreshKey = Key('leaderboard_refresh');
  static const Key meCardKey = Key('leaderboard_me');
  static Key tabKey(int i) => ValueKey('leaderboard_tab_$i');
  static Key rowKey(int rank) => ValueKey('leaderboard_row_$rank');

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int _tab = 0;
  LeaderboardBoard? _class;
  LeaderboardBoard? _school;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final load = widget.loader ?? ApiService().getLeaderboardBoard;
    try {
      final c = await load('class');
      final s = await load('school');
      if (!mounted) return;
      setState(() {
        _class = c;
        _school = s;
        _loading = false;
      });
    } catch (_) {
      // Never invent rankings: a failed load says so, so a student cannot
      // mistake placeholder names for real classmates.
      if (!mounted) return;
      setState(() {
        _class = null;
        _school = null;
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(authProvider).student;
    final board = _tab == 0 ? _class : _school;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF140E1F), Color(0xFF2A1A3A), Color(0xFF3A2433)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    MenuChip(
                      icon: PixelGlyph.back,
                      tooltip: 'Bumalik',
                      onTap: () => context.pop(),
                    ),
                    const SizedBox(width: 6),
                    if (MediaQuery.sizeOf(context).width >= 560)
                      Flexible(
                        child: Text(
                          'LEADERBOARD',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _Segments(
                          labels: const ['KLASE KO', 'SCHOOL NATIN'],
                          selected: _tab,
                          onSelect: (i) => setState(() => _tab = i),
                        ),
                      ),
                    ),
                    const Spacer(),
                    _RefreshChip(onTap: _loading ? null : _load),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.accent))
                    : _error || board == null
                        ? _Message(
                            title: 'HINDI MA-LOAD',
                            body: 'Walang internet o hindi maabot ang server.',
                            button: 'SUBUKAN ULIT',
                            onButton: _load,
                          )
                        : board.leaders.isEmpty
                            ? const _Message(
                                title: 'WALA PANG PUNTOS',
                                body:
                                    'Maglaro ng isang level para lumabas ka dito.',
                              )
                            : _Board(
                                // A different tab is a different list.
                                key: ValueKey('board_$_tab'),
                                board: board,
                                myId: student?.id,
                                myName: student?.name ?? '',
                                showClass: _tab == 1,
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header pieces ────────────────────────────────────────────────────────────
class _Segments extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  const _Segments({
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black38,
        border: Border.all(color: AppColors.primaryDark, width: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            GestureDetector(
              key: LeaderboardScreen.tabKey(i),
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(i),
              child: Container(
                constraints: const BoxConstraints(minHeight: 36),
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width < 520 ? 7 : 12,
                ),
                color: i == selected ? AppColors.accent : Colors.transparent,
                child: Text(
                  labels[i],
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: i == selected
                        ? AppColors.primaryDark
                        : const Color(0xFFCDBA94),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RefreshChip extends StatelessWidget {
  final VoidCallback? onTap;
  const _RefreshChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'I-refresh',
      child: Semantics(
        button: true,
        label: 'I-refresh',
        child: GestureDetector(
          key: LeaderboardScreen.refreshKey,
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primaryDark, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.primaryDark,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.refresh,
                  size: 22,
                  color: onTap == null ? Colors.white38 : AppColors.accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty and failed states: a title, one line, and an optional button.
class _Message extends StatelessWidget {
  final String title;
  final String body;
  final String? button;
  final VoidCallback? onButton;
  const _Message({
    required this.title,
    required this.body,
    this.button,
    this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.surface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
            ),
            if (button != null) ...[
              const SizedBox(height: 14),
              GameButton(
                label: button!,
                fontSize: 11,
                minHeight: 44,
                onPressed: onButton,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── One ranking ──────────────────────────────────────────────────────────────
const _avatarColors = [
  Color(0xFF3D8FD1),
  Color(0xFF43A83E),
  Color(0xFF9B59B6),
  Color(0xFFE8433A),
  Color(0xFFD4891A),
  Color(0xFF2F8F83),
  Color(0xFF7A5CC0),
  Color(0xFF8A5A2B),
];

Color _colorFor(String name) => _avatarColors[
    name.codeUnits.fold<int>(0, (a, b) => a + b) % _avatarColors.length];

String _initial(String name) =>
    name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

String _grouped(int n) {
  final s = n.toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

/// One person on the list, read from the server's row.
class _Entry {
  final int rank;
  final String id;
  final String name;
  final int score;
  final int level;
  final String classCode;
  final bool isMe;
  const _Entry({
    required this.rank,
    required this.id,
    required this.name,
    required this.score,
    required this.level,
    required this.classCode,
    required this.isMe,
  });

  String sub(bool withClass) {
    final parts = [
      if (level > 0) 'Antas $level',
      if (withClass && classCode.isNotEmpty) classCode,
    ];
    return parts.join(' · ');
  }
}

class _Board extends StatefulWidget {
  final LeaderboardBoard board;
  final String? myId;
  final String myName;
  final bool showClass;
  const _Board({
    super.key,
    required this.board,
    required this.myId,
    required this.myName,
    required this.showClass,
  });

  @override
  State<_Board> createState() => _BoardState();
}

class _BoardState extends State<_Board> {
  late final List<_Entry> _entries;
  final _meRow = GlobalKey();

  @override
  void initState() {
    super.initState();
    _entries = [
      for (var i = 0; i < widget.board.leaders.length; i++)
        _Entry(
          rank: i + 1,
          id: '${widget.board.leaders[i]['_id'] ?? widget.board.leaders[i]['id'] ?? ''}',
          name: widget.board.leaders[i]['name'] as String? ?? '?',
          score: (widget.board.leaders[i]['score'] as num?)?.toInt() ?? 0,
          level:
              (widget.board.leaders[i]['levelReached'] as num?)?.toInt() ?? 0,
          classCode: widget.board.leaders[i]['classCode'] as String? ?? '',
          isMe: widget.myId != null &&
              '${widget.board.leaders[i]['_id'] ?? widget.board.leaders[i]['id'] ?? ''}' ==
                  widget.myId,
        ),
    ];
    // A long list opens on the student's own row.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _meRow.currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(ctx, alignment: 0.5);
      }
    });
  }

  _Entry? get _me {
    for (final e in _entries) {
      if (e.isMe) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    final hasPodium = _entries.length >= 3;
    final rest = hasPodium ? _entries.skip(3).toList() : _entries;
    final myScore = me?.score ?? widget.board.myScore ?? 0;

    final meCard = _MeCard(
      key: LeaderboardScreen.meCardKey,
      name: widget.myName.isNotEmpty ? widget.myName : (me?.name ?? ''),
      level: me?.level ?? 0,
      rank: me?.rank,
      score: myScore,
      above: me == null
          ? (_entries.isEmpty ? null : _entries.last)
          : (me.rank > 1 ? _entries[me.rank - 2] : null),
      inList: me != null,
    );

    final podium = hasPodium
        ? _Podium(first: _entries[0], second: _entries[1], third: _entries[2])
        : null;

    // Below the top 20: pinned under the list.
    final pinned = me == null && widget.myId != null
        ? _Row(
            rank: null,
            entry: _Entry(
              rank: 0,
              id: widget.myId!,
              name: widget.myName,
              score: myScore,
              level: 0,
              classCode: '',
              isMe: true,
            ),
            withClass: false,
          )
        : null;

    final rows = [
      for (final e in rest)
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: _Row(
            key: e.isMe ? _meRow : LeaderboardScreen.rowKey(e.rank),
            rank: e.rank,
            entry: e,
            withClass: widget.showClass,
          ),
        ),
    ];

    return LayoutBuilder(
      builder: (context, box) {
        // Three columns on a roomy phone; on a tighter one the podium moves
        // into the list column; below that everything is one column.
        final threeColumns = box.maxWidth >= 760;
        if (box.maxWidth >= 520) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    width: 196, child: SingleChildScrollView(child: meCard)),
                if (podium != null && threeColumns) ...[
                  const SizedBox(width: 12),
                  SizedBox(width: 252, child: podium),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 4),
                          children: [
                            if (podium != null && !threeColumns) ...[
                              podium,
                              const SizedBox(height: 10),
                            ],
                            ...rows,
                          ],
                        ),
                      ),
                      if (pinned != null) ...[
                        const SizedBox(height: 4),
                        pinned,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        // Narrow: one column.
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              meCard,
              if (podium != null) ...[const SizedBox(height: 12), podium],
              const SizedBox(height: 12),
              ...rows,
              if (pinned != null) pinned,
            ],
          ),
        );
      },
    );
  }
}

// ── "Ikaw": the student's own place ──────────────────────────────────────────
class _MeCard extends StatelessWidget {
  final String name;
  final int level;
  final int? rank;
  final int score;
  final _Entry? above;
  final bool inList;
  const _MeCard({
    super.key,
    required this.name,
    required this.level,
    required this.rank,
    required this.score,
    required this.above,
    required this.inList,
  });

  @override
  Widget build(BuildContext context) {
    final small = GoogleFonts.poppins(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: AppColors.textSecondary,
    );
    final gap = above == null ? 0 : above!.score - score;
    final progress = above == null || above!.score <= 0
        ? 1.0
        : (score / above!.score).clamp(0.0, 1.0);

    final String message;
    if (rank == 1) {
      message = 'Ikaw ang nangunguna!';
    } else if (above == null) {
      message = 'Maglaro ng level para umakyat.';
    } else if (!inList) {
      message =
          '${_grouped(gap < 0 ? 0 : gap)} puntos pa para makapasok sa top 20';
    } else {
      message =
          '${_grouped(gap < 0 ? 0 : gap)} puntos na lang para maabot si ${above!.name} (#${above!.rank})';
    }

    return GamePanel(
      color: AppColors.surface,
      borderWidth: 3,
      shadowOffset: 4,
      borderRadius: 4,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('IKAW', style: small),
          const SizedBox(height: 6),
          Row(
            children: [
              _Avatar(name: name, size: 38),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (level > 0)
                      Text(
                        'Antas $level',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          height: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '#',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextSpan(
                  text: rank?.toString() ?? '20+',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              border: Border.all(color: AppColors.primaryDark, width: 2),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress,
              child: Container(color: AppColors.success),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.3,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text('${_grouped(score)} PUNTOS', style: small),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  const _Avatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _colorFor(name),
        border:
            Border.all(color: AppColors.primaryDark, width: size < 32 ? 2 : 3),
      ),
      child: Text(
        _initial(name),
        style: GoogleFonts.poppins(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          height: 1,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Top three ────────────────────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final _Entry first;
  final _Entry second;
  final _Entry third;
  const _Podium(
      {required this.first, required this.second, required this.third});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Column(entry: second, height: 64, color: const Color(0xFFB0BEC5)),
        const SizedBox(width: 6),
        _Column(entry: first, height: 98, color: AppColors.accent, crown: true),
        const SizedBox(width: 6),
        _Column(entry: third, height: 44, color: const Color(0xFFCD7F32)),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  final _Entry entry;
  final double height;
  final Color color;
  final bool crown;
  const _Column({
    required this.entry,
    required this.height,
    required this.color,
    this.crown = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (crown)
            const PixelIcon(PixelGlyph.trophy,
                size: 18, color: AppColors.accent)
          else
            const SizedBox(height: 18),
          const SizedBox(height: 2),
          Container(
            decoration: entry.isMe
                ? BoxDecoration(
                    border: Border.all(color: AppColors.accent, width: 2),
                  )
                : null,
            padding: entry.isMe ? const EdgeInsets.all(1) : EdgeInsets.zero,
            child: _Avatar(name: entry.name, size: 30),
          ),
          const SizedBox(height: 3),
          Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: Colors.white,
            ),
          ),
          Text(
            _grouped(entry.score),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: double.infinity,
            height: height,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: color,
              border: const Border(
                top: BorderSide(color: AppColors.primaryDark, width: 3),
                left: BorderSide(color: AppColors.primaryDark, width: 3),
                right: BorderSide(color: AppColors.primaryDark, width: 3),
              ),
            ),
            child: Text(
              '${entry.rank}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── One row of the list ──────────────────────────────────────────────────────
class _Row extends StatelessWidget {
  /// Null for the pinned row of a student below the top 20.
  final int? rank;
  final _Entry entry;
  final bool withClass;
  const _Row(
      {super.key,
      required this.rank,
      required this.entry,
      required this.withClass});

  @override
  Widget build(BuildContext context) {
    final me = entry.isMe;
    final ink = me ? AppColors.primaryDark : Colors.white;
    final soft = me ? AppColors.primaryDark : const Color(0xFFCDBA94);
    final sub = entry.sub(withClass);

    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
      decoration: BoxDecoration(
        color: me ? AppColors.accent : Colors.black.withValues(alpha: 0.25),
        border: Border.all(
          color: me ? AppColors.primaryDark : Colors.black38,
          width: 2,
        ),
        boxShadow: me
            ? const [
                BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 3))
              ]
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              rank?.toString() ?? '20+',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: soft,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _Avatar(name: entry.name, size: 26),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  me ? '${entry.name} (ikaw)' : entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: ink,
                  ),
                ),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 11, height: 1.2, color: soft),
                  ),
              ],
            ),
          ),
          Text(
            _grouped(entry.score),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: me ? AppColors.primaryDark : AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
