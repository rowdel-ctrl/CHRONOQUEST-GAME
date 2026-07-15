import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

  // ─── QUESTION CACHE ──────────────────────────────────────────────────────
  static Future<void> cacheQuestions(
      String era, int level, List<Map<String, dynamic>> questions) async {
    await appBox.put('questions_${era}_$level', questions);
  }

  static List<Map<String, dynamic>>? getCachedQuestions(
      String era, int level) {
    final data = appBox.get('questions_${era}_$level');
    if (data == null) return null;
    return (data as List).cast<Map<String, dynamic>>();
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

  // ─── CLEAR ALL ────────────────────────────────────────────────────────────
  static Future<void> clearAll() async {
    await _storage.deleteAll();
    await appBox.clear();
  }
}
