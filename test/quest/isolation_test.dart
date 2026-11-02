import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/quest/quest_mode.dart';

/// The new top-down gameplay (`lib/quest/`) must never leak into the platformer or
/// into a build that did not ask for it.
void main() {
  // The only files outside lib/quest/ allowed to name it: the route table and the
  // level screen's "which game do I open" choice.
  const allowedImporters = {
    'lib/core/router.dart',
    'lib/screens/game/level_select_screen.dart',
  };
  // `chronoquest/` (the package name) must not match, so a quote or slash comes first.
  final questImport = RegExp(
      r'''import\s+[\x27"][^\x27"]*[\x27"/]quest/|import\s+[\x27"]quest/''');

  List<File> dartFilesUnder(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  String rel(File f) =>
      f.path.replaceAll('\\', '/').replaceFirst(RegExp(r'^.*?(lib/)'), 'lib/');

  test('the switch is off unless the build turns it on', () {
    expect(AppFlags.newGameplay, isFalse);
    expect(QuestMode.enabled, isFalse);
  });

  test('nothing in lib/game imports the new gameplay', () {
    final offenders = [
      for (final f in dartFilesUnder('lib/game'))
        if (questImport.hasMatch(f.readAsStringSync())) rel(f),
    ];
    expect(offenders, isEmpty);
  });

  test('only the route table and the level screen may import it', () {
    final offenders = [
      for (final f in dartFilesUnder('lib'))
        if (!rel(f).startsWith('lib/quest/') &&
            !allowedImporters.contains(rel(f)) &&
            questImport.hasMatch(f.readAsStringSync()))
          rel(f),
    ];
    expect(offenders, isEmpty);
  });

  test('the guard really scans files', () {
    expect(dartFilesUnder('lib/game'), isNotEmpty);
    expect(dartFilesUnder('lib/quest'), isNotEmpty);
  });
}
