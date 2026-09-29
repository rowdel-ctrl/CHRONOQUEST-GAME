import 'package:flame/game.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import 'components/player_component.dart';
import 'components/enemy_component.dart';
import 'components/boss_component.dart';
import 'components/gap_component.dart';
import 'components/enemy_spawner.dart';
import 'components/parallax_background.dart';
import 'components/tile_platform_component.dart';
import 'game_camera.dart';
import 'game_input.dart';
import 'game_spawning.dart';
import 'stretch_to_fill_viewport.dart';

/// Main Flame game class for ChronoQuest.
/// Manages the game loop, player, enemies, questions, and level state.
///
/// Mixes in ChangeNotifier so HUD/boss-health overlay widgets can react to
/// state changes (lives, score, coins, boss health) via ListenableBuilder —
/// without this, those Flutter overlays are only built once when added and
/// never update again, since Flame doesn't rebuild overlay widgets on its
/// own each frame.
class ChronoGame extends FlameGame with HasCollisionDetection, ChangeNotifier {
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

  // Game state
  late PlayerComponent player;
  late GameInput gameInput;
  late EnemySpawner spawner;
  late GroundSpawner groundSpawner;

  // Maintained by GroundSection's onMount/onRemove (see gap_component.dart)
  // so PlayerComponent can check ground collision without scanning/filtering
  // game.children every frame — that scan runs 60x/sec across every enemy,
  // coin, and wall on screen too, which adds up.
  final List<GroundSection> groundSections = [];

  // Maintained by TilePlatformComponent's onMount/onRemove, mirrors
  // groundSections above — lets PlayerComponent check elevated-platform
  // landings without scanning game.children every frame.
  final List<TilePlatformComponent> platforms = [];

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

  int score = 0;
  int playerCoins = 0;
  bool questionShowing = false;
  bool hasJumped = false;
  bool bossPhase = false;
  bool shieldActive = false;
  Question? currentQuestion;
  EnemyComponent? currentEnemy;
  BossComponent? boss;
  List<QuestionSnapshot> answers = [];
  List<Question> bossQuestions = [];

  // Powerups
  PowerUps playerPowerUps = PowerUps();

  // Services
  final AudioService audioService = AudioService();
  final ApiService apiService = ApiService();

  // Callbacks for navigation
  Function(int score, int correct, int total, List<QuestionSnapshot> answers)?
      onLevelComplete;
  Function()? onLevelFailed;

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
    gameInput = GameInput(game: this);
    gameInput.setup();

    // Ground + enemy spawners (game_spawning.dart). After `player` exists —
    // EnemySpawner seeds its distance tracking from the player's starting
    // worldX.
    setupSpawning();

    // Start timer
    _stopwatch.start();

    // Play BGM
    audioService.playBgm(currentEra);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _gameTime += dt;

    // Set after super.update(dt) so it reflects this frame's player
    // movement, not last frame's (avoids a one-frame lag).
    updateCamera();

    if (!questionShowing && !bossPhase) {
      updateSpawning(dt);
      checkLevelEnd();
    }
  }

  // ─── GAME EVENTS ──────────────────────────────────────────────────────────

  void onPlayerJump() {
    if (!questionShowing) {
      player.jump();
      if (!hasJumped) {
        hasJumped = true;
        notifyListeners();
      }
    }
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

  void checkLevelEnd() {
    if (spawner.allEnemiesSpawned &&
        world.children.whereType<EnemyComponent>().isEmpty) {
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

  void levelComplete() {
    _stopwatch.stop();
    pauseEngine();
    audioService.playLevelComplete();

    final correct = answers.where((a) => a.isCorrect).length;
    final total = answers.length;
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
    } catch (_) {
      // Silently fail — result can be retransmitted later
    }
  }
}
