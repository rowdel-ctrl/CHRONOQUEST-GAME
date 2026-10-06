import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/combat_constants.dart';
import '../../core/constants.dart';
import '../answer_point_handler.dart';
import '../chrono_game.dart';
import '../game_collision.dart';
import '../kaalaman_handler.dart';
import 'artifact_component.dart';
import 'attack_hitbox_component.dart';
import 'enemy_component.dart';
import 'coin_component.dart';
import 'gate_component.dart';

/// Player character — `position.x` is the player's real world x-position,
/// `worldX`. Horizontal movement is driven by the on-screen joystick
/// (`game.gameInput.joystick`, GAMEPLAY-V2.md Section 3), student taps the
/// jump button to jump. The camera follows `worldX` so the player always
/// renders at a fixed screen offset; the player never moves itself in
/// screen space. Displays real walk, jump, and hurt sprite animations.
class PlayerComponent extends SpriteAnimationComponent
    with HasGameReference<ChronoGame>, CollisionCallbacks {
  static const double gravity = 900.0;
  static const double jumpForce = -480.0;

  /// Top horizontal speed, in world units/second, the joystick can command
  /// in either direction. Previously an unconditional auto-advance rate
  /// applied every frame regardless of input (GAMEPLAY-V2.md Section 3);
  /// same value, now scaled by the joystick's `relativeDelta.x` instead —
  /// the camera, spawn positions, and despawn checks still derive from
  /// `worldX`, which is what actually moves.
  ///
  /// Raised from the original 150 to 210, and from 210 to 250 on 2026-10-06
  /// (playtest: "medyo mabagal ang galaw"). The jump itself did not change,
  /// so a full-speed jump now carries 250 * 1.067 = 267 units instead of 224,
  /// and every gap rule in tools/levelgen/rules.js was re-derived from it.
  ///
  /// Raised from the original 150 after playtesting found walking too slow.
  /// Nothing needed retuning alongside it: `ParallaxBackground` derives its
  /// scroll speed from this constant by ratio rather than a hardcoded
  /// number (see its own doc comment), and the spawner measures distance
  /// from the player's actual worldX rather than assuming a fixed speed, so
  /// both already track this value automatically.
  static const double forwardSpeed = 250.0;

  /// The player's real position in world space. Aliases `position.x` —
  /// obstacles/camera never subtract a scroll speed from themselves;
  /// instead this value increases every frame and everything else is
  /// positioned relative to it.
  double get worldX => position.x;

  double velocityY = 0.0;
  bool isOnGround = false;
  bool isHurt = false;

  /// Which way the character is drawn facing, toggled whenever the
  /// joystick's horizontal pull changes sign. Mirrored in `render()` via a
  /// local canvas transform rather than `flipHorizontallyAroundCenter()`:
  /// that method compensates a non-center anchor by nudging `position.x`
  /// (confirmed against the installed Flame source — for `Anchor.topLeft`
  /// it adds the full sprite width), and here `position.x` IS `worldX`, read
  /// by the camera, collision, and the spawner's distance tracking. A
  /// transform-based flip would silently displace all of them by ±size.x
  /// every time the player changes direction.
  bool facingRight = true;

  final String characterId;

  late SpriteAnimation walkAnimation;
  late SpriteAnimation jumpAnim;
  late SpriteAnimation hurtAnim;

  /// Time left before another `attack()` can spawn a new hitbox
  /// (CombatConstants.attackCooldown) — counted down every frame, not a
  /// `Future.delayed`, so it can be checked synchronously from `attack()`.
  double _attackCooldownRemaining = 0;

  /// True from the moment contact damage lands until
  /// `CombatConstants.invincibilityDuration` elapses — gates *all* further
  /// contact damage (enemy or wall) during that window, independent of
  /// `isHurt`/`triggerHurt()`'s own, shorter 600ms animation-swap-back
  /// timer. The two are sibling reactions to the same damage event with
  /// genuinely different durations, tracked separately on purpose — see
  /// `_takeContactDamage()`.
  /// When the current invincibility window ends, as wall-clock time.
  ///
  /// Deliberately NOT a `dt`-driven countdown. A question calls
  /// `pauseEngine()`, which stops `update()` entirely, so a countdown froze
  /// for the whole time a question was open: a student who spent 20s
  /// answering came back with a full second of invincibility still banked,
  /// and the window then expired mid-overlap so the *next* contact landed.
  /// That is the "sometimes immune after answering, sometimes not" bug from
  /// the 2026-10-03 playtest. Real time cannot be banked.
  DateTime? _invincibleUntil;

  bool get invincible =>
      _invincibleUntil != null && DateTime.now().isBefore(_invincibleUntil!);

  /// Toggled during the invincibility window to flash the sprite. `render()`
  /// skips drawing entirely while this is false.
  bool _flashVisible = true;
  double _flashTimer = 0;

  /// Whether the sprite is currently drawn — false only mid-flash during
  /// the invincibility window. Exposed so tests can assert the flash never
  /// leaves the player permanently invisible once the window ends.
  @visibleForTesting
  bool get isFlashVisible => _flashVisible;

  /// The last world x at which the player was standing on solid ground —
  /// the "respawn anchor" of GAMEPLAY-V2.md's Phase 4 gap handling.
  ///
  /// Before Phase 4 the ground was one unbroken slab (`GroundSpawner` laid a
  /// single million-unit section), so falling was only possible off the
  /// bottom of the screen and `respawn()` could simply reset y and keep
  /// worldX. Tiled levels have real gaps, so a fall now has to put the
  /// player back somewhere they can actually stand — otherwise respawning
  /// in place drops them straight back down the same hole, costing every
  /// remaining heart in a couple of seconds.
  ///
  /// Updated only while genuinely grounded and not mid-knockback, so a
  /// player shoved out over a gap anchors to where they were standing
  /// before the hit rather than to the lip they were knocked off.
  ///
  /// Seeded by the level loader from the Tiled `spawn` object, so a fall
  /// before ever touching ground still has somewhere valid to go.
  double respawnAnchorX = GameConstants.playerX;

  /// Horizontal velocity imparted by the most recent contact-damage
  /// knockback, decremented toward zero over
  /// `CombatConstants.knockbackDuration`. Added on top of joystick-driven
  /// movement in `update()`, not instead of it — the player can still steer
  /// during a knockback.
  double _knockbackVelocityX = 0;
  double _knockbackRemaining = 0;

  PlayerComponent({required this.characterId});

  @override
  Future<void> onLoad() async {
    // 1.5x the native 52x68 art, same ratio as before (was 64x80 — barely
    // bigger than a 60x72 enemy, so the hero didn't read as the hero). The
    // boss already upscales its own native art by roughly this much (80x90
    // -> 120x140), so this brings the player closer to that same treatment
    // instead of sitting almost flush with regular enemies.
    size = Vector2(96, 120);
    position = Vector2(0, game.groundY - size.y);

    // Load walk frames as individual sprites and build the animation sequence
    final walkSprites = <Sprite>[];
    for (int i = 1; i <= 4; i++) {
      try {
        walkSprites.add(
            await game.loadSprite('characters/${characterId}_walk_$i.png'));
      } catch (e) {
        // Safe fallback placeholder if asset fails to load
        debugPrint('Failed to load character walk frame $i: $e');
      }
    }

    if (walkSprites.isNotEmpty) {
      walkAnimation = SpriteAnimation.spriteList(walkSprites, stepTime: 0.15);
    } else {
      // Emergency blank animation fallback
      walkAnimation = SpriteAnimation.spriteList([], stepTime: 1.0);
    }

    // Load single jump and hurt frames
    jumpAnim = SpriteAnimation.spriteList(
      [await game.loadSprite('characters/${characterId}_jump.png')],
      stepTime: 1.0,
    );
    hurtAnim = SpriteAnimation.spriteList(
      [await game.loadSprite('characters/${characterId}_hurt.png')],
      stepTime: 0.3,
    );

    animation = walkAnimation;
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_attackCooldownRemaining > 0) _attackCooldownRemaining -= dt;

    // Player-driven horizontal movement (GAMEPLAY-V2.md Section 3): -1..1,
    // from the joystick's pull or from the arrow buttons, so this both sets
    // speed and direction whichever control scheme is on screen.
    //
    // Ignored while knocked back: a hit takes the controls for the length of
    // the shove, so the student cannot walk back into the enemy at once and
    // use the invincibility that follows to pass through it.
    final horizontalInput =
        _knockbackRemaining > 0 ? 0.0 : game.gameInput.horizontal;
    if (horizontalInput != 0) {
      position.x += forwardSpeed * horizontalInput * dt;
      facingRight = horizontalInput > 0;
    }

    // Knockback from contact damage: a steady shove away from the enemy for
    // CombatConstants.knockbackDuration, covering knockbackDistance in all.
    // The player cannot steer during it (above). On the ground it stops at the
    // edge of the ledge, so a hit never throws anyone into a gap.
    if (_knockbackRemaining > 0) {
      position.x = _keepOnGround(position.x + _knockbackVelocityX * dt);
      _knockbackRemaining -= dt;
      if (_knockbackRemaining <= 0) _knockbackVelocityX = 0;
    }

    // Never walk back past the level's start — there's no ground or
    // background authored to the left of it (Phase 4 gives levels real
    // bounds via Tiled).
    if (position.x < 0) position.x = 0;

    // A standing gate is a hard stop (GAMEPLAY-V2.md Section 6: "blocks the
    // full height of the corridor — you cannot jump it"). Clamped here in
    // update() rather than on collision so it holds on every frame the
    // player pushes against it, and so it works whether they arrive walking,
    // falling or knocked back. Only gates ahead of the player block: one
    // already passed must not pull them back.
    //
    // Opening (or explaining why not) also happens here, NOT in
    // onCollisionStart. That was a real softlock: the clamp parks the player
    // at `blockX - size.x`, which is `CombatConstants.gateStandoff` (8px)
    // short of the gate, so the two hitboxes never overlap and the collision
    // event never fired. The player was held against an invisible wall with
    // no way through. Deciding from the same loop that does the blocking
    // keeps the two in lockstep.
    for (final gate in game.world.children.whereType<GateComponent>()) {
      if (!gate.isBlocking) continue;
      final limit = gate.blockX - size.x;
      if (position.x > limit && position.x < gate.position.x + gate.size.x) {
        position.x = limit;
        if (gate.requirementMet) {
          // Every artifact answered: the gate simply opens. It asks nothing.
          game.passEndGate(gate);
        } else {
          // Blocked for a reason the student can act on: they still have
          // artifacts to find. Telling them beats silently refusing.
          game.showGateLockedNotice();
        }
      }
    }

    // Apply gravity
    if (!isOnGround) {
      velocityY += gravity * dt;
      position.y += velocityY * dt;
    }

    final onGround = resolveGroundContact();

    // Landed after a jump — swap back from the jump pose to the running
    // animation. Without this, the player stayed frozen in the jump frame
    // for the rest of the level after the first jump.
    if (onGround && !isOnGround && !isHurt) {
      animation = walkAnimation;
    }
    isOnGround = onGround;

    // Remember the last spot the player could actually stand, for
    // `respawn()` after a fall. Skipped during knockback so being shoved
    // off a ledge doesn't anchor them to the edge they were pushed over.
    //
    // Only counts when the whole foot span is over ground, never a platform:
    // a platform hangs over a gap, so anchoring there respawned the player
    // at ground height over nothing and they fell again.
    if (onGround && _knockbackRemaining <= 0) {
      final centre = position.x + size.x / 2;
      final half = size.x * footSpanFraction / 2;
      if (game.isGroundUnder(centre - half, centre + half)) {
        respawnAnchorX = position.x;
      }
    }

    // Invincibility-frame flashing (GAMEPLAY-V2.md Section 5: "~1s of
    // invincibility frames (flashing sprite)"). Deliberately independent of
    // isHurt/triggerHurt()'s own timer — see _takeContactDamage().
    if (invincible) {
      _flashTimer -= dt;
      if (_flashTimer <= 0) {
        _flashTimer = CombatConstants.flashInterval;
        _flashVisible = !_flashVisible;
      }
    } else if (!_flashVisible) {
      _flashVisible = true;
    }

    // Fall in gap handling
    if (position.y > game.size.y + 50) {
      game.playerFellInGap();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_flashVisible) return;

    if (facingRight) {
      super.render(canvas);
      return;
    }
    // Mirror the drawn sprite within its own bounding box: translate to the
    // right edge, then scale -1 so drawing runs back over [0, size.x]. Only
    // affects this render call's canvas — position/transform (and therefore
    // worldX and the hitbox) are untouched. Restored before children (the
    // hitbox) render, so it can't leak into their transform either.
    canvas.save();
    canvas.translate(size.x, 0);
    canvas.scale(-1, 1);
    super.render(canvas);
    canvas.restore();
  }

  void jump() {
    if (isOnGround) {
      velocityY = jumpForce;
      isOnGround = false;
      animation = jumpAnim;
      game.audioService.playJump();
    }
  }

  /// Swings the attack hitbox in the facing direction (GAMEPLAY-V2.md
  /// Section 3). Needs at least one charge and an expired cooldown, but the
  /// charge is only spent when the swing hits an enemy, so a miss is free.
  void attack() {
    if (_attackCooldownRemaining > 0) return;
    if (!game.canAttack) return;

    _attackCooldownRemaining = CombatConstants.attackCooldown;

    final hitboxSize = Vector2(
      CombatConstants.attackHitboxWidth,
      CombatConstants.attackHitboxHeight,
    );
    final offsetX = facingRight ? size.x : -hitboxSize.x;
    final offsetY = (size.y - hitboxSize.y) / 2;
    game.world.add(
      AttackHitboxComponent(
        position: position + Vector2(offsetX, offsetY),
        size: hitboxSize,
        facingRight: facingRight,
        follow: this,
      ),
    );
  }

  void triggerHurt() {
    isHurt = true;
    animation = hurtAnim;
    game.audioService.playHurt();
    Future.delayed(const Duration(milliseconds: 600), () {
      isHurt = false;
      if (isOnGround) {
        animation = walkAnimation;
      }
    });
  }

  /// Brief celebratory pose on a correct quiz answer. There's no dedicated
  /// "cheer" art yet, so this reuses the already-loaded jump pose as a
  /// stand-in reaction — same idea as triggerHurt(), just a happy trigger
  /// instead of a damage one. Uses its own delayed revert rather than
  /// relying on update()'s on-ground-transition reset, since that only
  /// fires when isOnGround flips false->true (i.e. landing a jump), which
  /// never happens here if the player was already on the ground.
  void triggerCheer() {
    if (isHurt) return;
    animation = jumpAnim;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (isOnGround && !isHurt) {
        animation = walkAnimation;
      }
    });
  }

  /// Puts the player back on the last solid ground they stood on, after a
  /// fall into a gap (GAMEPLAY-V2.md Phase 4).
  ///
  /// Pre-Phase-4 this reset only vertical state and deliberately kept
  /// worldX, which was correct when the ground was one unbroken slab and a
  /// "gap" could not exist. Tiled levels have real gaps, so keeping worldX
  /// would drop the player back into the same hole they just fell through,
  /// draining the whole heart pool in seconds. Horizontal position now
  /// returns to [respawnAnchorX].
  ///
  /// It returns a run-up *before* that spot, not to it. The anchor is where
  /// the player last stood, which is the lip of the gap they fell into;
  /// respawning on the lip with the joystick still held walked them straight
  /// back off, one heart per second, until the level failed. Backing up
  /// (never past the start of that ground) gives them time to jump.
  static const double respawnRunway = 300;

  void respawn() {
    final centre = respawnAnchorX + size.x / 2;
    var x = respawnAnchorX - respawnRunway;
    for (final section in game.groundSections) {
      if (centre >= section.position.x &&
          centre <= section.position.x + section.size.x) {
        if (x < section.position.x) x = section.position.x;
        break;
      }
    }
    position.x = x < 0 ? 0 : x;
    position.y = game.groundY - size.y;
    velocityY = 0;
    isOnGround = true;
    // A respawn cancels any in-flight knockback — otherwise the shove that
    // pushed the player into the gap keeps pushing once they are back.
    _knockbackVelocityX = 0;
    _knockbackRemaining = 0;
    animation = walkAnimation;
  }

  /// Enemy contact is checked every frame of an overlap, not only on the
  /// frame it begins.
  ///
  /// `onCollisionStart` alone fired once per *new* overlap, so standing
  /// inside an enemy was free, and whether a touch hurt depended on whether
  /// the player had separated first rather than on anything the student
  /// could see. (It also produced the "the enemy only hurts me when it
  /// faces me" report: the hitbox is the same box in both directions — only
  /// the sprite mirrors — so what actually varied was whether the overlap
  /// was new.) The i-frame guard in `_takeContactDamage` is what keeps this
  /// from becoming damage every frame.
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is EnemyComponent && !other.defeated) {
      _takeContactDamage(
        knockbackDirection: worldX < other.position.x ? -1 : 1,
      );
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is CoinComponent && !other.collected) {
      other.collect();
      game.collectCoin();
    }
    if (other is ArtifactComponent && other.isInteractable) {
      // Walk into it and the question opens (GAMEPLAY-V2.md Section 6).
      // No damage, ever — an artifact is an opportunity, not a hazard.
      game.showArtifactQuestion(other);
    }
    // Gates are deliberately NOT handled here. The clamp in update() stops
    // the player 8px short of the gate, so these hitboxes never overlap and
    // this branch never ran — see the gate loop in update(), which both
    // blocks and asks.
  }

  /// Limits [x] so a shoved player who is standing on something stays on it.
  ///
  /// Finds the ground section or platform the whole foot span is over and keeps
  /// the foot span inside it, so a hit never throws anyone into a gap, from a
  /// ledge or from a platform fight. Airborne, or already off the edge, there is
  /// nothing to stay on, so [x] is returned unchanged.
  double _keepOnGround(double x) {
    if (!isOnGround) return x;
    final half = size.x * footSpanFraction / 2;
    final centre = position.x + size.x / 2;
    double clampTo(double start, double width) => x.clamp(
          start + half - size.x / 2,
          start + width - half - size.x / 2,
        );
    for (final s in game.groundSections) {
      if (centre - half >= s.position.x &&
          centre + half <= s.position.x + s.size.x) {
        return clampTo(s.position.x, s.size.x);
      }
    }
    final feetY = position.y + size.y;
    for (final p in game.platforms) {
      if ((feetY - p.surfaceY).abs() < 1 &&
          centre - half >= p.position.x &&
          centre + half <= p.position.x + p.size.x) {
        return clampTo(p.position.x, p.size.x);
      }
    }
    return x;
  }

  /// The one place contact damage (enemy touch or wall) is decided from.
  /// Early-returns while [invincible] is already true — this is the "don't
  /// get chain-hit" guard (Section 5), and it's what stops a wall from
  /// landing a second hit inside an enemy's own i-frame window, or vice
  /// versa, regardless of which triggered first. Deliberately separate
  /// from `isHurt`/`triggerHurt()`'s own, shorter 600ms animation-swap-back
  /// timer: invincibility (1.0s) is a render-layer flash, hurt (0.6s) is
  /// which animation frames play, and the two windows don't share a clock.
  void _takeContactDamage({required int knockbackDirection}) {
    if (invincible) return;

    game.loseLife();
    _knockbackVelocityX = CombatConstants.knockbackForce * knockbackDirection;
    _knockbackRemaining = CombatConstants.knockbackDuration;
    _invincibleUntil = DateTime.now().add(
      Duration(
        milliseconds:
            (CombatConstants.invincibilityDuration * 1000).round(),
      ),
    );
  }
}
