import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/game_provider.dart';
import '../../providers/unlock_all_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/hearts_pill.dart';
import 'level_node.dart';

String _formatCountdown(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class LevelSelectScreen extends ConsumerStatefulWidget {
  final String eraId;
  const LevelSelectScreen({super.key, required this.eraId});

  @override
  ConsumerState<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends ConsumerState<LevelSelectScreen> {
  Map<int, int> completedLevels = {};
  Timer? _heartsTimer;

  @override
  void initState() {
    super.initState();
    completedLevels = StorageService.getCompletedLevels(widget.eraId);
    // Ticks the persistent-hearts countdown shown below, and applies any
    // regen due since the provider was created — this screen is the main
    // place players wait out that countdown.
    _heartsTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => ref.read(gameProvider.notifier).refreshHearts(),
    );
  }

  @override
  void dispose() {
    _heartsTimer?.cancel();
    super.dispose();
  }

  bool _isLevelUnlocked(int level, int levelCount) {
    // Testing switch (Profile): everything open.
    if (ref.read(unlockAllProvider)) return true;
    if (level == 1) return true;
    if (level == levelCount) return completedLevels.length >= levelCount - 1;
    return completedLevels.containsKey(level - 1);
  }

  /// The first-play tutorial gates here — the point a student actually
  /// starts a level — rather than on character selection (effectively "on
  /// app open"), which is what the playtest flagged as the wrong trigger.
  void _startLevel(int level) {
    if (!StorageService.hasSeenTutorial()) {
      context.push('/tutorial').then((_) {
        if (mounted) context.go('/game/${widget.eraId}/$level');
      });
    } else {
      context.go('/game/${widget.eraId}/$level');
    }
  }

  void _showNoHeartsDialog(BuildContext context, Duration? timeUntilNext) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          side: BorderSide(color: AppColors.primaryDark, width: 3),
        ),
        title: Text(
          'Wala nang Puso',
          style: GoogleFonts.poppins(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          timeUntilNext != null
              ? 'Maghintay ng ${_formatCountdown(timeUntilNext)} para sa '
                  'susunod na puso, o bumalik mamaya.'
              : 'Maghintay ng kaunti para sa susunod na puso, o bumalik '
                  'mamaya.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Sige',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watched so the map redraws if the testing switch changes.
    ref.watch(unlockAllProvider);
    final era = getEraById(widget.eraId);
    final levelCount = era.levels.length;
    final hearts = ref.watch(gameProvider).hearts;
    // Also true while the testing switch makes hearts free.
    final hasHearts = ref.read(gameProvider.notifier).canStartLevel;
    final timeUntilNext = hearts.timeUntilNext(DateTime.now());

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getEraColor(widget.eraId).withValues(alpha: 0.6),
              _getEraColor(widget.eraId).withValues(alpha: 0.3),
              Colors.black87,
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
                      onPressed: () => context.go('/era-selection'),
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.white70),
                    ),
                    Expanded(
                      // Shrinks to fit rather than cutting the name: the longest
                      // is 47 characters.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          era.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            height: 1.4,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    // The shared hearts pool, the same pill character select
                    // shows in the same corner. Level select is where hearts
                    // gate starting a level, so it is where they matter most.
                    const HeartsPill(),
                  ],
                ),
              ),

              // Level milestones
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: List.generate(levelCount, (i) {
                        final level = i + 1;
                        final isUnlocked = _isLevelUnlocked(level, levelCount);
                        final isCompleted =
                            completedLevels.containsKey(level);
                        final stars = completedLevels[level] ?? 0;
                        final isBoss = level == levelCount;

                        return Row(
                          children: [
                            // Road connector
                            if (i > 0)
                              Container(
                                width: 30,
                                height: 4,
                                color: isCompleted || isUnlocked
                                    ? AppColors.accent.withValues(alpha: 0.6)
                                    : Colors.white24,
                              ),
                            // Level node
                            LevelNode(
                              level: level,
                              isUnlocked: isUnlocked,
                              isCompleted: isCompleted,
                              stars: stars,
                              isBoss: isBoss,
                              onTap: isUnlocked
                                  ? () {
                                      if (hasHearts) {
                                        _startLevel(level);
                                      } else {
                                        _showNoHeartsDialog(
                                            context, timeUntilNext);
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),

              // Bottom info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${completedLevels.length}/$levelCount Levels Tapos',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
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
}