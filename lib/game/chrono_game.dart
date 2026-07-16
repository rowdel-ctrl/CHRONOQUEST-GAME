import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
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
class ChronoGame extends FlameGame with HasCollisionDetection {
  // Game constants
  static const double groundY = 520.0;
  static const double worldScrollSpeed = 150.0;

  // Game state
  late PlayerComponent player;
  late GroundComponent ground;
  late EnemySpawner spawner;
  late GroundSpawner groundSpawner;

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

    // Background — solid color per era (placeholder for parallax)
    final bgColor = _getBackgroundColor(currentEra);
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = bgColor,
      priority: -10,
    ));

    // Add parallax-like scrolling elements
    _addScrollingBackground();

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

    spawner = EnemySpawner(game: this, questions: questions);

    // Start timer
    _stopwatch.start();

    // Play BGM
    audioService.playBgm(currentEra);
  }

  void _addScrollingBackground() {
    // Simple scrolling background elements as placeholders
    final colors = _getEraColors(currentEra);
    // Far layer — slow moving
    for (int i = 0; i < 5; i++) {
      add(_BackgroundElement(
        elementSize: Vector2(120, 80 + (i * 20).toDouble()),
        elementPosition: Vector2(i * 200.0, groundY - 200 - (i * 30).toDouble()),
        color: colors[0],
        speed: 20,
        priority: -8,
      ));
    }
    // Near layer — faster moving
    for (int i = 0; i < 8; i++) {
      add(_BackgroundElement(
        elementSize: Vector2(60, 40 + (i * 10).toDouble()),
        elementPosition: Vector2(i * 130.0, groundY - 80 - (i * 15).toDouble()),
        color: colors[1],
        speed: 40,
        priority: -5,
      ));
    }
  }

  List<Color> _getEraColors(String era) {
    switch (era) {
      case 'pre-colonial':
        return [const Color(0xFF2E7D32), const Color(0xFF4CAF50)];
      case 'spanish':
        return [const Color(0xFF5D4037), const Color(0xFF795548)];
      case 'american':
        return [const Color(0xFF37474F), const Color(0xFF607D8B)];
      case 'ww2':
        return [const Color(0xFF424242), const Color(0xFF616161)];
      case 'modern':
        return [const Color(0xFF1565C0), const Color(0xFF42A5F5)];
      default:
        return [const Color(0xFF5D4037), const Color(0xFF795548)];
    }
  }

  Color _getBackgroundColor(String era) {
    switch (era) {
      case 'pre-colonial':
        return const Color(0xFF87CEEB); // tropical sky
      case 'spanish':
        return const Color(0xFFD4C4A8); // warm colonial
      case 'american':
        return const Color(0xFFB0C4DE); // light blue
      case 'ww2':
        return const Color(0xFF808080); // grey war sky
      case 'modern':
        return const Color(0xFF90CAF9); // modern blue
      default:
        return const Color(0xFFD4C4A8);
    }
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
    if (lives <= 0) {
      showLevelFailed();
    } else {
      player.respawn();
    }
  }

  void collectCoin() {
    playerCoins++;
    score += 5;
    audioService.playCoin();
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

  // ─── SAMPLE QUESTIONS (fallback when API unavailable) ─────────────────────

  List<Question> _createSampleQuestions() {
    return List.generate(
      10,
      (i) => Question(
        id: 'sample_$i',
        era: currentEra,
        questionText: 'Tanong ${i + 1}: Sino ang bayani ng Mactan?',
        options: const [
          QuestionOption(label: 'A', text: 'Lapu-Lapu'),
          QuestionOption(label: 'B', text: 'Magellan'),
          QuestionOption(label: 'C', text: 'Rizal'),
          QuestionOption(label: 'D', text: 'Bonifacio'),
        ],
        correctAnswer: 'A',
      ),
    );
  }
}

/// Simple scrolling background element (placeholder for parallax images).
class _BackgroundElement extends PositionComponent {
  final Color color;
  final double speed;
  final Vector2 elementSize;
  final Vector2 elementPosition;

  // Cached velocity
  final Vector2 _velocity = Vector2.zero();

  _BackgroundElement({
    required this.elementSize,
    required this.elementPosition,
    required this.color,
    required this.speed,
    int priority = -5,
  }) : super(priority: priority);

  @override
  Future<void> onLoad() async {
    size = elementSize;
    position = elementPosition;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _velocity.setValues(-speed, 0);
    position.addScaled(_velocity, dt);

    // Wrap around
    if (position.x < -size.x) {
      final game = findGame()!;
      position.x = game.size.x + 50;
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color.withValues(alpha: 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        size.toRect(),
        const Radius.circular(4),
      ),
      paint,
    );
  }
}
