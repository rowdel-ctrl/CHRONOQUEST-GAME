// The level music must stop when its screen is left. Starting a track is several steps inside the
// audio plugin, and a stop that arrived in the middle of them used to be lost: the track then began
// and played on over the menus. Every music command now runs after the one before it.
import 'dart:async';

import 'package:chronoquest/services/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AudioService audio;
  late List<String> events;

  /// Starts that wait for the test to let them finish, to hold one "in the middle".
  late List<Completer<void>> gates;
  var gated = false;

  setUp(() {
    audio = AudioService()..resetMusicForTesting();
    events = [];
    gates = [];
    gated = false;
    audio.musicStarter = (file, volume) async {
      events.add('start $file');
      if (gated) {
        final gate = Completer<void>();
        gates.add(gate);
        await gate.future;
      }
      events.add('playing $file');
    };
    audio.musicStopper = () async => events.add('stop');
  });

  tearDown(() => audio.resetMusicForTesting());

  test('a stop asked for while a track is still starting stops it afterwards', () async {
    gated = true;
    final start = audio.playBgm('spanish');
    await Future<void>.delayed(Duration.zero);
    final stop = audio.stopBgm(); // the screen is left in the middle of the start
    gates.single.complete();
    await Future.wait([start, stop]);

    expect(events, ['start bgm_spanish.mp3', 'playing bgm_spanish.mp3', 'stop'],
        reason: 'the stop comes last, so nothing plays on');
  });

  test('a start that is still waiting when the stop comes never starts', () async {
    gated = true;
    final first = audio.playBgm('spanish');
    await Future<void>.delayed(Duration.zero);
    final second = audio.playBgm('american'); // queued behind the first
    final stop = audio.stopBgm();
    gates.single.complete();
    await Future.wait([first, second, stop]);

    expect(events.where((e) => e.startsWith('start')), ['start bgm_spanish.mp3']);
    expect(events.last, 'stop');
  });

  test('the newest track wins when two are asked for together', () async {
    gated = true;
    final first = audio.playBgm('spanish');
    await Future<void>.delayed(Duration.zero);
    final second = audio.playBgm('american');
    gates.first.complete();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    gates.last.complete();
    await Future.wait([first, second]);
    expect(events.where((e) => e.startsWith('playing')).last, 'playing bgm_american.mp3');
  });

  test('a stop with nothing ever started does nothing', () async {
    await audio.stopBgm();
    expect(events, isEmpty);
  });

  group('switching music on in Settings', () {
    test('on a menu (after a level) starts no track', () async {
      await audio.playBgm('spanish');
      await audio.stopBgm(); // the level screen was left
      events.clear();

      audio.setMusicEnabled(false);
      audio.setMusicEnabled(true);
      await Future<void>.delayed(Duration.zero);

      expect(events.where((e) => e.startsWith('start')), isEmpty,
          reason: 'a level that is over must not start its music again');
    });

    test('in a level, brings that level\'s track back', () async {
      await audio.playBgm('spanish');
      events.clear();

      audio.setMusicEnabled(false);
      await Future<void>.delayed(Duration.zero);
      expect(events, ['stop']);
      audio.setMusicEnabled(true);
      await Future<void>.delayed(Duration.zero);
      expect(events, ['stop', 'start bgm_spanish.mp3', 'playing bgm_spanish.mp3']);
    });

    test('in a boss fight, brings back the boss track of the same phase', () async {
      await audio.playBossBgm(phase: 2);
      events.clear();
      audio.setMusicEnabled(false);
      audio.setMusicEnabled(true);
      await Future<void>.delayed(Duration.zero);
      expect(events.where((e) => e.startsWith('start')), ['start bgm_boss_2.mp3']);
    });

    test('while music is off a level start is remembered, not played', () async {
      audio.setMusicEnabled(false);
      await audio.playBgm('spanish');
      expect(events.where((e) => e.startsWith('start')), isEmpty);
      audio.setMusicEnabled(true);
      await Future<void>.delayed(Duration.zero);
      expect(events.where((e) => e.startsWith('start')), ['start bgm_spanish.mp3']);
    });
  });
}
