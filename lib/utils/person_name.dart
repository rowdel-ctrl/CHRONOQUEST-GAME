/// The two name boxes of "Bago ako" (Pangalan and Apelyido): how a typed name is
/// tidied and what it must look like. The server checks the same rules again.
enum NameBox { first, last }

/// A letter first, then letters, accents, spaces, hyphens, apostrophes and periods
/// (Maria Clara, Dela Cruz, Jo-Ann, O'Brien, Peña).
final _allowed = RegExp(r"^\p{L}[\p{L}\p{M} .'’-]*$", unicode: true);
final _letter = RegExp(r'\p{L}', unicode: true);

const int maxNameLength = 30;

/// Extra spaces removed and a capital letter on each word: "  dela   CRUZ " is
/// "Dela Cruz", "jo-ann o'brien" is "Jo-Ann O'Brien".
String tidyName(String raw) {
  final words = raw.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  return words.map(_capitalize).join(' ');
}

String _capitalize(String word) {
  final out = StringBuffer();
  var capital = true;
  for (final rune in word.runes) {
    final ch = String.fromCharCode(rune);
    out.write(capital ? ch.toUpperCase() : ch.toLowerCase());
    capital = ch == '-' || ch == "'" || ch == '’';
  }
  return out.toString();
}

/// What is wrong with a tidied name for [box], in words the student can act on,
/// or null when it will do.
String? nameProblem(String tidy, NameBox box) {
  if (tidy.isEmpty) {
    return box == NameBox.first
        ? 'I-type ang pangalan mo'
        : 'I-type ang apelyido mo';
  }
  if (!_allowed.hasMatch(tidy)) {
    return 'Letra lang ang puwede dito, walang numero.';
  }
  if (_letter.allMatches(tidy).length < 2) {
    return 'Dapat hindi bababa sa 2 letra.';
  }
  if (tidy.length > maxNameLength) {
    return 'Masyadong mahaba. Hanggang $maxNameLength lang.';
  }
  return null;
}

/// The last name cannot be the first name again ("Juan Juan").
String? sameWordProblem(String first, String last) =>
    first.toLowerCase() == last.toLowerCase()
        ? 'Iba dapat ang apelyido sa pangalan.'
        : null;

/// What the teacher will see.
String fullName(String first, String last) => '$first $last';
