import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final student = authState.student;

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
                        'Profile',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Character + info
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            // Avatar
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.accent, width: 3),
                              ),
                              child: Center(
                                child: Text(
                                  student?.name.isNotEmpty == true
                                      ? student!.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              student?.name ?? 'Student',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              student?.classCode ?? '',
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.accent,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              student?.schoolName ?? '',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Stats row
                            _StatBox(
                              label: 'Puntos',
                              value: '${student?.score ?? 0}',
                              icon: Icons.star,
                            ),
                            const SizedBox(height: 8),
                            _StatBox(
                              label: 'Coins',
                              value: '${student?.coins ?? 0}',
                              icon: Icons.monetization_on,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Right: Era progress + powerups
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Era progress
                            ...allEras.map((era) {
                              final levels =
                                  StorageService.getCompletedLevels(era.id);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: levels.length >= 10
                                            ? AppColors.success
                                            : levels.isNotEmpty
                                                ? AppColors.warning
                                                : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        era.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${levels.length}/10',
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const SizedBox(height: 12),

                            // Powerups
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Powerups',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _PowerupDisplay(
                                        icon: Icons.filter_2,
                                        label: '50/50',
                                        count: student
                                                ?.powerUps.fiftyFifty ??
                                            0,
                                      ),
                                      _PowerupDisplay(
                                        icon: Icons.ac_unit,
                                        label: 'Freeze',
                                        count: student
                                                ?.powerUps.timeFreeze ??
                                            0,
                                      ),
                                      _PowerupDisplay(
                                        icon: Icons.shield,
                                        label: 'Shield',
                                        count:
                                            student?.powerUps.shield ?? 0,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Logout
                            OutlinedButton.icon(
                              onPressed: () async {
                                await ref
                                    .read(authProvider.notifier)
                                    .logout();
                                if (context.mounted) {
                                  context.go('/login');
                                }
                              },
                              icon: const Icon(Icons.logout, size: 18),
                              label: const Text('I-LOGOUT'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: BorderSide(
                                    color: AppColors.danger
                                        .withValues(alpha: 0.5)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerupDisplay extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _PowerupDisplay({
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 22),
        const SizedBox(height: 4),
        Text(
          '×$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}
