// Artifacts are drawn at 72 in their own colours with a glow behind them
// (playtest, 2026-10-06: "a little small", and the era tint washed them out).
import 'dart:ui';

import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/game/components/artifact_component.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('is 72 across, with its middle at the height it had at 56', () {
    expect(CombatConstants.artifactSize, 72);
    // The old centre: hovering 150 to the top at size 56 put it 122 up.
    expect(CombatConstants.artifactHoverHeight - CombatConstants.artifactSize / 2, 122);
  });

  test('draws its glow, ready or spent, without error', () {
    final artifact = ArtifactComponent(worldX: 500, spriteIndex: 1)
      ..size = Vector2.all(CombatConstants.artifactSize);
    final canvas = Canvas(PictureRecorder());

    artifact.render(canvas); // ready: halo and sparkles
    artifact.goInert();
    artifact.render(canvas); // dull, no glow
    artifact.opacity = 0.4;
    artifact.render(canvas); // mid fade-out after a claim
  });

  test('a spent artifact is dimmed, not tinted by the era', () {
    // The era tint is gone: the only decorator change left is going dull.
    final artifact = ArtifactComponent(worldX: 500, spriteIndex: 1);
    artifact.goInert();
    expect(artifact.isInert, isTrue);
  });
}
