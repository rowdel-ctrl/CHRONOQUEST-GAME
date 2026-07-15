import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';

class BackgroundHistoryScreen extends StatefulWidget {
  final String eraId;
  const BackgroundHistoryScreen({super.key, required this.eraId});

  @override
  State<BackgroundHistoryScreen> createState() =>
      _BackgroundHistoryScreenState();
}

class _BackgroundHistoryScreenState extends State<BackgroundHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasReachedBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final era = getEraById(widget.eraId);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getEraColor(widget.eraId).withValues(alpha: 0.9),
              _getEraColor(widget.eraId).withValues(alpha: 0.7),
              Colors.black87,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Era title
                      Text(
                        era.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        era.subtitle,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Historical text
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          era.historicalText,
                          style: GoogleFonts.sourceSans3(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Key terms
                      Text(
                        'Mga Mahahalagang Termino',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _getKeyTerms(widget.eraId)
                            .map((term) => _KeyTermChip(term: term))
                            .toList(),
                      ),
                      const SizedBox(height: 24),

                      // Guide character
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.accent, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                era.guide[0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  era.guide,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Iyong gabay sa panahong ito',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),

              // Bottom button
              AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _hasReachedBottom ? 1.0 : 0.3,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasReachedBottom
                          ? () =>
                              context.go('/level-select/${widget.eraId}')
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _hasReachedBottom
                            ? 'HANDA NA AKO!'
                            : '↓ Mag-scroll pababa para magpatuloy',
                        style: GoogleFonts.sourceSans3(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
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
          {'term': 'Barangay', 'def': 'Maliit na komunidad na pinamumunuan ng datu'},
          {'term': 'Baybayin', 'def': 'Sistema ng pagsulat ng sinaunang Pilipino'},
          {'term': 'Datu', 'def': 'Pinuno ng barangay'},
        ];
      case 'spanish':
        return [
          {'term': 'Encomienda', 'def': 'Sistema ng pagbibigay ng lupain sa mga Espanyol'},
          {'term': 'Katipunan', 'def': 'Lihim na samahan laban sa Espanya'},
          {'term': 'Himagsikan', 'def': 'Rebolusyon ng mga Pilipino'},
        ];
      case 'american':
        return [
          {'term': 'Thomasites', 'def': 'Mga gurong Amerikano na dumating sa Pilipinas'},
          {'term': 'Commonwealth', 'def': 'Pamahalaan bago ang ganap na kalayaan'},
          {'term': 'Malolos', 'def': 'Lugar kung saan itinatag ang unang republika'},
        ];
      case 'ww2':
        return [
          {'term': 'Bataan Death March', 'def': 'Malupit na martsa ng mga bihag ng Hapon'},
          {'term': 'Gerilya', 'def': 'Mga lihim na mandirigma laban sa Hapon'},
          {'term': 'Liberation', 'def': 'Pagpapalaya ng Pilipinas'},
        ];
      case 'modern':
        return [
          {'term': 'EDSA Revolution', 'def': 'People Power na nagpabagsak sa diktadura'},
          {'term': 'Martial Law', 'def': 'Batas militar na idineklara ni Marcos'},
          {'term': 'Demokrasya', 'def': 'Pamahalaan ng mamamayan'},
        ];
      default:
        return [];
    }
  }
}

class _KeyTermChip extends StatelessWidget {
  final Map<String, String> term;
  const _KeyTermChip({required this.term});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(term['term']!),
            content: Text(term['def']!),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline,
                size: 14, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              term['term']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
