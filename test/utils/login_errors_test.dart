// What a student reads when joining or logging in fails. The server's answers are
// the ones in CHRONO-DASHBOARD/CBACK/src/controllers/student.controller.js.
import 'package:chronoquest/utils/login_errors.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _reply(int status, String message) {
  final options = RequestOptions(path: '/student/login');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: {'success': false, 'message': message},
    ),
  );
}

DioException _of(DioExceptionType type) =>
    DioException(requestOptions: RequestOptions(path: '/student/login'), type: type);

void main() {
  group('a wrong class code', () {
    final e = _reply(404, 'Invalid class code. Ask your teacher for the correct code.');

    test('says the class code is wrong, on both tabs', () {
      for (final joining in [true, false]) {
        expect(loginErrorMessage(e, joining: joining), contains('Mali ang class code'));
      }
    });
  });

  group('"Babalik" (logging back in)', () {
    test('a username the server does not know is not called a missing name', () {
      // The server says "Real name is required for first-time join" here.
      final msg = loginErrorMessage(
          _reply(400, 'Real name is required for first-time join.'),
          joining: false);
      expect(msg, contains('Walang account na may ganitong username'));
      expect(msg, contains("'Bago'"), reason: 'it points at the other tab');
      expect(msg.toLowerCase(), isNot(contains('pangalan')));
    });

    test('a short password is a wrong password here, not a length rule', () {
      final msg = loginErrorMessage(
          _reply(400, 'Password must be at least 6 characters.'),
          joining: false);
      expect(msg, 'Mali ang password. Subukan muli.');
    });

    test('a wrong password says so', () {
      final msg = loginErrorMessage(
          _reply(401, 'Incorrect password. Please try again.'),
          joining: false);
      expect(msg, 'Mali ang password. Subukan muli.');
    });
  });

  group('"Bago" (joining)', () {
    test('a taken username is not called a wrong password', () {
      // The server says "Incorrect password" when the username already exists.
      final msg = loginErrorMessage(
          _reply(401, 'Incorrect password. Please try again.'),
          joining: true);
      expect(msg, contains('May gumagamit na ng username na ito'));
      expect(msg, contains("'Babalik'"));
      expect(msg, isNot(contains('Mali ang password')));
    });

    test('a missing real name asks for it', () {
      final msg = loginErrorMessage(
          _reply(400, 'Real name is required for first-time join.'),
          joining: true);
      expect(msg, contains('tunay mong pangalan'));
    });

    test('a short password gives the rule', () {
      final msg = loginErrorMessage(
          _reply(400, 'Password must be at least 6 characters.'),
          joining: true);
      expect(msg, contains('6 na characters'));
    });
  });

  group('everything else', () {
    test('a missing class code or username', () {
      expect(
        loginErrorMessage(_reply(400, 'Class code and username are required.'),
            joining: false),
        'Punan ang class code at username.',
      );
    });

    test('too many tries', () {
      expect(loginErrorMessage(_reply(429, 'Too many requests. Try again later.'), joining: false),
          contains('Masyadong maraming subok'));
    });

    test('a server fault', () {
      expect(loginErrorMessage(_reply(500, 'boom'), joining: false),
          contains('May problema sa server'));
    });

    test('an unexpected status still reads as a plain sentence', () {
      expect(loginErrorMessage(_reply(418, 'teapot'), joining: false),
          'Hindi makapag-login. Subukan muli.');
    });

    test('no internet reads as an internet problem, not a developer note', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
      ]) {
        expect(loginErrorMessage(_of(type), joining: false), contains('internet'));
      }
      final refused = loginErrorMessage(_of(DioExceptionType.connectionError), joining: false);
      expect(refused, contains('internet'));
      expect(refused.toLowerCase(), isNot(contains('backend')));
      expect(refused.toLowerCase(), isNot(contains('api')));
    });

    test('no reply at all', () {
      expect(loginErrorMessage(_of(DioExceptionType.unknown), joining: false),
          contains('Hindi makakonekta'));
    });

    test('no message is ever raw English from the server', () {
      final english = RegExp(r'(please|invalid|incorrect|required|ask your)', caseSensitive: false);
      for (final (status, text) in [
        (400, 'Real name is required for first-time join.'),
        (400, 'Password must be at least 6 characters.'),
        (400, 'Class code and username are required.'),
        (401, 'Incorrect password. Please try again.'),
        (401, 'Password is required.'),
        (404, 'Invalid class code. Ask your teacher for the correct code.'),
        (429, 'Too many requests. Try again later.'),
      ]) {
        for (final joining in [true, false]) {
          expect(loginErrorMessage(_reply(status, text), joining: joining),
              isNot(matches(english)),
              reason: '$status "$text" joining=$joining');
        }
      }
    });
  });

  group('which question a message is about', () {
    test('every message loginErrorMessage can produce maps to the right question', () {
      for (final joining in [true, false]) {
        expect(loginErrorField(loginErrorMessage(_reply(404, 'Invalid class code.'), joining: joining)),
            LoginField.classCode);
        expect(loginErrorField(loginErrorMessage(_reply(400, 'Class code and username are required.'), joining: joining)),
            LoginField.classCode);
      }
      expect(
          loginErrorField(loginErrorMessage(_reply(401, 'Incorrect password.'), joining: true)),
          LoginField.username,
          reason: 'on Bago, a wrong password really means the username is taken');
      expect(
          loginErrorField(loginErrorMessage(_reply(401, 'Incorrect password.'), joining: false)),
          LoginField.password);
      expect(
          loginErrorField(loginErrorMessage(_reply(400, 'Real name is required for first-time join.'), joining: false)),
          LoginField.username,
          reason: 'a username the server does not know');
      expect(
          loginErrorField(loginErrorMessage(_reply(400, 'Real name is required for first-time join.'), joining: true)),
          LoginField.name);
      expect(
          loginErrorField(loginErrorMessage(_reply(400, 'Password must be at least 6 characters.'), joining: true)),
          LoginField.password);
    });

    test('a problem that is not about anything typed is about no question', () {
      expect(loginErrorField(loginErrorMessage(_reply(429, 'Too many requests.'), joining: true)), isNull);
      expect(loginErrorField(loginErrorMessage(_reply(500, 'boom'), joining: true)), isNull);
      expect(loginErrorField(loginErrorMessage(_of(DioExceptionType.connectionError), joining: true)), isNull);
      expect(loginErrorField(loginErrorMessage(_of(DioExceptionType.receiveTimeout), joining: true)), isNull);
    });
  });

  group('saving a new password', () {
    test('says what happened, in Filipino', () {
      expect(changePasswordErrorMessage(_reply(400, 'New password must be at least 6 characters.')),
          contains('6 na characters'));
      expect(changePasswordErrorMessage(_reply(401, 'Not authorised')), contains('Mag-login ulit'));
      expect(changePasswordErrorMessage(_reply(429, 'Too many requests.')), contains('Masyadong maraming subok'));
      expect(changePasswordErrorMessage(_reply(500, 'boom')), contains('May problema sa server'));
      expect(changePasswordErrorMessage(_reply(418, 'teapot')), 'Hindi ma-save ang password. Subukan muli.');
    });

    test('no internet reads as an internet problem', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
        DioExceptionType.unknown,
      ]) {
        expect(changePasswordErrorMessage(_of(type)), contains('internet'), reason: '$type');
      }
    });

    test('never shows English from the server or a developer note', () {
      final english = RegExp(r'(please|invalid|incorrect|required|backend|api)', caseSensitive: false);
      for (final status in [400, 401, 429, 500, 418]) {
        expect(changePasswordErrorMessage(_reply(status, 'New password must be at least 6 characters.')),
            isNot(matches(english)));
      }
    });
  });
}
