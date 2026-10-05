// What a section QR code holds. The first group uses the dashboard's own output
// (CHRONO-DASHBOARD/CDASH/src/utils/joinLink.js):
//   `chronoquest://join?code=${encodeURIComponent(classCode)}`
import 'package:chronoquest/utils/join_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the link the dashboard prints', () {
    test('gives the class code', () {
      expect(parseJoinCode('chronoquest://join?code=EDG5A1'), 'EDG5A1');
    });

    test('upper-cases it, like the Class Code field', () {
      expect(parseJoinCode('chronoquest://join?code=edg5a1'), 'EDG5A1');
    });

    test('decodes a code the dashboard had to escape', () {
      // encodeURIComponent("AB C") is "AB%20C"; a space is not a valid code.
      expect(parseJoinCode('chronoquest://join?code=AB%20C'), isNull);
      expect(parseJoinCode('chronoquest://join?code=AB%2DC'), 'AB-C');
    });

    test('ignores surrounding whitespace and extra parameters', () {
      expect(parseJoinCode('  chronoquest://join?code=EDG5A1&x=1\n'), 'EDG5A1');
    });

    test('is not fussy about the scheme or host case', () {
      expect(parseJoinCode('ChronoQuest://JOIN?code=EDG5A1'), 'EDG5A1');
    });
  });

  group('a bare code', () {
    test('is accepted, so an older poster still scans', () {
      expect(parseJoinCode('EDG5A1'), 'EDG5A1');
      expect(parseJoinCode(' edg5a1 '), 'EDG5A1');
    });

    test('may hold dashes and underscores', () {
      expect(parseJoinCode('G5-SAMPAGUITA_1'), 'G5-SAMPAGUITA_1');
    });
  });

  group('anything else is not a class code', () {
    for (final raw in [
      null,
      '',
      '   ',
      'https://chronoquest.example/join?code=EDG5A1',
      'chronoquest://login?code=EDG5A1',
      'chronoquest://join',
      'chronoquest://join?code=',
      'otherapp://join?code=EDG5A1',
      'WIFI:S:home;T:WPA;P:secret;;',
      'two words',
      'X',
      'THISCODEISFARTOOLONGTOBEACLASSCODE',
    ]) {
      test(raw == null ? 'null' : '"$raw"', () {
        expect(parseJoinCode(raw), isNull);
      });
    }
  });
}
