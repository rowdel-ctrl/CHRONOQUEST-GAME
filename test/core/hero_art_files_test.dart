// Every hero on the hero screen has all of its picture files, and Maria Clara is the 300-coin hero.
import 'dart:io';

import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/screens/home/character_selection_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final c in allCharacters) {
    test('${c.shortName} has every picture file', () {
      bool has(String name) =>
          File('assets/characters/${c.id}_$name.png').existsSync();
      final missing = <String>[
        for (var i = 1; i <= walkFramesOf(c.id); i++)
          if (!has('walk_$i')) 'walk_$i',
        for (final n in ['jump', 'hurt', 'idle', 'win'])
          if (!has(n)) n,
        // Lapu-Lapu has 3 attack pictures, everyone else 4.
        for (var i = 1; i <= (c.id == 'lapu' ? 3 : 4); i++)
          if (!has('attack_$i')) 'attack_$i',
      ];
      expect(missing, isEmpty);
    });
  }

  test('Maria Clara costs 300 coins, so a new student has her locked', () {
    final c = getCharacterById('mariaclara');
    expect(c.id, 'mariaclara');
    expect(c.shortName, 'Maria Clara');
    expect(c.unlockCost, 300);
    expect(walkFramesOf('mariaclara'), 4);
  });
}
