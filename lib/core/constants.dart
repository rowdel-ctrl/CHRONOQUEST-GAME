import 'package:flutter/material.dart';

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

// ─── GAME CONSTANTS ─────────────────────────────────────────────────────────
class GameConstants {
  static const double groundY = 520.0;
  static const double playerX = 80.0;
  static const double worldScrollSpeed = 150.0;
  static const double gravity = 900.0;
  static const double jumpForce = -480.0;
  static const double enemySpeed = 90.0;
  static const double spawnInterval = 800.0;
  static const int livesPerLevel = 10;
  static const int questionsPerLevel = 10; // levels 1-9
  static const int bossWarmupQuestions = 10; // level 10, phase 1
  static const int bossFightQuestions = 12; // level 10, phase 2
  static const int bossHealth = 12; // one hit per boss-phase question
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

// ─── ERA-GRADE MAP ──────────────────────────────────────────────────────────
const Map<String, List<String>> eraGradeMap = {
  'pre-colonial': ['grade5'],
  'spanish': ['grade5'],
  'american': ['grade6'],
  'ww2': ['grade6'],
  'modern': ['grade6'],
};

// ─── ERA DATA ───────────────────────────────────────────────────────────────
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
  });
}

const List<EraData> allEras = [
  EraData(
    id: 'pre-colonial',
    name: 'Sinaunang Panahon',
    subtitle: 'Pre-colonial',
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
  ),
  EraData(
    id: 'spanish',
    name: 'Panahon ng Kastila',
    subtitle: 'Spanish Colonial 1565–1898',
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
  ),
  EraData(
    id: 'american',
    name: 'Panahon ng Amerikano',
    subtitle: 'American Period 1898–1946',
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
  ),
  EraData(
    id: 'ww2',
    name: 'Ikalawang Digmaang Pandaigdig',
    subtitle: 'World War II 1941–1945',
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
  ),
  EraData(
    id: 'modern',
    name: 'Makabagong Panahon',
    subtitle: 'Modern 1946–present',
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
    era: 'Sinaunang Panahon',
    description: 'Bayani ng Mactan',
    unlockCost: 0,
  ),
  CharacterData(
    id: 'rizal',
    name: 'Jose Rizal',
    era: 'Panahon ng Kastila',
    description: 'Pambansang Bayani',
    unlockCost: 0,
  ),
  CharacterData(
    id: 'luna',
    name: 'Heneral Antonio Luna',
    era: 'Panahon ng Amerikano',
    description: 'Heneral ng Hukbong Pilipino',
    unlockCost: 100,
  ),
  CharacterData(
    id: 'bonifacio',
    name: 'Andres Bonifacio',
    era: 'Panahon ng Kastila',
    description: 'Ama ng Katipunan',
    unlockCost: 200,
  ),
  CharacterData(
    id: 'delpilar',
    name: 'Gregorio Del Pilar',
    era: 'Panahon ng Amerikano',
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

// Helper to look up character data by ID
CharacterData getCharacterById(String characterId) {
  return allCharacters.firstWhere(
    (c) => c.id == characterId,
    orElse: () => allCharacters[1], // default to rizal
  );
}
