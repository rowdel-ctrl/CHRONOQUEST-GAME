import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// The sound files made by tools/sfx/make_sfx.js exist and are real WAV files.
/// The game asks AudioService for them by name, and a missing file would only
/// show up as a silent effect on a phone.
void main() {
  const files = [
    'land.wav',
    'step.wav',
    'tap.wav',
    'artifact.wav',
    'gate_rumble.wav',
    'splash.wav',
    'heart.wav',
    'flag.wav',
    'shield_pop.wav',
    'streak.wav',
    'chaser_notice.wav',
    'heavy_windup.wav',
    'lunge.wav',
    'boss_warning.wav',
    'boss_warning_short.wav',
    'shockwave.wav',
    'boss_phase.wav',
    'boss_ask.wav',
    'bgm_boss.wav',
  ];

  for (final name in files) {
    test('$name is a WAV file with sound in it', () {
      final bytes = File('assets/sounds/$name').readAsBytesSync();
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
      expect(bytes.length, greaterThan(2000));
      // Some samples are not silence.
      final data = ByteData.sublistView(bytes);
      var loud = 0;
      for (var i = 44; i + 1 < bytes.length; i += 2) {
        if (data.getInt16(i, Endian.little).abs() > 3000) loud++;
      }
      expect(loud, greaterThan(50));
    });
  }

  test('the boss warning is as long as the telegraph it goes with', () {
    // The first warning is 1.0 s and the second 0.6 s (BossPlan); each file is
    // that long plus a short tail.
    double seconds(String name) {
      final bytes = File('assets/sounds/$name').readAsBytesSync();
      return (bytes.length - 44) / 2 / 22050;
    }

    expect(seconds('boss_warning.wav'), closeTo(1.0, 0.1));
    expect(seconds('boss_warning_short.wav'), closeTo(0.6, 0.1));
  });
}
