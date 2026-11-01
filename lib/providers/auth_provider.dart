import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';
import '../data/question_bank.dart';
import '../services/api_service.dart';
import '../services/guest_mode.dart';
import '../services/question_sync.dart';
import '../services/storage_service.dart';

class AuthState {
  final Student? student;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  /// The wallet the server held at the last sign-in or profile read that reached
  /// it. Null until then: the cached student is not one, since it can be older
  /// than what the phone has. A new object each time, so the game notices.
  final ServerWallet? serverWallet;

  /// Someone trying the game without a class code (see [GuestMode]).
  bool get isGuest => student?.id == GuestMode.studentId;

  const AuthState({
    this.student,
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
    this.serverWallet,
  });

  AuthState copyWith({
    Student? student,
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
    ServerWallet? serverWallet,
  }) {
    return AuthState(
      student: student ?? this.student,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      serverWallet: serverWallet ?? this.serverWallet,
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
        QuestionSync.sync(student.classCode);
      }
    }
  }

  Future<Map<String, dynamic>> login({
    required String classCode,
    String? username,
    String? name,
    required String password,
    bool allowSameName = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.login(
        classCode: classCode,
        username: username,
        name: name,
        password: password,
        allowSameName: allowSameName,
      );
      final student = Student.fromJson(data['user'] as Map<String, dynamic>);
      state = AuthState(
        student: student,
        isLoggedIn: true,
        isLoading: false,
        serverWallet: ServerWallet.of(student),
      );
      // Retry any results that were queued while logged out or with an
      // expired token — now that we have a fresh one, this should succeed.
      _api.flushPendingResults();
      QuestionSync.sync(student.classCode);
      return {'success': true, 'isNewStudent': data['isNewStudent'] ?? false};
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        // The API layer throws a ready-to-show message. Anything else is a
        // bug or a bad reply, and its raw text means nothing to a student.
        error: e is String ? e : 'May problema. Subukan ulit.',
      );
      return {'success': false};
    }
  }

  /// Hides the last error, e.g. when the student switches between "Bago" and
  /// "Babalik", since the message was about the other one.
  void clearError() {
    if (state.error != null) state = state.copyWith(error: null);
  }

  /// Starts a guest session: the first era only, nothing sent to the server. Each
  /// session starts fresh, so a demo always begins from the beginning.
  Future<void> startGuest() async {
    // Whatever the phone kept for someone before (progress, the codex) goes, and
    // the guest's own wallet and hearts start empty.
    await StorageService.clearAll();
    await StorageService.clearGuestData(GuestMode.studentId);
    QuestionBank.clearSynced();
    GuestMode.active = true;
    state = AuthState(
      student: Student(
        id: GuestMode.studentId,
        username: 'guest',
        name: 'Guest',
        classCode: '',
        gradeLevel: 'grade5',
      ),
      isLoggedIn: true,
    );
  }

  Future<void> refreshProfile() async {
    if (GuestMode.active) return; // a guest has no profile on the server
    try {
      final student = await _api.getFreshProfile();
      state = state.copyWith(
          student: student, serverWallet: ServerWallet.of(student));
      QuestionSync.sync(student.classCode);
    } catch (_) {
      // Use cached data: the wallet is not joined with the server's this time.
    }
  }

  Future<void> logout() async {
    GuestMode.active = false;
    await StorageService.clearAll();
    QuestionBank.clearSynced();
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
