import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthState {
  final Student? student;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  const AuthState({
    this.student,
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
  });

  AuthState copyWith({
    Student? student,
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
  }) {
    return AuthState(
      student: student ?? this.student,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkExistingLogin();
  }

  final _api = ApiService();

  Future<void> _checkExistingLogin() async {
    final hasToken = await StorageService.hasToken();
    if (hasToken) {
      final student = StorageService.getStudent();
      if (student != null) {
        state = AuthState(student: student, isLoggedIn: true);
      }
    }
  }

  Future<Map<String, dynamic>> login({
    required String classCode,
    required String username,
    String? name,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.login(
        classCode: classCode,
        username: username,
        name: name,
        password: password,
      );
      final student =
          Student.fromJson(data['user'] as Map<String, dynamic>);
      state = AuthState(
        student: student,
        isLoggedIn: true,
        isLoading: false,
      );
      // Retry any results that were queued while logged out or with an
      // expired token — now that we have a fresh one, this should succeed.
      _api.flushPendingResults();
      return {'success': true, 'isNewStudent': data['isNewStudent'] ?? false};
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        // The API layer throws a ready-to-show message. Anything else is a
        // bug or a bad reply, and its raw text means nothing to a student.
        error: e is String ? e : 'May nangyaring problema. Subukan muli.',
      );
      return {'success': false};
    }
  }

  /// Hides the last error, e.g. when the student switches between "Bago" and
  /// "Babalik", since the message was about the other one.
  void clearError() {
    if (state.error != null) state = state.copyWith(error: null);
  }

  Future<void> refreshProfile() async {
    try {
      final student = await _api.getProfile();
      state = state.copyWith(student: student);
    } catch (_) {
      // Use cached data
    }
  }

  Future<void> logout() async {
    await StorageService.clearAll();
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());