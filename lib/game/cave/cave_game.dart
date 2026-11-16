import 'package:flame/components.dart';

import '../../core/cave_constants.dart';
import '../../models/artifact_art.dart' show artifactIconsPerEra;
import '../chrono_game.dart';
import '../components/artifact_component.dart';
import '../components/coin_component.dart';
import '../components/enemy_component.dart';
import '../components/gap_component.dart';
import '../components/pipe_component.dart';
import '../enemy_behavior.dart' show EnemyBehavior;
import 'cave_layout.dart';
import 'cave_scenery.dart';
import 'cave_session.dart';

/// The underground cave: a mini-level of its own, shown on top of the level.
///
/// It IS a [ChronoGame], so the hero, the controls, the jump, the attack move, the
/// enemies, the coins and the artifact question are exactly the level's own. It
/// plays with the level's hearts, Kaalaman, power-ups, coin wallet and question
/// supply (all handed over by [CaveGame.new]), and at the end it gives the level
/// back what changed ([result]).
///
/// There is no end gate and no end of the level here: the way out is the pipe at
/// the end, which opens once the cave's artifact has been answered, right or wrong.
class CaveGame extends ChronoGame {
  CaveGame({required this.level})
      : layout = CaveLayout.forLevel(level.currentEra, level.currentLevel),
        look = CaveLook.of(level.currentEra) {
    currentEra = level.currentEra;
    currentLevel = level.currentLevel;
    selectedCharacterId = level.selectedCharacterId;
    controlScheme = level.controlScheme;
    hearts = level.hearts;
    kaalaman = level.kaalaman;
    shieldActive = level.shieldActive;
    // The same power-ups object: a use in the cave is a use in the level.
    playerPowerUps = level.playerPowerUps;
    onHeartLost = level.onHeartLost;
    onHeartGained = level.onHeartGained;
    onCoinCollected = level.onCoinCollected;
    onPowerUpUsed = level.onPowerUpUsed;
    onLevelFailed = _lastHeartGone;
  }

  /// The level the student came from, held still underneath.
  final ChronoGame level;
  final CaveLayout layout;
  final CaveLook look;

  /// The pipe at the end of the cave.
  PipeComponent? exitPipe;

  /// Told when the student has left the cave (up the pipe, or by leaving, or when
  /// the last heart went). The screen shows the way back.
  void Function()? onFinish;

  /// True when the last heart went down here.
  bool failed = false;

  /// True once the way out has been taken.
  bool finished = false;

  void _lastHeartGone() {
    failed = true;
    _finish();
  }

  void _finish() {
    if (finished) return;
    finished = true;
    onFinish?.call();
  }

  /// The student leaves by the pipe (or chooses to leave): hands control back.
  void leave() => _finish();

  /// What the level gets back.
  CaveResult result() => CaveResult(
        answered: artifactsAnswered >= 1,
        claimed: artifactsClaimed >= 1,
        answers: List.of(answers),
        coins: playerCoins,
        score: score,
        kaalaman: kaalaman,
        hearts: hearts,
        shieldActive: shieldActive,
        failed: failed,
      );

  // ─── what the cave replaces in a level ─────────────────────────────────────

  @override
  Future<void> buildLevelContent() async {
    // The cave asks from the level's own pool, so a question the student has
    // already had in the level is not the first one chosen.
    questionPool = level.questionPool;
    artifactsTotal = 1;

    for (final f in layout.floor) {
      world.add(GroundSection(
        sectionWidth: f.x1 - f.x0,
        sectionPosition: Vector2(f.x0, groundY),
        drawn: false,
      ));
    }
    world.add(CaveGround(layout: layout, look: look));
    world.add(CaveLights(look));
    world.add(CaveCeilingPipe(
      centerX: layout.spawnX + 48,
      color: look.earthEdge,
    ));
    for (final p in layout.platforms) {
      world.add(CavePlatformComponent(
        widthInTiles: p.widthInTiles,
        surfaceY: p.surfaceY,
        spawnPosition: Vector2(p.x, p.surfaceY),
        look: look,
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
        patrolRangeOverride: 70,
        behaviorOverride:
            e.chaser ? EnemyBehavior.chaser : EnemyBehavior.walker,
        // Plain chasers: no fuse, no blast, no lunge down here.
        blasts: false,
      ));
    }
    world.add(ArtifactComponent(
      worldX: layout.artifactX,
      spriteIndex: (currentLevel * 3) % artifactIconsPerEra + 1,
    ));
    final pipe = PipeComponent(
      centerX: layout.exitX,
      eraId: currentEra,
      isExit: true,
      onEnter: (_) => _finish(),
    )..enabled = false;
    exitPipe = pipe;
    world.add(pipe);

    player.position = Vector2(layout.spawnX, groundY - player.size.y);
    player.respawnAnchorX = layout.spawnX;
  }

  @override
  void installBackdrop() {
    camera.backdrop = CaveBackdrop(look);
    // Dust, close rock and the darkened edges, over the whole cave.
    camera.viewport.add(CaveFront(look));
  }

  /// The level's music keeps playing underneath; the cave adds none of its own.
  @override
  void startMusic() {}

  /// There is no end of the level down here: only the pipe ends the cave.
  @override
  void checkLevelEnd() {}

  /// The progress bar in the corner fills toward the exit pipe.
  @override
  double get levelEndX => layout.exitX;

  @override
  void update(double dt) {
    super.update(dt);
    // The way out opens when the cave's artifact is answered.
    final pipe = exitPipe;
    if (pipe != null) pipe.enabled = canPassEndGate;
    // The hero cannot walk off the far end of the map.
    final limit = CaveConstants.mapWidth - player.size.x - 60;
    if (player.position.x > limit) player.position.x = limit;
  }
}
