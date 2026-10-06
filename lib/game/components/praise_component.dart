import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// A word of praise that pops up over the hero after a correct answer, rises
/// and fades ("WOW!", "GALING!"). Meant to be added as a child of the player so
/// it travels with them rather than being left behind at 250 units a second.
class PraiseComponent extends TextComponent {
  /// What it can say. Tagalog and the English children already know from games.
  static const List<String> words = [
    'WOW!',
    'GALING!',
    'AMAZING!',
    'ANG HUSAY!',
    'TAMA!',
    'GALING MO!',
  ];

  static const double lifetime = 1.1;

  /// How far up it floats, in world units.
  static const double rise = 70;

  PraiseComponent({String? word, Random? random})
      : super(
          text: word ?? words[(random ?? Random()).nextInt(words.length)],
          anchor: Anchor.bottomCenter,
          priority: 20,
          textRenderer: TextPaint(
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFD54F),
              // An outline made of four offset shadows, so the word reads on
              // any background.
              shadows: [
                Shadow(color: Color(0xFF3E2723), offset: Offset(2, 2)),
                Shadow(color: Color(0xFF3E2723), offset: Offset(-2, 2)),
                Shadow(color: Color(0xFF3E2723), offset: Offset(2, -2)),
                Shadow(color: Color(0xFF3E2723), offset: Offset(-2, -2)),
              ],
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    scale = Vector2.all(0.4);
    add(
      SequenceEffect([
        // Pops in, a little too big, then settles.
        ScaleEffect.to(
          Vector2.all(1.25),
          EffectController(duration: 0.18, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(duration: 0.12, curve: Curves.easeInOut),
        ),
      ]),
    );
    add(
      MoveByEffect(
        Vector2(0, -rise),
        EffectController(duration: lifetime, curve: Curves.easeOut),
      ),
    );
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.35, startDelay: lifetime - 0.35),
        onComplete: removeFromParent,
      ),
    );
  }
}
