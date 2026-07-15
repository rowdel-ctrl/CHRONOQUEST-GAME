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

  Future<bool> login(String classCode, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.login(classCode, name);
      final student =
          Student.fromJson(data['user'] as Map<String, dynamic>);
      state = AuthState(
        student: student,
        isLoggedIn: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
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
