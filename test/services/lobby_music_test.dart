// The lobby music plays in the menus (hero choice, the era books, the level map, the shop, the
// profile). Every menu asks for it and asking while it plays does nothing, so it does not start
// over between menus; a level's own music takes its place, and the reading screens are silent.
// It follows Settings > Tunog, and goes quiet for a moment while the chain break plays.
import 'dart:io';

import 'package:chronoquest/services/audio_service.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Pool implements AudioPool {
  final List<String> log;
  final String file;
  _Pool(this.log, this.file);
  @override
  Future<StopFunction> start({double volume = 1.0}) async {
    log.add('$file @${volume.toStringAsFixed(2)}');
    return () async {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AudioService audio;
  late List<String> events;

  setUp(() {
    audio = AudioService()..resetMusicForTesting();
    events = [];
    audio.musicStarter = (file, volume) async =>
        events.add('start $file ${volume.toStringAsFixed(3)}');
    audio.musicStopper = () async => events.add('stop');
  });

  tearDown(() => audio.resetMusicForTesting());

  test(
      'the lobby music starts once, and asking again while it plays does nothing',
      () async {
    await audio.playLobbyBgm();
    await audio.playLobbyBgm();
    await audio.playLobbyBgm();
    expect(events.where((e) => e.startsWith('start')), hasLength(1));
    expect(events.single, startsWith('start bgm_lobby.wav'));
    expect(audio.lobbyPlaying, isTrue);
  });

  test(
      "a level's music takes its place, and the lobby comes back when a menu asks for it",
      () async {
    await audio.playLobbyBgm();
    await audio.playBgm('spanish');
    expect(audio.lobbyPlaying, isFalse);
    await audio.playLobbyBgm();
    expect(
        events.where((e) => e.startsWith('start')).map((e) => e.split(' ')[1]),
        ['bgm_lobby.wav', 'bgm_spanish.mp3', 'bgm_lobby.wav']);
  });

  test(
      'a reading screen stops it for good, and it starts again when the next menu asks',
      () async {
    await audio.playLobbyBgm();
    await audio.stopBgm();
    expect(audio.lobbyPlaying, isFalse);
    expect(events.last, 'stop');
    await audio.playLobbyBgm();
    expect(events.where((e) => e.startsWith('start')), hasLength(2));
  });

  test(
      'with music off nothing starts, and switching it on in Settings brings the lobby back',
      () async {
    audio.setMusicEnabled(false);
    await audio.playLobbyBgm();
    expect(events.where((e) => e.startsWith('start')), isEmpty);
    audio.setMusicEnabled(true);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(events.where((e) => e.startsWith('start')), hasLength(1));
    expect(events.last, startsWith('start bgm_lobby.wav'));
  });

  test(
      'switching music off in Settings stops it, and on again restarts it (it is not "playing" while off)',
      () async {
    await audio.playLobbyBgm();
    audio.setMusicEnabled(false);
    await Future<void>.delayed(Duration.zero);
    expect(audio.lobbyPlaying, isFalse);
    audio.setMusicEnabled(true);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(events.where((e) => e.startsWith('start')), hasLength(2));
  });

  test(
      'the lobby is turned down a little next to the era music, and ducking scales the next start',
      () async {
    await audio.playLobbyBgm();
    // 0.4 base * 1.0 music * 0.8 gain
    expect(events.single, 'start bgm_lobby.wav 0.320');
    await audio.stopBgm();
    events.clear();
    await audio.duckMusic(0.3);
    await audio.playLobbyBgm();
    expect(events.single, 'start bgm_lobby.wav 0.096');
    await audio.duckMusic(1.0);
  });

  test('the new sounds are played from their own files', () async {
    final played = <String>[];
    audio.poolFactory = (file) async => _Pool(played, file);
    await audio.playBookSlide();
    await audio.playBookOpen();
    await audio.playBookClose();
    await audio.playBookLocked();
    await audio.playChainStrain();
    await audio.playChainUnlock();
    await audio.playBookReveal();
    await audio.playBossRumble();
    await audio.playBossBoom();
    await audio.playBossClatter();
    await audio.playBossMedal();
    await audio.playBossWin();
    expect(played.map((e) => e.split(' ').first), [
      'book_slide.wav',
      'book_open.wav',
      'book_close.wav',
      'book_locked.wav',
      'chain_strain.wav',
      'chain_unlock.wav',
      'book_reveal.wav',
      'boss_rumble.wav',
      'boss_boom.wav',
      'boss_clatter.wav',
      'boss_medal.wav',
      'boss_win.wav',
    ]);
  });

  test(
      'every one of those sounds, and the lobby music, is a real file in the game',
      () {
    for (final name in [
      'book_slide',
      'book_open',
      'book_close',
      'book_locked',
      'chain_strain',
      'chain_unlock',
      'book_reveal',
      'boss_rumble',
      'boss_boom',
      'boss_clatter',
      'boss_medal',
      'boss_win',
      'bgm_lobby',
    ]) {
      final file = File('assets/sounds/$name.wav');
      expect(file.existsSync(), isTrue,
          reason:
              '$name.wav is missing (node tools/sfx/make_book_sfx.js makes it)');
      final bytes = file.readAsBytesSync();
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF',
          reason: '$name.wav is a WAV file');
      expect(bytes.length, greaterThan(10000),
          reason: '$name.wav has sound in it');
    }
    // The lobby music is a loop of about twenty seconds.
    final lobby = File('assets/sounds/bgm_lobby.wav').readAsBytesSync();
    expect(lobby.length, inInclusiveRange(600000, 1500000));
  });
}
