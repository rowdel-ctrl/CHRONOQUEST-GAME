import 'dart:convert';

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

  // ─── LAST SIGN-IN ─────────────────────────────────────────────────────────
  // So "Balik na ako" only has to ask for the password. Never the password.
  static const _lastClassCodeKey = 'last_class_code';
  static const _lastUsernameKey = 'last_username';

  /// The class code and username of the last successful sign-in on this phone,
  /// or null. It survives logout (see [clearAll]).
  static ({String classCode, String username})? getLastSignIn() {
    final code = appBox.get(_lastClassCodeKey) as String?;
    final user = appBox.get(_lastUsernameKey) as String?;
    if (code == null || code.isEmpty || user == null || user.isEmpty) return null;
    return (classCode: code, username: user);
  }

  static Future<void> saveLastSignIn(String classCode, String username) async {
    await appBox.put(_lastClassCodeKey, classCode);
    await appBox.put(_lastUsernameKey, username);
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

  // ─── SOUND (Settings > Tunog) ─────────────────────────────────────────────
  static bool getSoundEnabled() =>
      appBox.get('sound_enabled', defaultValue: true) as bool;
  static bool getMusicEnabled() =>
      appBox.get('music_enabled', defaultValue: true) as bool;
  static double getSoundVolume() =>
      (appBox.get('sound_volume', defaultValue: 1.0) as num).toDouble();
  static double getMusicVolume() =>
      (appBox.get('music_volume', defaultValue: 1.0) as num).toDouble();

  static Future<void> setSoundEnabled(bool v) => appBox.put('sound_enabled', v);
  static Future<void> setMusicEnabled(bool v) => appBox.put('music_enabled', v);
  static Future<void> setSoundVolume(double v) => appBox.put('sound_volume', v);
  static Future<void> setMusicVolume(double v) => appBox.put('music_volume', v);

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

  // ─── HEARTS PER STUDENT ───────────────────────────────────────────────────
  // Hearts belong to the student, like the wallet: they survive logout and a
  // restart, and a student sharing the phone has their own. (They used to be one
  // set for the whole phone, which logout wiped, so logging out and restarting the
  // app gave a full set of hearts.)
  static const _heartsPerStudentPrefix = 'student_hearts_';
  static String _heartsKey(String studentId) => '$_heartsPerStudentPrefix$studentId';

  static bool hasHeartsFor(String studentId) =>
      appBox.get(_heartsKey(studentId)) is Map;

  /// This student's hearts. A student with none saved yet takes what the phone
  /// kept the old way (one set per phone), or a full set if there is none.
  static HeartsState getHeartsStateFor(String studentId) {
    final raw = appBox.get(_heartsKey(studentId));
    if (raw is Map) {
      return HeartsState(
        count: (raw['count'] as num).toInt(),
        regenStartMs: (raw['regenStartMs'] as num?)?.toInt(),
      );
    }
    return getHeartsState();
  }

  static Future<void> saveHeartsStateFor(String studentId, HeartsState hearts) =>
      appBox.put(_heartsKey(studentId), {
        'count': hearts.count,
        'regenStartMs': hearts.regenStartMs,
      });

  /// Forgets the old one-set-per-phone hearts, once a student has taken them, so
  /// the next student on the phone starts with a full set of their own.
  static Future<void> dropPerPhoneHearts() async {
    await appBox.delete(_heartsCountKey);
    await appBox.delete(_heartsRegenStartKey);
  }

  // ─── WALLET (coins, power-ups, bought characters; one per student) ───────
  static String _walletKey(String studentId) => 'wallet_$studentId';

  /// What this student has earned and bought on this phone:
  /// {coins, fiftyFifty, timeFreeze, shield, unlocked: [characterId]}, or null.
  static Map<String, dynamic>? getWallet(String studentId) {
    final raw = appBox.get(_walletKey(studentId)) as String?;
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveWallet(String studentId, Map<String, dynamic> wallet) async {
    await appBox.put(_walletKey(studentId), jsonEncode(wallet));
  }

  // ─── DOWNLOADED QUESTIONS (teacher question bank) ────────────────────────
  static const _questionCacheKey = 'question_bank_cache';

  /// The last question download: `{classCode, tag, levels}`, or null.
  static Map<String, dynamic>? getQuestionCache() {
    final raw = appBox.get(_questionCacheKey) as String?;
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveQuestionCache(Map<String, dynamic> cache) =>
      appBox.put(_questionCacheKey, jsonEncode(cache));

  // ─── CLEAR ALL ────────────────────────────────────────────────────────────
  /// What logout does NOT wipe:
  ///  - each student's wallet (coins, power-ups, bought characters) and hearts.
  ///    They are saved under that student's id, so a shared phone keeps one set
  ///    per student and the next student never sees them;
  ///  - the last sign-in, so the next one only asks for the password;
  ///  - settings that belong to the phone, not the student: sound, controls, the
  ///    tutorial flag and the tester's Test Mode switch.
  /// Everything else is per phone and is wiped, so the next student starts clean:
  /// the student, level progress, the codex, the queued results and the
  /// downloaded questions.
  static bool _survivesLogout(Object? key) =>
      key is String &&
      (key.startsWith('wallet_') ||
          key.startsWith(_heartsPerStudentPrefix) ||
          _keptAcrossLogout.contains(key));

  static const _keptAcrossLogout = {
    _lastClassCodeKey,
    _lastUsernameKey,
    'sound_enabled',
    'music_enabled',
    'sound_volume',
    'music_volume',
    _controlSchemeKey,
    _tutorialSeenKey,
    _unlockAllKey,
  };

  static Future<void> clearAll() async {
    final kept = <String, dynamic>{
      for (final key in appBox.keys)
        if (_survivesLogout(key)) key as String: appBox.get(key),
    };
    await _storage.deleteAll();
    await appBox.clear();
    await appBox.putAll(kept);
  }
}