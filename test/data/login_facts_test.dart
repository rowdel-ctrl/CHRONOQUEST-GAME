// The "Alam mo ba?" line says nothing the history screen does not already teach,
// and the version in the corner is the one in pubspec.yaml.
import 'dart:io';

import 'package:chronoquest/core/app_info.dart';
import 'package:chronoquest/data/era_story.dart';
import 'package:chronoquest/data/login_facts.dart';
import 'package:flutter_test/flutter_test.dart';

String _plain(String text) => text.replaceAll('**', '');

void main() {
  test('every fact is one event from the history screen', () {
    expect(loginFacts, isNotEmpty);
    for (final fact in loginFacts) {
      final beats = eraStories.values
          .expand((story) => story.beats)
          .where((b) => b.label == fact.label && _plain(b.text).contains(fact.proof));
      expect(beats, isNotEmpty, reason: '"${fact.text}" has no source beat "${fact.label}"');
    }
  });

  test('a year in a fact is in its source', () {
    final year = RegExp(r'\b(1[5-9]\d\d|20\d\d)\b');
    for (final fact in loginFacts) {
      for (final m in year.allMatches(fact.text)) {
        expect('${fact.label} ${fact.proof}'.contains(m.group(0)!), isTrue,
            reason: '"${fact.text}" says ${m.group(0)}, which its source does not');
      }
    }
  });

  test('a fact is short enough for a line or two', () {
    for (final fact in loginFacts) {
      expect(fact.text.length, lessThanOrEqualTo(80), reason: fact.text);
    }
  });

  test('the version in the corner is the one in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version =
        RegExp(r'^version:\s*([0-9.]+)\+', multiLine: true).firstMatch(pubspec)!.group(1);
    expect(appVersion, version);
  });
}
