import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import '../models/codex_entry.dart';
import '../models/control_scheme.dart';
import '../models/hearts_state.dart';
import '../models/student.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'student_token';
  static const _studentKey = 'student_data';
  static const _characterKey = 'selected_character';

  // ─── JWT TOKEN ─────────────────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<bool> hasToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // ─── STUDENT DATA (Hive) ──────────────────────────────────────────────────
  static Box? _appBox;

  static Future<void> initHive() async {
    await Hive.initFlutter();
    _appBox = await Hive.openBox('chronoquest');
  }

  static Box get appBox {
    _appBox ??= Hive.box('chronoquest');
    return _appBox!;
  }

  static Future<void> saveStudent(Student student) async {
    await appBox.put(_studentKey, student.toJson());
  }

  static Student? getStudent() {
    final data = appBox.get(_studentKey);
    if (data == null) return null;
    return Student.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // ─── CHARACTER SELECTION ──────────────────────────────────────────────────
  static Future<void> saveCharacter(String characterId) async {
    await appBox.put(_characterKey, characterId);
  }

  static String getCharacter() {
    return appBox.get(_characterKey, defaultValue: 'rizal') as String;
  }

  // ─── CONTROL SCHEME ───────────────────────────────────────────────────────
  static const _controlSchemeKey = 'control_scheme';

  /// Movement controls chosen in Settings. Joystick until a student picks
  /// otherwise.
  static ControlScheme getControlScheme() =>
      ControlScheme.fromName(appBox.get(_controlSchemeKey) as String?);

  static Future<void> setControlScheme(ControlScheme scheme) async {
    await appBox.put(_controlSchemeKey, scheme.name);
  }

  // ─── TESTING SWITCH ───────────────────────────────────────────────────────
  static const _unlockAllKey = 'dev_unlock_all';

  /// Whether every era and level is shown as unlocked (a temporary testing
  /// aid; see `unlock_all_provider.dart`).
  static bool getUnlockAll() =>
      appBox.get(_unlockAllKey, defaultValue: false) as bool;

  static Future<void> setUnlockAll(bool value) async {
    await appBox.put(_unlockAllKey, value);
  }

  // ─── ERA PROGRESS CACHE ───────────────────────────────────────────────────
  static Future<void> cacheEraProgress(
      String eraId, Map<String, dynamic> progress) async {
    await appBox.put('era_progress_$eraId', progress);
  }

  static Map<String, dynamic>? getCachedEraProgress(String eraId) {
    final data = appBox.get('era_progress_$eraId');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  // ─── LEVEL PROGRESS ──────────────────────────────────────────────────────
  static Future<void> saveLevelCompleted(
      String eraId, int level, int stars) async {
    final key = 'levels_$eraId';
    final Map<dynamic, dynamic> levels =
        Map<dynamic, dynamic>.from(appBox.get(key, defaultValue: {}) as Map);
    levels[level.toString()] = stars;
    await appBox.put(key, levels);
  }

  static Map<int, int> getCompletedLevels(String eraId) {
    final key = 'levels_$eraId';
    final data = appBox.get(key);
    if (data == null) return {};
    final Map<dynamic, dynamic> raw = Map<dynamic, dynamic>.from(data as Map);
    return raw.map(
        (k, v) => MapEntry(int.parse(k.toString()), v as int));
  }

  // ─── PENDING RESULTS (offline queue) ──────────────────────────────────────
  static const _pendingResultsKey = 'pending_results';

  static Future<void> queuePendingResult(Map<String, dynamic> resultJson) async {
    final List<dynamic> pending =
        List<dynamic>.from(appBox.get(_pendingResultsKey, defaultValue: []) as List);
    pending.add(resultJson);
    await appBox.put(_pendingResultsKey, pending);
  }

  static List<Map<String, dynamic>> getPendingResults() {
    final List<dynamic> pending =
        List<dynamic>.from(appBox.get(_pendingResultsKey, defaultValue: []) as List);
    return pending.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> clearPendingResults() async {
    await appBox.put(_pendingResultsKey, []);
  }

  // ─── CODEX (claimed artifacts) ───────────────────────────────────────────
  // One key per era, matching the 'levels_<eraId>' pattern above. Stored as
  // a map keyed by questionId rather than a list, so re-claiming the same
  // artifact on a replay updates in place instead of duplicating the tile.

  static String _codexKey(String eraId) => 'codex_$eraId';

  /// Records a claimed artifact. Idempotent per question: claiming the same
  /// one again (replaying a level) overwrites rather than appends.
  static Future<void> saveCodexEntry(CodexEntry entry) async {
    final key = _codexKey(entry.eraId);
    final Map<dynamic, dynamic> entries =
        Map<dynamic, dynamic>.from(appBox.get(key, defaultValue: {}) as Map);
    entries[entry.questionId] = entry.toJson();
    await appBox.put(key, entries);
  }

  /// Every artifact claimed in [eraId], newest claim first.
  static List<CodexEntry> getCodexEntries(String eraId) {
    final data = appBox.get(_codexKey(eraId));
    if (data == null) return [];
    final Map<dynamic, dynamic> raw = Map<dynamic, dynamic>.from(data as Map);
    final entries = raw.values
        .map((e) => CodexEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    entries.sort((a, b) => b.claimedAtMs.compareTo(a.claimedAtMs));
    return entries;
  }

  /// Total claimed across every era — the Profile tab's headline count.
  static int getCodexTotal() {
    return allEras.fold(0, (sum, era) => sum + getCodexEntries(era.id).length);
  }

  // ─── TUTORIAL ─────────────────────────────────────────────────────────────
  static const _tutorialSeenKey = 'has_seen_tutorial';

  static bool hasSeenTutorial() {
    return appBox.get(_tutorialSeenKey, defaultValue: false) as bool;
  }

  static Future<void> markTutorialSeen() async {
    await appBox.put(_tutorialSeenKey, true);
  }

  // ─── HEARTS (persistent, level-attempt gate) ─────────────────────────────
  static const _heartsCountKey = 'hearts_count';
  static const _heartsRegenStartKey = 'hearts_regen_start_ms';

  static HeartsState getHeartsState() {
    final count = appBox.get(_heartsCountKey) as int?;
    if (count == null) return HeartsState.initial();
    return HeartsState(
      count: count,
      regenStartMs: appBox.get(_heartsRegenStartKey) as int?,
    );
  }

  static Future<void> saveHeartsState(HeartsState hearts) async {
    await appBox.put(_heartsCountKey, hearts.count);
    if (hearts.regenStartMs == null) {
      await appBox.delete(_heartsRegenStartKey);
    } else {
      await appBox.put(_heartsRegenStartKey, hearts.regenStartMs);
    }
  }

  // ─── CLEAR ALL ────────────────────────────────────────────────────────────
  static Future<void> clearAll() async {
    await _storage.deleteAll();
    await appBox.clear();
  }
}