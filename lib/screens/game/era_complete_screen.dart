// Destination in your repo: lib/screens/game/era_complete_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';
import '../../widgets/game_ui.dart';

class EraCompleteScreen extends StatefulWidget {
  final String eraId;
  const EraCompleteScreen({super.key, required this.eraId});

  @override
  State<EraCompleteScreen> createState() => _EraCompleteScreenState();
}

class _EraCompleteScreenState extends State<EraCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Baseline is now the average of Levels 1-9 ("pre_test" type results),
  // not a separate cold pre-test. Both are nullable so we can tell the
  // difference between "0%" and "no data yet" instead of faking numbers.
  double? levelsAverage;
  int? postTestScore;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _loadScores();
  }

  Future<void> _loadScores() async {
    try {
      final results = await ApiService().getResults();
      final eraResults =
          results.where((r) => r.era == widget.eraId).toList();

      final levels = eraResults.where((r) => r.type == 'pre_test');
      final post = eraResults.where((r) => r.type == 'post_test');

      setState(() {
        levelsAverage = levels.isNotEmpty
            ? levels
                    .map((r) => r.percentage.toDouble())
                    .reduce((a, b) => a + b) /
                levels.length
            : null;
        postTestScore = post.isNotEmpty ? post.first.percentage : null;
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get hasCompleteData => levelsAverage != null && postTestScore != null;

  // Learning Gain = Boss (Level 10) score - Average(Levels 1-9)
  int get learningGain =>
      hasCompleteData ? (postTestScore! - levelsAverage!.round()) : 0;

  @override
  Widget build(BuildContext context) {
    final era = getEraById(widget.eraId);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getEraColor(widget.eraId),
              Colors.black87,
            ],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.accent))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Fireworks placeholder (animated particles)
                      SizedBox(
                        height: 60,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            return Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: List.generate(5, (i) {
                                final offset =
                                    ((_controller.value + i * 0.2) % 1.0) *
                                        40;
                                return Transform.translate(
                                  offset: Offset(0, -offset),
                                  child: Opacity(
                                    opacity: 1.0 -
                                        (_controller.value + i * 0.2) %
                                            1.0,
                                    child: Icon(
                                      Icons.auto_awesome,
                                      color: i.isEven
                                          ? AppColors.accent
                                          : Colors.orangeAccent,
                                      size: 20,
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),

                      // Title
                      Text(
                        'ERA TAPOS NA!',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          height: 1.4,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        era.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white60,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (!hasCompleteData) ...[
                        // Honest empty/error state instead of fake numbers
                        GamePanel(
                          color: AppColors.surface,
                          margin: const EdgeInsets.symmetric(horizontal: 0),
                          padding: const EdgeInsets.all(20),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Column(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: AppColors.textMuted, size: 32),
                                const SizedBox(height: 12),
                                Text(
                                  hasError
                                      ? 'Hindi ma-load ang iyong mga score ngayon. Subukang buksan muli ang page na ito.'
                                      : 'Kulang pa ang datos para makita ang iyong Learning Gain.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ] else ...[
                        // Score comparison card
                        GamePanel(
                          color: AppColors.surface,
                          padding: const EdgeInsets.all(20),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Column(
                            children: [
                              // Levels 1-9 average (the real pre-test baseline)
                              _ScoreRow(
                                label: 'Average sa mga Level (1–9):',
                                percentage: levelsAverage!.round(),
                                color: AppColors.warning,
                              ),
                              const SizedBox(height: 12),
                              // Boss level (post-test)
                              _ScoreRow(
                                label: 'Panghuling Pagsubok (Boss):',
                                percentage: postTestScore!,
                                color: AppColors.success,
                              ),
                              const SizedBox(height: 20),

                              // Learning gain
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: learningGain >= 20
                                      ? AppColors.success
                                          .withValues(alpha: 0.1)
                                      : learningGain >= 10
                                          ? AppColors.success
                                              .withValues(alpha: 0.08)
                                          : AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: learningGain >= 20
                                        ? AppColors.success
                                            .withValues(alpha: 0.3)
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      learningGain >= 20
                                          ? Icons.emoji_events
                                          : learningGain >= 10
                                              ? Icons.thumb_up
                                              : Icons.trending_up,
                                      color: learningGain >= 20
                                          ? AppColors.accent
                                          : AppColors.success,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${learningGain >= 0 ? '+' : ''}$learningGain% Natuto Ka!',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            height: 1.4,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                        Text(
                                          learningGain >= 20
                                              ? 'Napakagaling! 🏆'
                                              : learningGain >= 10
                                                  ? 'Magaling ka! 👍'
                                                  : 'Patuloy lang! 💪',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color:
                                                AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Next era button
                      GameButton(
                        label: 'SUSUNOD NA PANAHON',
                        fontSize: 11,
                        width: 280,
                        onPressed: () {
                          context.go('/era-selection');
                        },
                      ),
                    ],
                  ),
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
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int percentage;
  final Color color;

  const _ScoreRow({
    required this.label,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: GameProgressBar(
            value: percentage / 100,
            fillColor: color,
            height: 14,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$percentage%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}