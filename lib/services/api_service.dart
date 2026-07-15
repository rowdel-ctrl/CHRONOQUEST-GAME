import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import '../models/student.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../models/era_progress.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Dio get _dio => DioClient.instance;

  // ─── AUTH ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String classCode, String name) async {
    try {
      final response = await _dio.post('/student/login', data: {
        'classCode': classCode,
        'name': name,
      });
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      await StorageService.saveToken(token);

      final user = Student.fromJson(data['user'] as Map<String, dynamic>);
      await StorageService.saveStudent(user);

      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── PROFILE ──────────────────────────────────────────────────────────────
  Future<Student> getProfile() async {
    try {
      final response = await _dio.get('/student/profile');
      final student =
          Student.fromJson(response.data as Map<String, dynamic>);
      await StorageService.saveStudent(student);
      return student;
    } on DioException catch (e) {
      // Fallback to cached student
      final cached = StorageService.getStudent();
      if (cached != null) return cached;
      throw _handleError(e);
    }
  }

  // ─── QUESTIONS ────────────────────────────────────────────────────────────
  Future<List<Question>> getQuestions(
    String era,
    int level, {
    String? gradeLevel,
    int limit = 10,
  }) async {
    // Try cache first for offline support
    final cached = StorageService.getCachedQuestions(era, level);
    if (cached != null) {
      return cached.map((q) => Question.fromJson(q)).toList();
    }

    try {
      final response = await _dio.get(
        '/questions/by-era/$era',
        queryParameters: {
          'level': level,
          if (gradeLevel != null) 'gradeLevel': gradeLevel,
          'limit': limit,
        },
      );

      final List<dynamic> data = response.data is List
          ? response.data as List<dynamic>
          : (response.data['questions'] as List<dynamic>?) ?? [];

      final questions =
          data.map((q) => Question.fromJson(q as Map<String, dynamic>)).toList();

      // Cache for offline
      await StorageService.cacheQuestions(
        era,
        level,
        data.cast<Map<String, dynamic>>(),
      );

      return questions;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── RESULTS ──────────────────────────────────────────────────────────────
  Future<void> submitResult(QuizResult result) async {
    try {
      await _dio.post('/student/results', data: result.toJson());
    } on DioException catch (e) {
      // Queue for later submission if offline
      throw _handleError(e);
    }
  }

  Future<List<QuizResult>> getResults() async {
    try {
      final response = await _dio.get('/student/results');
      final List<dynamic> data = response.data is List
          ? response.data as List<dynamic>
          : (response.data['results'] as List<dynamic>?) ?? [];
      return data
          .map((r) => QuizResult.fromJson(r as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── ERA PROGRESS ─────────────────────────────────────────────────────────
  Future<Map<String, EraProgress>> getEraProgress() async {
    try {
      final response = await _dio.get('/student/era-progress');
      final data = response.data;

      final Map<String, EraProgress> progress = {};

      if (data is Map<String, dynamic>) {
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            progress[key] = EraProgress.fromJson(value);
            StorageService.cacheEraProgress(key, value);
          }
        });
      } else if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            final eraId = item['eraId'] as String? ?? '';
            if (eraId.isNotEmpty) {
              progress[eraId] = EraProgress.fromJson(item);
              StorageService.cacheEraProgress(eraId, item);
            }
          }
        }
      }

      return progress;
    } on DioException catch (e) {
      // Fallback to cached progress
      final Map<String, EraProgress> cached = {};
      for (final eraId in ['pre-colonial', 'spanish', 'american', 'ww2', 'modern']) {
        final data = StorageService.getCachedEraProgress(eraId);
        if (data != null) {
          cached[eraId] = EraProgress.fromJson(data);
        }
      }
      if (cached.isNotEmpty) return cached;
      throw _handleError(e);
    }
  }

  // ─── POWERUPS ─────────────────────────────────────────────────────────────
  Future<void> updatePowerUps(Map<String, int> powerUps) async {
    try {
      await _dio.patch('/student/power-ups', data: powerUps);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── LEADERBOARD ──────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getLeaderboard(String scope) async {
    try {
      final response = await _dio.get(
        '/student/leaderboard',
        queryParameters: {'scope': scope},
      );
      final List<dynamic> data = response.data is List
          ? response.data as List<dynamic>
          : (response.data['leaderboard'] as List<dynamic>?) ?? [];
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── ERROR HANDLING ───────────────────────────────────────────────────────
  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Walang internet connection. Subukan muli.';
    }
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'] as String;
      }
      return 'Error ${e.response?.statusCode}';
    }
    return 'Hindi makakonekta sa server. Subukan muli.';
  }
}
