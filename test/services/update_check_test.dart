// Is there a newer version? Reading the small file on the download page, and
// comparing it with the version on this phone.
import 'package:chronoquest/services/update_check.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// A client whose every request is answered by [answer] (or fails), no network.
Dio _dio(Object? Function() answer) {
  final dio = Dio();
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    try {
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: answer()));
    } catch (e) {
      handler.reject(DioException(requestOptions: options, error: e));
    }
  }));
  return dio;
}

void main() {
  group('versions', () {
    test('three numbers are read, and what follows them is ignored', () {
      expect(parseVersion('1.3.3'), [1, 3, 3]);
      expect(parseVersion(' 1.3.3 TEST'), [1, 3, 3]);
      expect(parseVersion('1.3.3-test'), [1, 3, 3]);
      expect(parseVersion('1.3'), isNull);
      expect(parseVersion('soon'), isNull);
    });

    test('older, same, newer, and each number counts as a number', () {
      expect(compareVersions('1.3.2', '1.3.3'), lessThan(0));
      expect(compareVersions('1.3.3', '1.3.3'), 0);
      expect(compareVersions('1.4.0', '1.3.9'), greaterThan(0));
      expect(compareVersions('1.10.0', '1.9.0'), greaterThan(0), reason: '10 is more than 9');
      expect(compareVersions('2.0.0', '1.99.99'), greaterThan(0));
    });

    test('the tester build is the same version as the student build', () {
      expect(compareVersions('1.3.3 TEST', '1.3.3'), 0);
    });

    test('a version that cannot be read is never "newer"', () {
      expect(compareVersions('soon', '1.3.3'), 0);
    });
  });

  group('the file', () {
    test('a full file is read', () {
      final v = LatestVersion.fromJson({
        'version': '1.3.3',
        'required': true,
        'notes': ['Saved na ang coins', '', 5, 'Bagong gate'],
        'reason': 'Hindi na makaka-save ang old version',
        'url': 'https://example.test/get',
      })!;
      expect(v.version, '1.3.3');
      expect(v.required, isTrue);
      expect(v.notes, ['Saved na ang coins', 'Bagong gate'], reason: 'blanks and non-text dropped');
      expect(v.reason, 'Hindi na makaka-save ang old version');
      expect(v.url, 'https://example.test/get');
    });

    test('only the version is needed: not required, no notes, the site for the link', () {
      final v = LatestVersion.fromJson({'version': '1.3.3'})!;
      expect(v.required, isFalse);
      expect(v.notes, isEmpty);
      expect(v.reason, isNull);
      expect(v.url, startsWith('https://'));
    });

    test('at most four notes, and the link must be https', () {
      final v = LatestVersion.fromJson({
        'version': '1.3.3',
        'notes': ['a', 'b', 'c', 'd', 'e', 'f'],
        'url': 'http://plain.test',
      })!;
      expect(v.notes, ['a', 'b', 'c', 'd']);
      expect(v.url, isNot('http://plain.test'));
    });

    test('a file with no readable version gives nothing', () {
      expect(LatestVersion.fromJson(null), isNull);
      expect(LatestVersion.fromJson('1.3.3'), isNull);
      expect(LatestVersion.fromJson({'notes': []}), isNull);
      expect(LatestVersion.fromJson({'version': 'soon'}), isNull);
    });
  });

  group('checking', () {
    test('a newer version is returned', () async {
      final v = await UpdateCheck.fetch(
        dio: _dio(() => {'version': '1.3.3', 'notes': ['x']}),
        current: '1.3.2',
        url: 'https://example.test/latest.json',
      );
      expect(v?.version, '1.3.3');
    });

    test('the same version, or an older one, gives nothing', () async {
      expect(await UpdateCheck.fetch(dio: _dio(() => {'version': '1.3.2'}), current: '1.3.2'), isNull);
      expect(await UpdateCheck.fetch(dio: _dio(() => {'version': '1.3.1'}), current: '1.3.2'), isNull);
    });

    test('no internet gives nothing, and does not throw', () async {
      final v = await UpdateCheck.fetch(dio: _dio(() => throw Exception('offline')), current: '1.3.2');
      expect(v, isNull);
    });

    test('a page that is not the file gives nothing', () async {
      final v = await UpdateCheck.fetch(dio: _dio(() => '<html>404</html>'), current: '1.3.2');
      expect(v, isNull);
    });
  });
}
