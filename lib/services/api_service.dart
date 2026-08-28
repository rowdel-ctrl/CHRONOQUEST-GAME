import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import '../models/student.dart';
import '../models/quiz_result.dart';
import '../models/era_progress.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Dio get _dio => DioClient.instance;

  // ─── AUTH ─────────────────────────────────────────────────────────────────

  Future<void> changePassword(String newPassword) async {
    try {
      await _dio
          .post('/student/change-password', data: {'newPassword': newPassword});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String classCode,
    required String username,
    String? name,
    required String password,
  }) async {
    try {
      final body = <String, dynamic>{
        'classCode': classCode,
        'username': username,
        'password': password,
      };
      if (name != null && name.isNotEmpty) {
        body['name'] = name;
      }

      final response = await _dio.post('/student/login', data: body);
      final data = (response.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
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
      final envelope = response.data as Map<String, dynamic>;
      final student =
          Student.fromJson(envelope['data'] as Map<String, dynamic>);
      await StorageService.saveStudent(student);
      return student;
    } on DioException catch (e) {
      // Fallback to cached student
      final cached = StorageService.getStudent();
      if (cached != null) return cached;
      throw _handleError(e);
    }
  }

  // ─── RESULTS ──────────────────────────────────────────────────────────────
  Future<void> submitResult(QuizResult result) async {
    try {
      await _dio.post('/student/results', data: result.toJson());
    } on DioException catch (e) {
      await StorageService.queuePendingResult(result.toJson());
      throw _handleError(e);
    }
  }

  /// Call on app launch and after any successful network call to flush
  /// results that failed to submit while offline.
  Future<void> flushPendingResults() async {
    final pending = StorageService.getPendingResults();
    if (pending.isEmpty) return;

    final stillFailed = <Map<String, dynamic>>[];
    for (final json in pending) {
      try {
        await _dio.post('/student/results', data: json);
      } catch (_) {
        stillFailed.add(json);
      }
    }

    if (stillFailed.isEmpty) {
      await StorageService.clearPendingResults();
    } else {
      await StorageService.clearPendingResults();
      for (final json in stillFailed) {
        await StorageService.queuePendingResult(json);
      }
    }
  }

  Future<List<QuizResult>> getResults() async {
    try {
      final response = await _dio.get('/student/results');
      final data = (response.data as Map<String, dynamic>)['data'];
      final List<dynamic> list = data is List ? data : [];
      return list
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
      final data = (response.data as Map<String, dynamic>)['data']['progress'];

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
      for (final eraId in [
        'pre-colonial',
        'spanish',
        'american',
        'ww2',
        'modern'
      ]) {
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
      final envelope = response.data as Map<String, dynamic>;
      final data = envelope['data']['leaders'];
      final List<dynamic> list = data is List ? data : [];
      return list.cast<Map<String, dynamic>>();
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
    if (e.type == DioExceptionType.connectionError) {
      return 'Hindi maabot ang server. I-check kung tumatakbo ang backend at tama ang API URL.';
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
