import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flame/rendering.dart';
import 'package:flutter/material.dart';
import '../chrono_game.dart';
import 'player_component.dart';

/// Scrolling background shared by all eras, built from four depth layers
/// (back trees, light rays, middle trees, front trees). Each layer's scroll
/// offset is driven every frame from how far the camera actually moved
/// (`game.cameraLeftEdgeX`), scaled down to the same background:world speed
/// ratio the original hardcoded velocity used, then further scaled per layer
/// by `velocityMultiplierDelta` — not a fixed guessed velocity. This keeps
/// the background locked to the camera even if the player's forward speed
/// ever changes (e.g. a future speed power-up), instead of drifting out of
/// sync.
class ParallaxBackground extends ParallaxComponent<ChronoGame> {
  double? _lastCameraX;

  /// The pre-Phase-3 code drove this with a hardcoded, independently-ticking
  /// `baseVelocity: Vector2(20, 0)` while the world scrolled at a constant
  /// 150 units/sec (`PlayerComponent.forwardSpeed`) — i.e. the background was
  /// tuned to move at roughly 20/150 of the world's speed, which is what
  /// keeps it looking like it's further away than the foreground. Re-anchored
  /// to real camera movement, that same ratio has to be reapplied explicitly,
  /// or feeding the camera's full speed straight into `baseVelocity` makes
  /// the (velocityMultiplierDelta-multiplied) layers scroll faster than the
  /// world itself.
  static const double _referenceBaseVelocity = 20.0;

  /// Per-era colour grading over the one forest background set the game
  /// ships, so eras stop looking identical without needing per-era art
  /// (GAMEPLAY-V2.md section 10). Kept local to the component that renders
  /// them, matching how GroundSection keeps its own per-era body colours.
  ///
  /// Alpha is deliberately low — a semi-transparent wash keeps the trees and
  /// light rays readable through the tint instead of flattening them into a
  /// solid colour field.
  ///
  /// Keyed by the era ids that exist today. Section 1's six-era structure
  /// maps onto them through its own art table (era 1 = pre-colonial,
  /// 2 = spanish, 4 = american, 5 = ww2, 6 = modern); era 3
  /// (Pag-usbong ng Nasyonalismo) has no era id to attach to until the
  /// Phase 0.5 registry creates one, so [era3Nasyonalismo] is defined ready
  /// for it but unreachable in game until then.
  static const Color era1Sinaunang = Color(0x665E8C3A); // warm green
  static const Color era2Espanya = Color(0x66A87232); // sepia / amber
  static const Color era3Nasyonalismo = Color(0x66C9A227); // warm ochre
  static const Color era4Himagsikan = Color(0x66BFAE6A); // dusty gold
  static const Color era5Kolonyal = Color(0x66788E9E); // desaturated blue-grey
  static const Color era6BatasMilitar = Color(0x664FB8C4); // hazy cyan

  static const Map<String, Color> eraTints = {
    'pre-colonial': era1Sinaunang,
    'spanish': era2Espanya,
    'american': era4Himagsikan,
    'ww2': era5Kolonyal,
    'modern': era6BatasMilitar,
  };

  ParallaxBackground() : super(priority: -10);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // game.size is the camera viewport's virtual size (the fixed virtual
    // resolution), not the device canvas, so this matches the scaled world
    // this is mounted behind as the camera's backdrop.
    size = game.size;
    position = Vector2.zero();

    try {
      parallax = await game.loadParallax(
        [
          // Farthest — opaque sky + faint trunks.
          ParallaxImageData('backgrounds/parallax-forest-back-trees.png'),
          // Translucent light rays — extra depth layer. Placed right after
          // the back layer (not after the mid trees) since array position
          // drives both draw order and scroll speed in Flame's
          // ParallaxComponent: a light-ray layer reads as distant/ambient
          // only if it draws behind and scrolls slower than the mid trees,
          // not faster and in front of them.
          ParallaxImageData('backgrounds/parallax-forest-lights.png'),
          // Mid trees, transparent gaps.
          ParallaxImageData('backgrounds/parallax-forest-middle-trees.png'),
          // Closest — big dark trunks.
          ParallaxImageData('backgrounds/parallax-forest-front-trees.png'),
        ],
        velocityMultiplierDelta: Vector2(1.4, 1.0),
        fill: LayerFill.height,
        repeat: ImageRepeat.repeatX,
        size: size,
      );

      // Applied after the layers load so a failed load falls through to the
      // flat fallback below untinted rather than double-colouring it.
      //
      // Chained onto the decorator, NOT assigned over it: PositionComponent
      // populates `decorator` in its own constructor with the
      // Transform2DDecorator that applies this component's position and
      // scale, so `decorator = PaintDecorator.tint(...)` would throw that
      // transform away. `replaceLast` appends on the first call and swaps the
      // tint on any later one, so a re-load can never stack two tints.
      final tint = eraTints[game.currentEra];
      if (tint != null) {
        decorator.replaceLast(PaintDecorator.tint(tint));
      }
    } catch (e) {
      // Fallback so the game is still playable if a background asset is
      // somehow missing, instead of leaving the whole load future unresolved.
      debugPrint('Failed to load parallax background: $e');
      add(RectangleComponent(
        size: size,
        paint: Paint()..color = const Color(0xFFD4C4A8),
      ));
    }
  }

  @override
  void update(double dt) {
    // Lazily captured on the first post-load frame — game.cameraLeftEdgeX
    // reads player.worldX, and the player isn't mounted yet during onLoad.
    _lastCameraX ??= game.cameraLeftEdgeX;

    if (parallax != null && dt > 0) {
      final cameraVelocityX = (game.cameraLeftEdgeX - _lastCameraX!) / dt;
      parallax!.baseVelocity.x = cameraVelocityX *
          (_referenceBaseVelocity / PlayerComponent.forwardSpeed);
    }
    _lastCameraX = game.cameraLeftEdgeX;

    super.update(dt);
  }
}
