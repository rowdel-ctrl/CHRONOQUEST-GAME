import 'package:dio/dio.dart';

import '../core/dio_client.dart';
import '../data/question_bank.dart';
import 'storage_service.dart';

/// Keeps the questions a teacher published on the phone.
///
/// The app ships with a full set of questions and always works from them. When
/// the student's teacher has published changes, this downloads them, keeps a copy
/// on the phone, and hands them to [QuestionBank]. Offline, the last copy is used;
/// with none, the bundled questions are. Nothing here ever blocks play.
class QuestionSync {
  const QuestionSync._();

  static bool _syncing = false;

  /// Applies the copy saved on the phone, if it is for [classCode]. Needs no
  /// network, so call it at startup.
  static void restore(String classCode) {
    final cache = StorageService.getQuestionCache();
    if (cache == null || cache['classCode'] != classCode) return;
    final levels = cache['levels'];
    if (levels is Map) {
      QuestionBank.applySynced(Map<String, dynamic>.from(levels), picks: cache['picks']);
    }
  }

  /// Downloads the teacher's published questions if they changed since the
  /// copy on the phone. Returns whether anything new was applied. [fetch] is for
  /// tests; it takes the tag of the copy held and returns the response data.
  static Future<bool> sync(
    String classCode, {
    Future<Map<String, dynamic>> Function(String? tag)? fetch,
  }) async {
    if (_syncing || classCode.isEmpty) return false;
    _syncing = true;
    try {
      final cache = StorageService.getQuestionCache();
      final tag = cache != null && cache['classCode'] == classCode
          ? cache['tag'] as String?
          : null;

      final data = await (fetch ?? _fetch)(tag);
      if (data['upToDate'] == true) return false;

      final newTag = data['tag'];
      final levels = data['levels'];
      if (newTag is! String || levels is! Map) return false;

      final downloaded = Map<String, dynamic>.from(levels);
      final picks = data['picks'];
      QuestionBank.applySynced(downloaded, picks: picks);
      await StorageService.saveQuestionCache({
        'classCode': classCode,
        'tag': newTag,
        'levels': downloaded,
        if (picks is Map) 'picks': picks,
      });
      return true;
    } catch (_) {
      // Offline or a bad reply: keep playing with what the phone has.
      return false;
    } finally {
      _syncing = false;
    }
  }

  static Future<Map<String, dynamic>> _fetch(String? tag) async {
    final response = await DioClient.instance.get(
      '/student/questions',
      queryParameters: {if (tag != null) 'tag': tag},
      options: Options(receiveTimeout: const Duration(seconds: 20)),
    );
    final body = response.data as Map;
    return Map<String, dynamic>.from(body['data'] as Map);
  }
}
