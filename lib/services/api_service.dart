import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../core/dio_client.dart';
import '../models/student.dart';
import '../models/quiz_result.dart';
import '../models/era_progress.dart';
import 'storage_service.dart';
import '../utils/login_errors.dart';
import 'guest_mode.dart';

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
      throw changePasswordErrorMessage(e);
    }
  }

  /// Signs in ("Balik na ako": [username] and [password]) or joins ("Bago ako":
  /// [name] and [password], no username: the server makes it from the name and
  /// sends it back). [allowSameName] goes on when a student with that name is
  /// already in the class and the student says it is someone else.
  Future<Map<String, dynamic>> login({
    required String classCode,
    String? username,
    String? name,
    required String password,
    bool allowSameName = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'classCode': classCode,
        'password': password,
      };
      if (username != null && username.isNotEmpty) {
        body['username'] = username;
      }
      if (name != null && name.isNotEmpty) {
        body['name'] = name;
      }
      if (allowSameName) {
        body['allowSameName'] = true;
      }

      final response = await _dio.post('/student/login', data: body);
      final data = (response.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      final token = data['token'] as String;
      await StorageService.saveToken(token);

      final user = Student.fromJson(data['user'] as Map<String, dynamic>);
      await StorageService.saveStudent(user);
      // The username the server has on record: a new student never typed one.
      final remembered =
          user.username.isNotEmpty ? user.username : (username ?? '');
      if (remembered.isNotEmpty) {
        await StorageService.saveLastSignIn(classCode, remembered);
      }

      return data;
    } on DioException catch (e) {
      // A name is only sent when joining ("Bago"); see loginErrorMessage.
      throw loginErrorMessage(e, joining: name != null && name.isNotEmpty);
    }
  }

  /// Asks the student's teacher to reset the password. The server gives the same
  /// answer whether or not that student exists, so nobody can use this to find
  /// out who is in a class. Throws a message that is ready to show.
  Future<void> requestPasswordReset({
    required String classCode,
    required String username,
  }) async {
    try {
      await _dio.post('/student/password-reset-request',
          data: {'classCode': classCode, 'username': username});
    } on DioException catch (e) {
      throw resetRequestErrorMessage(e);
    }
  }

  // ─── PROFILE ──────────────────────────────────────────────────────────────
  /// The profile as the server has it now. Throws when it cannot be reached, so
  /// the caller knows what it holds is not the cached copy.
  Future<Student> getFreshProfile() async {
    final response = await _dio.get('/student/profile');
    final envelope = response.data as Map<String, dynamic>;
    final student = Student.fromJson(envelope['data'] as Map<String, dynamic>);
    await StorageService.saveStudent(student);
    return student;
  }

  Future<Student> getProfile() async {
    try {
      return await getFreshProfile();
    } on DioException catch (e) {
      // Fallback to cached student
      final cached = StorageService.getStudent();
      if (cached != null) return cached;
      throw _handleError(e);
    }
  }

  /// Saves the wallet on the server so it follows the student to a new phone.
  /// True when the server took it. Never throws: the phone keeps its own copy, so
  /// a failure (offline, "saving too fast") only means "send it again later".
  Future<bool> saveWallet(Map<String, dynamic> wallet) async {
    // A guest has no account to save it to.
    if (DevFlags.skipAuth || GuestMode.active) return true;
    try {
      await _dio.put('/student/wallet', data: wallet);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── RESULTS ──────────────────────────────────────────────────────────────
  Future<void> submitResult(QuizResult result) async {
    // Dev no-login mode: drop results instead of queueing them, otherwise
    // they'd be flushed to the next real account that logs in.
    // A guest's results are not the teacher's to see, and are never queued.
    if (DevFlags.skipAuth || GuestMode.active) return;
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
    if (GuestMode.active) return;
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
    if (GuestMode.active) return const [];
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
    if (GuestMode.active) return const {};
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
      for (final eraId in allEras.map((e) => e.id)) {
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
  Future<List<Map<String, dynamic>>> getLeaderboard(String scope) async =>
      (await getLeaderboardBoard(scope)).leaders;

  /// The top list plus where the asking student stands: `myRank` is null when
  /// they are not in the top 20, `myScore` is their own score either way.
  Future<LeaderboardBoard> getLeaderboardBoard(String scope) async {
    try {
      final response = await _dio.get(
        '/student/leaderboard',
        queryParameters: {'scope': scope},
      );
      final envelope = response.data as Map<String, dynamic>;
      final data = envelope['data'] as Map<String, dynamic>;
      final leaders = data['leaders'];
      final List<dynamic> list = leaders is List ? leaders : [];
      return LeaderboardBoard(
        leaders: list.cast<Map<String, dynamic>>(),
        myRank: (data['myRank'] as num?)?.toInt(),
        myScore: (data['myScore'] as num?)?.toInt(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── ERROR HANDLING ───────────────────────────────────────────────────────
  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Walang internet. Subukan ulit.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Hindi maabot ang server. Subukan ulit mamaya.';
    }
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'] as String;
      }
      return 'Error ${e.response?.statusCode}';
    }
    return 'Hindi maka-connect sa server. Subukan ulit.';
  }
}

/// The reply of `GET /student/leaderboard`.
class LeaderboardBoard {
  final List<Map<String, dynamic>> leaders;
  final int? myRank;
  final int? myScore;
  const LeaderboardBoard({required this.leaders, this.myRank, this.myScore});
}
