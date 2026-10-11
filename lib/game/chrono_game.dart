import 'dart:async' show unawaited;

import 'package:flame/game.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../core/combat_constants.dart';
import '../core/constants.dart';
import '../data/question_pool.dart';
import '../models/control_scheme.dart';
import '../models/level.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import 'components/artifact_component.dart';
import 'components/player_component.dart';
import 'components/boss_component.dart';
import 'components/gate_component.dart';
import 'components/gap_component.dart';
import 'components/enemy_spawner.dart';
import 'components/parallax_background.dart';
import 'components/tile_platform_component.dart';
import 'game_camera.dart';
import 'game_input.dart';
import 'game_spawning.dart';
import 'kaalaman_handler.dart';
import 'level_loader.dart';
import 'stretch_to_fill_viewport.dart';

/// Main Flame game class for ChronoQuest.
/// Manages the game loop, player, enemies, questions, and level state.
///
/// Mixes in ChangeNotifier so HUD/boss-health overlay widgets can react to
/// state changes (lives, score, coins, boss health) via ListenableBuilder —
/// without this, those Flutter overlays are only built once when added and
/// never update again, since Flame doesn't rebuild overlay widgets on its
/// own each frame.
///
class ChronoGame extends FlameGame
    with HasCollisionDetection, ChangeNotifier {
  /// The game renders into a fixed virtual height that Flame scales to the
  /// real device, rather than drawing in raw device pixels. Without it the
  /// same sprite was ~11% of a desktop window's height and ~22% of a
  /// landscape phone's, which is why the game looked oversized on a phone.
  ///
  /// Uses `StretchToFillViewport` rather than Flame's own
  /// `CameraComponent.withFixedResolution` (which builds a
  /// `FixedResolutionViewport`): that viewport also fixes virtual *width*,
  /// preserving one exact aspect ratio (16:9) uniformly scaled, which
  /// pillarboxes (black bars on the sides) any device whose landscape aspect
  /// is wider than 16:9 — effectively every modern phone. `StretchToFillViewport`
  /// instead keeps virtual height fixed at GameConstants.virtualHeight but
  /// lets virtual *width* track the device's own aspect ratio, so it fills
  /// the real screen edge-to-edge with a uniform (non-distorting) scale on
  /// every device — no black bars, no stretched sprites. `size.y` (what
  /// `groundY` below reads) is unaffected either way — still always exactly
  /// GameConstants.virtualHeight, regardless of device; `size.x` now varies
  /// per device (a wider-than-16:9 phone sees a proportionally wider slice
  /// of world), same as `cameraRightEdgeX` below already expects.
  ChronoGame()
      : super(
          camera: CameraComponent(
            viewport: StretchToFillViewport(
              height: GameConstants.virtualHeight,
            ),
            viewfinder: Viewfinder(),
          ),
        );

  /// Y position of the ground surface — where GroundSection draws the top of
  /// the ground band, flush with the bottom of the viewport.
  ///
  /// `size` here is the camera viewport's virtual size, i.e. the fixed
  /// virtual resolution above, NOT the device canvas (that's `canvasSize`).
  /// So this is a constant 660 on every device, where it used to vary with
  /// the phone's real pixel height.
  double get groundY => size.y - GroundSection.bandHeight;

  /// World x-coordinate of the camera's visible left edge — the player's
  /// worldX offset by the fixed screen position they render at (see
  /// `updateCamera()` in game_camera.dart).
  double get cameraLeftEdgeX => player.worldX - GameConstants.playerX;

  /// World x-coordinate just past the camera's visible right edge — where
  /// enemies/obstacles/ground should spawn so they enter from off-screen.
  /// One virtual screen-width ahead of the left edge — `size` is the
  /// viewport's virtual size, same as in groundY above.
  double get cameraRightEdgeX => cameraLeftEdgeX + size.x;

  /// Whether [currentLevel] is the last level of [currentEra] — each era has
  /// its own level count (Section 1: 10/5/7/8/8/5), so "the boss level" is
  /// never a fixed number.
  bool get isBossLevel => currentLevel == getEraById(currentEra).levels.length;

  /// The [Level] data for [currentLevel] within [currentEra] — `Level.index`
  /// is 1-based, matching `currentLevel` directly.
  Level get currentLevelData =>
      getEraById(currentEra).levels[currentLevel - 1];

  // Game state
  late PlayerComponent player;
  late GameInput gameInput;

  /// The movement controls to show, set by the screen from the student's
  /// saved choice before the level loads. Changing it later (after a trip to
  /// Settings from the pause menu) goes through `gameInput.setScheme`.
  ControlScheme controlScheme = ControlScheme.joystick;

  /// The pre-Phase-4 runtime spawners, created only on levels with no
  /// authored `.tmx` (see game_spawning.dart).
  ///
  /// Nullable rather than `late` on purpose: `setupSpawning()` became async
  /// in Phase 4 (it reads the level file from the asset bundle), so there is
  /// now a window where `update()` runs before setup has finished. With
  /// `late` that window threw a LateInitializationError on the first frame;
  /// null simply means "not spawning yet", which `updateSpawning` checks.
  EnemySpawner? spawner;
  GroundSpawner? groundSpawner;

  // Maintained by GroundSection's onMount/onRemove (see gap_component.dart)
  // so PlayerComponent can check ground collision without scanning/filtering
  // game.children every frame — that scan runs 60x/sec across every enemy,
  // coin, and wall on screen too, which adds up.
  final List<GroundSection> groundSections = [];

  // Maintained by TilePlatformComponent's onMount/onRemove, mirrors
  // groundSections above — lets PlayerComponent check elevated-platform
  // landings without scanning game.children every frame.
  final List<TilePlatformComponent> platforms = [];

  /// The authored Tiled level this attempt is playing, or null when the
  /// level has no `.tmx` yet and fell back to the procedural spawner
  /// (GAMEPLAY-V2.md Section 11, Phase 4).
  ///
  /// Doubles as the "is this level authored" flag: `updateSpawning` skips
  /// the runtime spawners when it is set, and `checkLevelEnd` uses the
  /// authored `exit` position instead of `Level.lengthUnits`. One field
  /// rather than a separate bool, so the two can't disagree.
  LoadedLevel? tiledLevel;

  String currentEra = 'spanish';
  int currentLevel = 1;

  /// The shared hearts pool (GAMEPLAY-V2.md section 8) — seeded from the
  /// persistent `HeartsState` count by `GameScreen` at construction, and
  /// spent by every damage event in this level. Not a level-local counter:
  /// [onHeartLost] pushes each loss straight back to the persisted pool, so
  /// running out mid-level really does lock out the next attempt too.
  int hearts = GameConstants.maxHearts;

  /// Fired once per heart lost, so the caller (GameScreen) can persist the
  /// new count to the same `HeartsState` pool shown on the menu screens.
  Function()? onHeartLost;

  /// Attack charges (GAMEPLAY-V2.md Section 4) — a level-local resource,
  /// same shape as [hearts]: every level starts fresh at
  /// `CombatConstants.kaalamanStart`, not carried over or persisted. This
  /// is a different layer from the persistent, Hive-backed `HeartsState`
  /// pool `hud_overlay.dart` references — there is no persistent Kaalaman
  /// pool. Real rewards (correct artifact answers) are Phase 3; until then
  /// this is only spent by attacking and granted by the debug key (see
  /// kaalaman_handler.dart).
  int kaalaman = CombatConstants.kaalamanStart;

  /// Answer-point progress shown in the HUD pill: how many gates and
  /// artifacts this level has, and how many the student has cleared. Totals
  /// are set when the level is built (authored count for Tiled levels, the
  /// fixed `CombatConstants` counts for procedural ones) and stay 0 on boss
  /// levels, which have neither.
  int artifactsTotal = 0;
  int artifactsClaimed = 0;

  /// Distinct artifacts the student has answered at all, right or wrong.
  ///
  /// This, not [artifactsClaimed], is what the end gate requires. Demanding
  /// *correct* answers would drive every student to 100% and leave the
  /// teacher dashboard measuring nothing — no error rates, no weak topics,
  /// no learning gain. A wrong answer still shows the explanation, still
  /// counts here, and still reaches the dashboard as the wrong answer it was.
  int artifactsAnswered = 0;

  /// Whether the end gate's requirement is met.
  bool get canPassEndGate => artifactsAnswered >= artifactsTotal;

  /// How many artifacts the student still has to reach.
  int get artifactsRemaining =>
      (artifactsTotal - artifactsAnswered).clamp(0, artifactsTotal);

  /// True while the "you still have artifacts to find" notice is on screen.
  bool gateLockedNoticeShowing = false;
  DateTime? _gateNoticeUntil;

  /// Shows the locked-gate notice, if one isn't already up.
  ///
  /// Called from the player's update loop, so it fires on every frame the
  /// student pushes against the gate — the flag and the wall-clock cooldown
  /// are what keep that from restarting the notice continuously.
  void showGateLockedNotice() {
    final until = _gateNoticeUntil;
    if (gateLockedNoticeShowing) return;
    if (until != null && DateTime.now().isBefore(until)) return;

    gateLockedNoticeShowing = true;
    _gateNoticeUntil = DateTime.now().add(const Duration(seconds: 4));
    if (isMounted) {
      overlays.add('GateLockedOverlay');
      notifyListeners();
    }
  }

  void dismissGateLockedNotice() {
    if (!gateLockedNoticeShowing) return;
    gateLockedNoticeShowing = false;
    if (isMounted) {
      overlays.remove('GateLockedOverlay');
      notifyListeners();
    }
  }

  /// Seconds accumulated toward the next regenerated charge; see
  /// `updateKaalamanRegen` in kaalaman_handler.dart.
  double kaalamanRegenTimer = 0;

  int score = 0;
  int playerCoins = 0;
  bool questionShowing = false;
  bool bossPhase = false;
  bool shieldActive = false;
  Question? currentQuestion;
  BossComponent? boss;

  /// Which answer point opened the question currently on screen, if any.
  /// Exactly one is non-null while an artifact or gate question is up; both
  /// are null for boss questions, which take `quiz_handler.dart`'s path.
  ArtifactComponent? activeArtifact;

  /// This attempt's question supply (GAMEPLAY-V2.md Section 14, Phase 3).
  /// Per-attempt, not static: two levels played in one session must not
  /// share a served-set. Built in [setupSpawning].
  QuestionPool? questionPool;

  /// Serves one question for an artifact or gate, avoiding [exclude] so a
  /// retry is guaranteed to differ. Null only when the level has no
  /// authored content at all.
  Question? drawQuestion({Question? exclude}) =>
      questionPool?.draw(exclude: exclude);
  List<QuestionSnapshot> answers = [];

  // Powerups
  PowerUps playerPowerUps = PowerUps();

  // Services
  final AudioService audioService = AudioService();
  final ApiService apiService = ApiService();

  // Callbacks for navigation
  Function(int score, int correct, int total, List<QuestionSnapshot> answers)?
      onLevelComplete;
  Function()? onLevelFailed;

  /// Called once the server has the result, so the student's score (which the
  /// server adds to) can be fetched again. Not called if the post failed.
  Function()? onResultSubmitted;

  // Elapsed time tracking
  final Stopwatch _stopwatch = Stopwatch();

  // Time tracking for animation
  double _gameTime = 0;
  @override
  double currentTime() => _gameTime;

  // Character selection
  String selectedCharacterId = 'rizal';

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // IMPORTANT: Flame's Images cache defaults to looking under
    // 'assets/images/'. Our pubspec.yaml declares images directly under
    // 'assets/characters/', 'assets/bosses/', 'assets/enemies/', etc.
    // Without this line, every game.loadSprite(...) call in the whole
    // game (player, enemies, boss) throws a "file not found" exception,
    // which is why nothing was rendering.
    images.prefix = 'assets/';

    // Camera: the player's worldX is drawn at a fixed screen offset
    // (GameConstants.playerX) rather than the player moving on screen —
    // see updateCamera() in game_camera.dart, called from update() below.
    camera.viewfinder.anchor = Anchor.topLeft;

    // Real parallax background using the actual era artwork. Its own
    // update() derives layer offsets from the camera's movement — see
    // ParallaxBackground.
    //
    // Mounted as the camera's backdrop rather than a direct child of the
    // game: the backdrop renders inside the viewport, so it is scaled to the
    // virtual resolution along with the world, and it stays put as the
    // camera moves — which is what a parallax layer wants. A direct child
    // would be drawn in raw canvas pixels and no longer line up.
    camera.backdrop = ParallaxBackground();

    // Player — lives in world space so the camera transform applies to it.
    player = PlayerComponent(characterId: selectedCharacterId);
    world.add(player);

    // On-screen joystick + jump/attack buttons (game_input.dart) — added to
    // the viewport, so they read player input regardless of where the
    // camera is looking.
    gameInput = GameInput(game: this, scheme: controlScheme);
    gameInput.setup();

    // Level content (game_spawning.dart): an authored Tiled map when one
    // exists, else the procedural spawner. After `player` exists — the
    // Tiled path repositions the player onto the map's `spawn` object, and
    // EnemySpawner seeds its distance tracking from the player's worldX.
    // Awaited so no frame can run against a half-built level.
    await setupSpawning();

    // Start timer
    _stopwatch.start();

    // Get the sound effects ready, then play the BGM. Not awaited: audio must
    // never hold up the level.
    unawaited(audioService.preloadSfx());
    audioService.playBgm(currentEra);
  }

  /// Longest stretch of game time one frame may advance. A stall longer than
  /// this (playtest: dropping off the internet) is treated as this long,
  /// so the game pauses for the stall instead of jumping forward through it.
  static const double maxFrameDt = 0.1;

  /// Longest single simulation step. A late frame is split into steps no
  /// longer than this rather than run as one big step.
  ///
  /// Playtest bug: the game took each frame's full elapsed time as one step,
  /// and ground contact is only checked once per step. After a stall the
  /// player moved hundreds of units in one go, past solid ground and into a
  /// gap, and a long fall step could also skip past the 20-unit landing band
  /// (game_collision.dart) and drop through the floor. At 1/60 s the fastest
  /// fall moves about 11 units per step.
  static const double maxStepDt = 1 / 60;

  @override
  void updateTree(double dt) {
    // Always at least one call, even for a zero-length frame: Flame also
    // mounts newly added components inside updateTree.
    var remaining = dt > maxFrameDt ? maxFrameDt : dt;
    do {
      final step = remaining > maxStepDt ? maxStepDt : remaining;
      super.updateTree(step);
      remaining -= step;
    } while (remaining > 1e-6);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _gameTime += dt;

    // Set after super.update(dt) so it reflects this frame's player
    // movement, not last frame's (avoids a one-frame lag).
    updateCamera();

    if (!questionShowing && !bossPhase) {
      updateKaalamanRegen(dt);
      updateSpawning(dt);
      checkLevelEnd();
    }
  }

  // ─── GAME EVENTS ──────────────────────────────────────────────────────────

  void onPlayerJump() {
    if (!questionShowing) player.jump();
  }

  void onPlayerAttack() {
    if (!questionShowing) player.attack();
  }

  /// Spends one heart from the shared pool and plays the hurt reaction.
  /// Returns true when that was the last heart and the level has been
  /// failed.
  bool loseLife() {
    hearts--;
    player.triggerHurt();
    onHeartLost?.call();
    notifyListeners(); // hearts changed
    if (hearts > 0) return false;
    showLevelFailed();
    return true;
  }

  /// Lets [QuizHandler] (quiz_handler.dart) notify overlay listeners, since
  /// [notifyListeners] is protected and can't be called from an extension.
  void notifyState() => notifyListeners();

  /// How far the player still has to walk to the end gate, in world units, once
  /// every artifact is answered and the gate is the only thing between them
  /// and the exit. Null before then, when there is no gate to head for, or once
  /// it has opened. Zero when standing at it.
  ///
  /// Measured from the player's right edge to where they are held in front of
  /// the gate (`CombatConstants.gateStandoff` short of it), so it reads 0 at
  /// the spot they actually stop.
  double? gateDistanceUnits() {
    if (artifactsTotal == 0 || !canPassEndGate) return null;
    for (final gate in world.children.whereType<GateComponent>()) {
      if (!gate.isLevelExit || !gate.isBlocking) continue;
      final playerRight = player.position.x + player.size.x;
      final left = gate.position.x - CombatConstants.gateStandoff - playerRight;
      return left < 0 ? 0 : left;
    }
    return null;
  }

  void playerFellInGap() {
    if (!loseLife()) player.respawn();
  }

  /// Player failed to jump over a wall obstacle in time. Same damage as
  /// falling in a gap, but no respawn — the player didn't fall anywhere,
  /// they just took a hit, and the wall keeps scrolling past.
  void playerHitObstacle() => loseLife();

  void collectCoin() {
    playerCoins++;
    score += 5;
    audioService.playCoin();
    notifyListeners(); // coins/score changed
  }

  // ─── LEVEL STATE ──────────────────────────────────────────────────────────

  /// Where this level finishes, in world x.
  ///
  /// An authored level ends at its Tiled `exit` object — the spot a person
  /// chose (GAMEPLAY-V2.md Section 11). A level without a `.tmx` yet falls
  /// back to `Level.lengthUnits`, the Phase 2 interim rule, which is a
  /// global default rather than anything authored.
  double get levelEndX => tiledLevel?.exitX ?? currentLevelData.lengthUnits;

  /// A level ends on reaching [levelEndX], not "all enemies dead" — enemies
  /// no longer gate progress (GAMEPLAY-V2.md Section 14, Phase 2: contact
  /// damage + Kaalaman replace the quiz-on-contact loop, so a level must be
  /// finishable without killing a single enemy).
  void checkLevelEnd() {
    if (player.worldX >= levelEndX) {
      if (isBossLevel && !bossPhase) {
        startBossFight();
      } else if (!isBossLevel) {
        levelComplete();
      }
    }
  }

  void startBossFight() {
    bossPhase = true;
    boss = BossComponent(eraId: currentEra);
    world.add(boss!);
    overlays.add('BossHealthOverlay');
  }

  /// Set once a level has completed or failed, so it can only end once.
  /// Completion can be reached two ways (the end gate, and the exit marker's
  /// distance check) and a hit can land during the crumble effect; without
  /// this a student could complete a level twice or fail one they had won.
  bool levelEnded = false;

  void levelComplete() {
    if (levelEnded) return;
    levelEnded = true;
    _stopwatch.stop();
    pauseEngine();
    audioService.playLevelComplete();

    // Scored per distinct question, taking the best attempt — not per
    // recorded attempt.
    //
    // Phase 3 lets a wrong answer be retried (GAMEPLAY-V2.md Section 6:
    // "There is no dead end"), and every attempt is still logged to
    // `answers` because Section 12 requires the payload to carry them all.
    // Counting raw attempts would mean a student who got every question
    // right on the second try scored 50% and one star, which inverts the
    // teaching goal: the explanation panel exists to be learned from, so
    // learning from it must not be punished. Retrying still costs real
    // things — time, charges, and an artifact's reward drops from 2 to 1.
    //
    // `answers` itself is untouched, so `_submitResult` posts exactly the
    // same array shape it always did.
    final bestByQuestion = <String, bool>{};
    for (final a in answers) {
      bestByQuestion[a.questionId] = (bestByQuestion[a.questionId] ?? false) || a.isCorrect;
    }
    var correct = bestByQuestion.values.where((ok) => ok).length;
    var total = bestByQuestion.length;

    // A level with artifacts is scored per artifact: the student answered ten,
    // so the screen says "x/10", whatever the number of distinct questions.
    // Counting distinct questions gave "5/5" on a level of ten artifacts,
    // because the question bank holds only five per level and the pool serves
    // them twice (playtest, 2026-10-06). Claimed means answered correctly at
    // some attempt, so the best-attempt rule above still holds.
    if (artifactsTotal > 0) {
      total = artifactsTotal;
      correct = artifactsClaimed.clamp(0, artifactsTotal);
    }
    final percentage = total > 0 ? (correct / total * 100).round() : 0;

    // Check perfect level bonus
    if (correct == total && total > 0) {
      score += 50;
    }

    // Submit result
    _submitResult(percentage);

    // Notify game screen
    onLevelComplete?.call(score, correct, total, answers);
  }

  void showLevelFailed() {
    if (levelEnded) return;
    levelEnded = true;
    _stopwatch.stop();
    pauseEngine();
    audioService.playLevelFailed();
    onLevelFailed?.call();
  }

  Future<void> _submitResult(int percentage) async {
    try {
      await apiService.submitResult(QuizResult(
        era: currentEra,
        level: currentLevel,
        type: isBossLevel ? 'post_test' : 'pre_test',
        correctAnswersCount: answers.where((a) => a.isCorrect).length,
        totalQuestions: answers.length,
        percentage: percentage,
        timeTakenTotal: _stopwatch.elapsed.inSeconds,
        questionSnapshots: answers,
      ));
      onResultSubmitted?.call();
    } catch (_) {
      // Silently fail — result can be retransmitted later
    }
  }
}
