// Sound effects are played through a few reused players per sound, not a new
// player per play. The old code (`FlameAudio.play`) built an AudioPlayer for
// every jump and coin and never disposed it, so phones slowed down the longer a
// level ran. These tests pin that a level's worth of sounds builds a handful of
// pools and no more.
import 'package:chronoquest/services/audio_service.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePool implements AudioPool {
  int starts = 0;
  double? lastVolume;

  @override
  Future<StopFunction> start({double volume = 1.0}) async {
    starts++;
    lastVolume = volume;
    return () async {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AudioService audio;
  late Map<String, _FakePool> built;
  late List<String> buildOrder;

  setUp(() {
    audio = AudioService();
    built = {};
    buildOrder = [];
    audio.poolFactory = (file) async {
      buildOrder.add(file);
      return built.putIfAbsent(file, _FakePool.new);
    };
  });

  tearDown(() {
    // Back to the real builder and a clean slate for the next test.
    audio.resetSfxForTesting();
    if (!audio.soundEnabled) audio.toggleSound();
    audio.setSfxVolume(1.0);
  });

  test('a whole level of jumps builds one pool, not a player per jump', () async {
    for (var i = 0; i < 400; i++) {
      await audio.playJump();
    }
    expect(buildOrder, ['jump.mp3']);
    expect(built['jump.mp3']!.starts, 400);
  });

  test('each sound gets its own pool and every play reaches it', () async {
    for (var i = 0; i < 50; i++) {
      await audio.playJump();
      await audio.playCoin();
    }
    await audio.playHurt();
    expect(buildOrder.toSet(), {'jump.mp3', 'coin.mp3', 'player_hurt.mp3'});
    expect(buildOrder.length, 3, reason: 'one pool per sound');
    expect(built['jump.mp3']!.starts, 50);
    expect(built['coin.mp3']!.starts, 50);
    expect(built['player_hurt.mp3']!.starts, 1);
  });

  test('plays at full effect volume', () async {
    await audio.playCorrect();
    expect(built['correct.mp3']!.lastVolume, 1.0);
  });

  test('the volume set in Settings scales every effect', () async {
    audio.setSfxVolume(0.5);
    await audio.playCoin();
    expect(built['coin.mp3']!.lastVolume, 0.5);
  });

  test('volume at zero plays nothing, and out of range is clamped', () async {
    audio.setSfxVolume(0);
    await audio.playCoin();
    expect(buildOrder, isEmpty);

    audio.setSfxVolume(7);
    expect(audio.sfxVolume, 1.0);
    audio.setSfxVolume(-3);
    expect(audio.sfxVolume, 0.0);
  });

  test('plays at once even when two sounds are asked for together', () async {
    await Future.wait([audio.playJump(), audio.playJump(), audio.playJump()]);
    expect(buildOrder, ['jump.mp3'], reason: 'shared, not built three times');
    expect(built['jump.mp3']!.starts, 3);
  });

  test('preload gets the frequent sounds ready before the level starts', () async {
    await audio.preloadSfx();
    expect(
      buildOrder.toSet(),
      containsAll(['jump.mp3', 'coin.mp3', 'player_hurt.mp3']),
    );
    final before = buildOrder.length;
    await audio.playJump();
    expect(buildOrder.length, before, reason: 'already prepared');
  });

  test('with sound off nothing is built or played', () async {
    audio.toggleSound();
    await audio.playJump();
    expect(buildOrder, isEmpty);
  });

  test('a pool that fails to build is tried again on the next play', () async {
    var attempts = 0;
    audio.poolFactory = (file) async {
      attempts++;
      if (attempts == 1) throw StateError('no audio device');
      return built.putIfAbsent(file, _FakePool.new);
    };

    await audio.playJump(); // fails quietly: audio never breaks gameplay
    expect(built, isEmpty);

    await audio.playJump();
    expect(built['jump.mp3']!.starts, 1);
    expect(attempts, 2);
  });
}
