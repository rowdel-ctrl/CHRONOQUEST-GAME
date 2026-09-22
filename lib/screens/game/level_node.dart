import 'package:flutter/material.dart';
import '../../core/constants.dart';

/// A single tappable level milestone on [LevelSelectScreen]'s horizontal
/// path — stars earned, the level number/BOSS badge, and a lock icon when
/// progression hasn't reached it yet. Split out of the screen file to keep
/// it within the project's line budget; behavior is unchanged.
class LevelNode extends StatelessWidget {
  final int level;
  final bool isUnlocked;
  final bool isCompleted;
  final int stars;
  final bool isBoss;
  final VoidCallback? onTap;

  const LevelNode({
    super.key,
    required this.level,
    required this.isUnlocked,
    required this.isCompleted,
    required this.stars,
    required this.isBoss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stars
          if (isCompleted)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (s) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Image.asset(
                    s < stars
                        ? 'assets/ui/star_full.png'
                        : 'assets/ui/star_empty.png',
                    width: 14,
                    height: 14,
                  ),
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
              shape: isBoss ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isBoss ? BorderRadius.circular(12) : null,
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
                  ? const Icon(Icons.check, color: Colors.white, size: 22)
                  : !isUnlocked
                      ? Image.asset(
                          'assets/ui/lock_icon.png',
                          color: Colors.white38,
                          width: 18,
                          height: 18,
                        )
                      : Text(
                          isBoss ? 'BOSS' : '$level',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isBoss ? 12 : 16,
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isBoss ? 'Level 10' : 'Level $level',
            style: TextStyle(
              color: isUnlocked ? Colors.white70 : Colors.white30,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
