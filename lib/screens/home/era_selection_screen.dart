// Destination in your repo: lib/screens/home/era_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';

class EraSelectionScreen extends ConsumerStatefulWidget {
  const EraSelectionScreen({super.key});

  @override
  ConsumerState<EraSelectionScreen> createState() =>
      _EraSelectionScreenState();
}

class _EraSelectionScreenState extends ConsumerState<EraSelectionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(progressProvider.notifier).loadProgress());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final progressState = ref.watch(progressProvider);
    final student = authState.student;
    final gradeLevel = student?.gradeLevel ?? 'grade5';

    // Filter eras by grade level
    final visibleEras = allEras
        .where((era) =>
            eraGradeMap[era.id]?.contains(gradeLevel) ?? false)
        .toList();

    final visibleEraIds = visibleEras.map((e) => e.id).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backgrounds/bookshelf_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        foregroundDecoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.35),
              Colors.black.withValues(alpha: 0.15),
              Colors.black.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/character-selection'),
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white70),
                    ),
                    Expanded(
                      child: Text(
                        'PILIIN ANG PANAHON',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: GoogleFonts.pressStart2p(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/profile'),
                      icon: const Icon(Icons.person, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Era books shelf
              Expanded(
                child: progressState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accent))
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: visibleEras.asMap().entries.map((entry) {
                            final index = entry.key;
                            final era = entry.value;
                            final progress = ref
                                .read(progressProvider.notifier)
                                .getEraProgress(era.id);
                            final isUnlocked = ref
                                .read(progressProvider.notifier)
                                .isEraUnlocked(era.id, visibleEraIds);

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6),
                                child: _EraBook(
                                  era: era,
                                  progress: progress,
                                  isUnlocked: isUnlocked,
                                  index: index,
                                  onTap: isUnlocked
                                      ? () {
                                          // No more separate cold pre-test —
                                          // first visit goes straight to the
                                          // background reading, then into
                                          // Level 1 (which doubles as the
                                          // real pre-test baseline).
                                          if (progress.levelsCompleted > 0) {
                                            context.go(
                                                '/level-select/${era.id}');
                                          } else {
                                            context.go(
                                                '/background/${era.id}');
                                          }
                                        }
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ),

              // Student info bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  border: Border(
                    top: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        (student?.name.isNotEmpty ?? false)
                            ? student!.name[0]
                            : '?',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      student?.name ?? 'Student',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                    ),
                    const Spacer(),
                    Image.asset('assets/ui/star_full.png',
                        width: 18, height: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${student?.score ?? 0} pts',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
}

class _EraBook extends StatelessWidget {
  final EraData era;
  final dynamic progress;
  final bool isUnlocked;
  final int index;
  final VoidCallback? onTap;

  const _EraBook({
    required this.era,
    required this.progress,
    required this.isUnlocked,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = progress.isCompleted;
    final isInProgress = progress.isInProgress;
    final levelsCompleted = progress.levelsCompleted as int;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isUnlocked ? 1.0 : 0.4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Book spine
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: (isCompleted
                        ? const Color(0xFFD4AF37)
                        : isUnlocked
                            ? _getEraBookColor(era.id)
                            : Colors.grey.shade700)
                    .withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isUnlocked
                      ? AppColors.accent.withValues(alpha: 0.5)
                      : Colors.grey,
                  width: 1.5,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: _getEraBookColor(era.id)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(2, 4),
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                children: [
                  // Book content
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isCompleted)
                          Image.asset('assets/ui/star_full.png',
                              width: 28, height: 28)
                        else if (!isUnlocked)
                          Image.asset('assets/ui/lock_icon.png',
                              width: 26, height: 26)
                        else
                          Icon(Icons.auto_stories,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 28),
                        const SizedBox(height: 6),
                        Text(
                          era.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 8,
                            height: 1.4,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress indicator
                  if (isInProgress)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$levelsCompleted/10',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              era.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 9,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Color _getEraBookColor(String id) {
    switch (id) {
      case 'pre-colonial':
        return const Color(0xFF2E7D32);
      case 'spanish':
        return const Color(0xFF8B4513);
      case 'american':
        return const Color(0xFF1565C0);
      case 'ww2':
        return const Color(0xFF424242);
      case 'modern':
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF8B4513);
    }
  }
}