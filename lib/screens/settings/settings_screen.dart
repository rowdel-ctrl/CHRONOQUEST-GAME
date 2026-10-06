import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/control_scheme.dart';
import '../../providers/control_scheme_provider.dart';
import '../../services/audio_service.dart';
import '../../widgets/game_ui.dart';
import 'settings_header.dart';

/// Settings: one list of rows, each leading to its own screen. Opened from the
/// main menu's gear and from the pause menu, and it is the same screen either
/// way. Kontrol and Tunog are the rows today; further settings become more rows.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final scheme = ref.watch(controlSchemeProvider);

    return Scaffold(
      body: GameBackdrop(
        baseColor: AppColors.background,
        child: SafeArea(
          child: Column(
            children: [
              const SettingsHeader(title: 'SETTINGS'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        children: [
                          _SettingsRow(
                            icon: Icons.sports_esports,
                            title: 'Kontrol',
                            value: scheme == ControlScheme.arrows
                                ? 'Mga Arrow'
                                : 'Joystick',
                            onTap: () => context.push('/settings/controls'),
                          ),
                          const SizedBox(height: 12),
                          _SettingsRow(
                            icon: Icons.volume_up,
                            title: 'Tunog',
                            value: _soundSummary(),
                            // The summary under the title is read again on the way back.
                            onTap: () async {
                              await context.push('/settings/sound');
                              if (mounted) setState(() {});
                            },
                          ),
                        ],
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
}

/// What the Tunog row shows under its title.
String _soundSummary() {
  final audio = AudioService();
  final music = audio.musicEnabled ? 'Musika ON' : 'Musika OFF';
  final sfx = audio.soundEnabled ? 'Effects ON' : 'Effects OFF';
  return '$music · $sfx';
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title: $value',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: GamePanel(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}
