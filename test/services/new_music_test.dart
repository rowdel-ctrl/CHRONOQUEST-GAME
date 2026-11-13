import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The music and sound files the user added on 2026-11-09 to 11-10 are in the game and are real
/// MP3 files. The game asks AudioService for them by name, and a missing or broken file would
/// only show up as silence on a phone.
void main() {
  // name -> the least size (bytes) it can have, so a file cut short or empty is noticed.
  const files = {
    'bgm_boss_1.mp3': 200000, // boss phase 1
    'bgm_boss_2.mp3': 900000, // boss phase 2
    'bgm_boss_3.mp3': 900000, // boss phase 3
    'bgm_victory.mp3': 700000, // era complete
    'bgm_bonus.mp3': 800000, // the bonus round
    'jump.mp3': 20000,
    'button.mp3': 5000,
    'level_complete.mp3': 100000,
    'teleport.mp3': 30000,
  };

  for (final entry in files.entries) {
    test('${entry.key} is an MP3 file of the right size', () {
      final bytes = File('assets/sounds/${entry.key}').readAsBytesSync();
      expect(bytes.length, greaterThan(entry.value));
      final id3 = String.fromCharCodes(bytes.sublist(0, 3)) == 'ID3';
      final frame = bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0;
      expect(id3 || frame, isTrue, reason: 'starts with an ID3 tag or an MP3 frame');
    });
  }

  test('the old boss music is still there as a fallback', () {
    expect(File('assets/sounds/bgm_boss.wav').existsSync(), isTrue);
  });
}
