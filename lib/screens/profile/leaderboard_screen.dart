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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderboards();
  }

  Future<void> _loadLeaderboards() async {
    try {
      final classData = await ApiService().getLeaderboard('class');
      final schoolData = await ApiService().getLeaderboard('school');
      setState(() {
        classLeaderboard = classData;
        schoolLeaderboard = schoolData;
        isLoading = false;
      });
    } catch (_) {
      // Use sample data for display
      setState(() {
        classLeaderboard = _sampleData();
        schoolLeaderboard = _sampleData();
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _sampleData() {
    return List.generate(
      10,
      (i) => {
        'name': 'Student ${i + 1}',
        'score': (10 - i) * 100 + 50,
        'rank': i + 1,
      },
    );
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
              Color(0xFF3E2723),
              Color(0xFF5D4037),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.white70),
                    ),
                    Expanded(
                      child: Text(
                        'Leaderboard',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _loadLeaderboards,
                      icon:
                          const Icon(Icons.refresh, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: AppColors.primaryDark,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  dividerHeight: 0,
                  tabs: const [
                    Tab(text: 'Aking Klase'),
                    Tab(text: 'Aming Paaralan'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Content
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accent))
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
      return const Center(
        child: Text(
          'Walang data pa',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Top 3 podium
          if (data.length >= 3)
            SizedBox(
              height: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 2nd place
                  _PodiumItem(
                    entry: data[1],
                    rank: 2,
                    height: 90,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 8),
                  // 1st place
                  _PodiumItem(
                    entry: data[0],
                    rank: 1,
                    height: 120,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  // 3rd place
                  _PodiumItem(
                    entry: data.length > 2 ? data[2] : {},
                    rank: 3,
                    height: 70,
                    color: const Color(0xFFCD7F32),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Remaining ranks
          ...data.skip(3).toList().asMap().entries.map((entry) {
            final i = entry.key + 4;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '#$i',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      (item['name'] as String? ?? '?')[0],
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['name'] as String? ?? '',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                    ),
                  ),
                  Text(
                    '${item['score'] ?? 0}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
  final double height;
  final Color color;

  const _PodiumItem({
    required this.entry,
    required this.rank,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final name = entry['name'] as String? ?? '?';
    final score = entry['score'] ?? 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar
        CircleAvatar(
          radius: rank == 1 ? 22 : 18,
          backgroundColor: color,
          child: Text(
            name[0],
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: rank == 1 ? 18 : 14,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        // Podium block
        Container(
          width: rank == 1 ? 80 : 65,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '$score pts',
                style: const TextStyle(
                  color: Colors.white70,
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
