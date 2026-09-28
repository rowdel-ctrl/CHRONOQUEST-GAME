import 'dart:ui';

import 'package:flame/game.dart';
// `Viewport` itself (the abstract base class every shipped viewport,
// including FixedResolutionViewport, extends) isn't re-exported from any
// public Flame library — only its concrete subclasses are. There's no way
// to write a custom Viewport without this import.
// ignore: implementation_imports
import 'package:flame/src/camera/viewport.dart';

/// A viewport that always covers the entire canvas edge-to-edge, while
/// keeping [virtualSize] pinned to a fixed [resolution] — the same contract
/// [FixedResolutionViewport] makes, minus the pillarboxing.
///
/// [FixedResolutionViewport] (what this game used before) auto-shrinks its
/// own `size` to the largest rectangle matching [resolution]'s aspect ratio
/// that fits inside the canvas, uniformly scaled, and centers it — which is
/// exactly correct at 16:9, but leaves black bars on the sides of every
/// device whose landscape aspect is wider than 16:9 (effectively every
/// modern phone: ~19.5:9 to ~22:9).
///
/// This viewport instead sets `size` to the full canvas every time (no
/// shrinking, no centering, nothing to clip) and scales the virtual
/// [resolution] onto it per-axis independently, so it always fills the
/// screen exactly. `virtualSize` — what `ChronoGame.size` actually reads —
/// stays the fixed [resolution] regardless of device, so nothing in world
/// space (`groundY`, jump physics, platform heights, spawn distances, HUD
/// margins measured against the virtual width/height) changes at all; only
/// the final scale-to-screen step does. The tradeoff is a mild non-uniform
/// stretch on any device whose aspect isn't exactly 16:9 (a modern phone's
/// ~19.5:9-22:9 is roughly 8-25% wider than tall relative to 16:9), since X
/// and Y no longer scale by the same factor.
///
/// `globalToLocal`/`localToGlobal` are copied from `FixedResolutionViewport`
/// (both route through the inherited `transform` field's own matrix-based
/// conversion, which already handles non-uniform scale correctly) so touch
/// input — the joystick and HUD buttons — maps back to world space exactly
/// as it did before, just against a differently-scaled transform.
class StretchToFillViewport extends Viewport {
  StretchToFillViewport({required this.resolution, super.children});

  /// The resolution that world-space code should keep seeing, regardless of
  /// the real device's canvas size or aspect ratio.
  final Vector2 resolution;

  @override
  Vector2 get virtualSize => resolution;

  @override
  void onLoad() {
    size = findGame()!.canvasSize;
  }

  @override
  void onGameResize(Vector2 size) {
    this.size = size;
    super.onGameResize(size);
  }

  @override
  void onViewportResize() {
    // `transform` is `@internal` on the base Viewport class, but it's the
    // exact field FixedResolutionViewport itself relies on for this same
    // purpose — there's no public alternative for a custom Viewport to hook
    // into the canvas-to-virtual-space scale.
    // ignore: invalid_use_of_internal_member
    transform.scale = Vector2(size.x / resolution.x, size.y / resolution.y);
  }

  @override
  void clip(Canvas canvas) {}

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  Vector2 globalToLocal(Vector2 point, {Vector2? output}) {
    final viewportPoint = super.globalToLocal(point, output: output);
    // ignore: invalid_use_of_internal_member
    return transform.globalToLocal(viewportPoint, output: output);
  }

  @override
  Vector2 localToGlobal(Vector2 point, {Vector2? output}) {
    // ignore: invalid_use_of_internal_member
    final viewportPoint = transform.localToGlobal(point, output: output);
    return super.localToGlobal(viewportPoint, output: output);
  }
}
