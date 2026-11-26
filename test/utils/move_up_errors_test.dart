// What a learner reads when the class has ended and they move to the new class. The server's
// answers are the ones in CHRONO-DASHBOARD/CBACK/src/controllers/student.controller.js
// (class-lookup, move-up, and the 409 CLASS_ENDED of the login).
import 'package:chronoquest/models/class_move.dart';
import 'package:chronoquest/utils/login_errors.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _reply(int status, Map<String, dynamic> body) {
  final options = RequestOptions(path: '/student/move-up');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: body),
  );
}

DioException _code(int status, String code,
        [String message = 'English words']) =>
    _reply(status, {'success': false, 'code': code, 'message': message});

void main() {
  group('a login on an ended class', () {
    final ended = _reply(409, {
      'success': false,
      'code': 'CLASS_ENDED',
      'message':
          'This class has ended. Ask your teacher for the new class code.',
      'classEnded': {
        'name': 'Juan Dela Cruz',
        'username': 'juan',
        'sectionName': 'Sampaguita',
        'grade': 'Grade 5',
        'schoolYear': '2025-2026',
      },
    });

    test('gives back who the learner is', () {
      final info = classEndedFrom(ended)!;
      expect(info.name, 'Juan Dela Cruz');
      expect(info.username, 'juan');
      expect(info.sectionName, 'Sampaguita');
      expect(info.grade, 'Grade 5');
      expect(info.schoolYear, '2025-2026');
      expect(info.hasAccount, isTrue);
    });

    test('a join has no name or username, so there is nothing to move', () {
      final join = _reply(409, {
        'success': false,
        'code': 'CLASS_ENDED',
        'classEnded': {
          'sectionName': 'Sampaguita',
          'grade': 'Grade 5',
          'schoolYear': '2025-2026'
        },
      });
      final info = classEndedFrom(join)!;
      expect(info.hasAccount, isFalse);
      expect(info.sectionName, 'Sampaguita');
    });

    test('an answer with no classEnded part still counts as ended', () {
      expect(classEndedFrom(_code(409, 'CLASS_ENDED'))!.hasAccount, isFalse);
    });

    test('other answers are not an ended class', () {
      expect(
          classEndedFrom(
              _reply(401, {'success': false, 'message': 'Incorrect password'})),
          isNull);
      expect(classEndedFrom(_code(409, 'SESSION_ACTIVE')), isNull);
      expect(classEndedFrom(_code(409, 'NAME_TAKEN')), isNull);
    });

    test(
        'as a plain login message it says to ask the teacher, on the class code question',
        () {
      final msg = loginErrorMessage(ended, joining: true);
      expect(msg, classEndedMessage);
      expect(loginErrorField(msg), LoginField.classCode);
    });
  });

  group('"Is this your class?" could not find the class', () {
    test('a wrong code, an empty code and too many tries', () {
      expect(
          classLookupErrorMessage(
              _reply(404, {'message': 'Invalid class code'})),
          contains('Mali ang class code'));
      expect(
          classLookupErrorMessage(
              _reply(400, {'message': 'Class code is required'})),
          'I-type ang bagong class code.');
      expect(
          classLookupErrorMessage(
              _reply(429, {'message': 'Too many requests'})),
          contains('Masyadong maraming try'));
    });

    test('the new code is an old class too', () {
      expect(classLookupErrorMessage(_code(409, 'CLASS_ENDED')),
          contains('Tapos na rin ang klase'));
    });

    test('no internet and a server fault', () {
      final off = DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError);
      expect(classLookupErrorMessage(off), contains('internet'));
      expect(classLookupErrorMessage(_reply(500, {})),
          contains('May problema sa server'));
    });
  });

  group('moving to the new class failed', () {
    test("every server code has its own words, in the game's Taglish", () {
      const expected = {
        'CLASS_FULL': 'Puno na ang klase na ito',
        'CLASS_ENDED': 'Tapos na rin ang klase',
        'SAME_CLASS': 'Ito rin ang dati mong klase',
        'WRONG_YEAR': 'Hindi para sa school year na ito',
        'YEAR_ENDED': 'Tapos na ang school year',
        'CLASS_NOT_ENDED': 'Hindi pa tapos ang dati mong klase',
        'CLASS_NOT_FOUND': 'Mali ang class code',
      };
      for (final e in expected.entries) {
        final error = moveUpError(_code(409, e.key));
        expect(error.message, contains(e.value), reason: e.key);
        expect(error.code, e.key);
        expect(error.message, isNot(contains('English words')),
            reason: 'never the raw server text');
      }
    });

    test('the wrong grade says which grades when it knows them', () {
      final plain = moveUpError(_code(409, 'WRONG_GRADE'));
      expect(plain.message, contains('Parehong grade o isang grade pataas'));
      final named = moveUpError(_code(409, 'WRONG_GRADE'),
          oldGrade: 'Grade 5', newGrade: 'Grade 3');
      expect(named.message, contains('Grade 5 ka ngayon'));
      expect(named.message, contains('Grade 3'));
    });

    test(
        'an open session on another phone is a question, so it carries its code',
        () {
      final error = moveUpError(_code(409, 'SESSION_ACTIVE'));
      expect(error.code, 'SESSION_ACTIVE');
      expect(error.message, sessionActiveMessage);
    });

    test('a wrong password, a missing class, a lock and a server fault', () {
      expect(
          moveUpError(_reply(401, {'message': 'Incorrect password'})).message,
          contains('Mali ang password'));
      expect(moveUpError(_reply(404, {'message': 'x'})).message,
          contains('Mali ang class code'));
      expect(
          moveUpError(_reply(429, {
            'message': 'Too many attempts. Try again in 7 minutes.'
          })).message,
          contains('7 minuto'));
      expect(moveUpError(_reply(429, {'message': 'Too many'})).message,
          contains('Masyadong maraming try'));
      expect(moveUpError(_reply(500, {'message': 'boom'})).message,
          contains('May problema sa server'));
    });

    test("a code the game does not know shows the server's own message", () {
      expect(
          moveUpError(_code(409, 'SOMETHING_NEW', 'Try something else.'))
              .message,
          'Try something else.');
      expect(moveUpError(_reply(418, {})).message, contains('Hindi makalipat'));
    });

    test('no internet reads as an internet problem', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        final e = DioException(
            requestOptions: RequestOptions(path: '/x'), type: type);
        expect(moveUpError(e).message, contains('internet'), reason: '$type');
      }
    });
  });

  group('the answers are read the way the server sends them', () {
    test('a class', () {
      final info = ClassInfo.fromJson({
        'classCode': 'EDG6A1',
        'sectionName': 'Sampaguita',
        'gradeLevel': 'grade6',
        'grade': 'Grade 6',
        'teacherName': 'Ana Reyes',
        'schoolName': 'Bangbangalon Elementary School',
        'schoolYear': '2026-2027',
      });
      expect((
        info.classCode,
        info.sectionName,
        info.grade,
        info.teacherName,
        info.schoolYear
      ), (
        'EDG6A1',
        'Sampaguita',
        'Grade 6',
        'Ana Reyes',
        '2026-2027'
      ));
    });

    test('missing parts are empty, not a crash', () {
      final info = ClassInfo.fromJson({'classCode': 'X1'});
      expect((info.sectionName, info.teacherName), ('', ''));
      expect(ClassEndedInfo.fromJson(null).hasAccount, isFalse);
      expect(ClassEndedInfo.fromJson({'username': '  '}).hasAccount, isFalse);
    });
  });
}
