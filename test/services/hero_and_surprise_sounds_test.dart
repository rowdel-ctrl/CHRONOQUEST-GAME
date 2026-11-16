// The hero attack sounds, the five surprise sounds and the rule that keeps warning
// sounds from piling up (2026-11-16). The files are small WAVs made by a program;
// the numbers below check that none is missing, silent, too long or louder than the
// game's other sounds, so a bad file shows up here and not as noise on a phone.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/services/audio_service.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePool implements AudioPool {
  int starts = 0;

  @override
  Future<StopFunction> start({double volume = 1.0}) async {
    starts++;
    return () async {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// What a WAV file holds: its length in seconds, its loudest point and its average
/// loudness (RMS), both as a fraction of full scale.
({double seconds, double peak, double rms}) _measure(String name) {
  final bytes = File('assets/sounds/$name').readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF', reason: name);
  expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE', reason: name);
  final rate = data.getUint32(24, Endian.little);
  final n = (bytes.length - 44) ~/ 2;
  var peak = 0.0, sum = 0.0;
  for (var i = 0; i < n; i++) {
    final v = data.getInt16(44 + i * 2, Endian.little) / 32768;
    peak = max(peak, v.abs());
    sum += v * v;
  }
  return (seconds: n / rate, peak: peak, rms: sqrt(sum / n));
}

void main() {
  const surprises = [
    'hopper.wav',
    'ground_pop.wav',
    'rock_warn.wav',
    'rock_crash.wav',
    'throw_windup.wav',
    'throw_fly.wav',
    'golden_run.wav',
  ];

  group('hero attack sounds', () {
    test('every hero in the game has one, and the list names no hero that does not exist', () {
      final ids = allCharacters.map((c) => c.id).toSet();
      expect(AudioService.heroesWithAttackSound, ids,
          reason: 'a new hero needs its own attack sound (or is left out on purpose)');
      for (final id in ids) {
        expect(File('assets/sounds/attack_$id.wav').existsSync(), isTrue, reason: id);
      }
    });

    for (final id in AudioService.heroesWithAttackSound) {
      test('attack_$id.wav is short, has sound in it and is not louder than the others', () {
        final m = _measure('attack_$id.wav');
        expect(m.seconds, inInclusiveRange(0.25, 0.8));
        expect(m.rms, greaterThan(0.03), reason: 'not silent');
        expect(m.peak, lessThan(0.95), reason: 'leaves headroom');
        expect(m.rms, lessThan(0.15), reason: 'quieter than the loud effects');
      });
    }

    test('a hero with an attack sound plays it, a hero without one stays silent', () async {
      final audio = AudioService();
      final built = <String, _FakePool>{};
      audio.poolFactory = (file) async => built.putIfAbsent(file, _FakePool.new);
      addTearDown(audio.resetSfxForTesting);

      await audio.playHeroAttack('lapu');
      await audio.playHeroAttack('rizal');
      await audio.playHeroAttack('nobody');
      expect(built.keys.toSet(), {'attack_lapu.wav', 'attack_rizal.wav'});
      expect(built['attack_lapu.wav']!.starts, 1);
    });
  });

  group('surprise sounds', () {
    for (final name in surprises) {
      test('$name is short, has sound in it and is quieter than the loud effects', () {
        final m = _measure(name);
        expect(m.seconds, inInclusiveRange(0.3, 0.8));
        expect(m.rms, greaterThan(0.03));
        expect(m.rms, lessThan(0.13));
        expect(m.peak, lessThan(0.95));
      });
    }

    test('each surprise plays its own sound', () async {
      final audio = AudioService();
      final built = <String, _FakePool>{};
      audio.poolFactory = (file) async => built.putIfAbsent(file, _FakePool.new);
      audio.warningWait = (_) async {};
      addTearDown(audio.resetSfxForTesting);

      await audio.playRockCrash();
      await audio.playThrowFly();
      expect(built.keys.toSet(), {'rock_crash.wav', 'throw_fly.wav'});
    });
  });

  group('the warning rule', () {
    late AudioService audio;
    late Map<String, _FakePool> built;
    late List<Duration> waits;
    late DateTime now;

    setUp(() {
      audio = AudioService();
      built = {};
      waits = [];
      now = DateTime(2026, 11, 16, 12);
      audio.poolFactory = (file) async => built.putIfAbsent(file, _FakePool.new);
      audio.warningClock = () => now;
      // The clock stands still (as it does when the calls come in the same instant);
      // the wait is only written down.
      audio.warningWait = (d) async => waits.add(d);
    });

    tearDown(() => audio.resetSfxForTesting());

    test('a lone warning plays at once', () async {
      await audio.playHeavyWindup();
      expect(waits, isEmpty);
      expect(built['heavy_windup.wav']!.starts, 1);
    });

    test('two warnings at the same moment are 0.4 s apart: the second waits', () async {
      await audio.playHeavyWindup();
      await audio.playGroundPop();
      expect(waits, [AudioService.warningGap]);
      expect(built['ground_pop.wav']!.starts, 1, reason: 'still played, just later');
    });

    test('three at once come at 0, 0.4 and 0.8 s', () async {
      await Future.wait([
        audio.playHopper(),
        audio.playThrowWindup(),
        audio.playRockWarn(),
      ]);
      expect(waits.length, 2);
      expect(waits[0], AudioService.warningGap);
      expect(waits[1], greaterThanOrEqualTo(AudioService.warningGap));
      expect(built.keys, containsAll(['hopper.wav', 'throw_windup.wav', 'rock_warn.wav']));
    });

    test('one that would wait too long is dropped: the moment has passed', () async {
      for (var i = 0; i < 4; i++) {
        audio.playChaserNotice();
      }
      await pumpEventQueue();
      // The 4th is due 1.2 s later, past the longest wait, so it is not played.
      expect(built['chaser_notice.wav']!.starts, 3);
    });

    test('a warning after a quiet moment is not held back', () async {
      await audio.playHeavyWindup();
      now = now.add(const Duration(seconds: 2));
      waits.clear();
      await audio.playRockWarn();
      expect(waits, isEmpty);
    });

    test('sounds that are not warnings (a lunge, a crash, the shockwave) are never held back', () async {
      await audio.playHeavyWindup();
      await audio.playLunge();
      await audio.playRockCrash();
      await audio.playShockwave();
      expect(waits, isEmpty);
    });
  });
}
