import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import '../../core/combat_constants.dart';
import '../../core/constants.dart';
import '../../core/hero_move_constants.dart';
import '../answer_point_handler.dart';
import '../art_scale.dart';
import '../chrono_game.dart';
import '../game_collision.dart';
import '../hero_move_art.dart';
import '../hero_move_runner.dart';
import '../kaalaman_handler.dart';
import 'artifact_component.dart';
import 'attack_hitbox_component.dart';
import 'enemy_component.dart';
import 'coin_component.dart';
import 'gate_component.dart';
import 'heart_pickup_component.dart';

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

  /// Seconds between footsteps while walking, and how fast the student has to be
  /// falling for the landing to thud.
  static const double _stepSeconds = 0.3;
  static const double _thudSpeed = 220;
  double _stepTimer = 0;
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

  /// The hero's attack pictures by number (`<id>_attack_1..4`). Optional: a hero
  /// with none swings with no picture of its own and keeps the old white slash.
  /// Lapu has only 1..3.
  final Map<int, Sprite> _attackSprites = {};

  /// Whether this hero has attack pictures. The attack hitbox skips its own
  /// white crescent when it does, because the pictures draw a golden slash.
  bool get hasAttackArt => _attackSprites.isNotEmpty;

  /// Seconds since the current swing began, or null when no attack picture is
  /// showing. A per-frame timer like [_attackCooldownRemaining], not a
  /// `Future.delayed`. It is only a picture: movement and jumping carry on.
  double? _attackPictureElapsed;

  /// Whether the swing began in the air (decided once, at the moment of the swing).
  bool _attackInAir = false;

  /// Ground swing with 4 pictures: attack_1, then attack_4 from this moment.
  static const double _groundSecondPictureAt = 0.17;

  /// How long the current attack picture sequence lasts, and when its ground
  /// second picture takes over. A dash sets its own (see [showAttackPicture]).
  double _attackPictureLength = CombatConstants.attackHitboxDuration;
  double _secondPictureAt = _groundSecondPictureAt;

  /// Plays this hero's own move (the 2026-11 hero moves): flying things, dashes and
  /// the counter aimed at a boss attack. See hero_move_runner.dart.
  late final HeroMoveRunner _moves = HeroMoveRunner(this);

  @visibleForTesting
  HeroMoveRunner get moves => _moves;

  /// This hero's move (see hero_move_constants.dart).
  HeroMove get heroMove => heroMoveFor(characterId);

  /// Air swing: attack_2, then attack_3 from this moment.
  static const double _airSecondPictureAt = 0.10;

  /// The attack picture number (1..4) showing right now, or null when the walk,
  /// jump or hurt picture is. Hurt wins over a swing.
  @visibleForTesting
  int? get attackPictureNumber {
    final elapsed = _attackPictureElapsed;
    if (elapsed == null || isHurt || _attackSprites.isEmpty) return null;
    final int number;
    if (_attackInAir) {
      number = elapsed < _airSecondPictureAt ? 2 : 3;
    } else if (_attackSprites.containsKey(4)) {
      number = elapsed < _secondPictureAt ? 1 : 4;
    } else {
      number = 1;
    }
    return _attackSprites.containsKey(number) ? number : null;
  }

  /// Time left before another `attack()` can do anything (the hero's own
  /// [HeroMove.cooldown]) — counted down every frame, not a `Future.delayed`, so it
  /// can be checked synchronously from `attack()`.
  double _attackCooldownRemaining = 0;

  /// Seconds before the next attack can start.
  @visibleForTesting
  double get attackCooldownLeft => _attackCooldownRemaining;

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

  /// Safe from harm: for the 1.5 s after a hit or a respawn, and for as long as a
  /// dash move lasts (the dash heroes cannot be hurt while they dash).
  bool get invincible => _moves.dashing || _windowInvincible;

  /// The wall-clock window only (the one that flashes the sprite).
  bool get _windowInvincible =>
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
    // The box stays 96x120 for physics and the hitbox. The pictures are drawn at
    // their own size (pixels / artPixelsPerUnit, see art_scale.dart) with the
    // middle of their bottom edge on the feet, so a wide attack picture simply
    // draws wider than the box without moving the hero.
    size = Vector2(96, 120);
    position = Vector2(0, game.groundY - size.y);

    // Load walk frames as individual sprites and build the animation sequence.
    // A hero has 4 to 6 of them (Lapu has 5); a missing number is skipped.
    final walkSprites = <Sprite>[];
    for (int i = 1; i <= 6; i++) {
      final sprite = await _tryLoadSprite('${characterId}_walk_$i');
      if (sprite != null) walkSprites.add(sprite);
    }

    if (walkSprites.isNotEmpty) {
      walkAnimation = SpriteAnimation.spriteList(walkSprites, stepTime: 0.15);
    } else {
      debugPrint('No walk frames found for character $characterId');
      // Emergency blank animation fallback
      walkAnimation = SpriteAnimation.spriteList([], stepTime: 1.0);
    }

    // Attack pictures are optional.
    _attackSprites.clear();
    for (int i = 1; i <= 4; i++) {
      final sprite = await _tryLoadSprite('${characterId}_attack_$i');
      if (sprite != null) _attackSprites[i] = sprite;
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

  /// A picture from `assets/characters/`, or null when the file is not there.
  ///
  /// Checked against the asset list first, so a hero with fewer pictures (Lapu
  /// has 5 walk and 3 attack pictures) never asks for a file that is not there.
  Future<Sprite?> _tryLoadSprite(String name) async {
    final path = 'characters/$name.png';
    try {
      _assets ??= (await AssetManifest.loadFromAssetBundle(rootBundle))
          .listAssets()
          .toSet();
      if (!_assets!.contains('${game.images.prefix}$path')) return null;
      return await game.loadSprite(path);
    } catch (_) {
      return null;
    }
  }

  Set<String>? _assets;

  @override
  void update(double dt) {
    super.update(dt);

    if (_attackCooldownRemaining > 0) _attackCooldownRemaining -= dt;
    _moves.updatePages(dt);

    final pictureElapsed = _attackPictureElapsed;
    if (pictureElapsed != null) {
      final next = pictureElapsed + dt;
      _attackPictureElapsed = next >= _attackPictureLength ? null : next;
    }

    // Where the middle of the sprite is before any horizontal move this frame:
    // which side of a wall the player is on, if they run into one.
    final previousCentreX = position.x + size.x / 2;

    // Player-driven horizontal movement (GAMEPLAY-V2.md Section 3): -1..1,
    // from the joystick's pull or from the arrow buttons, so this both sets
    // speed and direction whichever control scheme is on screen.
    //
    // Ignored while knocked back: a hit takes the controls for the length of
    // the shove, so the student cannot walk back into the enemy at once and
    // use the invincibility that follows to pass through it.
    // Also ignored during a dash move, which moves the hero itself.
    final horizontalInput = _knockbackRemaining > 0 || _moves.dashing
        ? 0.0
        : game.gameInput.horizontal;
    if (horizontalInput != 0) {
      position.x += forwardSpeed * horizontalInput * dt;
      facingRight = horizontalInput > 0;
      // A footstep every so often while walking on the ground.
      if (isOnGround) {
        _stepTimer -= dt;
        if (_stepTimer <= 0) {
          _stepTimer = _stepSeconds;
          game.audioService.playStep();
        }
      }
    } else {
      _stepTimer = 0; // the first step sounds as soon as the walk starts
    }

    // Knockback from contact damage: a steady shove away from the enemy for
    // CombatConstants.knockbackDuration, covering knockbackDistance in all.
    // The player cannot steer during it (above). On the ground it stops at the
    // edge of the ledge, so a hit never throws anyone into a gap.
    if (_knockbackRemaining > 0) {
      position.x = keepOnGround(position.x + _knockbackVelocityX * dt);
      _knockbackRemaining -= dt;
      if (_knockbackRemaining <= 0) _knockbackVelocityX = 0;
    }

    // A dash move (Lapu-Lapu, Bonifacio) carries the hero forward: stopped at a
    // ledge here, and by a wall or a gate below (afterMove).
    _moves.stepDash(dt);

    // Never walk back past the level's start — there's no ground or
    // background authored to the left of it (Phase 4 gives levels real
    // bounds via Tiled).
    if (position.x < 0) position.x = 0;

    // Raised ground is solid at its sides (game_collision.dart). After every
    // horizontal move, before gravity, so a wall stops the player in the same
    // frame whatever moved them: the joystick or a knockback.
    resolveWalls(previousCentreX);

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
          // Every artifact answered, but the student never saw it open (the
          // trip to the gate normally does that): open it now. It asks nothing.
          game.openEndGate(gate);
        } else {
          // Blocked for a reason the student can act on: they still have
          // artifacts to find. Telling them beats silently refusing.
          game.showGateLockedNotice();
        }
      }
    }

    // A wall or a gate that pushed the hero back ends a dash.
    _moves.afterMove();

    // Apply gravity
    if (!isOnGround) {
      velocityY += gravity * dt;
      position.y += velocityY * dt;
    }

    final fallSpeed = velocityY;
    final onGround = resolveGroundContact();

    // A thud for a real landing, not for stepping down off a kerb.
    if (onGround && !isOnGround && fallSpeed > _thudSpeed) {
      game.audioService.playLand();
    }

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
    if (_windowInvincible) {
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

  final Paint _bubbleFill = Paint()..color = const Color(0x337FD3FF);
  final Paint _bubbleEdge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = const Color(0xCC9FE0FF);

  /// The Shield's bubble around the student, for as long as it is up.
  void _drawBubble(Canvas canvas) {
    final rect = Rect.fromLTWH(-6, -6, size.x + 12, size.y + 12);
    canvas.drawOval(rect, _bubbleFill);
    canvas.drawOval(rect, _bubbleEdge);
  }

  /// The picture to draw now: the swing's if one is showing, else the current
  /// frame of the walk, jump or hurt animation.
  Sprite? get _currentSprite {
    final number = attackPictureNumber;
    if (number != null) return _attackSprites[number];
    return animationTicker?.getSprite();
  }

  // Not calling super: it would draw the frame squeezed into the 96x120 box.
  @override
  // ignore: must_call_super
  void render(Canvas canvas) {
    if (!_flashVisible) return;

    // The art faces right. Facing left is mirrored by paintArt around the feet,
    // render-local: position.x IS worldX (camera, collision, spawner), so it must
    // not move. Restored before children (the hitbox) render.
    final sprite = _currentSprite;
    final dash = _moves.dashLook; // a dash move: ghosts, a slash and the safe ring
    final gliding = dash?.gliding ?? false;
    if (sprite != null) {
      if (dash != null && !gliding) {
        paintDashAfterimages(canvas, sprite,
            footX: size.x / 2, footY: size.y, facingRight: facingRight);
      }
      paintArt(
        canvas,
        sprite,
        footX: size.x / 2,
        footY: size.y,
        flip: !facingRight,
        overridePaint: paint,
      );
    }
    if (dash != null) {
      if (!gliding) {
        paintDashSlash(canvas,
            footX: size.x / 2,
            footY: size.y,
            facingRight: facingRight,
            progress: dash.progress,
            distance: dash.distance);
      }
      paintSafeRing(canvas, footX: size.x / 2, footY: size.y);
    }
    if (game.shieldActive) _drawBubble(canvas);
  }

  void jump() {
    if (isOnGround) {
      velocityY = jumpForce;
      isOnGround = false;
      animation = jumpAnim;
      game.audioService.playJump();
    }
  }

  /// Starts the attack picture sequence: [seconds] long, with the ground second
  /// picture (attack_4) from [secondAt]. Which sequence plays (ground or air) is
  /// decided by where the hero is now. Picture only: movement carries on.
  void showAttackPicture({
    double seconds = CombatConstants.attackHitboxDuration,
    double secondAt = _groundSecondPictureAt,
  }) {
    _attackInAir = !isOnGround;
    _attackPictureElapsed = 0;
    _attackPictureLength = seconds;
    _secondPictureAt = secondAt;
  }

  /// The hero's own move (2026-11, see hero_move_constants.dart): Juan's boomerang
  /// coin, Maria's net, Del Pilar's long shot, Lapu-Lapu's and Bonifacio's dashes,
  /// Luna's saber wave, Maria Clara's petals, Rizal's pages. One button, the hero
  /// decides. Needs at least one charge and an expired cooldown, but the charge is
  /// only spent when the move hits an enemy, so a miss is free. A dash needs the
  /// ground under the hero: in the air a dash hero uses the old short swing, so
  /// jump attacks still work.
  void attack() {
    if (_attackCooldownRemaining > 0) return;
    if (!game.canAttack) return;
    if (_moves.busyWithCounter) return;

    final move = heroMove;
    _attackCooldownRemaining = move.cooldown;
    if (move.isDash && isOnGround) {
      _moves.startDash();
    } else if (move.isDash) {
      showAttackPicture();
      _swingMelee();
    } else {
      showAttackPicture();
      _moves.fire();
    }
  }

  /// The old short swing: a box in front of the hero for 0.25 s that hits what it
  /// touches. What a dash hero does in the air.
  void _swingMelee() {
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
        drawSlash: !hasAttackArt,
      ),
    );
  }

  /// The hero's own move aimed at a boss attack (a right answer in the boss fight).
  /// [target] is where the attack is in world coordinates. The move plays its own
  /// picture and effect and calls [onImpact] at the moment it meets the attack:
  /// flying things when they reach `target.x` (a burst: its first page), a dash when
  /// it ends (the hero then glides back to where it stood). Called exactly once,
  /// whatever happens, and it spends no Kaalaman charge.
  void playCounter({required Vector2 target, required VoidCallback onImpact}) =>
      _moves.counter(target: target, onImpact: onImpact);

  void triggerHurt() {
    isHurt = true;
    _attackPictureElapsed = null; // hurt wins over a swing
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
  ///
  /// 300 until 2026-11-02, when a fall became "soft": the student comes back close to
  /// the edge they fell from (200 behind it is a run-up for the jump),
  /// safe from enemies for [CombatConstants.invincibilityDuration], and never behind
  /// the halfway flag once that is passed.
  static const double respawnRunway = 200;

  void respawn() {
    final centre = respawnAnchorX + size.x / 2;
    var x = respawnAnchorX - respawnRunway;
    // The block of ground they last stood on: back up along it, never off it,
    // and put them on its surface, which is not the base height on raised ground.
    var surfaceY = game.groundY;
    for (final section in game.groundSections) {
      if (centre >= section.position.x &&
          centre <= section.position.x + section.size.x) {
        if (x < section.position.x) x = section.position.x;
        // Once the halfway flag has been passed, a fall in that block never
        // puts the student back behind it.
        final flag = game.stats.checkpointX;
        if (flag != null &&
            x < flag &&
            flag <= section.position.x + section.size.x) {
          x = flag;
        }
        surfaceY = section.position.y;
        break;
      }
    }
    position.x = x < 0 ? 0 : x;
    position.y = surfaceY - size.y;
    velocityY = 0;
    isOnGround = true;
    // A moment to find their feet: flashing, and no enemy can hurt them.
    _invincibleUntil = DateTime.now().add(Duration(
        milliseconds: (CombatConstants.invincibilityDuration * 1000).round()));
    // A respawn cancels any in-flight knockback — otherwise the shove that
    // pushed the player into the gap keeps pushing once they are back.
    _knockbackVelocityX = 0;
    _knockbackRemaining = 0;
    _moves.cancel(); // and any dash or pages still on the way
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
      // The sprite boxes touch; what hurts is the drawn body against the enemy's own
      // hit area (CombatConstants.playerHurtWidthFraction).
      // A dizzy hopper, a rising enemy and a golden runner cannot hurt (surprises).
      if (!other.hurtsOnTouch || !_hurtBy(other)) return;
      _takeContactDamage(
        knockbackDirection: worldX < other.position.x ? -1 : 1,
      );
    }
  }

  /// A hit that is not an enemy touching the student (the boss's shockwave): the
  /// same damage, shove and safe moment, the same Shield.
  void takeHazardHit({required int knockbackDirection}) =>
      _takeContactDamage(knockbackDirection: knockbackDirection);

  /// Whether the drawn body (as [_hurtBy] measures it) overlaps a box: used by
  /// hazards that are not enemies.
  bool bodyOverlaps(double left, double top, double right, double bottom) {
    final hurtWidth = size.x * CombatConstants.playerHurtWidthFraction;
    final hurtLeft = position.x + (size.x - hurtWidth) / 2;
    final hurtBottom =
        position.y + size.y - CombatConstants.playerHurtFeetGrace;
    return hurtLeft < right &&
        hurtLeft + hurtWidth > left &&
        position.y < bottom &&
        hurtBottom > top;
  }

  /// The ring that bursts where the Shield's bubble was.
  void _popShield() {
    game.audioService.playShieldPop();
    final ring = CircleComponent(
      radius: 40,
      anchor: Anchor.center,
      position: position + size / 2,
      priority: 14,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFF7FD3FF),
    );
    ring.add(ScaleEffect.to(
      Vector2.all(2.2),
      EffectController(duration: 0.3, curve: Curves.easeOut),
    ));
    ring.add(OpacityEffect.fadeOut(
      EffectController(duration: 0.3),
      onComplete: ring.removeFromParent,
    ));
    game.world.add(ring);
  }

  /// Whether the part of the player that can be hurt overlaps the part of [enemy] that hurts.
  bool _hurtBy(EnemyComponent enemy) {
    final hurtWidth = size.x * CombatConstants.playerHurtWidthFraction;
    final hurtLeft = position.x + (size.x - hurtWidth) / 2;
    final hurtTop = position.y;
    final hurtBottom =
        position.y + size.y - CombatConstants.playerHurtFeetGrace;

    final hit = enemy.hitRect;

    return hurtLeft < hit.right &&
        hurtLeft + hurtWidth > hit.left &&
        hurtTop < hit.bottom &&
        hurtBottom > hit.top;
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is CoinComponent && !other.collected) {
      other.collect();
      game.collectCoin(onHighPlatform: other.onHighPlatform);
    }
    if (other is HeartPickupComponent) other.collect();
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
  ///
  /// Public because a dash move stops at a ledge by the same rule (hero_move_runner.dart).
  double keepOnGround(double x) {
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

    // A Shield turns one hit away as well as one wrong answer (2026-11-02): no
    // heart is lost, the bubble pops, and the usual shove and safe moment follow.
    if (game.shieldActive) {
      game.shieldActive = false;
      _popShield();
      game.notifyState();
    } else {
      game.loseLife();
    }
    _knockbackVelocityX = CombatConstants.knockbackForce * knockbackDirection;
    _knockbackRemaining = CombatConstants.knockbackDuration;
    _invincibleUntil = DateTime.now().add(
      Duration(
        milliseconds: (CombatConstants.invincibilityDuration * 1000).round(),
      ),
    );
  }
}
