import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../core/bonus_constants.dart';
import '../../models/control_scheme.dart';
import '../chrono_game.dart';
import '../components/coin_component.dart';
import '../components/enemy_component.dart';
import '../components/gap_component.dart';
import '../enemy_behavior.dart' show EnemyBehavior;
import 'bonus_layout.dart';
import 'bonus_scenery.dart';
import 'bonus_session.dart';

/// The bonus round: 20 seconds on a different map, as its own small game.
///
/// It IS a [ChronoGame] (so the hero, the controls, the jump, the attack move and
/// the enemies are exactly the level's own) but nothing of the level is in it: no
/// questions, no gate, no artifacts, no pits and no water. Three things differ:
///
/// - Coins go into a bonus counter, not the wallet ([collectCoin]).
/// - An enemy touch takes [BonusConstants.enemyPenalty] coins out of the counter,
///   never below 0, and costs no heart ([loseLife]). The hero still gets its
///   shove and its blink.
/// - A 20 second clock ([timeLeft]) that runs only while the game itself runs.
///
/// The level is held still underneath on its own `ChronoGame`, so nothing here can
/// touch its hearts, Kaalaman, enemies or timers.
class BonusGame extends ChronoGame {
  BonusGame({
    required String eraId,
    int levelNo = BonusConstants.firstGoldenLevel,
    String characterId = 'boy',
    ControlScheme scheme = ControlScheme.joystick,
  }) : layout = BonusLayout.forEra(eraId) {
    currentEra = eraId;
    currentLevel = levelNo;
    selectedCharacterId = characterId;
    controlScheme = scheme;
  }

  final BonusLayout layout;

  /// Seconds left on the clock, and the same as a notifier for the HUD bar (which
  /// must move every frame without rebuilding everything else).
  double timeLeft = BonusConstants.roundSeconds;
  final ValueNotifier<double> clock =
      ValueNotifier<double>(BonusConstants.roundSeconds);

  /// True while the clock runs: from [begin] until the time is up.
  bool running = false;

  /// True once the 20 seconds are over.
  bool timeUp = false;

  /// The bonus counter: coins picked up minus what enemies knocked out of it.
  int counter = 0;

  /// Every coin picked up, and the coins enemies actually removed (a touch with
  /// 3 in the counter removes 3, not 5), and how many touches there were.
  int grabbed = 0;
  int knockedLoose = 0;
  int hits = 0;

  /// The coins the latest touch removed (0 when the counter was already empty).
  int lastLost = 0;

  /// Seconds since the last coin and the last enemy touch, for the HUD's pop.
  double sinceCoin = 99;
  double sinceHit = 99;

  /// Pays the counter into the wallet. Called by [settle], exactly once.
  void Function(int coins)? onPayout;

  /// Told when the 20 seconds run out.
  VoidCallback? onTimeUp;

  bool _settled = false;

  /// True once the coins have been paid.
  bool get settled => _settled;

  /// Starts the clock. The screen calls this when the round is on screen; until
  /// then the hero can stand and look but nothing is lost.
  void begin() {
    if (timeUp) return;
    running = true;
    notifyListeners();
  }

  // ─── what the round replaces in a level ───────────────────────────────────

  @override
  Future<void> buildLevelContent() async {
    // One long floor: collision only (it is drawn by BonusGroundComponent), no pits.
    world.add(GroundSection(
      sectionWidth: layout.mapWidth,
      sectionPosition: Vector2(0, groundY),
      drawn: false,
    ));
    world.add(BonusGroundComponent(length: layout.mapWidth));
    for (final p in layout.platforms) {
      world.add(BonusPlatformComponent(
        widthInTiles: p.widthInTiles,
        surfaceY: p.surfaceY,
        spawnPosition: Vector2(p.x, p.surfaceY),
      ));
    }
    for (final c in layout.coins) {
      world.add(CoinComponent(spawnPosition: c.clone()));
    }
    for (final e in layout.enemies) {
      world.add(EnemyComponent(
        eraId: currentEra,
        enemyTypeOverride: e.kind,
        worldX: e.x,
        patrolRangeOverride: BonusConstants.enemyPatrol,
        // They only pace: no chasing, no fuse, no lunge in a bonus round.
        behaviorOverride: EnemyBehavior.walker,
        blasts: false,
      ));
    }
    player.position = Vector2(BonusConstants.spawnX, groundY - player.size.y);
    player.respawnAnchorX = BonusConstants.spawnX;
  }

  @override
  void installBackdrop() {
    camera.backdrop = BonusBackdrop();
  }

  /// The level's music keeps playing underneath; the round adds none of its own.
  @override
  void startMusic() {}

  /// There is no exit to reach: only the clock ends the round.
  @override
  void checkLevelEnd() {}

  // ─── the rules of the round ───────────────────────────────────────────────

  @override
  void collectCoin({bool onHighPlatform = false}) {
    if (timeUp) return;
    grabbed++;
    counter++;
    sinceCoin = 0;
    audioService.playCoin();
    notifyListeners();
  }

  /// An enemy touch: 5 coins out of the counter (never below 0), the hurt pose and
  /// sound, and the blink the hero's own contact code adds. No heart, ever.
  @override
  bool loseLife() {
    final lost = counter < BonusConstants.enemyPenalty
        ? counter
        : BonusConstants.enemyPenalty;
    counter -= lost;
    knockedLoose += lost;
    lastLost = lost;
    hits++;
    sinceHit = 0;
    player.triggerHurt();
    notifyListeners();
    return false;
  }

  /// There are no pits, but if the hero ever ends up below the floor it simply
  /// stands up again where it last stood. Nothing is lost.
  @override
  void playerFellInGap() => player.respawn();

  @override
  void update(double dt) {
    super.update(dt);
    sinceCoin += dt;
    sinceHit += dt;

    // The hero cannot walk off the far end of the map.
    final limit = layout.mapWidth - player.size.x - 100;
    if (player.position.x > limit) player.position.x = limit;

    if (!running || timeUp) return;
    timeLeft -= dt;
    if (timeLeft <= 0) {
      timeLeft = 0;
      _finishClock();
    }
    clock.value = timeLeft;
  }

  void _finishClock() {
    running = false;
    timeUp = true;
    pauseEngine();
    notifyListeners();
    onTimeUp?.call();
  }

  /// Ends the round now, as if the 20 seconds were up (a test, or a skip).
  @visibleForTesting
  void forceTimeUp() {
    timeLeft = 0;
    clock.value = 0;
    if (!timeUp) _finishClock();
  }

  /// Closes the books: pays the counter into the wallet (once, whatever calls this
  /// or how often) and says how the round went. Leaving early pays what is in the
  /// counter so far.
  BonusResult settle() {
    final coins = counter;
    if (!_settled) {
      _settled = true;
      if (coins > 0) onPayout?.call(coins);
    }
    return BonusResult(
      coins: coins,
      grabbed: grabbed,
      knockedLoose: knockedLoose,
      leftEarly: !timeUp,
    );
  }
}
