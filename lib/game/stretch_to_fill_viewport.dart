import 'dart:ui';

import 'package:flame/components.dart';
// `Viewport` itself (the abstract base class every shipped viewport,
// including FixedResolutionViewport, extends) isn't re-exported from any
// public Flame library — only its concrete subclasses are. There's no way
// to write a custom Viewport without this import.
// ignore: implementation_imports
import 'package:flame/src/camera/viewport.dart';

/// A viewport that always covers the entire canvas edge-to-edge, with a
/// fixed virtual [height] and a virtual width that tracks the device's own
/// aspect ratio — so the world-to-screen scale is always uniform (no
/// stretch on either axis) while still filling the screen exactly.
///
/// [FixedResolutionViewport] (what this game used originally) fixes both
/// virtual width and height, uniformly scaled — exactly correct at 16:9,
/// but leaves black bars on the sides of every device whose landscape
/// aspect is wider than 16:9 (effectively every modern phone: ~19.5:9 to
/// ~22:9). An earlier version of this viewport fixed both dimensions too
/// and instead stretched non-uniformly to fill the canvas, which removed
/// the bars but visibly distorted round sprites and required counter-
/// scaling the HUD back to circular. Letting virtual width float with the
/// device's aspect ratio removes the stretch at its source: X and Y always
/// scale by the same factor, because the virtual aspect ratio always
/// matches the canvas's.
///
/// `virtualSize` — what `ChronoGame.size` actually reads — keeps `height`
/// fixed at [height] on every device, so `groundY`, jump physics, and
/// platform heights (all measured against virtual height) are unaffected.
/// Virtual *width* now varies with the device: a wider-than-16:9 phone
/// sees a wider slice of world (more `cameraRightEdgeX` reach), the same
/// tradeoff Unity's "match height" Canvas Scaler and Cocos2d's
/// `FIXED_HEIGHT` policy make — standard for 2D platformers/runners, and
/// the reason no HUD counter-scaling is needed here: nothing stretches.
///
/// `globalToLocal`/`localToGlobal` are copied from `FixedResolutionViewport`
/// (both route through the inherited `transform` field's own matrix-based
/// conversion) so touch input — the joystick and HUD buttons — maps back
/// to world space exactly, against whatever this device's uniform scale is.
class StretchToFillViewport extends Viewport {
  StretchToFillViewport({required this.height, super.children});

  /// The virtual height every device renders at, regardless of canvas size.
  final double height;

  final Vector2 _virtualSize = Vector2.zero();

  @override
  Vector2 get virtualSize => _virtualSize;

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
    final aspectRatio = size.x / size.y;
    _virtualSize.setValues(height * aspectRatio, height);

    final scale = size.y / height;
    // `transform` is `@internal` on the base Viewport class, but it's the
    // exact field FixedResolutionViewport itself relies on for this same
    // purpose — there's no public alternative for a custom Viewport to hook
    // into the canvas-to-virtual-space scale.
    // ignore: invalid_use_of_internal_member
    transform.scale = Vector2.all(scale);
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
