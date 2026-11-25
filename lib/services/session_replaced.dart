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

  /// Whether [response] is the server saying this session was replaced.
  static bool isReplaced(Response<dynamic>? response) {
    if (response?.statusCode != 401) return false;
    final data = response?.data;
    return data is Map && data['code'] == code;
  }
}
