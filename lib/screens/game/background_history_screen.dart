import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../data/era_story.dart';
import '../../services/storage_service.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/pixel_icon.dart';

/// The era's background before its levels: a short story cut into events, a
/// timeline, and three key terms to tap open. The levels unlock for the next
/// step ("HANDA NA AKO!") once every term has been read.
class BackgroundHistoryScreen extends StatefulWidget {
  final String eraId;
  const BackgroundHistoryScreen({super.key, required this.eraId});

  static const Key backButtonKey = Key('background_back_button');
  static const Key readyButtonKey = Key('background_ready_button');
  static Key termKey(int i) => ValueKey('background_term_$i');

  @override
  State<BackgroundHistoryScreen> createState() =>
      _BackgroundHistoryScreenState();
}

class _BackgroundHistoryScreenState extends State<BackgroundHistoryScreen> {
  final Set<int> _opened = {};

  /// Back to the era list. The screen is reached with `go`, so there is no
  /// page under it for the phone's own back button to return to.
  void _back() => context.go('/era-selection');

  @override
  Widget build(BuildContext context) {
    final era = getEraById(widget.eraId);
    final eraColor = eraColorFor(widget.eraId);
    final terms = keyTermsFor(widget.eraId);
    final story = eraStories[widget.eraId];
    final character = getCharacterById(StorageService.getCharacter());
    final eraNumber = allEras.indexWhere((e) => e.id == era.id) + 1;
    final left = terms.length - _opened.length;
    final ready = left <= 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
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
            child: Row(
              children: [
                _Sidebar(
                  era: era,
                  eraColor: eraColor,
                  eraNumber: eraNumber,
                  characterId: character.id,
                  line: ready
                      ? 'Magaling! Handa ka na ba?'
                      : 'Ako si ${character.name}. Samahan mo ako!',
                  onBack: _back,
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          _Progress(done: _opened.length, total: terms.length),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 96),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (story != null) ...[
                                    for (final beat in story.beats) ...[
                                      _BeatCard(beat: beat),
                                      const SizedBox(height: 8),
                                    ],
                                    const SizedBox(height: 4),
                                    _Timeline(nodes: story.timeline),
                                    const SizedBox(height: 16),
                                  ] else ...[
                                    _BeatCard(
                                        beat:
                                            StoryBeat('', era.historicalText)),
                                    const SizedBox(height: 16),
                                  ],
                                  Text(
                                    'MGA MAHAHALAGANG TERMINO  ·  itapik ang kard',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (var i = 0;
                                          i < terms.length;
                                          i++) ...[
                                        if (i > 0) const SizedBox(width: 8),
                                        Expanded(
                                          child: _TermCard(
                                            key:
                                                BackgroundHistoryScreen.termKey(
                                                    i),
                                            term: terms[i],
                                            open: _opened.contains(i),
                                            onTap: () =>
                                                setState(() => _opened.add(i)),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _BottomBar(
                          ready: ready,
                          left: left,
                          onTap: () =>
                              context.go('/level-select/${widget.eraId}'),
                        ),
                      ),
                    ],
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

// ── Left column: the era's name, and the hero speaking ───────────────────────
class _Sidebar extends StatelessWidget {
  final EraData era;
  final Color eraColor;
  final int eraNumber;
  final String characterId;
  final String line;
  final VoidCallback onBack;
  const _Sidebar({
    required this.era,
    required this.eraColor,
    required this.eraNumber,
    required this.characterId,
    required this.line,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width * 0.28).clamp(190.0, 250.0);
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [eraColor, Color.lerp(eraColor, Colors.black, 0.6)!],
        ),
        border: const Border(
          right: BorderSide(color: AppColors.primaryDark, width: 3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MenuChip(
            key: BackgroundHistoryScreen.backButtonKey,
            icon: PixelGlyph.back,
            tooltip: 'Bumalik',
            onTap: onBack,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PANAHON $eraNumber NG ${allEras.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: const Color(0xFFE9D3A3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    era.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    era.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.3,
                      color: const Color(0xFFE9D3A3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Image.asset(
                'assets/characters/${characterId}_walk_1.png',
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 48, height: 48),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GamePanel(
                  color: AppColors.surface,
                  borderWidth: 2,
                  shadowOffset: 0,
                  borderRadius: 4,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Text(
                    line,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      height: 1.3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Progress: one segment per key term opened ────────────────────────────────
class _Progress extends StatelessWidget {
  final int done;
  final int total;
  const _Progress({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: i < done ? AppColors.success : Colors.black45,
                  border: Border.all(color: AppColors.primaryDark, width: 2),
                ),
              ),
            ),
          ],
          const SizedBox(width: 10),
          Text(
            '$done NG $total TERMINO',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

// ── One event of the story ───────────────────────────────────────────────────
class _BeatCard extends StatelessWidget {
  final StoryBeat beat;
  const _BeatCard({required this.beat});

  @override
  Widget build(BuildContext context) {
    final body = GoogleFonts.poppins(
        fontSize: 13, height: 1.35, color: AppColors.textPrimary);
    return GamePanel(
      color: AppColors.surface,
      borderWidth: 2,
      shadowOffset: 3,
      borderRadius: 4,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (beat.label.isNotEmpty)
            SizedBox(
              width: 72,
              child: Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: Text(
                  beat.label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: _spans(beat.text, body, const Color(0xFF8A3B12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline: a gold square per event on one wooden line ─────────────────────
class _Timeline extends StatelessWidget {
  final List<TimelineNode> nodes;
  const _Timeline({required this.nodes});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 24,
          right: 24,
          top: 7,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              border: Border.all(color: AppColors.primaryDark, width: 1),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final n in nodes)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: n.top.isEmpty
                            ? AppColors.surfaceAlt
                            : AppColors.accent,
                        border:
                            Border.all(color: AppColors.primaryDark, width: 3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 14,
                      child: Text(
                        n.top,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      n.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        height: 1.2,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ── A key term: closed until tapped ──────────────────────────────────────────
class _TermCard extends StatelessWidget {
  final Map<String, String> term;
  final bool open;
  final VoidCallback onTap;
  const _TermCard({
    super.key,
    required this.term,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: !open,
      label: open
          ? '${term['term']}: ${term['def']}'
          : 'Buksan ang ${term['term']}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: open ? null : onTap,
        child: GamePanel(
          color: open ? AppColors.surface : AppColors.surfaceAlt,
          borderWidth: 2,
          shadowOffset: 3,
          borderRadius: 4,
          padding: const EdgeInsets.all(9),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 70),
            child: Column(
              crossAxisAlignment:
                  open ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  term['term']!,
                  textAlign: open ? TextAlign.start : TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  open ? term['def']! : 'Itapik para mabasa',
                  textAlign: open ? TextAlign.start : TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: open ? 12 : 11,
                    height: 1.3,
                    color:
                        open ? AppColors.textPrimary : AppColors.textSecondary,
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

// ── Bottom bar: what is left, and the button ─────────────────────────────────
class _BottomBar extends StatelessWidget {
  final bool ready;
  final int left;
  final VoidCallback onTap;
  const _BottomBar(
      {required this.ready, required this.left, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 22, 14, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00140E1F), Color(0xEE140E1F)],
          stops: [0.0, 0.4],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: Text(
              ready
                  ? 'Nabasa mo na ang lahat ng termino.'
                  : left == 1
                      ? 'Isa pang termino ang kailangang basahin.'
                      : '$left termino pa ang kailangang basahin.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.3,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 10,
            child: GameButton(
              key: BackgroundHistoryScreen.readyButtonKey,
              label: 'HANDA NA AKO!',
              color: AppColors.success,
              textColor: Colors.white,
              fontSize: 11,
              minHeight: 46,
              onPressed: ready ? onTap : null,
            ),
          ),
        ],
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
