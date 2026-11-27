import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// "This account was signed in on another device." The server keeps one active session per
/// student: a sign-in on a second device ends the first. The old phone finds out on its next
/// request, which the server refuses with a 401 carrying the code [code].
///
/// The API client raises [notifier] when it sees that answer; `SessionReplacedGate` shows the
/// notice over whatever screen is open, with a button that returns to the login screen.
class SessionReplaced {
  SessionReplaced._();

  /// The `code` field of the server's refusal.
  static const String code = 'SESSION_REPLACED';

  /// True while the notice is waiting to be acknowledged.
  static final ValueNotifier<bool> notifier = ValueNotifier<bool>(false);

  /// True while the notice "your login ended" is waiting to be acknowledged: the server refused
  /// this phone's saved login for any other reason (the token ran out, the account was deleted, the
  /// teacher reset the password, the whole database was emptied).
  static final ValueNotifier<bool> endedNotifier = ValueNotifier<bool>(false);

  /// What a refused request means. Only a request that carried a saved login counts: a wrong
  /// password at the sign-in screen is also a 401, and must stay on that screen.
  static LoginRefusal classify(DioException error) {
    final response = error.response;
    if (response?.statusCode != 401) return LoginRefusal.none;
    if (isReplaced(response)) return LoginRefusal.replaced;
    final hadLogin = error.requestOptions.headers.containsKey('Authorization');
    return hadLogin ? LoginRefusal.ended : LoginRefusal.none;
  }

  /// Whether [response] is the server saying this session was replaced.
  static bool isReplaced(Response<dynamic>? response) {
    if (response?.statusCode != 401) return false;
    final data = response?.data;
    return data is Map && data['code'] == code;
  }
}

/// What a refusal of a saved login means for the student.
enum LoginRefusal { none, replaced, ended }
