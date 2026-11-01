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
import '../../widgets/guest_card.dart';
import '../../widgets/pixel_icon.dart';
import '../../widgets/update_card.dart';
import 'settings_header.dart';

/// Settings: big icon tiles, one word each, each leading to its own screen. Opened
/// from the main menu's gear and from the pause menu, and it is the same screen
/// either way. Tunog and Kontrol are the tiles today (with their state small
/// underneath), then I-LOGOUT in red; further settings become more tiles. Below
/// them sits Test Mode (tester build only).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const Key soundKey = Key('settings_sound');
  static const Key controlsKey = Key('settings_controls');

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final scheme = ref.watch(controlSchemeProvider);
    final audio = AudioService();

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
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        children: [
                          // Big icon tiles, one word each. A tile that has a state
                          // shows it small underneath.
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              _SettingsTile(
                                key: SettingsScreen.soundKey,
                                icon: PixelGlyph.speaker,
                                title: 'Tunog',
                                value: _soundSummary(audio),
                                valueWidget: _SoundMarks(
                                  music: audio.musicEnabled,
                                  effects: audio.soundEnabled,
                                ),
                                // The marks under the title are read again on the way back.
                                onTap: () async {
                                  await context.push('/settings/sound');
                                  if (mounted) setState(() {});
                                },
                              ),
                              _SettingsTile(
                                key: SettingsScreen.controlsKey,
                                icon: PixelGlyph.move,
                                title: 'Kontrol',
                                value: scheme == ControlScheme.arrows
                                    ? 'Mga Arrow'
                                    : 'Joystick',
                                onTap: () => context.push('/settings/controls'),
                              ),
                              const _LogoutTile(),
                            ],
                          ),
                          // This phone's version, and the newer one when there is one.
                          const SizedBox(height: 18),
                          const UpdateRow(),
                          // Only the tester build has Test Mode.
                          if (ref.watch(testBuildProvider)) ...const [
                            SizedBox(height: 18),
                            _UnlockAllSwitch(),
                          ],
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

/// Test Mode (tester build only): opens every era and level, and while it is on
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

/// What a screen reader says for the Tunog tile: music and effects, on or off.
String _soundSummary(AudioService audio) {
  final music = audio.musicEnabled ? 'Musika ON' : 'Musika OFF';
  final sfx = audio.soundEnabled ? 'Effects ON' : 'Effects OFF';
  return '$music · $sfx';
}

/// The two small marks under Tunog: the note (music) and the speaker (effects),
/// green when on and grey when off.
class _SoundMarks extends StatelessWidget {
  final bool music;
  final bool effects;
  const _SoundMarks({required this.music, required this.effects});

  @override
  Widget build(BuildContext context) {
    Color tone(bool on) => on ? AppColors.success : const Color(0xFF7A6B94);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PixelIcon(PixelGlyph.note, size: 14, color: tone(music)),
        const SizedBox(width: 8),
        PixelIcon(PixelGlyph.speaker, size: 14, color: tone(effects)),
      ],
    );
  }
}

/// A wooden tile: a big gold icon, one word, and its state small underneath.
class _SettingsTile extends StatelessWidget {
  final PixelGlyph icon;
  final String title;

  /// What a screen reader says after the title; the tile shows [valueWidget] or this text.
  final String value;
  final Widget? valueWidget;
  final VoidCallback onTap;
  final bool danger;

  /// The gold tile: the one thing to do here (a guest signing in).
  final bool gold;

  const _SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.valueWidget,
    this.danger = false,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    final ink = danger
        ? const Color(0xFFFF8F86)
        : gold
            ? AppColors.primaryDark
            : AppColors.accent;
    return Semantics(
      button: true,
      label: value.isEmpty ? title : '$title: $value',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 118,
          height: 118,
          decoration: BoxDecoration(
            color: danger
                ? const Color(0xFF5A1620)
                : gold
                    ? AppColors.accent
                    : AppColors.primary,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.primaryDark, width: 3),
            boxShadow: const [
              BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 4))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PixelIcon(icon, size: 40, color: ink),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.2,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: ink,
                ),
              ),
              SizedBox(
                height: 18,
                child: Center(
                  child: valueWidget ??
                      (value.isEmpty
                          ? null
                          : Text(
                              value,
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                color:
                                    gold ? AppColors.primaryDark : Colors.white,
                              ),
                            )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutTile extends ConsumerWidget {
  const _LogoutTile();

  static const Key buttonKey = Key('logout_button');
  static const Key signInKey = Key('guest_sign_in_button');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A guest has nothing to log out of: the way on is to leave Guest Mode, after
    // being asked, and land on the first screen.
    final guest = ref.watch(authProvider.select((s) => s.isGuest));
    if (guest) {
      return _SettingsTile(
        key: signInKey,
        icon: PixelGlyph.door,
        title: 'EXIT GUEST MODE',
        value: '',
        gold: true,
        onTap: () async {
          if (!await showGuestExitConfirm(context)) return;
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) context.go('/login');
        },
      );
    }
    return _SettingsTile(
      key: buttonKey,
      icon: PixelGlyph.door,
      title: 'I-LOGOUT',
      value: '',
      danger: true,
      onTap: () async {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) context.go('/login');
      },
    );
  }
}
