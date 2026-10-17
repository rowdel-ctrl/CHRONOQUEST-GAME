// Poppins ships inside the app, so text looks the same with no internet. These
// checks keep it that way: every weight the code asks for has its file, and no
// other downloaded font creeps back in.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Poppins file name for each weight google_fonts can ask for.
const _fileFor = {
  400: 'Poppins-Regular.ttf',
  500: 'Poppins-Medium.ttf',
  600: 'Poppins-SemiBold.ttf',
  700: 'Poppins-Bold.ttf',
  900: 'Poppins-Black.ttf',
};

Iterable<File> _libFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every bundled Poppins file is in the app and is a real font', () async {
    for (final file in _fileFor.values) {
      final data = await rootBundle.load('assets/google_fonts/$file');
      expect(data.lengthInBytes, greaterThan(50000), reason: file);
      // A TrueType file starts with 0x00010000.
      expect(data.getUint32(0), 0x00010000, reason: '$file is not a TrueType font');
    }
  });

  test('the licence travels with the fonts', () {
    expect(File('assets/google_fonts/OFL-Poppins.txt').existsSync(), isTrue);
  });

  test('every weight the code uses has a bundled file', () {
    final used = <int>{};
    final weight = RegExp(r'FontWeight\.(w[1-9]00|bold|normal)');
    for (final f in _libFiles()) {
      for (final m in weight.allMatches(f.readAsStringSync())) {
        final w = m.group(1)!;
        used.add(switch (w) { 'bold' => 700, 'normal' => 400, _ => int.parse(w.substring(1)) });
      }
    }
    expect(used, isNotEmpty);
    expect(used.difference(_fileFor.keys.toSet()), isEmpty,
        reason: 'a weight with no file would be downloaded at run time');
  });

  test('no other downloaded font is used', () {
    final other = RegExp(r'GoogleFonts\.(?!poppins\b|poppinsTextTheme\b|config\b|pendingFonts\b)\w+');
    for (final f in _libFiles()) {
      final hits = other.allMatches(f.readAsStringSync()).map((m) => m.group(0)).toList();
      expect(hits, isEmpty, reason: f.path);
    }
  });
}
