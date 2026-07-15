import 'package:flutter/material.dart';

// ─── COLORS ─────────────────────────────────────────────────────────────────
class AppColors {
  static const Color primary = Color(0xFF8B4513);
  static const Color primaryDark = Color(0xFF5C2D0A);
  static const Color primaryLight = Color(0xFFC4773B);
  static const Color accent = Color(0xFFD4AF37);
  static const Color background = Color(0xFFFAF7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF3EDE3);
  static const Color border = Color(0xFFE8D9C4);
  static const Color textPrimary = Color(0xFF2C1810);
  static const Color textSecondary = Color(0xFF7A5C42);
  static const Color textMuted = Color(0xFFB09880);
  static const Color success = Color(0xFF3A7D44);
  static const Color danger = Color(0xFFC0392B);
  static const Color warning = Color(0xFFD97706);
  static const Color info = Color(0xFF2E6DA4);
}

// ─── FONTS ──────────────────────────────────────────────────────────────────
class AppFonts {
  static const String display = 'Playfair Display';
  static const String body = 'Source Sans 3';
}

// ─── API ────────────────────────────────────────────────────────────────────
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api/v1',
  );
}

// ─── GAME CONSTANTS ─────────────────────────────────────────────────────────
class GameConstants {
  static const double groundY = 520.0;
  static const double playerX = 80.0;
  static const double worldScrollSpeed = 150.0;
  static const double gravity = 900.0;
  static const double jumpForce = -480.0;
  static const double enemySpeed = 90.0;
  static const double spawnInterval = 500.0;
  static const int livesPerLevel = 3;
  static const int questionsPerLevel = 10;
  static const int bossHealth = 5;
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
  'pre-colonial': ['grade4', 'grade5'],
  'spanish': ['grade5'],
  'american': ['grade5', 'grade6'],
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
