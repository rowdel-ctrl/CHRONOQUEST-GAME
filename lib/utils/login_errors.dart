import 'package:dio/dio.dart';

import '../models/class_move.dart';

/// Joining found a student with the same name already in the class. Not an error
/// to show: the screen asks "Ikaw ba 'yon?" instead.
const String nameTakenMessage = 'May kapareho nang pangalan sa klase.';

/// The password was right but this account is open on another phone. Not an error to show:
/// the screen asks "Ituloy dito?" instead.
const String sessionActiveMessage = 'Gamit na ang account sa ibang device.';

/// The class has ended. A learner with an account there is offered a move to the new class
/// (see [ClassEndedException]); this text is for a join, which has nothing to move.
const String classEndedMessage =
    'Tapos na ang klase na ito. Itanong sa teacher mo ang bagong class code.';

/// The message a student sees when the login or join request fails.
///
/// The server answers in English and one answer can mean two things, so the raw
/// text is not shown. [joining] is true on the "Bago" tab (the form also sends a
/// real name) and false on "Babalik".
///
/// Why this needs the tab: the server treats a username it does not know as a new
/// student, so a mistyped username on "Babalik" comes back as "Real name is
/// required for first-time join", which says nothing useful to someone who is
/// not joining. And an existing username on "Bago" with a different password
/// comes back as "Incorrect password", when the real problem is that the name is
/// taken.
String loginErrorMessage(DioException e, {required bool joining}) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Mabagal o walang internet. Subukan ulit.';
    case DioExceptionType.connectionError:
      return 'Hindi maka-connect sa server. I-check ang internet at subukan ulit.';
    default:
      break;
  }

  final response = e.response;
  if (response == null) {
    return 'Hindi maka-connect sa server. Subukan ulit.';
  }

  final data = response.data;
  final server = data is Map && data['message'] is String
      ? (data['message'] as String).toLowerCase()
      : '';

  // Only the server's own code: it also answers 409 when it could not make a username.
  if (joining && data is Map && data['code'] == 'NAME_TAKEN') {
    return nameTakenMessage;
  }

  // The server's own code, after the password was checked.
  if (data is Map && data['code'] == 'SESSION_ACTIVE') {
    return sessionActiveMessage;
  }
  if (data is Map && data['code'] == 'CLASS_ENDED') return classEndedMessage;

  switch (response.statusCode) {
    case 400:
      if (server.contains('real name')) {
        return joining
            ? 'I-type ang tunay mong pangalan para sa teacher mo.'
            : 'Walang account na may ganitong username sa class code na ito. '
                "I-check ang username, o piliin ang 'BAGO AKO' para sumali.";
      }
      if (server.contains('password')) {
        return joining
            ? 'Dapat 6 characters o higit pa ang password.'
            : 'Mali ang password. Subukan ulit.';
      }
      if (server.contains('full')) {
        return 'Puno na ang klase na ito. Itanong sa teacher mo.';
      }
      // A server that does not make usernames yet answers a join with "class code
      // and username are required". Nothing the student typed is wrong.
      if (joining) return 'May problema sa pag-sali. Subukan ulit mamaya.';
      return 'I-type ang class code at username.';
    case 401:
      return joining
          ? "May gumagamit na ng username na ito sa klase. Kung ikaw 'yan, "
              "piliin ang 'BALIK NA AKO'. Kung hindi, gumamit ng ibang username."
          : 'Mali ang password. Subukan ulit.';
    case 404:
      return 'Mali ang class code. Itanong sa teacher mo ang tamang code.';
    case 429:
      // The server's block says how long is left; a plain rate limit does not.
      final wait = RegExp(r'try again in (\d+) minute').firstMatch(server);
      if (wait != null) {
        return 'Masyadong maraming mali. Subukan ulit sa loob ng ${wait.group(1)} '
            'minuto, o itanong sa teacher mo.';
      }
      return 'Masyadong maraming try. Maghintay sandali bago subukan ulit.';
    default:
      final code = response.statusCode ?? 0;
      return code >= 500
          ? 'May problema sa server. Subukan ulit mamaya.'
          : 'Hindi maka-login. Subukan ulit.';
  }
}

/// What a failed login complains about, so the screen can go back to that question.
enum LoginField { classCode, name, username, password }

/// Which question a message from [loginErrorMessage] is about, or null when it is
/// about nothing the student typed (no internet, too many tries, a server fault).
LoginField? loginErrorField(String message) {
  if (message == nameTakenMessage || message == sessionActiveMessage) return null;
  if (message.startsWith('Mali ang class code') ||
      message.startsWith('I-type ang class code') ||
      message.startsWith('Puno na ang klase') ||
      message.startsWith('Tapos na ang klase')) {
    return LoginField.classCode;
  }
  if (message.contains('username')) return LoginField.username;
  if (message.contains('pangalan')) return LoginField.name;
  if (message.contains('password')) return LoginField.password;
  return null;
}

/// Shown when the request to the teacher cannot be sent for any reason but the
/// internet or too many tries (the server has no such route yet, or it is down).
/// The student is told to say the class code and username to the teacher
/// instead, which the screen is already showing.
const String resetRequestCannotSend =
    'Hindi ma-send ngayon. Sabihin na lang sa teacher mo ang class code at username mo.';

/// The message a student sees when asking the teacher for a new password fails.
String resetRequestErrorMessage(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Mabagal o walang internet. Subukan ulit.';
    case DioExceptionType.connectionError:
      return 'Walang internet. Subukan ulit.';
    default:
      break;
  }
  if (e.response?.statusCode == 429) {
    return 'Masyadong maraming send. Subukan ulit mamaya.';
  }
  return resetRequestCannotSend;
}

/// The message a student sees when saving a new password fails. The server's own
/// answer is English, so it is not shown.
String changePasswordErrorMessage(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Mabagal o walang internet. Subukan ulit.';
    case DioExceptionType.connectionError:
      return 'Hindi ma-save ang password. I-check ang internet at subukan ulit.';
    default:
      break;
  }
  switch (e.response?.statusCode) {
    case 400:
      return 'Dapat 6 characters o higit pa ang password.';
    case 401:
      return 'Tapos na ang login mo. Mag-login ulit.';
    case 429:
      return 'Masyadong maraming try. Maghintay sandali bago subukan ulit.';
    case null:
      return 'Hindi ma-save ang password. I-check ang internet at subukan ulit.';
    default:
      final code = e.response!.statusCode!;
      return code >= 500
          ? 'May problema sa server. Subukan ulit mamaya.'
          : 'Hindi ma-save ang password. Subukan ulit.';
  }
}

/// The ended-class answer inside a failed login, or null when the answer is something else.
ClassEndedInfo? classEndedFrom(DioException e) {
  final data = e.response?.data;
  if (e.response?.statusCode != 409 || data is! Map) return null;
  if (data['code'] != 'CLASS_ENDED') return null;
  return ClassEndedInfo.fromJson(data['classEnded']);
}

/// Said when the phone cannot reach the server, or null when it did.
String? _noConnection(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Mabagal o walang internet. Subukan ulit.';
    case DioExceptionType.connectionError:
      return 'Hindi maka-connect sa server. I-check ang internet at subukan ulit.';
    default:
      return e.response == null
          ? 'Hindi maka-connect sa server. Subukan ulit.'
          : null;
  }
}

const String _tooManyTries =
    'Masyadong maraming try. Maghintay sandali bago subukan ulit.';

/// The message for a failed "Is this your class?" look-up of the new class code.
String classLookupErrorMessage(DioException e) {
  final gone = _noConnection(e);
  if (gone != null) return gone;
  final response = e.response!;
  final data = response.data;
  if (data is Map && data['code'] == 'CLASS_ENDED') {
    return 'Tapos na rin ang klase na ito. Itanong sa teacher mo ang bagong class code.';
  }
  switch (response.statusCode) {
    case 400:
      return 'I-type ang bagong class code.';
    case 404:
      return 'Mali ang class code. Itanong sa teacher mo ang tamang code.';
    case 429:
      return _tooManyTries;
    default:
      return (response.statusCode ?? 0) >= 500
          ? 'May problema sa server. Subukan ulit mamaya.'
          : 'Hindi mahanap ang klase. Subukan ulit.';
  }
}

/// What went wrong when moving to the new class. The server's codes come in English, so
/// each one gets its own words. [oldGrade] and [newGrade] ("Grade 5", "Grade 7") make the
/// wrong-grade message say which grades are meant, when the screen knows them.
MoveUpError moveUpError(DioException e, {String? oldGrade, String? newGrade}) {
  final gone = _noConnection(e);
  if (gone != null) return MoveUpError(gone);
  final response = e.response!;
  final data = response.data;
  final code = data is Map && data['code'] is String ? data['code'] as String : null;
  final server = data is Map && data['message'] is String
      ? (data['message'] as String)
      : '';

  switch (code) {
    case 'SESSION_ACTIVE':
      return const MoveUpError(sessionActiveMessage, code: 'SESSION_ACTIVE');
    case 'WRONG_GRADE':
      final grades = oldGrade != null && newGrade != null
          ? ' $oldGrade ka ngayon, at ang klase na ito ay $newGrade.'
          : '';
      return MoveUpError(
          'Hindi puwede ang klase na ito.$grades Parehong grade o isang grade '
          'pataas lang ang puwede.',
          code: code);
    case 'CLASS_FULL':
      return MoveUpError('Puno na ang klase na ito. Itanong sa teacher mo.',
          code: code);
    case 'CLASS_ENDED':
      return MoveUpError(
          'Tapos na rin ang klase na ito. Itanong sa teacher mo ang bagong class code.',
          code: code);
    case 'SAME_CLASS':
      return MoveUpError(
          'Ito rin ang dati mong klase. Ilagay ang bagong class code.',
          code: code);
    case 'WRONG_YEAR':
      return MoveUpError(
          'Hindi para sa school year na ito ang klase na ito. '
          'Itanong sa teacher mo ang tamang code.',
          code: code);
    case 'YEAR_ENDED':
      return MoveUpError(
          'Tapos na ang school year. Hintayin ang bagong school year bago '
          'sumali sa bagong klase.',
          code: code);
    case 'CLASS_NOT_ENDED':
      return MoveUpError(
          'Hindi pa tapos ang dati mong klase. Mag-login ka na lang.',
          code: code);
    case 'CLASS_NOT_FOUND':
      return MoveUpError(
          'Mali ang class code. Itanong sa teacher mo ang tamang code.',
          code: code);
  }

  switch (response.statusCode) {
    case 401:
      return const MoveUpError('Mali ang password. Bumalik sa login at subukan ulit.');
    case 404:
      return const MoveUpError(
          'Mali ang class code. Itanong sa teacher mo ang tamang code.');
    case 429:
      final wait = RegExp(r'try again in (\d+) minute').firstMatch(server.toLowerCase());
      return MoveUpError(wait != null
          ? 'Masyadong maraming mali. Subukan ulit sa loob ng ${wait.group(1)} '
              'minuto, o itanong sa teacher mo.'
          : _tooManyTries);
    default:
      if ((response.statusCode ?? 0) >= 500) {
        return const MoveUpError('May problema sa server. Subukan ulit mamaya.');
      }
      // A code this game does not know: the server's own words are better than none.
      return MoveUpError(
          server.isNotEmpty ? server : 'Hindi makalipat sa bagong klase. Subukan ulit.',
          code: code);
  }
}
