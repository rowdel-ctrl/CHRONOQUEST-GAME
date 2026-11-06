import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/widgets/hero_art.dart';

void main() {
  test('Lapu-Lapu has 5 walk pictures, everyone else 4', () {
    expect(heroWalkFrameCount('lapu'), 5);
    for (final id in [
      'boy',
      'girl',
      'luna',
      'rizal',
      'bonifacio',
      'delpilar'
    ]) {
      expect(heroWalkFrameCount(id), 4);
    }
  });

  test('walk picture cycles through every frame the hero has', () {
    String at(String id, int frame) => heroWalkAsset(id, frame * 140);
    expect([
      for (var i = 0; i < 6; i++) at('lapu', i)
    ], [
      for (final n in [1, 2, 3, 4, 5, 1]) 'assets/characters/lapu_walk_$n.png'
    ]);
    expect([
      for (var i = 0; i < 5; i++) at('boy', i)
    ], [
      for (final n in [1, 2, 3, 4, 1]) 'assets/characters/boy_walk_$n.png'
    ]);
  });
}
