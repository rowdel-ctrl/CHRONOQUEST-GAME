// The two name boxes of "Bago ako": how a typed name is tidied, and which names are refused.
import 'package:chronoquest/utils/person_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tidyName', () {
    test('removes extra spaces and puts a capital letter on each word', () {
      expect(tidyName('  dela   CRUZ '), 'Dela Cruz');
      expect(tidyName('maria clara'), 'Maria Clara');
      expect(tidyName('JUAN'), 'Juan');
    });

    test('capitals follow hyphens and apostrophes', () {
      expect(tidyName("jo-ann o'brien"), "Jo-Ann O'Brien");
      expect(tidyName('o’brien'), 'O’Brien');
    });

    test('keeps accents and ñ', () {
      expect(tidyName('peña'), 'Peña');
      expect(tidyName('NIÑO'), 'Niño');
    });

    test('nothing typed stays nothing', () {
      expect(tidyName(''), '');
      expect(tidyName('   '), '');
    });
  });

  group('nameProblem', () {
    String? first(String s) => nameProblem(tidyName(s), NameBox.first);
    String? last(String s) => nameProblem(tidyName(s), NameBox.last);

    test('real names pass', () {
      for (final name in ['Juan', 'Maria Clara', 'Dela Cruz', "O'Brien", 'Jo-Ann', 'Peña', 'Jo', 'Mary Jane De Guzman']) {
        expect(first(name), isNull, reason: name);
        expect(last(name), isNull, reason: name);
      }
    });

    test('an empty box asks for that name', () {
      expect(first('  '), 'I-type ang pangalan mo');
      expect(last(''), 'I-type ang apelyido mo');
    });

    test('numbers, symbols and emoji are refused', () {
      for (final name in ['Juan2', 'Cruz123', 'Juan@', 'Juan 😀', '99', '-Juan', '.Juan']) {
        expect(first(name), 'Letra lang ang puwede dito, walang numero.', reason: name);
      }
    });

    test('one letter is too short', () {
      expect(first('J'), 'Dapat hindi bababa sa 2 letra.');
      expect(first('J.'), 'Dapat hindi bababa sa 2 letra.');
    });

    test('more than 30 characters is too long', () {
      expect(first('A' * 30), isNull);
      expect(first('A' * 31), 'Masyadong mahaba. Hanggang 30 lang.');
    });
  });

  test('the last name cannot be the first name again', () {
    expect(sameWordProblem('Juan', 'JUAN'), 'Iba dapat ang apelyido sa pangalan.');
    expect(sameWordProblem('Juan', 'Cruz'), isNull);
    expect(sameWordProblem('Juan', 'Juan Cruz'), isNull);
  });

  test('the full name is the first name, a space, the last name', () {
    expect(fullName('Juan', 'Dela Cruz'), 'Juan Dela Cruz');
  });
}
