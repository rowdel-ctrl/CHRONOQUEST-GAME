import 'dart:math' as math;
import 'dart:ui' show Canvas, Color, Rect;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/foundation.dart' show VoidCallback, visibleForTesting;
import '../answer_point_handler.dart';
import '../art_scale.dart';
import '../boss_plan.dart';
import '../chrono_game.dart';
import '../quiz_handler.dart';
import '../../core/constants.dart';
import '../../models/question.dart';
import '../level_loader.dart';
import 'boss_scroll_component.dart';
import 'boss_shockwave.dart';
import 'enemy_component.dart';
import 'heart_pickup_component.dart';

/// Boss component — displays actual images for idle, attack, and defeated states.
class BossComponent extends SpriteComponent with HasGameReference<ChronoGame> {
  final String eraId;
  /// Questions still to be answered right, out of [maxHealth] (every question of the level).
  /// Both are 0 until the component has loaded and counted the questions.
  int health = 0;
  int maxHealth = 0;
  bool reachedCenter = false;
  static const double walkSpeed = 50.0;
  bool isDefeated = false;

  late Sprite idleSprite;
  late Sprite attackSprite;
  late Sprite defeatedSprite;

  /// Optional pictures: shown when the boss takes damage and when a shockwave is
  /// released. Without them the attack picture stands in, as before.
  Sprite? hurtSprite;
  Sprite? specialSprite;

  /// Seconds the hurt / special picture still shows.
  double _hurtLeft = 0;
  double _specialLeft = 0;
  static const double _hurtSeconds = 0.4;
  static const double _specialSeconds = 0.3;

  // Cached velocity
  final Vector2 _velocity = Vector2.zero();

  // The fight: every question of the level once (BossQuestions), a wave of minions after every
  // second one, a wrong answer asked again at the back. Three phases (BossPlan).
  late final BossQuestions _questions;
  Question? _current;
  final List<EnemyComponent> _minions = [];
  bool _waveActive = false;
  double _waveTime = 0;

  /// Seconds until the next thing happens (the wave arriving, or the next
  /// question). Counted in [update], so it stops while a question is open.
  double _pause = 0;
  VoidCallback? _afterPause;

  /// The boss arena this fight happens in, or null for the old open-ground
  /// fight. In an arena the boss is already standing where the map put it and
  /// the camera does not follow the player out of the room.
  final LoadedLevel? arena;

  BossComponent({required this.eraId, this.arena});

  // The boss's own attack (2026-11-02). From phase 2, with each wave of minions, it
  // flashes red (the warning) and then sends a low shockwave along the floor towards
  // the student, who jumps it. Phase 2 sends one, phase 3 sends two.
  double _telegraph = 0;
  int _shockwavesLeft = 0;

  /// Seconds the camera is still shaking (a new phase), out of [_shakeSeconds].
  double _shakeLeft = 0;
  static const double _shakeSeconds = 0.6;

  /// Whether an attack is still on its way: a warning, a wave to come, or a wave
  /// still running. The next question waits for it.
  bool get attackBusy =>
      _telegraph > 0 ||
      _shockwavesLeft > 0 ||
      _sent.any((w) => !w.isRemoved && !w.isRemoving);

  /// The shockwaves sent so far. Tracked here, not looked up in the world, because a
  /// wave added this frame is not in the world's children until the next one.
  final List<BossShockwave> _sent = [];

  /// Seconds to answer the question being asked: shorter in each phase.
  double get answerSeconds => BossPlan.answerSeconds[_questions.phase];

  /// "PHASE 2" or "FINAL QUESTION" while it is announced, else null.
  String? banner;

  /// "Tanong 7 ng 22" from the boss's glow until the question opens, else null.
  String? askTag;

  /// In an arena the question waits on this scroll, far from the student (null otherwise).
  BossScrollComponent? scroll;
  Question? _waiting;

  /// Which side of the screen the scroll is off, for the arrow: -1 left, 1 right, 0 none.
  int scrollSide = 0;

  /// In an arena the boss paces slowly round the place the map gave it. It never chases.
  double _homeX = 0;
  double _paceTime = 0;
  static const double _paceRange = 100;
  static const double _paceSpeed = 0.5; // radians per second: 50 units/s at the widest

  final math.Random _random = math.Random();

  @override
  Future<void> onLoad() async {
    _questions = BossQuestions(game.questionPool?.all ?? const []);
    health = maxHealth = _questions.total;
    game.notifyState();
    final bossName = getEraById(eraId).bossName;
    idleSprite     = await game.loadSprite('bosses/${bossName}_idle.png');
    attackSprite   = await game.loadSprite('bosses/${bossName}_attack.png');
    defeatedSprite = await game.loadSprite('bosses/${bossName}_defeated.png');
    hurtSprite = await _tryLoad('${bossName}_hurt');
    specialSprite = await _tryLoad('${bossName}_special');

    sprite = idleSprite;
    size = Vector2(120, 140);
    final room = arena?.boss;
    if (room != null) {
      // Standing in place, the question coming after a moment to take the room in.
      position = Vector2(room.x - size.x / 2, room.y - size.y);
      _homeX = position.x;
      reachedCenter = true;
      _after(1.8, _showBossQuestion);
    } else {
      position = Vector2(game.cameraRightEdgeX + 20, game.groundY - size.y);
    }
    game.audioService.playBossAppear();
  }

  Future<Sprite?> _tryLoad(String name) async {
    try {
      return await game.loadSprite('bosses/$name.png');
    } catch (_) {
      return null; // optional picture: the attack picture stands in
    }
  }

  /// Hurt after damage, then special for the moment a shockwave is released, then
  /// attack for the red warning, else idle. Each falls back to the attack picture.
  void _refreshSprite() {
    if (isDefeated) return;
    if (_hurtLeft > 0) {
      sprite = hurtSprite ?? attackSprite;
    } else if (_specialLeft > 0) {
      sprite = specialSprite ?? attackSprite;
    } else if (_telegraph > 0) {
      sprite = attackSprite;
    } else {
      sprite = idleSprite;
    }
  }

  /// Bosses face left and are never mirrored. The picture's size is its own
  /// (art_scale.dart) with the middle of its bottom edge on the boss's feet.
  @override
  // ignore: must_call_super
  void render(Canvas canvas) {
    final art = sprite;
    if (art == null) return;
    paintArt(canvas, art,
        footX: size.x / 2, footY: size.y, overridePaint: paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDefeated) return;

    if (_hurtLeft > 0) _hurtLeft -= dt;
    if (_specialLeft > 0) _specialLeft -= dt;
    _updateAttack(dt);
    _refreshSprite();
    _updateShake(dt);

    // Recomputed every frame since the camera keeps advancing with the
    // player — this is the world x that currently sits at screen-center.
    final centerX = game.cameraLeftEdgeX + game.size.x / 2 - size.x / 2;
    if (!reachedCenter) {
      _velocity.setValues(-walkSpeed, 0);
      position.addScaled(_velocity, dt);
      if (position.x <= centerX) {
        position.x = centerX;
        reachedCenter = true;
        _showBossQuestion();
      }
    } else {
      // Stay locked at screen-center as the world advances underneath. In an
      // arena the boss keeps the place the map gave it.
      if (arena == null) {
        position.x = centerX;
      } else {
        _pace(dt);
        _updateScroll();
      }
      _updateFight(dt);
    }
  }

  void _pace(double dt) {
    _paceTime += dt;
    position.x = _homeX + math.sin(_paceTime * _paceSpeed) * _paceRange;
  }

  /// The scroll: opens its question when the student touches it, and keeps the arrow right.
  void _updateScroll() {
    final s = scroll;
    final q = _waiting;
    if (s == null || q == null || !s.isMounted || isDefeated) return;
    final p = game.player;
    if (s.touches(Rect.fromLTWH(p.position.x, p.position.y, p.size.x, p.size.y))) {
      scroll = null;
      _waiting = null;
      askTag = null;
      scrollSide = 0;
      s.removeFromParent();
      game.showBossQuestion(q, this);
      return;
    }
    final side = s.position.x < game.cameraLeftEdgeX
        ? -1
        : (s.position.x > game.cameraRightEdgeX ? 1 : 0);
    if (side != scrollSide) {
      scrollSide = side;
      game.notifyState();
    }
  }

  void _updateFight(double dt) {
    if (_afterPause != null) {
      _pause -= dt;
      if (_pause <= 0) {
        final next = _afterPause!;
        _afterPause = null;
        next();
      }
      return;
    }
    if (!_waveActive) return;

    _waveTime += dt;
    // A minion still loading is not mounted yet, so it is not "gone" until it
    // has loaded and then left the world.
    _minions.removeWhere((m) => m.defeated || (m.isLoaded && !m.isMounted));
    if ((_minions.isEmpty && !attackBusy) ||
        _waveTime >= GameConstants.bossWaveTimeoutSeconds) {
      _waveActive = false;
      _after(0.5, _showBossQuestion);
    }
  }

  /// Where the [count] minions of a wave stand (left x, and the surface they
  /// stand on, or null for the base ground).
  ///
  /// In an arena they come from the map's spots, the ones furthest from the
  /// player first and alternating sides, so a wave is spread across the room
  /// and never lands on the student. With no arena they stand just past the
  /// right edge of the screen, as before.
  List<({double x, double? surfaceY})> _spotsForWave(int count) {
    final spots = arena?.minionSpawns ?? const [];
    if (spots.isEmpty) {
      final firstX = game.cameraRightEdgeX + 40;
      return [for (var i = 0; i < count; i++) (x: firstX + i * 130, surfaceY: null)];
    }
    final playerX = game.player.worldX + game.player.size.x / 2;
    final byDistance = [...spots]
      ..sort((a, b) => (b.x - playerX).abs().compareTo((a.x - playerX).abs()));
    final out = <({double x, double? surfaceY})>[];
    for (var i = 0; i < count; i++) {
      final s = byDistance[i % byDistance.length];
      // Two minions never share a spot: the next one is nudged along.
      final nudge = (i ~/ byDistance.length) * 90.0;
      out.add((
        x: s.x - EnemyComponent.spriteWidth / 2 + nudge,
        surfaceY: s.y < game.groundY - 1 ? s.y : null,
      ));
    }
    return out;
  }

  void _after(double seconds, VoidCallback what) {
    _pause = seconds;
    _afterPause = what;
  }

  void takeDamage() {
    health--;
    _hurtLeft = _hurtSeconds;
    _refreshSprite();

    _questions.solve();
    if (health <= 0) {
      defeat();
    } else {
      _afterAnswer();
    }
  }

  /// After an answer: a wave of minions on every second question, else straight on.
  void _afterAnswer() {
    if (_questions.asked % BossPlan.questionsPerWave == 0) {
      // In an arena the wave and the next scroll come together: the student has to cross
      // the room with the minions about, not clear them first.
      _after(0.8, arena == null ? _spawnWave : () {
        _spawnWave();
        _showBossQuestion();
      });
    } else {
      _after(0.8, _showBossQuestion);
    }
  }

  /// A wrong answer, or the clock running out: the boss takes no damage and the question goes
  /// to the back of the line to be asked again.
  void missed() {
    if (isDefeated) return;
    final q = _current;
    if (q != null) _questions.again(q);
    _afterAnswer();
  }

  void _spawnWave() {
    _minions.removeWhere((m) => m.defeated || (m.isLoaded && !m.isMounted));
    final room = arena != null;
    // Minions left alive from earlier waves are not added to without end.
    final count = room && _minions.length >= BossPlan.maxLiveMinions
        ? 0
        : BossPlan.minionsPerWave[_questions.phase];
    final spots = _spotsForWave(count);
    for (var i = 0; i < count; i++) {
      final minion = EnemyComponent(
        eraId: eraId,
        worldX: spots[i].x,
        surfaceY: spots[i].surfaceY,
        onDefeated: () {
          game.grantCharges(1);
          game.audioService.playPowerup();
        },
      );
      _minions.add(minion);
      game.world.add(minion);
    }
    // In an arena the next question does not wait for the wave (see [_afterAnswer]).
    _waveActive = !room;
    _waveTime = 0;
    _startAttack();
  }

  /// Phase 2 and 3: the warning, then the first shockwave.
  void _startAttack() {
    final phase = _questions.phase;
    if (phase < 1 || isDefeated) return;
    _shockwavesLeft = phase; // 1 in phase 2, 2 in phase 3
    _beginTelegraph(BossPlan.telegraphSeconds);
  }

  /// Starts the red warning and one shockwave without going through the phases.
  @visibleForTesting
  void warnForTest() {
    _shockwavesLeft = 1;
    _beginTelegraph(BossPlan.telegraphSeconds);
  }

  void _beginTelegraph(double seconds) {
    _telegraph = seconds;
    game.audioService.playBossWarning(short: seconds < BossPlan.telegraphSeconds);
    _refreshSprite();
    add(ColorEffect(
      const Color(0xFFFF3B30),
      EffectController(
          duration: seconds / 6, reverseDuration: seconds / 6, repeatCount: 3),
      opacityFrom: 0,
      opacityTo: 0.6,
    ));
  }

  void _updateAttack(double dt) {
    if (_telegraph <= 0) return;
    _telegraph -= dt;
    if (_telegraph > 0) return;
    _sendShockwave();
    _specialLeft = _specialSeconds;
    _shockwavesLeft--;
    if (_shockwavesLeft > 0) {
      _beginTelegraph(BossPlan.secondTelegraphSeconds);
    }
    _refreshSprite();
  }

  void _sendShockwave() {
    final player = game.player;
    final bossMid = position.x + size.x / 2;
    final dir = (player.position.x + player.size.x / 2) >= bossMid ? 1 : -1;
    final startX = dir > 0
        ? position.x + size.x
        : position.x - BossShockwave.waveWidth;
    final room = arena;
    final wave = BossShockwave(
      direction: dir,
      start: Vector2(startX, game.groundY - BossShockwave.waveHeight),
      limitX: room == null ? null : (dir > 0 ? room.mapWidth : 0),
    );
    _sent
      ..removeWhere((w) => w.isRemoved)
      ..add(wave);
    game.world.add(wave);
    game.audioService.playShockwave();
  }

  void _updateShake(double dt) {
    if (_shakeLeft <= 0) return;
    _shakeLeft -= dt;
    if (_shakeLeft <= 0) {
      game.cameraShake.setZero();
      return;
    }
    final amp = 10 * (_shakeLeft / _shakeSeconds);
    final t = _shakeSeconds - _shakeLeft;
    game.cameraShake.setValues(math.sin(t * 80) * amp, math.cos(t * 95) * amp * .6);
  }

  /// A new phase, or the last question: the boss changes colour and the screen
  /// shakes. Phase 2 also drops a heart for a student who is missing some.
  void _mood(String label) {
    switch (label) {
      case 'PHASE 2':
        tint(const Color(0x40FF3B30));
        _dropHeart();
      case 'PHASE 3':
        tint(const Color(0x70FF3B30));
      default: // FINAL QUESTION: pale and unsteady
        tint(const Color(0x66CFE8FF));
    }
    _shakeLeft = _shakeSeconds;
    game.audioService.playBossPhase();
  }

  void _dropHeart() {
    if (game.hearts >= GameConstants.maxHearts) return;
    final p = game.player;
    final room = arena;
    final lo = room == null ? game.cameraLeftEdgeX + 80 : 80.0;
    final hi = room == null ? game.cameraRightEdgeX - 120 : room.mapWidth - 120;
    final toward = (position.x + size.x / 2) >= p.position.x ? 1 : -1;
    final x = (p.position.x + toward * 220).clamp(lo, math.max(lo, hi)).toDouble();
    game.world.add(HeartPickupComponent(
      spawnPosition: Vector2(x, p.position.y + p.size.y - 100),
    ));
  }

  void defeat() {
    isDefeated = true;
    scroll?.removeFromParent();
    scroll = null;
    _waiting = null;
    askTag = null;
    scrollSide = 0;
    sprite = defeatedSprite;
    game.audioService.stopBgm(); // the music stops so the victory sound is clear
    game.audioService.playBossDefeat();
    game.overlays.remove('BossHealthOverlay');
    Future.delayed(const Duration(seconds: 1), () {
      removeFromParent();
      game.levelComplete();
    });
  }

  void _showBossQuestion() {
    final q = _questions.next();
    if (q == null) {
      defeat(); // a boss with no questions cannot be fought
      return;
    }
    _current = q;
    final label = _questions.takeBanner();
    if (label == null) {
      _ask(q);
      return;
    }
    // A new phase, or the last question: say so for a moment, then ask it.
    banner = label;
    _mood(label);
    game.notifyState();
    _after(1.6, () {
      banner = null;
      game.notifyState();
      _ask(q);
    });
  }

  /// The lead-in to a question: the boss glows gold and the screen says which one is coming.
  /// Then, in an arena, the scroll appears far away; otherwise the question opens.
  void _ask(Question q) {
    askTag = BossPlan.questionTag(_questions.solved, _questions.total);
    game.audioService.playBossAsk();
    add(ColorEffect(
      const Color(0xFFFFD54A),
      EffectController(
          duration: BossPlan.leadInSeconds / 2, reverseDuration: BossPlan.leadInSeconds / 2),
      opacityFrom: 0,
      opacityTo: 0.65,
    ));
    game.notifyState();
    _after(BossPlan.leadInSeconds, () {
      if (isDefeated) return;
      if (arena == null) {
        askTag = null;
        game.notifyState();
        game.showBossQuestion(q, this);
      } else {
        _dropScroll(q);
      }
    });
  }

  void _dropScroll(Question q) {
    final room = arena!;
    final p = game.player;
    final spot = BossPlan.scrollSpot(
      room.minionSpawns,
      p.position.x + p.size.x / 2,
      [for (final m in _minions) if (m.isMounted) m.position.x],
      _random,
    );
    if (spot == null) {
      // A map with no spots: the question just opens.
      askTag = null;
      game.notifyState();
      game.showBossQuestion(q, this);
      return;
    }
    final surface = spot.y < game.groundY - 1 ? spot.y : game.groundY;
    final made = BossScrollComponent(centerX: spot.x, surfaceY: surface);
    scroll = made;
    _waiting = q;
    game.world.add(made);
    game.notifyState();
  }
}