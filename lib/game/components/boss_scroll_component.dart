import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../core/combat_constants.dart';
import '../chrono_game.dart';

/// The scroll a boss fight's question waits on (arena fights only). It pops up far from the
/// student, who walks to it; touching it opens the question. The boss component checks the
/// touch itself, so this has no hitbox and cannot be mistaken for an artifact.
class BossScrollComponent extends SpriteComponent with HasGameReference<ChronoGame> {
  /// World x of its middle, and the world y of the surface it stands over.
  final double centerX;
  final double surfaceY;

  BossScrollComponent({required this.centerX, required this.surfaceY});

  double _time = 0;
  late final double _baseY;

  static final Paint _haloPaint = Paint();
  static Shader? _haloShader;

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('collectibles/artifact_1.png');
    size = Vector2.all(CombatConstants.artifactSize);
    anchor = Anchor.center;
    // Hovering just above the floor, low enough to be touched while standing.
    _baseY = surfaceY - 100;
    position = Vector2(centerX, _baseY);
    // It pops into being rather than just appearing.
    scale = Vector2.all(0.01);
    add(ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.3, curve: Curves.easeOutBack)));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    position.y = _baseY + sin(_time * CombatConstants.artifactBobSpeed) * CombatConstants.artifactBobAmplitude;
  }

  @override
  void render(Canvas canvas) {
    final centre = Offset(size.x / 2, size.y / 2);
    _haloShader ??= const RadialGradient(
      colors: [Color(0xF2FFF0A0), Color(0x8CFFC531), Color(0x00FFC531)],
      stops: [0.0, 0.38, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));
    _haloPaint.shader = _haloShader;
    final pulse = 0.86 + 0.14 * sin(_time * 2.6);
    canvas
      ..save()
      ..translate(centre.dx, centre.dy)
      ..scale(size.x * 1.15 * pulse)
      ..drawCircle(Offset.zero, 1, _haloPaint)
      ..restore();
    super.render(canvas);
  }

  /// Whether the student, at [playerRect] in world space, is touching it.
  bool touches(Rect playerRect) {
    final half = size.x / 2;
    return playerRect.overlaps(Rect.fromLTWH(position.x - half, position.y - half, size.x, size.y));
  }
}
