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
      return 'Mabagal o walang internet. Subukan muli.';
    case DioExceptionType.connectionError:
      return 'Hindi makakonekta sa server. Tingnan ang internet at subukan muli.';
    default:
      break;
  }

  final response = e.response;
  if (response == null) {
    return 'Hindi makakonekta sa server. Subukan muli.';
  }

  final data = response.data;
  final server = data is Map && data['message'] is String
      ? (data['message'] as String).toLowerCase()
      : '';

  switch (response.statusCode) {
    case 400:
      if (server.contains('real name')) {
        return joining
            ? 'Ilagay ang tunay mong pangalan para kay titser.'
            : 'Walang account na may ganitong username sa class code na ito. '
                "Tingnan ang username, o piliin ang 'Bago' para sumali.";
      }
      if (server.contains('password')) {
        return joining
            ? 'Ang password ay hindi bababa sa 6 na characters.'
            : 'Mali ang password. Subukan muli.';
      }
      return 'Punan ang class code at username.';
    case 401:
      return joining
          ? 'May gumagamit na ng username na ito sa klase. Kung ikaw iyon, '
              "piliin ang 'Babalik'. Kung hindi, gumamit ng ibang username."
          : 'Mali ang password. Subukan muli.';
    case 404:
      return 'Mali ang class code. Itanong sa titser ang tamang code.';
    case 429:
      return 'Masyadong maraming subok. Maghintay sandali bago subukan muli.';
    default:
      final code = response.statusCode ?? 0;
      return code >= 500
          ? 'May problema sa server. Subukan muli mamaya.'
          : 'Hindi makapag-login. Subukan muli.';
  }
}

/// What a failed login complains about, so the screen can go back to that question.
enum LoginField { classCode, name, username, password }

/// Which question a message from [loginErrorMessage] is about, or null when it is
/// about nothing the student typed (no internet, too many tries, a server fault).
LoginField? loginErrorField(String message) {
  if (message.startsWith('Mali ang class code') ||
      message.startsWith('Punan ang class code')) {
    return LoginField.classCode;
  }
  if (message.contains('username')) return LoginField.username;
  if (message.contains('pangalan')) return LoginField.name;
  if (message.contains('password')) return LoginField.password;
  return null;
}

/// The message a student sees when saving a new password fails. The server's own
/// answer is English, so it is not shown.
String changePasswordErrorMessage(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Mabagal o walang internet. Subukan muli.';
    case DioExceptionType.connectionError:
      return 'Hindi ma-save ang password. Tingnan ang internet at subukan muli.';
    default:
      break;
  }
  switch (e.response?.statusCode) {
    case 400:
      return 'Hindi bababa sa 6 na characters ang password.';
    case 401:
      return 'Tapos na ang login mo. Mag-login ulit.';
    case 429:
      return 'Masyadong maraming subok. Maghintay sandali bago subukan muli.';
    case null:
      return 'Hindi ma-save ang password. Tingnan ang internet at subukan muli.';
    default:
      final code = e.response!.statusCode!;
      return code >= 500
          ? 'May problema sa server. Subukan muli mamaya.'
          : 'Hindi ma-save ang password. Subukan muli.';
  }
}
