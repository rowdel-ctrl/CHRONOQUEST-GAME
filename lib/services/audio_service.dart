import 'dart:io' show Platform;

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
    _nextWarningAt = DateTime.fromMillisecondsSinceEpoch(0);
    warningClock = DateTime.now;
    warningWait = Future<void>.delayed;
  }

  /// Effects play over the music rather than pausing it, which is what
  /// `FlameAudio.play` did too.
  static final AudioContext _mixWithMusic =
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build();

  /// True while `flutter test` runs: there is no sound plugin then, and a screen that plays a
  /// sound (a tap, the lobby music) must not fail a test that has nothing to do with sound. A
  /// test that wants to watch the sound sets [poolFactory], [musicStarter] and [musicStopper].
  static bool get _underFlutterTest => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  static Future<AudioPool> _newPool(String file) {
    if (_underFlutterTest) return Future<AudioPool>.value(_SilentPool());
    final service = AudioService();
    return AudioPool.create(
      source: AssetSource(file),
      audioCache: service._sfxCache,
      audioContext: _mixWithMusic,
      minPlayers: 1,
      maxPlayers: _poolSize,
    );
  }

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
    'bgm_lobby.wav': 0.8,
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
      final stop = await pool.start(volume: _sfxBaseVolume * _sfxVolume);
      if (_celebrationFiles.contains(file)) _celebrationStops.add(stop);
    } catch (e) {
      debugPrint('AudioService: failed to play $file: $e');
    }
  }

  /// The long "success" sounds (a level or era complete, a boss down). They are sound effects, so
  /// the music commands do not reach them: one that was still playing when the student went on
  /// to the menus went on playing there ([stopCelebration] stops them).
  static const Set<String> _celebrationFiles = {
    'level_complete.mp3',
    'era_complete.mp3',
    'boss_win.wav',
  };
  final List<StopFunction> _celebrationStops = [];

  /// Stops any success sound that is still playing. A screen that is being left, and the lobby
  /// music starting, call this.
  Future<void> stopCelebration() async {
    final stops = List<StopFunction>.of(_celebrationStops);
    _celebrationStops.clear();
    for (final stop in stops) {
      try {
        await stop();
      } catch (_) {}
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
        FlameAudio.bgm.audioPlayer.setVolume(_bgmBaseVolume * _musicVolume * _currentGain * _duck);
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
      // Only a screen that owns music brings it back: switching music on in Settings, on a
      // menu, must not start the track of a level that is long over.
      _resumeMusic?.call();
    } else {
      _stopPlayer(); // the track is remembered, so switching back on restores it
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
  Future<void> playChaserNotice() => _playWarning('chaser_notice.wav');
  Future<void> playHeavyWindup() => _playWarning('heavy_windup.wav');
  Future<void> playLunge() => _playSfx('lunge.wav');

  // ─── Surprises (2026-11-16). The sounds that warn of something about to happen
  // (a windup, a crack opening, a rock's ticks, a throw's whirl, a spotted cue) go
  // through [_playWarning], so two of them never pile up. ─────────────────────────
  Future<void> playHopper() => _playWarning('hopper.wav');
  Future<void> playGroundPop() => _playWarning('ground_pop.wav');
  Future<void> playRockWarn() => _playWarning('rock_warn.wav');
  Future<void> playRockCrash() => _playSfx('rock_crash.wav');
  Future<void> playThrowWindup() => _playWarning('throw_windup.wav');
  Future<void> playThrowFly() => _playSfx('throw_fly.wav');
  Future<void> playGoldenRun() => _playWarning('golden_run.wav');

  /// The heroes that have an attack sound (`attack_<id>.wav`, one per hero, made to suit
  /// how they attack). A hero without one, a new hero for example, is silent.
  static const Set<String> heroesWithAttackSound = {
    'boy',
    'girl',
    'delpilar',
    'lapu',
    'bonifacio',
    'luna',
    'mariaclara',
    'rizal',
  };

  /// The sound of [heroId]'s attack, played the moment the attack starts.
  Future<void> playHeroAttack(String heroId) async {
    if (!heroesWithAttackSound.contains(heroId)) return;
    await _playSfx('attack_$heroId.wav');
  }

  /// Warning sounds never start closer together than this. One that is due sooner waits
  /// its turn, so a windup, a crack and a "spotted you" cue are heard one after another
  /// and not as one loud lump.
  static const Duration warningGap = Duration(milliseconds: 400);

  /// A warning that would have to wait longer than this is dropped: the moment has passed.
  static const Duration warningMaxWait = Duration(milliseconds: 900);

  DateTime _nextWarningAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// The clock and the wait the warning rule uses. Replaceable so a test needs no real time.
  @visibleForTesting
  DateTime Function() warningClock = DateTime.now;
  @visibleForTesting
  Future<void> Function(Duration) warningWait = Future<void>.delayed;

  Future<void> _playWarning(String file) async {
    if (!_soundEnabled || _sfxVolume <= 0) return;
    final now = warningClock();
    final start = _nextWarningAt.isAfter(now) ? _nextWarningAt : now;
    final wait = start.difference(now);
    if (wait > warningMaxWait) return;
    _nextWarningAt = start.add(warningGap);
    if (wait > Duration.zero) await warningWait(wait);
    await _playSfx(file);
  }
  Future<void> playBossWarning({bool short = false}) =>
      _playSfx(short ? 'boss_warning_short.wav' : 'boss_warning.wav');
  Future<void> playShockwave() => _playSfx('shockwave.wav');
  Future<void> playBossPhase() => _playSfx('boss_phase.wav');

  /// The chime for the boss about to ask a question. Made, but not played yet:
  /// it waits for the boss's question lead-in.
  Future<void> playBossAsk() => _playSfx('boss_ask.wav');

  // ─── THE ERA BOOKS, THE CHAIN BREAK, THE BOSS DEFEAT ─────────────────────
  // Made by tools/sfx/make_book_sfx.js.
  Future<void> playBookSlide() => _playSfx('book_slide.wav');
  Future<void> playBookOpen() => _playSfx('book_open.wav');
  Future<void> playBookClose() => _playSfx('book_close.wav');
  Future<void> playBookLocked() => _playSfx('book_locked.wav');
  Future<void> playChainStrain() => _playSfx('chain_strain.wav');
  Future<void> playChainUnlock() => _playSfx('chain_unlock.wav');
  Future<void> playBookReveal() => _playSfx('book_reveal.wav');
  Future<void> playBossRumble() => _playSfx('boss_rumble.wav');
  Future<void> playBossBoom() => _playSfx('boss_boom.wav');
  Future<void> playBossClatter() => _playSfx('boss_clatter.wav');
  Future<void> playBossMedal() => _playSfx('boss_medal.wav');
  Future<void> playBossWin() => _playSfx('boss_win.wav');

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
    _currentGain = 1.0;
    _resumeMusic = () => playBgm(eraId);
    if (!_musicEnabled) return;
    await _startTrack('bgm_${_bgmAssetKeyForEra(eraId)}.mp3', 1.0);
  }

  /// The boss fight's own music, in place of the era's track until the level
  /// ends. [setMusicEnabled] brings the right one back if music is switched off
  /// and on again mid-fight.
  /// [phase] (1 to 3) picks the track: the fight gets more intense as it goes on.
  Future<void> playBossBgm({int phase = 1}) async {
    _bossPhase = phase.clamp(1, _bossTracks.length);
    final file = _bossTracks[_bossPhase - 1];
    _currentGain = _trackGain[file] ?? 1.0;
    final again = _bossPhase;
    _resumeMusic = () => playBossBgm(phase: again);
    if (!_musicEnabled) return;
    await _startTrack(file, _currentGain);
  }

  /// The music of the era-complete screen, after the boss has fallen. It is not the era's own
  /// track and not the boss's, and it stops when the screen is left ([stopBgm]).
  Future<void> playVictoryBgm() => _playOneOff('bgm_victory.mp3');

  /// The file of the lobby music: the menus (hero choice, the era books, the level map, the
  /// shop, the profile). Every menu screen asks for it, and asking while it already plays does
  /// nothing, so it does not start over when the student moves from one menu to the next. A
  /// level's own music takes its place when a level starts ([playBgm]).
  static const String lobbyTrack = 'bgm_lobby.wav';

  Future<void> playLobbyBgm() async {
    stopCelebration(); // a success sound from the screen before must not play on into the menus
    _resumeMusic = playLobbyBgm; // switching music on in Settings brings it back
    if (!_musicEnabled) return;
    if (_playingFile == lobbyTrack) return;
    _currentGain = _trackGain[lobbyTrack] ?? 1.0;
    await _startTrack(lobbyTrack, _currentGain);
  }

  /// Whether the lobby music is the track that is playing (or about to).
  bool get lobbyPlaying => _playingFile == lobbyTrack;

  /// How much quieter the music is made while something big plays over it (the chain break).
  double _duck = 1.0;

  /// Turns the music down to [factor] (0 to 1) of its level, or back up with 1. It lasts until
  /// it is called again.
  Future<void> duckMusic(double factor) async {
    _duck = factor.clamp(0.0, 1.0).toDouble();
    if (!_initialized || !_musicUsed) return;
    try {
      await FlameAudio.bgm.audioPlayer.setVolume(_bgmBaseVolume * _musicVolume * _currentGain * _duck);
    } catch (e) {
      debugPrint('AudioService: could not duck the music: $e');
    }
  }

  /// The music of the bonus round behind the golden portal. [playBgm] brings the era's own
  /// track back when the round is over.
  Future<void> playBonusBgm() => _playOneOff('bgm_bonus.mp3');

  Future<void> _playOneOff(String file) async {
    _currentGain = _trackGain[file] ?? 1.0;
    _resumeMusic = () => _playOneOff(file);
    if (!_musicEnabled) return;
    await _startTrack(file, _currentGain);
  }

  // ─── MUSIC COMMANDS, ONE AT A TIME ─────────────────────────────────────────
  // Starting a track is several awaited steps inside `FlameAudio.bgm` (release, source,
  // resume). A stop that arrived in the middle of them was lost, and the track then started
  // and played on over the menus (a finished level's music did not stop). So every music
  // command goes through one queue and runs only when the one before it is done.

  /// What brings the current track back after music was switched off and on in Settings.
  /// Null when no screen owns music (after [stopBgm]), so switching it on in a menu starts nothing.
  Future<void> Function()? _resumeMusic;

  Future<void> _musicQueue = Future<void>.value();

  /// Whether a track was ever started (so there is a player to stop).
  bool _musicUsed = false;

  /// The file of the track that is playing or has been asked for; null once stopped.
  String? _playingFile;

  /// Counts commands, so a start that is still waiting when a newer one (or a stop) is
  /// asked for can see it is out of date and not start.
  int _musicStamp = 0;

  /// Starts and stops the music player. Replaceable so a test can watch the order.
  @visibleForTesting
  Future<void> Function(String file, double volume) musicStarter = _startPlayer;
  @visibleForTesting
  Future<void> Function() musicStopper = _stopPlayerNow;

  static Future<void> _startPlayer(String file, double volume) async {
    if (_underFlutterTest) return;
    await AudioService()._ensureInitialized();
    await FlameAudio.bgm.play(file, volume: volume);
  }
  static Future<void> _stopPlayerNow() => _underFlutterTest ? Future<void>.value() : FlameAudio.bgm.stop();

  /// Forgets the music state and goes back to the real player, for a test.
  @visibleForTesting
  void resetMusicForTesting() {
    musicStarter = _startPlayer;
    musicStopper = _stopPlayerNow;
    _resumeMusic = null;
    _playingFile = null;
    _duck = 1.0;
    _musicUsed = false;
    _musicStamp = 0;
    _musicQueue = Future<void>.value();
    _musicEnabled = true;
  }

  Future<void> _queueMusic(Future<void> Function() job) {
    final next = _musicQueue.then((_) => job()).catchError((Object e) {
      debugPrint('AudioService: music command failed: $e');
    });
    _musicQueue = next;
    return next;
  }

  Future<void> _startTrack(String file, double gain) {
    final stamp = ++_musicStamp;
    final volume = _bgmBaseVolume * _musicVolume * gain * _duck;
    _playingFile = file;
    return _queueMusic(() async {
      if (stamp != _musicStamp) return; // a newer command replaced this one
      _musicUsed = true;
      // Bgm.play releases whatever is already playing first, so changing track needs no stop.
      await musicStarter(file, volume);
    });
  }

  /// Stops the player but keeps what to bring back ([_resumeMusic]).
  Future<void> _stopPlayer() {
    _musicStamp++;
    _playingFile = null;
    return _queueMusic(() async {
      if (!_musicUsed) return; // nothing was ever started
      await musicStopper();
    });
  }

  /// Stops the music only if [file] is the track that is playing. A screen that is being left
  /// after the next screen has already started its own music (go_router builds the new page
  /// first and removes the old one after the transition) must not cut that music off.
  Future<void> stopBgmIf(String file) {
    if (_playingFile != file) return Future<void>.value();
    return stopBgm();
  }

  /// Stops the music for good: a screen that is being left calls this, and nothing is brought
  /// back by switching music on afterwards.
  Future<void> stopBgm() {
    _resumeMusic = null;
    return _stopPlayer();
  }

  /// Stops music without tearing down the shared `FlameAudio.bgm` player —
  /// this is a singleton that outlives any one level, so disposing its
  /// underlying player would silence every level after the first.
  Future<void> dispose() => stopBgm();
}

/// A pool that plays nothing, for `flutter test`.
class _SilentPool implements AudioPool {
  @override
  Future<StopFunction> start({double volume = 1.0}) async => () async {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
