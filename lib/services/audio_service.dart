import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';

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
  static const double _bgmBaseVolume = 0.4;
  static const double _sfxBaseVolume = 1.0;

  /// How many players each sound effect keeps ready. A jump lasts well under a
  /// second, so a few are plenty; one asked for while all are busy is made on
  /// the spot and dropped afterwards (`AudioPool`), so nothing is ever skipped.
  static const int _poolSize = 3;

  /// Effects played often enough to be worth preparing before the level starts,
  /// so the first jump does not wait for a player to be built.
  static const List<String> _preloaded = [
    'jump.mp3',
    'coin.mp3',
    'player_hurt.mp3',
    'correct.mp3',
    'wrong.mp3',
    'enemy_defeat.mp3',
    'praise.wav',
    'land.wav',
    'step.wav',
    'tap.wav',
    'button.mp3',
  ];

  bool _soundEnabled = true;
  bool _musicEnabled = true;

  /// What the student set in Settings > Tunog, 0 to 1. It scales the base
  /// levels above, so "full" keeps music under the effects as before.
  double _musicVolume = 1.0;
  double _sfxVolume = 1.0;

  /// Deferred until the first real play call. Touching `FlameAudio.bgm` or
  /// `FlameAudio.audioCache` constructs an `AudioPlayer`, so doing it in the
  /// constructor would drag the plugin into every test that merely builds a
  /// `ChronoGame` (its `audioService` is a field initializer).
  bool _initialized = false;

  /// Effects use their own cache instead of `FlameAudio`'s global one, which
  /// keeps them off the `FlameAudio.bgm` player that touching it would build.
  final AudioCache _sfxCache = AudioCache(prefix: _assetPrefix);

  /// One pool of ready players per sound file, built on first use.
  final Map<String, Future<AudioPool>> _pools = {};

  /// Builds a pool for [file]. Replaceable so a test can count what is built
  /// without a platform plugin.
  @visibleForTesting
  Future<AudioPool> Function(String file) poolFactory = _newPool;

  /// Forgets every pool and goes back to the real builder.
  @visibleForTesting
  void resetSfxForTesting() {
    _pools.clear();
    poolFactory = _newPool;
  }

  /// Effects play over the music rather than pausing it, which is what
  /// `FlameAudio.play` did too.
  static final AudioContext _mixWithMusic =
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build();

  static Future<AudioPool> _newPool(String file) {
    final service = AudioService();
    return AudioPool.create(
      source: AssetSource(file),
      audioCache: service._sfxCache,
      audioContext: _mixWithMusic,
      minPlayers: 1,
      maxPlayers: _poolSize,
    );
  }

  /// The era whose BGM is currently loaded, so [toggleMusic] can resume the
  /// right track after being switched back on.
  String? _currentBgmEra;

  /// True from the moment the boss fight's music starts until any music stops.
  bool _bossMusic = false;

  /// Which boss phase's track is playing (1 to 3), so music switched off and on again mid-fight
  /// comes back as the same one.
  int _bossPhase = 1;

  /// The music track now playing and how loud it is next to the others (see [_trackGain]).
  double _currentGain = 1.0;

  /// The boss's music by phase: 1 an easy start, 2 the middle, 3 the most intense.
  static const List<String> _bossTracks = ['bgm_boss_1.mp3', 'bgm_boss_2.mp3', 'bgm_boss_3.mp3'];

  /// The tracks were made at different loudness (measured 2026-11-13: about -16 dB, -13 dB and
  /// -10 dB), so each is turned down to sit with the others. 1.0 is the base music level.
  static const Map<String, double> _trackGain = {
    'bgm_boss_1.mp3': 1.0,
    'bgm_boss_2.mp3': 0.7,
    'bgm_boss_3.mp3': 0.5,
    'bgm_victory.mp3': 0.75,
    'bgm_bonus.mp3': 0.85,
  };

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  /// Reads what Settings > Tunog saved. Called once at launch, after storage is
  /// open; without it (or in a test) everything is on at full volume.
  void loadSaved() {
    try {
      _soundEnabled = StorageService.getSoundEnabled();
      _musicEnabled = StorageService.getMusicEnabled();
      _sfxVolume = StorageService.getSoundVolume();
      _musicVolume = StorageService.getMusicVolume();
    } catch (e) {
      debugPrint('AudioService: no saved sound settings: $e');
    }
  }

  void _save(Future<void> Function() write) {
    // Fire and forget: a failed save must never get in the way of the game.
    try {
      write().catchError((Object _) {});
    } catch (_) {}
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    // Points the BGM player's cache at the music folder.
    FlameAudio.updatePrefix(_assetPrefix);
    // Registers the lifecycle observer that auto-pauses music when the app
    // is backgrounded and resumes it on return.
    await FlameAudio.bgm.initialize();
  }

  /// The pool for [file], built the first time it is asked for. A pool that
  /// failed to build is forgotten, so the next play tries again.
  Future<AudioPool> _poolFor(String file) async {
    try {
      return await (_pools[file] ??= poolFactory(file));
    } catch (_) {
      _pools.remove(file);
      rethrow;
    }
  }

  /// Gets the frequent effects ready, so no jump or coin has to build a player
  /// mid-level. Safe to call without waiting; failures are logged and the
  /// effect is built on its first play instead.
  Future<void> preloadSfx() async {
    for (final file in _preloaded) {
      try {
        await _poolFor(file);
      } catch (e) {
        debugPrint('AudioService: could not prepare $file: $e');
      }
    }
  }

  /// Plays an effect through its pool of reused players.
  ///
  /// `FlameAudio.play` made a brand-new `AudioPlayer` for every call and never
  /// disposed it. A level has hundreds of jumps and coin pickups, so players,
  /// their platform channels and their native sound handles piled up the longer
  /// a level ran. Phones got slower toward the end of a level (playtest report,
  /// two phones). A pool keeps a handful of players per sound and reuses them.
  Future<void> _playSfx(String file) async {
    if (!_soundEnabled || _sfxVolume <= 0) return;
    try {
      final pool = await _poolFor(file);
      await pool.start(volume: _sfxBaseVolume * _sfxVolume);
    } catch (e) {
      debugPrint('AudioService: failed to play $file: $e');
    }
  }

  void toggleSound() => setSoundEnabled(!_soundEnabled);

  void setSoundEnabled(bool on) {
    _soundEnabled = on;
    _save(() => StorageService.setSoundEnabled(on));
  }

  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0).toDouble();
    _save(() => StorageService.setSoundVolume(_sfxVolume));
  }

  /// Takes effect on the music that is playing now, not only the next track.
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0).toDouble();
    _save(() => StorageService.setMusicVolume(_musicVolume));
    if (_initialized) {
      try {
        FlameAudio.bgm.audioPlayer.setVolume(_bgmBaseVolume * _musicVolume * _currentGain);
      } catch (e) {
        debugPrint('AudioService: could not change music volume: $e');
      }
    }
  }

  void toggleMusic() => setMusicEnabled(!_musicEnabled);

  void setMusicEnabled(bool on) {
    if (on == _musicEnabled) return;
    _musicEnabled = on;
    _save(() => StorageService.setMusicEnabled(on));
    if (_musicEnabled) {
      final era = _currentBgmEra;
      if (_bossMusic) {
        playBossBgm(phase: _bossPhase);
      } else if (era != null) {
        playBgm(era);
      }
    } else {
      stopBgm();
    }
  }

  // ─── GAME SFX ─────────────────────────────────────────────────────────────
  Future<void> playJump() => _playSfx('jump.mp3');
  Future<void> playTeleport() => _playSfx('teleport.mp3');
  Future<void> playCorrect() => _playSfx('correct.mp3');

  /// The cheer after a correct answer (assets/sounds/praise.wav, made by
  /// tools/sfx/make_praise.js; drop a recording over it to change it).
  Future<void> playPraise() => _playSfx('praise.wav');
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

  // Placeholders made by tools/sfx/make_sfx.js; a recording with the same file
  // name dropped over one replaces it.
  Future<void> playLand() => _playSfx('land.wav');
  Future<void> playStep() => _playSfx('step.wav');
  Future<void> playTap() => _playSfx('button.mp3');
  Future<void> playArtifactGlow() => _playSfx('artifact.wav');
  Future<void> playGateRumble() => _playSfx('gate_rumble.wav');
  Future<void> playSplash() => _playSfx('splash.wav');
  Future<void> playHeart() => _playSfx('heart.wav');
  Future<void> playFlag() => _playSfx('flag.wav');
  Future<void> playShieldPop() => _playSfx('shield_pop.wav');
  Future<void> playStreak() => _playSfx('streak.wav');
  Future<void> playChaserNotice() => _playSfx('chaser_notice.wav');
  Future<void> playHeavyWindup() => _playSfx('heavy_windup.wav');
  Future<void> playLunge() => _playSfx('lunge.wav');
  Future<void> playBossWarning({bool short = false}) =>
      _playSfx(short ? 'boss_warning_short.wav' : 'boss_warning.wav');
  Future<void> playShockwave() => _playSfx('shockwave.wav');
  Future<void> playBossPhase() => _playSfx('boss_phase.wav');

  /// The chime for the boss about to ask a question. Made, but not played yet:
  /// it waits for the boss's question lead-in.
  Future<void> playBossAsk() => _playSfx('boss_ask.wav');

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
    _bossMusic = false;
    _currentGain = 1.0;
    if (!_musicEnabled) return;
    try {
      await _ensureInitialized();
      // Bgm.play releases whatever is already playing first, so switching
      // eras needs no explicit stop.
      await FlameAudio.bgm.play(
        'bgm_${_bgmAssetKeyForEra(eraId)}.mp3',
        volume: _bgmBaseVolume * _musicVolume,
      );
    } catch (e) {
      debugPrint('AudioService: failed to play BGM for $eraId: $e');
    }
  }

  /// The boss fight's own music, in place of the era's track until the level
  /// ends. [setMusicEnabled] brings the right one back if music is switched off
  /// and on again mid-fight.
  /// [phase] (1 to 3) picks the track: the fight gets more intense as it goes on.
  Future<void> playBossBgm({int phase = 1}) async {
    _bossMusic = true;
    _bossPhase = phase.clamp(1, _bossTracks.length);
    final file = _bossTracks[_bossPhase - 1];
    _currentGain = _trackGain[file] ?? 1.0;
    if (!_musicEnabled) return;
    try {
      await _ensureInitialized();
      await FlameAudio.bgm.play(
        file,
        volume: _bgmBaseVolume * _musicVolume * _currentGain,
      );
    } catch (e) {
      debugPrint('AudioService: failed to play the boss music: $e');
    }
  }

  /// The music of the era-complete screen, after the boss has fallen. It is not the era's own
  /// track and not the boss's, and it stops when the screen is left ([stopBgm]).
  Future<void> playVictoryBgm() => _playOneOff('bgm_victory.mp3');

  /// The music of the bonus round behind the golden portal. [playBgm] brings the era's own
  /// track back when the round is over.
  Future<void> playBonusBgm() => _playOneOff('bgm_bonus.mp3');

  Future<void> _playOneOff(String file) async {
    _bossMusic = false;
    _currentGain = _trackGain[file] ?? 1.0;
    if (!_musicEnabled) return;
    try {
      await _ensureInitialized();
      await FlameAudio.bgm.play(
        file,
        volume: _bgmBaseVolume * _musicVolume * _currentGain,
      );
    } catch (e) {
      debugPrint('AudioService: failed to play $file: $e');
    }
  }

  Future<void> stopBgm() async {
    _bossMusic = false;
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
