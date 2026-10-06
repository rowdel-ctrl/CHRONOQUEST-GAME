import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/control_scheme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/control_scheme_provider.dart';
import '../../providers/unlock_all_provider.dart';
import '../../services/audio_service.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/pixel_icon.dart';
import 'settings_header.dart';

/// Settings: one list of rows, each leading to its own screen. Opened from the
/// main menu's gear and from the pause menu, and it is the same screen either
/// way. Kontrol and Tunog are the rows today; further settings become more rows.
/// Below them sit Test Mode and the logout button.
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
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        children: [
                          _SettingsRow(
                            icon: PixelGlyph.move,
                            title: 'Kontrol',
                            value: scheme == ControlScheme.arrows
                                ? 'Mga Arrow'
                                : 'Joystick',
                            onTap: () => context.push('/settings/controls'),
                          ),
                          const SizedBox(height: 10),
                          _SettingsRow(
                            icon: PixelGlyph.speaker,
                            title: 'Tunog',
                            value: _soundSummary(),
                            // The summary under the title is read again on the way back.
                            onTap: () async {
                              await context.push('/settings/sound');
                              if (mounted) setState(() {});
                            },
                          ),
                          const SizedBox(height: 14),
                          const _UnlockAllSwitch(),
                          const SizedBox(height: 10),
                          const _LogoutButton(),
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

/// Test Mode (temporary): opens every era and level, and while it is on
/// hearts are not spent, so the whole game can be played without waiting.
class _UnlockAllSwitch extends ConsumerWidget {
  const _UnlockAllSwitch();

  static const Key switchKey = Key('unlock_all_switch');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A Material rather than a decorated Container: a ListTile needs the
    // Material directly behind it to paint its ink.
    return Material(
      color: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: SwitchListTile(
          key: switchKey,
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeThumbColor: AppColors.accent,
          title: Text(
            'Test Mode',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Bukas ang lahat ng panahon at level, at hindi nawawala ang puso.',
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10),
          ),
          value: ref.watch(unlockAllProvider),
          onChanged: (v) => ref.read(unlockAllProvider.notifier).set(v),
        ),
      ),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  static const Key buttonKey = Key('logout_button');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GameButton(
      key: buttonKey,
      label: 'I-LOGOUT',
      color: AppColors.danger,
      textColor: Colors.white,
      fontSize: 10,
      minHeight: 44,
      width: double.infinity,
      leading: const PixelIcon(PixelGlyph.door, size: 20, color: Colors.white),
      onPressed: () async {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) context.go('/login');
      },
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
  final PixelGlyph icon;
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              MenuChipFace(icon: icon, size: 40),
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
              const PixelIcon(PixelGlyph.chevron,
                  color: AppColors.textSecondary, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
