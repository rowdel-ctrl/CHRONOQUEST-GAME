// The word of praise over the hero after a correct answer.
import 'dart:io';
import 'dart:math';

import 'package:chronoquest/game/components/praise_component.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('says one of its words', () {
    for (var seed = 0; seed < 20; seed++) {
      final praise = PraiseComponent(random: Random(seed));
      expect(PraiseComponent.words, contains(praise.text));
    }
  });

  test('can be told what to say', () {
    expect(PraiseComponent(word: 'WOW!').text, 'WOW!');
  });

  test('every word is short enough to fit over the hero and is shouted', () {
    for (final word in PraiseComponent.words) {
      expect(word.length, lessThanOrEqualTo(12));
      expect(word, word.toUpperCase());
    }
  });

  test('has a cheer to go with it', () {
    // assets/sounds/praise.wav is made by tools/sfx/make_praise.js.
    expect(File('assets/sounds/praise.wav').existsSync(), isTrue);
  });
}
