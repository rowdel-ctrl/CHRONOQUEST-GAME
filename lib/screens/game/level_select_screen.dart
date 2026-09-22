import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/game_provider.dart';
import '../../services/storage_service.dart';
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

  bool _isLevelUnlocked(int level) {
    if (level == 1) return true;
    if (level == 10) return completedLevels.length >= 9;
    return completedLevels.containsKey(level - 1);
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
    final era = getEraById(widget.eraId);
    final hearts = ref.watch(gameProvider).hearts;
    final hasHearts = hearts.count > 0;
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
                      child: Text(
                        era.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // balance
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
                      children: List.generate(10, (i) {
                        final level = i + 1;
                        final isUnlocked = _isLevelUnlocked(level);
                        final isCompleted =
                            completedLevels.containsKey(level);
                        final stars = completedLevels[level] ?? 0;
                        final isBoss = level == 10;

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
                                        context.go(
                                            '/game/${widget.eraId}/$level');
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${completedLevels.length}/10 Levels Tapos',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Persistent hearts pool that gates starting/retrying a
                    // level — separate from in-level HP shown in the HUD.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(
                          GameConstants.maxHearts,
                          (i) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Image.asset(
                              i < hearts.count
                                  ? 'assets/ui/heart_full.png'
                                  : 'assets/ui/heart_empty.png',
                              width: 18,
                              height: 18,
                            ),
                          ),
                        ),
                        if (timeUntilNext != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Susunod: ${_formatCountdown(timeUntilNext)}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
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
}