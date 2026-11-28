import 'dart:math' as math;
import 'dart:ui' show BlendMode, Canvas, Color, ColorFilter, MaskFilter, BlurStyle, Paint;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../core/boss_attack_constants.dart';
import '../../core/combat_constants.dart';
import '../../core/constants.dart';
import '../../data/question_bank.dart';
import '../../models/question.dart';
import '../art_scale.dart';
import '../boss_attack_profile.dart';
import '../boss_countdown.dart';
import '../boss_plan.dart';
import '../chrono_game.dart';
import '../level_loader.dart';
import '../quiz_handler.dart';
import 'boss_attack_component.dart';
import 'boss_rune_component.dart';
import 'enemy_component.dart';
import '../enemy_behavior.dart';
import 'boss_attack_paint.dart' show star;
import 'boss_fx_component.dart';
import 'boss_wave_warning.dart';
import 'coin_component.dart';
import 'heart_pickup_component.dart';
import 'powerup_pickup_component.dart';

/// Where a boss round is.
enum BossRoundState {
  /// A moment to take the room in before the first round.
  intro,

  /// A rune is on the floor, away from the student. Walking up to it (or waiting 15 s) makes
  /// the boss throw.
  rune,

  /// A wave of minions between two rounds: the student fights them, then the next rune comes.
  wave,

  /// The boss glows and draws back. No question yet.
  windup,

  /// The attack is flying and the question is open; its timer is the attack's flight.
  asking,

  /// A wrong answer: the attack rushes the rest of the way in.
  rush,

  /// A right answer: the hero's counter is on its way to the attack.
  counter,

  /// The attack is sent back at the boss.
  reflect,

  /// A hit has landed (on the boss or on the hero); the next round comes in a moment.
  rest,

  /// The fight is over (the boss fell, or the hero ran out of hearts).
  ended,
}

/// The boss. It stands on its stage and fights in 22 rounds. A round starts when the student
/// walks up to a rune (or after 15 s without): the boss turns to him, winds up, throws an attack
/// that flies from it to the hero, and the question opens at once. The attack's flight is the
/// answer timer. A right answer makes the hero counter the attack (the boss loses 1 of 22
/// health), a wrong answer or no answer lets it hit the hero (-1 heart) and the question comes
/// back later. After every second round a wave of minions comes before the next rune.
///
/// Everything is counted in [update] with the frame's `dt`, so pausing the game pauses the fight.
class BossComponent extends SpriteComponent with HasGameReference<ChronoGame> {
  final String eraId;

  /// The boss arena this fight happens in, or null for the old open-ground fight. In an arena
  /// the boss stands where the map put it and the camera does not follow the hero out of the
  /// room.
  final LoadedLevel? arena;

  BossComponent({required this.eraId, this.arena});

  late final BossProfile profile = BossProfile.forEra(eraId);

  /// Questions still to be answered right, out of [maxHealth] (the rounds of the fight).
  /// Both are 0 until the component has loaded and counted the questions.
  int health = 0;
  int maxHealth = 0;
  bool reachedCenter = false;
  bool isDefeated = false;

  /// Set while the boss defeat sequence draws the boss itself (see boss_defeat.dart).
  bool hideArt = false;

  late Sprite idleSprite;
  late Sprite attackSprite;
  late Sprite defeatedSprite;

  /// Optional pictures: shown when the boss takes damage, and for the phase 3 attacks. Without
  /// them the attack picture stands in.
  Sprite? hurtSprite;
  Sprite? specialSprite;

  late final BossQuestions _questions;
  Question? _current;
  BossRoundState state = BossRoundState.intro;
  double _t = 0; // seconds in the current state
  double _clk = 0; // seconds since the fight began, for breathing and wobbling

  BossCountdown? _clock;
  bool _resolved = false;
  bool _cardClosed = true;
  int _counterToken = 0;
  double _rushRate = 0;

  /// The attack in flight (null between rounds).
  BossAttackComponent? attack;
  BossAttackKind? _kind;

  /// The rune waiting to be touched (null outside the rune state).
  BossRuneComponent? rune;

  /// The minions of the wave being fought, and how many rounds have been played (right or wrong).
  final List<EnemyComponent> _minions = [];

  /// Minions of the wave that have not appeared yet: each waits at its spot under a red warning.
  final List<_PendingSpawn> _pending = [];
  int _played = 0;

  /// The hearts and power-ups this wave has dropped so far (capped, see BossAttackConstants).
  int _waveHearts = 0;
  int _wavePowerUps = 0;
  double _waveClear = 0;
  final math.Random _random = math.Random();

  /// Which surface the last rune stood on, so the next one is on another, and how long the student has
  /// to reach this rune before the boss throws anyway (more for a rune up a block).
  int _lastRuneSurface = -1;

  /// For tests: replaces the random roll that decides whether this rune goes up on raised ground (a roll under
  /// [BossAttackConstants.runeRaisedChance] does): 0 always, 1 never.
  @visibleForTesting
  double? runeRaisedRollOverride;

  /// Which surface the last rune stood on (for tests).
  @visibleForTesting
  int get lastRuneSurface => _lastRuneSurface;
  double _runeLimit = BossAttackConstants.runeStallSeconds;

  /// Whether the last round began because the student waited too long for the rune.
  bool stalled = false;

  /// Which side of the boss the hero is on: -1 left, 1 right. It follows him between rounds and
  /// is kept for the whole of a round (he cannot cross the boss while a question is on).
  int _side = -1;

  /// Whether the boss is turned to its right (the hero is on that side).
  bool get facesRight => _side > 0;

  /// Starts a round at once (for tests; the game starts it by touching a rune).
  @visibleForTesting
  void startRoundNow() {
    rune?.removeFromParent();
    rune = null;
    _startRound();
  }

  /// What the student chose in the round being played ('' when time ran out), null before.
  String? lastAnswer;

  // looks
  double _hurtLeft = 0;
  double _dizzyLeft = 0;
  double _shakeLeft = 0;
  double _defeatLeft = 0;
  bool _finished = false;

  // ---------- what the HUD and the question card read ----------

  /// The round being played (1 to [maxHealth]): one more than the answers already right.
  int get round => math.min(_questions.round, math.max(1, maxHealth));

  /// 1 to 3.
  int get phase => BossPlan.phaseOfRound(round);

  /// Seconds the student has in this round: the attack's flight time. The teacher can set the
  /// number (QuestionBank.bossSeconds); otherwise a long question gets reading time added.
  double get answerSeconds => BossPlan.secondsFor(round,
      question: _current, teacherSeconds: QuestionBank.bossSeconds);

  String get roundTag => BossPlan.roundTag(round, maxHealth);
  String get phaseTag => BossPlan.phaseTag(round, seconds: answerSeconds);

  /// The attack thrown in this round (null before the first).
  BossAttackKind? get attackKind => _kind;

  /// Whether a question is open and waiting for an answer.
  bool get asking => state == BossRoundState.asking && !_resolved;

  double get secondsLeft => _clock?.secondsLeft ?? 0;
  double get clockFraction => _clock?.fraction ?? 0;
  bool get frozen => _clock?.frozen ?? false;

  /// Seconds of Time Freeze left (0 when not frozen) and whether it was already used on this question.
  double get frozenSecondsLeft => _clock?.frozenLeft ?? 0;
  bool get freezeUsed => _clock?.usedFreeze ?? false;

  /// The minions of the wave (for tests).
  @visibleForTesting
  List<EnemyComponent> get minions => _minions;

  /// The red warnings still showing, one for each minion that has not appeared yet (for tests).
  @visibleForTesting
  List<BossWaveWarning> get warnings => [for (final p in _pending) p.warning];

  /// How many minions of the wave have not appeared yet.
  int get minionsComing => _pending.length;

  /// Ends the wave now, minions or not (for tests, and nothing else calls it).
  @visibleForTesting
  void endWave() {
    if (state != BossRoundState.wave) return;
    for (final m in _minions) {
      if (m.isMounted) m.removeFromParent();
    }
    _minions.clear();
    _clearPending();
    _beginRune();
  }

  /// Seconds the rune has waited for the student.
  double get runeWaited => state == BossRoundState.rune ? _t : 0;

  /// Minions of the current wave still standing.
  int get minionsAlive => _minions.where(_isAlive).length;
  static bool _isAlive(EnemyComponent m) => !(m.defeated || m.isRemoved || m.isRemoving);

  /// Seconds the student has spent on this question (Time Freeze time does not count).
  int get elapsedSeconds => ((_clock?.seconds ?? 0) - secondsLeft).floor();

  /// How far the attack has come: 0 at the boss, 1 at the hero. Reaches 1 exactly when the
  /// time is up.
  double get attackProgress => attack?.progress ?? 0;

  // ---------- loading ----------

  @override
  Future<void> onLoad() async {
    _questions = BossQuestions(game.questionPool?.all ?? const []);
    health = maxHealth = _questions.total;
    game.notifyState();
    final bossName = getEraById(eraId).bossName;
    idleSprite = await game.loadSprite('bosses/${bossName}_idle.png');
    attackSprite = await game.loadSprite('bosses/${bossName}_attack.png');
    defeatedSprite = await game.loadSprite('bosses/${bossName}_defeated.png');
    hurtSprite = await _tryLoad('${bossName}_hurt');
    specialSprite = await _tryLoad('${bossName}_special');

    sprite = idleSprite;
    size = Vector2(120, 140);
    final room = arena?.boss;
    if (room != null) {
      position = Vector2(room.x - size.x / 2, room.y - size.y);
    } else {
      position = Vector2(_screenCentreX, game.groundY - size.y);
    }
    reachedCenter = true;
    game.audioService.playBossAppear();
  }

  double get _screenCentreX => game.cameraLeftEdgeX + game.size.x / 2 - size.x / 2;

  Future<Sprite?> _tryLoad(String name) async {
    try {
      return await game.loadSprite('bosses/$name.png');
    } catch (_) {
      return null; // optional picture: the attack picture stands in
    }
  }

  // ---------- where things are ----------

  double get _bossX => position.x + size.x / 2;
  double get _bossFeet => position.y + size.y;

  /// +1 when the hero is on the boss's left (offsets in the data point left), -1 on its right.
  double get _toward => -_side.toDouble();

  Vector2 _startPoint(BossAttackKind k) =>
      Vector2(_bossX + k.start.dx * _toward, _bossFeet - k.start.up);

  Vector2 _heroPoint(BossAttackKind k) {
    final p = game.player;
    return Vector2(p.position.x + p.size.x / 2 + k.end.dx * _toward, p.position.y + p.size.y - k.end.up);
  }

  Vector2 get _bossHitPoint => Vector2(_bossX + profile.hitDx * _toward, _bossFeet - profile.hitUp);

  // ---------- looks ----------

  /// The picture of the throw: the special one for the phase 3 attacks, else the attack one.
  Sprite get _poseSprite {
    final k = _kind;
    return (k != null && k.usesSpecialPose) ? (specialSprite ?? attackSprite) : attackSprite;
  }

  /// The attack pictures all face the hero, but most idle pictures face the front. So from the
  /// wind-up on the boss shows its attack picture (the one that faces the hero) and keeps it
  /// through the round. The phase 3 special pictures carry figures of their own and keep the old
  /// short timing.
  bool get _posing {
    final k = _kind;
    final holds = k != null && !k.usesSpecialPose;
    switch (state) {
      case BossRoundState.windup:
        return _t >= BossAttackConstants.windupSeconds * (holds ? _turnEnd : 0.5);
      case BossRoundState.asking:
        return holds || _t < BossAttackConstants.throwPoseSeconds;
      case BossRoundState.rush:
      case BossRoundState.counter:
      case BossRoundState.reflect:
        return holds;
      default:
        return false;
    }
  }

  // The turn to face the hero: a quick squash from this share of the wind-up to [_turnEnd].
  static const double _turnStart = 0.2;
  static const double _turnEnd = 0.35;

  void _refreshSprite() {
    if (isDefeated) return;
    if (_hurtLeft > 0.15) {
      sprite = hurtSprite ?? attackSprite;
    } else if (_posing) {
      sprite = _poseSprite;
    } else {
      sprite = idleSprite;
    }
  }

  double get _poseShift {
    if (sprite == idleSprite || sprite == hurtSprite || sprite == defeatedSprite) return 0;
    final k = _kind;
    return (k != null && k.usesSpecialPose) ? profile.specialShift : profile.attackShift;
  }

  /// Bosses face left and are never mirrored. The picture's size is its own (art_scale.dart)
  /// with the middle of its bottom edge on the boss's feet.
  @override
  // ignore: must_call_super
  void render(Canvas canvas) {
    final art = sprite;
    if (art == null || hideArt) return;
    var footX = size.x / 2 + _poseShift;
    if (state == BossRoundState.windup) {
      final u = (_t / BossAttackConstants.windupSeconds).clamp(0.0, 1.0);
      footX += 8 * u * u * (3 - 2 * u); // draws back
    }
    if (_hurtLeft > 0) footX += math.sin(_clk * 70) * 3;
    canvas.save();
    if (_side > 0) {
      // The pictures face left: turn to the hero on the right.
      canvas.translate(size.x / 2, 0);
      canvas.scale(-1, 1);
      canvas.translate(-size.x / 2, 0);
    }
    if (!isDefeated && _hurtLeft <= 0) {
      var squash = 1.0;
      if (state == BossRoundState.windup) {
        final u = ((_t / BossAttackConstants.windupSeconds - _turnStart) / (_turnEnd - _turnStart))
            .clamp(0.0, 1.0);
        squash = u >= 1 || u <= 0 ? 1.0 : 0.3 + 0.7 * u;
      }
      canvas.translate(footX, size.y);
      canvas.scale(squash, 1 + .012 * math.sin(_clk * 3));
      canvas.translate(-footX, -size.y);
    }
    if (state == BossRoundState.windup && !isDefeated) {
      // The glow: a soft silhouette in the boss's colour behind the picture.
      final glow = Paint()
        ..colorFilter = ColorFilter.mode(
            profile.glow.withValues(alpha: .85), BlendMode.srcIn)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7 + 4 * math.sin(_clk * 10));
      paintArt(canvas, art, footX: footX, footY: size.y, overridePaint: glow);
    }
    paintArt(canvas, art, footX: footX, footY: size.y, overridePaint: paint);
    canvas.restore();
    if (_dizzyLeft > 0) _paintDizzy(canvas);
  }

  void _paintDizzy(Canvas canvas) {
    final a = math.min(1.0, _dizzyLeft / .3);
    final cx = size.x / 2, cy = size.y - 150;
    for (var k = 0; k < 3; k++) {
      final an = _clk * 6 + k * 2.094;
      star(canvas, cx + math.cos(an) * 28, cy + math.sin(an) * 7,
          5 + (math.sin(an) > 0 ? 2 : 0), const Color(0xFFFFD24A).withValues(alpha: a));
    }
  }

  // ---------- the fight ----------

  @override
  void update(double dt) {
    super.update(dt);
    _clk += dt;
    if (isDefeated) {
      _tickDefeat(dt);
      return;
    }
    _tickLooks(dt);
    if (arena == null && reachedCenter) position.x = _screenCentreX;
    if (game.levelEnded) {
      // Failed (the last heart is gone) or finished: nothing more happens here.
      if (state != BossRoundState.ended) _endFight();
      return;
    }
    if (state == BossRoundState.intro || state == BossRoundState.rune || state == BossRoundState.wave) {
      _side = _heroCentre >= _bossX ? 1 : -1;
    }
    _keepHero();
    _t += dt;
    switch (state) {
      case BossRoundState.intro:
        if (_t >= BossAttackConstants.introSeconds) _beginRune();
      case BossRoundState.rune:
        _tickRune();
      case BossRoundState.wave:
        _tickWave(dt);
      case BossRoundState.windup:
        if (_t >= BossAttackConstants.windupSeconds) _launch();
      case BossRoundState.asking:
        _tickAsking(dt);
      case BossRoundState.rush:
        _tickRush(dt);
      case BossRoundState.counter:
        // The hero's move always answers; if it somehow never does, go on.
        if (_t >= BossAttackConstants.counterTimeoutSeconds) _onImpact(_counterToken);
      case BossRoundState.reflect:
        _tickReflect();
      case BossRoundState.rest:
        _tickRest();
      case BossRoundState.ended:
        break;
    }
    _refreshSprite();
  }

  void _tickLooks(double dt) {
    if (_hurtLeft > 0) _hurtLeft = math.max(0, _hurtLeft - dt);
    if (_dizzyLeft > 0) _dizzyLeft = math.max(0, _dizzyLeft - dt);
    // A white flash while it is hurt, fading in the first 0.25 s.
    final flash = ((_hurtLeft - .3) / .25).clamp(0.0, .75);
    paint.colorFilter =
        flash > 0 ? ColorFilter.mode(Color.fromRGBO(255, 255, 255, flash), BlendMode.srcATop) : null;
    if (_shakeLeft > 0) {
      _shakeLeft = math.max(0, _shakeLeft - dt);
      if (_shakeLeft == 0) {
        game.cameraShake.setZero();
      } else {
        final amp = 9 * (_shakeLeft / BossAttackConstants.hitShakeSeconds);
        final t = BossAttackConstants.hitShakeSeconds - _shakeLeft;
        game.cameraShake.setValues(math.sin(t * 80) * amp, math.cos(t * 95) * amp * .6);
      }
    }
  }

  /// While a round is on the hero keeps to his side of the boss (right up to it, not past it), so
  /// the attack always flies the same way and the boss faces him. Between rounds, looking for a
  /// rune or fighting minions, the whole room is his: he can cross over the stage to the other
  /// side. He is let go while his counter is moving him about.
  void _keepHero() {
    if (state == BossRoundState.counter || state == BossRoundState.reflect) return;
    final p = game.player;
    final spot = arena?.boss;
    final inRound = state == BossRoundState.windup ||
        state == BossRoundState.asking ||
        state == BossRoundState.rush ||
        state == BossRoundState.rest;
    if (!inRound) return; // looking for a rune or fighting minions: the whole room is his
    p.facingRight = _side < 0;
    if (spot == null) return;
    const gap = BossAttackConstants.heroBossGap;
    final centre = p.position.x + p.size.x / 2;
    if (_side < 0 && centre > spot.x - gap) {
      p.position.x = spot.x - gap - p.size.x / 2;
    } else if (_side > 0 && centre < spot.x + gap) {
      p.position.x = spot.x + gap - p.size.x / 2;
    }
  }

  // ---------- the rune and the waves ----------

  /// Flat floor on both sides of the boss's stage where a rune or a minion may stand: base
  /// ground only (not the stage, its steps or the walls), away from the ends of each stretch.
  List<({double x, double y})> floorSpots() => [for (final run in floorRuns()) ...run];

  /// The same spots grouped by stretch of floor: one stretch is ground you can walk along from
  /// end to end (a pool, a gap or the stage cuts the floor in two). A minion can only reach a
  /// student on its own stretch.
  List<List<({double x, double y})>> floorRuns() {
    final room = arena;
    final spot = room?.boss;
    if (room == null || spot == null) {
      // The old open-ground fight: the floor in view.
      final left = game.cameraLeftEdgeX + 80;
      return [
        [for (var x = left; x <= left + game.size.x - 160; x += 24) (x: x, y: game.groundY)]
      ];
    }
    final runs = <List<({double x, double y})>>[];
    final base = game.groundY;
    const margin = BossAttackConstants.runeEdgeMargin;
    for (final b in room.blocks) {
      if ((b.topY - base).abs() > 1) continue;
      if (b.startX < spot.x + 168 && b.startX + b.width > spot.x - 168) continue; // on or beside the stage
      final run = <({double x, double y})>[
        for (var x = b.startX + margin; x <= b.startX + b.width - margin; x += 24) (x: x, y: b.topY)
      ];
      if (run.isNotEmpty) runs.add(run);
    }
    return runs;
  }

  /// Where a rune may stand: every floor spot (as in [floorSpots]) and, in an arena, the top of every
  /// raised block and ledge the student can stand on (the arena solver has proven each reachable).
  /// [surface] tells which floor, block or ledge a spot is on. The stage and its steps and the end walls
  /// are left out, and a rune keeps off the edge of what it stands on (less on a small block, so a block
  /// 2 tiles wide still gets one in its middle).
  @visibleForTesting
  List<({double x, double y, int surface})> runeSpots() {
    final out = <({double x, double y, int surface})>[];
    final runs = floorRuns();
    for (var i = 0; i < runs.length; i++) {
      for (final s in runs[i]) {
        out.add((x: s.x, y: s.y, surface: i));
      }
    }
    final room = arena;
    final stage = room?.boss;
    if (room == null || stage == null) return out;
    final base = game.groundY;
    final lastEnd = room.blocks.isEmpty ? 0.0 : room.blocks.map((b) => b.endX).reduce(math.max);
    void top(double x0, double x1, double y, int surface) {
      final w = x1 - x0;
      if (w < 48) return;
      final m = math.min(BossAttackConstants.runeEdgeMargin, (w - 24) / 2);
      var any = false;
      for (var x = x0 + m; x <= x1 - m + 0.01; x += 24) {
        out.add((x: x, y: y, surface: surface));
        any = true;
      }
      if (!any) out.add((x: (x0 + x1) / 2, y: y, surface: surface));
    }

    for (var i = 0; i < room.blocks.length; i++) {
      final b = room.blocks[i];
      if (b.topY >= base - 1) continue; // base ground: the floor spots above
      if (b.startX <= 1 || b.endX >= lastEnd - 1) continue; // an end wall
      if (b.startX < stage.x + 168 && b.endX > stage.x - 168) continue; // the stage and its steps
      top(b.startX, b.endX, b.topY, 1000 + i);
    }
    var p = 0;
    for (final e in room.entities) {
      if (e.type != 'platform') continue;
      top(e.x, e.x + e.width, e.y, 2000 + p++);
    }
    return out;
  }

  /// A fallen minion pays one Kaalaman charge back.
  void _payCharge() {
    game.kaalaman = (game.kaalaman + 1).clamp(0, CombatConstants.kaalamanDisplayMax);
    game.notifyState();
  }

  double get _heroCentre => game.player.position.x + game.player.size.x / 2;

  void _float(String text, Color color) {
    final p = game.player;
    game.world.add(BossFloatText(
        text: text, at: Vector2(_heroCentre, p.position.y - 40), color: color));
  }

  void _beginRune() {
    if (isDefeated) return;
    if (_questions.isDone) {
      defeat(); // a boss with no questions cannot be fought
      return;
    }
    state = BossRoundState.rune;
    _t = 0;
    stalled = false;
    final all = runeSpots();
    if (all.isEmpty) {
      _startRound(); // nowhere to put a rune: just go on
      return;
    }
    // Half the rounds (when the room has raised ground) the rune is on a block or a ledge, so the
    // student sometimes has to climb for it; never on the same surface twice in a row.
    final raisedSpots = [for (final s in all) if (s.y < game.groundY - 1) s];
    final floorOnly = [for (final s in all) if (s.y >= game.groundY - 1) s];
    final preferRaised = raisedSpots.isNotEmpty && (runeRaisedRollOverride ?? _random.nextDouble()) < BossAttackConstants.runeRaisedChance;
    var pool = preferRaised ? raisedSpots : floorOnly;
    if (pool.isEmpty) pool = all;
    final fresh = [for (final s in pool) if (s.surface != _lastRuneSurface) s];
    if (fresh.isNotEmpty) pool = fresh;
    double away(({double x, double y, int surface}) s) => (s.x - _heroCentre).abs();
    // Far from the hero but not too far: the room is big, and every round should not be a long walk.
    ({double x, double y, int surface})? pickFrom(List<({double x, double y, int surface})> list) {
      final band = [
        for (final s in list)
          if (away(s) >= BossAttackConstants.runeMinDistance && away(s) <= BossAttackConstants.runeMaxDistance) s
      ];
      if (band.isNotEmpty) return band[_random.nextInt(band.length)];
      // None in that band: the nearest one beyond it.
      final beyond = [for (final s in list) if (away(s) >= BossAttackConstants.runeMinDistance) s]
        ..sort((a, b) => away(a).compareTo(away(b)));
      return beyond.isNotEmpty ? beyond.first : null;
    }

    final pick = pickFrom(pool) ??
        pickFrom(all) ??
        (all.toList()..sort((a, b) => away(b).compareTo(away(a)))).first;
    _lastRuneSurface = pick.surface;
    // A climb takes longer than a walk: the "boss throws anyway" timer gets a little more for the height.
    _runeLimit = BossAttackConstants.runeStallSeconds +
        math.max(0.0, game.groundY - pick.y) / 100 * BossAttackConstants.runeClimbSecondsPer100;
    final r = BossRuneComponent(x: pick.x, surfaceY: pick.y);
    rune = r;
    game.world.add(r);
    _float('Lapitan ang runa!', const Color(0xFFFFC83D));
    game.notifyState();
  }

  void _tickRune() {
    final r = rune;
    if (r == null) {
      _startRound();
      return;
    }
    final p = game.player;
    final feet = p.position.y + p.size.y;
    // At the rune's own height: from below (the floor under a ledge) does not count.
    final near = (_heroCentre - r.centreX).abs() <= BossAttackConstants.runeTouchRange &&
        feet >= r.surfaceY - 90 &&
        feet <= r.surfaceY + 30;
    if (near || _t >= _runeLimit) {
      stalled = !near;
      r.collect();
      rune = null;
      _startRound();
    }
  }

  /// The spots for a wave of [n] minions, in the order they will be used. They are on the stretch of
  /// floor nearest to the hero (a minion cannot cross a pool, a gap or the stage), as far from him as
  /// BossAttackConstants.waveSpawnMin to waveSpawnMax allows. When the floor has no [n] spots that far,
  /// the farthest it has are used, never nearer than waveSpawnNearest.
  @visibleForTesting
  List<({double x, double y})> waveSpots(int n) {
    final runs = floorRuns();
    double gapTo(List<({double x, double y})> run) {
      final lo = run.first.x, hi = run.last.x;
      return _heroCentre < lo ? lo - _heroCentre : (_heroCentre > hi ? _heroCentre - hi : 0.0);
    }

    var spots = <({double x, double y})>[];
    if (runs.isNotEmpty) {
      final byDistance = runs.toList()..sort((a, b) => gapTo(a).compareTo(gapTo(b)));
      // The nearest stretch that is long enough for the wave (else simply the nearest).
      spots = byDistance.firstWhere((r) => r.length >= 6, orElse: () => byDistance.first);
    }
    double away(({double x, double y}) s) => (s.x - _heroCentre).abs();
    final far = [
      for (final s in spots)
        if (away(s) >= BossAttackConstants.waveSpawnMin && away(s) <= BossAttackConstants.waveSpawnMax) s
    ];
    if (far.length >= n) {
      spots = far;
    } else {
      final farthest = [for (final s in spots) if (away(s) >= BossAttackConstants.waveSpawnNearest) s]
        ..sort((a, b) => away(b).compareTo(away(a)));
      spots = farthest.take(math.max(n * 3, 6)).toList();
    }
    return spots.toList()..shuffle(_random);
  }

  void _beginWave() {
    state = BossRoundState.wave;
    _t = 0;
    _waveClear = 0;
    _waveHearts = 0;
    _wavePowerUps = 0;
    _minions.clear();
    _clearPending();
    final n = math.min(BossAttackConstants.waveMaxAlive, BossAttackConstants.waveSizes[phase - 1]);
    final spots = waveSpots(n);
    // Each minion waits at its spot under a red warning, and they come one after another.
    for (var i = 0; i < n; i++) {
      final s = spots.isEmpty
          ? (x: _heroCentre + BossAttackConstants.waveSpawnMin, y: game.groundY)
          : spots[i % spots.length];
      final x = s.x + (spots.isNotEmpty && i >= spots.length ? 40.0 * i : 0);
      final warning = BossWaveWarning(spotX: x, surfaceY: s.y);
      game.world.add(warning);
      _pending.add(_PendingSpawn(
        x: x,
        y: s.y,
        onGround: (s.y - game.groundY).abs() < 1,
        at: BossAttackConstants.waveWarnSeconds + i * BossAttackConstants.waveSpawnGapSeconds,
        warning: warning,
      ));
    }
    _float('Paparating ang mga kalaban! ($n)', const Color(0xFFFF6B5E));
    game.notifyState();
  }

  /// A minion appears at the spot its warning marked and starts walking in: it hunts, so it comes
  /// all the way however far it is.
  void _spawnMinion(_PendingSpawn p) {
    final m = EnemyComponent(
      eraId: eraId,
      worldX: p.x - EnemyComponent.spriteWidth / 2,
      surfaceY: p.onGround ? null : p.y,
      behaviorOverride: EnemyBehavior.chaser,
      blasts: false,
      hunts: true,
      onDefeated: _payCharge,
      onDropped: _dropBonus,
    );
    _minions.add(m);
    game.world.add(m);
  }

  void _clearPending() {
    for (final p in _pending) {
      p.warning.removeFromParent();
    }
    _pending.clear();
  }

  /// What a fallen minion may leave besides its coins: a heart or a power-up, by chance.
  void _dropBonus(Vector2 spot) =>
      dropBonusWith(spot, _random.nextDouble(), _random.nextDouble(), _random.nextInt(3));

  /// The drop with its dice given (for tests): [heartRoll] and [powerRoll] are 0 to 1 and win
  /// when under the chance; [kindIndex] picks the power-up (0 50/50, 1 Kalasag, 2 Hinto).
  /// A heart drops only while the student has fewer than the five (at full hearts it is a few
  /// coins), and no wave drops more than BossAttackConstants.waveMaxHearts hearts or
  /// waveMaxPowerUps power-ups.
  @visibleForTesting
  void dropBonusWith(Vector2 spot, double heartRoll, double powerRoll, int kindIndex) {
    if (state == BossRoundState.ended || isDefeated) return;
    // Lying on the floor where the minion fell: its box is 90 wide and 108 high.
    final floorY = spot.y + EnemyComponent.spriteHeight - 44 - 6;
    final middleX = spot.x + EnemyComponent.spriteWidth / 2 - 22;
    var shifted = false;
    if (heartRoll < BossAttackConstants.minionHeartChance && _waveHearts < BossAttackConstants.waveMaxHearts) {
      _waveHearts++;
      if (game.hearts < GameConstants.maxHearts) {
        game.world.add(HeartPickupComponent(spawnPosition: Vector2(middleX - 28, floorY)));
        shifted = true;
      } else {
        // Full hearts: nothing to give back, so a few coins instead.
        for (var i = 0; i < BossAttackConstants.heartFullCoins; i++) {
          game.world.add(CoinComponent(spawnPosition: Vector2(middleX + i * 22.0, floorY)));
        }
      }
    }
    if (powerRoll < BossAttackConstants.minionPowerUpChance && _wavePowerUps < BossAttackConstants.waveMaxPowerUps) {
      _wavePowerUps++;
      const kinds = ['fiftyFifty', 'shield', 'timeFreeze'];
      game.world.add(PowerUpPickupComponent(
        kind: kinds[kindIndex.clamp(0, kinds.length - 1)],
        spawnPosition: Vector2(middleX + (shifted ? 28 : 0), floorY),
      ));
    }
  }

  void _tickWave(double dt) {
    // The warnings run out one at a time, and each minion appears at its own spot.
    for (final p in _pending.toList()) {
      if (_t >= p.at) {
        _pending.remove(p);
        p.warning.removeFromParent();
        _spawnMinion(p);
      }
    }
    if (_t >= GameConstants.bossWaveTimeoutSeconds) {
      for (final m in _minions) {
        if (_isAlive(m)) m.removeFromParent();
      }
      _minions.clear();
      _clearPending();
      _beginRune();
      return;
    }
    if (_pending.isNotEmpty || minionsAlive > 0) {
      _waveClear = 0;
      return;
    }
    _waveClear += dt;
    if (_waveClear >= BossAttackConstants.waveClearSeconds) {
      _minions.clear();
      _beginRune();
    }
  }

  /// The boss phase whose music is playing (the fight starts in phase 1).
  int _musicPhase = 1;

  void _startRound() {
    _side = _heroCentre >= _bossX ? 1 : -1; // kept for the whole round
    final q = _questions.next();
    if (q == null) {
      defeat(); // a boss with no questions cannot be fought
      return;
    }
    _current = q;
    if (phase != _musicPhase) {
      // A harder phase: the cue, and the next, more intense, track.
      _musicPhase = phase;
      game.audioService.playBossPhase();
      game.audioService.playBossBgm(phase: phase);
    }
    _kind = profile.attackForRound(round);
    _resolved = false;
    lastAnswer = null;
    state = BossRoundState.windup;
    _t = 0;
    game.audioService.playBossAsk();
    game.notifyState();
  }

  /// The throw: the attack leaves the boss and the question opens at the same moment.
  void _launch() {
    final kind = _kind!;
    final a = BossAttackComponent(
        kind: kind, start: _startPoint(kind), end: _heroPoint(kind), mirrored: _side > 0);
    attack = a;
    game.world.add(a);
    game.world.add(BossBurstComponent(
        kind: BossBurstKind.muzzle,
        at: a.start,
        tint: profile.glow,
        seed: _questions.asked));
    _clock = BossCountdown(seconds: answerSeconds);
    state = BossRoundState.asking;
    _t = 0;
    _cardClosed = false;
    _explainTapped = false;
    game.audioService.playShockwave();
    game.showBossQuestion(_current!, this);
    game.notifyState();
  }

  void _syncAttack(BossAttackKind kind) {
    final a = attack;
    if (a == null) return;
    a.start.setFrom(_startPoint(kind));
    a.end.setFrom(_heroPoint(kind));
  }

  void _tickAsking(double dt) {
    final clock = _clock!;
    clock.tick(dt);
    final left = clock.secondsLeft;
    final a = attack!;
    a.progress = left <= 1e-6 ? 1.0 : 1 - clock.fraction;
    _syncAttack(a.kind);
    if (left <= 1e-6) _timeUp();
  }

  /// The attack arrived and nobody answered: the same as a wrong answer.
  void _timeUp() {
    if (!asking) return;
    game.handleAnswer(''); // records the miss, then calls [answered]
    if (!_resolved) answered(correct: false, timedOut: true); // (no question to record)
  }

  /// The student answered (the game calls this once for each question, from `handleAnswer`).
  /// A second call, or one when no question is open, does nothing.
  void answered({required bool correct, bool timedOut = false, String answer = ''}) {
    if (!asking) return;
    _resolved = true;
    lastAnswer = timedOut ? '' : answer;
    final a = attack;
    if (correct) {
      state = BossRoundState.counter;
      _t = 0;
      a?.freeze();
      final token = ++_counterToken;
      final target = (a?.centre ?? _heroPoint(_kind!)).clone();
      // The hero's move calls back exactly once; [_onImpact] ignores anything else.
      game.player.playCounter(target: target, onImpact: () => _onImpact(token));
      return;
    }
    final q = _current;
    if (q != null) _questions.again(q);
    if (timedOut || a == null) {
      _hitHero();
    } else {
      final left = 1 - a.progress;
      _rushRate = left <= 0
          ? 1
          : left /
              (BossAttackConstants.rushMinSeconds + BossAttackConstants.rushExtraSeconds * left);
      state = BossRoundState.rush;
      _t = 0;
    }
  }

  void _tickRush(double dt) {
    final a = attack;
    if (a == null) {
      _hitHero();
      return;
    }
    a.progress = math.min(1.0, a.progress + dt * _rushRate);
    _syncAttack(a.kind);
    if (a.progress >= 1) _hitHero();
  }

  /// The hero's counter met the attack.
  void _onImpact(int token) {
    if (token != _counterToken || state != BossRoundState.counter) return;
    _counterToken++; // a second call is ignored
    final a = attack;
    if (a == null || !a.kind.reflects) {
      a?.fadeOut();
      attack = null;
      _hitBoss(a?.centre ?? _bossHitPoint, a?.kind);
      return;
    }
    a.sendBack(_bossHitPoint);
    state = BossRoundState.reflect;
    _t = 0;
  }

  void _tickReflect() {
    final a = attack;
    if (a != null) a.reflectProgress = (_t / BossAttackConstants.reflectSeconds).clamp(0.0, 1.0);
    if (_t >= BossAttackConstants.reflectSeconds) {
      attack = null;
      a?.removeFromParent();
      _hitBoss(_bossHitPoint, a?.kind);
    }
  }

  static BossBurstKind _burstOf(BossAttackKind? k) => switch (k) {
        BossAttackKind.gslash => BossBurstKind.coin,
        BossAttackKind.knights || BossAttackKind.ghost => BossBurstKind.ghost,
        BossAttackKind.pistol || BossAttackKind.sonic => BossBurstKind.volley,
        BossAttackKind.slash || BossAttackKind.wind => BossBurstKind.slash,
        BossAttackKind.fan || BossAttackKind.vortex => BossBurstKind.bag,
        _ => BossBurstKind.water,
      };

  void _hitBoss(Vector2 at, BossAttackKind? kind) {
    game.world.add(BossBurstComponent(
        kind: _burstOf(kind), at: at, onBoss: true, seed: _questions.asked * 977 + 5));
    game.world.add(BossFloatText(
        text: '-1',
        at: Vector2(_bossX, _bossFeet - 150),
        color: const Color(0xFF58C47A)));
    game.audioService.playEnemyDefeat();
    takeDamage();
    if (!isDefeated) {
      state = BossRoundState.rest;
      _t = 0;
    }
  }

  /// The boss takes one point of damage: it shows hurt, and falls when the last is gone.
  void takeDamage() {
    health--;
    _hurtLeft = BossAttackConstants.hurtSeconds;
    _dizzyLeft = BossAttackConstants.dizzySeconds;
    _refreshSprite();
    _questions.solve();
    game.notifyState();
    if (health <= 0) defeat();
  }

  /// The attack arrives: a heart is lost (unless the safe moment or a Shield stops it).
  void _hitHero() {
    final a = attack;
    attack = null;
    a?.removeFromParent();
    final kind = a?.kind ?? _kind!;
    final p = game.player;
    final before = game.hearts;
    p.takeHazardHit(knockbackDirection: _side); // away from the boss: left if he is on its left, right if on its right
    final at = _heroPoint(kind);
    game.world.add(BossBurstComponent(
        kind: _burstOf(kind), at: at, seed: _questions.asked * 977 + 13));
    if (game.hearts < before) {
      game.world.add(BossFloatText(
          text: '-1',
          at: Vector2(p.position.x + p.size.x / 2, p.position.y - 10),
          color: const Color(0xFFFF6B5E)));
    }
    _shakeLeft = BossAttackConstants.hitShakeSeconds;
    game.notifyState();
    if (game.levelEnded) {
      _endFight();
      return;
    }
    state = BossRoundState.rest;
    _t = 0;
  }

  /// Whether the hero is held where he stands: from the wind-up to the end of the round (the
  /// question, the attack's flight, the counter or the hit, and the explanation). The attack
  /// is aimed at him, so walking about would drag it along. Between rounds he is free.
  bool get holdsHero =>
      !isDefeated &&
      switch (state) {
        BossRoundState.windup ||
        BossRoundState.asking ||
        BossRoundState.rush ||
        BossRoundState.counter ||
        BossRoundState.reflect ||
        BossRoundState.rest =>
          true,
        _ => false,
      };

  /// Whether the card is showing why (the right answer and its explanation) and the fight is
  /// waiting for the student to tap SUSUNOD. It is on from the moment the hit lands.
  bool get explaining => state == BossRoundState.rest && !_cardClosed;

  bool _explainTapped = false;

  /// SUSUNOD on the explanation: the card goes and the next round follows after a short breath.
  void continueAfterExplanation() {
    if (explaining) _explainTapped = true;
  }

  void _tickRest() {
    if (!_cardClosed) {
      // The fight waits here for the student to finish reading.
      if (!_explainTapped) {
        _t = 0;
        return;
      }
      _cardClosed = true;
      game.closeBossQuestion();
      _t = math.max(_t, BossAttackConstants.restSeconds - 0.4);
    }
    if (_t >= BossAttackConstants.restSeconds) _afterRound();
  }

  /// Between two rounds: a wave of minions after every second one, then the next rune.
  void _afterRound() {
    _played++;
    if (_played % BossAttackConstants.waveEveryRounds == 0) {
      _beginWave();
    } else {
      _beginRune();
    }
  }

  /// Time Freeze: the clock and the attack hang where they are for 8 seconds (once a question).
  void freezeClock() {
    if (asking) _clock?.freeze();
  }

  /// The fight stops without a winner here (the hero has no hearts left).
  void _endFight() {
    state = BossRoundState.ended;
    _clearPending();
    attack?.removeFromParent();
    attack = null;
    _cardClosed = true;
    game.closeBossQuestion();
    game.cameraShake.setZero();
  }

  void defeat() {
    if (isDefeated) return;
    isDefeated = true;
    state = BossRoundState.ended;
    _clearPending();
    attack?.removeFromParent();
    attack = null;
    _cardClosed = true;
    game.closeBossQuestion();
    sprite = defeatedSprite;
    // The defeat sequence (cracks, explosion, medal) takes over and ends the level itself; with
    // no sequence (a phone set to remove animations) the boss just lies there for a second.
    _defeatLeft = game.beginBossDefeat(this) ? double.infinity : BossAttackConstants.defeatSeconds;
    game.audioService.stopBgm(); // the music stops so the victory sound is clear
    game.overlays.remove('BossHealthOverlay');
  }

  /// The defeat sequence is over: the boss goes and the level is complete.
  void finishDefeat() {
    if (_finished) return;
    _finished = true;
    removeFromParent();
    game.levelComplete();
  }

  void _tickDefeat(double dt) {
    if (_finished) return;
    _defeatLeft -= dt;
    if (_defeatLeft > 0) return;
    _finished = true;
    removeFromParent();
    game.levelComplete();
  }
}

/// A minion of a wave that has not appeared yet: where it will stand, when (seconds after the wave
/// began) and the red warning marking the spot until then.
class _PendingSpawn {
  final double x;
  final double y;
  final bool onGround;
  final double at;
  final BossWaveWarning warning;
  const _PendingSpawn({
    required this.x,
    required this.y,
    required this.onGround,
    required this.at,
    required this.warning,
  });
}
