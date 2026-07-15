/// Stub audio service — plays no audio but provides the same API.
/// Replace with a real implementation (e.g. flame_audio) when audio assets
/// are ready and the audioplayers Kotlin compatibility issue is resolved.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool _soundEnabled = true;
  bool _musicEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
  }

  void toggleMusic() {
    _musicEnabled = !_musicEnabled;
  }

  // ─── GAME SFX (stubs) ─────────────────────────────────────────────────────
  Future<void> playJump() async {}
  Future<void> playCorrect() async {}
  Future<void> playWrong() async {}
  Future<void> playCoin() async {}
  Future<void> playHurt() async {}
  Future<void> playEnemyDefeat() async {}
  Future<void> playPowerup() async {}
  Future<void> playLevelComplete() async {}
  Future<void> playLevelFailed() async {}
  Future<void> playBossAppear() async {}
  Future<void> playBossDefeat() async {}
  Future<void> playEraComplete() async {}

  // ─── BACKGROUND MUSIC (stub) ──────────────────────────────────────────────
  Future<void> playBgm(String eraId) async {}
  Future<void> stopBgm() async {}
  Future<void> dispose() async {}
}
