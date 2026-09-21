import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../data/question_bank.dart';
import 'components/player_component.dart';
import 'components/enemy_component.dart';
import 'components/boss_component.dart';
import 'components/ground_component.dart';
import 'components/gap_component.dart';
import 'components/enemy_spawner.dart';
import 'components/parallax_background.dart';
import 'components/tile_platform_component.dart';

/// Main Flame game class for ChronoQuest.
/// Manages the game loop, player, enemies, questions, and level state.
///
/// Mixes in ChangeNotifier so HUD/boss-health overlay widgets can react to
/// state changes (lives, score, coins, boss health) via ListenableBuilder —
/// without this, those Flutter overlays are only built once when added and
/// never update again, since Flame doesn't rebuild overlay widgets on its
/// own each frame.
class ChronoGame extends FlameGame with HasCollisionDetection, ChangeNotifier {
  /// Y position of the ground surface. Computed from the actual game
  /// canvas size (not hardcoded) so it always matches where
  /// GroundComponent visually draws the ground (game.size.y - 60) —
  /// this project has no fixed-resolution viewport, so real device
  /// screens vary and a fixed constant only lined up by coincidence.
  double get groundY => size.y - 60;

  /// World x-coordinate of the camera's visible left edge — the player's
  /// worldX offset by the fixed screen position they render at (see
  /// `camera.viewfinder.position` assignment in `update()`).
  double get cameraLeftEdgeX => player.worldX - GameConstants.playerX;

  /// World x-coordinate just past the camera's visible right edge — where
  /// enemies/obstacles/ground should spawn so they enter from off-screen.
  double get cameraRightEdgeX => cameraLeftEdgeX + size.x;

  // Game state
  late PlayerComponent player;
  late GroundComponent ground;
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
  int lives = GameConstants.livesPerLevel;
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
    // see the viewfinder.position assignment in update().
    camera.viewfinder.anchor = Anchor.topLeft;

    // Real parallax background using the actual era artwork. Its own
    // update() derives layer offsets from the camera's movement — see
    // ParallaxBackground.
    add(ParallaxBackground());

    // Ground — static screen-space backdrop, not part of the scrolling
    // world (stays put regardless of camera position, like a HUD element).
    ground = GroundComponent();
    add(ground);

    // Ground spawner for gap system — sections live in world space.
    groundSpawner = GroundSpawner(game: this);
    groundSpawner.spawnInitialGround();

    // Player — lives in world space so the camera transform applies to it.
    player = PlayerComponent(characterId: selectedCharacterId);
    world.add(player);

    // Questions are intentionally bundled with the app — no backend round-trip.
    final questions = QuestionBank.getQuestions(currentEra, currentLevel);

    if (currentLevel == 10) {
      // Split into warm-up (regular enemies) and boss-phase (asked while fighting).
      final warmup = questions.take(GameConstants.bossWarmupQuestions).toList();
      bossQuestions =
          questions.skip(GameConstants.bossWarmupQuestions).toList();
      spawner = EnemySpawner(game: this, questions: warmup);
    } else {
      spawner = EnemySpawner(game: this, questions: questions);
    }

    // Start timer
    _stopwatch.start();

    // Play BGM
    audioService.playBgm(currentEra);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _gameTime += dt;

    // Camera follows the player's worldX, offset so the player always
    // renders at the fixed screen position GameConstants.playerX. Set
    // after super.update(dt) so it reflects this frame's player movement,
    // not last frame's (avoids a one-frame lag).
    camera.viewfinder.position = Vector2(cameraLeftEdgeX, 0);

    if (!questionShowing && !bossPhase) {
      spawner.update(dt);
      groundSpawner.update(dt);
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

  /// Takes one life and plays the hurt reaction. Returns true when that was
  /// the last life and the level has been failed.
  bool loseLife() {
    lives--;
    player.triggerHurt();
    notifyListeners(); // lives changed
    if (lives > 0) return false;
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
      if (currentLevel == 10 && !bossPhase) {
        startBossFight();
      } else if (currentLevel < 10) {
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
        type: currentLevel == 10 ? 'post_test' : 'pre_test',
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
