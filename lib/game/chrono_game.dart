import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
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

/// Main Flame game class for ChronoQuest.
/// Manages the game loop, player, enemies, questions, and level state.
///
/// Mixes in ChangeNotifier so HUD/boss-health overlay widgets can react to
/// state changes (lives, score, coins, boss health) via ListenableBuilder —
/// without this, those Flutter overlays are only built once when added and
/// never update again, since Flame doesn't rebuild overlay widgets on its
/// own each frame.
class ChronoGame extends FlameGame with HasCollisionDetection, ChangeNotifier {
  // Game constants
  static const double worldScrollSpeed = 150.0;

  /// Y position of the ground surface. Computed from the actual game
  /// canvas size (not hardcoded) so it always matches where
  /// GroundComponent visually draws the ground (game.size.y - 60) —
  /// this project has no fixed-resolution viewport, so real device
  /// screens vary and a fixed constant only lined up by coincidence.
  double get groundY => size.y - 60;

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

  String currentEra = 'spanish';
  int currentLevel = 1;
  int lives = 3;
  int score = 0;
  int playerCoins = 0;
  bool questionShowing = false;
  bool bossPhase = false;
  bool shieldActive = false;
  Question? currentQuestion;
  EnemyComponent? currentEnemy;
  BossComponent? boss;
  List<QuestionSnapshot> answers = [];
  List<Question> bossQuestions = [];
  int wrongAttemptsOnCurrentQuestion = 0;

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

    // Real parallax background using the actual era artwork.
    await _addParallaxBackground();

    // Ground
    ground = GroundComponent();
    add(ground);

    // Ground spawner for gap system
    groundSpawner = GroundSpawner(game: this);
    groundSpawner.spawnInitialGround();

    // Player
    player = PlayerComponent(characterId: selectedCharacterId);
    add(player);

    // Questions are intentionally bundled with the app — no backend round-trip.
    final questions = QuestionBank.getQuestions(currentEra, currentLevel);

    if (currentLevel == 10) {
      // Split into warm-up (regular enemies) and boss-phase (asked while fighting).
      final warmup = questions.take(GameConstants.bossWarmupQuestions).toList();
      bossQuestions = questions.skip(GameConstants.bossWarmupQuestions).toList();
      spawner = EnemySpawner(game: this, questions: warmup);
    } else {
      spawner = EnemySpawner(game: this, questions: questions);
    }

    // Start timer
    _stopwatch.start();

    // Play BGM
    audioService.playBgm(currentEra);
  }

  Future<void> _addParallaxBackground() async {
    final bgKey = _backgroundAssetKeyForEra(currentEra);
    try {
      final parallax = await loadParallaxComponent(
        [
          ParallaxImageData('backgrounds/${bgKey}_far.png'),
          ParallaxImageData('backgrounds/${bgKey}_near.png'),
        ],
        baseVelocity: Vector2(20, 0),
        velocityMultiplierDelta: Vector2(2.2, 1.0),
        fill: LayerFill.height,
        repeat: ImageRepeat.repeatX,
        // Explicit size/position — don't rely on ParallaxComponent
        // auto-sizing to the canvas. It rendered as a small tile in the
        // corner instead of covering the screen without this.
        size: size,
        position: Vector2.zero(),
        priority: -10,
      );
      add(parallax);
    } catch (e) {
      // Fallback so the game is still playable if a background asset is
      // somehow missing, instead of leaving the whole load future unresolved.
      debugPrint('Failed to load parallax background for $currentEra: $e');
      add(RectangleComponent(
        size: size,
        paint: Paint()..color = const Color(0xFFD4C4A8),
        priority: -10,
      ));
    }
  }

  /// Background PNGs are named without the hyphen used in era ids
  /// (e.g. 'precolonial_far.png' for the 'pre-colonial' era).
  String _backgroundAssetKeyForEra(String era) {
    if (era == 'pre-colonial') return 'precolonial';
    return era;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _gameTime += dt;

    if (!questionShowing && !bossPhase) {
      spawner.update(dt);
      groundSpawner.update(dt);
      checkLevelEnd();
    }
  }

  // ─── QUESTION HANDLING ────────────────────────────────────────────────────

  void showQuestion(Question q, EnemyComponent enemy) {
    currentQuestion = q;
    currentEnemy = enemy;
    questionShowing = true;
    wrongAttemptsOnCurrentQuestion = 0;
    pauseEngine();
    overlays.add('QuestionOverlay');
  }

  void showBossQuestion(Question q, BossComponent bossRef) {
    currentQuestion = q;
    currentEnemy = null;
    questionShowing = true;
    wrongAttemptsOnCurrentQuestion = 0;
    pauseEngine();
    overlays.add('QuestionOverlay');
  }

  void handleAnswer(String answer) {
    overlays.remove('QuestionOverlay');
    final isCorrect = answer == currentQuestion!.correctAnswer;

    answers.add(QuestionSnapshot(
      questionId: currentQuestion!.id,
      studentAnswer: answer,
      correctAnswer: currentQuestion!.correctAnswer,
      isCorrect: isCorrect,
      timeTaken: currentQuestion!.elapsedSeconds,
    ));

    if (isCorrect) {
      score += 10;
      // Speed bonus
      if (currentQuestion!.elapsedSeconds < 10) {
        score += 5;
      }

      if (bossPhase && boss != null) {
        boss!.takeDamage();
      } else {
        currentEnemy?.defeat();
      }
      questionShowing = false;
      resumeEngine();
      notifyListeners(); // score changed, and possibly boss health
    } else {
      // Shield absorbs wrong answer
      if (shieldActive) {
        shieldActive = false;
        questionShowing = false;
        if (bossPhase && boss != null) {
          // No damage to boss, but no life lost either
        } else {
          currentEnemy?.defeat();
        }
        resumeEngine();
        return;
      }

      lives--;
      player.triggerHurt();
      wrongAttemptsOnCurrentQuestion++;
      notifyListeners(); // lives changed

      if (lives <= 0) {
        questionShowing = false;
        showLevelFailed();
      } else if (wrongAttemptsOnCurrentQuestion >= 2) {
        // 2 wrong on same enemy: enemy passes, already lost hearts
        questionShowing = false;
        currentEnemy?.defeat();
        resumeEngine();
      } else {
        // Show question one more time
        Future.delayed(const Duration(milliseconds: 800), () {
          overlays.add('QuestionOverlay');
        });
      }
    }
  }

  // ─── GAME EVENTS ──────────────────────────────────────────────────────────

  void onPlayerJump() {
    if (!questionShowing) {
      player.jump();
    }
  }

  void playerFellInGap() {
    lives--;
    player.triggerHurt();
    notifyListeners(); // lives changed
    if (lives <= 0) {
      showLevelFailed();
    } else {
      player.respawn();
    }
  }

  /// Player failed to jump over a wall obstacle in time. Same damage as
  /// falling in a gap, but no respawn — the player didn't fall anywhere,
  /// they just took a hit, and the wall keeps scrolling past.
  void playerHitObstacle() {
    lives--;
    player.triggerHurt();
    notifyListeners(); // lives changed
    if (lives <= 0) {
      showLevelFailed();
    }
  }

  void collectCoin() {
    playerCoins++;
    score += 5;
    audioService.playCoin();
    notifyListeners(); // coins/score changed
  }

  // ─── LEVEL STATE ──────────────────────────────────────────────────────────

  void checkLevelEnd() {
    if (spawner.allEnemiesSpawned &&
        children.whereType<EnemyComponent>().isEmpty) {
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
    add(boss!);
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
        correctAnswersCount:
            answers.where((a) => a.isCorrect).length,
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