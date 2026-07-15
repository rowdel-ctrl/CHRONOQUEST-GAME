import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../services/storage_service.dart';

class LevelSelectScreen extends StatefulWidget {
  final String eraId;
  const LevelSelectScreen({super.key, required this.eraId});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  Map<int, int> completedLevels = {};

  @override
  void initState() {
    super.initState();
    completedLevels = StorageService.getCompletedLevels(widget.eraId);
  }

  bool _isLevelUnlocked(int level) {
    if (level == 1) return true;
    if (level == 10) return completedLevels.length >= 9;
    return completedLevels.containsKey(level - 1);
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
                        era.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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
                            GestureDetector(
                              onTap: isUnlocked
                                  ? () => context.go(
                                      '/game/${widget.eraId}/$level')
                                  : null,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Stars
                                  if (isCompleted)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        3,
                                        (s) => Icon(
                                          s < stars
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 14,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 14),
                                  const SizedBox(height: 4),
                                  // Node circle
                                  Container(
                                    width: isBoss ? 60 : 48,
                                    height: isBoss ? 60 : 48,
                                    decoration: BoxDecoration(
                                      shape: isBoss
                                          ? BoxShape.rectangle
                                          : BoxShape.circle,
                                      borderRadius: isBoss
                                          ? BorderRadius.circular(12)
                                          : null,
                                      color: isCompleted
                                          ? AppColors.accent
                                          : isUnlocked
                                              ? AppColors.primary
                                              : Colors.grey.shade700,
                                      border: Border.all(
                                        color: isCompleted
                                            ? AppColors.accent
                                            : isUnlocked
                                                ? Colors.white54
                                                : Colors.grey,
                                        width: 2.5,
                                      ),
                                      boxShadow: isUnlocked
                                          ? [
                                              BoxShadow(
                                                color: (isCompleted
                                                        ? AppColors.accent
                                                        : AppColors.primary)
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Center(
                                      child: isCompleted
                                          ? const Icon(Icons.check,
                                              color: Colors.white, size: 22)
                                          : !isUnlocked
                                              ? const Icon(Icons.lock,
                                                  color: Colors.white38,
                                                  size: 18)
                                              : Text(
                                                  isBoss ? 'BOSS' : '$level',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize:
                                                        isBoss ? 12 : 16,
                                                  ),
                                                ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isBoss ? 'Level 10' : 'Level $level',
                                    style: TextStyle(
                                      color: isUnlocked
                                          ? Colors.white70
                                          : Colors.white30,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
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
                  '${completedLevels.length}/10 Levels Tapos',
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
