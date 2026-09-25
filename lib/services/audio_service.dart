import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Plays the game's bundled music and sound effects through `flame_audio`.
///
/// Every method is fire-and-forget and swallows its own failures: audio is
/// never worth crashing gameplay over, and the plugin's platform channel is
/// simply absent in a plain `flutter test` environment (the game's own tests
/// deliberately avoid `ChronoGame.onLoad()` for this reason). Same defensive
/// pattern the parallax and player sprite loaders already use.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  /// Where the bundled audio lives. `flame_audio` defaults to
  /// `assets/audio/`, but this project's pubspec declares `assets/sounds/`.
  static const String _assetPrefix = 'assets/sounds/';

  /// Music sits under the effects so answer/hurt cues stay audible over it.
  static const double _bgmVolume = 0.4;
  static const double _sfxVolume = 1.0;

  bool _soundEnabled = true;
  bool _musicEnabled = true;

  /// Deferred until the first real play call. Touching `FlameAudio.bgm` or
  /// `FlameAudio.audioCache` constructs an `AudioPlayer`, so doing it in the
  /// constructor would drag the plugin into every test that merely builds a
  /// `ChronoGame` (its `audioService` is a field initializer).
  bool _initialized = false;

  /// The era whose BGM is currently loaded, so [toggleMusic] can resume the
  /// right track after being switched back on.
  String? _currentBgmEra;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    // Updates the prefix on both the shared cache and the BGM player's own
    // cache — the one call covers music and effects.
    FlameAudio.updatePrefix(_assetPrefix);
    // Registers the lifecycle observer that auto-pauses music when the app
    // is backgrounded and resumes it on return.
    await FlameAudio.bgm.initialize();
  }

  Future<void> _playSfx(String file) async {
    if (!_soundEnabled) return;
    try {
      await _ensureInitialized();
      await FlameAudio.play(file, volume: _sfxVolume);
    } catch (e) {
      debugPrint('AudioService: failed to play $file: $e');
    }
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
  }

  void toggleMusic() {
    _musicEnabled = !_musicEnabled;
    if (_musicEnabled) {
      final era = _currentBgmEra;
      if (era != null) playBgm(era);
    } else {
      stopBgm();
    }
  }

  // ─── GAME SFX ─────────────────────────────────────────────────────────────
  Future<void> playJump() => _playSfx('jump.mp3');
  Future<void> playCorrect() => _playSfx('correct.mp3');
  Future<void> playWrong() => _playSfx('wrong.mp3');
  Future<void> playCoin() => _playSfx('coin.mp3');
  Future<void> playHurt() => _playSfx('player_hurt.mp3');
  Future<void> playEnemyDefeat() => _playSfx('enemy_defeat.mp3');
  Future<void> playPowerup() => _playSfx('powerup.mp3');
  Future<void> playLevelComplete() => _playSfx('level_complete.mp3');
  Future<void> playLevelFailed() => _playSfx('level_failed.mp3');
  Future<void> playBossAppear() => _playSfx('boss_appear.mp3');
  Future<void> playBossDefeat() => _playSfx('boss_defeat.mp3');
  Future<void> playEraComplete() => _playSfx('era_complete.mp3');

  // ─── BACKGROUND MUSIC ─────────────────────────────────────────────────────

  /// Music files drop the hyphen used in era ids (`bgm_precolonial.mp3` for
  /// the `pre-colonial` era) — the same naming mismatch `WallComponent`
  /// handles for obstacle art, fixed the same way here. There is no
  /// `bgm_nationalism.mp3` yet (Era 3 has no BGM of its own), so it reuses
  /// the Spanish era's track, matching the art/enemy/boss reuse elsewhere.
  String _bgmAssetKeyForEra(String eraId) {
    if (eraId == 'pre-colonial') return 'precolonial';
    if (eraId == 'nationalism') return 'spanish';
    return eraId;
  }

  Future<void> playBgm(String eraId) async {
    _currentBgmEra = eraId;
    if (!_musicEnabled) return;
    try {
      await _ensureInitialized();
      // Bgm.play releases whatever is already playing first, so switching
      // eras needs no explicit stop.
      await FlameAudio.bgm.play(
        'bgm_${_bgmAssetKeyForEra(eraId)}.mp3',
        volume: _bgmVolume,
      );
    } catch (e) {
      debugPrint('AudioService: failed to play BGM for $eraId: $e');
    }
  }

  Future<void> stopBgm() async {
    if (!_initialized) return;
    try {
      await FlameAudio.bgm.stop();
    } catch (e) {
      debugPrint('AudioService: failed to stop BGM: $e');
    }
  }

  /// Stops music without tearing down the shared `FlameAudio.bgm` player —
  /// this is a singleton that outlives any one level, so disposing its
  /// underlying player would silence every level after the first.
  Future<void> dispose() => stopBgm();
}
