# ChronoQuest — Auto-Runner Platformer (Manual Jump)

**Game type:** Side-scrolling platformer with manual jump + quiz encounters
**Engine:** Flutter + Flame game engine
**Platform:** Android (Android 10–13)
**Target users:** Grade 4–6 elementary students
**Subject:** Araling Panlipunan (Philippine History)
**Timeline:** 2 months
**Backend:** Node.js/Express already built and running

---

## What this game is

A side-scrolling platformer where the character runs forward automatically but the student controls jumping by tapping the screen. When an enemy appears, the game pauses and a quiz question card slides up. Correct answer = enemy defeated, game resumes. Wrong answer = lose a heart.

Falling into gaps does NOT cost a heart — student respawns automatically. Lives are only lost from wrong answers. This keeps the focus on learning, not platformer skill.

---

## What we build vs what we skip

### We build (core game — 2 months):
- Character runs automatically, student taps screen to jump
- Scrolling historical backgrounds (parallax, 2 layers)
- Flat ground with visible low walls and gaps as obstacles
- Falling into gap = lose 1 heart (gaps are a real threat, not just a nuisance)
- Enemies approach from right, trigger quiz on contact
- Correct answer: enemy defeated with animation
- Wrong answer: lose a heart, question reappears once
- 3 lives per level. Lost from WRONG ANSWERS and from FALLING INTO GAPS.
- 0 hearts → Level Failed → restart from Question 1, hearts reset to 3
- Coins collectible during gameplay — used to unlock characters (not just bonus points)
- Powerups (50/50, Time Freeze, Shield)
- Boss fight at Level 10 (5-question battle)
- 5 eras with different backgrounds, enemies, and bosses
- Cold pre-test before each era (plain screen, no Flame)
- Background history screen (scroll-gated)
- Level select screen (10 milestones per era)
- Level complete and level failed screens
- Era complete screen with learning gain revealed
- Full backend integration (results, progress, leaderboard)

### We skip for now (add after defense):
- Tile-based level maps (Tiled editor)
- Multiple platform heights
- More than 2 enemy types per era
- Full sprite sheet animations (12+ frames)
- Complex moving platforms

---

## Full game flow

```
App opens → Splash Screen
  ↓
Login Screen
  ↓
Character Selection Screen
  ├── 5 characters in carousel
  ├── Left: Mechanics card, Leaderboard card
  └── Bottom right: START button
  ↓
Era Selection Screen (5 books on shelf)
  ↓
Tap available era
  ↓
COLD PRE-TEST (plain parchment screen, no Flame, no timer)
  10 questions, no feedback on answers, score hidden
  Saved silently → { type: 'cold_pre_test' }
  ↓
BACKGROUND HISTORY SCREEN
  Scroll-gated, "Handa na ako!" button at bottom
  ↓
LEVEL SELECT SCREEN
  10 milestone markers on a road
  Level 1 always unlocked, others unlock sequentially
  Level 10 (Boss) locked until L1–9 done
  ↓
LEVEL STARTS → Flame game canvas loads
  Character begins running automatically
  Student taps screen to jump over walls and gaps
  Background scrolls (parallax)
  ↓
[GAMEPLAY LOOP]
  Character runs right automatically
  Walls and gaps appear → student taps screen to jump
  Fall into gap → lose 1 heart
  0 hearts → Level Failed → restart Level from Q1
  Coins appear → auto-collected on overlap → added to Student.coins (used to unlock characters)
  Enemy walks in from right
    → When close: game pauses, question card slides up
    → Student answers
    → Correct: enemy defeated, resume
    → Wrong: lose 1 heart, question reappears once
    → 2 wrong on same enemy: enemy passes, lose 2 hearts
  Character reaches end flag
  ↓
LEVEL COMPLETE
  Stars (1–3 based on score)
  Points earned
  Powerup earned if milestone
  Submit result to backend
  Next level unlocks
  ↓
After Levels 1–9 complete → Level 10 unlocks
  ↓
LEVEL 10 — BOSS LEVEL
  Regular enemies appear first (3 warm-up questions)
  Character reaches boss at end
  Boss walks to center, stops
  5-question boss battle begins
  Defeat boss → era complete
  ↓
ERA COMPLETE SCREEN
  Cold pre-test score revealed for first time
  Levels 1–9 avg shown
  Level 10 score shown
  Learning gain: +X% (first reveal)
  Badges earned, points total
  ↓
Return to era selection, next era unlocks
```

---

## Eras, enemies, and backgrounds

### Era 1: Sinaunang Panahon (Pre-colonial)

**Background:**
- Far layer: jungle treeline, mountains, tropical sky
- Near layer: bamboo forest, tropical plants, tribal markers
- Ground: dirt path, stone markers

**Character guide:** Datu Lapu-Lapu

**Enemies:**
- Rival tribal warrior (walks left, spear raised)
- Dark spirit / anito (floats left toward character)

**Boss (Level 10):** Bakunawa — giant sea serpent
Boss dialogue: "Patunayan mo ang iyong karunungan!"

**Obstacles:** Bamboo fences (walls to jump over), river gaps

**Collectibles:** Gold ornaments, ancient clay pots, tribal shields

**End landmark:** Bamboo gate with tribal markings

---

### Era 2: Panahon ng Kastila (Spanish Colonial 1565–1898)

**Background:**
- Far layer: Spanish colonial church silhouettes, stone buildings
- Near layer: cobblestone path, stone walls, hanging lanterns
- Ground: stone path with colonial tiles

**Character guide:** Jose Rizal

**Enemies:**
- Spanish soldier (walks left, sword drawn)
- Tax collector friar (runs left, scroll in hand)

**Boss (Level 10):** Spanish Governor-General (armored, large)
Boss dialogue: "Kaya mo bang harapin ang kapangyarihan ng Espanya?"

**Obstacles:** Stone walls, moat gaps, wooden barricades

**Collectibles:** Gold pesos, old books, quill pens

**End landmark:** Intramuros fort gate

---

### Era 3: Panahon ng Amerikano (American Period 1898–1946)

**Background:**
- Far layer: American-style buildings, Philippine and US flags
- Near layer: dirt road, telegraph poles, wooden fences
- Ground: packed dirt road

**Character guide:** Apolinario Mabini

**Enemies:**
- American soldier (walks left, rifle raised)
- Propaganda newspaper (floating, spinning left)

**Boss (Level 10):** American General (large uniformed figure)
Boss dialogue: "Ipakita mo na hindi ka mabibili ng pangako ng kalayaan!"

**Obstacles:** Wooden barricades, road trenches (gaps)

**Collectibles:** Philippine flags, Malolos Constitution scrolls, historical documents

**End landmark:** Malolos Congress building

---

### Era 4: Ikalawang Digmaang Pandaigdig (WW2 1941–1945)

**Background:**
- Far layer: war-damaged buildings, smoke and fire silhouettes
- Near layer: sandbags, barbed wire fences, military crates
- Ground: rubble-strewn dirt with shell craters

**Character guide:** Josefa Llanes Escoda

**Enemies:**
- Japanese soldier (runs left, bayonet ready)
- Military tank (slow-moving left, larger sprite)

**Boss (Level 10):** Japanese Commander (large, uniformed, katana)
Boss dialogue: "Ang kalayaan ay hindi ipinagkakaloob — kinukuha!"

**Obstacles:** Sandbag walls, bomb crater gaps, barbed wire barriers

**Collectibles:** Dog tags, Red Cross supply kits, resistance pamphlets

**End landmark:** Liberation checkpoint with Philippine flag

---

### Era 5: Makabagong Panahon (Modern 1946–present)

**Background:**
- Far layer: modern Manila skyline, government buildings, blue sky
- Near layer: city streets, jeepneys, streetlights, storefronts
- Ground: city pavement with road markings

**Character guide:** Corazon Aquino

**Enemies:**
- Corruption figure (shadowy suited figure, walks left)
- Misinformation cloud (dark floating cloud with false words, drifts left)

**Boss (Level 10):** Corruption personified (large shadowy figure with chains)
Boss dialogue: "Ang katotohanan ang iyong sandata!"

**Obstacles:** Overturned vehicles (walls), flooded road sections (gaps)

**Collectibles:** Yellow ribbons, ballot boxes, Philippine constitutions

**End landmark:** EDSA monument / People Power shrine

---

## Characters (5 total)

Student picks one on character selection screen. Chosen character appears throughout all eras.

Each character needs 6 images:

| Character | Files |
|-----------|-------|
| Lapu-Lapu | lapu_walk_1.png, lapu_walk_2.png, lapu_walk_3.png, lapu_walk_4.png, lapu_jump.png, lapu_hurt.png |
| Jose Rizal | rizal_walk_1-4.png, rizal_jump.png, rizal_hurt.png |
| Apolinario Mabini | mabini_walk_1-4.png, mabini_jump.png, mabini_hurt.png |
| Josefa Escoda | escoda_walk_1-4.png, escoda_jump.png, escoda_hurt.png |
| Corazon Aquino | aquino_walk_1-4.png, aquino_jump.png, aquino_hurt.png |

6 images × 5 characters = **30 character sprites**

---

## Enemies (2 per era = 10 types)

Each enemy: 2-frame walk animation (walk_1.png, walk_2.png)

```
assets/enemies/
├── tribal_warrior_1.png, tribal_warrior_2.png
├── dark_spirit_1.png, dark_spirit_2.png
├── spanish_soldier_1.png, spanish_soldier_2.png
├── tax_collector_1.png, tax_collector_2.png
├── american_soldier_1.png, american_soldier_2.png
├── propaganda_1.png, propaganda_2.png
├── japanese_soldier_1.png, japanese_soldier_2.png
├── tank_1.png, tank_2.png
├── corruption_figure_1.png, corruption_figure_2.png
└── misinfo_cloud_1.png, misinfo_cloud_2.png
```

10 types × 2 frames = **20 enemy sprites**

---

## Bosses (1 per era = 5 bosses)

Each boss: 3 images (idle, attack/hurt reaction, defeated)

```
assets/bosses/
├── bakunawa_idle.png, bakunawa_attack.png, bakunawa_defeated.png
├── governor_idle.png, governor_attack.png, governor_defeated.png
├── general_idle.png, general_attack.png, general_defeated.png
├── commander_idle.png, commander_attack.png, commander_defeated.png
└── corruption_boss_idle.png, corruption_boss_attack.png, corruption_boss_defeated.png
```

5 bosses × 3 images = **15 boss sprites**

---

## Total art assets

| Category | Count |
|----------|-------|
| Character sprites | 30 |
| Enemy sprites | 20 |
| Boss sprites | 15 |
| Background layers (2 per era × 5) | 10 |
| Ground/obstacle tiles | 10 |
| Collectible icons (3 per era) | 15 |
| Powerup icons | 3 |
| UI elements | ~20 |
| **Total** | **~123 images** |

Use colored rectangles as placeholders during development. Replace with real art before defense.

---

## Powerups

**50/50** — removes 2 wrong answer options from current question.

**Time Freeze** — freezes all enemies on screen for 10 seconds. Character keeps running, no questions trigger during freeze.

**Shield** — absorbs one wrong answer without losing a heart. Shows as a brief glow around character. Single use per level.

Powerups NOT available during cold pre-test or Level 10 post-test boss fight.

Students earn powerups at milestones:
- Complete Level 3: earn 1 × 50/50
- Complete Level 5: earn 1 × Time Freeze
- Complete Level 7: earn 1 × Shield
- Perfect score any level: earn 1 random powerup
- Top 3 on weekly leaderboard: earn 1 of each

---

## Points system

| Action | Points |
|--------|--------|
| Correct answer | 10 |
| Correct answer under 10 seconds | +5 bonus |
| Coin collected | 5 |
| Artifact collected | 15 |
| Perfect level (all correct) | +50 bonus |
| Complete an era | +100 bonus |
| Learning gain ≥ 20% | +75 bonus |

---

## 8-week build schedule

### Week 1: Setup + Flame basics
- Flutter project, pubspec.yaml, folder structure
- Flame installed, blank game canvas running
- Character walk animation (4 frames) loading and playing
- Character moves right automatically at fixed speed
- Parallax background scrolling (2 layers) for one era

### Week 2: Jump + ground + obstacles
- Ground component (flat rectangle at bottom)
- Character stays on ground correctly
- GestureDetector wrapping GameWidget — tap screen = jump
- Manual gravity: character jumps and lands correctly
- Question overlay blocks jump taps
- Visible low wall obstacles (character must jump over)
- Gap in ground: falling respawns player at same X, no heart lost

### Week 3: Enemy system + question overlay
- Enemy component loads 2-frame walk animation, walks left
- Collision detection: player touches enemy → game pauses
- Flutter question card overlay slides up
- Correct answer: enemy defeated (fade out), resume
- Wrong answer: player loses heart, question reappears once
- 0 hearts: level failed screen

### Week 4: Full level loop
- Enemy spawner: spawns every 500px of travel
- End-of-level landmark: reaching it triggers level complete
- Level complete screen (stars, score, points, next button)
- Level failed screen (retry, return to level select)
- Result submitted to backend after each level
- Lives reset to 3 on each new level start

### Week 5: All 5 eras
- All 5 background sets (swap parallax per era)
- All 10 enemy types loaded (era-specific enemy pool)
- Level select screen (10 milestones per era)
- Era unlock logic (complete all 10 levels → next era opens)
- Questions fetched from backend per era per level

### Week 6: Boss fight + powerups
- Boss component: large sprite, walks to center, stops
- Boss health bar (Flutter overlay widget, decreases per correct answer)
- 5-question boss battle (correct = boss damage, wrong = player damage)
- Boss defeat animation + era complete trigger
- All 3 powerups: 50/50, Time Freeze, Shield
- Powerup UI on question overlay (grayed when count = 0)
- Powerup earned on milestones (award after level complete)

### Week 7: Complete game loop + all screens
- Cold pre-test screen (plain Flutter, before each era)
- Background history screen (scroll-gated)
- Era complete screen (cold pre-test score revealed, learning gain)
- Era unlock after boss defeat
- Era progress synced with backend
- Coin collectibles (tap to collect during run)
- Character selection screen (5 characters, PageView carousel)
- Era selection screen (bookshelf, locked/unlocked/completed)
- Leaderboard screen (class + school tabs)
- Profile screen (stats, per-era scores, powerup inventory)

### Week 8: Polish + testing
- Sound effects (correct, wrong, jump, coin, boss, era complete, BGM)
- Lottie fireworks on era complete screen
- Bug fixing on Android devices
- Performance testing on low-spec Android (min 2GB RAM)
- Release APK build

---

## Folder structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants.dart
│   ├── theme.dart
│   ├── router.dart
│   └── dio_client.dart
├── models/
│   ├── student.dart
│   ├── question.dart
│   ├── quiz_result.dart
│   └── era_progress.dart
├── providers/
│   ├── auth_provider.dart
│   ├── game_provider.dart
│   └── progress_provider.dart
├── services/
│   ├── api_service.dart
│   ├── storage_service.dart
│   └── audio_service.dart
├── game/
│   ├── chrono_game.dart
│   ├── components/
│   │   ├── player_component.dart
│   │   ├── enemy_component.dart
│   │   ├── boss_component.dart
│   │   ├── ground_component.dart
│   │   ├── gap_component.dart
│   │   ├── wall_component.dart
│   │   ├── coin_component.dart
│   │   └── enemy_spawner.dart
│   └── overlays/
│       ├── question_overlay.dart
│       ├── hud_overlay.dart
│       └── pause_overlay.dart
└── screens/
    ├── auth/login_screen.dart
    ├── home/character_selection_screen.dart
    ├── home/era_selection_screen.dart
    ├── game/pre_test_screen.dart
    ├── game/background_history_screen.dart
    ├── game/level_select_screen.dart
    ├── game/level_complete_screen.dart
    ├── game/level_failed_screen.dart
    ├── game/era_complete_screen.dart
    ├── profile/profile_screen.dart
    └── profile/leaderboard_screen.dart
```

---

---
---

# AI PROMPT — ChronoQuest Platformer Game (Manual Jump)

**Instructions:** Paste ChronoQuest_Project_Context.md first in a new conversation, then paste everything below.

---

## PASTE THIS ENTIRE BLOCK:

---

I am building a Flutter mobile game called ChronoQuest for my capstone project at Marinduque State University. It is a Philippine History (Araling Panlipunan) side-scrolling platformer game for Grade 4–6 students using Flutter + Flame game engine. Build the complete, fully deployable Flutter application. Use the specifications below exactly. Do not ask for clarification — build everything as described.

---

### WHAT THIS GAME IS

A side-scrolling platformer where:
- The character runs forward automatically (student does not control horizontal movement)
- The student taps anywhere on screen to make the character jump
- When an enemy approaches and touches the player, the game pauses and a quiz question card appears (Flutter widget overlay over Flame canvas)
- Correct answer: enemy defeated, game resumes
- Wrong answer: player loses 1 heart, question appears once more
- Falling into a gap: player loses 1 heart
- Lives (hearts) are lost from WRONG ANSWERS and from FALLING INTO GAPS
- This is NOT a full physics platformer — no Rigidbody, no Tiled maps, flat ground only, manual gravity

---

### TECH STACK

```yaml
dependencies:
  flutter:
    sdk: flutter
  flame: ^1.17.0
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  go_router: ^13.0.0
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.3
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  audioplayers: ^5.2.1
  lottie: ^3.1.0
  google_fonts: ^6.1.0
  cached_network_image: ^3.3.1

dev_dependencies:
  build_runner: ^2.4.8
  riverpod_generator: ^2.3.9
  hive_generator: ^2.0.1
```

---

### DESIGN SYSTEM

```dart
class AppColors {
  static const Color primary      = Color(0xFF8B4513);
  static const Color primaryDark  = Color(0xFF5C2D0A);
  static const Color accent       = Color(0xFFD4AF37);
  static const Color background   = Color(0xFFFAF7F2);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color surfaceAlt   = Color(0xFFF3EDE3);
  static const Color textPrimary  = Color(0xFF2C1810);
  static const Color textMuted    = Color(0xFFB09880);
  static const Color success      = Color(0xFF3A7D44);
  static const Color danger       = Color(0xFFC0392B);
  static const Color warning      = Color(0xFFD97706);
}

class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL', defaultValue: 'http://10.0.2.2:5000/api/v1');
}
```

---

### BACKEND API

```
POST   /api/v1/student/login
GET    /api/v1/student/profile
POST   /api/v1/student/results
GET    /api/v1/student/era-progress
PATCH  /api/v1/student/power-ups
GET    /api/v1/student/leaderboard?scope=class|school
GET    /api/v1/questions/by-era/:era?level=N&gradeLevel=grade5&limit=10
```

QuizResult body:
```json
{
  "era": "spanish",
  "level": 3,
  "type": "pre_test",
  "correctAnswersCount": 7,
  "totalQuestions": 10,
  "percentage": 70,
  "timeTakenTotal": 187,
  "questionSnapshots": [
    {
      "questionId": "...",
      "studentAnswer": "B",
      "correctAnswer": "B",
      "isCorrect": true,
      "timeTaken": 18
    }
  ]
}
```

type values:
- "cold_pre_test" → baseline pre-test (plain screen, before reading)
- "pre_test"       → formative assessment (Levels 1–9 gameplay, after reading)
- "post_test"      → summative post-test (Level 10 boss fight)
Learning gain = post_test score minus cold_pre_test score.
Levels 1-9 data shows progressive improvement per level.

---

### MAIN FLAME GAME: chrono_game.dart

```dart
class ChronoGame extends FlameGame with HasCollisionDetection {
  late PlayerComponent player;
  late ParallaxComponent background;
  late GroundComponent ground;
  late EnemySpawner spawner;

  String currentEra = 'spanish';
  int currentLevel = 1;
  int lives = 3;
  int score = 0;
  bool questionShowing = false;
  bool bossPhase = false;
  Question? currentQuestion;
  EnemyComponent? currentEnemy;
  BossComponent? boss;
  List<QuestionAnswer> answers = [];
  int questionsTotal = 10;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Parallax background
    background = await loadParallaxComponent(
      [
        ParallaxImageData('backgrounds/${currentEra}_far.png'),
        ParallaxImageData('backgrounds/${currentEra}_near.png'),
      ],
      baseVelocity: Vector2(20, 0),
      velocityMultiplierDelta: Vector2(1.8, 0),
      repeat: ImageRepeat.repeatX,
      fill: LayerFill.height,
    );
    add(background);

    // Ground
    ground = GroundComponent();
    add(ground);

    // Player
    player = PlayerComponent(characterId: selectedCharacterId);
    add(player);

    // Enemy spawner
    final questions = await apiService.getQuestions(currentEra, currentLevel);
    spawner = EnemySpawner(game: this, questions: questions);

    // Overlays
    overlays.addEntry('QuestionOverlay', (context, game) =>
      QuestionOverlayWidget(
        game: game as ChronoGame,
        onAnswer: handleAnswer,
      ));
    overlays.addEntry('HudOverlay', (context, game) =>
      HudOverlayWidget(game: game as ChronoGame));
    overlays.addEntry('BossHealthOverlay', (context, game) =>
      BossHealthOverlayWidget(game: game as ChronoGame));
    overlays.add('HudOverlay');
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!questionShowing && !bossPhase) {
      spawner.update(dt);
      checkLevelEnd();
    }
  }

  void showQuestion(Question q, EnemyComponent enemy) {
    currentQuestion = q;
    currentEnemy = enemy;
    questionShowing = true;
    pauseEngine();
    overlays.add('QuestionOverlay');
  }

  void handleAnswer(String answer) {
    overlays.remove('QuestionOverlay');
    final isCorrect = answer == currentQuestion!.correctAnswer;

    answers.add(QuestionAnswer(
      questionId: currentQuestion!.id,
      studentAnswer: answer,
      correctAnswer: currentQuestion!.correctAnswer,
      isCorrect: isCorrect,
      timeTaken: currentQuestion!.elapsedSeconds,
    ));

    if (isCorrect) {
      score += 10;
      currentEnemy?.defeat();
      questionShowing = false;
      resumeEngine();
    } else {
      lives--;
      player.triggerHurt();
      if (lives <= 0) {
        questionShowing = false;
        showLevelFailed();
      } else {
        // Show question one more time
        Future.delayed(const Duration(milliseconds: 800), () {
          overlays.add('QuestionOverlay');
        });
      }
    }
  }

  void onPlayerJump() {
    if (!questionShowing) {
      player.jump();
    }
  }

  void playerFellInGap() {
    // Lose a heart and respawn
    lives--;
    player.triggerHurt();
    if (lives <= 0) {
      showLevelFailed();
    } else {
      player.position = Vector2(80, groundY - player.size.y);
      player.velocityY = 0;
      player.isOnGround = true;
    }
  }

  void checkLevelEnd() {
    if (spawner.allEnemiesSpawned && children.whereType<EnemyComponent>().isEmpty) {
      if (currentLevel == 10 && !bossPhase) {
        startBossFight();
      } else if (currentLevel < 10) {
        levelComplete();
      }
    }
  }

  void levelComplete() {
    pauseEngine();
    final percentage = (answers.where((a) => a.isCorrect).length / answers.length * 100).round();
    submitResult(percentage);
    // Navigate to level complete screen via router
  }

  void showLevelFailed() {
    pauseEngine();
    overlays.add('LevelFailedOverlay');
  }

  void startBossFight() {
    bossPhase = true;
    boss = BossComponent(eraId: currentEra);
    add(boss!);
    overlays.add('BossHealthOverlay');
  }

  void submitResult(int percentage) async {
    await apiService.submitResult(QuizResult(
      era: currentEra,
      level: currentLevel,
      type: currentLevel == 10 ? 'post_test' : 'pre_test',
      correctAnswersCount: answers.where((a) => a.isCorrect).length,
      totalQuestions: answers.length,
      percentage: percentage,
      timeTakenTotal: elapsedTime.toInt(),
      questionSnapshots: answers,
    ));
  }

  static const double groundY = 520.0; // adjust based on screen
  String selectedCharacterId = 'rizal'; // set from character selection
}
```

---

### PLAYER COMPONENT: player_component.dart

```dart
class PlayerComponent extends SpriteAnimationComponent
    with HasGameRef<ChronoGame>, CollisionCallbacks {

  static const double runSpeed  = 0;       // player stays at fixed X
  static const double gravity   = 900.0;
  static const double jumpForce = -480.0;
  static const double groundY   = ChronoGame.groundY;

  double velocityY = 0.0;
  bool isOnGround = true;
  final String characterId;

  late SpriteAnimation walkAnimation;
  late SpriteAnimation jumpAnim;
  late SpriteAnimation hurtAnim;

  PlayerComponent({required this.characterId});

  @override
  Future<void> onLoad() async {
    walkAnimation = await gameRef.loadSpriteAnimation(
      'characters/${characterId}_walk_1.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.15,
        textureSize: Vector2(64, 80),
      ),
    );
    // Load individual frames for jump and hurt using SpriteAnimation.spriteList
    jumpAnim = SpriteAnimation.spriteList(
      [await gameRef.loadSprite('characters/${characterId}_jump.png')],
      stepTime: 1.0,
    );
    hurtAnim = SpriteAnimation.spriteList(
      [await gameRef.loadSprite('characters/${characterId}_hurt.png')],
      stepTime: 0.3,
    );

    animation = walkAnimation;
    size = Vector2(64, 80);
    position = Vector2(80, groundY - 80);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isOnGround) {
      velocityY += gravity * dt;
      position.y += velocityY * dt;
    }

    // Land on ground
    if (position.y >= groundY - size.y) {
      position.y = groundY - size.y;
      velocityY = 0;
      isOnGround = true;
      animation = walkAnimation;
    }

    // Fell into gap — lose a heart
    if (position.y > gameRef.size.y + 100) {
      gameRef.playerFellInGap();
    }
  }

  void jump() {
    if (isOnGround) {
      velocityY = jumpForce;
      isOnGround = false;
      animation = jumpAnim;
      gameRef.audioService.playJump();
    }
  }

  void triggerHurt() {
    animation = hurtAnim;
    gameRef.audioService.playHurt();
    Future.delayed(const Duration(milliseconds: 600), () {
      animation = walkAnimation;
    });
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    super.onCollision(points, other);
    if (other is EnemyComponent && !gameRef.questionShowing) {
      gameRef.showQuestion(other.question, other);
    }
    if (other is CoinComponent) {
      other.removeFromParent();
      gameRef.score += 5;
      gameRef.audioService.playCoin();
    }
  }
}
```

---

### GAME SCREEN WIDGET: game_screen.dart

This is the Flutter widget that wraps the Flame GameWidget. The tap-to-jump is handled here.

```dart
class GameScreen extends StatefulWidget {
  final String eraId;
  final int level;
  const GameScreen({required this.eraId, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late ChronoGame game;

  @override
  void initState() {
    super.initState();
    game = ChronoGame()
      ..currentEra = widget.eraId
      ..currentLevel = widget.level;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Only jump if question is not showing
          // This prevents accidental jumps while answering
          if (!game.questionShowing) {
            game.onPlayerJump();
          }
        },
        child: GameWidget(
          game: game,
          overlayBuilderMap: {
            'QuestionOverlay': (context, game) => QuestionOverlayWidget(
              game: game as ChronoGame,
              onAnswer: (game as ChronoGame).handleAnswer,
            ),
            'HudOverlay': (context, game) => HudOverlayWidget(
              game: game as ChronoGame,
            ),
            'BossHealthOverlay': (context, game) => BossHealthOverlayWidget(
              game: game as ChronoGame,
            ),
          },
          initialActiveOverlays: const ['HudOverlay'],
        ),
      ),
    );
  }
}
```

---

### ENEMY COMPONENT: enemy_component.dart

```dart
class EnemyComponent extends SpriteAnimationComponent
    with HasGameRef<ChronoGame>, CollisionCallbacks {

  final Question question;
  final String eraId;
  static const double moveSpeed = 90.0;
  bool defeated = false;

  EnemyComponent({required this.question, required this.eraId});

  @override
  Future<void> onLoad() async {
    // Each era has 2 enemy types — randomly pick one
    final enemyType = _getEnemyTypeForEra(eraId);
    animation = SpriteAnimation.spriteList(
      [
        await gameRef.loadSprite('enemies/${enemyType}_1.png'),
        await gameRef.loadSprite('enemies/${enemyType}_2.png'),
      ],
      stepTime: 0.3,
    );
    size = Vector2(60, 72);
    position = Vector2(gameRef.size.x + 60, ChronoGame.groundY - 72);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!defeated) {
      position.x -= moveSpeed * dt;
      if (position.x < -size.x) removeFromParent();
    }
  }

  void defeat() {
    defeated = true;
    removeFromParent();
    gameRef.audioService.playEnemyDefeat();
  }

  String _getEnemyTypeForEra(String era) {
    final enemies = {
      'pre-colonial': ['tribal_warrior', 'dark_spirit'],
      'spanish':      ['spanish_soldier', 'tax_collector'],
      'american':     ['american_soldier', 'propaganda'],
      'ww2':          ['japanese_soldier', 'tank'],
      'modern':       ['corruption_figure', 'misinfo_cloud'],
    };
    final list = enemies[era] ?? ['spanish_soldier'];
    return list[Random().nextInt(list.length)];
  }
}
```

---

### ENEMY SPAWNER: enemy_spawner.dart

```dart
class EnemySpawner {
  final ChronoGame game;
  final List<Question> questions;
  double distanceTraveled = 0.0;
  double spawnInterval = 500.0;
  int nextIndex = 0;
  bool allEnemiesSpawned = false;

  EnemySpawner({required this.game, required this.questions});

  void update(double dt) {
    distanceTraveled += 150.0 * dt; // world scroll speed
    if (distanceTraveled >= spawnInterval && nextIndex < questions.length) {
      _spawnEnemy();
      distanceTraveled = 0;
    }
    if (nextIndex >= questions.length) {
      allEnemiesSpawned = true;
    }
  }

  void _spawnEnemy() {
    final enemy = EnemyComponent(
      question: questions[nextIndex],
      eraId: game.currentEra,
    );
    game.add(enemy);
    nextIndex++;
  }
}
```

---

### BOSS COMPONENT: boss_component.dart

```dart
class BossComponent extends SpriteComponent with HasGameRef<ChronoGame> {
  final String eraId;
  int health = 5;
  bool reachedCenter = false;
  static const double walkSpeed = 50.0;

  late Sprite idleSprite;
  late Sprite attackSprite;
  late Sprite defeatedSprite;

  BossComponent({required this.eraId});

  @override
  Future<void> onLoad() async {
    final bossName = _getBossNameForEra(eraId);
    idleSprite     = await gameRef.loadSprite('bosses/${bossName}_idle.png');
    attackSprite   = await gameRef.loadSprite('bosses/${bossName}_attack.png');
    defeatedSprite = await gameRef.loadSprite('bosses/${bossName}_defeated.png');

    sprite = idleSprite;
    size = Vector2(120, 140);
    position = Vector2(gameRef.size.x + 20, ChronoGame.groundY - 140);
    gameRef.audioService.playBossAppear();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!reachedCenter) {
      position.x -= walkSpeed * dt;
      final centerX = gameRef.size.x / 2 - size.x / 2;
      if (position.x <= centerX) {
        position.x = centerX;
        reachedCenter = true;
        _showBossQuestion();
      }
    }
  }

  void takeDamage() {
    health--;
    sprite = attackSprite;
    Future.delayed(const Duration(milliseconds: 400), () => sprite = idleSprite);
    if (health <= 0) defeat();
  }

  void defeat() {
    sprite = defeatedSprite;
    gameRef.audioService.playBossDefeat();
    gameRef.overlays.remove('BossHealthOverlay');
    Future.delayed(const Duration(seconds: 1), () {
      removeFromParent();
      gameRef.levelComplete();
    });
  }

  void _showBossQuestion() {
    final q = gameRef.spawner.questions[gameRef.answers.length % gameRef.spawner.questions.length];
    gameRef.showQuestion(q, EnemyComponent(question: q, eraId: eraId));
  }

  String _getBossNameForEra(String era) {
    const names = {
      'pre-colonial': 'bakunawa',
      'spanish':      'governor',
      'american':     'general',
      'ww2':          'commander',
      'modern':       'corruption_boss',
    };
    return names[era] ?? 'governor';
  }
}
```

---

### GROUND COMPONENT: ground_component.dart

```dart
class GroundComponent extends PositionComponent with HasGameRef<ChronoGame> {
  @override
  Future<void> onLoad() async {
    size = Vector2(gameRef.size.x, 60);
    position = Vector2(0, ChronoGame.groundY);
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    // Draw era-colored ground rectangle
    final paint = Paint()..color = _groundColorForEra(gameRef.currentEra);
    canvas.drawRect(size.toRect(), paint);
  }

  Color _groundColorForEra(String era) {
    const colors = {
      'pre-colonial': Color(0xFF5D4E37),
      'spanish':      Color(0xFF808080),
      'american':     Color(0xFF8B6914),
      'ww2':          Color(0xFF4A4A3A),
      'modern':       Color(0xFF555555),
    };
    return colors[era] ?? const Color(0xFF5D4E37);
  }
}
```

---

### GAP COMPONENT: gap_component.dart

```dart
// A gap is simply the absence of ground — a break in the ground component.
// Implemented as a ground section that stops, then resumes.
// The world scrolls, so gaps appear as the ground segments scroll left.

class GroundSection extends PositionComponent with HasGameRef<ChronoGame> {
  final double width;
  final Color color;

  GroundSection({required this.width, required this.color});

  @override
  Future<void> onLoad() async {
    size = Vector2(width, 60);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    position.x -= 150 * dt; // scroll with world speed
    if (position.x < -width) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color;
    canvas.drawRect(size.toRect(), paint);
  }
}

// Spawned by EnemySpawner between enemies:
// 3 GroundSections + 1 gap (no ground section) at random intervals
```

---

### WALL COMPONENT: wall_component.dart

```dart
// Visible low wall — student must jump over it
class WallComponent extends SpriteComponent with HasGameRef<ChronoGame> {
  @override
  Future<void> onLoad() async {
    // Use era-appropriate wall image (stone, bamboo, sandbag, etc.)
    sprite = await gameRef.loadSprite('obstacles/${gameRef.currentEra}_wall.png');
    size = Vector2(40, 50);
    position = Vector2(gameRef.size.x + 20, ChronoGame.groundY - 50);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    position.x -= 150 * dt;
    if (position.x < -size.x) removeFromParent();
  }
}
// Wall does NOT trigger auto-jump.
// Player must tap screen to jump over it manually.
// If player does not jump, player lands on top of wall (treat wall top as ground)
// OR wall pushes player back (add collision response)
// SIMPLEST: make wall's hitbox only block from the left — player slides up onto wall top
```

---

### COIN COMPONENT: coin_component.dart

```dart
class CoinComponent extends SpriteComponent
    with HasGameRef<ChronoGame>, CollisionCallbacks {

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('collectibles/coin.png');
    size = Vector2(32, 32);
    // Spawn at random height: ground level or slightly above
    position = Vector2(
      gameRef.size.x + 20,
      ChronoGame.groundY - 32 - (Random().nextDouble() * 80),
    );
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    position.x -= 150 * dt;
    if (position.x < -size.x) removeFromParent();
  }
}
// Auto-collects on overlap with player
// Adds to game.playerCoins (synced to backend Student.coins after level)
// NOT added to score — coins are for character unlocking only
```

---

### QUESTION OVERLAY: question_overlay.dart

```dart
// Regular Flutter widget displayed over Flame canvas
// Do NOT use Flame for this — pure Flutter StatefulWidget

class QuestionOverlayWidget extends StatefulWidget {
  final ChronoGame game;
  final Function(String answer) onAnswer;
  const QuestionOverlayWidget({required this.game, required this.onAnswer});

  @override
  State<QuestionOverlayWidget> createState() => _QuestionOverlayWidgetState();
}

class _QuestionOverlayWidgetState extends State<QuestionOverlayWidget> {
  bool answered = false;
  String? selectedAnswer;
  int secondsElapsed = 0;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    widget.game.currentQuestion?.elapsedSeconds = 0;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      widget.game.currentQuestion?.elapsedSeconds++;
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void handleTap(String answer) {
    if (answered) return;
    setState(() {
      answered = true;
      selectedAnswer = answer;
    });
    // Show green/red flash for 800ms then call onAnswer
    Future.delayed(const Duration(milliseconds: 800), () {
      widget.onAnswer(answer);
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.game.currentQuestion!;
    return GestureDetector(
      // Block tap-to-jump while question is showing
      onTap: () {},
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 20)],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Text('HAMON NG KAAWAY',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                    letterSpacing: 1.2,
                  )),
                const SizedBox(height: 12),

                // Question text
                Text(question.questionText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  )),
                const SizedBox(height: 20),

                // Answer buttons — 2x2 grid
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.5,
                  children: question.options.map((option) {
                    Color buttonColor = AppColors.surface;
                    if (answered) {
                      if (option.label == question.correctAnswer) {
                        buttonColor = AppColors.success.withOpacity(0.2);
                      } else if (option.label == selectedAnswer) {
                        buttonColor = AppColors.danger.withOpacity(0.2);
                      }
                    }
                    return GestureDetector(
                      onTap: () => handleTap(option.label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: buttonColor,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${option.label}) ${option.text}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Powerup row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PowerupButton(
                      icon: 'powerups/fifty_fifty.png',
                      count: widget.game.playerPowerUps.fiftyFifty,
                      onTap: () => widget.game.useFiftyFifty(),
                    ),
                    const SizedBox(width: 12),
                    _PowerupButton(
                      icon: 'powerups/time_freeze.png',
                      count: widget.game.playerPowerUps.timeFreeze,
                      onTap: () => widget.game.useTimeFreeze(),
                    ),
                    const SizedBox(width: 12),
                    _PowerupButton(
                      icon: 'powerups/shield.png',
                      count: widget.game.playerPowerUps.shield,
                      onTap: () => widget.game.useShield(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

### HUD OVERLAY: hud_overlay.dart

```dart
class HudOverlayWidget extends StatelessWidget {
  final ChronoGame game;
  const HudOverlayWidget({required this.game});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        color: Colors.black54,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Lives
            Row(children: List.generate(3, (i) =>
              Icon(i < game.lives ? Icons.favorite : Icons.favorite_border,
                color: AppColors.danger, size: 24))),
            const Spacer(),
            // Level
            Text('Level ${game.currentLevel}',
              style: const TextStyle(color: Colors.white, fontSize: 14,
                fontWeight: FontWeight.bold)),
            const Spacer(),
            // Score
            Text('${game.score} pts',
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
```

---

### ALL NON-FLAME SCREENS

Build all of these as regular Flutter screens with no Flame.

---

#### LoginScreen
- Background: `assets/backgrounds/login_bg.png`
- ChronoQuest logo text (PlayfairDisplay, gold)
- Subtitle: "Tuklasin ang Kasaysayan ng Pilipinas"
- Email field + Password field (show/hide toggle)
- "Mag-login" button (full width, primary color)
- Loading indicator on button while authenticating
- Error message below button on failure
- POST /api/v1/student/login → save JWT to flutter_secure_storage key 'student_token'
- On success: navigate to /character-selection

---

#### CharacterSelectionScreen
- Background: `assets/backgrounds/character_select_bg.png`
- Title: "Piliin ang Iyong Bayani"
- Center: PageView with 5 character cards
  - Selected: gold border, scale 1.05
  - Unselected: faded, scale 0.95
  - Each card: character image, name, era, short description
- LEFT SIDE (Positioned, left: 16):
  - Mechanics card (brown, scroll icon) → taps open BottomSheet with how-to-play
  - Leaderboard card (brown, trophy icon) → navigate to /leaderboard
- BOTTOM RIGHT: "SIMULA!" button
  - Disabled (grey) until character selected
  - On tap: save character to Hive, navigate to /era-selection

Characters:
```dart
[ lapu: Datu Lapu-Lapu / Sinaunang Panahon / Bayani ng Mactan,
  rizal: Jose Rizal / Panahon ng Kastila / Pambansang Bayani,
  mabini: Apolinario Mabini / Panahon ng Amerikano / Utak ng Rebolusyon,
  escoda: Josefa Llanes Escoda / Ikalawang Digmaang Pandaigdig / Bayaning Kababaihan,
  aquino: Corazon Aquino / Makabagong Panahon / Ina ng Demokrasya ]
```

Mechanics BottomSheet content:
- Tap screen to jump over obstacles
- Defeat enemies by answering questions correctly
- Wrong answers lose hearts — falling in gaps does NOT
- Use powerups to help with hard questions
- Complete all 10 levels to finish an era

---

#### EraSelectionScreen
- Background: bookshelf illustration
- Title: "Piliin ang Panahon"
- Only show eras matching the student grade level (DepEd MELC verified):
  - Grade 4 → Pre-colonial only (1 book)
  - Grade 5 → Pre-colonial, Spanish, American (3 books)
  - Grade 6 → American, WW2, Modern (3 books)
  - Eras outside the student grade are HIDDEN entirely, not locked
- Hardcode this map in constants.dart:
  ERA_GRADE_MAP = { pre-colonial: [grade4, grade5], spanish: [grade5], american: [grade5, grade6], ww2: [grade6], modern: [grade6] }
- Filter: visibleEras = ALL_ERAS.where((e) => ERA_GRADE_MAP[e.id].contains(student.gradeLevel))
- Each visible book: Available (glowing) / In progress (shows 6/10) / Completed (gold checkmark)
- Student stats bar at bottom: avatar, name, total points
- GET /api/v1/student/era-progress to get completion state
- Within visible eras: Era N unlocks when Era N-1 complete (all 10 levels)
- First visible era always available
- Tap available era → navigate to /pre-test/:eraId

---

#### PreTestScreen
- Background: plain AppColors.background (NO game art, NO era artwork)
- Top: small era name text in AppColors.textMuted
- Center white card:
  - Before start: "Bago tayo magsimula..." explanation + "Magsimula" button
  - During test: question N of 10, progress bar, question text, 4 answer buttons
  - Tap answer → immediately next question (NO correct/wrong feedback shown)
  - NO timer, NO powerups, NO lives, NO character
  - After Q10: "Magaling! Basahin natin ang kasaysayan." → auto-navigate after 1.5s
- Submit silently: POST /api/v1/student/results { type: 'cold_pre_test', level: 1 }
- Do NOT show score to student anywhere on this screen
- Questions: GET /api/v1/questions/by-era/:era?level=1&limit=10

---

#### BackgroundHistoryScreen
- Background: full-screen era background with dark overlay (opacity 0.45)
- Scrollable content:
  - Era title (PlayfairDisplay, large, white/gold)
  - Historical period dates
  - 150–200 word historical text in Filipino (hardcoded per era — see below)
  - Key term chips → tap opens AlertDialog with simple definition
  - 2 historical images with captions
- ScrollController detects when bottom reached
- "Handa na ako!" button only visible after scrolling to bottom
- Character image in bottom-left corner

Historical text (hardcode in constants.dart):
```
pre-colonial: "Bago dumating ang mga mananakop, ang mga Pilipino ay nabuhay sa mga 
barangay — maliliit na komunidad na pinamumunuan ng isang datu. Ang bawat barangay 
ay may sariling kaugalian, tradisyon, at sistema ng pamahalaan. Ang mga sinaunang 
Pilipino ay mahusay na mangangalakal — nakipagpalakasan sila sa China, India, at 
iba pang bansa sa Asya. Gumamit sila ng baybayin, isang sistema ng pagsulat na 
orihinal na Filipino. Ang Labanan sa Mactan noong 1521 ay nagpakita ng lakas ng 
loob ng mga Pilipino nang ipagtanggol ni Datu Lapu-Lapu ang kanyang lupain."

spanish: "Noong 1565, nagsimula ang pananakop ng Espanya sa Pilipinas sa ilalim 
ni Miguel Lopez de Legazpi. Itinayo nila ang Intramuros sa Maynila bilang sentro 
ng kanilang kapangyarihan. Sa loob ng mahigit tatlong daang taon, kinontrol ng 
Espanya ang relihiyon, kalakalan, at pamahalaan ng bansa. Ang sistemang encomienda 
ay nagbigay ng lupain sa mga Espanyol. Naglunsad ng mga rebolusyon ang mga Pilipino 
laban sa pananakop — mula sa Dagohoy Rebellion hanggang sa Himagsikan ng 1896 
na pinamunuan ni Andres Bonifacio at ang Katipunan."

american: "Noong 1898, pagkatapos ng Digmaang Espanyol-Amerikano, inilipat ang 
Pilipinas sa Estados Unidos. Itinatag ng mga Amerikano ang sistema ng edukasyong 
pampubliko at nagpadala ng mga Thomasites — mga guro mula Amerika. Nagtagal ang 
pananakop ng Amerika at naglunsad ng Philippine-American War na nagkahalaga ng 
maraming buhay ng Pilipino. Noong 1935, naitatag ang Commonwealth ng Pilipinas na 
may Manuel Quezon bilang unang Pangulo, at noong Hulyo 4, 1946, opisyal na nakamit 
ng Pilipinas ang kalayaan."

ww2: "Noong Disyembre 8, 1941, sinalakay ng Hapon ang Pilipinas. Naganap ang 
malupit na Bataan Death March noong Abril 1942. Sa ilalim ng pananakop ng Hapon, 
naghirap ang mga Pilipino. Nabuo ang mga gerilya na lumaban sa Hapon — kabilang 
ang Hukbalahap. Noong Oktubre 1944, bumalik si General Douglas MacArthur at 
nagsimula ang Labanan para sa Pilipinas. Ang Labanan ng Maynila noong 1945 ay 
isa sa pinaka-mapanirang labanan sa lungsod sa buong Ikalawang Digmaang Pandaigdig."

modern: "Noong Hulyo 4, 1946, opisyal na naging malaya ang Pilipinas. Sa mga 
sumunod na dekada, hinarap ng bansa ang maraming pagsubok — mula sa Marcos 
diktadura (1972–1986) hanggang sa People Power Revolution na nagluklok kay Corazon 
Aquino bilang Pangulo noong 1986. Ang EDSA Revolution ay naging simbolo ng 
kapangyarihan ng mamamayan sa buong mundo. Patuloy na lumalago ang Pilipinas 
bilang isang demokratikong bansa na nagtataguyod ng kalayaan, katarungan, at 
pagkakapantay-pantay para sa lahat ng Pilipino."
```

---

#### LevelSelectScreen
- Background: era background (lighter, less dark overlay)
- Road/path illustration stretching across screen
- 10 circular milestone markers placed along the road
  - Locked: grey circle, lock icon, level number
  - Unlocked: gold outline circle, level number, tappable
  - Completed: filled gold circle, checkmark, stars earned (1–3)
  - Level 10: star shape, "BOSS" label, locked until L1–9 done
- Fetch completion state from Hive local cache (synced from era-progress)
- Tap unlocked level → navigate to /game/:eraId/:level

---

#### LevelCompleteScreen
- Background: era background with gold overlay
- Animated stars appearing one by one (1–3 based on score: <70%=1, 70–89%=2, 90%+=3)
- Score: "7/10 Tama" text
- Points: "+70 puntos" with floating animation
- Powerup earned: show icon if milestone reached
- "Susunod" button → back to level select, next level unlocked

---

#### LevelFailedScreen
- Background: era background with dark red tint overlay
- "Subukan muli!" heading
- Hearts: show remaining (usually 0)
- Hint: show correct answer for the question that caused final failure
- Two buttons:
  - "Ulit" (retry from Q1, lives reset to 3)
  - "Bumalik sa Level Select" (return without retrying)

---

#### EraCompleteScreen
- Base: era background
- Lottie fireworks: `assets/animations/fireworks.json` plays automatically
- "ERA TAPOS NA!" heading (PlayfairDisplay, large, gold)
- Three-row comparison card (white, rounded):
  ```
  Bago Basahin:              42%  ██████░░░░░░
  Habang Naglalaro (L1–9):   63%  ████████░░░░
  Panghuling Pagsubok (L10): 81%  ██████████░░
  ```
- Learning gain: "+39% Natuto Ka!" in large gold text
  - ≥20%: trophy icon, success color
  - 10–19%: thumbs up, green
  - <10%: encouraging message, normal
  - First time student sees cold pre-test score
- Badges earned this era (simple icon + name)
- Total points earned
- "Susunod na Panahon →" button → era selection, next era unlocked
- If all 5 eras complete: "NATAPOS MO ANG LAHAT!" special screen with extra fireworks

---

#### ProfileScreen
- Student name, class code, school name
- Selected character image (large, centered)
- Stats row: total points | eras completed | total levels done
- Per-era accordion rows:
  - Era name + status (not started / in progress / complete)
  - Cold pre-test score (shown if taken)
  - Level progress: "6 / 10 levels"
  - Post-test score (shown if Level 10 done)
  - Learning gain (shown if both available)
- Powerup inventory: 50/50 × N, Time Freeze × N, Shield × N
- "I-logout" button (bottom, danger color)

---

#### LeaderboardScreen
- Two tabs: "Aking Klase" / "Aming Paaralan"
- Top 3 podium: 2nd | 1st | 3rd (character avatars, names, scores)
- Scrollable list: ranks 4–20 (rank number, avatar, name, points)
- Current student row highlighted in gold
- Refresh button top right
- GET /api/v1/student/leaderboard?scope=class and ?scope=school

---

### ROUTING

```dart
final router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final isLoggedIn = StorageService.hasToken();
    if (!isLoggedIn && state.matchedLocation != '/login') return '/login';
    return null;
  },
  routes: [
    GoRoute(path: '/login',              builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/character-selection', builder: (_, __) => const CharacterSelectionScreen()),
    GoRoute(path: '/era-selection',      builder: (_, __) => const EraSelectionScreen()),
    GoRoute(path: '/pre-test/:eraId',    builder: (_, s) => PreTestScreen(eraId: s.pathParameters['eraId']!)),
    GoRoute(path: '/background/:eraId',  builder: (_, s) => BackgroundHistoryScreen(eraId: s.pathParameters['eraId']!)),
    GoRoute(path: '/level-select/:eraId', builder: (_, s) => LevelSelectScreen(eraId: s.pathParameters['eraId']!)),
    GoRoute(path: '/game/:eraId/:level', builder: (_, s) => GameScreen(
      eraId: s.pathParameters['eraId']!,
      level: int.parse(s.pathParameters['level']!),
    )),
    GoRoute(path: '/level-complete/:eraId/:level', builder: (_, s) => LevelCompleteScreen(
      eraId: s.pathParameters['eraId']!,
      level: int.parse(s.pathParameters['level']!),
    )),
    GoRoute(path: '/level-failed/:eraId/:level', builder: (_, s) => LevelFailedScreen(
      eraId: s.pathParameters['eraId']!,
      level: int.parse(s.pathParameters['level']!),
    )),
    GoRoute(path: '/era-complete/:eraId', builder: (_, s) => EraCompleteScreen(eraId: s.pathParameters['eraId']!)),
    GoRoute(path: '/leaderboard',        builder: (_, __) => const LeaderboardScreen()),
    GoRoute(path: '/profile',            builder: (_, __) => const ProfileScreen()),
  ],
);
```

---

### ASSETS STRUCTURE

```
assets/
├── backgrounds/
│   ├── login_bg.png
│   ├── character_select_bg.png
│   ├── bookshelf_bg.png
│   ├── precolonial_far.png, precolonial_near.png
│   ├── spanish_far.png, spanish_near.png
│   ├── american_far.png, american_near.png
│   ├── ww2_far.png, ww2_near.png
│   └── modern_far.png, modern_near.png
├── characters/
│   ├── lapu_walk_1.png ... lapu_walk_4.png, lapu_jump.png, lapu_hurt.png
│   ├── rizal_walk_1.png ... rizal_walk_4.png, rizal_jump.png, rizal_hurt.png
│   ├── mabini_walk_1.png ... mabini_walk_4.png, mabini_jump.png, mabini_hurt.png
│   ├── escoda_walk_1.png ... escoda_walk_4.png, escoda_jump.png, escoda_hurt.png
│   └── aquino_walk_1.png ... aquino_walk_4.png, aquino_jump.png, aquino_hurt.png
├── enemies/
│   ├── tribal_warrior_1.png, tribal_warrior_2.png
│   ├── dark_spirit_1.png, dark_spirit_2.png
│   ├── spanish_soldier_1.png, spanish_soldier_2.png
│   ├── tax_collector_1.png, tax_collector_2.png
│   ├── american_soldier_1.png, american_soldier_2.png
│   ├── propaganda_1.png, propaganda_2.png
│   ├── japanese_soldier_1.png, japanese_soldier_2.png
│   ├── tank_1.png, tank_2.png
│   ├── corruption_figure_1.png, corruption_figure_2.png
│   └── misinfo_cloud_1.png, misinfo_cloud_2.png
├── bosses/
│   ├── bakunawa_idle.png, bakunawa_attack.png, bakunawa_defeated.png
│   ├── governor_idle.png, governor_attack.png, governor_defeated.png
│   ├── general_idle.png, general_attack.png, general_defeated.png
│   ├── commander_idle.png, commander_attack.png, commander_defeated.png
│   └── corruption_boss_idle.png, corruption_boss_attack.png, corruption_boss_defeated.png
├── obstacles/
│   ├── precolonial_wall.png
│   ├── spanish_wall.png
│   ├── american_wall.png
│   ├── ww2_wall.png
│   └── modern_wall.png
├── collectibles/
│   └── coin.png, artifact_1.png ... artifact_5.png
├── powerups/
│   ├── fifty_fifty.png
│   ├── time_freeze.png
│   └── shield.png
├── ui/
│   ├── heart_full.png, heart_empty.png
│   ├── star_full.png, star_empty.png
│   └── lock_icon.png
├── sounds/
│   ├── correct.mp3, wrong.mp3
│   ├── jump.mp3
│   ├── enemy_defeat.mp3, player_hurt.mp3
│   ├── coin.mp3, powerup.mp3
│   ├── level_complete.mp3, level_failed.mp3
│   ├── boss_appear.mp3, boss_defeat.mp3
│   ├── era_complete.mp3
│   ├── footsteps.mp3
│   └── bgm_precolonial.mp3, bgm_spanish.mp3, bgm_american.mp3, bgm_ww2.mp3, bgm_modern.mp3
└── animations/
    └── fireworks.json
```

All images: use colored rectangles as placeholders. Replace with real art before defense.

---

### ERROR HANDLING

- Network error → Snackbar "Walang internet connection" + retry button
- 401 → clear token, redirect to /login
- Empty questions from API → show dialog "Walang tanong na makita", return to level select
- Missing asset file → catch error in onLoad(), use placeholder colored rectangle
- All API calls wrapped in try-catch

---

### OFFLINE SUPPORT

Cache questions in Hive after first fetch:
```dart
// Before API call:
final cached = hiveBox.get('questions_${era}_$level');
if (cached != null) return (cached as List).cast<Question>();

// After successful API call:
hiveBox.put('questions_${era}_$level', questions);
```

Cache era progress locally, sync on app resume.

---

### BUILD ORDER — PRODUCE ALL 32 FILES IN THIS EXACT ORDER

1. pubspec.yaml
2. lib/core/constants.dart (AppColors, AppFonts, ApiConstants, era data map)
3. lib/core/theme.dart
4. lib/core/dio_client.dart (Dio instance with JWT interceptor, 401 redirect)
5. lib/core/router.dart
6. lib/models/student.dart
7. lib/models/question.dart (includes elapsedSeconds field for timing)
8. lib/models/quiz_result.dart
9. lib/models/era_progress.dart
10. lib/services/storage_service.dart (flutter_secure_storage wrapper)
11. lib/services/audio_service.dart (all sound methods)
12. lib/services/api_service.dart (all API calls)
13. lib/providers/auth_provider.dart
14. lib/providers/game_provider.dart
15. lib/providers/progress_provider.dart
16. lib/main.dart
17. lib/app.dart
18. lib/game/components/ground_component.dart
19. lib/game/components/gap_component.dart
20. lib/game/components/wall_component.dart
21. lib/game/components/coin_component.dart
22. lib/game/components/player_component.dart
23. lib/game/components/enemy_component.dart
24. lib/game/components/enemy_spawner.dart
25. lib/game/components/boss_component.dart
26. lib/game/overlays/hud_overlay.dart
27. lib/game/overlays/question_overlay.dart
28. lib/game/overlays/pause_overlay.dart
29. lib/game/chrono_game.dart
30. lib/screens/auth/login_screen.dart
31. lib/screens/home/character_selection_screen.dart
32. lib/screens/home/era_selection_screen.dart
33. lib/screens/game/pre_test_screen.dart
34. lib/screens/game/background_history_screen.dart
35. lib/screens/game/level_select_screen.dart
36. lib/screens/game/game_screen.dart (GestureDetector wrapping GameWidget)
37. lib/screens/game/level_complete_screen.dart
38. lib/screens/game/level_failed_screen.dart
39. lib/screens/game/era_complete_screen.dart
40. lib/screens/profile/profile_screen.dart
41. lib/screens/profile/leaderboard_screen.dart

Produce each file completely. No TODO comments. No placeholder functions. Every file fully working.

---

### AFTER ALL FILES

Produce:
1. Final complete pubspec.yaml with all assets declared under flutter: assets:
2. These exact terminal commands to run:
   ```bash
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/v1
   ```
3. Checklist of what to verify on first run:
   - flutter pub get succeeds with no errors
   - Blank Flame canvas appears when navigating to /game/spanish/1
   - Character walk animation plays
   - Background scrolls left continuously
   - Tapping screen makes character jump
   - Enemy walks in from right
   - Touching enemy pauses game and shows question card
   - Answering correctly removes enemy and resumes game
   - Answering wrong decreases heart count
   - Falling into gap respawns player without losing heart

---

## END OF PASTE BLOCK

---

## Notes

Paste ChronoQuest_Project_Context.md first, then this entire prompt.

When AI stops mid-file: say **"continue"**
When AI skips a file: say **"Build [filename] completely before moving on"**
When code does not compile: paste the error and say **"Fix this error in [filename]"**

Test milestone checkpoints:
- After file 17: `flutter pub get` succeeds
- After file 29: blank Flame canvas loads, character runs, tap to jump works
- After file 27: enemy appears and question overlay shows on contact
- After file 41: full game loop works end to end
