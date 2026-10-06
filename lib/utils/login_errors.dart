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
