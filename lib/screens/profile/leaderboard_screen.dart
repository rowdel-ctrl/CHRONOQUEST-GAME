import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> classLeaderboard = [];
  List<Map<String, dynamic>> schoolLeaderboard = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderboards();
  }

  Future<void> _loadLeaderboards() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final classData = await ApiService().getLeaderboard('class');
      final schoolData = await ApiService().getLeaderboard('school');
      if (!mounted) return;
      setState(() {
        classLeaderboard = classData;
        schoolLeaderboard = schoolData;
        isLoading = false;
      });
    } catch (_) {
      // Don't fabricate fake student rankings — show a real error state
      // so students never mistake placeholder names for actual classmates.
      if (!mounted) return;
      setState(() {
        classLeaderboard = [];
        schoolLeaderboard = [];
        isLoading = false;
        hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1209),
              Color(0xFF3E2723),
              Color(0xFF4A3728),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Spotlight radial glow behind the podium area
            Positioned(
              top: -80,
              left: 0,
              right: 0,
              child: Container(
                height: 400,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.8,
                    colors: [
                      AppColors.accent.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          tooltip: 'Bumalik',
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white70),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.emoji_events,
                                  color: AppColors.accent, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Leaderboard',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _loadLeaderboards,
                          tooltip: 'I-refresh',
                          icon: const Icon(Icons.refresh, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  // ── Tabs ──────────────────────────────────────────────────
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: AppColors.primaryDark,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      dividerHeight: 0,
                      tabs: const [
                        Tab(text: 'Aking Klase'),
                        Tab(text: 'Aming Paaralan'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Content ───────────────────────────────────────────────
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.accent))
                        : hasError
                            ? _ErrorState(onRetry: _loadLeaderboards)
                            : TabBarView(
                                controller: _tabController,
                                children: [
                                  _LeaderboardList(data: classLeaderboard),
                                  _LeaderboardList(data: schoolLeaderboard),
                                ],
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white38, size: 52),
            const SizedBox(height: 16),
            Text(
              'Hindi ma-load ang leaderboard.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Subukang muli.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: AppColors.accent),
              label: Text('Subukang Muli',
                  style: GoogleFonts.poppins(
                      color: AppColors.accent, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accent),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _LeaderboardList({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.leaderboard_outlined,
                color: Colors.white24, size: 48),
            const SizedBox(height: 12),
            Text(
              'Walang data pa',
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          // ── Top 3 Podium ────────────────────────────────────────────────
          if (data.length >= 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2nd place
                _PodiumItem(
                  entry: data[1],
                  rank: 2,
                  podiumHeight: 95,
                  color: const Color(0xFFB0BEC5),
                ),
                const SizedBox(width: 10),
                // 1st place
                _PodiumItem(
                  entry: data[0],
                  rank: 1,
                  podiumHeight: 130,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 10),
                // 3rd place
                _PodiumItem(
                  entry: data.length > 2 ? data[2] : {},
                  rank: 3,
                  podiumHeight: 75,
                  color: const Color(0xFFCD7F32),
                ),
              ],
            ),

          const SizedBox(height: 8),

          // ── Divider ─────────────────────────────────────────────────────
          if (data.length > 3)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                      child: Divider(
                          color: Colors.white.withValues(alpha: 0.12))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Iba pang manlalaro',
                      style: GoogleFonts.poppins(
                          color: Colors.white30, fontSize: 12),
                    ),
                  ),
                  Expanded(
                      child: Divider(
                          color: Colors.white.withValues(alpha: 0.12))),
                ],
              ),
            ),

          // ── Remaining Ranks ──────────────────────────────────────────────
          ...data.skip(3).toList().asMap().entries.map((entry) {
            final rank = entry.key + 4;
            final item = entry.value;
            final isEven = entry.key % 2 == 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isEven
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06), width: 1),
              ),
              child: Row(
                children: [
                  // Rank pill
                  Container(
                    width: 34,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#$rank',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.8),
                    child: Text(
                      (item['name'] as String? ?? '?')[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name
                  Expanded(
                    child: Text(
                      item['name'] as String? ?? '',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Score
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${item['score'] ?? 0}',
                          style: GoogleFonts.poppins(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        TextSpan(
                          text: ' pts',
                          style: GoogleFonts.poppins(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final Map<String, dynamic> entry;
  final int rank;
  final double podiumHeight;
  final Color color;

  const _PodiumItem({
    required this.entry,
    required this.rank,
    required this.podiumHeight,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final name = entry['name'] as String? ?? '?';
    final score = entry['score'] ?? 0;
    final avatarRadius = rank == 1 ? 26.0 : 20.0;
    final blockWidth = rank == 1 ? 96.0 : 76.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Crown for 1st place
        if (rank == 1) ...[
          const Icon(Icons.workspace_premium, color: AppColors.accent, size: 22),
          const SizedBox(height: 2),
        ] else
          const SizedBox(height: 30),

        // Avatar with colored ring
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: rank == 1 ? 3 : 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: avatarRadius,
            backgroundColor: color.withValues(alpha: 0.25),
            child: Text(
              name[0].toUpperCase(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: rank == 1 ? 22 : 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Name
        SizedBox(
          width: blockWidth,
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),

        // Podium block
        Container(
          width: blockWidth,
          height: podiumHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.45),
                color.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: rank == 1 ? 22 : 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$score',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: rank == 1 ? 14 : 12,
                ),
              ),
              Text(
                'pts',
                style: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}