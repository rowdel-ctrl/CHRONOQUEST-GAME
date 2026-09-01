import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../services/storage_service.dart';
import '../../widgets/game_ui.dart';

class BackgroundHistoryScreen extends StatefulWidget {
  final String eraId;
  const BackgroundHistoryScreen({super.key, required this.eraId});

  @override
  State<BackgroundHistoryScreen> createState() =>
      _BackgroundHistoryScreenState();
}

class _BackgroundHistoryScreenState extends State<BackgroundHistoryScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _hasReachedBottom = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  void _onScroll() {
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent - 20) {
      if (!_hasReachedBottom) {
        setState(() => _hasReachedBottom = true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final era = getEraById(widget.eraId);
    final eraColor = _getEraColor(widget.eraId);
    final selectedChar = StorageService.getCharacter();

    return Scaffold(
      body: Stack(
        children: [
          // ── Bookshelf background image ────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/bookshelf_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // ── Era-tinted dark overlay ───────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    eraColor.withValues(alpha: 0.88),
                    eraColor.withValues(alpha: 0.75),
                    Colors.black.withValues(alpha: 0.90),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // ── Era identity header ─────────────────────────────────
                  _EraHeader(era: era, eraColor: eraColor),

                  // ── Scrollable content ──────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Historical text card
                          _HistoricalTextCard(
                              era: era, eraColor: eraColor),
                          const SizedBox(height: 24),

                          // Key terms section
                          _SectionLabel(
                            icon: Icons.menu_book_rounded,
                            label: 'Mga Mahahalagang Termino',
                            color: eraColor,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _getKeyTerms(widget.eraId)
                                .map((term) => _KeyTermChip(
                                    term: term, eraColor: eraColor))
                                .toList(),
                          ),
                          const SizedBox(height: 28),

                          // Guide character companion panel
                          _GuidePanel(
                            era: era,
                            eraColor: eraColor,
                            characterId: selectedChar,
                          ),

                          // Extra scroll room so the button doesn't cover content
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),

                  // ── Bottom CTA ──────────────────────────────────────────
                  _BottomCta(
                    hasReachedBottom: _hasReachedBottom,
                    eraColor: eraColor,
                    onTap: () =>
                        context.go('/level-select/${widget.eraId}'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEraColor(String id) {
    switch (id) {
      case 'pre-colonial':
        return const Color(0xFF1B5E20);
      case 'spanish':
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

  List<Map<String, String>> _getKeyTerms(String eraId) {
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
          {
            'term': 'Demokrasya',
            'icon': '🗳️',
            'def': 'Pamahalaan ng mamamayan'
          },
        ];
      default:
        return [];
    }
  }
}

// ── Era Identity Header ────────────────────────────────────────────────────────
class _EraHeader extends StatelessWidget {
  final EraData era;
  final Color eraColor;
  const _EraHeader({required this.era, required this.eraColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.5),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb subtitle
          Text(
            era.subtitle.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.accent.withValues(alpha: 0.8),
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 4),
          // Main era title
          Text(
            era.name,
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          // Decorative divider
          Row(
            children: [
              Container(
                height: 2,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.auto_stories_rounded,
                  color: AppColors.accent.withValues(alpha: 0.7), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1,
                  color: AppColors.accent.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Historical Text Card ───────────────────────────────────────────────────────
class _HistoricalTextCard extends StatelessWidget {
  final EraData era;
  final Color eraColor;
  const _HistoricalTextCard({required this.era, required this.eraColor});

  @override
  Widget build(BuildContext context) {
    // Split into two paragraphs at midpoint for readability
    final text = era.historicalText;
    final mid = text.indexOf('.', text.length ~/ 2) + 1;
    final para1 = text.substring(0, mid).trim();
    final para2 = mid < text.length ? text.substring(mid).trim() : '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parchment label
          Row(
            children: [
              Icon(Icons.history_edu,
                  color: AppColors.accent.withValues(alpha: 0.6), size: 16),
              const SizedBox(width: 6),
              Text(
                'Kasaysayan',
                style: GoogleFonts.poppins(
                  color: AppColors.accent.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // First paragraph
          Text(
            para1,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.75,
            ),
          ),

          // Ornamental divider between paragraphs
          if (para2.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      height: 1,
                      width: 40,
                      color: AppColors.accent.withValues(alpha: 0.2)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('✦',
                        style: TextStyle(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            fontSize: 12)),
                  ),
                  Container(
                      height: 1,
                      width: 40,
                      color: AppColors.accent.withValues(alpha: 0.2)),
                ],
              ),
            ),
            Text(
              para2,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.92),
                height: 1.75,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionLabel(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

// ── Key Term Chip ──────────────────────────────────────────────────────────────
class _KeyTermChip extends StatelessWidget {
  final Map<String, String> term;
  final Color eraColor;
  const _KeyTermChip({required this.term, required this.eraColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${term['icon']} ${term['term']}',
                    style: GoogleFonts.poppins(
                      color: AppColors.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    term['def']!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Sarado',
                        style: GoogleFonts.poppins(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: AppColors.accent.withValues(alpha: 0.45), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(term['icon']!, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              term['term']!,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.touch_app_rounded,
                size: 12, color: AppColors.accent.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Guide Character Panel ──────────────────────────────────────────────────────
class _GuidePanel extends StatelessWidget {
  final EraData era;
  final Color eraColor;
  final String characterId;
  const _GuidePanel({
    required this.era,
    required this.eraColor,
    required this.characterId,
  });

  @override
  Widget build(BuildContext context) {
    // The avatar below is always the PLAYER'S chosen hero
    // (assets/characters/${characterId}_walk_1.png), so the name shown next
    // to it must describe that same hero — not era.guide, which is a fixed
    // lore mentor per era (e.g. pre-colonial's is always "Datu Lapu-Lapu")
    // and was never tied to what the player picked. Displaying era.guide
    // here made it look like character selection wasn't saving.
    final character = getCharacterById(characterId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: eraColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: eraColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Character sprite / avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: eraColor.withValues(alpha: 0.6),
              backgroundImage: AssetImage(
                  'assets/characters/${characterId}_walk_1.png'),
              onBackgroundImageError: (_, __) {},
              child: Text(
                character.name[0],
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Speech bubble content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Companion label
                Text(
                  'IYONG BAYANI',
                  style: GoogleFonts.poppins(
                    color: AppColors.accent.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  character.name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: eraColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: eraColor.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Text(
                    // era.guide keeps its lore role here — a mentor spirit
                    // for the era, clearly separate from the avatar above.
                    '"Ika\'y gagabayan ni ${era.guide} sa iyong paglalakbay!"',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
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

// ── Bottom CTA ─────────────────────────────────────────────────────────────────
class _BottomCta extends StatelessWidget {
  final bool hasReachedBottom;
  final Color eraColor;
  final VoidCallback onTap;
  const _BottomCta({
    required this.hasReachedBottom,
    required this.eraColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: hasReachedBottom
            ? Row(
                key: const ValueKey('ready'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GameButton(
                    label: 'HANDA NA AKO!',
                    fontSize: 12,
                    icon: Icons.play_arrow_rounded,
                    onPressed: onTap,
                  ),
                ],
              )
            : SizedBox(
                key: const ValueKey('scroll'),
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white38, size: 20),
                  label: Text(
                    'Mag-scroll pababa para magpatuloy',
                    style: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
