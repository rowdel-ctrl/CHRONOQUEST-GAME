import 'package:dio/dio.dart';
import '../services/session_replaced.dart';
import '../services/storage_service.dart';
import 'constants.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await StorageService.clearToken();
            // Say so over any screen, and send the student back to the login screen: the same
            // account was signed in on another device, or the server no longer knows this login
            // (it ran out, the account is gone). Without this the phone kept a ghost session,
            // played on and queued results that a later sign-in would have sent as its own.
            switch (SessionReplaced.classify(error)) {
              case LoginRefusal.replaced:
                SessionReplaced.notifier.value = true;
              case LoginRefusal.ended:
                SessionReplaced.endedNotifier.value = true;
              case LoginRefusal.none:
                break;
            }
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  /// Reset the Dio instance (useful after logout)
  static void reset() {
    _instance = null;
  }
}
