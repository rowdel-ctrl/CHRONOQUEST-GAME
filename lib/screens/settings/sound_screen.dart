import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../services/audio_service.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/pixel_icon.dart';
import 'settings_header.dart';

/// Tunog: music and sound effects side by side (one above the other on a narrow
/// phone). Each has one big ON/OFF button, a meter of ten chunky blocks between a
/// big minus and a big plus, the volume as a large percentage, and (for the sound
/// effects) a PAKINGGAN button to hear the level. Changes apply at once (music that
/// is playing gets quieter as the meter moves) and are saved on this device.
class SoundScreen extends StatefulWidget {
  /// Replaceable so a test does not need the audio plugin.
  final AudioService? audio;
  const SoundScreen({super.key, this.audio});

  /// The big ON/OFF buttons.
  static const Key musicSwitchKey = Key('sound_music_switch');
  static const Key sfxSwitchKey = Key('sound_sfx_switch');

  /// The meters: tap a block (or drag along it) to set the volume.
  static const Key musicSliderKey = Key('sound_music_slider');
  static const Key sfxSliderKey = Key('sound_sfx_slider');

  static const Key musicMinusKey = Key('sound_music_minus');
  static const Key musicPlusKey = Key('sound_music_plus');
  static const Key sfxMinusKey = Key('sound_sfx_minus');
  static const Key sfxPlusKey = Key('sound_sfx_plus');
  static const Key musicPercentKey = Key('sound_music_percent');
  static const Key sfxPercentKey = Key('sound_sfx_percent');

  /// Plays a short sound at the chosen level. Music has none: there is no short
  /// music sample, and playing a track would cut in on the level's own music.
  static const Key sfxPreviewKey = Key('sound_sfx_preview');

  @override
  State<SoundScreen> createState() => _SoundScreenState();
}

class _SoundScreenState extends State<SoundScreen> {
  late final AudioService _audio = widget.audio ?? AudioService();

  @override
  Widget build(BuildContext context) {
    final music = _VolumePanel(
      icon: PixelGlyph.note,
      title: 'MUSIKA',
      note: 'Tugtog habang naglalaro',
      on: _audio.musicEnabled,
      volume: _audio.musicVolume,
      switchKey: SoundScreen.musicSwitchKey,
      meterKey: SoundScreen.musicSliderKey,
      minusKey: SoundScreen.musicMinusKey,
      plusKey: SoundScreen.musicPlusKey,
      percentKey: SoundScreen.musicPercentKey,
      onSwitch: (v) => setState(() => _audio.setMusicEnabled(v)),
      onVolume: (v) => setState(() => _audio.setMusicVolume(v)),
    );
    final sfx = _VolumePanel(
      icon: PixelGlyph.speaker,
      title: 'SOUND EFFECTS',
      note: 'Talon, barya at atake',
      on: _audio.soundEnabled,
      volume: _audio.sfxVolume,
      switchKey: SoundScreen.sfxSwitchKey,
      meterKey: SoundScreen.sfxSliderKey,
      minusKey: SoundScreen.sfxMinusKey,
      plusKey: SoundScreen.sfxPlusKey,
      percentKey: SoundScreen.sfxPercentKey,
      onSwitch: (v) => setState(() => _audio.setSoundEnabled(v)),
      onVolume: (v) => setState(() => _audio.setSfxVolume(v)),
      // Let them hear the new level once they have set it.
      onVolumeDone: () => _audio.playCoin(),
      previewKey: SoundScreen.sfxPreviewKey,
      onPreview: () => _audio.playCoin(),
    );
    return Scaffold(
      body: GameBackdrop(
        baseColor: AppColors.background,
        child: SafeArea(
          child: Column(
            children: [
              const SettingsHeader(title: 'TUNOG'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 780),
                      child: Column(
                        children: [
                          if (MediaQuery.sizeOf(context).width >= 560)
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: music),
                                  const SizedBox(width: 18),
                                  Expanded(child: sfx),
                                ],
                              ),
                            )
                          else ...[
                            music,
                            const SizedBox(height: 16),
                            sfx,
                          ],
                          const SizedBox(height: 14),
                          Text(
                            'Saved na sa device na ito.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFFC9BEDB),
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

const Color _ink = AppColors.primaryDark;
const Color _litTop = Color(0xFFFFD65C);
const Color _litBottom = Color(0xFFE0A52B);
const Color _unlit = Color(0xFFCDB88C);
const Color _on = Color(0xFF43A83E);
const Color _off = Color(0xFF5A5068);

/// One sound: its name and ON/OFF, the ten-block meter with minus and plus, the
/// volume as a big percentage, and (when [onPreview] is given) PAKINGGAN.
class _VolumePanel extends StatelessWidget {
  final PixelGlyph icon;
  final String title;
  final String note;
  final bool on;
  final double volume;
  final Key switchKey;
  final Key meterKey;
  final Key minusKey;
  final Key plusKey;
  final Key percentKey;
  final ValueChanged<bool> onSwitch;
  final ValueChanged<double> onVolume;

  /// After a tap, a minus or plus, or the end of a drag.
  final VoidCallback? onVolumeDone;
  final Key? previewKey;
  final VoidCallback? onPreview;

  const _VolumePanel({
    required this.icon,
    required this.title,
    required this.note,
    required this.on,
    required this.volume,
    required this.switchKey,
    required this.meterKey,
    required this.minusKey,
    required this.plusKey,
    required this.percentKey,
    required this.onSwitch,
    required this.onVolume,
    this.onVolumeDone,
    this.previewKey,
    this.onPreview,
  });

  int get _blocks => (volume * 10).round().clamp(0, 10);

  void _set(int n) => onVolume(n.clamp(0, 10) / 10);

  void _step(int by) {
    _set(_blocks + by);
    onVolumeDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final percent = on ? _blocks * 10 : 0;
    return GamePanel(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MenuChipFace(icon: on ? icon : PixelGlyph.speakerOff, size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        height: 1.3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _Chunk(
                key: switchKey,
                width: 74,
                height: 40,
                color: on ? _on : _off,
                semanticsLabel: '$title, ${on ? 'naka-on' : 'naka-off'}',
                toggled: on,
                onTap: () => onSwitch(!on),
                child: Text(
                  on ? 'ON' : 'OFF',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color:
                        on ? const Color(0xFF0E2A0C) : const Color(0xFFE9E2F2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Dim and dead while it is off.
          IgnorePointer(
            ignoring: !on,
            child: Opacity(
              opacity: on ? 1 : 0.4,
              child: Row(
                children: [
                  _Chunk(
                    key: minusKey,
                    width: 44,
                    height: 44,
                    color: AppColors.primary,
                    semanticsLabel: 'Hinaan ang $title',
                    onTap: () => _step(-1),
                    child: const _Sign(plus: false),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Meter(
                      key: meterKey,
                      title: title,
                      lit: _blocks,
                      onSet: _set,
                      onEnd: onVolumeDone,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Chunk(
                    key: plusKey,
                    width: 44,
                    height: 44,
                    color: AppColors.primary,
                    semanticsLabel: 'Lakasan ang $title',
                    onTap: () => _step(1),
                    child: const _Sign(plus: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Semantics(
                  label: '$title, $percent porsyento',
                  child: ExcludeSemantics(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Text.rich(
                        key: percentKey,
                        TextSpan(
                          text: '$percent',
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: on
                                ? AppColors.textPrimary
                                : const Color(0xFF8E7A5A),
                          ),
                          children: [
                            TextSpan(
                              text: '%',
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (onPreview != null)
                _Chunk(
                  key: previewKey,
                  height: 40,
                  color: on ? AppColors.accent : _off,
                  semanticsLabel: 'Pakinggan ang $title',
                  onTap: on ? onPreview : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'PAKINGGAN',
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w700,
                        color: on ? _ink : const Color(0xFFE9E2F2),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }
}

/// The ten blocks. A tap on a block lights up to it; a drag along them follows the
/// finger (past the left edge is 0). Nothing here is a thin target.
class _Meter extends StatelessWidget {
  final String title;
  final int lit;
  final ValueChanged<int> onSet;
  final VoidCallback? onEnd;

  const _Meter({
    super.key,
    required this.title,
    required this.lit,
    required this.onSet,
    this.onEnd,
  });

  void _at(BuildContext context, double dx) {
    final width = (context.findRenderObject() as RenderBox).size.width;
    if (width <= 0) return;
    onSet((dx / width * 10).ceil().clamp(0, 10));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      slider: true,
      label: title,
      value: '${lit * 10}%',
      increasedValue: '${(lit + 1).clamp(0, 10) * 10}%',
      decreasedValue: '${(lit - 1).clamp(0, 10) * 10}%',
      onIncrease: lit < 10
          ? () {
              onSet(lit + 1);
              onEnd?.call();
            }
          : null,
      onDecrease: lit > 0
          ? () {
              onSet(lit - 1);
              onEnd?.call();
            }
          : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _at(context, d.localPosition.dx),
          onTap: onEnd,
          onHorizontalDragStart: (d) => _at(context, d.localPosition.dx),
          onHorizontalDragUpdate: (d) => _at(context, d.localPosition.dx),
          onHorizontalDragEnd: (_) => onEnd?.call(),
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                for (var i = 0; i < 10; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Align(
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _ink, width: 2),
                          gradient: i < lit
                              ? const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [_litTop, _litBottom],
                                )
                              : null,
                          color: i < lit ? null : _unlit,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A big minus or plus drawn with two bars.
class _Sign extends StatelessWidget {
  final bool plus;
  const _Sign({required this.plus});

  @override
  Widget build(BuildContext context) {
    const bar = BoxDecoration(
      color: AppColors.accent,
      borderRadius: BorderRadius.all(Radius.circular(1)),
    );
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 18, height: 5, decoration: bar),
          if (plus) Container(width: 5, height: 18, decoration: bar),
        ],
      ),
    );
  }
}

/// The chunky button of this screen: flat fill, dark border, a hard shadow that
/// presses in. It is quiet (no tap sound): the sound buttons are the ones that
/// decide what is heard. [onTap] null makes it dim and dead.
class _Chunk extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final double? width;
  final double height;
  final String semanticsLabel;
  final bool? toggled;

  const _Chunk({
    super.key,
    required this.child,
    required this.onTap,
    required this.color,
    required this.semanticsLabel,
    required this.height,
    this.width,
    this.toggled,
  });

  @override
  State<_Chunk> createState() => _ChunkState();
}

class _ChunkState extends State<_Chunk> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      toggled: widget.toggled,
      label: widget.semanticsLabel,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapUp: (_) => setState(() => _down = false),
          onTapCancel: () => setState(() => _down = false),
          onTap: widget.onTap,
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: Transform.translate(
              offset: _down ? const Offset(0, 3) : Offset.zero,
              child: Container(
                width: widget.width,
                height: widget.height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _ink, width: 3),
                  boxShadow: _down
                      ? null
                      : const [BoxShadow(color: _ink, offset: Offset(0, 3))],
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
