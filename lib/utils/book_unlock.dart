import '../core/constants.dart';
import '../services/storage_service.dart';

/// Which book comes unchained when a boss falls, and the mark that makes the chain break play
/// once on the era shelf.
class BookUnlock {
  BookUnlock._();

  /// The era that the boss of [eraId] opens: the next one among the eras of [gradeLevel]
  /// (`grade5`, `grade6`). Null for the last era of a grade, or an era that is not in it.
  static String? nextEraId(String eraId, String? gradeLevel) {
    final grade = (gradeLevel ?? 'grade5');
    final eras = allEras.where((e) => 'grade${e.grade}' == grade).toList();
    final i = eras.indexWhere((e) => e.id == eraId);
    if (i < 0 || i + 1 >= eras.length) return null;
    return eras[i + 1].id;
  }

  /// The mark the tester build's "watch the chain break again" button leaves: the era shelf
  /// plays the break for that book even though it is already open.
  static const String replayPrefix = 'replay:';

  /// The book the replay button unchains: the second era of [gradeLevel] (null if there is none).
  static String? replayEraId(String? gradeLevel) {
    final grade = (gradeLevel ?? 'grade5');
    final eras = allEras.where((e) => 'grade${e.grade}' == grade).toList();
    return eras.length < 2 ? null : eras[1].id;
  }

  /// Called when a boss is beaten for the first time: remembers the book to unchain, unless
  /// the student is a guest (a guest has the first era only) or there is no next era.
  /// Returns the era that was marked, or null.
  static Future<String?> markAfterBoss({
    required String eraId,
    required String? gradeLevel,
    required bool isGuest,
    required bool firstClear,
  }) async {
    if (isGuest || !firstClear) return null;
    final next = nextEraId(eraId, gradeLevel);
    if (next == null) return null;
    try {
      await StorageService.setPendingBookUnlock(next);
    } catch (_) {
      return null; // no local storage: the book is simply open
    }
    return next;
  }
}
