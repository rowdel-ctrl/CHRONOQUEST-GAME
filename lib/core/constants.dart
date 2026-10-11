import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import '../models/level.dart';
import 'combat_constants.dart';

// ─── COLORS ─────────────────────────────────────────────────────────────────
// Retro pixel-adventure palette. Field names are unchanged from the old
// Material palette on purpose — every existing AppColors.xxx reference
// across the app picks up the new look automatically, no call sites needed
// touching just for color.
class AppColors {
  static const Color primary = Color(0xFF6B3A1F); // wood-brown UI chrome
  static const Color primaryDark = Color(0xFF2E1608); // thick pixel borders
  static const Color primaryLight = Color(0xFFB8763E);
  static const Color accent = Color(0xFFFFC531); // quest gold
  static const Color background = Color(0xFF140E1F); // night-map backdrop
  static const Color surface = Color(0xFFF5E3BE); // parchment panels
  static const Color surfaceAlt = Color(0xFFE8CE9C); // deeper parchment
  static const Color border = Color(0xFF2E1608); // pixel outline color
  static const Color textPrimary = Color(0xFF2A1707); // ink on parchment
  static const Color textSecondary = Color(0xFF6B4423);
  static const Color textMuted = Color(0xFFA9855C);
  static const Color success = Color(0xFF43A83E);
  static const Color danger = Color(0xFFE8433A);
  static const Color warning = Color(0xFFF5A623);
  static const Color info = Color(0xFF3D8FD1);
}

// ─── FONTS ──────────────────────────────────────────────────────────────────
// Press Start 2P: chunky pixel-game display face — titles, buttons, HUD
// numbers, short labels only (wide letterforms, hard to read in long
// lines). Pixelify Sans: a pixel-styled but far more readable face for
// anything a grade 4-5 student needs to actually read — quiz questions,
// explanations, paragraphs.
class AppFonts {
  static const String display = 'Poppins';
  static const String body = 'Poppins';
}

// ─── API ────────────────────────────────────────────────────────────────────
class ApiConstants {
  static const String _baseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;

    return 'https://chronoquest-backend.vercel.app/api/v1';
  }
}

// ─── DEV FLAGS ──────────────────────────────────────────────────────────────
class DevFlags {
  /// Lets you run the game without logging in:
  ///   flutter run --dart-define=DEV_SKIP_AUTH=true
  /// The router skips its login redirect and opens on character selection, and
  /// quiz results are neither sent nor queued (a queued result would later be
  /// flushed to whichever real account logs in next). `!kReleaseMode` makes it
  /// impossible for a release build to enable this.
  static const bool skipAuth =
      !kReleaseMode && bool.fromEnvironment('DEV_SKIP_AUTH');

  /// Where the app opens when [skipAuth] is on, e.g.
  /// `--dart-define=DEV_START_ROUTE=/game/pre-colonial/1` to land straight in
  /// a level. Defaults to character selection, the normal post-login screen.
  static const String startRoute = String.fromEnvironment(
    'DEV_START_ROUTE',
    defaultValue: '/character-selection',
  );
}

// ─── GAME CONSTANTS ─────────────────────────────────────────────────────────
class GameConstants {
  /// The virtual height the whole game is designed at. `StretchToFillViewport`
  /// scales this to fit whatever the device actually is, so every sprite
  /// stays the same fraction of the screen everywhere.
  ///
  /// Before this, the world used raw device pixels: the 80px player was ~11%
  /// of a 1280x720 window but ~22% of a landscape phone (~360-412 logical px
  /// tall), which is why the game looked roughly twice the size on a phone.
  /// 720 is used because every size in the game — sprite sizes, the ~128px
  /// jump peak, platform spawn heights — was tuned by eye at a 1280x720
  /// reference resolution, so keeping the height means none of them have to
  /// be retuned. There is no matching `virtualWidth`: width is computed live
  /// from each device's own aspect ratio (`StretchToFillViewport`) rather
  /// than fixed, so the world-to-screen scale is always uniform — no
  /// stretch on either axis, unlike a fixed 1280x720 forced onto a
  /// non-16:9 screen.
  static const double virtualHeight = 720.0;

  static const double groundY = 520.0;

  /// Fixed virtual x the player renders at (see ChronoGame.cameraLeftEdgeX)
  /// — how far into the screen from the left edge the character sits.
  ///
  /// Raised from 80: at that value the player's sprite (x 80-176) sat
  /// almost entirely under the joystick's footprint no matter how the
  /// joystick was sized or placed — a comfortable, thumb-reachable
  /// joystick radius/margin combination always reaches past x=80. 220
  /// gives ~55 units of clear space between the two instead. Forward view
  /// shrinks by the same 140 units this adds (cameraLeftEdgeX moves right
  /// by exactly this much) — about 12% less world visible ahead of the
  /// player, still well clear of GameConstants.spawnInterval (1400), so
  /// nothing spawns already-visible.
  static const double playerX = 220.0;
  static const double gravity = 900.0;
  static const double jumpForce = -480.0;
  /// How far the player must travel before another enemy spawns ahead.
  ///
  /// Raised from 800 in Phase 2. That figure was set while every enemy
  /// carried a quiz question and *was* the level's content, so meeting one
  /// often was the point. Enemies are pure hazards now (contact costs a
  /// heart, GAMEPLAY-V2.md Section 5), and at the old spacing they arrived
  /// relentlessly enough to drain the shared pool in seconds. This is a
  /// per-encounter pacing number, not a content-delivery one — a level now
  /// holds *more* enemies overall (it is far longer, see
  /// CombatConstants.lengthUnitsDefault) while meeting them less often.
  static const double spawnInterval = 1400.0;

  /// Cap on the single shared hearts pool (see HeartsState) — one pool for
  /// everything, per GAMEPLAY-V2.md section 8 (revision 7 reverses the
  /// earlier in-level-HP/persistent-Energy split). It gates *starting or
  /// retrying* a level (`GameNotifier.canStartLevel`) and is also what every
  /// in-level damage event (enemy contact, hazard hit, falling) spends from
  /// directly — there is no separate level-local counter that resets on
  /// retry. It regenerates over real time via [heartRegenInterval], even
  /// while the app is closed.
  static const int maxHearts = 5;
  static const Duration heartRegenInterval = Duration(minutes: 1);

  /// Coins to buy one heart. A placeholder chosen by the user on 2026-10-03
  /// ("for now we use 20 coins"), now spent through [GameNotifier.buyHeart].
  static const int heartPriceCoins = 20;

  /// Coins for one of each power-up, bought on the Profile screen. Placeholders
  /// to tune once students have played with coins: a level pays roughly 30 to 60.
  static const int fiftyFiftyPriceCoins = 15;
  static const int shieldPriceCoins = 25;
  static const int timeFreezePriceCoins = 30;

  static const int questionsPerLevel = 10; // levels 1-9
  // The size of a boss level's question pool (own lesson + reused ones).
  static const int bossWarmupQuestions = 10;
  static const int bossFightQuestions = 12;

  // The boss fight (GAMEPLAY-V2.md Section 7, the simple version): six right
  // answers beat the boss, each question has a countdown, and a few minions
  // come between questions.
  static const int bossQuestionsToWin = 6;
  static const int bossHealth = bossQuestionsToWin;
  static const double bossAnswerSeconds = 15;

  /// If the minions of a wave are not all beaten after this long, the next
  /// question comes anyway, so a stuck minion can never trap the student.
  static const double bossWaveTimeoutSeconds = 40;

  /// Widest width:height ratio the game canvas is allowed to render at
  /// before GameScreen pillarboxes it. Backgrounds use Flame's
  /// `LayerFill.height` + `repeatX` (see parallax_background.dart), which
  /// scales each era's art to the canvas height and tiles it horizontally —
  /// the active background art is 2048x768 (an 8:3 ≈ 2.667 tile), so a
  /// second tile becomes visible within a single frame once the canvas
  /// itself is wider than that ratio. 2.5 stays safely under 8:3 (covering
  /// rounding at the boundary) while remaining well above every normal
  /// phone/tablet/desktop landscape ratio, so pillarboxing only kicks in on
  /// unusually wide windows.
  static const double maxAspectRatio = 2.5;
}

// ─── POINTS ─────────────────────────────────────────────────────────────────
class PointValues {
  static const int correctAnswer = 10;
  static const int speedBonus = 5;
  static const int coinCollected = 5;
  static const int artifactCollected = 15;
  static const int perfectLevel = 50;
  static const int completeEra = 100;
  static const int learningGainBonus = 75;
}

// ─── ERA DATA ───────────────────────────────────────────────────────────────
// One source of truth for the six eras and their level lists (GAMEPLAY-V2.md
// Phase 0.5). Previously a level was just an `int` scoped to an era string,
// with the boss position and question count baked in as the literal `10`
// at ~18 call sites — this is what every one of them now reads from instead.
class EraData {
  final String id;
  final String name;
  final String subtitle;
  final String guide;
  final List<String> enemyTypes;
  final String bossName;
  final String bossDialogue;
  final Color groundColor;
  final String historicalText;

  /// DepEd MATATAG grade (5 or 6) and three-term slot (1-3) this era
  /// occupies — see GAMEPLAY-V2.md Section 1. Replaces the old standalone
  /// `eraGradeMap`, which only ever mapped one grade per era anyway.
  final int grade;
  final int term;

  /// Each level's BOW week numbers, in order — one list per level, sourced
  /// from GAMEPLAY-V2.md Section 1's "Curriculum weeks, sourced" table
  /// (itself transcribed from the DepEd Budget of Work PDFs; real data, not
  /// invented). The era's level count is simply this list's length, uneven
  /// on purpose (10/5/7/8/8/5 per Section 1) because the curriculum is
  /// uneven — do not normalise it, and do not add a separate `levelCount`
  /// field that could drift out of sync with it.
  final List<List<int>> levelWeeks;

  const EraData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.guide,
    required this.enemyTypes,
    required this.bossName,
    required this.bossDialogue,
    required this.groundColor,
    required this.historicalText,
    required this.grade,
    required this.term,
    required this.levelWeeks,
  });

  /// This era's levels, 1-indexed, last one flagged `isBoss`, each carrying
  /// its real BOW weeks from [levelWeeks].
  List<Level> get levels => List.generate(
        levelWeeks.length,
        (i) => Level(
          eraId: id,
          index: i + 1,
          curriculum: CurriculumTag(grade: grade, term: term, weeks: levelWeeks[i]),
          isBoss: i + 1 == levelWeeks.length,
          lengthUnits: CombatConstants.lengthUnitsDefault,
        ),
      );
}

// Era names and subtitles are the six titles of GAMEPLAY-V2.md Section 1 (the
// MATATAG Three-Term BOW), the same ones the dashboard shows; they carry no
// date ranges. Only the ids below stay as they were.
//
// Era ids for pre-colonial/spanish/american/ww2/modern predate the six-era
// curriculum and are kept as-is rather than renamed: they're the join key for
// already-recorded progress (Hive locally, and QuizResult/EraProgress on the
// backend), and nothing in Section 1 requires renaming them, only adding the
// era the old five-era list was missing entirely — Era 3, Rise of Filipino
// Nationalism, added below as 'nationalism'. `historicalText`/`subtitle` for
// the five carried-over eras are otherwise unchanged from before this phase;
// Section 1 notes that eras 4 and 5 each span more than one visual period
// (era4 Spanish→American, era5 American→WW2→Modern) and that some of what
// reads today as "American Period" content actually belongs on the Era 3/4
// boundary — re-splitting that text needs the source BOW PDFs (Appendix D),
// not a code change, so it's left as a known gap rather than guessed at.
const List<EraData> allEras = [
  EraData(
    id: 'pre-colonial',
    name: 'Sinaunang Pilipinas',
    subtitle: 'Ancient Philippines',
    guide: 'Datu Lapu-Lapu',
    enemyTypes: ['tribal_warrior', 'dark_spirit'],
    bossName: 'bakunawa',
    bossDialogue: 'Patunayan mo ang iyong karunungan!',
    groundColor: Color(0xFF5D4E37),
    historicalText:
        'Bago dumating ang mga mananakop, ang mga Pilipino ay nabuhay sa mga '
        'barangay — maliliit na komunidad na pinamumunuan ng isang datu. Ang bawat barangay '
        'ay may sariling kaugalian, tradisyon, at sistema ng pamahalaan. Ang mga sinaunang '
        'Pilipino ay mahusay na mangangalakal — nakipagpalakasan sila sa China, India, at '
        'iba pang bansa sa Asya. Gumamit sila ng baybayin, isang sistema ng pagsulat na '
        'orihinal na Filipino. Ang Labanan sa Mactan noong 1521 ay nagpakita ng lakas ng '
        'loob ng mga Pilipino nang ipagtanggol ni Datu Lapu-Lapu ang kanyang lupain.',
    grade: 5,
    term: 1,
    levelWeeks: [
      [1], [2], [3], [4], [5], [6], [7], [8], [9], [10],
    ],
  ),
  EraData(
    id: 'spanish',
    name: 'Pananakop ng Espanya',
    subtitle: 'Spanish Colonization',
    guide: 'Jose Rizal',
    enemyTypes: ['spanish_soldier', 'tax_collector'],
    bossName: 'governor',
    bossDialogue: 'Kaya mo bang harapin ang kapangyarihan ng Espanya?',
    groundColor: Color(0xFF808080),
    historicalText:
        'Noong 1565, nagsimula ang pananakop ng Espanya sa Pilipinas sa ilalim '
        'ni Miguel Lopez de Legazpi. Itinayo nila ang Intramuros sa Maynila bilang sentro '
        'ng kanilang kapangyarihan. Sa loob ng mahigit tatlong daang taon, kinontrol ng '
        'Espanya ang relihiyon, kalakalan, at pamahalaan ng bansa. Ang sistemang encomienda '
        'ay nagbigay ng lupain sa mga Espanyol. Naglunsad ng mga rebolusyon ang mga Pilipino '
        'laban sa pananakop — mula sa Dagohoy Rebellion hanggang sa Himagsikan ng 1896 '
        'na pinamunuan ni Andres Bonifacio at ang Katipunan.',
    grade: 5,
    term: 2,
    levelWeeks: [
      [1, 2], [3, 4, 5], [6, 7], [8], [9, 10],
    ],
  ),
  EraData(
    id: 'nationalism',
    name: 'Pag-usbong ng Nasyonalismo',
    subtitle: 'Rise of Nationalism',
    // Reuses the Spanish era's enemy set, wall art, ground colour and boss
    // sprite throughout the codebase (GAMEPLAY-V2.md Section 1: "Era 3 has
    // no boss sprite... reuse the Governor if time runs out"; "Era 3 reuses
    // spanish_wall.png, which is period-correct").
    guide: 'Marcelo H. del Pilar',
    enemyTypes: ['spanish_soldier', 'tax_collector'],
    bossName: 'governor',
    bossDialogue: 'Ang pluma ba ay mas matalas sa espada?',
    groundColor: Color(0xFF808080),
    historicalText:
        'Noong huling bahagi ng ika-19 na siglo, sumibol ang damdaming '
        'nasyonalista sa mga Pilipino. Itinatag ang Propaganda Movement ng mga '
        'ilustrado tulad nina Jose Rizal, Marcelo H. del Pilar, at Graciano '
        'Lopez Jaena, na naglathala ng pahayagang La Solidaridad sa Espanya '
        'upang hingin ang reporma. Isinulat ni Rizal ang Noli Me Tangere at El '
        'Filibusterismo upang ilantad ang mga kaapihan sa ilalim ng Espanya. '
        'Itinatag ni Rizal ang La Liga Filipina noong 1892. Ang GOMBURZA — '
        'sina Padre Gomez, Burgos, at Zamora — ay pinatay noong 1872, isang '
        'pangyayaring nagpaalab sa damdaming makabayan ng mga Pilipino.',
    grade: 5,
    term: 3,
    // 7 levels, not 6 — GAMEPLAY-V2.md's original count of this era's BOW
    // competency groups miscounted; corrected in its revision 5 (2026-09-25)
    // after recounting the source PDF gives [1]/[2-3]/[4-5]/[6]/[7]/[8-9]/[10].
    levelWeeks: [
      [1], [2, 3], [4, 5], [6], [7], [8, 9], [10],
    ],
  ),
  EraData(
    id: 'american',
    name: 'Himagsikan at Imperyalismong Amerikano',
    subtitle: 'Revolution & American Imperialism',
    guide: 'Apolinario Mabini',
    enemyTypes: ['american_soldier', 'propaganda'],
    bossName: 'general',
    bossDialogue: 'Ipakita mo na hindi ka mabibili ng pangako ng kalayaan!',
    groundColor: Color(0xFF8B6914),
    historicalText:
        'Noong 1898, pagkatapos ng Digmaang Espanyol-Amerikano, inilipat ang '
        'Pilipinas sa Estados Unidos. Itinatag ng mga Amerikano ang sistema ng edukasyong '
        'pampubliko at nagpadala ng mga Thomasites — mga guro mula Amerika. Nagtagal ang '
        'pananakop ng Amerika at naglunsad ng Philippine-American War na nagkahalaga ng '
        'maraming buhay ng Pilipino. Noong 1935, naitatag ang Commonwealth ng Pilipinas na '
        'may Manuel Quezon bilang unang Pangulo, at noong Hulyo 4, 1946, opisyal na nakamit '
        'ng Pilipinas ang kalayaan.',
    grade: 6,
    term: 1,
    levelWeeks: [
      [1], [2], [3], [4], [5], [6], [7, 8], [9, 10],
    ],
  ),
  EraData(
    id: 'ww2',
    name: 'Pamahalaang Kolonyal at Pananakop ng Hapon',
    subtitle: 'Colonial Government & Japanese Occupation',
    guide: 'Josefa Llanes Escoda',
    enemyTypes: ['japanese_soldier', 'tank'],
    bossName: 'commander',
    bossDialogue: 'Ang kalayaan ay hindi ipinagkakaloob — kinukuha!',
    groundColor: Color(0xFF4A4A3A),
    historicalText:
        'Noong Disyembre 8, 1941, sinalakay ng Hapon ang Pilipinas. Naganap ang '
        'malupit na Bataan Death March noong Abril 1942. Sa ilalim ng pananakop ng Hapon, '
        'naghirap ang mga Pilipino. Nabuo ang mga gerilya na lumaban sa Hapon — kabilang '
        'ang Hukbalahap. Noong Oktubre 1944, bumalik si General Douglas MacArthur at '
        'nagsimula ang Labanan para sa Pilipinas. Ang Labanan ng Maynila noong 1945 ay '
        'isa sa pinaka-mapanirang labanan sa lungsod sa buong Ikalawang Digmaang Pandaigdig.',
    grade: 6,
    term: 2,
    levelWeeks: [
      [1, 2], [3], [4], [5], [6], [7], [8, 9], [10],
    ],
  ),
  EraData(
    id: 'modern',
    name: 'Batas Militar at Muling Pagbangon ng Demokrasya',
    subtitle: 'Martial Law & Democracy',
    guide: 'Corazon Aquino',
    enemyTypes: ['corruption_figure', 'misinfo_cloud'],
    bossName: 'corruption_boss',
    bossDialogue: 'Ang katotohanan ang iyong sandata!',
    groundColor: Color(0xFF555555),
    historicalText:
        'Noong Hulyo 4, 1946, opisyal na naging malaya ang Pilipinas. Sa mga '
        'sumunod na dekada, hinarap ng bansa ang maraming pagsubok — mula sa Marcos '
        'diktadura (1972–1986) hanggang sa People Power Revolution na nagluklok kay Corazon '
        'Aquino bilang Pangulo noong 1986. Ang EDSA Revolution ay naging simbolo ng '
        'kapangyarihan ng mamamayan sa buong mundo. Patuloy na lumalago ang Pilipinas '
        'bilang isang demokratikong bansa na nagtataguyod ng kalayaan, katarungan, at '
        'pagkakapantay-pantay para sa lahat ng Pilipino.',
    grade: 6,
    term: 3,
    levelWeeks: [
      [1, 2, 3], [4], [5, 6], [7, 8], [9, 10],
    ],
  ),
];

// ─── CHARACTER DATA ─────────────────────────────────────────────────────────
class CharacterData {
  final String id;
  final String name;
  final String era;
  final String description;
  final int unlockCost;

  const CharacterData({
    required this.id,
    required this.name,
    required this.era,
    required this.description,
    this.unlockCost = 0,
  });
}

const List<CharacterData> allCharacters = [
  CharacterData(
    id: 'lapu',
    name: 'Datu Lapu-Lapu',
    era: 'Sinaunang Pilipinas',
    description: 'Bayani ng Mactan',
    unlockCost: 0,
  ),
  CharacterData(
    id: 'rizal',
    name: 'Jose Rizal',
    era: 'Pananakop ng Espanya',
    description: 'Pambansang Bayani',
    unlockCost: 0,
  ),
  CharacterData(
    id: 'luna',
    name: 'Heneral Antonio Luna',
    era: 'Himagsikan at Imperyalismong Amerikano',
    description: 'Heneral ng Hukbong Pilipino',
    unlockCost: 100,
  ),
  CharacterData(
    id: 'bonifacio',
    name: 'Andres Bonifacio',
    era: 'Pananakop ng Espanya',
    description: 'Ama ng Katipunan',
    unlockCost: 200,
  ),
  CharacterData(
    id: 'delpilar',
    name: 'Gregorio Del Pilar',
    era: 'Himagsikan at Imperyalismong Amerikano',
    description: 'Batang Heneral ng Tirad Pass',
    unlockCost: 300,
  ),
];

// Helper to look up era data by ID
EraData getEraById(String eraId) {
  return allEras.firstWhere(
    (e) => e.id == eraId,
    orElse: () => allEras[1], // default to spanish
  );
}

/// This era's 1-based number in Section 1's era table (1 = Sinaunang
/// Pilipinas … 6 = Batas Militar). [allEras] is declared in that order, so
/// the number is simply the index + 1.
///
/// Used by the Tiled level loader, whose files are named
/// `era<N>_<n>.tmx` — filenames use the number rather than the string id so
/// levels sort in curriculum order on disk. Returns 0 for an unknown id.
int eraNumberFor(String eraId) {
  final i = allEras.indexWhere((e) => e.id == eraId);
  return i < 0 ? 0 : i + 1;
}

// Helper to look up character data by ID
CharacterData getCharacterById(String characterId) {
  return allCharacters.firstWhere(
    (c) => c.id == characterId,
    orElse: () => allCharacters[1], // default to rizal
  );
}
