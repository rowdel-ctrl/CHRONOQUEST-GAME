import 'package:dio/dio.dart';

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
      return 'I-type ang class code at username.';
    case 401:
      return joining
          ? "May gumagamit na ng username na ito sa klase. Kung ikaw 'yan, "
              "piliin ang 'BALIK NA AKO'. Kung hindi, gumamit ng ibang username."
          : 'Mali ang password. Subukan ulit.';
    case 404:
      return 'Mali ang class code. Itanong sa teacher mo ang tamang code.';
    case 429:
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
  if (message.startsWith('Mali ang class code') ||
      message.startsWith('I-type ang class code')) {
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
