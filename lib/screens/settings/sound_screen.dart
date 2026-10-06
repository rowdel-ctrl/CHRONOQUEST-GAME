import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../services/audio_service.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/pixel_icon.dart';
import 'settings_header.dart';

/// Tunog: music and sound effects, each with an on/off switch and a volume
/// slider. Changes apply at once (music that is playing gets quieter as the
/// slider moves) and are saved on this device.
class SoundScreen extends StatefulWidget {
  /// Replaceable so a test does not need the audio plugin.
  final AudioService? audio;
  const SoundScreen({super.key, this.audio});

  static const Key musicSwitchKey = Key('sound_music_switch');
  static const Key musicSliderKey = Key('sound_music_slider');
  static const Key sfxSwitchKey = Key('sound_sfx_switch');
  static const Key sfxSliderKey = Key('sound_sfx_slider');

  @override
  State<SoundScreen> createState() => _SoundScreenState();
}

class _SoundScreenState extends State<SoundScreen> {
  late final AudioService _audio = widget.audio ?? AudioService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackdrop(
        baseColor: AppColors.background,
        child: SafeArea(
          child: Column(
            children: [
              const SettingsHeader(title: 'TUNOG'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        children: [
                          _VolumeCard(
                            icon: PixelGlyph.note,
                            title: 'Musika',
                            on: _audio.musicEnabled,
                            volume: _audio.musicVolume,
                            switchKey: SoundScreen.musicSwitchKey,
                            sliderKey: SoundScreen.musicSliderKey,
                            onSwitch: (v) =>
                                setState(() => _audio.setMusicEnabled(v)),
                            onVolume: (v) =>
                                setState(() => _audio.setMusicVolume(v)),
                          ),
                          const SizedBox(height: 14),
                          _VolumeCard(
                            icon: PixelGlyph.speaker,
                            title: 'Sound Effects',
                            on: _audio.soundEnabled,
                            volume: _audio.sfxVolume,
                            switchKey: SoundScreen.sfxSwitchKey,
                            sliderKey: SoundScreen.sfxSliderKey,
                            onSwitch: (v) =>
                                setState(() => _audio.setSoundEnabled(v)),
                            onVolume: (v) =>
                                setState(() => _audio.setSfxVolume(v)),
                            // Let them hear the new level when they let go.
                            onVolumeDone: (_) => _audio.playCoin(),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Naka-save sa device na ito.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
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

class _VolumeCard extends StatelessWidget {
  final PixelGlyph icon;
  final String title;
  final bool on;
  final double volume;
  final Key switchKey;
  final Key sliderKey;
  final ValueChanged<bool> onSwitch;
  final ValueChanged<double> onVolume;
  final ValueChanged<double>? onVolumeDone;

  const _VolumeCard({
    required this.icon,
    required this.title,
    required this.on,
    required this.volume,
    required this.switchKey,
    required this.sliderKey,
    required this.onSwitch,
    required this.onVolume,
    this.onVolumeDone,
  });

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              MenuChipFace(
                  icon: on ? icon : PixelGlyph.speakerOff, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                on ? 'ON' : 'OFF',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: on ? AppColors.accent : AppColors.textMuted,
                ),
              ),
              Switch(
                key: switchKey,
                value: on,
                activeThumbColor: AppColors.accent,
                onChanged: onSwitch,
              ),
            ],
          ),
          Row(
            children: [
              const PixelIcon(PixelGlyph.speakerLow,
                  size: 20, color: AppColors.textSecondary),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.accent,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: AppColors.accent,
                  ),
                  child: Slider(
                    key: sliderKey,
                    value: volume,
                    divisions: 10,
                    label: '${(volume * 100).round()}%',
                    onChanged: on ? onVolume : null,
                    onChangeEnd: on ? onVolumeDone : null,
                  ),
                ),
              ),
              const PixelIcon(PixelGlyph.speaker,
                  size: 20, color: AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}
