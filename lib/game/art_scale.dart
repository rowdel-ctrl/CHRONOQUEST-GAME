import 'dart:ui';

import 'package:flame/components.dart';

/// The 2026-11 art (heroes, enemies, bosses) is drawn from pictures of different
/// sizes. One rule keeps them all the same size in the game: every picture is
/// drawn at its pixels divided by [artPixelsPerUnit], with the middle of its
/// bottom edge standing on the figure's feet.
///
/// So a hero's walking picture (about 240x300 pixels) is 96x120 units, which is the
/// box the game has always given the hero, and a wide picture (an attack with a
/// slash in front) simply draws wider than the box without moving the hero.
const double artPixelsPerUnit = 2.5;

/// How big [sprite] is drawn, in game units.
Vector2 artSizeOf(Sprite sprite) => sprite.srcSize / artPixelsPerUnit;

/// Draws [sprite] with the middle of its bottom edge at ([footX], [footY]).
/// With [flip] the picture is mirrored around that point.
void paintArt(
  Canvas canvas,
  Sprite sprite, {
  required double footX,
  required double footY,
  bool flip = false,
  Paint? overridePaint,
}) {
  final size = artSizeOf(sprite);
  if (flip) {
    canvas.save();
    canvas.translate(footX, 0);
    canvas.scale(-1, 1);
    sprite.render(
      canvas,
      position: Vector2(-size.x / 2, footY - size.y),
      size: size,
      overridePaint: overridePaint,
    );
    canvas.restore();
    return;
  }
  sprite.render(
    canvas,
    position: Vector2(footX - size.x / 2, footY - size.y),
    size: size,
    overridePaint: overridePaint,
  );
}
